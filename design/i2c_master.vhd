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

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity i2c_master is
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
  --  d_out : out std_logic;
    sdata : inout std_logic
    
    );

end i2c_master;

architecture Behavioral of i2c_master is




TYPE State_type IS (IDLE, ON_CONT, ON_START, OFF_END, ADDRESS, REG_ADDR, READ, WRITE, RESET, SLV_ACK, MSR_ACK);
SIGNAL State : State_Type;

component scl_generator is
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
end component;

-- Four clock phases
constant FALL : std_logic_vector(1 downto 0) := "00"; 
constant NXT : std_logic_vector(1 downto 0) := "01"; 
constant RISE : std_logic_vector(1 downto 0) := "10"; 
constant STABLE : std_logic_vector(1 downto 0) := "11";

-- Internals
signal count : std_logic_vector(2 downto 0);
signal toggle : std_logic;
signal scl_gen : std_logic;
signal scl_toggle : std_logic;
signal scl_quarter : std_logic_vector(1 downto 0);
signal prev_cyc : std_logic_vector(1 downto 0);
signal not_start : std_logic;
signal scl_rise : std_logic;
signal rw_reg : std_logic;
signal seq_cnt : std_logic_vector(1 downto 0);
signal sample_data : std_logic;
signal sample_point : std_logic;
signal change : std_logic;

-- Inputs
signal addr_reg : std_logic_vector(7 downto 0);
signal raddr_reg : std_logic_vector(7 downto 0);
signal write_reg : std_logic_vector(7 downto 0);
signal read_reg : std_logic_vector(7 downto 0);
begin 

scl_generator1 : scl_generator
port map( 
            rst => rst,
            clk => clk,
            scl_gen => scl_gen,
            toggle => toggle,
            scl_quarter => scl_quarter
 );
 
 sclk <= scl_gen OR not_start;
 
process(clk, rst)
begin

end process;
sdata <= 'H';
process(clk, rst) 
begin
-- Change these to use cases rather than ifs. it is messy
if(clk'event and clk='1') then
    if(rst = '1') then -- Reset into idle state
        toggle <= '0';
        not_start <= '0';
        state <= IDLE;
        addr_reg <= x"00";
        raddr_reg <= x"00";
        write_reg <= x"00";        
        seq_cnt <= "00";
    else
        if(toggle = '1') then -- Toggling on scl_generator should only be for 1 clock cycle.
            toggle <= '0';
        else
            toggle <= '0';
        end if;
        -- STORE REGISTERS
        -- NEXT STATE ON_CONT
        if (state = IDLE) and enable = '1' then
            --SAVE ALL REGISTERS
            rw_reg <= r_w;
            state <= ON_START;
            toggle <= '1';
            addr_reg <= dev & r_w;
            raddr_reg <= dev_reg;
            write_reg <= data_w;
            seq_cnt <= "00";
        
        elsif state = ON_START  then
        -- FROM HERE WE SHOULD SET THE LINE AND ALWAYS GO TO ADDR / REG ADDR.
        -- MANUALLY TRIGGER SCL_GEN AND THEN PASS OVER CONTROLS - SCL GEN IS AN ANDED SIGNAL NOT A REGULAR SIGNAL
        -- SET SCL LOW
      
            if ((scl_quarter = NXT) and (change = '1')) then
                state <= ADDRESS;
            end if;
            
            
        elsif state = ON_CONT then
           if ((scl_quarter = NXT) and (change = '1')) then
                state <= ADDRESS;
           else
                state <= ON_CONT;
           end if;
           
        elsif state = SLV_ACK then
            if((scl_quarter = NXT) and (change = '1')) then
                if(sample_data = '0') then
                    seq_cnt <= seq_cnt + "01";
                
                    
                    if(seq_cnt = "00") then
                        state <= REG_ADDR;
                    
                    elsif(seq_cnt = "01") then
                        if(rw_reg = '1') then
                            state <= ON_CONT;
                           -- not_start <= '1'; -- ready for continue
      
                        else
                            seq_cnt <= "11";
                            state <= WRITE;
                        end if;

                    elsif (seq_cnt = "10") then
                        if(rw_reg = '1') then
                            STATE <= READ;
                        else 
                            STATE <= WRITE;
                        end if;
                    elsif (seq_cnt = "11") then
                        state <= OFF_END;
                    end if;
                
                elsif(sample_data = '1') then
                    state <= IDLE;

                   
               end if;
            end if;
        elsif state = ADDRESS then
        -- set outputs on bus
            if((scl_quarter = NXT) and (change = '1')) then
                if (count = 7) then
                    state <= SLV_ACK;
                    --change sdata to in?
                elsif (count = 6) then
                
                     
                    --sdata <= 0 -- always write address to 0 
                    --- THIS IS OUR PROBLEM, ADDRESS MODE SHOULD ALWAYS SET TO 0 FIRST TIME, R/W SECOND AND WITH NOT first_addr.
                    -- can and with first bit of seq_cnt.
                else
                    -- place output
                  
                        -- SHOULD BE READ/WRITE/REGISTER AND NO TOGGLE = '1'
                end if;
                    
            end if;
        
        elsif state = REG_ADDR then
            if((scl_quarter = NXT) and (change = '1')) then
                if (count = 7) then
                    state <= SLV_ACK;
                    --change sdata to in?
                else
                    -- place output
                  
                        -- SHOULD BE READ/WRITE/REGISTER AND NO TOGGLE = '1'
                end if;
           end if;
       elsif state = READ then
            if((scl_quarter = NXT) and (change = '1')) then
                if (count = 7) then
                    state <= SLV_ACK; -- Should be NACK?
                    --change sdata to in?
                elsif (count = 6) then
                    --sdata <= rw_reg
                else
                    -- place output
                  
                        -- SHOULD BE READ/WRITE/REGISTER AND NO TOGGLE = '1'
                end if;
                    
            end if;
            
      elsif state = WRITE then
            if((scl_quarter = NXT) and (change = '1')) then
                if (count = 7) then
                    state <= SLV_ACK;
                    --change sdata to in?
                elsif (count = 6) then
                    --sdata <= rw_reg
                else
                    -- place output
                  
                        -- SHOULD BE READ/WRITE/REGISTER AND NO TOGGLE = '1'
                end if;
            end if;
      elsif state = MSR_ACK then
            --sdata<= '0';
            if((scl_quarter = NXT) and (change = '1')) then
                STATE <= OFF_END;
            end if;
            
      elsif STATE = OFF_END then
            if (scl_quarter = NXT) and (change = '1') then
                STATE <= IDLE;
            else
                STATE <= OFF_END;
            end if;
      end if;
        -- ALWAYS GO TO IDLE STATE FOR 1 SCL_GEN
        
        -- SCL_GEN ZONE
        -- ON SCL_GEN TRIGGER
        
        -- SET STATE TO ADDRESS 
            -- BASED ON PHASE SET STATE TO READ/WRITE OR CONT.
       
        -- SET STATE TO REGISTER
            -- SET TO CONT
        -- SET STATE 
        -- Transfer to idle - set in
        
        
    
    -- First step should be to integrate the counter with scl_gen and make a test_bench for this component, just to make sure it has 
    -- the correct timing properties.
        end if;
        end if;
end process;



--Change on scl_gen

process(clk, rst)
begin
if (clk'event and clk='1') then
    if(rst = '1') then
        scl_rise <= '1';
    else
        
        -- TRIGGER = NOT SCL_GEN
        if(scl_gen = '1') then
            scl_rise <= '0';
        elsif (scl_gen = '0') then
            scl_rise <= '1';
        end if;
    end if;

end if;
end process;
 

--TEST CASES
-- scl_Gen having correct timing
-- Toggling enable disabling scl_gen after sequence.
-- If this works for 8, then can be extended for full transaction.


--Process for sampling / writing to sdata based on state.
process(clk, rst)
begin
if(clk'event and clk='1') then
    if(rst = '1') then
        sdata <= '0';
        sample_data <= '0';
        read_reg <= x"00";
    else
    
    -- To only sample on 1 clock in final half of positive clock
    if(scl_quarter = STABLE and prev_cyc = RISE) then
        sample_point <= '1';
        prev_cyc <= scl_quarter;
    else 
        prev_cyc <= scl_quarter;
        sample_point <= '0';
    end if;
    
    
    
    --TYPE State_type IS (IDLE, ON_CONT, ON_START, OFF_END, ADDRESS, REG_ADDR, READ, WRITE, RESET, SLV_ACK, MSR_ACK);
    case(STATE) is
        when IDLE =>
            sdata <= '0';
            sample_data <= '0';
        when ON_CONT | ON_START=>
            sample_data <= '1';
            if((scl_quarter = STABLE) or (scl_quarter = FALL)) then
                sdata <= '0';
            else
                sdata <= 'Z';
            end if;
        when OFF_END =>
            sample_data <= '0';
            if((scl_quarter = STABLE) or (scl_quarter = FALL)) then
                sdata <= 'Z';
            else
                sdata <= '0';
            end if;
        when ADDRESS =>
            sample_data <= '0';
            if (addr_reg(to_integer(unsigned(count))) = '1') then -- NEEDS TO BE MSB FIRST
                sdata <= 'Z';
            else
                sdata <= '0';
            end if;
        when REG_ADDR =>
            sample_data <= '0';
            if (raddr_reg(to_integer(unsigned(count))) = '1') then -- NEEDS TO BE MSB FIRST
                sdata <= 'Z';
            else
                sdata <= '0';
            end if;
        when READ =>
            sdata <= 'Z';
            sample_data <= sdata;
            if((scl_quarter = STABLE) and sample_point = '1') then
            
            case(sdata) is
                when 'H' | '1' =>
                        read_reg(to_integer(unsigned(count))) <= '1'; -- NEEDS TO BE MSB FIRST ALL SAMPLES SHOULD BE PUT TO 1
                when '0' =>
                        read_reg(to_integer(unsigned(count))) <= '0';
                when others =>
                        read_reg(to_integer(unsigned(count))) <= '0';
                end case; 
            
            end if;                
        when WRITE =>
            sample_data <= '0';
            if (write_reg(to_integer(unsigned(count))) = '1') then -- NEEDS TO BE MSB FIRST
                sdata <= 'Z';
            else
                sdata <= '0';
            end if;
        when SLV_ACK =>
            sdata <= 'Z';
            if(scl_quarter = STABLE and sample_point = '1') then
                case(sdata) is
                    when 'H' | '1' =>
                        sample_data <= '1';
                    when '0' =>
                        sample_data <= '0';
                    when others =>
                        sample_data <= '0';
                    end case;
            else
                sample_data <= sample_data;
            end if;
        when MSR_ACK =>
            sample_data <= '0';
            sdata <= '0';
            
            -- ADD master NACK
        when RESET =>
            sdata <= '0';
            sample_data <= '0';  
    end case;
    
    end if;
    
end if;
end process;





-- Counter, set to count through states ADDRESS, REG_ADDR, READ, WRITE
process(clk, rst)
begin
if(clk'event and clk='1') then
    if (rst = '1') then
         count <= (others=>'0'); 
         change <= '0'; 
    else
        if (scl_gen = '1') then
            change <= '1';
        elsif((scl_quarter = NXT) and (change = '1')) then -- Set to result of the counter -- falling edge means starts at 0 when transaction begins.
            change <= '0';
            case state is
                when ADDRESS | REG_ADDR | READ | WRITE =>
                    count <= count+'1';
                when others =>
                    count <= (others=>'0');
            -- Add reset state and conditions - reset and reset only counter, and i_start.
            end case;
       end if;
    end if;
end if;
end process;

end Behavioral;
--TODO
--REPLACE ALL "TRIGGERS" WITH SCL_GEN'EVENT AND = 1 ETC.