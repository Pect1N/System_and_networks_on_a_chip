library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

entity test is
	generic
	(
		TICK : time := 200 fs
	);
end entity test;

architecture lab of test is
    constant devices : integer := 6;
    signal clk : std_logic := '0';
    signal tests_completed : boolean := false;
    signal requests : std_logic_vector(devices - 1 downto 0) := (others => '0');
    signal permissions : std_logic_vector(devices - 1 downto 0);

    component arbitr is
        generic(
           devices : integer 
        );
        port(
            clk : in std_logic;
            requests : in std_logic_vector(devices - 1 downto 0);
            permissions : out std_logic_vector(devices - 1 downto 0)
        );
    end component;

begin
    arbiter_port : arbitr
    generic map (devices => devices)
    port map(
        clk => clk,
        requests => requests,
        permissions => permissions
    );

    --Тактовый генератор
    clock:process(clk)
    begin 
        if tests_completed = false then 
            if clk = '1' then
                clk <= '0' after TICK;
            else
                clk <= '1' after TICK;
            end if;
        end if;
    end process clock;
    
    --Перебор элементов
    test_iterator: process(clk)
	begin
		if rising_edge(clk) then
            requests <= requests + "000001";
            if requests = "111111" then
                tests_completed <= true;
            end if;
        end if;
	end process test_iterator;
end lab;