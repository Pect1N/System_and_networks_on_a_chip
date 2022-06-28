library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity memory is
    generic
    (
        DATA_WIDTH : integer := 32; 
        ADDRESS_WIDTH : integer := 8; 
        INTERFACE_NUM : integer := 5
    );
    port (
        clk : in std_logic;
        rst : in std_logic;
        data_in_bus  : in std_logic_vector(INTERFACE_NUM * DATA_WIDTH - 1 downto 0); 
        data_out_bus : out std_logic_vector(INTERFACE_NUM * DATA_WIDTH - 1 downto 0); 
        address_bus  : in std_logic_vector(INTERFACE_NUM * ADDRESS_WIDTH - 1 downto 0); 
        control_bus  : in std_logic_vector(INTERFACE_NUM - 1 downto 0);
        readyDMA_bus : in std_logic_vector(INTERFACE_NUM - 1 downto 0);
        validDMA_bus : in std_logic_vector(INTERFACE_NUM - 1 downto 0);
        readyMEM_bus : out std_logic_vector(INTERFACE_NUM - 1 downto 0);
        validMEM_bus : out std_logic_vector(INTERFACE_NUM - 1 downto 0)
    );
end entity memory;

architecture rtl of memory is
    type mem is array (integer range<>) of std_logic_vector(DATA_WIDTH - 1 downto 0);
begin
    
    main: process(clk, rst)
        variable i : integer;
        variable memory_block : mem(2**ADDRESS_WIDTH - 1 downto 0); 
        variable readyMEM_bus_map :  std_logic_vector(INTERFACE_NUM - 1 downto 0);
        variable validMEM_bus_map : std_logic_vector(INTERFACE_NUM - 1 downto 0);
    begin	
        if rst = '1' then 
            readyMEM_bus <= (others => '1');  
            data_out_bus <= (others => '0');
            memory_block := (others => std_logic_vector(to_unsigned(0, DATA_WIDTH)));
            validMEM_bus <= (others => '0');
            readyMEM_bus_map := (others => '1');
            validMEM_bus_map := (others => '0'); 
        elsif rising_edge(clk) then
            clear: for i in 0 to INTERFACE_NUM - 1 loop
                if validMEM_bus_map(i) = '1' and readyDMA_bus(i) = '1' then
                    validMEM_bus_map(i) := '0';
                    readyMEM_bus_map(i) := '1';
                end if;
            end loop clear;


            work: for i in 0 to INTERFACE_NUM - 1 loop
                if validDMA_bus(i) = '1' and readyMEM_bus_map(i) = '1'  then
                    readyMEM_bus_map(i) := '0';
                    if control_bus(i) = '1' then
                        memory_block(to_integer(unsigned(address_bus((i+1) * ADDRESS_WIDTH - 1 downto i * ADDRESS_WIDTH)))) := data_in_bus((i+1) * DATA_WIDTH - 1 downto i * DATA_WIDTH);
                        readyMEM_bus_map(i) := '1';
                    elsif control_bus(i) = '0' then
                        data_out_bus((i+1) * DATA_WIDTH - 1 downto i * DATA_WIDTH) <= memory_block(to_integer(unsigned(address_bus((i+1) * ADDRESS_WIDTH - 1 downto i * ADDRESS_WIDTH))));
                        validMEM_bus_map(i) := '1';
                    end if;
                end if;
            end loop work;

            readyMEM_bus <= readyMEM_bus_map;
            validMEM_bus <= validMEM_bus_map;
        end if;
    end process main;
end architecture rtl;