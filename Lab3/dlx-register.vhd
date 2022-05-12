--Author:	Mary Mitchell
--Date:		March 17, 2022
--Course:	COMP4300-001
--Program:	This will be used everywhere in the chip that a temporary
--		value could be stored. 

use work.dlx_types.all;
use work.bv_arithmetic.all;

entity dlx_register is 
	generic(prop_delay: time := 10 ns);
	port(in_val: in dlx_word;
	     clock: in bit;
	     out_val: out dlx_word);
end entity dlx_register;

architecture behavior of dlx_register is 
begin
	dlx_register_process: process(in_val, clock) is
	begin
		if (clock = '1') then
			out_val <= in_val after prop_delay;
		end if;
	end process dlx_register_process;
end architecture behavior;