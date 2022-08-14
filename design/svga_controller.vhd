library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use ieee.std_logic_unsigned.all;
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity svga_controller is
generic ( 
			mclk_freq : integer := 25000000
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
	 transfer_complete : out std_logic;

	 -- Interface
	 mclk : out std_logic;
	 data_i : in std_logic_vector(9 downto 0);
	 HREF : in std_logic;
	 MHSYNC : out std_logic;
	 MVSYNC : out std_logic;
	 
	 --debug
	 sampled_out : out std_logic_vector(15 downto 0);
	 mode : in std_logic
    );
end svga_controller;
--needded from/to top
--GENERIC SET.
--clk, rst, data_o, data_i, href, sigmhsync, sigmvsync, data_transfer_complete,

-- Structure - just set enable 1 for one clock cycle in initial reset state. Then we move to idle where we wait for
-- data from avalon. Address and size, start is implicit in (WRITE_SIGNAL_ENABLE).
architecture svga_controller_arch of svga_controller is

--Output/input buffers
--MHSYNC, VSYNC Validity
signal initialised : std_logic;



COMPONENT svga_master is
	generic ( 
			mclk_freq : integer
	);
	port(
	 -- FPGA internal
    rst : in std_logic;
    clk : in std_logic;
	 enable : in std_logic;
	 data_o : out std_logic_vector(9 downto 0);
	 data_valid : out std_logic;
	 continue : in std_logic;
	 frame_valid : out std_logic;
	 frame_end : out std_logic;
	 
	 -- Interface
	 mclk : out std_logic;
	 data_i : in std_logic_vector(9 downto 0);
	 HREF : in std_logic;
	 MHSYNC : out std_logic;
	 MVSYNC : out std_logic
    );
END COMPONENT;
--Component signals of SVGA_MASTER
signal sig_MHSYNC : std_logic;
signal sig_MVSYNC : std_logic;
signal enable : std_logic;
signal data_o : std_logic_vector(9 downto 0);
signal data_valid : std_logic;
signal continue : std_logic;
signal frame_valid : std_logic;
signal frame_end : std_logic;
-- More buffers
signal sig_continue : std_logic;


--For outputting data

TYPE OUT_type IS (WAITING, OUTPUTTING);
SIGNAL OUT_STATE : OUT_Type;

signal out_counter : std_logic_vector(3 downto 0);
signal carryover_2 : std_logic;
signal offset : std_logic_vector(3 downto 0);
signal word_offset : std_logic_vector(3 downto 0);
signal data_carry : std_logic_vector(7 downto 0);

signal sig_word_send : std_logic;

signal size : std_logic_vector(31 downto 0);
signal address : std_logic_vector(31 downto 0);
--Initilisation
signal enable_pclk : std_logic;

begin

word_send <= sig_word_send;
word_address <= address;

SVGA_MASTER0 : SVGA_MASTER
		generic map(
			mclk_freq => mclk_freq 
		)
		PORT MAP (
			clk => clk,
			rst => rst,
			enable => enable,
			data_o => data_o,
			data_valid => data_valid,
			mclk => mclk,
			data_i => data_i,
			HREF => HREF,
			MHSYNC => sig_MHSYNC,
			MVSYNC => sig_MVSYNC,
			continue => continue,
			frame_valid => frame_valid,
			frame_end => frame_end
		);

--Combinatorial MHSYNC, MVSYNC.
--case initiliased is-- we set initialised internally. Based on Continue and frame_valid.
--	when '1' =>
--		MHSYNC <= sig_MHSYNC;
--		MVSYNC <= sig_MVSYNC;
--   when '0' =>
--		MHSYNC <= '1';
--		MVSYNC <= '0';
--end case;

MHSYNC <= sig_MHSYNC OR (not initialised);
MVSYNC <= sig_MVSYNC and initialised;
--with initialised select MHSYNC <=
--		sig_MVSYNC when '1',
--		'0' when '0',
--		'0' when others;


continue <= sig_continue;
--Always enable pclk.
process(clk, rst) 
begin
if(clk'event and clk='1') then
	if(rst = '1') then
		enable_pclk <= '1';
		enable <= '0';
		
	elsif(enable_pclk = '1') then
		enable <= '1';
		enable_pclk <= '0';
	else
		enable <= '0';
		enable_pclk <= enable_pclk;
	end if;
end if;
end process;
		
		
--Process to determine initialisation.
process(clk, rst)
begin
if(clk'event and clk='1') then
	if(rst = '1') then
		initialised <= '0';
		OUT_STATE <= WAITING;
	else
		-- We will use this by holding the fact, continue can only be one if data is in.
		-- How can we guarantee that the camera is initialised though?
		if(frame_valid = '1' and sig_continue = '1') then
			initialised <= '1';
			OUT_STATE <= OUTPUTTING;
		else
			initialised <= initialised;
			OUT_STATE <= OUT_STATE;
		end if;

	end if;
end if;	
end process;


--Process for address handling
process(clk, rst)
begin
if(clk'event and clk='1') then
	if(rst = '1') then
			size <= x"00000000";
			address <= x"20000000";
			sig_continue <= '0';
			transfer_complete <= '0';
	else
		transfer_complete <= '0';
		if(size > x"00000000") then
			sig_continue <= '1';
			if(sig_word_send = '1') then
				address <= address + x"4";
			end if;	
			if(frame_valid = '1' and frame_end = '1') then
				size <= size - '1';
				if(size - '1' = x"00000000") then
					transfer_complete <= '1';
				end if;
			end if;
		elsif (burst_start = '1' and frame_valid = '0') then
			address <= burst_address;
			size <= burst_size;
		else
			sig_continue <= '0';
		end if;
	end if;
end if;
end process;
--So enabled PCLK, and initialised is determined. Now data_valid is all we need.
--Process to output data -- Needs states OUTPUT_IDLE, OUTPUT_SENDING .And a counter up to 3
process(clk, rst) 
begin
if(clk'event and clk='1') then
	
	if(rst = '1') then
		out_counter <= (others => '0');
		offset <= (others => '0');
		word_offset <= x"0";
		data_carry <= (others => '0');
		carryover_2 <= '0';
		sig_word_send <= '0';
		word_o <= (others => '0');
	else
		case(OUT_STATE) is
			
			when WAITING =>
				out_counter <= (others => '0');
				offset <= (others => '0');
				word_offset <= x"0";
				data_carry <= (others => '0');
				carryover_2 <= '0';
			
			when OUTPUTTING =>
			
			sig_word_send <= '0';
			
			if(MODE = '0') then --RGB
				if(data_valid = '1' and frame_valid = '1') then
					out_counter <= out_counter + '1';
					if(out_counter < 3) then
						word_o((8*(to_integer(unsigned(out_counter))+1) - 1) downto (8*to_integer(unsigned(out_counter)))) <= data_o(9 downto 2);
					else
						out_counter <= x"0";
						sig_word_send <= '1';
						word_o(31 downto 24) <= data_o(9 downto 2);
					end if;
				end if;
						
				
			elsif(MODE = '1' ) then --Raw RGB
					if(data_valid = '1' and frame_valid = '1') then
						out_counter <= out_counter + '1';						
							if(out_counter < (3 - to_integer(unsigned(x"0" + carryover_2)))) then
								word_o((to_integer(unsigned(offset)) + (10*(to_integer(unsigned(out_counter))+1)-1)) downto (to_integer(unsigned(offset)) + (10*to_integer(unsigned(out_counter))))) <= data_o;
							else
								word_offset <= word_offset + '1';
								out_counter <= x"0";
								sig_word_send <= '1';
								
								--Placing data in correct place.
								case(word_offset) is
									when x"0" =>
										offset <= x"8"; -- Add 2 at end -- Taken from start.
										carryover_2 <= '1';
										word_o(31 downto 30) <= data_o(1 downto 0);
										data_carry <= data_o(9 downto 2);
										word_offset <= x"1";
									when x"1" =>
										offset <= x"6"; -- Add 8 at start.
										word_o(7 downto 0) <= data_carry;
										word_o(31 downto 28) <= data_o(3 downto 0);
										carryover_2 <= '1';
										data_carry(5 downto 0) <= data_o(9 downto 4);
										word_offset <= x"2";
									when x"2" =>
										offset <= x"4"; -- Add 6 at start
										word_o(5 downto 0) <= data_carry(5 downto 0);
										word_o(31 downto 26) <= data_o(5 downto 0);
										carryover_2 <= '1';
										data_carry(3 downto 0) <= data_o(9 downto 6);
										word_offset <= x"3";
									when x"3" =>
										offset <= x"2"; -- add 4 at start
										word_o(3 downto 0) <= data_carry(3 downto 0);
										word_o(31 downto 24) <= data_o(7 downto 0);
										carryover_2 <= '0';
										data_carry(1 downto 0) <= data_o(9 downto 8);
										word_offset <= x"4";
									when x"4" =>
										offset <= x"0"; -- add 2 at start
										word_o(1 downto 0) <= data_carry(1 downto 0);
										word_o(31 downto 24) <= data_o(7 downto 0);
										carryover_2 <= '0';
										data_carry(1 downto 0) <= data_o(9 downto 8);
										word_offset <= x"0";
									when others =>
								end case;
							end if;
						elsif(frame_valid = '1' and frame_end = '1') then
							word_offset <= x"0";
							offset <= x"0";
							carryover_2 <= '0';
							out_counter <= x"0";
							if(not (out_counter = x"0") or not(offset = x"0")) then
								sig_word_send <= '1';
								--Output all just without ending.
								case(word_offset) is 
									when x"0" =>
										--nothing to do.
									when x"1" =>
										word_o(7 downto 0) <= data_carry;
									when x"2" =>
										word_o(5 downto 0) <= data_carry(5 downto 0);
								
								   when x"3" =>
										word_o(3 downto 0) <= data_carry(3 downto 0);
								
									when x"4" =>
										word_o(1 downto 0) <= data_carry (1 downto 0);
									when others =>
								end case;
							end if;
						end if;
			end if;
		end case;
	end if;
end if;

end process;

-- Process to read inputs and start
--Continue must be used based on inputs.
-- Process to 








end svga_controller_arch;
		
		
		
		
		
		
		
		
		
		
		
		
		
		
		
		
		
		