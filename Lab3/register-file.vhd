--Author:	Mary Mitchell
--Date:		March 17, 2022
--Course:	COMP4300-001
--Program:	The register file consists of 32 registers numbered 0-31. In a given
--		clock cycle one value can be read or one value can be written (not both).

use work.dlx_types.all;
use work.bv_arithmetic.all;

entity reg_file is 
	generic(prop_delay: time := 10 ns);
	port(data_in: in dlx_word; 
	     readnotwrite, clock: in bit;
	     data_out: out dlx_word;
	     reg_number: in register_index);
end entity reg_file;

architecture behavior of reg_file is
	type reg_type is array (0 to 31) of dlx_word;
begin
	register_file_process: process(data_in, readnotwrite, clock, reg_number) is
	variable registers : reg_type;
	begin 
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