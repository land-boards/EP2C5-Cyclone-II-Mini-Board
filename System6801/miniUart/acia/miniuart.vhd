--===========================================================================--
--
--  S Y N T H E Z I A B L E    miniUART   C O R E
--
--  www.OpenCores.Org - January 2000
--  This core adheres to the GNU public license
--
-- Design units   : miniUART core for the OCRP-1
--
-- File name      : miniuart.vhd
--
-- Purpose        : Implements an miniUART device for communication purposes
--                  between the OR1K processor and the Host computer through
--                  an RS-232 communication protocol.
--
-- Library        : uart_lib.vhd
--
-- Dependencies   : IEEE.Std_Logic_1164
--
-- Simulator      : ModelSim PE/PLUS version 4.7b on a Windows95 PC
--===========================================================================--
-------------------------------------------------------------------------------
-- Revision list
-- Version   Author                 Date           Changes
--
-- 0.1      Ovidiu Lupas     15 January 2000       New model
-- 1.0      Ovidiu Lupas     January  2000         Synthesis optimizations
-- 2.0      Ovidiu Lupas     April    2000         Bugs removed - RSBusCtrl
--          the RSBusCtrl did not process all possible situations
--
--        olupas@opencores.org
--
-- 3.0      John Kent        October  2002         Changed Status bits to match mc6805
--          Added CTS, RTS, Baud rate control & Software Reset
--
-- 3.1      Mike Hasenfratz  20 August   2003      Conntected Format bits to control registers
--				mikehsr@opencores.org
-------------------------------------------------------------------------------
-- Entity for miniUART Unit - 9600 baudrate                                  --
-------------------------------------------------------------------------------
library ieee;
   use ieee.std_logic_1164.all;
   use ieee.numeric_std.all;

entity miniUART is
  port (
     SysClk   : in  Std_Logic;  -- System Clock
     rst      : in  Std_Logic;  -- Reset input (active high)
     cs       : in  Std_Logic;
     rw       : in  Std_Logic;
     RxD      : in  Std_Logic;
     TxD      : out Std_Logic;
     CTS_n    : in  Std_Logic;
     RTS_n    : out Std_Logic;
     Irq      : out Std_Logic;  -- interrupt
     Addr     : in  Std_Logic;  -- Register Select
     DataIn   : in  Std_Logic_Vector(7 downto 0); --
     DataOut  : out Std_Logic_Vector(7 downto 0)); --
end entity; --================== End of entity ==============================--
-------------------------------------------------------------------------------
-- Architecture for miniUART Controller Unit
-------------------------------------------------------------------------------
architecture uart of miniUART is
  -----------------------------------------------------------------------------
  -- Signals
  -----------------------------------------------------------------------------
  signal RxData : Std_Logic_Vector(7 downto 0); --
  signal TxData : Std_Logic_Vector(7 downto 0); --
  signal StatReg : Std_Logic_Vector(7 downto 0); -- status register
  signal CtrlReg : Std_Logic_Vector(7 downto 0); -- control register
  --             StatReg detailed
  -----------+--------+--------+--------+--------+--------+--------+--------+
  --  Int    | PErr   | ORErr  | FErr   | CTS    | DCD    | TBufE  | DRdy   |
  -----------+--------+--------+--------+--------+--------+--------+--------+
  signal EnabRx : Std_Logic;  -- Enable RX unit
  signal EnabTx : Std_Logic;  -- Enable TX unit
  signal DRdy   : Std_Logic;  -- Receive Data ready
  signal TBufE  : Std_Logic;  -- Transmit buffer empty
  signal FErr   : Std_Logic;  -- Frame error
  signal OErr   : Std_Logic;  -- Output error
  signal PErr   : Std_Logic;  -- Parity error
  signal Read   : Std_Logic;  -- Read receive buffer
  signal Load   : Std_Logic;  -- Load transmit buffer
  signal Int    : Std_Logic;  -- Interrupt bit
  signal Reset  : Std_Logic;  -- Reset (Software & Hardware)
  -----------------------------------------------------------------------------
  -- Baud rate Generator
  -----------------------------------------------------------------------------
  component ClkUnit is
   port (
     Clk      : in  Std_Logic;  -- System Clock
     Reset    : in  Std_Logic;  -- Reset input
     EnableRX : out Std_Logic;  -- Control signal
     EnableTX : out Std_Logic;  -- Control signal
	  BaudRate : in  Std_Logic_Vector(1 downto 0));
  end component;
  -----------------------------------------------------------------------------
  -- Receive Unit
  -----------------------------------------------------------------------------
  component RxUnit is
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
     DAOut  : out Std_Logic_Vector(7 downto 0));
  end component;
  -----------------------------------------------------------------------------
  -- Transmitter Unit
  -----------------------------------------------------------------------------
  component TxUnit is
  port (
     Clk    : in  Std_Logic;  -- Clock signal
     Reset  : in  Std_Logic;  -- Reset input
     Enable : in  Std_Logic;  -- Enable input
     LoadD  : in  Std_Logic;  -- Load transmit data
	  Format : in  Std_Logic_Vector(2 downto 0) := "000"; -- word format
     TxD    : out Std_Logic;  -- RS-232 data output
     TBE    : out Std_Logic;  -- Tx buffer empty
     DataO  : in  Std_Logic_Vector(7 downto 0));
  end component;
begin
  -----------------------------------------------------------------------------
  -- Instantiation of internal components
  -----------------------------------------------------------------------------

  ClkDiv  : ClkUnit port map (
                Clk      => SysClk,
					 EnableRx => EnabRX,
					 EnableTx => EnabTX,
					 BaudRate => CtrlReg(1 downto 0),
					 Reset    => Reset);

  TxDev   : TxUnit  port map (
                Clk      => SysClk,
					 Reset    => Reset,
					 Enable   => EnabTX,
					 LoadD    => Load,
           Format		=> CtrlReg(4 downto 2),
					 TxD      => TxD,
					 TBE      => TBufE,
					 DataO    => TxData);

  RxDev   : RxUnit  port map (
           Clk      => SysClk,
					 Reset    => Reset,
					 Enable   => EnabRX,
					 RxD      => RxD,
					 ReadD    => Read,
           Format		=> CtrlReg(4 downto 2),
					 FRErr    => FErr,
					 ORErr    => OErr,
					 PAErr		=> PErr,
					 DARdy    => DRdy,
					 DAOut    => RxData);

  -----------------------------------------------------------------------------
  -- Implements the controller for Rx&Tx units
  -----------------------------------------------------------------------------
  RSBusCtrl : process(SysClk, Reset, DRdy, TBufE, FErr, OErr, Int, CtrlReg)
     variable StatM : Std_Logic_Vector(7 downto 0);
  begin
     if SysClk'event and SysClk='0' then
        if Reset = '1' then
           StatM := "00000000";
           Int <= '0';
        else
           StatM(0) := DRdy;
           StatM(1) := TBufE;
			  StatM(2) := '0'; -- DCD
			  StatM(3) := CTS_n;
           StatM(4) := FErr;
           StatM(5) := OErr;
           StatM(6) := PErr; -- Parrity error
		     StatM(7) := Int;
		     Int <= (CtrlReg(7) and DRdy) or
		           ((not CtrlReg(6)) and CtrlReg(5) and TBufE);
        end if;

		 RTS_n <= CtrlReg(6) and not CtrlReg(5);
       Irq <= Int;
       StatReg <= StatM;
     end if;
  end process;

-----------------------------------------------------------------------------
-- Combinational section
-----------------------------------------------------------------------------

control_strobe:  process(SysClk, Reset, cs, rw, Addr, DataIn, CtrlReg )
  begin
	if SysClk'event and SysClk='1' then
		if (reset = '1') then
			CtrlReg <= "00000000";
			Load <= '0';
			Read <= '0';
		else
			if cs = '1' then
				if Addr = '1' then
					CtrlReg <= CtrlReg;
					if rw = '0' then  -- write data register
						Load <= '1';
						Read <= '0';
					else               -- read Data Register
						Load <= '0';
						Read <= '1';
					end if; -- rw
				else                 -- read Status Register
					Load <= '0';
					Read <= '0';
					if rw = '0' then  -- write data register
						CtrlReg <= DataIn;
					else               -- read Data Register
						CtrlReg <= CtrlReg;
					end if; -- rw
				end if; -- Addr
			else                   -- not selected
				Load <= '0';
				Read <= '0';
				CtrlReg <= CtrlReg;
			end if;  -- cs
		end if; -- reset
	end if; -- SysClk
end process;

---------------------------------------------------------------
--
-- set data output mux
--
--------------------------------------------------------------

data_port: process(Addr, StatReg, RxData, DataIn )
begin
     TxData <= DataIn;
	  if Addr = '1' then
		 DataOut <= RxData;  -- read data register
	  else
		 DataOut <= StatReg;   -- read status register
	  end if; -- Addr
end process;

---------------------------------------------------------------
--
-- reset may be hardware or software
--
---------------------------------------------------------------

uart_reset: process(CtrlReg, rst )
begin
	  Reset <= (CtrlReg(1) and CtrlReg(0)) or rst;
end process;

end uart; --===================== End of architecture =======================--

