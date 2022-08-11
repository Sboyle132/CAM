library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use ieee.std_logic_unsigned.all;
use ieee.math_real.all;


entity CAM_INIT is
generic ( 
				sccb_frequency : integer := 200000
);
	port(
		clk : in std_logic;
		rst : in std_logic;
		cam_initialise : in std_logic;
		sccb_scl : out std_logic;
		sccb_sdata : inout std_logic;
		sccb_odata : out std_logic_vector(7 downto 0)
		);
end CAM_INIT;

architecture CAM_INIT_ARCH of CAM_INIT is

COMPONENT sccb_master is
	 generic (
				frequency : integer
				);
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

COMPONENT INIT_RAM is
	port(
		clk : in std_logic;
		rst : in std_logic;
		address : in std_logic_vector(8 downto 0);
		data : out std_logic_vector(15 downto 0);
		finished : out std_logic
	);
END COMPONENT;

-- SCCB Signals to camera.
signal sccb_dev : std_logic_vector(6 downto 0);
signal sccb_devreg : std_logic_vector(7 downto 0);
signal sccb_wdata : std_logic_vector( 7 downto 0);
signal sccb_rw : std_logic;
signal sccb_enable : std_logic;

--CONFIG OF CAMERA SCCB
signal config_addr : std_logic_vector(8 downto 0);
signal config_data : std_logic_vector(15 downto 0);
signal config_end : std_logic;
signal counter : std_logic_vector(31 downto 0);

--States
TYPE State_type IS (UNINIT, SENDING, CONFIRM, DONE);
SIGNAL State : State_Type;


constant count_top : integer := 10000 * (400000 / sccb_frequency) ;
constant count_mid : integer := 10000 * ((400000 / sccb_frequency)/2);


begin

cam_ram : INIT_RAM
			PORT MAP(
				clk => clk,
				rst => rst,
				address => config_addr,
				data =>	config_data,
				finished => config_end
			);

	sccb_m : sccb_master
		generic map(
			frequency => sccb_frequency 
		)
		PORT MAP (
			clk => clk,
			rst => rst,
			dev => sccb_dev,
			r_w => sccb_rw,
			dev_reg => sccb_devreg,
			data_w => sccb_wdata,
			o_data => sccb_odata,
			enable => sccb_enable,
			sdata => sccb_sdata,
			sclk => sccb_scl
		);

process(clk, rst)
begin

if(rst = '1') then
	sccb_dev <= x"6" & "000";
	sccb_rw <= '0';
	sccb_devreg <= x"00";
	sccb_wdata <= x"00";
	sccb_enable <= '0';
	counter <= (others => '0');
	config_addr <= (others => '0');
	STATE <= UNINIT;
	
elsif (clk'event and clk='1') then
	case(STATE) is
	
		when UNINIT =>
			counter <= (others => '0');
			config_addr <= (others => '0');
			sccb_enable <= '0';
			if(cam_initialise = '1') then
				STATE <= SENDING;
			end if;
			
		when SENDING =>
			if(counter > count_top) then
				counter <= (others => '0');	
				if(config_end = '1') then
					STATE <= CONFIRM;
				else
					STATE <= SENDING;
					sccb_enable <= '1';
					config_addr <= config_addr + '1';
				end if;
			elsif(counter = count_mid) then
				sccb_devreg <= config_data(15 downto 8);
				sccb_wdata <= config_data(7 downto 0);
				sccb_rw <= '0';
				counter <= counter + '1';
			else
				counter <= counter + '1';
				sccb_enable <= '0';
			end if;
			
		when CONFIRM =>
			if(counter > count_top) then
				counter <= (others => '0');
				STATE <= DONE;
				sccb_enable <= '1';
			elsif(counter = count_mid) then
				sccb_devreg <= x"0B";
				sccb_wdata <= x"00";
				sccb_rw <= '1';
				counter <= counter + '1';	
			else
				counter <= counter + '1';
				sccb_enable <= '0';		
			end if;
			
		when DONE =>
			counter <= (others => '0');
			config_addr <= (others => '0');
			sccb_enable <= '0';
			if(cam_initialise = '1') then
				STATE <= SENDING;
			end if;
	end case;
end if;

end process;
		
end CAM_INIT_ARCH;



