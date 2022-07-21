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



entity sccb_master_tb is
--  Port ( );
end sccb_master_tb;

architecture Behavioral of sccb_master_tb is



COMPONENT sccb_master is
    port(
    rst : in std_logic;
    clk : in std_logic;
    dev : in std_logic_vector(6 downto 0);
    dev_reg : in std_logic_vector(7 downto 0);
    data_w : in std_logic_vector( 7 downto 0);
    o_data : out std_logic_vector(7 downto 0);
    r_w : in std_logic;
    enable : in std_logic;
    sclk : inout std_logic;
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
signal nack_check : std_logic;

-- Signals for reading data.
signal read_data : std_logic_vector(7 downto 0) := "H0HH0HH0";
signal read_devaddr : std_logic_vector(7 downto 0);
signal read_regaddr : std_logic_vector(7 downto 0);
signal write_data : std_logic_vector(7 downto 0);


constant ClockPeriod : time := 10ns;
begin

sccb_m : sccb_master
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
-- I2C Mode scl <= 'H';
mosi_miso <= 'H';
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
       
        rw <= '1';
        wait for ClockPeriod;
        enable <= '0';
        --First start condition
		  wait for ClockPeriod * 16;
		  --First start condition
		  --Frame 1
		  
		  wait for ClockPeriod * 12; -- In line with stable.
		  read_devaddr(7) <= mosi_miso;
		  wait for ClockPeriod;
		  read_devaddr(7) <= read_devaddr(7);
		  wait for ClockPeriod * 15;
		  read_devaddr(6) <= mosi_miso;
		  wait for ClockPeriod;
		  read_devaddr(6) <= read_devaddr(6);
		  wait for ClockPeriod * 15;
		  read_devaddr(5) <= mosi_miso;
		  wait for ClockPeriod;
		  read_devaddr(5) <= read_devaddr(5);
		  wait for ClockPeriod * 15;
		  read_devaddr(4) <= mosi_miso;
		  wait for ClockPeriod;
		  read_devaddr(4) <= read_devaddr(4);
		  wait for ClockPeriod * 15;
		  read_devaddr(3) <= mosi_miso;
		  wait for ClockPeriod;
		  read_devaddr(3) <= read_devaddr(3);
		  wait for ClockPeriod * 15;
		  read_devaddr(2) <= mosi_miso;
		  wait for ClockPeriod;
		  read_devaddr(2) <= read_devaddr(2);
		  wait for ClockPeriod * 15;
		  read_devaddr(1) <= mosi_miso;
		  wait for ClockPeriod;
		  read_devaddr(1) <= read_devaddr(1);
		  wait for ClockPeriod * 15;
		  read_devaddr(0) <= mosi_miso;
		  wait for ClockPeriod;
		  read_devaddr(0) <= read_devaddr(0);
		  wait for ClockPeriod * 5;
		  -- Frame 1 complete.
		  
		  --Ack 1
        wait for ClockPeriod * 7;
        mosi_miso <= 'Z';
        driver <= 'Z';
        wait for ClockPeriod * 16;  -- these 16s can be replaced by generics.;
        mosi_miso <= 'Z';
        driver <= 'Z';
		  --Ack 1
		  
		  -- Frame 2
		  wait for ClockPeriod * 3;
		  read_regaddr(7) <= mosi_miso;
		  wait for ClockPeriod;
		  read_regaddr(7) <= read_regaddr(7);
		  wait for ClockPeriod * 15;
		  read_regaddr(6) <= mosi_miso;
		  wait for ClockPeriod;
		  read_regaddr(6) <= read_regaddr(6);
		  wait for ClockPeriod * 15;
		  read_regaddr(5) <= mosi_miso;
		  wait for ClockPeriod;
		  read_regaddr(5) <= read_regaddr(5);
		  wait for ClockPeriod * 15;
		  read_regaddr(4) <= mosi_miso;
		  wait for ClockPeriod;
		  read_regaddr(4) <= read_regaddr(4);
		  wait for ClockPeriod * 15;
		  read_regaddr(3) <= mosi_miso;
		  wait for ClockPeriod;
		  read_regaddr(3) <= read_regaddr(3);
		  wait for ClockPeriod * 15;
		  read_regaddr(2) <= mosi_miso;
		  wait for ClockPeriod;
		  read_regaddr(2) <= read_regaddr(2);
		  wait for ClockPeriod * 15;
		  read_regaddr(1) <= mosi_miso;
		  wait for ClockPeriod;
		  read_regaddr(1) <= read_regaddr(1);
		  wait for ClockPeriod * 15;
		  read_regaddr(0) <= mosi_miso;
		  wait for ClockPeriod;
		  read_regaddr(0) <= read_regaddr(0);
		  wait for ClockPeriod * 6;
		  -- Frame 2 complete
		  
		  --Ack 2
        mosi_miso <= '0';
        driver <= '0';
        wait for ClockPeriod * 16;
        mosi_miso <= 'Z';
        driver <= 'Z';
		  --Ack 2
		  --Stop and start
		  wait for ClockPeriod * 16 * 2;
		  
		  --Frame 3
        wait for ClockPeriod * 12; -- In line with stable.
		  read_devaddr(7) <= mosi_miso;
		  wait for ClockPeriod;
		  read_devaddr(7) <= read_devaddr(7);
		  wait for ClockPeriod * 15;
		  read_devaddr(6) <= mosi_miso;
		  wait for ClockPeriod;
		  read_devaddr(6) <= read_devaddr(6);
		  wait for ClockPeriod * 15;
		  read_devaddr(5) <= mosi_miso;
		  wait for ClockPeriod;
		  read_devaddr(5) <= read_devaddr(5);
		  wait for ClockPeriod * 15;
		  read_devaddr(4) <= mosi_miso;
		  wait for ClockPeriod;
		  read_devaddr(4) <= read_devaddr(4);
		  wait for ClockPeriod * 15;
		  read_devaddr(3) <= mosi_miso;
		  wait for ClockPeriod;
		  read_devaddr(3) <= read_devaddr(3);
		  wait for ClockPeriod * 15;
		  read_devaddr(2) <= mosi_miso;
		  wait for ClockPeriod;
		  read_devaddr(2) <= read_devaddr(2);
		  wait for ClockPeriod * 15;
		  read_devaddr(1) <= mosi_miso;
		  wait for ClockPeriod;
		  read_devaddr(1) <= read_devaddr(1);
		  wait for ClockPeriod * 15;
		  read_devaddr(0) <= mosi_miso;
		  wait for ClockPeriod;
		  read_devaddr(0) <= read_devaddr(0);
		  wait for ClockPeriod * 4;
		  
		  --Frame 3 Complete
		  
		  --Ack 3
        mosi_miso <= 'Z';
        driver <= '1';
        wait for ClockPeriod * 16;
        mosi_miso <= 'Z';
        driver <= 'Z';
		  -- Ack 3
		  
		 --Frame 4 - Read from tb
		  wait for ClockPeriod* 7;
		  mosi_miso <= read_data(7);
		  wait for ClockPeriod * 16;
		  mosi_miso <= read_data(6);
		  wait for ClockPeriod * 16;
		  mosi_miso <= read_data(5);
		  wait for ClockPeriod * 16;
		  mosi_miso <= read_data(4);
		  wait for ClockPeriod * 16;
		  mosi_miso <= read_data(3);
		  wait for ClockPeriod * 16;
		  mosi_miso <= read_data(2);
		  wait for ClockPeriod * 16;
		  mosi_miso <= read_data(1);
		  wait for ClockPeriod * 16;
		  mosi_miso <= read_data(0);
		  wait for ClockPeriod * 9;
		  mosi_miso <= 'Z';
		  --Frame 4 - Complete
		  
		  --Master NACK
		  wait for ClockPeriod * 12;
		  nack_check <= mosi_miso;
		  wait for ClockPeriod;
		  nack_check <= nack_check;
		  wait for ClockPeriod *3;
		  -- Nack complete
		  
		  --Return to idle state.
		  wait for ClockPeriod*16*5;
		  
		  --Begin Write operation
		  
		  
		  
        rw <= '0';
        enable <= '1';
		  addr_reg <= "01101101";
        dev <= "1101101";
        data_reg <= "11011011";
		  
		  
        --First start condition
		  wait for ClockPeriod * 16;
		  --First start condition
		  
		  --Frame 1
		  wait for ClockPeriod * 13; -- In line with stable.
		  read_devaddr(7) <= mosi_miso;
		  wait for ClockPeriod;
		  read_devaddr(7) <= read_devaddr(7);
		  wait for ClockPeriod * 15;
		  read_devaddr(6) <= mosi_miso;
		  wait for ClockPeriod;
		  read_devaddr(6) <= read_devaddr(6);
		  wait for ClockPeriod * 15;
		  read_devaddr(5) <= mosi_miso;
		  wait for ClockPeriod;
		  read_devaddr(5) <= read_devaddr(5);
		  wait for ClockPeriod * 15;
		  read_devaddr(4) <= mosi_miso;
		  wait for ClockPeriod;
		  read_devaddr(4) <= read_devaddr(4);
		  wait for ClockPeriod * 15;
		  read_devaddr(3) <= mosi_miso;
		  wait for ClockPeriod;
		  read_devaddr(3) <= read_devaddr(3);
		  wait for ClockPeriod * 15;
		  read_devaddr(2) <= mosi_miso;
		  wait for ClockPeriod;
		  read_devaddr(2) <= read_devaddr(2);
		  wait for ClockPeriod * 15;
		  read_devaddr(1) <= mosi_miso;
		  wait for ClockPeriod;
		  read_devaddr(1) <= read_devaddr(1);
		  wait for ClockPeriod * 15;
		  read_devaddr(0) <= mosi_miso;
		  wait for ClockPeriod;
		  read_devaddr(0) <= read_devaddr(0);
		  wait for ClockPeriod * 5;
		  -- Frame 1 complete.
		  
		  --Ack 1
        wait for ClockPeriod * 7;
        mosi_miso <= '0';
        driver <= '0';
        wait for ClockPeriod * 16;  -- these 16s can be replaced by generics.;
        mosi_miso <= 'Z';
        driver <= 'Z';
		  --Ack 1
		  
		  -- Frame 2
		  wait for ClockPeriod * 3;
		  read_regaddr(7) <= mosi_miso;
		  wait for ClockPeriod;
		  read_regaddr(7) <= read_regaddr(7);
		  wait for ClockPeriod * 15;
		  read_regaddr(6) <= mosi_miso;
		  wait for ClockPeriod;
		  read_regaddr(6) <= read_regaddr(6);
		  wait for ClockPeriod * 15;
		  read_regaddr(5) <= mosi_miso;
		  wait for ClockPeriod;
		  read_regaddr(5) <= read_regaddr(5);
		  wait for ClockPeriod * 15;
		  read_regaddr(4) <= mosi_miso;
		  wait for ClockPeriod;
		  read_regaddr(4) <= read_regaddr(4);
		  wait for ClockPeriod * 15;
		  read_regaddr(3) <= mosi_miso;
		  wait for ClockPeriod;
		  read_regaddr(3) <= read_regaddr(3);
		  wait for ClockPeriod * 15;
		  read_regaddr(2) <= mosi_miso;
		  wait for ClockPeriod;
		  read_regaddr(2) <= read_regaddr(2);
		  wait for ClockPeriod * 15;
		  read_regaddr(1) <= mosi_miso;
		  wait for ClockPeriod;
		  read_regaddr(1) <= read_regaddr(1);
		  wait for ClockPeriod * 15;
		  read_regaddr(0) <= mosi_miso;
		  wait for ClockPeriod;
		  read_regaddr(0) <= read_regaddr(0);
		  wait for ClockPeriod * 6;
		  -- Frame 2 complete
		  
		  --Ack 2
        mosi_miso <= 'Z';
        driver <= 'Z';
        wait for ClockPeriod * 16;
        mosi_miso <= 'Z';
        driver <= 'Z';
		  --Ack 2

		  -- Frame 4 (Skipped 3)
		  wait for ClockPeriod * 7;
		  write_data(7) <= mosi_miso;
		  wait for ClockPeriod;
		  write_data(7) <= write_data(7);
		  wait for ClockPeriod * 15;
		  write_data(6) <= mosi_miso;
		  wait for ClockPeriod;
		  write_data(6) <= write_data(6);
		  wait for ClockPeriod * 15;
		  write_data(5) <= mosi_miso;
		  wait for ClockPeriod;
		  write_data(5) <= write_data(5);
		  wait for ClockPeriod * 15;
		  write_data(4) <= mosi_miso;
		  wait for ClockPeriod;
		  write_data(4) <= write_data(4);
		  wait for ClockPeriod * 15;
		  write_data(3) <= mosi_miso;
		  wait for ClockPeriod;
		  write_data(3) <= write_data(3);
		  wait for ClockPeriod * 15;
		  write_data(2) <= mosi_miso;
		  wait for ClockPeriod;
		  write_data(2) <= write_data(2);
		  wait for ClockPeriod * 15;
		  write_data(1) <= mosi_miso;
		  wait for ClockPeriod;
		  write_data(1) <= write_data(1);
		  wait for ClockPeriod * 15;
		  write_data(0) <= mosi_miso;
		  wait for ClockPeriod;
		  write_data(0) <= write_data(0);
		  wait for ClockPeriod * 6;
		  -- Frame 4 complete
		  -- ensure idle
		  
		  enable <= '0';
		  
		  --Ack 4
        mosi_miso <= 'Z';
        driver <= 'Z';
        wait for ClockPeriod * 16;
        mosi_miso <= 'Z';
        driver <= 'Z';
		  --Ack 4
		  -- Return to idle state.
		  wait for ClockPeriod * 16 * 10;
		  
		  
		  
		  
		  
		  
		  
		  
		  
		  
		  
		  
		  
		  
		  
		  
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