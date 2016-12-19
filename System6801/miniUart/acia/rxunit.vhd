--===========================================================================--
--
--  S Y N T H E Z I A B L E    miniUART   C O R E
--
--  www.OpenCores.Org - January 2000
--  This core adheres to the GNU public license  
--
-- Design units   : miniUART core for the System68
--
-- File name      : rxunit.vhd
--
-- Purpose        : Implements an miniUART device for communication purposes 
--                  between the cpu68 cpu and the Host computer through
--                  an RS-232 communication protocol.
--                  
-- Dependencies   : ieee.std_logic_1164.all;
--                  ieee.numeric_std.all;
--
--===========================================================================--
-------------------------------------------------------------------------------
-- Revision list
-- Version   Author                 Date                        Changes
--
-- 0.1      Ovidiu Lupas     15 January 2000                   New model
-- 2.0      Ovidiu Lupas     17 April   2000  samples counter cleared for bit 0
--        olupas@opencores.org
--
-- 3.0      John Kent         5 January 2003  Added 6850 word format control
-- 3.1      John Kent        12 January 2003  Significantly revamped receive code.
--        dilbert57@opencores.org
-- 3.2      Mike Hasenfratz     7 August   2003       Renamed to match Entity
--				mikehsr@opencores.org
--
-------------------------------------------------------------------------------
-- Description    : Implements the receive unit of the miniUART core. Samples
--                  16 times the RxD line and retain the value in the middle of
--                  the time interval. 
library ieee;
   use ieee.std_logic_1164.all;
   use ieee.std_logic_unsigned.all;

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
	  Format : in  Std_Logic_Vector(2 downto 0) := "000";
     FRErr  : out Std_Logic;  -- Status signal
     ORErr  : out Std_Logic;  -- Status signal
	  PAErr  : out Std_logic;  -- Status Signal
     DARdy  : out Std_Logic;  -- Status signal
     DAOut  : out Std_Logic_Vector(7 downto 0)
	  );
end entity; --================== End of entity ==============================--
-------------------------------------------------------------------------------
-- Architecture for receive Unit
-------------------------------------------------------------------------------
architecture Behaviour of RxUnit is
  -----------------------------------------------------------------------------
  -- Signals
  -----------------------------------------------------------------------------
  signal RxStart    : Std_Logic;             -- Start Receive Request
  signal RxFinish   : Std_Logic;             -- Receive finished
  signal RxValid    : Std_Logic;             -- Receive data valid
  signal RxFalse    : Std_Logic;             -- False start flag
  signal tmpRxD     : Std_Logic;             -- RxD buffer
  signal tmpRxC     : Std_Logic;             -- Rx clock
  signal tmpDRdy    : Std_Logic;             -- Data Ready flag
  signal tmpRxVal   : Std_Logic;             -- Rx Data Valid
  signal tmpRxFin   : Std_Logic;             -- Rx Finish
  signal outErr     : Std_Logic;             -- Over run error bit
  signal frameErr   : Std_Logic;             -- Framing error bit
  signal ParityErr  : Std_Logic;             -- Parity Error Bit
  signal RxParity   : Std_Logic;             -- Calculated RX parity bit
  signal RxState    : Std_Logic_Vector(3 downto 0);  -- receive bit state
  signal SampleCnt  : Std_Logic_Vector(3 downto 0);  -- samples on one bit counter
  signal ShtReg     : Std_Logic_Vector(7 downto 0);  -- Shift Register
  signal DataOut    : Std_Logic_Vector(7 downto 0);  -- Data Output register

  constant CntOne    : Std_Logic_Vector(3 downto 0):= "0001";
  constant CntZero   : Std_Logic_Vector(3 downto 0):= "0000";

begin
  ---------------------------------------------------------------------
  -- Receiver Read process
  ---------------------------------------------------------------------
  RcvRead : process(Clk, Reset, ReadD, Enable, RxValid, tmpRxVal, tmpDRdy )
  begin
    if Clk'event and Clk='1' then
      if Reset = '1' then
        tmpDRdy   <= '0';
		  tmpRxVal  <= '0';
      else
        if ReadD = '1' then
          tmpDRdy  <= '0';              -- Data was read
			 tmpRxVal <= tmpRxVal;
		  else
		    if RxValid = '1' and tmpRxVal = '0' then
			   tmpDRdy  <= '1';            -- Data was received
				tmpRxVal <= '1';
			 else
		      tmpDRdy <= tmpDRdy;
			   if RxValid = '0' and tmpRxVal = '1' then
			     tmpRxVal  <= '0';
			   else
			     tmpRxVal  <= tmpRxVal;
				end if;
			 end if; -- RxValid
        end if; -- ReadD
      end if; -- reset
    end if; -- clk
  end process;

  ---------------------------------------------------------------------
  -- Receiver Synchronisation process
  ---------------------------------------------------------------------
  RcvSync : process(Clk, Reset, Enable, RxStart, RxFinish, RxD, SampleCnt )
		variable CntIni   : Std_Logic_Vector(3 downto 0);
		variable CntAdd   : Std_Logic_Vector(3 downto 0);
  begin
    if Clk'event and Clk='1' then
      if Reset = '1' then
		  RxStart   <= '0';
        SampleCnt <= "0000";
		  CntIni    := SampleCnt;
		  CntAdd    := CntZero;
      else
        if Enable = '1' then
          if RxFinish = '1' and RxStart = '0' then    -- Are we looking for a start bit ?
            if RxD = '0' then                         -- yes, look for Start Edge 
              RxStart   <= '1';                       -- we have a start edge
		        CntIni    := CntZero;
		        CntAdd    := CntZero;
			   else
				  RxStart   <= '0';                       -- no start, spin sample count
		        CntIni    := SampleCnt;
		        CntAdd    := CntOne;
            end if;
          else
			   if RxFinish = '0' and RxStart = '1' then  -- have we received a start bit ?
			     RxStart <= '0';                         -- yes, reset start request
				else
				  if RxFalse = '1' and RxStart = '1' then -- false start ?
				    RxStart <= '0';                       -- yep, reset start request
              else
			       RxStart <= RxStart;
				  end if;
				end if;
		      CntIni    := SampleCnt;
		      CntAdd    := CntOne;
			 end if; -- RxStart
		  else
		    CntIni    := SampleCnt;
		    CntAdd    := CntZero;
          RxStart   <= RxStart;
        end if; -- enable
      end if; -- reset
		SampleCnt <= CntIni + CntAdd;
    end if; -- clk
  end process;


  ---------------------------------------------------------------------
  -- Receiver Clock process
  ---------------------------------------------------------------------
  RcvClock : process(Clk, Reset, Enable, SampleCnt, RxD, tmpRxD )
  begin
    if Clk'event and Clk='1' then
      if Reset = '1' then
		  tmpRxC    <= '0';
		  tmpRxD    <= '1';
      else
		  if SampleCnt = "1000" then
			 tmpRxD <= RxD;
		  else
			 tmpRxD <= tmpRxD;
 		  end if;

		  if SampleCnt = "1111" then
			 tmpRxC <= '1';
		  else
			 tmpRxC <= '0';
 		  end if;
      end if; -- reset
    end if; -- clk
  end process;

  ---------------------------------------------------------------------
  -- Receiver process
  ---------------------------------------------------------------------
  RcvProc : process(Clk, Reset, RxState, tmpRxC, Enable, tmpRxD, RxStart )
  begin
    if Clk'event and Clk='1' then
      if Reset = '1' then
        frameErr  <= '0';
        outErr    <= '0';
		  parityErr <= '0';

        ShtReg    <= "00000000";  -- Shift register
		  RxParity  <= '0';         -- Parity bit
		  RxFinish  <= '1';         -- Data RX finish flag
		  RxValid   <= '0';         -- Data RX data valid flag
		  RxFalse   <= '0';
        RxState   <= "1111";
		  DataOut   <= "00000000";
      else
        if tmpRxC = '1' and Enable = '1' then
          case RxState is
          when "0000" | "0001" | "0010" | "0011" |
					"0100" | "0101" | "0110" => -- data bits 0 to 6
            ShtReg    <= tmpRxD & ShtReg(7 downto 1);
			   RxParity  <= RxParity xor tmpRxD;
				parityErr <= parityErr;
				frameErr  <= frameErr;
				outErr    <= outErr;
				RxValid   <= '0';   
				DataOut   <= DataOut;
		      RxFalse   <= '0';
            RxFinish  <= '0';
				if RxState = "0110" then
 			     if Format(2) = '0' then
                RxState <= "1000";          -- 7 data + parity
			     else
                RxState <= "0111";          -- 8 data bits
				  end if; -- Format(2)
				else
              RxState   <= RxState + CntOne;
				end if; -- RxState
          when "0111" =>                 -- data bit 7
            ShtReg    <= tmpRxD & ShtReg(7 downto 1);
			   RxParity  <= RxParity xor tmpRxD;
				parityErr <= parityErr;
				frameErr  <= frameErr;
				outErr    <= outErr;
				RxValid   <= '0';   
				DataOut   <= DataOut;
		      RxFalse   <= '0';
            RxFinish  <= '0';
			   if Format(1) = '1' then      -- parity bit ?
              RxState <= "1000";         -- yes, go to parity
				else
              RxState <= "1001";         -- no, must be 2 stop bit bits
			   end if;
	       when "1000" =>                 -- parity bit
			   if Format(2) = '0' then
              ShtReg <= tmpRxD & ShtReg(7 downto 1); -- 7 data + parity
				else
				  ShtReg <= ShtReg;          -- 8 data + parity
				end if;
				RxParity <= RxParity;
				if Format(0) = '0' then      -- parity polarity ?
				  if RxParity = tmpRxD then  -- check even parity
					  parityErr <= '1';
				  else
					  parityErr <= '0';
				  end if;
				else
				  if RxParity = tmpRxD then  -- check for odd parity
					  parityErr <= '0';
				  else
					  parityErr <= '1';
				  end if;
				end if;
				frameErr  <= frameErr;
				outErr    <= outErr;
				RxValid   <= '0';   
				DataOut   <= DataOut;
		      RxFalse   <= '0';
            RxFinish  <= '0';
            RxState   <= "1001";
          when "1001" =>                 -- stop bit (Only one required for RX)
			   ShtReg    <= ShtReg;
				RxParity  <= RxParity;
				parityErr <= parityErr;
            if tmpRxD = '1' then         -- stop bit expected
              frameErr <= '0';           -- yes, no framing error
            else
              frameErr <= '1';           -- no, framing error
            end if;
            if tmpDRdy = '1' then        -- Has previous data been read ? 
              outErr <= '1';             -- no, overrun error
            else
              outErr <= '0';             -- yes, no over run error
            end if;
				RxValid   <= '1';   
				DataOut   <= ShtReg;
		      RxFalse   <= '0';
            RxFinish  <= '1';
            RxState   <= "1111";
          when others =>                 -- this is the idle state
            ShtReg    <= ShtReg;
			   RxParity  <= RxParity;
				parityErr <= parityErr;
				frameErr  <= frameErr;
				outErr    <= outErr;
				RxValid   <= '0';   
				DataOut   <= DataOut;
			   if RxStart = '1' and tmpRxD = '0' then  -- look for start request
		        RxFalse   <= '0';
              RxFinish <= '0';
              RxState  <= "0000"; -- yes, read data
			   else
				  if RxStart = '1' and tmpRxD = '1' then -- start request, but no start bit
				  	 RxFalse   <= '1';
              else
				    RxFalse   <= '0';
				  end if;
			     RxFinish  <= '1';
				  RxState <= "1111";    -- otherwise idle
			   end if;
          end case; -- RxState
		  else
            ShtReg    <= ShtReg;
			   RxParity  <= RxParity;
				parityErr <= parityErr;
				frameErr  <= frameErr;
				outErr    <= outErr;
				RxValid   <= RxValid;   
				DataOut   <= DataOut;
		      RxFalse   <= RxFalse;
			   RxFinish  <= RxFinish;
				RxState   <= RxState;
        end if; -- tmpRxC
      end if; -- reset
    end if; -- clk
  end process;

  DARdy <= tmpDRdy;
  DAOut <= DataOut;
  FRErr <= frameErr;
  ORErr <= outErr;
  PAErr <= parityErr;

end Behaviour; --==================== End of architecture ====================--