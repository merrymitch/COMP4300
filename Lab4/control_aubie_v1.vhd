-- Author: Mary Mitchell
-- Course: COMP 4300-001
-- Date:   4/22/2022

use work.bv_arithmetic.all; 
use work.dlx_types.all; 

entity aubie_controller is
	generic(prop_delay: time := 5 ns;
		prop_delay2: time := 10 ns
		);
	port(ir_control: in dlx_word;
	     alu_out: in dlx_word; 
	     alu_error: in error_code; 
	     clock: in bit; 
	     regfilein_mux: out threeway_muxcode; 
	     memaddr_mux: out threeway_muxcode; 
	     addr_mux: out bit; 
	     pc_mux: out bit; 
	     alu_func: out alu_operation_code; 
	     regfile_index: out register_index;
	     regfile_readnotwrite: out bit; 
	     regfile_clk: out bit;   
	     mem_clk: out bit;
	     mem_readnotwrite: out bit;  
	     ir_clk: out bit; 
	     imm_clk: out bit; 
	     addr_clk: out bit;  
             pc_clk: out bit; 
	     op1_clk: out bit; 
	     op2_clk: out bit; 
	     result_clk: out bit
	     ); 
end aubie_controller; 

architecture behavior of aubie_controller is
begin
	behav: process(clock) is 
		type state_type is range 1 to 20; 
		variable state: state_type := 1; 
		variable opcode: byte; 
		variable destination,operand1,operand2 : register_index; 

	begin
		if clock'event and clock = '1' then
		   opcode := ir_control(31 downto 24);
		   destination := ir_control(23 downto 19);
		   operand1 := ir_control(18 downto 14);
		   operand2 := ir_control(13 downto 9); 
		   case state is
			when 1 => -- fetch the instruction, for all types
				-- your code goes here
				-- Mem[PC] -> InstrReg
				mem_readnotwrite <= '1' after prop_delay; -- Set because we are doing a read from mem
				memaddr_mux <= "00" after prop_delay; -- Need the value from PC: mux selects 0
				--addr_mux <= '1' after prop_delay; -- Select 1 for mem_out
				mem_clk <= '1' after prop_delay; -- The clock goes to 1 to read the value
				ir_clk <= '1' after prop_delay; -- The clock goes to 1 to update value in instruction register
				state := 2; -- Move to state 2
			when 2 =>  
				-- figure out which instruction
			 	if opcode(7 downto 4) = "0000" then -- ALU op
					state := 3; 
				elsif opcode = X"20" then  -- STO 
					state := 9;
				elsif opcode = X"30" or opcode = X"31" then -- LD or LDI
					state := 7;
				elsif opcode = X"22" then -- STOR
					state := 14;
				elsif opcode = X"32" then -- LDR
					state := 12;
				elsif opcode = X"40" or opcode = X"41" then -- JMP or JZ
					state := 16;
				elsif opcode = X"10" then -- NOOP
					state := 19;
				else -- error
				end if; 
			when 3 => 
				-- ALU op:  load op1 register from the regfile
				-- your code here 
				-- Regs[IR[op1]] -> Op1
				regfile_readnotwrite <= '1' after prop_delay; -- Set because we are doing a read from regfile
				regfile_index <= operand1 after prop_delay; -- Get operand 1
				regfile_clk <= '1' after prop_delay; -- The clock goes to 1 to read the value from regfile
				op1_clk <= '1' after prop_delay; -- The clock goes to 1 to update the value in Op1
				state := 4; -- Move to state 4
			when 4 => 
				-- ALU op: load op2 registear from the regfile 
				-- your code here
				-- Regs[IR[op2]] -> Op2
				regfile_readnotwrite <= '1' after prop_delay; -- Set because we are doing a read from regfile
				regfile_index <= operand2 after prop_delay; -- Get operand 2
				regfile_clk <= '1' after prop_delay; -- The clock goes to 1 to read the value from regfile
				op2_clk <= '1' after prop_delay; -- The clock goes to 1 to update the value in Op2
         			state := 5; 
			when 5 => 
				-- ALU op:  perform ALU operation
				-- your code here
				-- ALUout -> Result
				alu_func <= opcode(3 downto 0) after prop_delay; -- Get the opcode: only need last 4 bits
				result_clk <= '1' after prop_delay; -- The clock goes to 1 to allow alu_out to update result	
				state := 6; -- Move to state 6
			when 6 => 
				-- ALU op: write back ALU operation
				-- your code here
				-- Result -> Regs[IR[dest]]; PC + 1 -> PC
				regfile_readnotwrite <= '0' after prop_delay; -- Not set because we are doing a write to regfile
				regfilein_mux <= "00" after prop_delay; -- Select 0 to pass rsult_out through mux
				regfile_index <= destination after prop_delay; -- Get the destination of the result
				regfile_clk <= '1' after prop_delay; -- The clock goes to 1 to update the result into regfile
				pc_mux <= '0' after prop_delay; -- Select 0 for pcplusone to pass through mux
				pc_clk <= '1' after prop_delay; -- The clock goes to 1 to update the PC
           			state := 1; -- Move to state 0 
			when 7 => 
				-- LD or LDI: get the addr or immediate word
			   	-- your code here
				-- PC + 1 -> PC 
				pc_mux <= '0' after prop_delay; -- Select 0 for pcplusone to pass through mux
				pc_clk <= '1' after prop_delay; -- The clock goes to 1 to update the PC
				-- Mem[PC] -> Addr
				if opcode = X"30" then -- If this is a LD instuction
					mem_readnotwrite <= '1' after prop_delay; -- Set because we are doing a read from mem
					memaddr_mux <= "00" after prop_delay; -- Select 0 to get value from PC
					mem_clk <= '1' after prop_delay; -- The clock goes to 1 to read value from memory
					addr_mux <= '1' after prop_delay; -- Select 1 to get mem_out
					addr_clk <='1' after prop_delay; -- The clock goes to 1 to update value in addr
				-- Mem[PC] -> Immed
				elsif opcode = X"31" then -- If this is a LDI instruction
					mem_readnotwrite <= '1' after prop_delay; -- Set because we are doing a read from mem
					memaddr_mux <= "00" after prop_delay; -- Select 0 to get value from PC
					mem_clk <= '1' after prop_delay; -- The clock goes to 1 to read value from memory
					imm_clk <= '1' after prop_delay; -- The clock goes to 1 to update value in immediate
				end if;
				state := 8; -- Move to state 8
			when 8 => 
				-- LD or LDI
				-- your code here
				-- Mem[Addr] -> Regs[IR[dest]]
				if opcode = X"30" then -- If this is a LD instuction
					mem_readnotwrite <= '1' after prop_delay; -- Set because we are doing a read from mem
					memaddr_mux <= "01" after prop_delay; -- Select 1 to get value from addr register
					mem_clk <= '1' after prop_delay; -- The clock goes to 1 to read value from memory
					regfile_readnotwrite <= '0' after prop_delay; -- Not set because we are doing a write to regfile
					regfile_index <= destination after prop_delay; -- Get the destination of the write
					regfilein_mux <= "01" after prop_delay; -- Select 1 to get value from mem_out
					regfile_clk <= '1' after prop_delay; -- The clock goes to 1 to update value in regfile
				-- Immed -> Regs[IR[dest]]
				elsif opcode = X"31" then -- If this is a LDI instruction
					regfile_readnotwrite <= '0' after prop_delay; -- Not set because we are doing a write to regfile
					regfile_index <= destination after prop_delay; -- Get the destination of the write
					imm_clk <= '1' after prop_delay; -- The clock goes to 1 to get value from immed register
					regfilein_mux <= "10" after prop_delay; -- Select 2 to get value from immed register
					regfile_clk <= '1' after prop_delay; -- The clock goes to 1 to update value in regfile
				end if;
				-- PC + 1 -> PC
				pc_mux <= '0' after prop_delay; -- Select 0 for pcplusone to pass through mux
				pc_clk <= '1' after prop_delay; -- The clock goes to 1 to update the PC
        			state := 1; -- Move to state 1
			
				-- EXTRA CREDIT: *** Fully test if there is time ***	
			when 9 =>
				-- STO (EXTRA CREDIT): Increment PC
				-- your code here
				-- PC + 1 -> PC
				pc_mux <= '0' after prop_delay; -- Select 0 for pcplusone to pass through mux
				pc_clk <= '1' after prop_delay; -- The clock goes to 1 to update the PC
				state := 10; -- Move to state 10
			when 10 =>
				-- STO (EXTRA CREDIT): Load memory at address given by PC to the Addr register
				-- your code here
				-- Mem[PC] -> Addr
				mem_readnotwrite <= '1' after prop_delay; -- Set because we are doing a read from mem
				memaddr_mux <= "00" after prop_delay; -- Select 0 to get value from PC
				mem_clk <= '1' after prop_delay; -- The clock goes to 1 to read value from memory
				addr_mux <= '1' after prop_delay; -- Select 1 to get mem_out
				addr_clk <='1' after prop_delay; -- The clock goes to 1 to update value in addr
				state := 11; -- Move to state 11
			when 11 =>
				-- STO (EXTRA CREDIT): Store contents src register to address in memory given by Addr; Increment PC
				-- your code here
				-- Regs[IR[src]] -> Mem[Addr]; PC + 1 -> PC
				regfile_readnotwrite <= '1' after prop_delay; -- Set because we are doing a read from regfile
				regfile_index <= operand1 after prop_delay; -- Get operand1: what we are reading
				regfile_clk <= '1' after prop_delay; -- The clock goes to 1 to read the value
				mem_readnotwrite <= '0' after prop_delay; -- Not set because we are doing a write to mem
				pc_mux <= '1' after prop_delay, '0' after prop_delay2; -- Select 1 to get value from addr register
				pc_clk <= '1' after prop_delay; -- The clock goes to 1 to update value in PC
				memaddr_mux <= "00" after prop_delay; -- Select 0 to get value from PC
				mem_clk <= '1' after prop_delay; -- The clock goes to 1 to update value in memory
				state := 1; -- Move to state 1
			when 12 =>
				-- LDR (EXTRA CREDIT): copy op1 reg to Addr
				-- your code here
				-- Regs[IR[op1]] -> Addr
				regfile_readnotwrite <= '1' after prop_delay; -- Set because we are doing a read from regfile
				regfile_index <= operand1 after prop_delay; -- Set index to be operand1
				regfile_clk <= '1' after prop_delay; -- The clock goes to 1 to read value from regfile
				addr_mux <= '0' after prop_delay; -- Select 0 to get value from regfile
				addr_clk <= '1' after prop_delay; -- The clock goes to 1 to update value in addr register
				state := 13; -- Move to state 13
			when 13 =>
				-- LDR (EXTRA CREDIT): copy contents of memory addr to dest register; increment PC
				-- your code here
				-- Mem[Addr] -> Regs[IR[dest]]; PC + 1 -> PC
				mem_readnotwrite <= '1' after prop_delay; -- Set because we are doing a read from mem
				memaddr_mux <= "01" after prop_delay; -- Select 1 to get value from addr register
				mem_clk <= '1' after prop_delay; -- The clock goes to 1 to read value
				regfile_index <= destination after prop_delay; -- Get destination of the value
				regfile_readnotwrite <= '0' after prop_delay; -- Not set because we are doing a write to regfile
				regfilein_mux <= "01" after prop_delay; -- Select 1 to get value from mem_out
				regfile_clk <= '1' after prop_delay; -- The clock goes to 1 to update value in regfile
				pc_mux <= '0' after prop_delay; -- Select 0 for pcplusone to pass through mux
				pc_clk <= '1' after prop_delay; -- The clock goes to 1 to update the PC
				state := 1; -- Move to state 1
			when 14 =>
				-- STOR (EXTRA CREDIT): copy contents of dest register to addr register
				-- your code here
				-- Regs[IR[dest]] -> Addr
				regfile_readnotwrite <= '1' after prop_delay; -- Set because we are reading from regfile
				regfile_index <= destination after prop_delay; -- Set index to be destination
				regfile_clk <= '1' after prop_delay; -- The clock goes to 1 to read the value
				addr_mux <= '0' after prop_delay; -- Select 0 to get value from regfile
				addr_clk <= '1' after prop_delay; -- The clock goes to 1 to update value in addr register
				state := 15; -- Move to state 15
			when 15 =>
				-- STOR (EXTRA CREDIT): copy contents of op1 register to mem addr
				-- your code here
				-- Regs[IR[op1]] -> Mem[Addr]; PC + 1 -> PC
				regfile_readnotwrite <= '1' after prop_delay; -- Set because we are doing a read from regfile
				regfile_index <= operand1 after prop_delay; -- Set index to be operand1
				regfile_clk <= '1' after prop_delay; -- The clock goes to 1 to read value from regfile
				mem_readnotwrite <= '0' after prop_delay; -- Not set because we are doing a write to mem
				memaddr_mux <= "01" after prop_delay; -- Select 1 to get value from addr
				mem_clk <= '1' after prop_delay; -- The clock goes to 1 to update value in mem
				pc_mux <= '0' after prop_delay; -- Select 0 for pcplusone to pass through mux
				pc_clk <= '1' after prop_delay; -- The clock goes to 1 to update the PC
				state := 1; -- Move to state 1
			-- Jumps (EXTRA CREDIT) *** Complete and test if there is time ***
			when 16 =>
				state := 17;
			when 17 =>
				state := 18;
			when 18 =>
				state := 1;
			when 19 =>
				-- NOOP: PC + 1 -> PC
				-- your code here
				pc_mux <= '0'; -- Select 0 for pcplusone to pass through mux
				pc_clk <= '1'; -- The clock goes to 1 to update the PC
				state := 1; -- Move to state 1
			when others => null; 
		   end case; 
		elsif clock'event and clock = '0' then
			-- reset all the register clocks
			-- your code here	
			regfile_clk <= '0';
			mem_clk <= '0';
			ir_clk <= '0';
			imm_clk <= '0';
			addr_clk <= '0';
			pc_clk <= '0';
	    		op1_clk <= '0';
	    		op2_clk <= '0';
	    		result_clk <= '0';
		end if; 
	end process behav;
end behavior;	