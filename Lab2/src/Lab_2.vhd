library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

entity arbitr is
    generic (
        devices : integer := 6
    );
    port(
        clk : in std_logic;
        requests : in std_logic_vector(devices - 1 downto 0);
        permissions : out std_logic_vector(devices - 1 downto 0)
    );
end entity arbitr;

architecture main of arbitr is
type mas is array(integer range <>) of integer;
begin
    main : process(clk)
        constant max_prior : integer := 5; -- число приоритетов
        --связь приоритетов и устройств
        constant priorities : mas(0 to devices - 1) := (
            0 => 1,
            1 => 1,
            2 => 3,
            3 => 1,
            4 => 1,
            5 => 2
        );
        --номер последнего устройства в приоритете
        variable last_device : mas(0 to max_prior - 1) := (others => 0);
        variable flag : boolean;
        variable current_device : integer;

    begin
        --чистим выбор
        if rising_edge(clk) then
            permissions <= STD_LOGIC_VECTOR(to_unsigned(0, DEVICES));
            flag := false;
            current_device := 0;
            --выбор устройства
            for i in 0 to devices - 1 loop
                if requests(i) = '1' then
                    if flag = false then
                        flag := true;
                        current_device := i;
                    elsif priorities(i) < priorities(current_device) then
                        current_device := i;
                    elsif priorities(i) = priorities(current_device) then
                        if last_device(priorities(i)) /= i then
                            current_device := i;
                        end if ;
                    end if;
                end if;
            end loop;
            
            permissions(current_device) <= '1';
            last_device(priorities(current_device)) := current_device;
        end if;
    end process main;
end main;