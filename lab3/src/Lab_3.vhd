library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

entity TB is
	generic
	(
		DATA_WIDTH : integer := 8;
		ADDRESS_WIDTH : integer := 5
	);
end TB;

architecture beh of TB is
    component Memory
        port(
            clk: in std_logic;
			address_N : in std_logic_vector(ADDRESS_WIDTH - 1 downto 0);
			data_in1  : in std_logic_vector(DATA_WIDTH - 1 downto 0);
			valid1    : in std_logic;
			control1  : in std_logic;
			data_out1 : out std_logic_vector(DATA_WIDTH - 1 downto 0);
			ready1    : out std_logic;
			data_in2  : in std_logic_vector(DATA_WIDTH - 1 downto 0);
			valid2    : in std_logic;
			control2  : in std_logic;
			data_out2 : out std_logic_vector(DATA_WIDTH - 1 downto 0);
			ready2    : out std_logic
        );
    end component;

    signal address  : std_logic_vector(ADDRESS_WIDTH - 1 downto 0):=(others => '0');
    signal data_in  : std_logic_vector(DATA_WIDTH - 1 downto 0):=(others => '0');
	signal data_out : std_logic_vector(DATA_WIDTH - 1 downto 0):=(others => '0');
	signal success  : std_logic:='0';
    signal valid    : std_logic:='0';
    signal control  : std_logic:='0';

    signal data_in2  : std_logic_vector(DATA_WIDTH - 1 downto 0):=(others => '0');
	signal data_out2 : std_logic_vector(DATA_WIDTH - 1 downto 0):=(others => '0');
	signal success2  : std_logic:='0';
    signal valid2    : std_logic:='0';
    signal control2  : std_logic:='0';
	
    constant period : time := 200 fs;
    signal clk : std_logic:='0';
	
	signal cnt : integer:=0;
	
    begin
        p: Memory port map(
            clk => clk,
            address_N => address,
			
            data_in1 => data_in,
          	data_out1 => data_out,
          	valid1 => valid,
          	ready1 => success,
          	control1 => control,

			data_in2 => data_in2,
          	data_out2 => data_out2,
          	valid2 => valid2,
          	ready2 => success2,
          	control2 => control2
        );
		
        test_clk:process(clk)
            begin
				if cnt /= 2**ADDRESS_WIDTH then
					if clk = '1' then
						cnt <= cnt+1;
						clk <= '0' after period;
					else
						clk <= '1' after period;
					end if;
				end if;
            end process test_clk;

        TBranch:process(cnt)
            begin
                if clk = '1' then
					valid <= '0';
					valid2 <= '0';
					address <= std_logic_vector(to_unsigned(cnt, ADDRESS_WIDTH));
					data_in <= std_logic_vector(to_unsigned(cnt+1, DATA_WIDTH));
					control <= '1';
					valid <= '1';
					if cnt >= 1 then
						address <= std_logic_vector(to_unsigned(cnt-1, ADDRESS_WIDTH));
						control2 <= '0';
						valid2 <= '1';
					end if;
                end if;
            end process TBranch;
    end architecture beh;