 -- Quartus Prime VHDL Template
-- Single port RAM with single read/write address 

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.all;
use IEEE.std_logic_unsigned.all;


entity DE10_NANO_SoC_GHRD_TB is
--  Port ( );
end DE10_NANO_SoC_GHRD_TB;

architecture Behavioural of DE10_NANO_SoC_GHRD_TB is

component DE10_NANO_SoC_GHRD is
    port 
    (
        -------- CLOCKS --------------------
        clk		: in 	std_logic;
        FPGA_CLK2_50		: in 	std_logic;
        FPGA_CLK3_50		: in	std_logic;
        -- HPS ----------------------------
--        HPS_DDR3_ADDR		: out	std_logic_vector(14 downto 0);
--        HPS_DDR3_BA		: out	std_logic_vector(2 downto 0);
--        HPS_DDR3_CAS_N		: out	std_logic;
--        HPS_DDR3_CK_N		: out	std_logic;
--        HPS_DDR3_CK_P		: out	std_logic;
--        HPS_DDR3_CKE		: out	std_logic;
--        HPS_DDR3_CS_N		: out	std_logic;
--        HPS_DDR3_DM		: out	std_logic_vector(3 downto 0);
--        HPS_DDR3_DQ		: inout	std_logic_vector(31 downto 0);
--        HPS_DDR3_DQS_N		: inout	std_logic_vector(3 downto 0);
--        HPS_DDR3_DQS_P		: inout	std_logic_vector(3 downto 0);
--       HPS_DDR3_ODT		: out	std_logic;
--        HPS_DDR3_RAS_N		: out	std_logic;
--        HPS_DDR3_RESET_N	: out	std_logic;
--        HPS_DDR3_RZQ		: in	std_logic;
--        HPS_DDR3_WE_N		: out	std_logic;
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
end COMPONENT;

begin




end Behavioral;
