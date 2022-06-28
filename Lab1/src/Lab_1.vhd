library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity place is
    port(
        A : in std_logic;
        B : in std_logic;
        C : in std_logic;
        D : in std_logic;
        Y : out std_logic
    );
end entity place;

architecture doing of place is
begin
    calculation: process(A, B, C, D)
    begin
        Y <= (A or B) and (not (C or D));
    end process calculation;
end architecture doing;