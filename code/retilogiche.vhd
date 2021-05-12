
----------------------------------------------------------------------------------
-- Students: Mauro Fama', CP: 10631287, Mat: 908861
--           Elia Fantini, CP: 10651951, Mat. 907960
-- 
-- Module Name: project_reti_logiche 
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
                        COMPARE_MAX_MIN, CALCULATE_DELTA_VALUE, CALCULATE_SHIFT_LEVEL,
                        CALCULATE_NEW_PIXEL_VALUE,CHECK_NEW_PIXEL_VALUE,WRITE_NEW_PIXEL_VALUE,DISABLE_WRITING,DONE);
    signal next_state : state_type:=INIT;
    signal curr_state : state_type:=INIT;
    signal curr_addr: UNSIGNED(15 downto 0):="0000000000000000";
    signal counter: UNSIGNED(15 downto 0):="0000000000000000";
    signal write_addr: UNSIGNED(15 downto 0):="0000000000000000";
    signal n_col: UNSIGNED(7 downto 0):="00000000";
    signal max_pixel_value: std_logic_vector(7 downto 0):="00000000";
    signal min_pixel_value: std_logic_vector(7 downto 0):="11111111";
    signal delta_value: std_logic_vector(7 downto 0):="11111111";
    signal shift_level: std_logic_vector (3 downto 0):="0000";
    signal new_pixel_value: UNSIGNED (15 downto 0):="0000000000000000";
    
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
          
  lambda:process(curr_state,i_clk,i_start,i_rst)
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
                    counter <= "0000000000000001";
                    next_state<= COMPARE_MAX_MIN;  
             when COMPARE_MAX_MIN =>
                    counter<= counter +1;                               
                    if ( counter >= write_addr) then
                        next_state<= CALCULATE_DELTA_VALUE;
                    end if;
             when CALCULATE_DELTA_VALUE =>
                    next_state<= CALCULATE_SHIFT_LEVEL; 
             when CALCULATE_SHIFT_LEVEL =>
                    counter <= "0000000000000001";
                    next_state<= CALCULATE_NEW_PIXEL_VALUE;
             when CALCULATE_NEW_PIXEL_VALUE =>
                    next_state<=CHECK_NEW_PIXEL_VALUE ;
             when CHECK_NEW_PIXEL_VALUE =>    
                    next_state<=WRITE_NEW_PIXEL_VALUE ;    
             when WRITE_NEW_PIXEL_VALUE   =>
                    next_state<= DISABLE_WRITING ;       
             when DISABLE_WRITING =>
                    counter<= counter +1;                               
                    if ( counter < write_addr ) then
                        next_state<= CALCULATE_NEW_PIXEL_VALUE;
                    elsif (counter = write_addr ) then 
                        next_state<= DONE;
                    end if;
             when DONE =>
                    if i_start = '0' then
                        next_state <= RESET;
                    end if;
             when others => next_state <= RESET;
             
             end case;
      end if;
  end process;
                       
           
    delta:process(curr_state,i_clk,i_start,i_rst)     
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
                    new_pixel_value <= "0000000000000000";  
                    delta_value<="11111111";
                    o_done <= '0';
                    
                when START =>
                    o_en <= '1';
                                        
                when READ_N_COL =>
                    n_col <= UNSIGNED(i_data);
                    curr_addr <= curr_addr + 1;
                                                        
                when CALCULATE_WRITE_ADDR =>
                    write_addr <= (UNSIGNED(i_data) * n_col); 
                    curr_addr <= curr_addr + 1;
                    
                when COMPARE_MAX_MIN =>
                    if ( i_data < min_pixel_value ) then
                        min_pixel_value <= i_data;
                        end if;
                    if ( i_data > max_pixel_value ) then
                        max_pixel_value <= i_data;
                        end if;                  
                    curr_addr <= curr_addr + 1;
                    
               when CALCULATE_DELTA_VALUE =>  
                    delta_value<= std_logic_vector(UNSIGNED(max_pixel_value)- UNSIGNED(min_pixel_value));    
                                              
               when CALCULATE_SHIFT_LEVEL =>                  
                    curr_addr <= curr_addr - write_addr; --riporto curr_addr al primo pixel
                    if(delta_value = "11111111") then
                        shift_level<="0000";
                    else
                        if ((delta_value(7)= '1') OR(delta_value  = "01111111")) then
                            shift_level<="0001";
                        else 
                            if((delta_value(7)= '0'AND delta_value(6)= '1' ) OR(delta_value  = "00111111")) then
                                shift_level<="0010";
                            else 
                                if((delta_value(7)= '0'AND delta_value(6)= '0'AND delta_value(5)= '1')OR(delta_value = "00011111"))then
                                    shift_level<="0011";    
                                else
                                    if ((delta_value(7)= '0'AND delta_value(6)= '0'AND delta_value(5)= '0'AND delta_value(4)= '1') OR(delta_value = "00001111"))then
                                        shift_level<="0100";    
                                    else 
                                        if((delta_value(7)= '0'AND delta_value(6)= '0'AND delta_value(5)= '0'AND delta_value(4)= '0' AND delta_value(3)= '1') OR(delta_value  = "00000111"))then
                                            shift_level<="0101";     
                                        else 
                                            if((delta_value(7)= '0'AND delta_value(6)= '0'AND delta_value(5)= '0'AND delta_value(4)= '0' AND delta_value(3)= '0'AND delta_value(2)= '1') OR(delta_value  = "00000011"))then
                                                shift_level<="0110";    
                                            else 
                                                if((delta_value(7)= '0'AND delta_value(6)= '0'AND delta_value(5)= '0'AND delta_value(4)= '0' AND delta_value(3)= '0'AND delta_value(2)= '0'AND delta_value(1)= '1') OR(delta_value  = "00000001"))then
                                                    shift_level<="0111";    
                                                else 
                                                    if(delta_value  = "00000000") then
                                                        shift_level<="1000";
                                                    else  shift_level<="----";
                                                    end if; 
                                                end if;
                                            end if;
                                        end if;
                                    end if;
                               end if;
                           end if;
                       end if;
                    end if;
                                      
                                   
               when CALCULATE_NEW_PIXEL_VALUE =>
                    new_pixel_value<= shift_left(resize(UNSIGNED(UNSIGNED(i_data)- UNSIGNED(min_pixel_value)),16),  to_integer(UNSIGNED(shift_level)));                    
                    curr_addr <= curr_addr + write_addr;
               
               when  CHECK_NEW_PIXEL_VALUE =>
                    if( new_pixel_value > "0000000011111111" ) then
                        new_pixel_value<= "0000000011111111";
                    end if;   
                    
               when WRITE_NEW_PIXEL_VALUE=>
                    o_we<= '1';    
                    o_data<=std_logic_vector(new_pixel_value(7 downto 0));
                    
               when DISABLE_WRITING =>              
                    o_we <= '0';
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
