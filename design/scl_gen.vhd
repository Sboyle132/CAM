library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;
use ieee.std_logic_unsigned.all;
-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity scl_generator is

generic ( 
			threshold : integer := 16
);
port (
rst : in std_logic;
clk : in std_logic;
toggle : in std_logic;
scl_gen : out std_logic;
scl_quarter : out std_logic_vector(1 downto 0)
);

end scl_generator;


architecture Behavioral of scl_generator is
signal count : std_logic_vector(15 downto 0);
signal half_threshold : std_logic_vector(15 downto 0) := std_logic_vector(to_unsigned(threshold/2, 16));
signal quarter_threshold : std_logic_vector(15 downto 0) := std_logic_vector(to_unsigned(threshold/4, 16));
signal upper_threshold : std_logic_vector(15 downto 0) := std_logic_vector(to_unsigned(3*threshold/4, 16));
signal start_stop : std_logic := '0';
signal enable_rise : std_logic := '0';
signal scl_generator : std_logic;
begin

process(clk, rst)
begin
if (clk'event and clk = '1') then
    if (rst = '1') then
        start_stop <= '0';
        enable_rise <= '1';
    else
        if(toggle = '1') then
            enable_rise <= '0';
        elsif (toggle = '0') then
            enable_rise <= '1';
        end if;
    
        if toggle='1' and enable_rise='1' then --SCL START is toggle, high or low for many cycles, Trigger ensures only one activation  replace with rising edge toggle and = '1'
            start_stop <= not start_stop;
        end if;
    end if;
end if;
end process;

scl_gen <= scl_generator;

process(clk, rst)
begin
if (clk'event and clk = '1') then 
    if (rst = '1') then
        scl_generator <= '0';
        count <= (others=>'0');
        scl_quarter <= (others=>'0');
    
        --start_stop <= '0';
    else
        if (start_stop = '1') then
            -- Reversing this may need to be a mode.
            if(count > (half_threshold-'1')) then
                scl_generator <= '1';
                if (count = (threshold-1)) then
                    count <= (others=>'0');
                
                else
                    count <= count + '1';
                end if;
            elsif (half_threshold > count) then
                scl_generator <= '0';
                count <= count + '1';
    
            end if;
        else
            count <= (others=>'0');
            scl_generator <='0';    
        end if;
        
		  if(count > upper_threshold - '1') then
			scl_quarter <= "11";
		  elsif (count > half_threshold - '1') then
			scl_quarter <= "10";
		  elsif (count > quarter_threshold - '1') then
			scl_quarter <= "01";
		  else
			scl_quarter <= "00";
		  end if;
--        if(scl_generator = '1' and count > half_threshold-'1') then
--            if((count > upper_threshold - 1)) then -- or (count = x"0000"))  then
--                scl_quarter <= "11";
--            else
--                scl_quarter <= "10";
--            end if;
--        else
--            if(count > quarter_threshold - 1) then
--                scl_quarter <= "01";
--            else
--                scl_quarter <= "00";
--            end if;
--        end if;
            
end if;
end if;

end process;

--Control frame count and MCLK count
process(clk, rst)
begin
if(clk'event and clk='1') then
	if(reset = '1') then
	else
	MCLK...
end if;
end if;
end process;
end Behavioral;