-- FPGA TOP BEGINS HERE
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.all;
use IEEE.std_logic_unsigned.all;

entity FPGA_TOP is 

port (

rst_n : in std_logic;
clk : in std_logic; -- 50 Mhz
led : out std_logic_vector(7 downto 0);
cam_scl : out std_logic;
cam_sdata : inout std_logic;
cam_reset : out std_logic;
cam_pwdn : out std_logic;
cam_xclk : out std_logic;
cam_data : in std_logic_vector(9 downto 0);
cam_pclk : in std_logic;
cam_href : in std_logic;
cam_vsync : in std_logic


);

end FPGA_TOP;

architecture FPGA_TOP_ARCH of FPGA_TOP is

COMPONENT INIT_RAM is
	port(
		clk : in std_logic;
		rst : in std_logic;
		address : in std_logic_vector(8 downto 0);
		data : out std_logic_vector(15 downto 0);
		finished : out std_logic
	);
END COMPONENT;
	
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

component scl_generator is
    generic ( 
        threshold : integer
    );
    port (
        rst : in std_logic;
        clk : in std_logic;
        toggle : in std_logic;
        scl_gen : out std_logic;
        scl_quarter : out std_logic_vector(1 downto 0)
		  );
end component;


	signal rst_gen : std_logic;

-- Testing
   constant test_factor : integer := 1; --1 -- Set to 1 to disable test mode - good value is 50khz
	constant test_sccb_mul : integer := 1;  --1  -- Good starting point is 50
	
-- Camera SCCB configuration.
	constant sccb_freq : integer := 400000 * test_sccb_mul;
	
	
	signal sccb_dev : std_logic_vector(6 downto 0);
	signal sccb_devreg : std_logic_vector(7 downto 0);
	signal sccb_wdata : std_logic_vector (7 downto 0);
	signal sccb_odata : std_logic_vector (7 downto 0);
	signal sccb_rw : std_logic;
	signal sccb_enable : std_logic;
	signal sccb_sclk : std_logic;
	signal sccb_sdata : std_logic;
	
	-- Camera
--	signal cam_rst : std_logic;
--	signal cam_pwdn : std_logic;
--	signal pixel_check : std_logic := '0';
--	signal pixel_check2 : std_logic := '0';
	signal pixel_check_1 : std_logic_vector(3 downto 0);
	signal pixel_check_2 : std_logic_vector(3 downto 0);
	signal pon_counter : std_logic_vector(26 downto 0);
	signal poff_counter : std_logic_vector(26 downto 0);
	--- Cam
	signal sig_xclk : std_logic;
	
	constant xclk_freq : integer := 25000000/1;
	signal cam_clktoggle : std_logic;
	signal cam_clkquarter : std_logic_vector(1 downto 0);
	-- Config sccb
	signal config_addr : std_logic_vector(8 downto 0);
	signal config_data : std_logic_vector(15 downto 0);
	signal config_end : std_logic;
	signal config_counter : std_logic;
	
	
	-- TOP
	signal led_array : std_logic_vector(7 downto 0);
	signal counter : std_logic_vector(26 downto 0);
	
	TYPE State_type IS (IDLE, INIT, SENDING, SEND2, READING);
	SIGNAL State : State_Type;
	
begin


	cam_ram : INIT_RAM
			PORT MAP(
				clk => clk,
				rst => rst_gen,
				address => config_addr,
				data =>	config_data,
				finished => config_end
			);

	sccb_m : sccb_master
		generic map(
			frequency => sccb_freq 
		)
		PORT MAP (
			clk => clk,
			rst => rst_gen,
			dev => sccb_dev,
			r_w => sccb_rw,
			dev_reg => sccb_devreg,
			data_w => sccb_wdata,
			o_data => sccb_odata,
			enable => sccb_enable,
			sdata => cam_sdata,
			sclk => cam_scl
		);
		
	scl_generator1 : scl_generator
		generic map (
				threshold => (50000000/xclk_freq)
				)
		port map( 
            rst => rst_gen,
            clk => clk,
            scl_gen => cam_xclk,
            toggle => cam_clktoggle,
            scl_quarter => cam_clkquarter
		);	
	
	
	with rst_n select rst_gen <=
		'0' when '1',
		'1' when '0',
		'0' when others;
	
	led <= led_array;
	--cam_scl <= sccb_sclk;
	--cam_sdata <= sccb_sdata;
	--led_array <= sccb_odata(7 downto 0);
	--Pclk test
	led_array <= pixel_check_1 & pixel_check_2; -- & "000000";




process(clk, rst_n)
begin
	
	if(rst_gen = '1') then
		sccb_dev <= x"0" & "000";
		sccb_rw <= '0';
		sccb_devreg <= x"00";
		sccb_wdata <= x"00";
		sccb_enable <= '0';
		counter <= (others => '0');
		cam_reset <= '0';
		cam_pwdn <= '0';
		cam_clktoggle <= '0';
		STATE <= INIT;
		pon_counter <= (others => '0');
		poff_counter <= (others => '0');
		pixel_check_1 <= (others => '0');
		pixel_check_2 <= (others => '0');
		config_addr <= (others => '0');
		
	elsif(clk'event and clk = '1') then
	
	--Testing PCLK
	
	if(cam_href = '1') then
		if(cam_pclk = '0') then
			poff_counter <= poff_counter + '1';
			if(poff_counter > 25000000) then
				poff_counter <= (others => '0');
				pixel_check_2 <= pixel_check_2 + '1';
			end if;
		end if;
		
		if(cam_pclk = '1') then
			pon_counter <= pon_counter + '1';
			if(pon_counter > 25000000) then
				pon_counter <= (others => '0');
				pixel_check_1 <= pixel_check_1 + '1';
			end if;
		end if;
	end if;
		
		
		


		case(STATE) is
		
        when INIT =>	--led_array <= sccb_odata;
	--cam_xclk <= cam_xclk
		  
				if(counter > 100000 / test_factor) then
					counter <= (others => '0');
					STATE <= SENDING;
					cam_clktoggle <= '0';
					sccb_enable <= '0';
					sccb_dev <= x"6" & "000";
					sccb_rw <= '0';
					
				else
		-- Fill in device registers and information
					
					counter <= counter + '1';
					cam_reset <= '1';
					cam_pwdn <= '0';
					cam_clktoggle <= '1';

				end if;
					
		  when SENDING =>
				-- Fill in address change between sending / receiving on state change (probably '1')
				if(counter > 10000 / test_factor) then
					counter <= (others => '0');
					
					if(config_end = '1') then
						STATE <= IDLE;
					else
						STATE <= SENDING;
						sccb_enable <= '1';
						config_addr <= config_addr + '1';
					end if;
					
				elsif(counter = 5000) then
					sccb_devreg <= config_data(15 downto 8);
					sccb_wdata <= config_data(7 downto 0);
					sccb_rw <= '0';
					counter <= counter + '1';
					


				else
					counter <= counter + '1';
					sccb_enable <= '0';


					
				end if;
				-- Fill in changes also.				sccb_enable <= '1';
--
--		  when SEND2 =>
--				if(counter > 50000000 / test_factor) then
--					STATE <= READING;
--					sccb_enable <= '1';
--				else
--					sccb_enable <= '0';
--					sccb_devreg <= x"12";
--					sccb_wdata <= x"40";
--					sccb_rw <= '0';
--				end if;
--				
--		  when READING =>
--				if(counter > 50000000 / test_factor) then
--					STATE <= IDLE;
--					sccb_enable <= '0';
--				else
--					sccb_enable <= '0';
--		
--				end if;
		  
		  
		 when OTHERS =>
				sccb_enable <= '0';
		 end case;
	
	
	
	


--		if(counter < 25000000/4) then
--			counter <= counter + '1';
--			led_array <= (others => '0');
--		elsif(counter > 50000000/4) then
--			counter <= (others=>'0');
--		else
--			led_array <= (others => '1');
--			counter <= counter + '1';
--		end if;
--			
	
	end if;
	

end process;

end FPGA_TOP_ARCH;	
