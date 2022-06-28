library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity test is
    generic
    (
        TICK : time := 200 fs;
        arg_num : integer := 4
    );
end entity test;

architecture main of test is
    signal test_clk : std_logic := '0';
    signal arguments : std_logic_vector(arg_num - 1 downto 0) := "0000";
    signal answers : std_logic_vector(1 downto 0) := (others => '0');
    signal test_completed : boolean := false;

    component place is
        port
        (
            A : in std_ulogic;
            B : in std_ulogic;
            C : in std_ulogic;
            D : in std_ulogic;
            Y : out std_ulogic
            );
    end component place;
    
    component place2 is
        port
        (
            A : in std_ulogic;
            B : in std_ulogic;
            C : in std_ulogic;
            D : in std_ulogic;
            Y : out std_ulogic
            );
    end component place2;
    
    begin
    funct : place port map (
        A=>arguments(0),
        B=>arguments(1),
        C=>arguments(2),
        D=>arguments(3),
        Y=>answers(0)
    );
    funct2 : place2 port map (
        A=>arguments(0),
        B=>arguments(1),
        C=>arguments(2),
        D=>arguments(3),
        Y=>answers(1)
    );

    clock : process(test_clk)
    begin
        if test_completed = false then
            if test_clk = '1' then
                test_clk <= '0' after TICK;
            else
                test_clk <= '1' after TICK;
            end if;
        end if;
    end process clock;

    test_iterator : process(test_clk)
    begin
        if rising_edge(test_clk) then
            arguments <= arguments + "0001";
            if arguments = "1111" then
                test_completed <= true;
            end if;
        end if;
    end process test_iterator;
end architecture main;