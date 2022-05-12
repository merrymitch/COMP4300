-- datapath_aubie.vhd

-- entity reg_file (lab 3)
use work.dlx_types.all; 
use work.bv_arithmetic.all;  

entity reg_file is
     generic(prop_delay: time := 10 ns);
     port (data_in: in dlx_word; readnotwrite,clock : in bit; 
	   data_out: out dlx_word; reg_number: in register_index );
end entity reg_file; 

-- architecture reg_file (lab 3)
architecture behavior of reg_file is
	type reg_type is array (0 to 31) of dlx_word;
begin
	register_file_process: process(data_in, readnotwrite, clock, reg_number) is
	variable registers : reg_type;
	begin 
		--set registers 1, 2 to be a value for testing
		--Note: This code runs every time an input to the regfile changes,
		--so don't store anything in R1 and R2 while this is here,
		--or it will get overwritten
		registers(1) := X"01010101";
		registers(2) := X"10101010";
		--In a given clock cycle one value can be read or one can be written
		if clock = '1' then
			--If a read is being done, the data_in input is ignored, and
			--the value in register reg_number is copied to the data_out port.
			if readnotwrite = '1' then 
				data_out <= registers(bv_to_integer(reg_number)) after prop_delay; 
			--If a write is being done, the value present on data_in is copied 
			--into register number reg_number
			else
				registers(bv_to_integer(reg_number)) := data_in;
			end if;
		end if;
	end process register_file_process;
end architecture behavior;

-- entity alu (lab 2) 
use work.dlx_types.all; 
use work.bv_arithmetic.all; 

entity alu is 
     generic(prop_delay : Time := 5 ns);
     port(operand1, operand2: in dlx_word; operation: in alu_operation_code; 
          result: out dlx_word; error: out error_code); 
end entity alu; 

-- alu_operation_code values
-- 0000 unsigned add
-- 0001 signed add
-- 0010 2's compl add
-- 0011 2's compl sub
-- 0100 2's compl mul
-- 0101 2's compl divide
-- 0110 logical and
-- 0111 bitwise and
-- 1000 logical or
-- 1001 bitwise or
-- 1010 logical not (op1) 
-- 1011 bitwise not (op1)
-- 1100-1111 output all zeros

-- error code values
-- 0000 = no error
-- 0001 = overflow (too big positive) 
-- 0010 = underflow (too small neagative) 
-- 0011 = divide by zero 

-- architecture alu (lab 2)
architecture behavior of alu is
begin
	alu_process: process(operand1, operand2, operation) is
		--Variables to input into bva operations
		variable op_result: dlx_word;
		variable op_flow: boolean;
		variable zero_error: boolean;
		variable operand1_bool: boolean;
		variable operand2_bool: boolean;
	begin
		--Set/reset some variables
		error <= "0000";
		operand1_bool := false;
		operand2_bool := false;
		--0000 = unsigned add
		if operation = "0000" then
			bv_addu(operand1, operand2, op_result, op_flow);
			if op_flow then
				error <= "0001" after prop_delay;
			end if;
			result <= op_result after prop_delay;
		--0001 = unsigned subtract
		elsif operation = "0001" then
			bv_subu(operand1, operand2, op_result, op_flow);
			if op_flow then 
				error <= "0010" after prop_delay;
			end if;
			result <= op_result after prop_delay;
		--0010 = two's complement add
		elsif operation = "0010" then
			bv_add(operand1, operand2, op_result, op_flow);
			if op_flow then 
				--If you add two positives and get a negative: overflow
				if ((operand1(31) = '0') and (operand2(31) = '0') and (op_result(31) = '1')) then
					error <= "0001" after prop_delay;
				--If you add two negatives and get a positive: underflow
				elsif ((operand1(31) = '1') and (operand2(31) = '1') and (op_result(31) = '0')) then
					error <= "0010" after prop_delay;
				end if;
			end if;
			result <= op_result after prop_delay;
		--0011 = two's complement subtract
		elsif operation = "0011" then 
			bv_sub(operand1, operand2, op_result, op_flow);
			if op_flow then
				--If you subtract a negative from positive and get a negative: overflow
				if ((operand1(31) = '0') and (operand2(31) = '1') and (op_result(31) = '1')) then
					error <= "0001" after prop_delay;	
				--If you subtract a positive from negative and get a positive: underflow
				elsif ((operand1(31) = '1') and (operand2(31) = '0') and (op_result(31) = '0')) then
					error <= "0010" after prop_delay;
				end if;
			end if;
			result <= op_result after prop_delay;
		--0100 = two's complement multiply
		elsif operation = "0100" then 
			bv_mult(operand1, operand2, op_result, op_flow);
		    	if op_flow then
				--If you multiply a positive with a negative and get a positive: underflow
				if ((operand1(31) = '0') and (operand2(31) = '1') and (op_result(31) = '0')) then 	
		    			error <= "0010" after prop_delay;
				elsif ((operand1(31) = '1') and (operand2(31) = '0') and (op_result(31) = '0')) then
			    		error <= "0010" after prop_delay; 
				--If you multiply two positves or negatives and get a negative: overflow
				elsif ((operand1(31) = '0') and (operand2(31) = '0') and (op_result(31) = '1')) then
			   		error <= "0001" after prop_delay; 
				elsif ((operand1(31) = '1') and (operand2(31) = '1') and (op_result(31) = '1')) then
					error <= "0001" after prop_delay;
				end if;
		    	end if;
		    	result <= op_result after prop_delay;
		--0101 = two's complement divide
		elsif operation = "0101" then 
			bv_div(operand1, operand2, op_result, zero_error, op_flow);
			--If you try to divide by zero: divide by zero error
			if zero_error then 
				error <= "0011" after prop_delay;
			end if; 
			if op_flow then 
				error <= "0010" after prop_delay;
			end if;
			result <= op_result after prop_delay;
		--0110 = logical AND
		elsif operation = "0110" then
			--Check if first operand is non-zero
			for i in 0 to 31 loop
				if (operand1(i) = '1') then
					operand1_bool := true;
				end if;
			end loop;
			--Check if second operand is non-zero
			for i in 0 to 31 loop
				if (operand2(i) = '1') then
					operand2_bool := true;
				end if;
			end loop;
			--If both operands are non-zero then result is 1, otherwise 0
			if operand1_bool and operand2_bool then
				result <= x"00000001" after prop_delay;
			else
				result <= x"00000000" after prop_delay;
			end if;
		--0111 = bitwise AND
		elsif operation = "0111" then
			for i in 0 to 31 loop
				op_result(i) := operand1(i) and operand2(i);
			end loop;
			result <= op_result after prop_delay;
		--1000 = logical OR
		elsif operation = "1000" then
			--Check if first operand is non-zero
			for i in 0 to 31 loop
				if (operand1(i) = '1') then
					operand1_bool := true;
				end if;
			end loop;
			--Check if second operand is non-zero
			for i in 0 to 31 loop
				if (operand2(i) = '1') then
					operand2_bool := true;
				end if;
			end loop;
			--If either operand is non-zero then result is 1, otherwise 0
			if operand1_bool or operand2_bool then
				result <= x"00000001" after prop_delay;
			else
				result <= x"00000000" after prop_delay;
			end if;
		--1001 = bitwise OR
		elsif operation = "1001" then
			for i in 0 to 31 loop
				op_result(i) := operand1(i) or operand2(i);
			end loop;
			result <= op_result after prop_delay;
		--1010 = logical NOT of operand1 (ignore operand2)
		elsif operation = "1010" then 
			--Check if operand is non-zero
			for i in 0 to 31 loop
				if (operand1(i) = '1') then
					operand1_bool := true;
				end if;
			end loop;
			--If operand is 0 result is 1, otherwise 0
			if (not operand1_bool) then
				result <= x"00000001" after prop_delay;
			else
				result <= x"00000000" after prop_delay;
			end if;
		--1011 = bitwise NOT of operand1 (ignore operand2)
		elsif operation = "1011" then
			for i in 0 to 31 loop
				op_result(i) := not operand1(i);
			end loop;
			result <= op_result after prop_delay;
		--1100-1111 = just output all zeroes
		else 
			result <= x"00000000" after prop_delay;
		end if;
	end process alu_process;
end architecture behavior;

-- entity dlx_register (lab 3)
use work.dlx_types.all; 

entity dlx_register is
     generic(prop_delay : Time := 5 ns);
     port(in_val: in dlx_word; clock: in bit; out_val: out dlx_word);
end entity dlx_register;

-- architecture dlx_register (lab 3)
architecture behavior of dlx_register is 
begin
	dlx_register_process: process(in_val, clock) is
	begin
		if (clock = '1') then
			out_val <= in_val after prop_delay;
		end if;
	end process dlx_register_process;
end architecture behavior;

-- entity pcplusone
use work.dlx_types.all;
use work.bv_arithmetic.all; 

entity pcplusone is
	generic(prop_delay: Time := 5 ns); 
	port (input: in dlx_word; clock: in bit;  output: out dlx_word); 
end entity pcplusone; 

architecture behavior of pcplusone is 
begin
	plusone: process(input,clock) is  -- add clock input to make it execute
		variable newpc: dlx_word;
		variable error: boolean; 
	begin
	   if clock'event and clock = '1' then
	  	bv_addu(input,"00000000000000000000000000000001",newpc,error);
		output <= newpc after prop_delay; 
	  end if; 
	end process plusone; 
end architecture behavior; 

-- entity mux
use work.dlx_types.all; 

entity mux is
     generic(prop_delay : Time := 5 ns);
     port (input_1,input_0 : in dlx_word; which: in bit; output: out dlx_word);
end entity mux;

architecture behavior of mux is
begin
   muxProcess : process(input_1, input_0, which) is
   begin
      if (which = '1') then
         output <= input_1 after prop_delay;
      else
         output <= input_0 after prop_delay;
      end if;
   end process muxProcess;
end architecture behavior;
-- end entity mux

-- entity threeway_mux 
use work.dlx_types.all; 

entity threeway_mux is
     generic(prop_delay : Time := 5 ns);
     port (input_2,input_1,input_0 : in dlx_word; which: in threeway_muxcode; output: out dlx_word);
end entity threeway_mux;

architecture behavior of threeway_mux is
begin
   muxProcess : process(input_1, input_0, which) is
   begin
      if (which = "10" or which = "11" ) then
         output <= input_2 after prop_delay;
      elsif (which = "01") then 
	 output <= input_1 after prop_delay; 
       else
         output <= input_0 after prop_delay;
      end if;
   end process muxProcess;
end architecture behavior;
-- end entity mux

-- entity memory
use work.dlx_types.all;
use work.bv_arithmetic.all;

entity memory is
  port (
    address : in dlx_word;
    readnotwrite: in bit; 
    data_out : out dlx_word;
    data_in: in dlx_word; 
    clock: in bit); 
end memory;

architecture behavior of memory is
begin  -- behavior
  mem_behav: process(address,clock) is
    -- note that there is storage only for the first 1k of the memory, to speed
    -- up the simulation
    type memtype is array (0 to 1024) of dlx_word;
    variable data_memory : memtype;
  begin
    -- fill this in by hand to put some values in there
    -- some instructions
    data_memory(0) :=  X"30200000"; --LD R4, 0x100
    data_memory(1) :=  X"00000100"; -- address 0x100 for previous instruction
    data_memory(2) :=  "00000000000110000100010000000000"; -- ADDU R3,R1,R2
    -- some data
    -- note that this code runs every time an input signal to memory changes, 
    -- so for testing, write to some other locations besides these
    data_memory(256) := "01010101000000001111111100000000";
    data_memory(257) := "10101010000000001111111100000000";
    data_memory(258) := "00000000000000000000000000000001";
    if clock = '1' then
      if readnotwrite = '1' then
        -- do a read
        data_out <= data_memory(bv_to_natural(address)) after 5 ns;
      else
        -- do a write
        data_memory(bv_to_natural(address)) := data_in; 
      end if;
    end if;
  end process mem_behav; 
end behavior;
-- end entity memory


