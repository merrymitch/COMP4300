--Mary Mitchell
--Lab 1: One-bit Full Adder
--Created: 02/09/2022

entity adder is
	generic(prop_delay: Time := 10 ns);
	port(carry_in,a_in,b_in: in bit;
		result,carry_out: out bit);
end entity adder;

architecture behavior1 of adder is 
begin
	adderProcess : process(carry_in,a_in,b_in) is
	
	begin
		if carry_in = '0' then
			if a_in = '0' then 
				if b_in = '0' then
					--000
					result <= '0' after prop_delay;
					carry_out <= '0' after prop_delay;
				else 
					--001
					result <= '1' after prop_delay;
					carry_out <= '0' after prop_delay;
				end if;
			else
				if b_in = '0' then 
					--010
					result <= '1' after prop_delay;
					carry_out <= '0' after prop_delay;
				else 
					--011
					result <= '0' after prop_delay;
					carry_out <= '1' after prop_delay;
				end if;
			end if;
		else 
			if a_in = '0' then 
				if b_in = '0' then
					--100
					result <= '1' after prop_delay;
					carry_out <= '0' after prop_delay;
				else 
					--101
					result <= '0' after prop_delay;
					carry_out <= '1' after prop_delay;
				end if;
			else 
				if b_in = '0' then
					--110
					result <= '0' after prop_delay;
					carry_out <= '1' after prop_delay;
				else 
					--111
					result <= '1' after prop_delay;
					carry_out <= '1' after prop_delay;
				end if;
			end if;
		end if;
	end process adderProcess;
end architecture behavior1;