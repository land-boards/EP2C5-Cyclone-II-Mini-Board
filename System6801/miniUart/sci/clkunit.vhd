--===========================================================================--
--
--  S Y N T H E Z I A B L E    miniUART   C O R E
--
--  www.OpenCores.Org - January 2000
--  This core adheres to the GNU public license  

-- Design units   : miniUART core for the OCRP-1
--
-- File name      : clkUnit.vhd
--
-- Purpose        : Implements an miniUART device for communication purposes 
--                  between the OR1K processor and the Host computer through
--                  an RS-232 communication protocol.
--                  
-- Library        : uart_lib.vhd
--
-- Dependencies   : IEEE.Std_Logic_1164
--
--===========================================================================--
-------------------------------------------------------------------------------
-- Revision list
-- Version   Author                 Date              Changes
--
-- 0.1      Ovidiu Lupas       15 January 2000        New model
--        olupas@opencores.org
-- 2.0      John Kent          10 November 2002       Added programmable baud rate
-- 3.0      John Kent          15 December 2002       Fix TX clock divider
-------------------------------------------------------------------------------
-- Description    : Generates the Baud clock and enable signals for RX & TX
--                  units. 
-------------------------------------------------------------------------------
-- Entity for Baud rate generator Unit - 9600 baudrate                       --
-------------------------------------------------------------------------------
library ieee;
   use ieee.std_logic_1164.all;
   use ieee.numeric_std.all;
library work;
--   use work.UART_Def.all;
-------------------------------------------------------------------------------
-- Baud rate generator
-------------------------------------------------------------------------------
entity ClkUnit is
  port (
     Clk      : in  Std_Logic;  -- System Clock
     Reset    : in  Std_Logic; -- Reset input
     EnableRx : out Std_Logic;  -- Control signal
     EnableTx : out Std_Logic;  -- Control signal
	  BaudRate : in Std_Logic_Vector(1 downto 0));
end entity; --================== End of entity ==============================--
-------------------------------------------------------------------------------
-- Architecture for Baud rate generator Unit
-------------------------------------------------------------------------------
architecture Behaviour of ClkUnit is
signal tmpEnRx : std_logic;

begin
  -----------------------------------------------------------------------------
  -- Divides the system clock of 40 MHz div 260 gives 153 KHz for 9600bps
  --                             48 MHz div 156 gives 300 KHz for 19.2Kbps
  --                             24 MHz div 156 gives 153 KHz for 9600bps
  --                             4.9152MHz div 32 gives 153KHz for 9600bps 
  -----------------------------------------------------------------------------
  DivClk : process(Clk,Reset,tmpEnRx, BaudRate)
   variable Count  : unsigned(7 downto 0);
   constant CntOne : Unsigned(7 downto 0):="00000001";
   begin
     if Clk'event and Clk = '1' then
        if Reset = '1' then
           Count := "00000000";
           tmpEnRx <= '0';
        else
			  if Count = "00000000" then
				 tmpEnRx <= '1';
				 case BaudRate is
				 when "00" => -- divide by 1 ((1*2)-1) (fast)
				   Count := "00000001";
				 when "01" => -- divide by 16 ((16*2)-1) (9600 Baud)
				   Count := "00011111";
				 when "10" => -- divide by 64 ((64*2)-1) (2400 Baud)
				   Count := "01111111";
				 when others =>
--				 when "11" => -- reset
				   Count := "00000000";
				   null;
				 end case;
			  else
             tmpEnRx <= '0';
		       Count := Count - CntOne;
           end if;
        end if;
     end if;
     EnableRx <= tmpEnRx;
  end process;

  -----------------------------------------------------------------------------
  -- Provides the EnableTX signal, at 9.6 KHz
  -- Divide by 16
  -- Except it wasn't ... it counted up to "10010" (18)
  -----------------------------------------------------------------------------
  DivClk16 : process(Clk,Reset,tmpEnRX)
   variable Cnt16  : unsigned(4 downto 0);
   constant CntOne : Unsigned(4 downto 0):="00001";
   begin
    if Clk'event and Clk = '1' then
      if Reset = '1' then
        Cnt16 := "00000";
        EnableTX <= '0';
      else
        case Cnt16 is
          when "00000" =>
            if tmpEnRx = '1' then
              Cnt16 := "01111";
              EnableTx <='1';
				else
				  Cnt16 := Cnt16;
				  EnableTx <= '0';
				end if;
	       when others =>
            if tmpEnRx = '1' then
              Cnt16 := Cnt16 - CntOne;
				else
				  Cnt16 := Cnt16;
				end if;
            EnableTX <= '0';
        end case;
		end if;
    end if;
  end process;
end Behaviour; --==================== End of architecture ===================--