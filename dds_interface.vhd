----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 05.08.2019 19:46:01
-- Design Name: 
-- Module Name: dds_interface - Behavioral
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
use IEEE.STD_LOGIC_unsigned.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity dds_interface is
port(
        tclk_fpga                   :   IN std_logic ;             --input oscc
        i_reset                     :   IN std_logic ;             --input oscc
        bit_2_clk                   :   IN std_logic ;             -- double the pcm bit rate signal is generated
        dds_reset                   :   OUT STD_LOGIC;             
        dds_writeb                  :   OUT STD_LOGIC;             
        dds_update                  :   OUT STD_LOGIC := '0';      
        dds_data                    :   OUT std_logic_vector(7 downto 0)    --- double the pcm bit rate signal is generated
       
);
end dds_interface;

architecture Behavioral of dds_interface is
-------------------------------DDS
SIGNAL dds_writeb1 :STD_LOGIC; -- output to the clock gen for clock signal lock  
SIGNAL dds_reset1 :STD_LOGIC; -- output to the clock gen for clock signal lock  
SIGNAL dds_update1 :STD_LOGIC; -- output to the clock gen for clock signal lock  
SIGNAL dds_data1 :STD_LOGIC_vector (7 downto 0); -- output to the clock gen for clock signal lock  
SIGNAL cnt :STD_LOGIC_VECTOR( 11 DOWNTO 0):=x"000";		

signal STATE :integer  range 50 downto 0 := 0; 
signal DDS_STATE :integer  range 50 downto 0 := 1; 
signal state_dac :integer  range 50 downto 0 := 1; 

begin

PROCESS (tclk_fpga,I_RESET) 
BEGIN 
IF(I_RESET = '0') THEN 
             DDS_STATE      <= 1;
 ELSIF( RISING_EDGE (tclk_fpga)) THEN 
CASE  DDS_STATE IS 
 
WHEN  1 => 
         dds_reset1 <=  '1'; dds_update1 <= '1';     -- reset assert making it one 
        IF(CNT <= X"150") THEN                     -- counter for delay 
            CNT <= CNT + X"001";    
            DDS_STATE <= 1;
        ELSE 
           DDS_STATE <= 2;
           CNT <=x"000";
        END IF ;
WHEN  2 => dds_reset1 <=  '0';               -- reset signal is made low 
        IF(CNT <= X"150") THEN 
            CNT <= CNT + X"001";            -- counter for dealy 
            DDS_STATE <= 2;
        ELSE 
           DDS_STATE <= 3;
           CNT <=x"000";
        END IF ;         
             
WHEN  3 =>                             -- set up  
            dds_update1 <= '0';              
            dds_writeb1 <= '0';
            DDS_STATE <= 4;
            
WHEN  4 => dds_data1 <= x"00";          --  writing the first data into the data line 
            IF(CNT <= X"4") THEN           -- inserting the delay 
                 CNT <= CNT + X"001"; 
                 DDS_STATE <=4;
             ELSE 
                DDS_STATE <= 5;
                CNT <=x"000";
             END IF ;               
             
WHEN  5 =>  dds_writeb1 <= '1';             -- first write clock high 
             IF(CNT <= X"4") THEN           -- delay to keep it high 
                  CNT <= CNT + X"001"; 
                  DDS_STATE <= 5;
              ELSE 
                 DDS_STATE <= 6;
                 CNT <=x"000";
              END IF ;    
when 6 =>   
              dds_writeb1 <= '0';           --- making the clock low 
                IF(CNT <= X"6") THEN         -- introducinf the dealy    
                      CNT <= CNT + X"001";  
                      DDS_STATE <= 6;
                  ELSE 
                     DDS_STATE <= 7;
                     CNT <=x"000";
                  END IF ;   
                  
WHEN  7 => 
                dds_data1 <= x"08";           --writing the second byte of data 
               DDS_STATE <= 8;
                            
             
 WHEN  8 => 
              dds_writeb1 <= '1';               -- making the write signal high for the second byte 
              IF(CNT <= X"4") THEN              -- counter for keeping the clock high 
                   CNT <= CNT + X"001"; 
                   DDS_STATE <= 8;
               ELSE 
                  DDS_STATE <=9;
                  CNT <=x"000";
               END IF ;    

when 9 =>   
              dds_writeb1 <= '0';               -- making the clock signal low 
                IF(CNT <= X"6") THEN            -- counter to keep the clock low 
                    CNT <= CNT + X"001"; 
                    DDS_STATE <= 9;
                ELSE 
                   DDS_STATE <= 10;
                   CNT <=x"000";
                END IF ; 
            
WHEN  10 => 
                 dds_data1 <= x"00";          --writing the third byte of the data 
                DDS_STATE <= 11;
                                     
          
WHEN  11 => 
           dds_writeb1 <= '1';                  -- making the clock signal high  
           IF(CNT <= X"4") THEN                 -- counter to keep the clock high 
                CNT <= CNT + X"001"; 
                DDS_STATE <= 11;
            ELSE 
               DDS_STATE <=12;
               CNT <=x"000";
            END IF ;       
            
 when 12 =>   
              dds_writeb1 <= '0';               -- making the clock low 
                IF(CNT <= X"6") THEN            -- counter to keep the clock signal low
                    CNT <= CNT + X"001"; 
                    DDS_STATE <= 12;
                ELSE 
                   DDS_STATE <= 13;
                   CNT <=x"000";
                END IF ; 
                        
WHEN  13 => 
                 dds_data1 <= x"00";              -- writing the fourth byte of the data 
                DDS_STATE <=14;           
            
            
 WHEN  14 => 
       dds_writeb1 <= '1';                          -- making the write clock high 
       IF(CNT <= X"4") THEN                         -- counter to keep the clock high 
            CNT <= CNT + X"001"; 
            DDS_STATE <= 14;
        ELSE 
           DDS_STATE <=15;                          
           CNT <=x"000";
        END IF ;       
        
when 15 =>   
          dds_writeb1 <= '0';                   --  making the write clock low 
            IF(CNT <= X"6") THEN                -- counter to make the clock low 
                CNT <= CNT + X"001"; 
                DDS_STATE <= 15;
            ELSE 
               DDS_STATE <= 16;
               CNT <=x"000";
            END IF ; 
                    
WHEN  16 => 
             dds_data1 <= x"00";              -- writing the fifth  byte of the data
            DDS_STATE <=17;           
           
            
 WHEN  17 => 
       dds_writeb1 <= '1';                      --  -- making the write clock high
       IF(CNT <= X"4") THEN                         -- counter to keep the clock high
            CNT <= CNT + X"001"; 
            DDS_STATE <= 17;
        ELSE 
           DDS_STATE <=18;
           CNT <=x"000";
        END IF ;       
        
when 18 =>   
          dds_writeb1 <= '0';                    --  making the write clock low
            IF(CNT <= X"6") THEN               -- counter to make the clock low
                CNT <= CNT + X"001"; 
                DDS_STATE <= 18;
            ELSE 
               DDS_STATE <= 19;
               CNT <=x"000";
            END IF ; 

              
  WHEN  19 =>   dds_update1 <= '1';              -- making the update signal high           
                dds_writeb1 <= '0';
                DDS_STATE <= 25;                -- leaving the state to the update signal 
                
 		 
 WHEN OTHERS => null;
 
    end case;  
    end if;
end process; 

 dds_update <= dds_update1;                      		 
 dds_writeb	<= dds_writeb1;
 dds_reset  <= dds_reset1;	 
 dds_data   <= dds_data1;
 
 
end Behavioral;
