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
	 --Will probably also need transfer start signal.
	 transfer_complete : out std_logic;

	 -- Interface
	 mclk : in std_logic;
	 data_i : in std_logic_vector(9 downto 0);
	 HREF : in std_logic;
	 MHSYNC : out std_logic;
	 MVSYNC : out std_logic;
	 
	 --debug
	 sampled_out : out std_logic_vector(15 downto 0);
	 mode : in std_logic
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
	
	
	-- TOP
	signal led_array : std_logic_vector(7 downto 0);
	signal counter : std_logic_vector(26 downto 0);
	
	TYPE State_type IS (IDLE, INIT, SENDING, SEND2, READING, DATA);
	SIGNAL State : State_Type;
	
	-- SVGA CONTROLLER
	signal word_o : std_logic_vector(31 downto 0);
	signal word_send : std_logic;
	signal word_address : std_logic_vector(31 downto 0);

	signal mode : std_logic; 
	signal transfer_complete : std_logic;
	signal burst_size : std_logic_vector(31 downto 0);
	signal burst_address : std_logic_vector(31 downto 0); 
	signal burst_start : std_logic;
	signal sampled_out : std_logic_vector(15 downto 0);
	
begin


--led(7 downto 0) <= "11111111";

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
	SVGA_CONTROLLER0 : SVGA_CONTROLLER
		
		generic map(
			mclk_freq => xclk_freq
		)
		PORT MAP (
			clk => clk,
			rst => rst_gen,
			word_o => word_o,
			word_send => word_send,
			word_address => word_address,
			data_i => cam_data,
			mclk => sig_xclk,
			HREF => cam_href,
			MHSYNC => cam_reset,
			MVSYNC => cam_pwdn,
			mode => mode,
			transfer_complete => transfer_complete,
			burst_size => burst_size,
			burst_address => burst_address,
			burst_start => burst_start,
			sampled_out => sampled_out	
		);
	scl_generator1 : scl_generator
		generic map (
				threshold => (50000000/xclk_freq)
				)
		port map( 
            rst => rst_gen,
            clk => clk,
            scl_gen => sig_xclk,
            toggle => cam_clktoggle,
            scl_quarter => cam_clkquarter
		);	
	

	with rst_n select rst_gen <=
		'0' when '1',
		'1' when '0',
		'0' when others;
	
	cam_xclk <= sig_xclk;
	led <= led_array;
	--cam_scl <= sccb_sclk;
    --cam_sdata <= sccb_sdata;
	led_array <= sampled_out(15 downto 8); --Test IF href still in slave mode.
	--led_array <= cam_data(9 downto 2);
	--Pclk test
-- led_array <= pixel_check_1 & pixel_check_2; -- & "000000";




process(clk, rst_n)
begin
	
	if(rst_gen = '1') then
		sccb_dev <= x"0" & "000";
		sccb_rw <= '0';
		sccb_devreg <= x"00";
		sccb_wdata <= x"00";
		sccb_enable <= '0';
		counter <= (others => '0');
		
		--SVGA 

		mode <= '0';
		burst_size <= (others => '0');
		burst_address <= (others => '0');		
		burst_start <= '0';
		
		
		
		--
--		cam_reset <= '0';
--		cam_pwdn <= '0';
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
		if(sig_xclk = '0') then
			poff_counter <= poff_counter + '1';
			if(poff_counter > 25000000) then
				poff_counter <= (others => '0');
				pixel_check_2 <= pixel_check_2 + '1';
			end if;
		end if;
		
		if(sig_xclk = '1') then
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
--					cam_reset <= '1';
--					cam_pwdn <= '0';
					cam_clktoggle <= '1';


				end if;
					
		  when SENDING =>
				-- Fill in address change between sending / receiving on state change (probably '1')
				if(counter > 10000 / test_factor) then
					counter <= (others => '0');
					
					if(config_end = '1') then
						STATE <= READING;
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
		  when READING =>
				if(counter > 10000 / test_factor) then
					counter <= (others => '0');
					STATE <= DATA;
					sccb_enable <= '0';
					
					burst_size <= x"00000001";
					burst_address <= x"20000000";
 					burst_start <= '1';
					
				elsif(counter = 5000) then
					sccb_devreg <= x"0B";
					sccb_wdata <= x"00";
					sccb_rw <= '1';
					counter <= counter + '1';
					


				else
					counter <= counter + '1';
					sccb_enable <= '0';

					
				end if;
		  
		 when DATA =>
				counter <= counter + '1';
				 burst_start <= '0';
				if(counter = 100000) then
				   sccb_enable <= '1';

					STATE <= IDLE;
				end if;

		 when OTHERS =>
		 		counter <= counter + '1';
				if(counter = 1000000) then
					sccb_enable <= '0';
					burst_start <= '1';
					burst_size <= x"0000000A";
				else
					burst_start <= '0';
				end if;
		 end case;
	
	
	
	


		--if(counter < 25000000/4) then
--			counter <= counter + '1';
--			led_array <= (others => '0');
--		elsif(counter > 50000000/4) then
--			counter <= (others=>'0');
--		else
--			led_array <= (others => '1');
--			counter <= counter + '1';
--		end if;
			
	
	end if;
	

end process;

end FPGA_TOP_ARCH;		
