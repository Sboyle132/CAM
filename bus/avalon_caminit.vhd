library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use ieee.std_logic_unsigned.all;

entity avalon_caminit is
	port(
		clk : in std_logic;
		reset : in std_logic;
		avs_s0_writedata : in std_logic_vector(31 downto 0);
		avs_s0_write : in std_logic;
		cam_init : out std_logic
		);
end avalon_caminit;

architecture avalon_caminit_arch of avalon_caminit is

begin

cam_init <= avs_s0_write; -- Ensure single clock cycle, controlled via avalon.

end avalon_caminit_arch;
	