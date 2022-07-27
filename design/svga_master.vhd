
-- General idea : - Bring in SCL_GEN at 4 CLK - 80 NS per clock
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use ieee.std_logic_unsigned.all;
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity svga_master is
generic ( 
			threshold : integer := 4
);
port(
	 -- FPGA internal
    rst : in std_logic;
    clk : in std_logic;
	 enable : in std_logic;
	 data_o : out std_logic_vector(9 downto 0);
	 data_valid : out std_logic;
	 
	 -- Inteface
	 mclk : out std_logic;
	 data_i : in std_logic_vector(9 downto 0);
	 HREF : in std_logic;
	 MHSYNC : out std_logic;
	 MVSYNC : out std_logic
	 
    );
end svga_master;

--So VSYNC, while HSYNC, then HREF means data valid. In this case, we should have data_valid signal out.
-- Hsync time - 1190 total, 80 Sync, 179 Front porch, 800 Href, 131 back porch.
-- Vsync time - 73895 front porch, 4 * Hsync is Vsync, 1190 * 800 Vref, 7415 back porch - apparently 672 * Hsync but doesn't make sense
-- Frame time - Vsync time * 600