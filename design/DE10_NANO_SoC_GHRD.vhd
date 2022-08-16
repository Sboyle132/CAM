 -- Quartus Prime VHDL Template
-- Single port RAM with single read/write address 

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.all;
use IEEE.std_logic_unsigned.all;

entity DE10_NANO_SoC_GHRD is
    port 
    (
        -------- CLOCKS --------------------
        clk		: in 	std_logic;
        FPGA_CLK2_50		: in 	std_logic;
        FPGA_CLK3_50		: in	std_logic;
        -- HPS ----------------------------
        HPS_DDR3_ADDR		: out	std_logic_vector(14 downto 0);
        HPS_DDR3_BA		: out	std_logic_vector(2 downto 0);
        HPS_DDR3_CAS_N		: out	std_logic;
        HPS_DDR3_CK_N		: out	std_logic;
        HPS_DDR3_CK_P		: out	std_logic;
        HPS_DDR3_CKE		: out	std_logic;
        HPS_DDR3_CS_N		: out	std_logic;
        HPS_DDR3_DM		: out	std_logic_vector(3 downto 0);
        HPS_DDR3_DQ		: inout	std_logic_vector(31 downto 0);
        HPS_DDR3_DQS_N		: inout	std_logic_vector(3 downto 0);
        HPS_DDR3_DQS_P		: inout	std_logic_vector(3 downto 0);
        HPS_DDR3_ODT		: out	std_logic;
        HPS_DDR3_RAS_N		: out	std_logic;
        HPS_DDR3_RESET_N	: out	std_logic;
        HPS_DDR3_RZQ		: in	std_logic;
        HPS_DDR3_WE_N		: out	std_logic;
        ------- INPUT/OUTPUT --------------------
    --    KEY			: in	std_logic_vector(1 downto 0);
        LED			: out	std_logic_vector(7 downto 0);
   --     SW			: in	std_logic_vector(3 downto 0);
    --    GPIO_0    : out std_logic_vector(35 downto 0);
    --    GPIO_1    : in  std_logic_vector(35 downto 0);
       --- RESET
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
end DE10_NANO_SoC_GHRD;

architecture rtl of DE10_NANO_SoC_GHRD is
--=======================================================
--  REG/WIRE declarations
--=======================================================
  signal  hps_fpga_reset_n : std_logic;
  signal  fpga_led_internal : std_logic_vector(6 downto 0);
 
 component soc_system is
        port (
            clk_clk                                   : in    std_logic                     := 'X';             -- clk
            hps_0_h2f_reset_reset_n                   : out   std_logic;                                        -- reset_n
            memory_mem_a                              : out   std_logic_vector(14 downto 0);                    -- mem_a
            memory_mem_ba                             : out   std_logic_vector(2 downto 0);                     -- mem_ba
            memory_mem_ck                             : out   std_logic;                                        -- mem_ck
            memory_mem_ck_n                           : out   std_logic;                                        -- mem_ck_n
            memory_mem_cke                            : out   std_logic;                                        -- mem_cke
            memory_mem_cs_n                           : out   std_logic;                                        -- mem_cs_n
            memory_mem_ras_n                          : out   std_logic;                                        -- mem_ras_n
            memory_mem_cas_n                          : out   std_logic;                                        -- mem_cas_n
            memory_mem_we_n                           : out   std_logic;                                        -- mem_we_n
            memory_mem_reset_n                        : out   std_logic;                                        -- mem_reset_n
            memory_mem_dq                             : inout std_logic_vector(31 downto 0) := (others => 'X'); -- mem_dq
            memory_mem_dqs                            : inout std_logic_vector(3 downto 0)  := (others => 'X'); -- mem_dqs
            memory_mem_dqs_n                          : inout std_logic_vector(3 downto 0)  := (others => 'X'); -- mem_dqs_n
            memory_mem_odt                            : out   std_logic;                                        -- mem_odt
            memory_mem_dm                             : out   std_logic_vector(3 downto 0);                     -- mem_dm
            memory_oct_rzqin                          : in    std_logic                     := 'X';             -- oct_rzqin
            reset_reset_n                             : in    std_logic                     := 'X';            -- reset_n
				svga_complete_export    : in   	 					  std_logic                     := '0';          
				svga_i_export1          : out   						  std_logic_vector(31 downto 0);                   
				svga_i_export0          : out   						  std_logic_vector(31 downto 0);                  
				svga_i_export2          : out   						  std_logic;                                       
				svga_o_export0          : in    						  std_logic                     := '0';             
				svga_o_export1          : in   						  std_logic_vector(31 downto 0) := (others => '0');
				svga_o_export2				: in							  std_logic_vector(31 downto 0) := (others => '0')
				
        );
 end component soc_system;
  
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

COMPONENT INIT_RAM is
	port(
		clk : in std_logic;
		rst : in std_logic;
		address : in std_logic_vector(8 downto 0);
		data : out std_logic_vector(15 downto 0);
		finished : out std_logic
	);
END COMPONENT;


-- Testing
constant test_factor : integer := 1; --1 -- Set to 1 to disable test mode - good value is 50khz
constant test_sccb_mul : integer := 1;  --1  -- Good starting point is 50

-- CUSTOM IP -----------------------------
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
		
		-- Config sccb
		signal config_addr : std_logic_vector(8 downto 0);
		signal config_data : std_logic_vector(15 downto 0);
		signal config_end : std_logic;
			
		-- MCLK
		signal sig_xclk : std_logic;
		constant xclk_freq : integer := 25000000/1;
		signal cam_clktoggle : std_logic;
		signal cam_clkquarter : std_logic_vector(1 downto 0);
		
		--SCCB 
		
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
		
		signal rst_n : std_logic;
		
		--Internal
		
signal rst_gen : std_logic;
--signal clk : std_logic;

		TYPE State_type IS (IDLE, INIT, SENDING, SEND2, READING, DATA);
		SIGNAL State : State_Type;
		signal counter : std_logic_vector(26 downto 0);

begin

with rst_n select rst_gen <=
		'0' when '1',
		'1' when '0',
		'0' when others;
--clk <= FPGA_CLK1_50;

LED <= sccb_odata;
cam_xclk <= sig_xclk;







process(clk, rst_n)
begin
	
	if(rst_gen = '1') then
		sccb_dev <= x"0" & "000";
		sccb_rw <= '0';
		sccb_devreg <= x"00";
		sccb_wdata <= x"00";
		sccb_enable <= '0';
		counter <= (others => '0');
		
		--svga mode
		mode <= '0';
		
		STATE <= INIT;
		config_addr <= (others => '0');
		
	elsif(clk'event and clk = '1') then
	
	--Testing PCLK
		
		
		


		case(STATE) is
		
        when INIT =>	
		  
				if(counter > 100000 / test_factor) then
					counter <= (others => '0');
					STATE <= SENDING;
					sccb_enable <= '0';
					sccb_dev <= x"6" & "000";
					sccb_rw <= '0';
				else					
					counter <= counter + '1';
				end if;
					
		  when SENDING =>
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

		  when READING =>
				if(counter > 10000 / test_factor) then
					counter <= (others => '0');
					STATE <= DATA;
					sccb_enable <= '0';	
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
				if(counter = 100000) then
				   sccb_enable <= '1';
					STATE <= IDLE;
				end if;
		 when OTHERS =>
				sccb_enable <= '0';
		 end case;
end if;
end process;
	

    

    u0 : component soc_system
    port map (
        -- CLOCK
        clk_clk                                   => clk,
        reset_reset_n                             => rst_n,    
            
	-- DDR3 RAM
        memory_mem_a                              => HPS_DDR3_ADDR,      --                         memory.mem_a
        memory_mem_ba                             => HPS_DDR3_BA,        --                               .mem_ba
        memory_mem_ck                             => HPS_DDR3_CK_P,      --                               .mem_ck
        memory_mem_ck_n                           => HPS_DDR3_CK_N,      --                               .mem_ck_n
        memory_mem_cke                            => HPS_DDR3_CKE,       --                               .mem_cke
        memory_mem_cs_n                           => HPS_DDR3_CS_N,      --                               .mem_cs_n
        memory_mem_ras_n                          => HPS_DDR3_RAS_N,     --                               .mem_ras_n
        memory_mem_cas_n                          => HPS_DDR3_CAS_N,     --                               .mem_cas_n
        memory_mem_we_n                           => HPS_DDR3_WE_N,      --                               .mem_we_n
        memory_mem_reset_n                        => HPS_DDR3_RESET_N,   --                               .mem_reset_n
        memory_mem_dq                             => HPS_DDR3_DQ,        --                               .mem_dq
        memory_mem_dqs                            => HPS_DDR3_DQS_P,     --                               .mem_dqs
        memory_mem_dqs_n                          => HPS_DDR3_DQS_N,     --                               .mem_dqs_n
        memory_mem_odt                            => HPS_DDR3_ODT,       --                               .mem_odt
        memory_mem_dm                             => HPS_DDR3_DM,        --                               .mem_dm
        memory_oct_rzqin                          => HPS_DDR3_RZQ,        --                          reset.reset_n
		  hps_0_h2f_reset_reset_n 						  => rst_n,
		  svga_i_export0									  => burst_address,
		  svga_i_export1									  => burst_size,
		  svga_i_export2									  => burst_start,
		  svga_o_export0									  => word_send,
		  svga_o_export1									  => word_address,
		  svga_o_export2									  => word_o,
		  svga_complete_export							  => transfer_complete
	 );
	 
	 
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
	 
	 
	 
	 
end rtl;