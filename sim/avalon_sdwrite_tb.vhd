library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

library work;
use work.all;




entity avalon_sdwrite_tb is
--  Port ( );
end avalon_sdwrite_tb;

architecture Behavioral of avalon_sdwrite_tb is



COMPONENT avalon_sdwrite is
	port(
		clk : in std_logic;
		reset : in std_logic;
		
		--Avalon
		
		avm_m0_read : out std_logic;
		avm_m0_write : out std_logic;
		avm_m0_writedata : out std_logic_vector(255 downto 0);
		avm_m0_address : out std_logic_vector(31 downto 0);
		avm_m0_readdata : in std_logic_vector(255	downto 0);
		avm_m0_readdatavalid : in std_logic;
		avm_m0_byteenable : out std_logic_vector(31 downto 0);
		avm_m0_waitrequest : in std_logic;
		avm_m0_burstcount : out std_logic_vector(10 downto 0);
		
		--FPGA
		sdram_write : in std_logic;
		sdram_address : in std_logic_vector(31 downto 0);
		sdram_data : in std_logic_vector(31 downto 0);		
		
		--Debug
		bad_counter : out std_logic_vector(7 downto 0)
		);
end COMPONENT;

signal clk : std_logic := '0';
signal reset: std_logic := '0';
-- Avalon
signal avm_m0_read : std_logic;
signal avm_m0_write : std_logic;
signal avm_m0_writedata : std_logic_vector(255 downto 0);
signal avm_m0_address : std_logic_vector(31 downto 0);
signal avm_m0_readdata : std_logic_vector(255 downto 0);
signal avm_m0_byteenable : std_logic_vector(31 downto 0);
signal avm_m0_burstcount : std_logic_vector(10 downto 0);
signal avm_m0_waitrequest : std_logic;
signal avm_m0_readdatavalid : std_logic;
--Input
signal sdram_write : std_logic;
signal sdram_address : std_logic_vector(31 downto 0);
signal sdram_data : std_logic_vector(31 downto 0);

--debug
signal bad_counter : std_logic_vector(7 downto 0);

constant ClockPeriod : time := 10ns;
constant Clockfreq : integer := 50000000;

begin
SDWRITE_INST : avalon_sdwrite
        port map( 
				reset => reset,
            clk => clk,
            avm_m0_read => avm_m0_read,
				avm_m0_write => avm_m0_write,
				avm_m0_writedata => avm_m0_writedata,
				avm_m0_address => avm_m0_address,
				avm_m0_readdata => avm_m0_readdata,
				avm_m0_readdatavalid => avm_m0_readdatavalid,
				avm_m0_byteenable => avm_m0_byteenable,
				avm_m0_waitrequest => avm_m0_waitrequest,
				avm_m0_burstcount => avm_m0_burstcount,
				sdram_write => sdram_write,
				sdram_address => sdram_address,
				sdram_data => sdram_data,
				bad_counter => bad_counter
            );
				
clk <= not clk after ClockPeriod/2;


stimuli : process
    begin
		reset <= '1';
      wait for ClockPeriod;
      reset <= '0';
		wait for ClockPeriod;
		sdram_write <= '1';
		sdram_address <= x"20000000";
		sdram_data <= x"AAAAAAAA";
		wait for ClockPeriod;
		sdram_write <= '0';
		avm_m0_waitrequest <= '1';
		wait for ClockPeriod;
		avm_m0_waitrequest <= '0';
		wait for ClockPeriod;
		sdram_write <= '1';
		sdram_address <= x"20000000";
		sdram_data <= x"AAAAAAAA";
		wait for ClockPeriod;
		avm_m0_waitrequest <= '1';
		wait for ClockPeriod * 100;
	   end process stimuli;
end Behavioral;