--===========================================================================--
--
--  S Y N T H E Z I A B L E    CPU68 / WISHBONE System  (Altera Cyclone Version)
--
--  www.OpenCores.Org - August 2003
--  This core adheres to the GNU public license
--
-- File name      : wb_cyclone_cpu68.vhd
--
-- Purpose        : Implements a WISHBONE compatble system
--                  based on the 6801 compatible CPU core by John Kent
--                  (http://members.optushome.com.au/jekent)
--                  All Wishbone Version by Michael L. Hasenfratz (mikeh@ToThe.Net)
--
-- Dependencies   : ieee.Std_Logic_1164
--                  ieee.std_logic_unsigned
--                  cpu01.vhd
--                  wb_rom.vhd
--                  wb_ram.vhd
--                  wb_acia.vhd
--                  wb_pio.vhd
--
-- Author         : Michael L. Hasenfratz Sr.mikeh@ToThe.Net
--
-- CPU01 Core by  : John Kent (http://members.optushome.com.au/jekent)
--                  (CPU01.VHD Revision 1.0 24, August, 2003)
--
--===========================================================================----
--
-- Revision History:
--
-- Revision Date        Author
--===========================================================================--
--	0.1			Thursday, August 07, 2003 [4:58 PM] (mlh) Michael L. Hasenfratz Sr.
--	0.2			Friday, August 29, 2003 (mlh) 				Changed to CPU01
--	0.3			Wednesday, September 10, 2003 (mlh) 	Added PIO
--	0.4			Sunday, October 12, 2003 (mlh) 				Corrected Short I/O Window size
--	0.5			Saturday, October 18, 2003 (mlh) 			Added Genreric divider to
--																								generate 4.9152MHz clock
-------------------------------------------------------------------------------

--
--	Local PACKAGE
--
library ieee;
   use ieee.std_logic_1164.all;
   use IEEE.STD_LOGIC_ARITH.ALL;

package my_local_pkg is

	-- Define some of the CONSTANTS needed
	constant	BRD_CLOCK :								integer	:= 50000;		-- Boards basic clock in KHz
	constant	LPM_WIDTH :								integer := 8;				-- basic data granularity
	constant	LPM_ROM_WIDTHAD :					integer := 11;			-- 2KByte Internal ROM
	constant	LPM_BSCTRAM_WIDTHAD :			integer := 7;				-- 128Byte Internal RAM
	constant	LPM_DSCTRAM_WIDTHAD :			integer := 15;			-- 32KByte External RAM
	constant	LPM_FILE :								string := "cpu01mon.hex";
--	constant	LPM_FILE :								string := "MON68.hex";
	constant	LPM_FAMILY :							string := "CYCLONE";

end;

-------------------------------------------------------------------------------
--
-- Wishbone System68
--
-------------------------------------------------------------------------------
library ieee;
   use ieee.std_logic_1164.all;
   use ieee.std_logic_arith.all;
   use ieee.std_logic_unsigned.all;
   use ieee.numeric_std.all;

library work;
   use work.my_local_pkg.all;
--   use work.lpm_components.all;

entity wb_cyclone_cpu68 is
	port (
		-- External RAM H/W Interface
		FSE_A :					out		std_logic_vector(22 downto 0);
		FSE_D :					inout	std_logic_vector(31 downto 0);
		SRAM_BE_N :			out		std_logic_vector(3 downto 0);
		SRAM_WE_N :			out		std_logic;		-- ram Write Enable
		SRAM_CS_N :			out		std_logic;		-- ram Chip Select
		SRAM_OE_N :			out		std_logic;		-- ram Output Enable

		-- External UART H/W Interface
		TXD :						out		std_logic_vector(2 downto 1);	-- Tx Data
		RXD :						in		std_logic_vector(2 downto 1);	-- Rx Data
		RTS :				 		out		std_logic_vector(1 downto 1);	-- Request To Send
		CTS :				 		in		std_logic_vector(1 downto 1);	-- Clear To Send

		-- Unused DevKit Kit Signals
		FLASH_CS_N :		out		std_logic;
		FLASH_OE_N :		out		std_logic;
		FLASH_RW_N :		out		std_logic;
		FLASH_RY_BY_N :	in		std_logic;

		ENET_BE_N :			out		std_logic_vector(3 downto 0);
		ENET_ADS_N :		out		std_logic;
		ENET_AEN :			out		std_logic;
		ENET_CYCLE_N :	out		std_logic;
		ENET_DATACS_N :	out		std_logic;
		ENET_IOR_N :		out		std_logic;
		ENET_IOW_N :		out		std_logic;
		ENET_LCLK :			in		std_logic;
		ENET_LDEV_N : 	out		std_logic;
		ENET_W_R_N : 		out		std_logic;

		RI : 						in		std_logic_vector(1 downto 1);
		DCD :				 		in		std_logic_vector(1 downto 1);
		DSR :				 		in		std_logic_vector(1 downto 1);
		DTR :				 		out		std_logic_vector(1 downto 1);

		--	External PIO H/W Interface
		Display_7_Segment :	inout	std_logic_vector(15 downto 0);

		PORT2_IO :			inout	std_logic_vector(7 downto 0);
		PORT3_IO :			inout	std_logic_vector(7 downto 0);

		PROTO2_IO :			inout	std_logic_vector(40 downto 0);

		-- System Common
		PLD_CLOCKINPUT :	in		std_logic_vector(1 downto 1);		-- Board Clock
		PLD_CLEAR_N :	in		std_logic			-- System Reset
	);
end wb_cyclone_cpu68;

-------------------------------------------------------------------------------
-- Architecture for the Wishbone System68
-------------------------------------------------------------------------------
architecture bhv_wb_cyclone_cpu68 of wb_cyclone_cpu68 is

-----------------------------------------------------------------------------
-- Components
-----------------------------------------------------------------------------

-- CPU01
component wb_cpu01
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
end component wb_cpu01;

--	ROM
component wb_lpm_rom
	generic (
		LPM_WIDTH	:		positive	range 1 to 64 := 8;				-- data bits WIDE
		LPM_WIDTHAD :	positive	range 1 to 32	:= 8;				-- address bits;
		LPM_FILE :		string	:= "my_rom";								-- ROM Data File
		LPM_FAMILY  : string := "UNUSED"
	);
	port (
	  DAT_O :      out std_logic_vector(LPM_WIDTH-1 downto 0);
		ADR_I :      in  std_logic_vector(LPM_WIDTHAD-1 downto 0);
		SEL_I :      in  std_logic_vector((LPM_WIDTH/8)-1 downto 0);
		STB_I :	     in  std_logic;		-- VMA (Valid Memory Access)
		CYC_I :	     in  std_logic;		-- CYC in progress
		ACK_O :      out std_logic;		-- Data ready
		CLK_I :	     in  std_logic;		-- System Clock
		RST_I :	     in  std_logic		-- Reset
	);
end component;

--	RAM
component wb_lpm_ram
	generic (
		LPM_WIDTH	:		positive	range 1 to 64 := 8;				-- data bits WIDE
		LPM_WIDTHAD :	positive	range 1 to 32	:= 8;				-- address bits;
		LPM_FAMILY  : string := "UNUSED"
	);
	port (
	  DAT_I :      in  std_logic_vector(LPM_WIDTH-1 downto 0);
	  DAT_O :      out std_logic_vector(LPM_WIDTH-1 downto 0);
		ADR_I :      in  std_logic_vector(LPM_WIDTHAD-1 downto 0);
		SEL_I :      in  std_logic_vector((LPM_WIDTH/8)-1 downto 0);
		WE_I :       in  std_logic;
		STB_I :	     in  std_logic;		-- VMA (Valid Memory Access)
		CYC_I :	     in  std_logic;		-- CYC in progress
		ACK_O :      out std_logic;		-- Data ready
		CLK_I :	     in  std_logic;		-- System Clock
		RST_I :	     in  std_logic		-- Reset
	);
end component;

--	External RAM
component wb_ram
	generic (
		RAM_WIDTH	:		positive	range 1 to 64 := 8;				-- data bits WIDE
		RAM_WIDTHAD :	positive	range 1 to 32	:= 8				-- address bits;
	);
	port (
	  DAT_I :      in    std_logic_vector(RAM_WIDTH-1 downto 0);
	  DAT_O :      out   std_logic_vector(RAM_WIDTH-1 downto 0);
		ADR_I :      in    std_logic_vector(RAM_WIDTHAD-1 downto 0);
		SEL_I :      in    std_logic_vector((RAM_WIDTH/8)-1 downto 0);
		WE_I :       in    std_logic;
		STB_I :	     in    std_logic;		-- VMA (Valid Memory Access)
		CYC_I :	     in    std_logic;		-- CYC in progress
		ACK_O :      out   std_logic;		-- Data ready
		CLK_I :	     in    std_logic;		-- System Clock
		RST_I :	     in    std_logic;		-- Reset

		ram_adr :    out   std_logic_vector(RAM_WIDTHAD-1 downto 0);
	  ram_dat :    inout std_logic_vector(RAM_WIDTH-1 downto 0);
	  ram_ben :    out   std_logic_vector((RAM_WIDTH/8)-1 downto 0);
	  ram_csn :    out   std_logic;		-- RAM Chip Select
	  ram_wen :    out   std_logic;		-- RAM Chip Select
	  ram_oen :    out   std_logic		-- RAM Output Enable
	);
end component;

-- UART / ACIA (subset)
component wb_acia is
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
end component;

component wb_ioport is
	port (
		-- WishBone Interface
	  DAT_I :      in  std_logic_vector(7 downto 0);
	  DAT_O :      out std_logic_vector(7 downto 0);
		ADR_I :      in  std_logic_vector(2 downto 0);		-- Register Select
		SEL_I :      in  std_logic;		-- Byte Lane Select
		STB_I :	     in  std_logic;		-- VMA (Valid Memory Access)
		CYC_I :	     in  std_logic;		-- CYC in progress (Device Select)
		WE_I :	     in  std_logic;		-- Write Enable
		ACK_O :      out std_logic;		-- Data ready
		CLK_I :	     in  std_logic;		-- System Clock
		RST_I :	     in  std_logic;		-- Reset

		-- External H/W Interface
		PORT0_IO :	inout	std_logic_vector(7 downto 0);
		PORT1_IO :	inout	std_logic_vector(7 downto 0);
		PORT2_IO :	inout	std_logic_vector(7 downto 0);
		PORT3_IO :	inout	std_logic_vector(7 downto 0)
	);
end component;

-----------------------------------------------------------------------------
-- Signals
-----------------------------------------------------------------------------
	signal	DAT_O_BSCTRAM :	std_logic_vector(7 downto 0);
	signal	DAT_O_DSCTRAM :	std_logic_vector(7 downto 0);
	signal	DAT_O_PIO :			std_logic_vector(7 downto 0);
	signal	DAT_O_UART :		std_logic_vector(7 downto 0);
	signal	DAT_O_ROM :			std_logic_vector(7 downto 0);
	signal	DAT_I :					std_logic_vector(7 downto 0);
	signal	DAT_O :					std_logic_vector(7 downto 0);
	signal	SEL_O :					std_logic_vector((LPM_WIDTH/8)-1 downto 0);
	signal	ADR_O :					std_logic_vector(15 downto 0);
	signal	WE_O :					std_logic;		-- Memory WRITE in progress
	signal	STB_O :					std_logic;		-- VMA (Valid Memory Access)
	signal	CYC_O :					std_logic;		-- CYC in progress
	signal	ACK_I :					std_logic;		-- Not HOLD
	signal	CLK_I :					std_logic;		-- System Clock
	signal	RST_I :					std_logic;		-- Reset
	signal	HALT_I :				std_logic;		-- HALT (halt processor) TAG_TYPE=CYCLE
	signal	IRQ_ICF :				std_logic;		-- ICF IRQ (maskable Interrupt) TAG_TYPE=CYCLE
	signal	IRQ_OCF :				std_logic;		-- OCF IRQ (maskable Interrupt) TAG_TYPE=CYCLE
	signal	IRQ_TOF :				std_logic;		-- TOF IRQ (maskable Interrupt) TAG_TYPE=CYCLE
	signal	IRQ_SCI :				std_logic;		-- SCI IRQ (maskable Interrupt) TAG_TYPE=CYCLE
	signal	IRQ_I :					std_logic;		-- IRQ (maskable interrupt) TAG_TYPE=CYCLE
	signal	NMI_I :					std_logic;		-- NMI (NON-maskable interrupt) TAG_TYPE=CYCLE

	--	Address Decoding Signals
	signal	rom_sel :				std_logic;		-- Select the ROM
	signal	dram_sel :			std_logic;		-- Select the DSCT RAM
	signal	bram_sel :			std_logic;		-- Select the BSCT RAM
	signal	pio_sel :				std_logic;		-- Select the PIO
	signal	uart_sel :			std_logic;		-- Select the UART
	signal	rom_ack :				std_logic;		-- ROM ACK
	signal	dram_ack :			std_logic;		-- DSCT RAM ACK
	signal	bram_ack :			std_logic;		-- BSCT RAM ACK
	signal	pio_ack :				std_logic;		-- PIO ACK
	signal	uart_ack :			std_logic;		-- UART ACK
	signal	dmy_ack :				std_logic;		-- Dummy ACK for UNUSED locations

	-- External RAM H/W Interface
	signal	ram_adr :				std_logic_vector(LPM_DSCTRAM_WIDTHAD-1 downto 0);
	signal	ram_dat :				std_logic_vector(LPM_WIDTH-1 downto 0);
	signal	ram_ben :				std_logic_vector((LPM_WIDTH/8)-1 downto 0);
	signal	ram_wen :				std_logic;		-- ram Write Enable
	signal	ram_csn :				std_logic;		-- ram Chip Select
	signal	ram_oen :				std_logic;		-- ram Output Enable

	--	External PIO H/W Interface
	signal	PORT0_IO :			std_logic_vector(7 downto 0);
	signal	PORT1_IO :			std_logic_vector(7 downto 0);
--	signal	PORT2_IO :			std_logic_vector(7 downto 0);
--	signal	PORT3_IO :			std_logic_vector(7 downto 0)

	-- External UART H/W Interface
	signal	iTxD :					std_logic;		-- Tx Data
	signal	iRxD :					std_logic;		-- Rx Data
	signal	uart_irq :			std_logic;		-- UART Interrupt

	signal	SysClk :				std_logic;		-- System Clock
	signal	BrdClk :				std_logic;		-- Board Clock
	signal	nReset :				std_logic;		-- System Reset

	-- *** Temp ***
	signal	RTSn :					std_logic;		-- Request To Send
	signal	CTSn :					std_logic;		-- Clear To Send

begin

-----------------------------------------------------------------------------
-- Connect the Components
-----------------------------------------------------------------------------

cpu : wb_cpu01  port map (
	  DAT_I		=> DAT_I,
	  DAT_O		=> DAT_O,
		SEL_O		=> SEL_O,
		ADR_O		=> ADR_O,
		WE_O		=> WE_O,
		STB_O		=> STB_O,
		CYC_O		=> CYC_O,
		ACK_I		=> ACK_I,
		CLK_I		=> CLK_I,
		RST_I		=> RST_I,
		HALT_I	=> HALT_I,
		IRQ_ICF	=> IRQ_ICF,
		IRQ_OCF	=> IRQ_OCF,
		IRQ_TOF	=> IRQ_TOF,
		IRQ_SCI	=> IRQ_SCI,
		IRQ_I		=> IRQ_I,
		NMI_I		=> NMI_I
  );

rom : wb_lpm_rom
	generic map (
		LPM_WIDTH		=> LPM_WIDTH,
		LPM_WIDTHAD	=> LPM_ROM_WIDTHAD,
		LPM_FILE		=> LPM_FILE,
    LPM_FAMILY	=> LPM_FAMILY
	)
	port map (
	  DAT_O			=> DAT_O_ROM,
		ADR_I			=> ADR_O(LPM_ROM_WIDTHAD-1 downto 0),
		SEL_I			=> SEL_O,
		STB_I			=> STB_O,
		CYC_I			=> rom_sel,
		ACK_O			=> rom_ack,
		CLK_I			=> CLK_I,
		RST_I			=> RST_I
	);

bram : wb_lpm_ram
	generic map (
		LPM_WIDTH		=> LPM_WIDTH,
		LPM_WIDTHAD	=> LPM_BSCTRAM_WIDTHAD,
    LPM_FAMILY	=> LPM_FAMILY
	)
	port map (
	  DAT_I			=> DAT_O,
	  DAT_O			=> DAT_O_BSCTRAM,
		ADR_I			=> ADR_O(LPM_BSCTRAM_WIDTHAD-1 downto 0),
		WE_I			=> WE_O,
		SEL_I			=> SEL_O,
		STB_I			=> STB_O,
		CYC_I			=> bram_sel,
		ACK_O			=> bram_ack,
		CLK_I			=> CLK_I,
		RST_I			=> RST_I
	);

dram : wb_ram
	generic map (
		RAM_WIDTH		=> LPM_WIDTH,
		RAM_WIDTHAD	=> LPM_DSCTRAM_WIDTHAD
	)
	port map (
	  DAT_I			=> DAT_O,
	  DAT_O			=> DAT_O_DSCTRAM,
		ADR_I			=> ADR_O(LPM_DSCTRAM_WIDTHAD-1 downto 0),
		WE_I			=> WE_O,
		SEL_I			=> SEL_O,
		STB_I			=> STB_O,
		CYC_I			=> dram_sel,
		ACK_O			=> dram_ack,
		CLK_I			=> CLK_I,
		RST_I			=> RST_I,
		ram_adr		=> ram_adr,
	  ram_dat		=> ram_dat,
	  ram_ben		=> ram_ben,
	  ram_csn		=> ram_csn,
	  ram_wen		=> ram_wen,
	  ram_oen		=> ram_oen
	);

pio0 : wb_ioport
	port map (
	  DAT_I			=> DAT_O,
	  DAT_O			=> DAT_O_PIO,
		ADR_I			=> ADR_O(2 downto 0),
		WE_I			=> WE_O,
		SEL_I			=> SEL_O(0),
		STB_I			=> STB_O,
		CYC_I			=> pio_sel,
		ACK_O			=> pio_ack,
		CLK_I			=> CLK_I,
		RST_I			=> RST_I,
		PORT0_IO	=> PORT0_IO,
		PORT1_IO	=> PORT1_IO,
		PORT2_IO	=> PORT2_IO,
		PORT3_IO	=> PORT3_IO
	);

uart0 : wb_acia
	port map (
	  DAT_I			=> DAT_O,
	  DAT_O			=> DAT_O_UART,
		ADR_I			=> ADR_O(0),
		WE_I			=> WE_O,
		SEL_I			=> SEL_O(0),
		STB_I			=> STB_O,
		CYC_I			=> uart_sel,
		ACK_O			=> uart_ack,
		CLK_I			=> CLK_I,
		RST_I			=> RST_I,
		IRQ_O			=> uart_irq,
	  TxD				=> iTxD,
		RxD				=> iRxD,
	  RTSn			=> RTSn,
	  CTSn			=> CTSn
	);

-----------------------------------------------------------------------------
-- Concurrent Interconnects
-----------------------------------------------------------------------------
	-- merge te ACKs
	ACK_I		<= rom_ack or dram_ack or bram_ack or pio_ack or uart_ack or dmy_ack;

	IRQ_ICF	<= '0';
	IRQ_OCF	<= '0';
	IRQ_TOF	<= '0';
	IRQ_SCI	<= '0';

	HALT_I	<= '0';
	NMI_I		<= '0';

	IRQ_I		<= uart_irq;		-- connect the UART/ACIA
	CLK_I 	<= SysClk;			-- Connect the CLOCK

-- ******************************************
-- Temporary assignments for DevKit
-- ******************************************
	-- Cyclone DevKit has 32bit SRAM. So we start with FSE_A(2)
	FSE_A(FSE_A'HIGH downto ram_adr'LENGTH+2)		<= (others => '0');
	FSE_A(ram_adr'HIGH+2 downto ram_adr'LOW+2)	<= ram_adr;

	FSE_D(FSE_D'HIGH downto ram_dat'LENGTH)	<= (others => 'Z');
	FSE_D(ram_dat'RANGE)	<= ram_dat;

	SRAM_BE_N(3 downto 1)	<= (others => '1');
	SRAM_BE_N(0)	<= ram_ben(0);
	SRAM_CS_N			<= ram_csn;
	SRAM_OE_N			<= ram_oen;
	SRAM_WE_N			<= ram_wen;

	BrdClk				<= PLD_CLOCKINPUT(1);
	nReset				<= PLD_CLEAR_N;

	Display_7_Segment(15 downto 8)	<= PORT0_IO;
	Display_7_Segment( 7 downto 0)	<= PORT1_IO;

	PROTO2_IO(39)	<= SysClk;

	ENET_BE_N			<= (others => '1');
	ENET_ADS_N		<= '1';
	ENET_AEN			<= '1';
	ENET_CYCLE_N	<= '1';
	ENET_DATACS_N	<= '1';
	ENET_IOR_N		<= '1';
	ENET_IOW_N		<= '1';
	ENET_LDEV_N		<= '1';
	ENET_W_R_N		<= '1';

	FLASH_CS_N		<= '1';
	FLASH_OE_N		<= '1';
	FLASH_RW_N		<= '1';

	TXD(1)				<= iTxD;
	iRxD					<= RXD(1);

	TXD(2)				<= '1';

	DTR						<= (others => '1');
	RTS						<= (others => '1');
	CTSn					<= '0';
-- ******************************************

-----------------------------------------------------------------------------
-- Memory Map Decoding
-----------------------------------------------------------------------------
-- memory decoding
dcdr : process(ADR_O, CYC_O, STB_O, DAT_O_ROM, DAT_O_BSCTRAM, DAT_O_DSCTRAM, DAT_O_PIO, DAT_O_UART)
	begin
		-- assume all are negated
		rom_sel		<= '0';
		dram_sel	<= '0';
		bram_sel	<= '0';
		pio_sel		<= '0';
		uart_sel	<= '0';
		dmy_ack		<= '0';
		DAT_I			<= (others => '0');

		-- ROM
		if ADR_O(ADR_O'HIGH) = '1' then
			rom_sel	<= CYC_O and STB_O;
			DAT_I	<= DAT_O_ROM;
		else
			-- see if SHORT Mem or I/O selected
			if ADR_O(ADR_O'HIGH-1 downto 8) = "0000000" then

				if ADR_O(7) = '1' then
					-- Short Memory BSCT RAM $00FF - $0080
					bram_sel	<= CYC_O;
					DAT_I	<= DAT_O_BSCTRAM;
				else
					-- Short I/O = $007F - $0000 (4 byte blocks)
					case ADR_O(6 downto 2) is

						when "00000" | "00001" =>	-- $0007 - $0000
						-- PIO
							pio_sel	<= CYC_O and STB_O;
							DAT_I	<= DAT_O_PIO;

						when "00100" =>	-- $0013 - $0010
						-- UART
							uart_sel	<= CYC_O and STB_O;
							DAT_I	<= DAT_O_UART;

						when others =>
							dmy_ack	<= CYC_O and STB_O;
							DAT_I	<= X"A5";

					end case;
				end if;
			else
				-- DSCT RAM $7FFF - $0100
				dram_sel	<= CYC_O and STB_O;
				DAT_I	<= DAT_O_DSCTRAM;

			end if;
		end if;
	end process;

-----------------------------------------------------------------------------
-- System Clock (4.9152MHz) generator
-----------------------------------------------------------------------------
clkgen : process( BrdClk )
	constant	SYSTEM_CLK :	integer := 4915;	-- in KHz
	constant	DIVISOR :			integer := (BRD_CLOCK / SYSTEM_CLK) / 2;
	variable	clkcntr :			integer range 0 to DIVISOR-1;
	begin
		if BrdClk'EVENT and BrdClk = '1' then
			if nReset = '0' then
				SysClk	<= '0';
				clkcntr	:= 0;
			else
				if clkcntr = DIVISOR-1 then
					clkcntr	:= 0;
					SysClk	<= not( SysClk );	-- toggle the system clock
				else
					clkcntr	:= clkcntr + 1;
				end if;
			end if;
		end if;
	end process;

-----------------------------------------------------------------------------
-- System System RESET
-----------------------------------------------------------------------------
rstgen : process( SysClk )
	constant	RESETDLY :		integer := 32;
	variable	rstcntr :			integer range 0 to RESETDLY-1;
	variable	rst :					std_logic;
	begin
		if nReset = '0' then
			rst			:= '0';
			rstcntr	:= 0;
		elsif SysClk'EVENT and SysClk = '1' then
			if rstcntr = RESETDLY - 1 then
				rst			:= '1';
			else
				rst			:= '0';
				rstcntr	:= rstcntr + 1;
			end if;
		end if;
		RST_I		<= not( rst );
	end process;

end bhv_wb_cyclone_cpu68; --===================== End of architecture =======================--

