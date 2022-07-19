----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 05/20/2022 10:31:58 AM
-- Design Name: 
-- Module Name: shiftreg_tb - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

library work;
use work.all;
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;



entity i2c_master_tb is
--  Port ( );
end i2c_master_tb;

architecture Behavioral of i2c_master_tb is



COMPONENT i2c_master is
    port(
    rst : in std_logic;
    clk : in std_logic;
    dev : in std_logic_vector(6 downto 0);
    dev_reg : in std_logic_vector(7 downto 0);
    data_w : in std_logic_vector( 7 downto 0);
    o_data : out std_logic_vector(7 downto 0);
    r_w : in std_logic;
    enable : in std_logic;
    sclk : out std_logic;
    sdata : inout std_logic
);



END COMPONENT;


signal clk : std_logic := '0';
signal rst : std_logic := '0';
signal addr_reg : std_logic_vector(7 downto 0); -- Could add extra variable here
signal data_reg : std_logic_vector(7 downto 0);
signal enable : std_logic;
signal rw : std_logic;
signal o_data : std_logic_vector(7 downto 0);
signal o_busy : std_logic;
signal mosi_miso :  std_logic;
signal dev : std_logic_vector(6 downto 0);
signal scl : std_logic;
signal driver : std_logic;



constant ClockPeriod : time := 10ns;
begin

i2c_m : i2c_master
        PORT MAP (
          clk => clk,
          rst => rst,
          r_w => rw,
          dev_reg => addr_reg,
          data_w => data_reg,
          o_data => o_data,
          enable => enable,
          sdata => mosi_miso,
          sclk => scl,
          dev => dev
        );

clk <= not clk after ClockPeriod/2;

--mosi_miso <= 'H';
    stimuli : process
    begin
        driver <= 'Z';
        mosi_miso <= 'Z';
        rst <= '1';
        wait for ClockPeriod;
        rst <= '0'; 
        wait for ClockPeriod;
      --  rw <= '1';
       -- addr <= "1010101";
     --   data <= "10101010";
        
        enable <= '1';
        addr_reg <= "10111010";
        dev <= "0101011";
        data_reg <= "10101010";
       
        rw <= '0';
        wait for ClockPeriod;
        enable <= '0';
        wait for ClockPeriod *16*9; --*2;
        wait for ClockPeriod * 7;
        mosi_miso <= '0';
        driver <= '0';
        wait for ClockPeriod * 16;  -- these 16s can be replaced by generics.;
        mosi_miso <= 'Z';
        driver <= 'Z';
        wait for ClockPeriod *16*8;
        mosi_miso <= '0';
        driver <= '0';
        wait for ClockPeriod * 16;
        mosi_miso <= 'Z';
        driver <= 'Z';
     --   addr <= "0000001";
     --   data <= "00000000";
     --   miso <= '1';
        wait for ClockPeriod*16*8;
        mosi_miso <= '0';
        driver <= '0';
        wait for ClockPeriod * 16;
        mosi_miso <= 'Z';
        driver <= 'Z';
        wait for ClockPeriod*16*2;

        rw <= '0';
        enable <= '1';

        wait for ClockPeriod;
        
--        enable <= '0';
--        wait for ClockPeriod *16*8;

--        wait for ClockPeriod *16;
--     --   miso <= '1';
--        wait for ClockPeriod *16;
--     --   miso <= '1';
--        wait for ClockPeriod *16;
--        miso <= '0';
--        wait for ClockPeriod *16;
--        miso <= '1';
--        wait for ClockPeriod *16;
--        miso <= '0';
--        wait for ClockPeriod *16;
--        miso <= '1';
--        wait for ClockPeriod *16;
--        miso <= '1';
--        wait for ClockPeriod *16;
--        wait for ClockPeriod *16;
--        wait for ClockPeriod *16;
--        wait for ClockPeriod * 4;
--        addr <= "0011001";
--        data <= "00000000";
--        miso <= '0';
--        rw <= '0';
--        enable <= '1';

--        wait for ClockPeriod;
        
--        enable <= '0';
--        wait for ClockPeriod *16*8;

--        wait for ClockPeriod *16;
--        miso <= '0';
--        wait for ClockPeriod *16;
--        miso <= '1';
--        wait for ClockPeriod *16;
--        miso <= '0';
--        wait for ClockPeriod *16;
--        miso <= '1';
--        wait for ClockPeriod *16;
--        miso <= '1';
--        wait for ClockPeriod *16;
--        miso <= '0';
--        wait for ClockPeriod *16;
--        miso <= '1';
--        wait for ClockPeriod *16;
--        wait for ClockPeriod *16;
--        wait for ClockPeriod *16;

    end process stimuli;

end Behavioral;