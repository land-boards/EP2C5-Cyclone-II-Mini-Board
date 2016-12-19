--===========================================================================--
--
--  S Y N T H E Z I A B L E    miniUART   C O R E
--
--  www.OpenCores.Org - January 2000
--  This core adheres to the GNU public license  
--
-- Design units   : miniUART core for the System68
--
-- File name      : txunit.vhd
--
-- Purpose        : Implements an miniUART device for communication purposes 
--                  between the CPU68 processor and the Host computer through
--                  an RS-232 communication protocol.
--                  
-- Dependencies   : IEEE.Std_Logic_1164
--
--===========================================================================--
-------------------------------------------------------------------------------
-- Revision list
-- Version   Author                 Date                        Changes
--
-- 0.1      Ovidiu Lupas       15 January 2000                 New model
-- 2.0      Ovidiu Lupas       17 April   2000    unnecessary variable removed
--  olupas@opencores.org
--
-- 3.0      John Kent           5 January 2003    added 6850 word format control
-- 3.1      John Kent          12 January 2003    Rearranged state machine code
-- 3.2      John Kent          30 March 2003      Revamped State machine
--  dilbert57@opencores.org
--
-- 3.2      Mike Hasenfratz     7 August   2003   Renamed to match Entity
--					mikehsr@opencores.org
-------------------------------------------------------------------------------
-- Description    : 
-------------------------------------------------------------------------------
-- Entity for the Tx Unit                                                    --
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;

-------------------------------------------------------------------------------
-- Transmitter unit
-------------------------------------------------------------------------------
entity TxUnit is
  port (
     Clk    : in  Std_Logic;  -- Clock signal
     Reset  : in  Std_Logic;  -- Reset input
     Enable : in  Std_Logic;  -- Enable input
     LoadD  : in  Std_Logic;  -- Load transmit data
	  Format : in  Std_Logic_Vector(2 downto 0) := "000"; -- word format
     TxD    : out Std_Logic;  -- RS-232 data output
     TBE    : out Std_Logic;  -- Tx buffer empty
     DataO  : in  Std_Logic_Vector(7 downto 0));
end entity; --================== End of entity ==============================--
-------------------------------------------------------------------------------
-- Architecture for TxUnit
-------------------------------------------------------------------------------
architecture Behaviour of TxUnit is
  type TxStateType is (TxReset_State, TxIdle_State, Start_State, Data_State, Parity_State, Stop_State );
  -----------------------------------------------------------------------------
  -- Signals
  -----------------------------------------------------------------------------
  signal TBuff    : Std_Logic_Vector(7 downto 0); -- transmit buffer
  signal tmpTBufE : Std_Logic;                    -- Transmit Buffer Empty

  signal TReg     : Std_Logic_Vector(7 downto 0); -- transmit register
  signal TxParity : Std_logic;                    -- Parity Bit
  signal DataCnt  : Std_Logic_Vector(3 downto 0); -- Data Bit Counter
  signal tmpTRegE : Std_Logic;                    --  Transmit Register empty
  signal TxState  : TxStateType;

  signal NextTReg     : Std_Logic_Vector(7 downto 0); -- transmit register
  signal NextTxParity : Std_logic;                    -- Parity Bit
  signal NextDataCnt  : Std_Logic_Vector(3 downto 0); -- Data Bit Counter
  signal NextTRegE    : Std_Logic;                    --  Transmit Register empty
  signal NextTxState  : TxStateType;
begin
  ---------------------------------------------------------------------
  -- Transmitter activation process
  ---------------------------------------------------------------------
  TxSync : process(Clk, Reset, Enable, LoadD, DataO, tmpTBufE, tmpTRegE )
  begin
     if Clk'event and Clk = '1' then
        if Reset = '1' then
           tmpTBufE <= '1';
			  TBuff    <= "00000000";
        else
		     if LoadD = '1' then
			    TBuff <= DataO;
             tmpTBufE <= '0';
			  else
			    TBuff <= TBuff;
             if (Enable = '1') and (tmpTBufE = '0') and (tmpTRegE = '1') then
               tmpTBufE <= '1';
				 else
               tmpTBufE <= tmpTBufE;
				 end if;
			  end if;
        end if; -- reset
    end if; -- clk
    TBE <= tmpTBufE;

  end process;

  -----------------------------------------------------------------------------
  -- Implements the Tx unit
  -----------------------------------------------------------------------------
 TxProc :  process(TxState, TBuff, TReg, TxParity, DataCnt, Format, tmpTRegE, tmpTBufE)
  begin
    case TxState is
	 when TxReset_State =>
      TxD          <= '1';
	   NextTReg     <= "00000000";
	   NextTxParity <= '0';
		NextDataCnt  <= "0000";
		NextTRegE    <= '1';
      NextTxState  <= TxIdle_State;

    when Start_State =>
      TxD          <= '0';           -- Start bit
		NextTReg     <= TReg;
	   NextTxParity <= '0';
		if Format(2) = '0' then
		  NextDataCnt <= "0110";       -- 7 data + parity
	   else
        NextDataCnt <= "0111";       -- 8 data
	   end if;
      NextTRegE    <= '0';
      NextTxState  <= Data_State;

    when Data_State =>
      TxD          <= TReg(0);
      NextTReg     <= '1' & TReg(7 downto 1);
      NextTxParity <= TxParity xor TReg(0);
      NextTRegE    <= '0';
		NextDataCnt  <= DataCnt - "0001";
		if DataCnt = "0000" then
	     if (Format(2) = '1') and (Format(1) = '0') then
			 if Format(0) = '0' then            -- 8 data bits
            NextTxState <= Stop_State;       -- 2 stops
			 else
				NextTxState <= TxIdle_State;     -- 1 stop
		    end if;
		  else
			 NextTxState <= Parity_State;       -- parity
		  end if;
		else
        NextTxState  <= Data_State;
		end if;

    when Parity_State =>           -- 7/8 data + parity bit
	   if Format(0) = '0' then
			TxD <= not( TxParity );   -- even parity
		else
			TXD <= TxParity;          -- odd parity
	   end if;
		NextTreg   <= Treg;
		NextTxParity <= '0';
      NextTRegE <= '0';
		NextDataCnt <= "0000";
		if Format(1) = '0' then
			NextTxState <= Stop_State; -- 2 stops
		else
			NextTxState <= TxIdle_State; -- 1 stop
		end if;

    when Stop_State => -- first stop bit
      TxD          <= '1';           -- 2 stop bits
	   NextTreg     <= Treg;
		NextTxParity <= '0';
		NextDataCnt  <= "0000";
      NextTRegE    <= '0';
		NextTxState  <= TxIdle_State;

    when others =>  -- TxIdle_State (2nd Stop bit)
      TxD          <= '1';
	   NextTreg     <= TBuff;
		NextTxParity <= '0';
		NextDataCnt  <= "0000";
		if (tmpTBufE = '0') and (tmpTRegE = '1') then
         NextTRegE   <= '0';
         NextTxState <= Start_State;
	   else
         NextTRegE   <= '1';
         NextTxState <= TxIdle_State;
		end if;

    end case; -- TxState

  end process;

  --
  -- Tx State Machine
  -- Slowed down by "Enable"
  --
  TX_State_Machine: process( Clk, Reset, Enable, NextTReg, NextTxParity, NextDataCnt, NextTRegE, NextTxState )
  begin
    if Clk'event and Clk = '1' then
	   if Reset = '1' then
	      Treg     <= "00000000";
		   TxParity <= '0';
		   DataCnt  <= "0000";
         tmpTRegE <= '1';
		   TxState  <= TxReset_State;
		else
		   if Enable = '1' then
	        Treg     <= NextTreg;
		     TxParity <= NextTxParity;
		     DataCnt  <= NextDataCnt;
           tmpTRegE <= NextTRegE;
		     TxState  <= NextTxState;
			else
	        Treg     <= Treg;
		     TxParity <= TxParity;
		     DataCnt  <= DataCnt;
           tmpTRegE <= tmpTRegE;
			  TxState  <= TxState;
			end if;
		end if;
	 end if;

  end process;

end Behaviour; --=================== End of architecture ====================--