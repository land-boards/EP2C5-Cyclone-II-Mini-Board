--===========================================================================--
--
--  S Y N T H E Z I A B L E    miniUART   C O R E
--
--  www.OpenCores.Org - January 2000
--  This core adheres to the GNU public license  
--
-- Design units   : UART_Def
--
-- File name      : uart_lib.vhd
--
-- Purpose        : Implements an miniUART device for communication purposes 
--                  between the OR1K processor and the Host computer through
--                  an RS-232 communication protocol.
--                  
-- Library        : uart_lib.vhd
--
-- Dependencies   : IEEE.Std_Logic_1164
--
--===========================================================================--
-------------------------------------------------------------------------------
-- Revision list
-- Version   Author                 Date                        Changes
--
-- 0.1      Ovidiu Lupas     15 January 2000                   New model
--        olupas@opencores.org
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------- 
-- package UART_Def
-------------------------------------------------------------------------------- 
library IEEE;
use IEEE.Std_Logic_1164.all;
use IEEE.Numeric_Std.all;
--**--
package UART_Def is
      -----------------------------------------------------------------------------
      -- Converts unsigned Std_LOGIC_Vector to Integer, leftmost bit is MSB
      -- Error message for unknowns (U, X, W, Z, -), converted to 0
      -- Verifies whether vector is too long (> 16 bits)
      -----------------------------------------------------------------------------
      function  ToInteger (
         Invector : in  Unsigned(3 downto 0))
       return     Integer;
end UART_Def; --==================== End of package header ======================--
package body UART_Def is
  function  ToInteger (
       InVector : in Unsigned(3 downto 0))
      return  Integer is
    variable Result       : Integer         := 0;
    constant HeaderMsg   : String          := "To_Integer:";
    constant MsgSeverity : Severity_Level  := Warning;
  begin
    for i in 0 to 3 loop
      if (InVector(i) = '1') then
         Result := Result + (2**I);
      end if;
    end loop;
    return Result;
  end ToInteger;
end UART_Def; --================ End of package body ================--


