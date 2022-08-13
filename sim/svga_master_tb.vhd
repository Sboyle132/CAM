library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

library work;
use work.all;




entity SVGA_MASTER_TB is
--  Port ( );
end SVGA_MASTER_TB;

architecture Behavioral of SVGA_MASTER_TB is

COMPONENT svga_master is
	generic ( 
			mclk_freq : integer
	);
	port(
	 -- FPGA internal
    rst : in std_logic;
    clk : in std_logic;
	 enable : in std_logic;
	 data_o : out std_logic_vector(9 downto 0);
	 data_valid : out std_logic;
	 continue : in std_logic;
	 frame_valid : out std_logic;
	 frame_end : out std_logic;
	 
	 -- Interface
	 mclk : out std_logic;
	 data_i : in std_logic_vector(9 downto 0);
	 HREF : in std_logic;
	 MHSYNC : out std_logic;
	 MVSYNC : out std_logic
    );
END COMPONENT;

signal clk : std_logic := '0';
signal rst : std_logic := '0';
signal enable : std_logic := '0';
signal data_o : std_logic_vector(9 downto 0);
signal data_valid : std_logic;
signal mclk : std_logic;
signal data_i : std_logic_vector(9 downto 0);
signal HREF : std_logic;
signal MHSYNC : std_logic;
signal MVSYNC : std_logic;
signal continue : std_logic;
signal frame_valid : std_logic;
signal frame_end : std_logic;

constant ClockPeriod : time := 10ns;
constant Clockfreq : integer := 672*1190*2;

begin

SVGA_MASTER0 : SVGA_MASTER
		generic map(
			mclk_freq => 25000000 
		)
		PORT MAP (
			clk => clk,
			rst => rst,
			enable => enable,
			data_o => data_o,
			data_valid => data_valid,
			mclk => mclk,
			data_i => data_i,
			HREF => HREF,
			MHSYNC => MHSYNC,
			MVSYNC => MVSYNC,
			continue => continue,
			frame_valid => frame_valid,
			frame_end => frame_end
		);
		
		
				
clk <= not clk after ClockPeriod/2;

stimuli : process
    begin
		rst <= '1';
      wait for ClockPeriod;
      rst <= '0';
		wait for ClockPeriod * 10; 
		continue <= '1';
		data_i <= "11" & x"11";
		enable <= '1';
		wait for ClockPeriod * 1;
		enable <= '0';
		wait for ClockPeriod * Clockfreq;
		continue <= '0';
		wait for ClockPeriod * 1000;
		wait for ClockPeriod * Clockfreq * 2;
		continue <= '1';
		wait for ClockPeriod * Clockfreq * 2;
	   end process stimuli;

end Behavioral;
	 
	 