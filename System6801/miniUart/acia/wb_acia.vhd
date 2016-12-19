--===========================================================================--
--
--  S Y N T H E Z I A B L E    ACIA (miniUart) / WISHBONE interface
--
--  www.OpenCores.Org - August 2003
--  This core adheres to the GNU public license  
--
-- File name      : wb_acia.vhd
--
-- Purpose        : Implements a WISHBONE compatble interface
--                  for a UART / ACIA
--
-- Dependencies   : ieee.Std_Logic_1164
--                  ieee.std_logic_unsigned
--                  ieee.std_logic_arith
--
-- Author         : Michael L. Hasenfratz Sr.
--								  Based on OpenCores.Org miniUart Ver 3.0
--									*** Note: clkunit.vhd timing based on 50.0MHz 
--
--===========================================================================----
--
-- Revision History:
--
-- Date:          Revision         Author
--===========================================================================--
-- 6 Aug 2003	    0.1              Michael L. Hasenfratz Sr. mikehsr@opencores.org
--      Created
--

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;

--library work;
--use work.std_logic_arith.all;

entity wb_acia is
	port (	
		-- WishBone Interface
	  DAT_I :      in  std_logic_vector(7 downto 0);
	  DAT_O :      out std_logic_vector(7 downto 0);
		ADR_I :      in  std_logic;		-- Register Select
		SEL_I :      in  std_logic;		-- Byte Lane Select
		STB_I :	     in  std_logic;		-- VMA (Valid Memory Access)
		CYC_I :	     in  std_logic;		-- CYC in progress (Device Select)
		WE_I :	     in  std_logic;		-- Write Enable
		ACK_O :      out std_logic;		-- Data ready
		CLK_I :	     in  std_logic;		-- System Clock
		RST_I :	     in  std_logic;		-- Reset
		
		-- Non-WishBone signals
		IRQ_O :      out std_logic;		-- Interrupt Out
		
		-- External H/W Interface
	  TxD :        out std_logic;		-- Tx Data
		RxD :        in  std_logic;		-- Rx Data
	  RTSn :       out std_logic;		-- Request To Send
	  CTSn :       in  std_logic		-- Clear To Send
	);
end;

architecture bhv_wb_acia of wb_acia is

-----------------------------------------------------------------
--
-- Open Cores Mini UART
--
-----------------------------------------------------------------

component miniUART is
  port (
     SysClk   : in  Std_Logic;  -- System Clock
     rst      : in  Std_Logic;  -- Reset input
     cs       : in  Std_Logic;
     rw       : in  Std_Logic;
     RxD      : in  Std_Logic;
     TxD      : out Std_Logic;
     CTS_n    : in  Std_Logic;
     RTS_n    : out Std_Logic;
     Irq      : out Std_logic;
     Addr     : in  Std_Logic;
     DataIn   : in  Std_Logic_Vector(7 downto 0); -- 
     DataOut  : out Std_Logic_Vector(7 downto 0)); -- 
end component;

	signal	irw :			std_logic;		-- internal Read/Write*
	signal	ics :			std_logic;		-- internal Chip Selct
	signal	iack :		std_logic;		-- internal ACK
	
begin

my_uart  : miniUART port map (
   SysClk    => CLK_I,
	 rst       => RST_I,
   cs        => ics,
	 rw        => irw,
	 RxD       => RxD,
	 TxD       => TxD,
	 CTS_n     => CTSN,
	 RTS_n     => RTSn,
   Irq       => IRQ_O,
   Addr      => ADR_I,
	 Datain    => DAT_I,
	 DataOut   => DAT_O
	 );

---------------------------------------------------------
--	Interconnections
---------------------------------------------------------
	irw		<= not(WE_I);		-- invert the Write Enable
	ics		<= STB_I and CYC_I and SEL_I;
	ACK_O	<= STB_I and CYC_I and SEL_I and iack;
	
sel0 :	process(CLK_I, RST_I)
	begin
		if CLK_I'EVENT and CLK_I = '1' then
			if RST_I = '1' then
				iack		<= '0';
			else
				iack		<= ics;
			end if;
		end if;
	end process;
	
end bhv_wb_acia;
	
