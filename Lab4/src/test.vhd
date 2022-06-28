library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity test is
    generic
    (
        TICK   : time := 200 fs;
        length : integer := 8;
        zero : std_logic_vector (7 downto 0)  := "00000000";
        max_limit : std_logic_vector (7 downto 0)  := "11111111";
        add : std_logic_vector (7 downto 0)  := "00000001"
    );
end entity test;

architecture main of test is
    signal clk : std_logic := '0';
    signal rst : std_logic := '0';
    signal test_completed : boolean := false;
    signal arguments1     : std_logic_vector(length - 1 downto 0) := zero;
    signal arguments2     : std_logic_vector(length - 1 downto 0) := zero;
    signal operation      : std_logic_vector(2 downto 0) := "000";
    signal answers        : std_logic_vector(length - 1 downto 0) := zero;
    signal overflow       : std_logic := '0';

    component place is
        port
        (
            clk : in std_logic;
            rst : in std_logic;
            A1 : in std_logic_vector(length - 1 downto 0);
            A2 : in std_logic_vector(length - 1 downto 0);
            O  : in std_logic_vector(2 downto 0);
            Y  : out std_logic_vector(length - 1 downto 0);
            Overflow : out std_logic
        );
    end component place;
    
    begin
    funct : place port map (
        clk => clk,
        rst => rst,
        A1 => arguments1,
        A2 => arguments2,
        Y => answers,
        O => operation,
        Overflow => overflow
    );

    clock : process(clk)
    begin
        if test_completed = false then
            if rst = '1' then
                clk <= '0';
            elsif clk = '1' then
                clk <= '0' after TICK;
            else
                clk <= '1' after TICK;
            end if;
        end if;
    end process clock;

    reset: process
    begin
        rst <= '1', '0' after TICK;
        wait;
    end process reset;

    test_iterator : process(clk)
    begin
        if rising_edge(clk) then
            operation <= operation + "001";
            if operation = "101" then
                operation <= "000";
                arguments1 <= arguments1 + add;
                if arguments1 = max_limit then
                    arguments2 <= arguments2 + add;
                    arguments1 <= zero;
                    if arguments2 = max_limit then
                        test_completed <= true;
                    end if;
                end if;
            end if;
        end if;
    end process test_iterator;
end architecture main;