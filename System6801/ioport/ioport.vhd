--===========================================================================--
--
--  S Y N T H E Z I A B L E    Programmable I/O Port   C O R E
--
--  www.OpenCores.Org - September 2003
--  This core adheres to the GNU public license  
--
-- File name      : ioport.vhd
--
-- Purpose        : Implements a 6801 compatible I/O Port core
--                  Based on a CORE by: John E. Kent      
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
-- 02 Sep 2003    0.1              Michael L. Hasenfratz Sr.
--

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity ioport is
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
end;

architecture ioport_arch of ioport is

signal port_ddr :		std_logic_vector(PORT_WIDTH-1 downto 0);
signal port_data :	std_logic_vector(PORT_WIDTH-1 downto 0);

begin

--------------------------------
--
-- read I/O port
--
--------------------------------
ioport_read : process( sel, port_ddr, port_data, port_io )
begin
	if sel = '0' then
		data_out <= port_ddr;
	else
		for idx in 0 to PORT_WIDTH-1 loop
			if port_ddr(idx) = '1' then
				data_out(idx) <= port_data(idx);
			else
				data_out(idx) <= port_io(idx);
			end if;
		end loop;
	end if;
end process;

---------------------------------
--
-- Write I/O ports
--
---------------------------------
ioport_write : process( clk, rst, sel, cs, rw, data_in, port_data, port_ddr )
begin
  if rst = '1' then
      port_data <= (others => '0');
      port_ddr  <= (others => '0');
  elsif clk'event and clk = '1' then
    if cs = '1' and rw = '0' then
    	if sel = '0' then
		    port_data <= port_data;
		    port_ddr  <= data_in;
			else
		    port_data <= data_in;
		    port_ddr  <= port_ddr;
			end if;
		else
		  port_data <= port_data;
	    port_ddr  <= port_ddr;
		end if;
  end if;
end process;

---------------------------------
--
-- direction control port
--
---------------------------------
port_direction : process ( port_data, port_ddr )
begin
  for idx in 0 to PORT_WIDTH-1 loop
    if port_ddr(idx) = '1' then
      port_io(idx) <= port_data(idx);
    else
      port_io(idx) <= 'Z';
    end if;
  end loop;
end process;

end ioport_arch;
