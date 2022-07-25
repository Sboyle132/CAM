-- FPGA TOP BEGINS HERE
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.all;
use IEEE.std_logic_unsigned.all;

entity FPGA_TOP is 

port (

rst_n : in std_logic;
clk : in std_logic; -- 50 Mhz
led : out std_logic_vector(7 downto 0)

);

end FPGA_TOP;

architecture FPGA_TOP_ARCH of FPGA_TOP is

	signal led_array : std_logic_vector(7 downto 0);
	signal counter : std_logic_vector(26 downto 0);
begin 

led <= led_array;

process(clk, rst_n)
begin
	if(not (rst_n = '1')) then
		counter <= (others =>'0');
		led_array <= (others => '0');
	elsif(clk'event and clk = '1') then
		if(counter < 25000000/4) then
			counter <= counter + '1';
			led_array <= (others => '0');
		elsif(counter > 50000000/4) then
			counter <= (others=>'0');
		else
			led_array <= (others => '1');
			counter <= counter + '1';
		end if;
			
	
	end if;
	

end process;

end FPGA_TOP_ARCH;	
