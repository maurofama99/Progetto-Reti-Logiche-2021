
----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 17.03.2021 15:10:02
-- Design Name: 
-- Module Name: project_reti_logiche - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.ALL;

entity project_reti_logiche is
    Port ( i_clk : in STD_LOGIC;
           i_rst : in STD_LOGIC;
           i_start : in STD_LOGIC;
           i_data : in STD_LOGIC;
           o_address : out STD_LOGIC;
           o_done : out STD_LOGIC;
           o_en : out STD_LOGIC;
           o_we : out STD_LOGIC;
           o_data : out STD_LOGIC);
end project_reti_logiche;

architecture Behavioral of project_reti_logiche is
    type state_type is (INIT,RESET,START);
    signal next_state : state_type:=INIT;
    signal current_state : state_type:=INIT;
    signal curr_address: std_logic_vector(15 downto 0):="0000000000000000";
    signal free_mem_address: std_logic_vector(15 downto 0):="0000000000000000";
    signal n_col: std_logic_vector(8 downto 0):="00000000";
    signal n_rig: std_logic_vector(8 downto 0):="00000000";
    signal max_pix_val: std_logic_vector(8 downto 0):="00000000";
    signal min_pix_val: std_logic_vector(8 downto 0):="00000000";
    signal shift_level: std_logic_vector (4 downto 0):="0000";
    
begin
    state_reg:process(i_clk,i_rst)
    begin
        if(i_rst= '1') then
            current_state<= RESET;
        elsif rising_edge(i_clk)then
            current_state<= next_state;
        end if;  
    end process;
          
    lambda:process(current_state,i_clk,i_start)
    begin
        if falling_edge(i_clk) then
            case current_state is 
                when RESET =>
                    if i_start = '1' then
                        next_state<= START;
                    end if;
                when START =>
                    next_state<= LEGGO_N_COL;
                when LEGGO_N_COL =>
                    next_state<= LEGGO_N_RIG;    
                when LEGGO_N_RIG =>
                    next_state<= CALCOLO_FREE_MEM_ADDR;  
                when CALCOLO_FREE_MEM_ADDR =>
                    next_state<= CALCOLO_DELTA_VALUE;    
                when CALCOLO_DELTA_VALUE =>
                    next_state<= CALCOLO_SHIFT_LEVEL;
                when CALCOLO_SHIFT_LEVEL =>
                    next_state<= CALCOLO_NEW_PIXEL_VALUE; 
                when CALCOLO_NEW_PIXEL_VALUE =>
                    next_state<= MEMORIZZA_NEW_PIXEL_VALUE;    
                when MEMORIZZA_NEW_PIXEL_VALUE =>
                    if UNSIGNED(curr_address) < UNSIGNED(free_mem_address) - 1 then
                        next_state<= CALCOLO_NEW_PIXEL_VALUE
                    else 
                        next_state<=DONE;
                    
                    
         
end Behavioral;
