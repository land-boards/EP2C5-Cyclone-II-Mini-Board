--===========================================================================--
--
--  S Y N T H E Z I A B L E    CPU01 / WISHBONE interface
--
--  www.OpenCores.Org - August 2003
--  This core adheres to the GNU public license  
--
-- File name      : wb_cpu68.vhd
--
-- Purpose        : Implements a WISHBONE compatble interface
--                  for the 6801 compatible CPU core by John Kent
--                  (http://members.optushome.com.au/jekent)
--
-- Dependencies   : ieee.Std_Logic_1164
--                  ieee.std_logic_unsigned
--                  cpu01.vhd
--
-- Author         : Michael L. Hasenfratz Sr.
--
-- CPU68 Core by  : John Kent (http://members.optushome.com.au/jekent)
--                  (CPU01.VHD Revision 1.0		August 24, 2003)
--
--===========================================================================----
--
-- Revision History:
--
-- Date:          Revision         Author
--===========================================================================--
-- 1 Aug 2003	    0.1              Michael L. Hasenfratz Sr.
--

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity wb_cpu01 is
	port (	
	  DAT_I :      in  std_logic_vector(7 downto 0);
	  DAT_O :      out std_logic_vector(7 downto 0);
		SEL_O :      out std_logic_vector(0 downto 0);
		ADR_O :      out std_logic_vector(15 downto 0);
		WE_O :	     out std_logic;					-- Memory WRITE in progress
		STB_O :	     out std_logic;					-- VMA (Valid Memory Access)
		CYC_O :	     out std_logic;					-- CYC in progress
		ACK_I :      in  std_logic;					-- Not HOLD
		CLK_I :	     in  std_logic;					-- System Clock
		RST_I :	     in  std_logic;					-- Reset
		HALT_I :     in  std_logic := '0';	-- HALT (halt processor) TAG_TYPE=CYCLE
		IRQ_ICF :    in  std_logic := '0';	-- ICF IRQ (maskable Interrupt) TAG_TYPE=CYCLE
		IRQ_OCF :    in  std_logic := '0';	-- OCF IRQ (maskable Interrupt) TAG_TYPE=CYCLE
		IRQ_TOF :    in  std_logic := '0';	-- TOF IRQ (maskable Interrupt) TAG_TYPE=CYCLE
		IRQ_SCI :    in  std_logic := '0';	-- SCI IRQ (maskable Interrupt) TAG_TYPE=CYCLE
		IRQ_I :      in  std_logic := '0';	-- IRQ (maskable Interrupt) TAG_TYPE=CYCLE
		NMI_I :      in  std_logic := '0'		-- NMI (NON-maskable interrupt) TAG_TYPE=CYCLE
	);
end;

architecture bhv_wb_cpu01 of wb_cpu01 is

---------------------------------------------------------
--	Define the CPU60 interface
---------------------------------------------------------
	component cpu01
	port (	
		clk:	    in  std_logic;
		rst:	    in  std_logic;
		rw:	      out std_logic;
		vma:	    out std_logic;
		address:  out std_logic_vector(15 downto 0);
		data_in:  in  std_logic_vector(7 downto 0);
		data_out: out std_logic_vector(7 downto 0);
		hold:     in  std_logic;
		halt:     in  std_logic;
		nmi:      in  std_logic;
		irq:      in  std_logic;
		irq_icf:  in  std_logic;
		irq_ocf:  in  std_logic;
		irq_tof:  in  std_logic;
		irq_sci:  in  std_logic;
		test_alu: out std_logic_vector(15 downto 0);
		test_cc:  out std_logic_vector(7 downto 0)
		);
	end component;

	signal	rw:				std_logic;
	signal	vma:			std_logic;
	signal	hold :		std_logic;
	signal	test_alu:	std_logic_vector(15 downto 0);
	signal	test_cc:	std_logic_vector(7 downto 0);

begin

---------------------------------------------------------
--	Instantiate the CPU68 interface
---------------------------------------------------------
	cpu0 : cpu01 port map (	
			clk				=> CLK_I,
			rst				=> RST_I,
			rw				=> rw,
			vma				=> vma,
			address		=> ADR_O,
		  data_in		=> DAT_I,
		  data_out	=> DAT_O,
			hold			=> hold,
			halt			=> HALT_I,
			irq_icf		=> IRQ_ICF,
			irq_ocf		=> IRQ_OCF,
			irq_tof		=> IRQ_TOF,
			irq_sci		=> IRQ_SCI,
			nmi				=> NMI_I,
			irq				=> IRQ_I,
			test_alu	=> test_alu,
			test_cc		=> test_cc
			);

---------------------------------------------------------
--	Interconnections
---------------------------------------------------------
	CYC_O			<= vma;
	STB_O			<= vma;
	SEL_O(0)	<= vma;

	WE_O			<= not(rw);
	hold			<= vma and not(ACK_I);

end bhv_wb_cpu01;
	
