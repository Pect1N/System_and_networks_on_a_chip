-- читает и пишет одновременно
library IEEE;
use ieee.numeric_std.all;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity place is
    generic(
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

        permissions : out std_logic_vector(INTERFACE_NUM - 1 downto 0)
    );
end entity place;

architecture rtl of place is
    type mas is array(integer range <>) of integer;
    type mem is array (integer range<>) of std_logic_vector(DATA_WIDTH - 1 downto 0);
    constant  zero : std_logic_vector (DATA_WIDTH - 1 downto 0)  := "00000000";
    constant  max_limit : std_logic_vector (DATA_WIDTH - 1 downto 0)  := "11111111";
    constant  add : std_logic_vector (DATA_WIDTH - 1 downto 0)  := "00000001";
    constant  decr_op : std_logic_vector (2 downto 0)  := "000"; -- 0
    constant  not_op  : std_logic_vector (2 downto 0)  := "001"; -- 1
    constant  add_fop : std_logic_vector (2 downto 0)  := "010"; -- 2
    constant  mult_op : std_logic_vector (2 downto 0)  := "011"; -- 3
    constant  add_sop : std_logic_vector (2 downto 0)  := "100"; -- 4
    constant  rol_op  : std_logic_vector (2 downto 0)  := "101"; -- 5
begin
    main : process(clk, rst)
        constant max_prior : integer := 5; -- число приоритетов
        variable priorities : mas(0 to INTERFACE_NUM - 1) := (
            0 => 0,
            1 => 1,
            2 => 2,
            3 => 3,
            4 => 4
        );
        variable tmp1 : std_logic_vector (DATA_WIDTH - 1 downto 0);
        variable validMEM_bus_map : std_logic_vector(INTERFACE_NUM - 1 downto 0);
        variable readyMEM_bus_map :  std_logic_vector(INTERFACE_NUM - 1 downto 0);
        variable result : std_logic_vector(INTERFACE_NUM * DATA_WIDTH - 1 downto 0);
        
        variable last_device : mas(0 to max_prior - 1) := (others => 0);
        variable flag : boolean;
        variable current_device : integer;
        
    begin
        if rst = '1' then
            ansver <= (others => '0');
            result := (others => '0');
            validMEM_bus <= (others => '0');
            validMEM_bus_map := (others => '0'); 
            readyMEM_bus_map := (others => '1');
            readyMEM_bus <= (others => '1');
        elsif rising_edge(clk) then
            --permissions <= STD_LOGIC_VECTOR(to_unsigned(0, INTERFACE_NUM));
            flag := false;
            current_device := -1;
            for i in 0 to INTERFACE_NUM - 1 loop
                if validMEM_bus_map(i) = '1' then
                    permissions(i) <= '0';
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
            if current_device /= -1 then
                permissions(current_device) <= '1';
            end if;
            -- last_device(priorities(current_device)) := current_device;
            
            for i in 0 to INTERFACE_NUM - 1 loop
                if validMEM_bus_map(i) = '1' and readyDMA_bus(i) = '1' then
                    validMEM_bus_map(i) := '0';
                    readyMEM_bus_map(i) := '1';
                end if;
            end loop;

            for i in 0 to INTERFACE_NUM - 1 loop
                if validDMA_bus(i) = '1' and readyMEM_bus_map(i) = '1'  then
                    readyMEM_bus_map(i) := '0';
                    -- если пишем
                    if control_bus(i) = '1' then
                        readyMEM_bus_map(i) := '1';
                        if current_device = i then
                            -- запись в память
                            ansver <= result((i+1) * DATA_WIDTH - 1 downto i * DATA_WIDTH);
                            -- смена приоритетов
                            for i in 0 to INTERFACE_NUM - 1 loop
                                if priorities(i) = 0 then
                                    priorities(i) := max_prior - 1;
                                else
                                    priorities(i) := priorities(i) - 1;
                                end if;
                            end loop;
                        end if;
                    -- если читаем
                    elsif control_bus(i) = '0' then
                        if operation((i+1) * 3 - 1 downto i * 3) = decr_op then
                            result((i+1) * DATA_WIDTH - 1 downto i * DATA_WIDTH) := arg_1((i+1) * DATA_WIDTH - 1 downto i * DATA_WIDTH) - add;
                        elsif operation((i+1) * 3 - 1 downto i * 3) = not_op then
                            tmp1 := arg_1((i+1) * DATA_WIDTH - 1 downto i * DATA_WIDTH);
                            tmp1(DATA_WIDTH - 1) := not(tmp1(DATA_WIDTH - 1));
                            result((i+1) * DATA_WIDTH - 1 downto i * DATA_WIDTH) := tmp1;
                        elsif operation((i+1) * 3 - 1 downto i * 3) = add_fop then
                            result((i+1) * DATA_WIDTH - 1 downto i * DATA_WIDTH) := arg_1((i+1) * DATA_WIDTH - 1 downto i * DATA_WIDTH) + arg_2((i+1) * DATA_WIDTH - 1 downto i * DATA_WIDTH);
                        elsif operation((i+1) * 3 - 1 downto i * 3) = mult_op then
                            result((i+1) * DATA_WIDTH - 1 downto i * DATA_WIDTH) := arg_1((i+1) * DATA_WIDTH - DATA_WIDTH / 2 - 1 downto i * DATA_WIDTH) * arg_2((i+1) * DATA_WIDTH - DATA_WIDTH / 2 - 1 downto i * DATA_WIDTH);                
                        end if;
                        validMEM_bus_map(i) := '1';
                    end if;
                end if;
            end loop;
            readyMEM_bus <= readyMEM_bus_map;
            validMEM_bus <= validMEM_bus_map;
        end if;
    end process main;
end architecture rtl;
