--===========================================================================--
--
--  S Y N T H E Z I A B L E    External RAM / WISHBONE interface
--
--  www.OpenCores.Org - August 2003
--  This core adheres to the GNU public license  
--
-- File name      : wb_ram.vhd
--
-- Purpose        : Implements a WISHBONE compatble interface
--
-- Dependencies   : ieee.Std_Logic_1164
--                  ieee.std_logic_unsigned
--
-- Author         : Michael L. Hasenfratz Sr.
--
--===========================================================================----
--
-- Revision History:
--
-- Date:          Revision         Author
--===========================================================================--
-- 4 Aug 2003     0.1              Michael L. Hasenfratz Sr.
--      Created
--

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity wb_ram is
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
end;

architecture bhv_wb_ram of wb_ram is

	signal	ibe :				std_logic_vector(SEL_I'RANGE);	-- Byte Enables
	signal	iadr :			std_logic_vector(ADR_I'RANGE);	-- RAM Address
	signal	idat :			std_logic_vector(DAT_I'RANGE);	-- Write DATA
	signal	iwe :				std_logic;		-- Write Enable
	signal	iwp :				std_logic;		-- Write Pulse
	signal	ioe :				std_logic;		-- Output Enable
	signal	ics :				std_logic;		-- Chip Select
	signal	iack :			std_logic;		-- ACK
	signal	isel :			std_logic;		-- device selected

	type 		typStates	is (Idle, Addr, Read, Write, WrtEnd);
	signal	State :	typStates;

begin

---------------------------------------------------------
--	Interconnections
---------------------------------------------------------
	ram_oen	<= not(isel and not(WE_I));
	ram_wen	<= not(iwp);
	ram_csn	<= not(ics) when iwe = '1' else not(isel); 
	ram_ben	<= not(ibe) when iwe = '1' else not(SEL_I);
	ram_adr	<= iadr when iwe = '1' else ADR_I;
--	ACK_O		<= iack when isel = '1' and WE_I = '0' else isel;
	ACK_O		<= iack and isel;

	DAT_O		<= ram_dat;
	
-- Selection
ramsel : process(SEL_I, CYC_I, STB_I)
	variable	vsel :	std_logic;
	begin
		vsel	:= '0';
		for ndx in SEL_I'RANGE loop
			vsel			:= vsel or SEL_I(ndx);
		end loop;
		isel		<= vsel and CYC_I and STB_I;
	end process;

-- Write Selection
wrram : process(RST_I, CLK_I)
	begin
		if CLK_I'EVENT and CLK_I = '1' then
			if RST_I = '1' then
				State		<= Idle;
				idat		<= (others => '0');
				iadr		<= (others => '0');
				ibe			<= (others => '0');
				iack		<= '0';
				iwe			<= '0';
				ioe			<= '0';
				ics			<= '0';
				iwp			<= '0';
			else
				for idx in SEL_I'RANGE loop
					ibe(idx)	<= SEL_I(idx) and STB_I and CYC_I;
				end loop;
				iadr		<= ADR_I;
				idat		<= DAT_I;
--				iack		<= isel and not(WE_I);
				ioe			<= isel and not(WE_I);
				iwe			<= isel and WE_I;
				ics			<= isel;
				
				-- read / write state machine
				case State is
					when Idle =>
						if isel = '1' and WE_I = '1' then
							iwp			<= '1';
							iack		<= '1';
							State		<= Write;
						elsif isel = '1' and WE_I = '0'then
							iack		<= '1';
							State		<= Read;
						else
							State		<= Idle;
						end if;
						
					when Read =>
						iack		<= '0';
						State		<= Idle;
						
					when Write =>
						iack		<= '0';
						iwp			<= '0';
						State		<= WrtEnd;
						
					when WrtEnd =>
						State		<= Idle;
					
					when Others =>
				end case;
			end if;
		end if;
	end process;

-- Data Bus Control
dbc : process(idat, iwe)
	begin
		if iwe = '1' then
			ram_dat	<= idat;
		else
			ram_dat	<= (others => 'Z');
		end if;
	end process;

end bhv_wb_ram;
	
