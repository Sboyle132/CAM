library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use ieee.std_logic_unsigned.all;

entity avalon_read is
	port(
		clk : in std_logic;
		reset : in std_logic;
		avs_s0_readdata : out std_logic_vector(31	downto 0);
		avs_s0_read : in std_logic;
		svga_complete : in std_logic
		);
end avalon_read;

architecture avalon_read_arch of avalon_read is
begin

--with avs_s0_read select avs_s0_readdata <=
--	x"0000000" & "000" & svga_complete when '1',
--	x"00000000" when others;
	
process(avs_s0_read)
begin

	case avs_s0_read is
		when '1' =>
			avs_s0_readdata <= x"0000000" & "000" & svga_complete;
		when others =>
			avs_s0_readdata <= x"00000000";
	end case;

end process;

--when '1' =>
--	avs_s0_readdata <= 
--when '0' =>
--	avs_s0_readdata <= x"00000000";
--when others =>
--	avs_s0_readdata <= x"00000000";
--end case;
-- with scl_gen OR not_start select sclk <=
--		'Z' when '1',
--		'0' when '0',
--		'Z' when others;



end avalon_read_arch;
	
	