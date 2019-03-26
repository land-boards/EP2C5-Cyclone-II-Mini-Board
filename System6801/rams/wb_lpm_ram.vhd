--===========================================================================--
--
--  S Y N T H E Z I A B L E    Altera LPM_RAM / WISHBONE interface
--
--  www.OpenCores.Org - January 2004
--  This core adheres to the GNU public license
--
-- File name      : wb_lpm_ram.vhd
--
-- Purpose        : Implements a WISHBONE compatble interface
--                  for the Altera LPM_ROM
--
-- Dependencies   : ieee.Std_Logic_1164
--                  work.std_logic_arith
--									work.lpm_components (Altera's 220PACK.vhd)
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
-- 5 Aug 2003     0.2              Michael L. Hasenfratz Sr.
--      Added Cache check
-- 20 Dec 2003    0.2              Michael L. Hasenfratz Sr.
--      Improved 'Sync RAM' performance
-- 19 Jan 2004    0.3              Michael L. Hasenfratz Sr.
--      Added CYC_I to 'WE' equation to prevent improper write
--

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

library lpm;
use lpm.lpm_components.all;

entity wb_lpm_ram is
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
end wb_lpm_ram;

architecture bhv_wb_lpm_ram of wb_lpm_ram is

	signal	iwe :				std_logic_vector(SEL_I'RANGE);	-- Internal Write Enables
	signal	iack :			std_logic;		-- Internal ACK
	signal	nadr :			std_logic_vector(ADR_I'RANGE);
	signal	iadr :			std_logic_vector(ADR_I'RANGE);
	signal	ladr :			std_logic_vector(ADR_I'RANGE);

begin

---------------------------------------------------------
--	Instantiate the RAM interface
---------------------------------------------------------
gen : for idx in SEL_I'RANGE generate
ram :	LPM_RAM_DQ
		generic map (
			LPM_WIDTH		=> 8,
			LPM_WIDTHAD	=> LPM_WIDTHAD,
      USE_EAB  => "ON",
	    LPM_OUTDATA => "UNREGISTERED",
	    INTENDED_DEVICE_FAMILY	=> LPM_FAMILY
		)
		port map (
		  DATA		=> DAT_I((idx*8)+7 downto (idx*8)),
		  Q				=> DAT_O((idx*8)+7 downto (idx*8)),
		  WE      => iwe(idx),
			ADDRESS	=> iadr,
			INCLOCK	=> CLK_I
		);
	end generate;

---------------------------------------------------------
--	Interconnections
---------------------------------------------------------
	-- Address MUX
	iadr	<= nadr when iack = '1' and WE_I = '0' else ADR_I;

	-- Internal ACK true when Latch Address = CPU Address
	iack	<= '1' when ladr = ADR_I else '0';

-- Selection
romsel : process(SEL_I, CYC_I, STB_I, WE_I, iack)
	variable	vsel :	std_logic;
	begin
		vsel	:= '0';
		for ndx in SEL_I'RANGE loop
			vsel			:= vsel or SEL_I(ndx);
			iwe(ndx)	<= WE_I and SEL_I(ndx) and CYC_I;
		end loop;
		ACK_O		<= vsel and (iack or WE_I) and CYC_I and STB_I;
	end process;

-- Read Acknowledge
rdack : process(RST_I, CLK_I)
	begin
		if CLK_I'EVENT and CLK_I = '1' then
			if RST_I = '1' then
				nadr	<= (others => '0');
				ladr	<= (others => '0');
			else
				if iack = '1' then
					nadr	<= nadr + "1";
				else
					nadr	<= ADR_I + "1";
				end if;

				ladr	<= iadr;

			end if;
		end if;
	end process;

end bhv_wb_lpm_ram;

