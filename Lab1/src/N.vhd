library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity Fnot is
    port(
        X : in std_logic;
        Y : out std_logic
    );
end Fnot;

architecture abstract of Fnot is
begin
    calculation : process(X)
    begin
        Y <= not X;
    end process calculation;
end architecture abstract;