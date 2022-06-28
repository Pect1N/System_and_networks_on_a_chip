library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity place is
    generic
    (
        length : integer := 8
    );
    port(
        clk : in std_logic;
        rst : in std_logic;
        A1 : in std_logic_vector(length - 1 downto 0);
        A2 : in std_logic_vector(length - 1 downto 0);
        O  : in std_logic_vector(2 downto 0);
        Y  : out std_logic_vector(length - 1 downto 0);
        Overflow : out std_logic
    );
end entity place;

architecture doing of place is
    constant  zero : std_logic_vector (length - 1 downto 0)  := "00000000";
    constant  max_limit : std_logic_vector (length - 1 downto 0)  := "11111111";
    constant  add : std_logic_vector (length - 1 downto 0)  := "00000001";
    constant  gecr_op : std_logic_vector (2 downto 0)  := "000"; -- 0
    constant  not_op  : std_logic_vector (2 downto 0)  := "001"; -- 1
    constant  add_fop : std_logic_vector (2 downto 0)  := "010"; -- 2
    constant  mult_op : std_logic_vector (2 downto 0)  := "011"; -- 3
    constant  add_sop : std_logic_vector (2 downto 0)  := "100"; -- 4
    constant  rol_op  : std_logic_vector (2 downto 0)  := "101"; -- 5
begin
    
    calculation : process(clk, rst)
    variable tmp1 : std_logic_vector (length - 1 downto 0);
    variable tmp2 : std_logic_vector (length - 1 downto 0);
    variable cycle : std_logic_vector (length - 1 downto 0);
    variable i : integer;
    begin
        if rising_edge(clk) then
            Overflow <= '0';
            tmp1 := zero;
            if O = gecr_op then
                if A1 /= max_limit then
                    if A1(length - 1) = '0' then
                        Y <= A1 - add;
                    else
                        Y <= A1 + add;
                    end if;
                else
                    Overflow <= '1';
                    Y <= zero;
                end if;
            end if;
            if O = not_op then
                tmp1 := A1;
                tmp1(length - 1) := not(tmp1(length - 1));
                Y <= tmp1;
            end if;
            if O = add_fop then
                if A1(length - 1 ) = '0' and A2(length - 1) = '0' then -- оба положительные
                    tmp1 := A1 + A2;
                    if tmp1(length - 1) = '1' then
                        Overflow <= '1';
                        tmp1(length - 1) := '0';
                        Y <= tmp1;
                    else
                        Y <= tmp1;
                    end if;
                elsif A1(length - 1 ) = '1' and A2(length - 1) = '1' then -- оба отрицательные
                    tmp1 := A1 + A2;
                    if tmp1(length - 1) = '1' then
                        Overflow <= '1';
                        Y <= tmp1;
                    else
                        tmp1(length - 1) := '1';
                        Y <= tmp1;
                    end if;
                else -- один отрицательный
                    if A1(length - 1) = '1' then -- первый отрицательный
                        tmp1 := A1;
                        tmp1(length - 2 downto 0) := not(tmp1(length - 2 downto 0));
                        tmp1 := tmp1 + A2;
                        if tmp1(length - 1) = '1' then
                            tmp1(length - 2 downto 0) := not(tmp1(length - 2 downto 0));
                            Y <= tmp1;
                        else
                            tmp1 := tmp1 + add;
                            Y <= tmp1;
                        end if;
                    else -- второй отрицательный
                        tmp1 := A2;
                        tmp1(length - 2 downto 0) := not(tmp1(length - 2 downto 0));
                        tmp1 := tmp1 + A1;
                        if tmp1(length - 1) = '1' then
                            tmp1(length - 2 downto 0) := not(tmp1(length - 2 downto 0));
                            Y <= tmp1;
                        else
                            tmp1 := tmp1 + add;
                            Y <= tmp1;
                        end if;
                    end if;
                end if;
            end if;
            if O = mult_op then -- 
                if A1(length - 1) = '0' then
                    if A2(length - 1) = '0' then
                        Y <= A1(length / 2 - 1 downto 0) * A2(length / 2 - 1 downto 0);
                    else
                        tmp1 := A1(length / 2 - 1 downto 0) * A2(length / 2 - 1 downto 0);
                        tmp1(length - 1) := '1';
                        Y <= tmp1;
                    end if;
                else
                    if A2(length - 1) = '0' then
                        tmp1 := A1(length / 2 - 1 downto 0) * A2(length / 2 - 1 downto 0);
                        tmp1(length - 1) := '1';
                        Y <= tmp1;
                    else
                        tmp1 := A1(length / 2 - 1 downto 0) * A2(length / 2 - 1 downto 0);
                        tmp1(length - 1) := '0';
                        Y <= tmp1;
                    end if;
                end if;
            end if;
            if O = add_sop then
                tmp1 := A1 + A2;
                if (A1(length - 1) = '0' and A2(length - 1) = '0' and tmp1(length - 1) = '1') or (A1(length - 1 ) = '1' and A2(length - 1) = '1' and tmp1(length - 1) = '1') then
                    Overflow <= '1';
                    tmp1(length - 1) := '0';
                    Y <= tmp1;
                elsif A1(length - 1 ) = '0' and A2(length - 1) = '0' then -- оба положительные
                    tmp1 := A1;
                    tmp2 := A2;
                    i := conv_integer(signed(tmp1)) + conv_integer(signed(tmp2));
                    Y <= conv_std_logic_vector(i, Y'length);
                elsif A1(length - 1 ) = '1' and A2(length - 1) = '1' then -- оба отрицательные
                    tmp1 := A1;
                    tmp2 := A2;
                    tmp1(length- 2 downto 0) := not(tmp1(length- 2 downto 0));
                    tmp2(length- 2 downto 0) := not(tmp2(length- 2 downto 0));
                    tmp1 := tmp1 + add;
                    tmp2 := tmp2 + add;
                    i := conv_integer(signed(tmp1)) + conv_integer(signed(tmp2));
                    tmp1 := conv_std_logic_vector(i, Y'length);
                    tmp1 := tmp1 - add;
                    tmp1(length- 2 downto 0) := not(tmp1(length- 2 downto 0));
                    Y <= tmp1;
                else
                    if A1(length - 1) = '1' then -- первый отрицательный
                        tmp1 := A1;
                        tmp2 := A2;
                        tmp1(length- 2 downto 0) := not(tmp1(length- 2 downto 0));
                        tmp1 := tmp1 + add;
                        i := conv_integer(signed(tmp1)) + conv_integer(signed(tmp2));
                        tmp1 := conv_std_logic_vector(i, Y'length);
                        if tmp1(length - 1) = '1' then
                            tmp1 := tmp1 - add;
                            tmp1(length- 2 downto 0) := not(tmp1(length- 2 downto 0));
                        end if;
                        Y <= tmp1;
                    else
                        tmp1 := A1;
                        tmp2 := A2;
                        tmp2(length- 2 downto 0) := not(tmp2(length- 2 downto 0));
                        tmp2 := tmp2 + add;
                        i := conv_integer(signed(tmp1)) + conv_integer(signed(tmp2));
                        tmp1 := conv_std_logic_vector(i, Y'length);
                        if tmp1(length - 1) = '1' then
                            tmp1 := tmp1 - add;
                            tmp1(length- 2 downto 0) := not(tmp1(length- 2 downto 0));
                        end if;
                        Y <= tmp1;
                    end if;
                end if;
            end if;
            if O = rol_op then
                cycle(length - 1 downto 0) := A2(length - 1 downto 0);
                cycle(length - 1) := '0';
                tmp1(length - 1 downto 0) := A1(length - 1 downto 0);
                tmp2 := tmp1;
                while cycle /= zero loop
                    if A2(length - 1) = '0' then
                        tmp1(0) := tmp2(length - 1);
                        tmp1(length - 1 downto 1) := tmp2(length - 2 downto 0);
                        tmp2(length - 1 downto 0) := tmp1(length - 1 downto 0);
                    else
                        tmp1(length - 1) := tmp2(0);
                        tmp1(length - 2 downto 0) := tmp2(length - 1 downto 1);
                        tmp2(length - 1 downto 0) := tmp1(length - 1 downto 0);
                    end if;
                    cycle := cycle - add;
                end loop;
                Y <= tmp1;
            end if;
        end if ;
    end process ;
end architecture doing;