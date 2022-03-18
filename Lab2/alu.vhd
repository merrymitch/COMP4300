--Author:   Mary Mitchell
--Course:   COMP4300-001
--Due Date: March 2, 2022
--Program:  Arithmetic-Logic Unit - This unit takes in two 32-bit values,
--	    and a 4-bit operation code that specifies which ALU operation
--          is to be performed on the two operands.

use work.dlx_types.all;
use work.bv_arithmetic.all;

entity alu is
	generic(prop_delay: time := 15 ns);
	port(operand1, operand2: in dlx_word; operation: in alu_operation_code;
	     result: out dlx_word; error: out error_code);
end entity alu;

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
