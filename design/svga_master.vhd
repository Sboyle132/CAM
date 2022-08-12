
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
constant ROW_EN_LINES : integer := LINE_COUNT * 600;

--Concerning HSYNC and LINE BREAKDOWN
--Total HSYNC = Line
constant HSYNC_ON : integer := LINE_COUNT - LINE_OFF;
constant HSYNC_OFF : integer := LINE_OFF;
-- HREF IN HSYNC PERIODS
constant HREF_START : integer := 179 + LINE_OFF;
constant HREF_END : integer := 979 + LINE_OFF;
-- FOR CAM SYNCHRONISATION
constant full_threshold : integer := (50000000/mclk_freq); -- for synchronisation
constant half_threshold : integer := (50000000/mclk_freq)/2; -- for synchronisation
signal count_cyc : std_logic_vector(15 downto 0);
signal mclk_count : std_logic_vector(31 downto 0);
signal mrise_2cyc : std_logic;
--mclk buffer
signal sig_mclk : std_logic;
signal prev_mclk : std_logic;

signal sync_start : std_logic;
--HSYNC Count
signal H_cyc : std_logic_vector(15 downto 0);
signal phase_change : std_logic;
signal sampled_count : std_logic_vector(15 downto 0);
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

--constant VSYNC_TIME; -- More than 1 line
--constant HSYNC_TIME; -- more than 6 cycles.
--constant VSYNC_PERIOD; -- 672 * Time of line
--constant HSYNC_PERIOD; -- Time of line


TYPE State_type IS (IDLE, AKTIV);
SIGNAL State : State_Type;

TYPE Phase_type IS (VSYNC, V_REAR, V_FRONT, ROW_EN, SYNCHRONISE, IDLE);
SIGNAL PHASE : Phase_Type;
SIGNAL PREV_PHASE : Phase_Type;
SIGNAL PREV_STATE :State_Type;
signal HREF_ACTIVE : std_logic;
signal state_change : std_logic;
signal sampled : std_logic;

signal enable_change : std_logic;
--signal LINE_COUNT std_logic_vector(16 downto 0);
signal mclk_toggle : std_logic;

signal mclk_quarter : std_logic_vector(1 downto 0);
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
					mclk_toggle <= '1';
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
		MHSYNC <= '0';
		MVSYNC <= '0';
		--V_cyc <= (others => '0');
		
	elsif(clk'event and clk='1') then
		case(STATE) is
		
			when IDLE =>
				MHSYNC <= '0';
				MVSYNC <= '0';				
			
			when AKTIV =>
			--MCLK must be enabled  We also need to synchronise these changes in terms of MCLKs.
			-- H_cyc must be handled in same place as MCLK.
					case(PHASE) is
						when SYNCHRONISE =>
							MVSYNC <= '0';
							MHSYNC <= '0';
							--V_cyc <= (others => '0');
						when VSYNC =>
							MVSYNC <= '1';
							if (mrise_2cyc = '1') then
								if(H_cyc <= LINE_OFF) then
									MHSYNC <= '0';
								elsif(H_cyc <= LINE_COUNT) then
									MHSYNC <= '1';
								else
									MHSYNC <= '0';
								end if;
							end if;
						when V_REAR =>
							MVSYNC <= '0';
							if (mrise_2cyc = '1') then
								if(H_cyc < LINE_OFF) then
									MHSYNC <= '0';
								elsif(H_cyc < LINE_COUNT) then
									MHSYNC <= '1';
								else
									MHSYNC <= '0';
								end if;
							end if;
						when V_FRONT =>
							MVSYNC <= '0';
							if (mrise_2cyc = '1') then
								if(H_cyc < LINE_OFF) then
									MHSYNC <= '0';
								elsif(H_cyc < LINE_COUNT) then
									MHSYNC <= '1';
								else
									MHSYNC <= '0';
								end if;
							end if;
						when ROW_EN =>
							MVSYNC <= '0';
							if (mrise_2cyc = '1') then
								if(H_cyc < LINE_OFF) then
									MHSYNC <= '0';
								elsif(H_cyc < LINE_COUNT) then
									MHSYNC <= '1';
								else
									MHSYNC <= '0';
								end if;
							end if;
						when others =>
						
					end case;
				-- New Line -> Gonna need second FSM.
				
				--Starts with VSYNC = 1;
				--HSYNC = 0 THEN 1 -- STARTS AS SOON AS HSYNC = 1;
				--Line is time between HREFS = time between hsyncs = 1190.
		end case;
	
	
	end if;

end process;

--Output process
process(clk, rst)
begin
if(clk'event and clk='1') then
	if(rst = '1') then
		data_o <= (others => '0');
		data_valid <= '0';
		sampled_count <= (others => '0');
		HREF_ACTIVE <= '0';
		sampled <= '0';
	else
		if(PHASE = ROW_EN) then
			if((H_cyc > HREF_START - 1) and (H_cyc < HREF_END)) then
				HREF_ACTIVE <= '1';
				if((sig_mclk = '1') and (sampled = '0')) then
					sampled <= '1';
					data_o <= data_i;
					data_valid <= '1';
					if (HREF = '1') then
						sampled_count <= sampled_count + '1';
					end if;
				elsif(sig_mclk = '0') then
					sampled <= '0';
					data_valid <= '0';
				else
					sampled <= sampled;
					data_valid <= '0';
				end if;
			else
				sampled <= '0';
				data_valid <= '0';
				sampled_count <= (others => '0');
				HREF_ACTIVE <= '0';
			end if;
		end if;
	end if;
	
end if;
end process;
--Control frame count and MCLK count
--Also control synchronisation of VSYNC, HSYNC WITH RISING EDGE OF MCLK.
--Just for phase changes.
process(clk, rst)
begin
if(clk'event and clk='1') then
	if(rst = '1') then
		phase_change <= '0';
	else
		phase_change <= '0';
		CASE(PHASE) is		
				when VSYNC =>
					if(mclk_count = VSYNC_LINES) then
						phase_change <= '1';
					end if;
				when V_REAR =>
					if(mclk_count = VSYNC_LINES + VREAR_LINES) then
						phase_change <= '1';
					end if;
				when ROW_EN =>
					if(mclk_count = VSYNC_LINES + VREAR_LINES + ROW_EN_LINES) then
						phase_change <= '1';
					end if;
				when V_FRONT =>
					if(mclk_count = VSYNC_LINES + VREAR_LINES + ROW_EN_LINES + VFRONT_LINES) then
							phase_change <= '1';
					end if;
				when OTHERS =>
					phase_change <= '0';
				end case;
	end if;
end if;
end process;

process(clk, rst)
begin
if(clk'event and clk='1') then
	if(rst = '1') then
		PHASE <= IDLE;
		count_cyc <= x"0000";
		mclk_count <= (others => '0');
		mrise_2cyc <= '0';
		prev_mclk <= '0';
		H_cyc <= x"0000";
		sync_start <= '0';
	else
		if(not (PHASE = IDLE) and (STATE = IDLE)) then
			PHASE <= IDLE;
		elsif(PHASE = IDLE and STATE = AKTIV) then
			PHASE <= SYNCHRONISE;
		else 
			PHASE <= PHASE;
		end if;
	case(PHASE) is
	
		when IDLE =>

		when SYNCHRONISE =>
			prev_mclk <= sig_mclk;
			if(prev_mclk = '0' and sig_mclk = '1') then
				sync_start <= '1';
				count_cyc <=	x"0001"; 
				--Ignore next cycle sync_start since 25MHZ leaves not enough time.
				if(full_threshold = 2 and sig_mclk = '1') then
					PHASE <= VSYNC;
					sync_start <= '0';
					count_cyc <= x"0000";
					H_cyc <= x"0000";
					sync_start <= '0';
					mrise_2cyc <= '1';

				end if;
				--Sync start as normal, in this case count_cyc entering should be 1 as one cycle is used to update sync_start value
			elsif (sync_start <= '1') then
				count_cyc <= count_cyc + '1';
				--Two cycles until VSNYC is one, one to enter phase, one to switch VSYNC Active.
				--On counter = '0' MCLK is still one, so FULL_THRESHOLD - 1 is still applicable. -- Check this
				if((count_cyc + 1) = full_threshold - 1) then
					PHASE <= VSYNC;
					H_cyc <= x"0000";
					sync_start <= '0';
					mrise_2cyc <= '1';
					count_cyc <= x"0000";
					sync_start <= '0';
				end if;
			else
				count_cyc <= (others => '0');
			end if;
			--Test whether VSNYC, mclk_count and rising MCLK edge align properly.
		
		when others =>
			count_cyc <= count_cyc + '1';
			--Case for 25MHZ
			if(full_threshold = 2 and sig_mclk = '1') then
				mrise_2cyc <= '1';
				count_cyc <= x"0000";
				mclk_count <= mclk_count + '1';
				if(H_cyc < LINE_COUNT) then
					H_cyc <= H_cyc + '1';			
				else 
				H_cyc <= x"0001" - phase_change;
				end if;
			--Case for all lower
			--Is elsif also so don't worry
			elsif(mclk_count = full_threshold - 1) then
				mrise_2cyc <= '1';
				count_cyc <= x"0000";
				mclk_count <= mclk_count + '1';
				if(H_cyc < LINE_COUNT) then
					H_cyc <= H_cyc + '1';			
				else 
					H_cyc <= x"0001" - phase_change;
			end if;
			else
				mrise_2cyc <= '0';
			end if;
			--When we enter next cycle MCLK is 1 (next cycle, we are 1 behind). So  should be 0.
			--We also need to apply PHASE Change here to avoid losing a clock cycle.
			if((full_threshold = 2 and sig_mclk='1') or ((mclk_count = full_threshold - 1) and (not (full_threshold = 2)))) then
				CASE(PHASE) is
				when VSYNC =>
					if(mclk_count = VSYNC_LINES) then
						PHASE <= V_REAR;
					end if;
				when V_REAR =>
					if(mclk_count = VSYNC_LINES + VREAR_LINES) then
						PHASE <= ROW_EN;
					end if;
				when ROW_EN =>
					if(mclk_count = VSYNC_LINES + VREAR_LINES + ROW_EN_LINES) then
						PHASE <= V_FRONT;
					end if;
				when V_FRONT =>
					if(mclk_count = VSYNC_LINES + VREAR_LINES + ROW_EN_LINES + VFRONT_LINES) then
							PHASE <= VSYNC;
							mclk_count <= (others => '0');
							H_cyc <= (others => '0');
							
					end if;
				when OTHERS =>
					
				
				end case;
				
			end if;
		
		
		-- Now we can start counting in active. VSYNC Becomes 1 one cycle after we change to this state.		
			
	end case;
	-- If mclk = 1 and prev_clock mclk = 0; in threshold cycles clock = 1 again. (therefore threshold can also indicate next mclk).
	
	end if;
end if;
	--If state = aktiv. (
	
	--We need to count MCLKs, without delay, on their exact rise time. Options - get half_threshold value.
	-- Problem -> we rely on enable. (enable enables counting in MCLK_controller.) but we can use state AKTIV for this?
	-- It's looking possible. on state aktiv -> 0 then switches to 1.
		
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