
-- General idea : - Bring in SCL_GEN at 4 CLK - 80 NS per clock
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use ieee.std_logic_unsigned.all;
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity svga_master is
generic ( 
			mclk_freq : integer := 25000000
);
port(
	 -- FPGA internal
    rst : in std_logic;
    clk : in std_logic;
	 enable : in std_logic;
	 data_o : out std_logic_vector(9 downto 0);
	 data_valid : out std_logic;
	 
	 -- Interface
	 mclk : out std_logic;
	 data_i : in std_logic_vector(9 downto 0);
	 HREF : in std_logic;
	 MHSYNC : out std_logic;
	 MVSYNC : out std_logic
	 
    );
end svga_master;




architecture svga_master_arch of svga_master is

--Concerning entire frame.
--FRAME
constant LINE_COUNT : integer := 1190;
constant LINE_OFF : integer := 80;


constant FRAME_SIZE : integer := 672 * LINE_COUNT;

--FRAME BREAKDOWN
constant VSYNC_LINES : integer := LINE_COUNT * 4;
constant VREAR_LINES : integer := LINE_COUNT * 6; -- May be + 15?
constant VFRONT_LINES : integer := LINE_COUNT * 62; -- May also have to add clocks.
constant ROW_EN : integer := LINE_COUNT * 600;

--Concerning HSYNC and LINE BREAKDOWN
--Total HSYNC = Line
constant HSYNC_ON : integer := LINE_COUNT - LINE_OFF;
constant HSYNC_OFF : integer := LINE_OFF;
-- HREF IN HSYNC PERIODS
constant HREF_START : integer := 179 + LINE_OFF;
constant HREF_END : integer := 979 + LINE_OFF;




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

constant VSYNC_TIME; -- More than 1 line
constant HSYNC_TIME; -- more than 6 cycles.
constant VSYNC_PERIOD; -- 672 * Time of line
constant HSYNC_PERIOD; -- Time of line

TYPE State_type IS (IDLE, AKTIV);
SIGNAL State : State_Type;

TYPE Phase_type IS (VSYNC, V_REAR, V_FRONT, ROW_EN);
SIGNAL PHASE : Phase_Type;

signal enable_change : std_logic;
signal LINE_COUNT std_logic_vector;
signal mclk_toggle : std_logic;
begin

scl_generator_svga : scl_generator
		generic map (
				threshold => (50000000/mclk_freq)
				)
		port map( 
            rst => rst,
            clk => clk,
            scl_gen => sig_mclk,
            toggle => mclk_toggle,
            scl_quarter => mclk_quarter
		);
mclk <= sig_mclk;		
		
-- FSM controller process.
process(rst, clk)
begin
	if	(rst='1') then
		enable_change <= '1';
		mclk_toggle <= '0';
	elsif (clk'event and clk='1') then
		  if(enable = '1') then
            enable_change <= '0';
        elsif (enable = '0') then
            enable_change <= '1';
        end if;
		  
		  if enable = '1' and enable_change = '1' then
				if(STATE = AKTIV) then
					STATE <= IDLE;
					mclk_toggle <= '0';
				elsif(STATE = IDLE) then
					STATE <= AKTIV;
					mclk_toggle <= '1';
				else 
					STATE <= STATE;
					mclk_toggle <= '0';
				end if;
			else
				mclk_toggle <= '0';
			end if;
	end if;
end process;
-- Put in, enable = '1' and (on rise to '1'.), then enable scl_generator_svga,
-- Move into initial state (from initial to idle). Could have output/input manager and one for internal state.

--May need some kind of counter.

--MCLK, HREF, VSYNC CONTROLLER
process(rst, clk)
begin
	if (rst='1') then
		data_o <= (others => '0');
		data_valid <= '0';
		MHSYNC <= '0';
		MVSYNC <= '0';
		
	elsif(clk'event and clk='1') then
		case(STATE) is
		
			when IDLE =>
				MHSYNC <= '0';
				MVSYNC <= '0';
				data_valid <= '0';
			when AKTIV =>
			--MCLK must be enabled !
					case(PHASE) is
					
						when VSYNC =>
							--Start here
							if(LINE_COUNT =
							VSYNC <= '1';
						when V_REAR =>
							VSYNC <= '0';
						when V_FRONT =>
							VSYNC <= '0';
						when ROW_EN =>
							VSYNC <= '0';
					end case;
				-- New Line -> Gonna need second FSM.
				
				--Starts with VSYNC = 1;
				--HSYNC = 0 THEN 1 -- STARTS AS SOON AS HSYNC = 1;
				--Line is time between HREFS = time between hsyncs = 1190.
		end case;
	
	
	end if;

end process;
		

end svga_master_arch;
--	Design considerations --
--	Enable on 0 to 1, not "stay at 1"
-- States -- Off, idle, read.
-- Implement Clock, divided, 50Mhz.

--So VSYNC, while HSYNC, then HREF means data valid. In this case, we should have data_valid signal out.
-- Hsync time - 1190 total, 80 Sync, 179 Front porch, 800 Href, 131 back porch.
-- Vsync time - 73895 front porch, 4 * Hsync is Vsync, 1190 * 800 Vref, 7415 back porch - apparently 672 * Hsync but doesn't make sense
-- Frame time - Vsync time * 600