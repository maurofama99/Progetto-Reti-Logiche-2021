
----------------------------------------------------------------------------------
-- Students: Mauro Famà
--           Elia Fantini
-- 
-- Module Name: project_reti_logiche - Behavioral

----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.ALL;

entity project_reti_logiche is
    Port ( i_clk : in std_logic;
           i_rst : in std_logic;
           i_start : in std_logic;
           i_data : in std_logic_vector(7 downto 0);
           o_address : out std_logic_vector(15 downto 0);
           o_done : out std_logic;
           o_en : out std_logic;
           o_we : out std_logic;
           o_data : out std_logic_vector(7 downto 0)
           );
end project_reti_logiche;

architecture Behavioral of project_reti_logiche is
    type state_type is (INIT,RESET,START,READ_N_COL,CALCULATE_WRITE_ADDR,
                        COMPARE_MAX_MIN, CALCULATE_SHIFT_LEVEL,
                        CALCULATE_NEW_PIXEL_VALUE,WRITE_NEW_PIXEL_VALUE,DONE);
    signal next_state : state_type:=INIT;
    signal curr_state : state_type:=INIT;
    signal curr_addr: UNSIGNED(15 downto 0):="0000000000000000";
    signal write_addr: UNSIGNED(15 downto 0):="0000000000000000";
    signal n_col: UNSIGNED(7 downto 0):="00000000";
    signal max_pixel_value: std_logic_vector(7 downto 0):="00000000";
    signal min_pixel_value: std_logic_vector(7 downto 0):="11111111";
    signal delta_value: std_logic_vector(7 downto 0):="11111111";
    signal shift_level: std_logic_vector (3 downto 0):="0000";
    signal new_pixel_value: UNSIGNED (7 downto 0):="00000000";
    
begin

    o_address <= std_logic_vector(curr_addr);

    state_reg:process(i_clk,i_rst)
    begin
        if(i_rst= '1') then
            curr_state<= RESET;
        elsif rising_edge(i_clk)then
            curr_state<= next_state;
        end if;  
    end process;
          
   lambda:process(curr_state,i_clk,i_start)
  begin
      if falling_edge(i_clk) then
         case curr_state is 
            when RESET =>
                if i_start = '1' then
                   next_state<= START;
               end if;
             when START =>
                  next_state <= READ_N_COL;
             when READ_N_COL =>
                next_state<= CALCULATE_WRITE_ADDR;    
             when CALCULATE_WRITE_ADDR =>
                 next_state<= COMPARE_MAX_MIN;  
             when COMPARE_MAX_MIN =>
                    if ( curr_addr >= write_addr ) then
                        next_state<= CALCULATE_SHIFT_LEVEL;
                    end if;    
             when CALCULATE_SHIFT_LEVEL =>
                    next_state<= CALCULATE_NEW_PIXEL_VALUE;
             when CALCULATE_NEW_PIXEL_VALUE =>
                    next_state<= WRITE_NEW_PIXEL_VALUE;
             when WRITE_NEW_PIXEL_VALUE =>
                    if ( curr_addr < write_addr + 1 ) then
                        next_state<= CALCULATE_NEW_PIXEL_VALUE;
                    elsif (curr_addr = write_addr + 1) then 
                        next_state<= DONE;
                    end if;
             when others => next_state <= RESET;
             
            end case;
        end if;
    end process;
                       
           
    delta:process(curr_state,i_clk,i_start)     
    begin
        if falling_edge(i_clk) then
            case curr_state is
        
                when RESET =>
                    curr_addr <= "0000000000000000";
                    write_addr <= "0000000000000000";
                    n_col <= "00000000";
                    max_pixel_value <= "00000000";
                    min_pixel_value <= "11111111";
                    shift_level <= "0000";
                    new_pixel_value <= "00000000";  
                    delta_value<="11111111";
                    o_done <= '0';
                    
                when START =>
                    o_en <= '1';
                    
                when READ_N_COL =>
                    n_col <= UNSIGNED(i_data);
                    curr_addr <= curr_addr + 1;
                    
                when CALCULATE_WRITE_ADDR =>
                    write_addr <= 2 + (UNSIGNED(i_data) * n_col);
                    curr_addr <= curr_addr + 1; 
                    
                when COMPARE_MAX_MIN =>
                    if ( i_data < min_pixel_value ) then
                        min_pixel_value <= i_data;
                        end if;
                    if ( i_data > max_pixel_value ) then
                        max_pixel_value <= i_data;
                        end if;
                    curr_addr <= curr_addr + 1;
                    if ( curr_addr = write_addr ) then 
                        write_addr <= write_addr - 2; 
                        end if;
                    curr_addr <= curr_addr - write_addr; --riporto curr_addr al primo pixel;    
                         
               when CALCULATE_SHIFT_LEVEL =>
                    delta_value<= std_logic_vector(UNSIGNED(max_pixel_value)- UNSIGNED(min_pixel_value));
                    if(delta_value = "11111111")then
                        shift_level<="0000";
                    elsif ((delta_value = "1-------") )OR(delta_value  = "01111111")then
                        shift_level<="0001";
                    elsif ((delta_value = "01------") OR(delta_value  = "00111111"))then
                        shift_level<="0010";
                    elsif ((delta_value = "001-----")OR(delta_value = "00011111"))then
                        shift_level<="0011";    
                    elsif ((delta_value = "0001----") OR(delta_value = "00001111"))then
                        shift_level<="0100";    
                    elsif ((delta_value = "00001---") OR(delta_value  = "00000111"))then
                        shift_level<="0101";     
                    elsif ((delta_value = "000001--") OR(delta_value  = "00000011"))then
                        shift_level<="0110";    
                    elsif ((delta_value = "0000001-") OR(delta_value  = "00000001"))then
                        shift_level<="0111";    
                    elsif (delta_value  = "00000000") then
                        shift_level<="1000";
                    else  shift_level<="----";
                    end if; 
                                   
               when CALCULATE_NEW_PIXEL_VALUE =>

                    new_pixel_value<= shift_left(UNSIGNED(UNSIGNED(i_data)- UNSIGNED(min_pixel_value)),  to_integer(UNSIGNED(shift_level)));
                    if( new_pixel_value > "11111111" ) then
                        new_pixel_value<= "11111111";
                    end if;
                    curr_addr <= curr_addr + write_addr;
                    
               when WRITE_NEW_PIXEL_VALUE=>
                    
                    o_we <= '1';
                    o_data<=std_logic_vector(new_pixel_value);
                    o_we <='0';
                    curr_addr <= curr_addr - write_addr + 1;
                    
                    
               when DONE =>
                    o_en <= '0';
                    o_done <='1';
              
               when others =>
                   o_en <= '1';
               
               end case;
           end if;
    end process;                         
                                  
end Behavioral;
