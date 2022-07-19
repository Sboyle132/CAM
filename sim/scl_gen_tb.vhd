----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 06/12/2022 02:46:51 PM
-- Design Name: 
-- Module Name: scl_generator_tb - Behavioral
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
library work;
use work.all;
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity scl_generator_tb is
--  Port ( );
end scl_generator_tb;

architecture Behavioral of scl_generator_tb is

signal clk : std_logic := '0';
signal rst : std_logic := '0';
signal scl_gen : std_logic := '0';
signal A : std_logic_vector(15 downto 0); -- Could add extra variable here
signal B : std_logic_vector(15 downto 0);
signal toggle : std_logic;
signal clock_segment : std_logic_vector(1 downto 0);
constant ClockPeriod : time := 10ns;

component scl_generator is
generic ( 
			threshold : integer
);
port (
rst : in std_logic;
clk : in std_logic;
scl_gen : out std_logic;
toggle : in std_logic;
scl_quarter : out std_logic_vector(1 downto 0)

);
end component;

begin
scl_generator1 : entity work.scl_generator
        generic map (
                threshold => 16
                )
        port map( 
            rst => rst,
            clk => clk,
            scl_gen => scl_gen,
            toggle => toggle,
            scl_quarter => clock_segment
            );

clk <= not clk after ClockPeriod/2;

 stimuli : process
    begin
        rst <= '1';
        wait for ClockPeriod;
        rst <= '0';
        toggle <= '1';
        wait for ClockPeriod;
        toggle <= '0';
        wait for ClockPeriod * 16 * 8 * 2;
        toggle <= '1';
        wait for ClockPeriod * 16 * 8 * 2;

    end process stimuli;

end Behavioral;
