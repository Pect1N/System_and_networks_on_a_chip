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
    constant DATA_WIDTH : integer := 32;
    constant ADDRESS_WIDTH : integer := 8;
    constant INTERFACE_NUM : integer := 5;
    constant PULSE : time := 2 * TICK; 
    component memory
        generic(
            DATA_WIDTH : integer := 32; 
            ADDRESS_WIDTH : integer := 8; 
            INTERFACE_NUM : integer := 5
        );
        port (
            clk: in std_logic;
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
    end component;

    signal data_in_bus : std_logic_vector(INTERFACE_NUM * DATA_WIDTH - 1 downto 0) := (others => '0');
    signal data_out_bus : std_logic_vector(INTERFACE_NUM * DATA_WIDTH - 1 downto 0) := (others => '0');
    signal address_bus : std_logic_vector(INTERFACE_NUM * ADDRESS_WIDTH - 1 downto 0) := (others => '0');
    signal control_bus : std_logic_vector(INTERFACE_NUM - 1 downto 0) := (others => '0');
    signal validDMA_bus : std_logic_vector(INTERFACE_NUM - 1 downto 0) := (others => '0');
    signal readyMEM_bus : std_logic_vector(INTERFACE_NUM - 1 downto 0) := (others => '0');
    signal validMEM_bus : std_logic_vector(INTERFACE_NUM - 1 downto 0) := (others => '0');
    signal readyDMA_bus : std_logic_vector(INTERFACE_NUM - 1 downto 0) := (others => '0');
	signal clk : std_logic := '0';
	signal rst : std_logic := '0';
	signal test_pulse_cnt : integer := 0;
    signal testCompleted : boolean := false;
    signal AllOK : boolean := true;
    begin
        mem: memory 
        generic map
        (
            DATA_WIDTH => DATA_WIDTH,
            ADDRESS_WIDTH => ADDRESS_WIDTH, 
            INTERFACE_NUM => INTERFACE_NUM
        )
        port map(
            clk => clk,
            rst => rst,
            data_in_bus => data_in_bus,
            data_out_bus => data_out_bus,
            address_bus => address_bus,
            control_bus => control_bus,
            validDMA_bus => validDMA_bus,
            readyMEM_bus => readyMEM_bus,
            validMEM_bus => validMEM_bus,
            readyDMA_bus => readyDMA_bus
        );

        clock: process(clk, rst)
        begin
            if not testCompleted then
                if rst = '1' then
                    clk <= '0';
                elsif rising_edge(clk) then
                    clk <= '0' after TICK;
                    test_pulse_cnt <= test_pulse_cnt + 1;
                else
                    clk <= '1' after TICK;
                end if;
            end if;
        end process clock;
        
        reset: process
        begin
            rst <= '1', '0' after PULSE;
            wait;
        end process reset;

        stress_test: process(clk, rst)
            type mem is array (integer range<>) of std_logic_vector(DATA_WIDTH - 1 downto 0);
            variable test_mem : mem(2**ADDRESS_WIDTH - 1 downto 0);
            variable i : integer; 
            type STAGE is (WR, RD, WAIT_ST, END_ST);
            type STAGE_ARRAY is array (integer range <>) of STAGE;
            variable int_stage : STAGE_ARRAY(0 to INTERFACE_NUM -1);
            type address_ARRAY  is array (integer range <>) of std_logic_vector(ADDRESS_WIDTH - 1 downto 0); 
            variable cnt_int_address : address_ARRAY(0 to INTERFACE_NUM -1); 
            type FLAG_ARRAY is array (integer range <>) of boolean;
            variable int_flag : FLAG_ARRAY(0 to INTERFACE_NUM - 1);
            variable validDMA_bus_map : std_logic_vector(INTERFACE_NUM - 1 downto 0) := (others => '0');

            variable testCompleted_map : boolean;
        begin
            if rst = '1' then
                readyDMA_bus <= (others =>'1');
                test_mem := (others => std_logic_vector(to_unsigned(0, DATA_WIDTH)));
                int_stage := (others => WR); 
                for i  in 0 to INTERFACE_NUM - 1 loop
                    cnt_int_address(i) :=  std_logic_vector(to_unsigned(2**ADDRESS_WIDTH/INTERFACE_NUM * i, ADDRESS_WIDTH));
                end loop;
                int_flag := (others => false);
                validDMA_bus_map := (others => '0');
                testCompleted_map := false;
            elsif rising_edge(clk) then
                for i in 0 to INTERFACE_NUM - 1 loop
                    if validDMA_bus_map(i)= '1' and readyMEM_bus(i) = '1' then
                        validDMA_bus_map(i) := '0';
                    end if;
                    if int_stage(i) = WAIT_ST then
                        if validMEM_bus(i) = '1' then 
                            if test_mem(to_integer(unsigned(cnt_int_address(i)))) /= data_out_bus((i+1) * DATA_WIDTH - 1 downto i * DATA_WIDTH) then 
                                AllOK <= false;
                            end if;
                            if cnt_int_address(i) = std_logic_vector(to_unsigned(2**ADDRESS_WIDTH/INTERFACE_NUM * (i+1) - 1, ADDRESS_WIDTH)) then
                                int_stage(i) := END_ST; 
                            else
                                cnt_int_address(i) := cnt_int_address(i) + std_logic_vector(to_unsigned(1, ADDRESS_WIDTH));
                                int_stage(i) := WR;
                            end if;
                        end if; 
                    end if;
                   
                    case int_stage(i) is
                        when WR =>
                            if validDMA_bus_map(i) = '0' then 
                                address_bus((i+1) * ADDRESS_WIDTH - 1 downto i * ADDRESS_WIDTH) <= cnt_int_address(i);
                                control_bus(i) <= '1';
                                data_in_bus((i+1) * DATA_WIDTH - 1 downto i * DATA_WIDTH) <= std_logic_vector(to_unsigned(test_pulse_cnt, DATA_WIDTH));
                                test_mem(to_integer(unsigned(cnt_int_address(i)))) := std_logic_vector(to_unsigned(test_pulse_cnt, DATA_WIDTH));
                                validDMA_bus_map(i) := '1';
                                int_stage(i) := RD;
                            end if;
                        when RD =>
                            if validDMA_bus_map(i)= '0' then    
                                validDMA_bus_map(i):='1';      
                                address_bus((i+1) * ADDRESS_WIDTH - 1 downto i * ADDRESS_WIDTH) <= cnt_int_address(i);
                                control_bus(i) <= '0';
                                int_stage(i) := WAIT_ST;
                            end if;
                        when others =>
                            NULL;
                    end case;

                end loop;
                testCompleted_map := true;
                for i in 0 to INTERFACE_NUM - 1 loop
                    if int_stage(i) /= END_ST then
                        testCompleted_map := false;
                    end if;    
                end loop; 
                testCompleted <= testCompleted_map;
                validDMA_bus <= validDMA_bus_map;
            end if;
        end process stress_test;
    end architecture main;
