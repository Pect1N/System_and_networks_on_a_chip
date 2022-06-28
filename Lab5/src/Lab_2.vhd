library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

entity arbitr is
    generic (
        DATA_WIDTH : integer := 8; 
        ADDRESS_WIDTH : integer := 8;
        INTERFACE_NUM : integer := 5
    );
    port(
        clk : in std_logic;
        rst : in std_logic;
        adr_1 : in std_logic_vector(INTERFACE_NUM * ADDRESS_WIDTH - 1 downto 0);
        adr_2 : in std_logic_vector(INTERFACE_NUM * ADDRESS_WIDTH - 1 downto 0);
        arg_1 : in std_logic_vector(INTERFACE_NUM * DATA_WIDTH - 1 downto 0);
        arg_2 : in std_logic_vector(INTERFACE_NUM * DATA_WIDTH - 1 downto 0);
        operation : in std_logic_vector(INTERFACE_NUM * 3 - 1 downto 0);

        ansver : out std_logic_vector(DATA_WIDTH - 1 downto 0);
        control_bus : in std_logic_vector(INTERFACE_NUM - 1 downto 0);
        validMEM_bus : out std_logic_vector(INTERFACE_NUM - 1 downto 0);
        validDMA_bus : in std_logic_vector(INTERFACE_NUM - 1 downto 0);
        readyMEM_bus : out std_logic_vector(INTERFACE_NUM - 1 downto 0);
        readyDMA_bus : in std_logic_vector(INTERFACE_NUM - 1 downto 0);
        
        requests : in std_logic_vector(INTERFACE_NUM - 1 downto 0)
        permissions : out std_logic_vector(INTERFACE_NUM - 1 downto 0);
    );
end entity arbitr;

architecture main of arbitr is
type mas is array(integer range <>) of integer;
begin
    main : process(clk)
        constant max_prior : integer := 5; -- число приоритетов
        --связь приоритетов и устройств
        constant priorities : mas(0 to INTERFACE_NUM - 1) := (
            0 => 1,
            1 => 1,
            2 => 3,
            3 => 1,
            4 => 2
        );
        --номер последнего устройства в приоритете
        variable last_device : mas(0 to max_prior - 1) := (others => 0);
        variable flag : boolean;
        variable current_device : integer;

    begin
        --чистим выбор
        if rising_edge(clk) then
            permissions <= STD_LOGIC_VECTOR(to_unsigned(0, INTERFACE_NUM));
            flag := false;
            current_device := 0;
            --выбор устройства
            for i in 0 to INTERFACE_NUM - 1 loop
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