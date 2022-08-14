library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

library work;
use work.all;




entity SVGA_CONTROLLER_TB is
--  Port ( );
end SVGA_CONTROLLER_TB;

architecture Behavioral of SVGA_CONTROLLER_TB is

COMPONENT svga_controller is
	generic ( 
			mclk_freq : integer
	);
	port(
	  -- FPGA internal
    rst : in std_logic;
    clk : in std_logic;
	 
	 --For FPGA to SDRAM write
	 word_o : out std_logic_vector(31 downto 0); --Make sure to buffer this from above.
	 word_send : out std_logic;
	 word_address : out std_logic_vector(31 downto 0);

	 --For HPS to FPGA write
	 burst_size : in std_logic_vector(31 downto 0);
	 burst_address : in std_logic_vector(31 downto 0);
	 burst_start : in std_logic;
	 
	 --HPS to FPGA read / Poll
	 transfer_complete : out std_logic;

	 -- Interface
	 mclk : out std_logic;
	 data_i : in std_logic_vector(9 downto 0);
	 HREF : in std_logic;
	 MHSYNC : out std_logic;
	 MVSYNC : out std_logic;
	 
	 --debug
	 sampled_out : out std_logic_vector(15 downto 0);
	 mode : in std_logic
    );
END COMPONENT;

signal clk : std_logic := '0';
signal rst : std_logic := '0';
signal burst_start : std_logic;
signal burst_address : std_logic_vector(31 downto 0);
signal burst_size : std_logic_vector(31 downto 0);
signal word_o : std_logic_vector(31 downto 0);
signal word_send : std_logic;
signal word_address : std_logic_vector(31 downto 0);
signal transfer_complete : std_logic;
signal mclk : std_logic;
signal data_i : std_logic_vector(9 downto 0);
signal HREF : std_logic;
signal MHSYNC : std_logic;
signal mode : std_logic;
signal MVSYNC : std_logic;
signal sampled_out : std_logic_vector(15 downto 0);


constant ClockPeriod : time := 10ns;
constant Clockfreq : integer := 672*1190*2;

begin

SVGA_CONTROLLER0 : SVGA_CONTROLLER
		generic map(
			mclk_freq => 25000000 
		)
		PORT MAP (
			clk => clk,
			rst => rst,
			word_o => word_o,
			word_send => word_send,
			word_address => word_address,
			data_i => data_i,
			mclk => mclk,
			HREF => HREF,
			MHSYNC => MHSYNC,
			MVSYNC => MVSYNC,
			mode => mode,
			transfer_complete => transfer_complete,
			burst_size => burst_size,
			burst_address => burst_address,
			burst_start => burst_start,
			sampled_out => sampled_out
			
			
			
		);
		
		
				
clk <= not clk after ClockPeriod/2;

stimuli : process
    begin
		rst <= '1';
      wait for ClockPeriod;
      rst <= '0';
		wait for ClockPeriod; 
		burst_size <= x"00000005";
		burst_address <= x"30000000";
		mode <= '0';
		data_i <= "1111000000";
		wait for ClockPeriod * 1; 
		burst_start <= '1';
		wait for ClockPeriod * 1000;
		burst_start <= '0';
		wait for ClockPeriod * Clockfreq * 5;
		data_i <= "1111111100";
		wait for ClockPeriod * 1000;
		wait for ClockPeriod * Clockfreq;
		burst_size <= x"00000002";
		data_i <= "1010101000";
		burst_start <= '1';
		wait for ClockPeriod * 1000;
		burst_start <= '0';
		wait for ClockPeriod * Clockfreq * 2;
		wait for ClockPeriod * Clockfreq * 2;
	   end process stimuli;

end Behavioral;
	 
	 