--===========================================================================--
--
--  S Y N T H E Z I A B L E    miniUART   C O R E
--
--  www.OpenCores.Org - January 2000
--  This core adheres to the GNU public license  
--
-- Design units   : miniUART core for the OCRP-1
--
-- File name      : RxUnit.vhd
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
-- Version   Author                 Date                        Changes
--
-- 0.1      Ovidiu Lupas     15 January 2000                   New model
-- 2.0      Ovidiu Lupas     17 April   2000  samples counter cleared for bit 0
--        olupas@opencores.org
-------------------------------------------------------------------------------
-- Description    : Implements the receive unit of the miniUART core. Samples
--                  16 times the RxD line and retain the value in the middle of
--                  the time interval. 
-------------------------------------------------------------------------------
-- Entity for Receive Unit - 9600 baudrate                                  --
-------------------------------------------------------------------------------
library ieee;
   use ieee.std_logic_1164.all;
   use ieee.numeric_std.all;

-------------------------------------------------------------------------------
-- Receive unit
-------------------------------------------------------------------------------
entity RxUnit is
  port (
     Clk    : in  Std_Logic;  -- system clock signal
     Reset  : in  Std_Logic;  -- Reset input
     Enable : in  Std_Logic;  -- Enable input
     RxD    : in  Std_Logic;  -- RS-232 data input
     ReadD  : in  Std_Logic;  -- Read data signal
     FRErr  : out Std_Logic;  -- Status signal
     ORErr  : out Std_Logic;  -- Status signal
     DARdy  : out Std_Logic;  -- Status signal
     DataI  : out Std_Logic_Vector(7 downto 0));
end entity; --================== End of entity ==============================--
-------------------------------------------------------------------------------
-- Architecture for receive Unit
-------------------------------------------------------------------------------
architecture Behaviour of RxUnit is
  -----------------------------------------------------------------------------
  -- Signals
  -----------------------------------------------------------------------------
  signal Start     : Std_Logic;             -- Syncro signal
  signal tmpRxD    : Std_Logic;             -- RxD buffer
  signal tmpDRdy   : Std_Logic;             -- Data ready buffer
  signal outErr    : Std_Logic;             -- 
  signal frameErr  : Std_Logic;             -- 
  signal BitCnt    : Unsigned(3 downto 0);  -- 
  signal SampleCnt : Unsigned(3 downto 0);  -- samples on one bit counter
  signal ShtReg    : Std_Logic_Vector(7 downto 0);  --
  signal DOut      : Std_Logic_Vector(7 downto 0);  --

begin
  ---------------------------------------------------------------------
  -- Receiver process
  ---------------------------------------------------------------------
  RcvProc : process(Clk,Reset,Enable,RxD)
      constant CntOne : Unsigned(3 downto 0):="0001";
  begin
     if Clk'event and Clk='1' then
        if Reset = '1' then
           BitCnt <= "0000";
           SampleCnt <= "0000";
           Start <= '0';
           tmpDRdy <= '0';
           frameErr <= '0';
           outErr <= '0';

           ShtReg <= "00000000";  --
           DOut   <= "00000000";  --
        else
           if ReadD = '1' then
              tmpDRdy <= '0';      -- Data was read
           end if;

           if Enable = '1' then
              if Start = '0' then
                 if RxD = '0' then -- Start bit, 
                    SampleCnt <= SampleCnt + CntOne;
                    Start <= '1';
                 end if;
              else
                 if SampleCnt = "1000" then  -- reads the RxD line
                    tmpRxD <= RxD;
                    SampleCnt <= SampleCnt + CntOne;                
                 elsif SampleCnt = "1111" then
                    case BitCnt is
                         when "0000" =>
                                if tmpRxD = '1' then -- Start Bit
                                   Start <= '0';
                                else
                                   BitCnt <= BitCnt + CntOne;
                                end if;
                                SampleCnt <= SampleCnt + CntOne;
                         when "1001" =>
                                if tmpRxD = '0' then  -- stop bit expected
                                   frameErr <= '1';
                                else
                                   frameErr <= '0';
                                end if;

                                if tmpDRdy = '1' then -- 
                                   outErr <= '1';
                                else
                                   outErr <= '0';
                                end if;

                                tmpDRdy <= '1';
                                DOut <= ShtReg;
                                BitCnt <= "0000";
                                Start <= '0';
                         when others =>
                                BitCnt <= BitCnt + CntOne;
                                SampleCnt <= SampleCnt + CntOne;
                                ShtReg <= tmpRxD & ShtReg(7 downto 1);
                    end case;
                 else
                    SampleCnt <= SampleCnt + CntOne;                
                 end if;
              end if;
           end if;
        end if;
     end if;
  end process;

  DARdy <= tmpDRdy;
  DataI <= DOut;
  FRErr <= frameErr;
  ORErr <= outErr;

end Behaviour; --==================== End of architecture ====================--