library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity Blink1 is
	Port (PB : in STD_LOGIC;
		LED0 : out STD_LOGIC;
		LED1 : out STD_LOGIC;
		LED2 : out STD_LOGIC);
end Blink1;

architecture Behavioral of Blink1 is
begin
	LED0 <= PB;
	LED1 <= not PB;
	LED2 <= PB;
end behavioral;
