library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

library work;
use work.all;




entity CAM_INIT_tb is
--  Port ( );
end CAM_INIT_tb;

architecture Behavioral of CAM_INIT_tb is

COMPONENT CAM_INIT is
	 generic (
				sccb_frequency : integer
				);
    port(
    rst : in std_logic;
    clk : in std_logic;
    cam_initialise : in std_logic;
    sccb_scl : out std_logic;
	 sccb_sdata : inout std_logic;
	 sccb_odata : out std_logic_vector(7 downto 0)
);
END COMPONENT;

signal clk : std_logic := '0';
signal rst : std_logic := '0';
signal cam_scl : std_logic := 'H';
signal cam_sdata : std_logic := 'H';
signal cam_odata : std_logic_vector(7 downto 0);
signal cam_initialise : std_logic;


constant ClockPeriod : time := 10ns;
constant Clockfreq : integer := 50000000;

begin

CAM_INIT0 : CAM_INIT
		generic map(
			sccb_frequency => 400000 
		)
		PORT MAP (
			clk => clk,
			rst => rst,
			cam_initialise => cam_initialise,
			sccb_sdata => cam_sdata,
			sccb_scl => cam_scl,
			sccb_odata => cam_odata
			
		);
				
clk <= not clk after ClockPeriod/2;

-- SCCB in I2C Mode 
cam_sdata <= 'H';
--cam_scl <= 'H';


stimuli : process
    begin
		rst <= '1';
      wait for ClockPeriod;
      rst <= '0';
		wait for ClockPeriod * 10; 
		cam_initialise <= '1';
		wait for ClockPeriod * 1;
		cam_initialise <= '0';
		wait for ClockPeriod * Clockfreq * 10;
	   end process stimuli;

end Behavioral;
	 
	 