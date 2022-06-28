library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

entity Memory is
    generic
	(
		DATA_WIDTH : integer := 8;
		ADDRESS_WIDTH : integer := 5
	);

    port(
        clk: in std_logic;
        address_N : in std_logic_vector(ADDRESS_WIDTH - 1 downto 0);
		data_in1 : in std_logic_vector(DATA_WIDTH - 1 downto 0);
		valid1 : in std_logic;
		control1 : in std_logic;
		data_out1 : out std_logic_vector(DATA_WIDTH - 1 downto 0);
		ready1 : out std_logic;
		data_in2 : in std_logic_vector(DATA_WIDTH - 1 downto 0);
		valid2 : in std_logic;
		control2 : in std_logic;
		data_out2 : out std_logic_vector(DATA_WIDTH - 1 downto 0);
		ready2 : out std_logic
    );
end Memory;

architecture mem of Memory is
	type mas is array(integer range <>) of std_logic_vector(DATA_WIDTH - 1 downto 0);
	
	begin
		interface: process(clk)
			variable count_data : integer := 2**ADDRESS_WIDTH;
			variable data_memory: mas(0 to count_data - 1);
			variable address_int : integer;
			begin
				if rising_edge(clk) then
					ready1 <= '0';
					ready2 <= '0';
					address_int:= to_integer(unsigned(address_N));
					if (valid1 = '1') then
						if (control1 = '1') then
							data_memory(address_int)(DATA_WIDTH - 1 downto 0):= data_in1(DATA_WIDTH - 1 downto 0);
							ready1 <= '1';
						else
							data_out1(DATA_WIDTH - 1 downto 0) <= data_memory(address_int)(DATA_WIDTH - 1 downto 0);
							ready1 <= '1';
						end if;
					end if;
					if (valid2 = '1') then
						if (control2 = '1') then
							data_memory(address_int)(DATA_WIDTH - 1 downto 0):= data_in2(DATA_WIDTH - 1 downto 0);
							ready2 <= '1';
						else
							data_out2(DATA_WIDTH - 1 downto 0) <= data_memory(address_int)(DATA_WIDTH - 1 downto 0);
							ready2 <= '1';
						end if;
					end if;
				end if;
		end process interface;
	end architecture mem;