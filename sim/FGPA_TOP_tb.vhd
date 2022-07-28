library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

library work;
use work.all;




entity FPGA_TOP_tb is
--  Port ( );
end FPGA_TOP_tb;

architecture Behavioral of FPGA_TOP_tb is



COMPONENT FPGA_TOP is
	port (
	rst_n : in std_logic;
	clk : in std_logic; -- 50 Mhz
	led : out std_logic_vector(7 downto 0);
	cam_scl : inout std_logic;
	cam_sdata : inout std_logic;
	cam_reset : out std_logic;
	cam_pwdn : out std_logic;
	cam_xclk : out std_logic;
	cam_data : in std_logic_vector(9 downto 0);
	cam_pclk : in std_logic;
	cam_href : in std_logic;
	cam_vsync : in std_logic
	
	);
END COMPONENT;

signal clk : std_logic := '0';
signal rst_n : std_logic := '0';
signal led : std_logic_vector(7 downto 0) := x"00";
signal cam_scl : std_logic := 'H';
signal cam_sdata : std_logic := 'H';
signal cam_reset : std_logic := '0';
signal cam_pwdn : std_logic := '0';
signal cam_xclk : std_logic := '0';
signal cam_data : std_logic_vector(9 downto 0);
signal cam_pclk : std_logic;
signal cam_href : std_logic;
signal cam_vsync : std_logic;



constant ClockPeriod : time := 10ns;
constant Clockfreq : integer := 50000000;

begin
FPGA_INST : FPGA_TOP
        port map( 
            rst_n => rst_n,
            clk => clk,
            led => led,
				cam_scl => cam_scl,
				cam_sdata => cam_sdata,
				cam_reset => cam_reset,
				cam_pwdn => cam_pwdn,
				cam_xclk => cam_xclk,
				cam_data => cam_data,
				cam_pclk => cam_pclk,
				cam_href => cam_href,
				cam_vsync => cam_vsync
				
            );
				
clk <= not clk after ClockPeriod/2;

-- SCCB in I2C Mode 
cam_sdata <= 'H';
cam_scl <= 'H';

stimuli : process
    begin
		rst_n <= '0';
      wait for ClockPeriod;
      rst_n <= '1';
		wait for ClockPeriod * Clockfreq * 10; 
	 
	   end process stimuli;

end Behavioral;
	 
	 
	 
	 
	 
	 
	 
	 
	 
	 
	 
	 
	 
	 