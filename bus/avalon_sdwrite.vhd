library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use ieee.std_logic_unsigned.all;

--If we can make it non-bursting. that would be best.
entity avalon_sdwrite is
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
end avalon_sdwrite;

architecture  avalon_sdwrite_arch of avalon_sdwrite is
signal sig_bad_counter : std_logic_vector(7 downto 0);
signal error : std_logic;
TYPE State_type IS (IDLE, SENDING);
SIGNAL State : State_Type;

begin


process(clk, reset)
begin
if(clk'event and clk='1') then
	if(reset = '1') then
		STATE <= IDLE;
		avm_m0_byteenable <= (others => '0');
		avm_m0_writedata <= (others => '0');
		avm_m0_address <= (others => '0');
		avm_m0_burstcount <= (others => '0');
		avm_m0_read <= '0';
		avm_m0_write <= '0';
		sig_bad_counter <= (others => '0');
		error <= '0';
	else
	
		case(STATE) is
			
			when IDLE =>
			
				if(sdram_write = '1') then
					avm_m0_write <= '1';
					avm_m0_address <= sdram_address;
					avm_m0_writedata(31 downto 0) <= sdram_data;
					avm_m0_byteenable <= x"0000000F";
					avm_m0_burstcount <= x"00" & "001"; -- May need to enable this. or leave disabled.
					avm_m0_read <= '0';
					STATE <= SENDING;
				else
					STATE <= IDLE;
					avm_m0_byteenable <= (others => '0');
					avm_m0_writedata <= (others => '0');
					avm_m0_address <= (others => '0');
					avm_m0_burstcount <= (others => '0');
					avm_m0_read <= '0';
					avm_m0_write <= '0';
				end if;
			
			when SENDING =>
			
				if(avm_m0_waitrequest = '0') then
					STATE <= IDLE;
					avm_m0_byteenable <= (others => '0');
					avm_m0_writedata <= (others => '0');
					avm_m0_address <= (others => '0');
					avm_m0_burstcount <= (others => '0');
					avm_m0_read <= '0';
					avm_m0_write <= '0';
				
				
				else
					if(avm_m0_waitrequest = '1' and sdram_write = '1') then
						sig_bad_counter <= sig_bad_counter + '1';
						if(sig_bad_counter = 255 and error = '0') then
							error <= '1';
							bad_counter <= sig_bad_counter;
						end if;
					end if;
				STATE <= SENDING;
				end if;
				
			end case;
					
	end if;
end if;
end process;
end avalon_sdwrite_arch;