use IEEE.STD_LOGIC_1164.ALL;
library IEEE;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity Eand is
    port(
        L : in std_logic;
        R : in std_logic;
        Y : out std_logic
    );
end Eand;

architecture abstract of Eand is
begin
    calculation : process(L, R)
    begin
        Y <= L and R;
    end process calculation;
end architecture abstract;