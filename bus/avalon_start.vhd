library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use ieee.std_logic_unsigned.all;

entity avalon_start is
	port(
		clk : in std_logic;
		reset : in std_logic;
		avs_s0_writedata : in std_logic_vector(63 downto 0);
		avs_s0_write : in std_logic;
		svga_start : out std_logic;
		svga_burst : out std_logic_vector(31 downto 0);
		svga_addr  : out std_logic_vector(31 downto 0)
		);
end avalon_start;

architecture avalon_start_arch of avalon_start is

begin

svga_start <= avs_s0_write; -- Ensure single clock cycle, controlled via avalon.
svga_addr <= avs_s0_writedata(31 downto 0);
svga_burst <= avs_s0_writedata(63 downto 32);

end avalon_start_arch;
	
