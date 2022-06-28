library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity Gor is
    port(
        L : in std_logic;
        R : in std_logic;
        Y : out std_logic
    );
end Gor;

architecture abstract of Gor is
begin
    calculation : process(L, R)
    begin
        Y <= L or R;
    end process calculation;
end architecture abstract;