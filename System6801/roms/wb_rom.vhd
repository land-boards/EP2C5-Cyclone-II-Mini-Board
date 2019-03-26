--===========================================================================--
--
--  S Y N T H E Z I A B L E    ROM / WISHBONE interface
--
--  www.OpenCores.Org - August 2003
--  This core adheres to the GNU public license  
--
-- File name      : wb_rom.vhd
--
-- Purpose        : Implements a WISHBONE compatble interface
--                  for an External ROM
--
-- Dependencies   : ieee.Std_Logic_1164
--                  ieee.std_logic_unsigned
--									work.std_logic_arith (MTI's mti_std_logic_arith.vhd)
--
-- Author         : Michael L. Hasenfratz Sr.
--
--===========================================================================----
--
-- Revision History:
--
-- Date:          Revision         Author
--===========================================================================--
-- 5 Aug 2003	    0.1              Michael L. Hasenfratz Sr.
--      Created
--

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;

entity wb_rom is
	generic (
		ROM_WIDTH	:		positive	range 1 to 64 := 8;				-- data bits WIDE
		ROM_WIDTHAD :	positive	range 1 to 32	:= 8				-- address bits;
	);
	port (	
	  DAT_O :      out std_logic_vector(ROM_WIDTH-1 downto 0);
		ADR_I :      in  std_logic_vector(ROM_WIDTHAD-1 downto 0);
		SEL_I :      in  std_logic_vector((ROM_WIDTH/8)-1 downto 0);
		STB_I :	     in  std_logic;		-- VMA (Valid Memory Access)
		CYC_I :	     in  std_logic;		-- CYC in progress
		ACK_O :      out std_logic;		-- Data ready
		
		rom_adr :    out std_logic_vector(ROM_WIDTHAD-1 downto 0);
	  rom_dat :    in  std_logic_vector(ROM_WIDTH-1 downto 0);
	  rom_csn :    out std_logic;		-- ROM Chip Select
	  rom_oen :    out std_logic		-- ROM Output Enable
	);
end;

architecture bhv_wb_rom of wb_rom is

	signal	sel :			std_logic;		-- internal SELECT

begin

---------------------------------------------------------
--	Interconnections
---------------------------------------------------------
sel0 :	process(SEL_I, CYC_I, STB_I)
	variable	isel :		std_logic;
	begin
		isel	:= '0';		-- reset 'or'
		-- look for ANY selects
		for idx in SEL_I'RANGE loop
			isel	:= isel or SEL_I(idx);
		end loop;
		sel		<= isel and CYC_I;
	end process;
	
	rom_adr	<= ADR_I;
	rom_csn	<= not(sel);
	rom_oen	<= not(sel) and STB_I;
	
	DAT_O		<= rom_dat;
	ACK_O		<= sel and STB_I;
	
end bhv_wb_rom;
	
