library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

entity test is
    generic
    (
        TICK : time := 200 fs
    );
end test;

architecture main of test is
    constant DATA_WIDTH : integer := 8;
    constant ADDRESS_WIDTH : integer := 8;
    constant INTERFACE_NUM : integer := 5;
    component place is
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
    end component place;

    type mas is array(integer range <>) of integer;
    signal clk : std_logic := '0';
    signal rst : std_logic := '0';
    signal adr_1 : std_logic_vector(INTERFACE_NUM * ADDRESS_WIDTH - 1 downto 0) := (others => '0');
    signal adr_2 : std_logic_vector(INTERFACE_NUM * ADDRESS_WIDTH - 1 downto 0) := (others => '0');
    signal arg_1 : std_logic_vector(INTERFACE_NUM * DATA_WIDTH - 1 downto 0) := (others => '0');
    signal arg_2 : std_logic_vector(INTERFACE_NUM * DATA_WIDTH - 1 downto 0) := (others => '0');
    signal operation : std_logic_vector(INTERFACE_NUM * 3 - 1 downto 0) := (others => '0');
    signal ansver : std_logic_vector(DATA_WIDTH - 1 downto 0) := (others => '0');
    signal control_bus : std_logic_vector(INTERFACE_NUM - 1 downto 0) := (others => '0');
    signal validDMA_bus : std_logic_vector(INTERFACE_NUM - 1 downto 0) := (others => '0');
    signal readyMEM_bus : std_logic_vector(INTERFACE_NUM - 1 downto 0) := (others => '0');
    signal validMEM_bus : std_logic_vector(INTERFACE_NUM - 1 downto 0) := (others => '0');
    signal readyDMA_bus : std_logic_vector(INTERFACE_NUM - 1 downto 0) := (others => '0');
    signal testCompleted : boolean := false;
    signal position : mas(0 to INTERFACE_NUM - 1) := (
        0 => 0,
        1 => 0,
        2 => 0,
        3 => 0,
        4 => 0
        );
    signal permissions : std_logic_vector(INTERFACE_NUM - 1 downto 0);

    begin
        funct : place
        generic map(
            DATA_WIDTH => DATA_WIDTH,
            ADDRESS_WIDTH => ADDRESS_WIDTH, 
            INTERFACE_NUM => INTERFACE_NUM
        ) 
        port map (
            clk => clk,
            rst => rst,
            adr_1 => adr_1,
            adr_2 => adr_2,
            arg_1 => arg_1,
            arg_2 => arg_2,
            ansver => ansver,
            control_bus => control_bus,
            validDMA_bus => validDMA_bus,
            readyMEM_bus => readyMEM_bus,
            validMEM_bus => validMEM_bus,
            readyDMA_bus => readyDMA_bus,
            operation => operation,
            permissions => permissions
        );

        reset: process
        begin
            rst <= '1', '0' after 2 * TICK;
            wait;
        end process reset;

        clock: process(clk, rst)
        begin
            if testCompleted = false then
                if rst = '1' then
                    clk <= '0';
                elsif rising_edge(clk) then
                    clk <= '0' after TICK;
                else
                    clk <= '1' after TICK;
                end if;
            end if;
        end process clock;

        memory : process(clk, rst)
            type mem is array (integer range<>) of std_logic_vector(DATA_WIDTH - 1 downto 0);
            variable test_mem : mem(2**ADDRESS_WIDTH - 1 downto 0);
            type STAGE is (WR, RD, WAIT_ST);
            type STAGE_ARRAY is array (integer range <>) of STAGE;
            variable int_stage : STAGE_ARRAY(0 to INTERFACE_NUM -1);
            variable validDMA_bus_map : std_logic_vector(INTERFACE_NUM - 1 downto 0) := (others => '0');
            variable oper : std_logic_vector(INTERFACE_NUM * 3 - 1 downto 0) := "010011010001000";

        begin
            if rst = '1' then
                readyDMA_bus <= (others =>'1');
                int_stage := (others => RD);
                -- operation(INTERFACE_NUM * 3 - 1 downto 0) <= "100011010001000";
                for i in 0 to INTERFACE_NUM - 1 loop
                    operation((i+1) * 3 - 1 downto i * 3) <= oper((i+1) * 3 - 1 downto i * 3);
                    position(i) <= 0;
                end loop;
                for i in 0 to INTERFACE_NUM - 1 loop
                    arg_1 <= (others => '1');
                    arg_2 <= (others => '1');
                    adr_1((i+1) * ADDRESS_WIDTH - 1 downto i * ADDRESS_WIDTH) <= std_logic_vector(to_unsigned(position(i), ADDRESS_WIDTH));
                    adr_2((i+1) * ADDRESS_WIDTH - 1 downto i * ADDRESS_WIDTH) <= std_logic_vector(to_unsigned(2**ADDRESS_WIDTH - 1 - position(i), ADDRESS_WIDTH));
                end loop;
                for i in 0 to 2**ADDRESS_WIDTH - 1 loop
                    test_mem(i) := std_logic_vector(to_unsigned(i mod 10, ADDRESS_WIDTH));
                end loop;
                validDMA_bus_map := (others => '0');
            elsif rising_edge(clk) then
                for i in 0 to INTERFACE_NUM - 1 loop
                    if validDMA_bus_map(i)= '1' and readyMEM_bus(i) = '1' then
                        validDMA_bus_map(i) := '0';
                    end if;
                    if int_stage(i) = WAIT_ST then
                        int_stage(i) := WR;
                    end if;

                    case int_stage(i) is
                        when WR =>
                            if validDMA_bus_map(i) = '0' then
                                adr_1((i+1) * ADDRESS_WIDTH - 1 downto i * ADDRESS_WIDTH) <= std_logic_vector(to_unsigned(position(i), ADDRESS_WIDTH));
                                control_bus(i) <= '1';
                                validDMA_bus_map(i) := '1';
                                int_stage(i) := RD;
                                if position(i) /= 2**ADDRESS_WIDTH - 1 and permissions(i) = '1' then
                                    position(i) <= position(i) + 1;
                                end if;
                            end if;
                        when RD =>
                            if validDMA_bus_map(i)= '0' then
                                validDMA_bus_map(i):='1';
                                adr_1((i+1) * DATA_WIDTH - 1 downto i * DATA_WIDTH) <= std_logic_vector(to_unsigned(position(i), ADDRESS_WIDTH));
                                arg_1((i+1) * DATA_WIDTH - 1 downto i * DATA_WIDTH) <= test_mem(to_integer(unsigned(adr_1((i+1) * DATA_WIDTH - 1 downto i * DATA_WIDTH))));
                                adr_2((i+1) * DATA_WIDTH - 1 downto i * DATA_WIDTH) <= std_logic_vector(to_unsigned(2**ADDRESS_WIDTH - 1 - position(i), ADDRESS_WIDTH));
                                arg_2((i+1) * DATA_WIDTH - 1 downto i * DATA_WIDTH) <= test_mem(to_integer(unsigned(adr_2((i+1) * DATA_WIDTH - 1 downto i * DATA_WIDTH))));
                                control_bus(i) <= '0';
                                int_stage(i) := WAIT_ST;
                            end if;
                        when others =>
                            NULL;
                    end case;
                end loop;
                testCompleted <= true;
                for i in 0 to INTERFACE_NUM - 1 loop
                    if position(i) /= 2**ADDRESS_WIDTH - 1 then
                        testCompleted <= false;
                    end if;
                end loop;
                validDMA_bus <= validDMA_bus_map;
            end if;
        end process memory;
end architecture main;
