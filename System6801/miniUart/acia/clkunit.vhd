--===========================================================================--
--
--  S Y N T H E Z I A B L E    miniUART   C O R E
--
--  www.OpenCores.Org - January 2000
--  This core adheres to the GNU public license

-- Design units   : miniUART core for the System68
--
-- File name      : clkunit.vhd
--
-- Purpose        : Implements an miniUART device for communication purposes
--                  between the CPU68 processor and the Host computer through
--                  an RS-232 communication protocol.
--
-- Dependencies   : ieee.std_logic_1164
--                  ieee.numeric_std
--
--===========================================================================--
-------------------------------------------------------------------------------
-- Revision list
-- Version   Author                 Date              Changes
--
-- 0.1      Ovidiu Lupas       15 January 2000        New model
--        olupas@opencores.org
--
-- 2.0      John Kent          10 November 2002       Added programmable baud rate
-- 3.0      John Kent          15 December 2002       Fix TX clock divider
-- 3.1      John kent          12 January  2003       Changed divide by 1 for 38.4Kbps
--        dilbert57@opencores.org
-- 3.2      Mike Hasenfratz     6 August   2003       Changed Baudrates for 33.333MHz clock
--                                                    Added 50.0MHz
--                                                    Requires 10bit Counter
--                                                    Renamed to match Entity
-- 3.3			Mike Hasenfratz			19 October	2003			Changed to 4.9152MHz System Clock
--				mikehsr@opencores.org
-------------------------------------------------------------------------------
-- Description    : Generates the Baud clock and enable signals for RX & TX
--                  units.
-------------------------------------------------------------------------------
-- Entity for Baud rate generator Unit - 19.2K / 9600 baudrate                       --
-------------------------------------------------------------------------------
library ieee;
   use ieee.std_logic_1164.all;
   use ieee.numeric_std.all;
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
  -- Divides the system clock of 40 MHz     div 260 gives 153KHz for 9600bps
  --                             48 MHz     div 156 gives 306KHz for 19.2Kbps
  --                             50 MHz     div 326 for 9600bps
  --                             50 MHz     div 162 for 19.2kbps
  --                             33.333 MHz div 217 for 9600bps
  --                             33.333 MHz div 108 for 19.2kbps
  --                             24 MHz     div 156 gives 153KHz for 9600bps
  --                             9.8304MHz  div 32  gives 306KHz for 19.2Kbps
  --                             4.9152MHz  div 32  gives 153KHz for 9600bps
  -----------------------------------------------------------------------------
  DivClk : process(Clk,Reset,tmpEnRx, BaudRate)
   variable Count  : unsigned(9 downto 0);
   constant CntOne : Unsigned(9 downto 0):= TO_UNSIGNED(1, Count'LENGTH);
   begin
     if Clk'event and Clk = '1' then
        if Reset = '1' then
           Count := (others => '0');
           tmpEnRx <= '0';
        else
			  if Count = TO_UNSIGNED(0, Count'LENGTH) then
				 tmpEnRx <= '1';
				 case BaudRate is
				 when "00" =>
				 -- 6850 divide by 1 ((1*2)-1) (synchronous)
				 -- miniUart 4.9152MHz div 16 = 19.2Kbps
				 -- miniUart 9.83MHz div 16 = 38.4Kbps
				 -- miniUart 33.333MHz div 108 = 19.2Kbps
				 -- miniUart 50.0MHz div 162 = 19.2Kbps
				   Count := TO_UNSIGNED(16, Count'LENGTH);
				 when "01" =>
				 -- 6850 divide by 16 ((16*2)-1) (9600 Baud)
				 -- miniUart 4.9152MHz div 32 = 9600bps
				 -- miniUart 9.83MHz div 32 = 19.2Kbps
				 -- miniUart 33.333MHz div 217 = 9600bps
				 -- miniUart 50.0MHz div 326 = 9600bps
				   Count := TO_UNSIGNED(32, Count'LENGTH);
				 when "10" =>
				 -- 6850 divide by 64 ((64*2)-1) (2400 Baud)
				 -- miniUart 4.9152MHz div 64 = 4800bps
				 -- miniUart 9.83MHz div 128 = 4800bps
				 -- miniUart 33.333MHz div 434 = 4800bps
				   Count := TO_UNSIGNED(64, Count'LENGTH);
				 when others =>
--				 when "11" => -- reset
				   Count := (others => '0');
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
  -- Provides the EnableTX signal, at 'Baudrate'
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