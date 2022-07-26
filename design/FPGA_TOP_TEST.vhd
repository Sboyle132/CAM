-- FPGA TOP BEGINS HERE
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.all;
use IEEE.std_logic_unsigned.all;

entity FPGA_TOP_TEST is 

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

end FPGA_TOP_TEST;

architecture FPGA_TOP_ARCH of FPGA_TOP_TEST is


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
	constant sccb_freq : integer := 10000 * test_sccb_mul;
	
	
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
	signal pixel_check : std_logic := '0';
	signal pixel_check2 : std_logic := '0';
	signal sig_xclk : std_logic;
	
	constant xclk_freq : integer := 25000000/2;
	signal cam_clktoggle : std_logic;
	signal cam_clkquarter : std_logic_vector(1 downto 0);
	signal state_counter : std_logic_vector(10 downto 0);
	signal led_array : std_logic_vector(7 downto 0);
	signal counter : std_logic_vector(26 downto 0);
	
	TYPE State_type IS (IDLE, INIT, TRANS_BEGIN);
	SIGNAL State : State_Type;
	
begin
--
--	sccb_m : sccb_master
--		generic map(
--			frequency => sccb_freq 
--		)
--		PORT MAP (
--			clk => clk,
--			rst => rst_gen,
--			dev => sccb_dev,
--			r_w => sccb_rw,
--			dev_reg => sccb_devreg,
--			data_w => sccb_wdata,
--			o_data => sccb_odata,
--			enable => sccb_enable,
--			sdata => cam_sdata,
--			sclk => cam_scl
--		);
--		
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
	led_array <= sccb_odata(7 downto 0);
--	led_array <= pixel_check & pixel_check2 & "000000";




process(clk, rst_n)
begin
	
	if(rst_gen = '1') then
		sccb_dev <= x"0" & "000";
		sccb_rw <= '0';
		sccb_devreg <= x"00";
		sccb_wdata <= x"00";
		sccb_enable <= '0';
		counter <= (others => '0');
		state_counter <= (others => '0');
		cam_reset <= '0';
		cam_pwdn <= '0';
		cam_clktoggle <= '0';
		STATE <= INIT;
		
	
	elsif(clk'event and clk = '1') then
		
		
		
		
		
		
		if(counter > 4999 / test_factor) then
			counter <= (others => '0');
		else
			counter <= counter + '1';
		end if;
		
		
		case(STATE) is
		
        when INIT =>
		  
				if(counter > 4999) then
					cam_reset <= '1';
					cam_pwdn <= '0';
					cam_clktoggle <= '1';
					state_counter <= (others => '0');
				end if;

					
			when trans_begin =>
				if(counter > 4999 / test_factor) then
					state_counter <= state_counter + '1';
				end if;
				
				if (state_counter = '0'); --
					-- Can use OR for 8 at time. Maybe setting this non propogation is important but i dont think so.
				
			-- also set registers before and can cycle through Do not forget MSB first
				
				
		  
		  
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
