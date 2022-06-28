library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity place2 is
    port(
        A : in std_logic;
        B : in std_logic;
        C : in std_logic;
        D : in std_logic;
        Y : out std_logic
    );
end entity place2;

architecture doing2 of place2 is

    component Fnot is
        port(
            X : in std_logic;
            Y : out std_logic
        );
    end component Fnot;

    component Eand is
        port(
            L : in std_logic;
            R : in std_logic;
            Y : out std_logic
        );
    end component Eand;

    component Gor is
        port(
            L : in std_logic;
            R : in std_logic;
            Y : out std_logic
        );
    end component Gor;

    signal s1, s2, s3, s4 : std_logic;

begin
    l1 : Gor port map (
        L => C,
        R => D,
        Y => s1
    );
    l2 : Fnot port map (X => s1, Y => s2);
    l3 : Gor port map (L => A, R => B, Y => s3);
    l4 : Eand port map (L => s3, R => s2, Y => Y);
end architecture doing2;