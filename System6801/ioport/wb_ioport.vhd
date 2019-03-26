--===========================================================================--
--
--  S Y N T H E Z I A B L E    I/O Port (PIO) / WISHBONE interface
--
--  www.OpenCores.Org - August 2003
--  This core adheres to the GNU public license  
--
-- File name      : wb_ioport.vhd
--
-- Purpose        : Implements a WISHBONE compatble interface
--                  for a Programmable I/O port register set
--
-- Dependencies   : ieee.Std_Logic_1164
--                  ieee.std_logic_unsigned
--                  ieee.std_logic_arith
--
-- Author         : Michael L. Hasenfratz Sr.
--
--===========================================================================----
--
-- Revision History:
--
-- Date:          Revision         Author
--===========================================================================--
-- 9 Sep 2003	    0.1              Michael L. Hasenfratz Sr. mikehsr@opencores.org
--      Created
--

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;

--library work;
--use work.std_logic_arith.all;

entity wb_ioport is
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
end;

architecture bhv_wb_ioport of wb_ioport is

-----------------------------------------------------------------
--
-- Open Cores Programmable I/O Port
--
-----------------------------------------------------------------

component ioport is
	generic (
		PORT_WIDTH :	positive range 1 to 63 := 8
	);
	port (	
		clk       : in		std_logic;
		rst       : in	  std_logic;
		cs        : in	  std_logic;
		rw        : in	  std_logic;
		sel       : in	  std_logic;
		data_in   : in	  std_logic_vector(PORT_WIDTH-1 downto 0);
		data_out  : out		std_logic_vector(PORT_WIDTH-1 downto 0);
		port_io   : inout	std_logic_vector(PORT_WIDTH-1 downto 0)
	);
end component;

	signal	irw :			std_logic;		-- internal Read/Write*
	signal	iack :		std_logic;		-- internal ACK
	signal	isel :		std_logic;		-- internal Reister Select
	signal	ics :			std_logic_vector(3 downto 0);		-- internal Chip Select
	signal	DAT0_O :	std_logic_vector(7 downto 0);		-- internal Data Out
	signal	DAT1_O :	std_logic_vector(7 downto 0);		-- internal Data Out
	signal	DAT2_O :	std_logic_vector(7 downto 0);		-- internal Data Out
	signal	DAT3_O :	std_logic_vector(7 downto 0);		-- internal Data Out
	
begin

portx0  : ioport 
	generic map (
		PORT_WIDTH	=> 8
	)
	port map (
   clk       => CLK_I,
	 rst       => RST_I,
   cs        => ics(0),
	 rw        => irw,
   sel       => isel,
	 data_in   => DAT_I,
	 data_out  => DAT0_O,
	 port_io   => PORT0_IO
	);

portx1  : ioport 
	generic map (
		PORT_WIDTH	=> 8
	)
	port map (
   clk       => CLK_I,
	 rst       => RST_I,
   cs        => ics(1),
	 rw        => irw,
   sel       => isel,
	 data_in   => DAT_I,
	 data_out  => DAT1_O,
	 port_io   => PORT1_IO
	 );

portx2  : ioport 
	generic map (
		PORT_WIDTH	=> 8
	)
	port map (
   clk       => CLK_I,
	 rst       => RST_I,
   cs        => ics(2),
	 rw        => irw,
   sel       => isel,
	 data_in   => DAT_I,
	 data_out  => DAT2_O,
	 port_io   => PORT2_IO
	 );

portx3  : ioport 
	generic map (
		PORT_WIDTH	=> 8
	)
	port map (
   clk       => CLK_I,
	 rst       => RST_I,
   cs        => ics(3),
	 rw        => irw,
   sel       => isel,
	 data_in   => DAT_I,
	 data_out  => DAT3_O,
	 port_io   => PORT3_IO
	 );

---------------------------------------------------------
--	Interconnections
---------------------------------------------------------
	irw		<= not(WE_I);		-- invert the Write Enable
	ACK_O	<= STB_I and CYC_I and SEL_I and iack;
	
ackx :	process(CLK_I, RST_I)
	variable	vack :	std_logic;
	begin
		if CLK_I'EVENT and CLK_I = '1' then
			if RST_I = '1' then
				vack	:= '0';
			else
				vack	:= '0';
				for idx in ics'RANGE loop
					vack		:= vack or ics(idx);
				end loop;
			end if;
			iack	<= vack;
		end if;
	end process;
	
iopx : process(DAT0_O, DAT1_O, DAT2_O, DAT3_O, ics)
	begin
		case ics is
			when "1000" => DAT_O	<= DAT3_O;
			when "0100" => DAT_O	<= DAT2_O;
			when "0010" => DAT_O	<= DAT1_O;
			when "0001" => DAT_O	<= DAT0_O;
			when others => DAT_O	<= (others => '0');
		end case;
	end process;
				
selx : process(ADR_I, CYC_I, STB_I)
	begin
		if CYC_I = '1' and STB_I = '1' then
			case ADR_I is
				when "000" => ics <= "0001"; isel <= '0';	-- DDR 0
				when "001" => ics <= "0010"; isel <= '0';	-- DDR 1
				when "010" => ics <= "0001"; isel <= '1';	-- DATA 0
				when "011" => ics <= "0010"; isel <= '1';	-- DATA 1
				when "100" => ics <= "0100"; isel <= '0';	-- DDR 2
				when "101" => ics <= "1000"; isel <= '0';	-- DDR 3
				when "110" => ics <= "0100"; isel <= '1';	-- DATA 2
				when "111" => ics <= "1000"; isel <= '1';	-- DATA 3
				when others => ics <= "0000"; isel <= '0';
			end case;
		else
			ics		<= "0000";
			isel	<= '0';
		end if;
	end process;
	
end bhv_wb_ioport;
	
