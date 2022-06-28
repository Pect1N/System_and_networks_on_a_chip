library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

-- порты АЛУ
-- reset - сброс
-- op_code - код операции
-- in1 - первый операнд
-- in2 - второй операнд
-- out1 - результат
-- flag_z - флаг нулевого результата
-- flag_cy - флаг переноса
-- flag_ov - флаг переполнения

entity alu is
    port(
        reset   : in std_logic;
        op_code : in  std_logic_vector (3 downto 0);
        in1     : in  std_logic_vector (7 downto 0);
        in2     : in  std_logic_vector (7 downto 0);
        out1    : out std_logic_vector (7 downto 0);
        flag_z  : out std_logic;
        flag_cy : out std_logic;
        flag_ov : out std_logic);
end alu;

architecture behaviour of alu is

--Коды операций, которые выполняет АЛУ
constant  alu_op_add : std_logic_vector (3 downto 0)  := "0001";
constant  alu_op_sub : std_logic_vector (3 downto 0)  := "0010";
constant  alu_op_mul : std_logic_vector (3 downto 0)  := "0011";
constant  alu_op_and : std_logic_vector (3 downto 0)  := "0100";
constant  alu_op_or  : std_logic_vector (3 downto 0)  := "0101";
constant  alu_op_xor : std_logic_vector (3 downto 0)  := "0110";
constant  alu_op_ror : std_logic_vector (3 downto 0)  := "0111";
constant  alu_op_rol : std_logic_vector (3 downto 0)  := "1000";
constant  alu_op_not : std_logic_vector (3 downto 0)  := "1001";

-- Процедура вычисляющая по значению результата значение флага OV
procedure calc_overflow_flag (
    result          : in  std_logic_vector (15 downto 0);
    overflow_flag   : out std_logic ) is
    begin
             -- Проверяются старшие 8 бит результата
        if( result( 15 downto 8 ) /= "00000000" ) then
                    -- Если они не нулевые, то установить флаг переполнения
            overflow_flag := '1';
        else
                    -- Если они нулевые, то сбросить флаг переполнения
            overflow_flag := '0';
        end if;
    end calc_overflow_flag;

begin
    process(
    reset,
    op_code,
    in1,
    in2 )
        -- Временные переменные для хранения значений внутри процесса
        variable tmp_in1, tmp_in2 : std_logic_vector (15 downto 0);
        variable res : std_logic_vector (15 downto 0);
        variable res_z, res_cy, res_ov : std_logic;
    begin

    if reset = '0' then
        -- Обнуляем внутренние переменные и записываем в них
        -- входные значения
        -- Внутренние переменные имеют вдвое большую разрядность, чем
        -- входные, для того, что бы иметь возможность устанавливать
        -- флаги
        tmp_in1 := "0000000000000000";
        tmp_in2 := "0000000000000000";
        tmp_in1( 7 downto 0 ) := in1;
        tmp_in2( 7 downto 0 ) := in2;

        -- Определяем какой код операции установлен
        case op_code is
            when alu_op_add =>
            -- Установлен код операции сложения
            -- Выполняем сложение
            res := tmp_in1 + tmp_in2;
            when alu_op_mul =>
            -- Умножение
                    -- Максимальное значение результата умножения
                    -- имеет разрядность в 2 раза больше чем операнды,
                    -- поэтому в качестве множителей берутся не 16-разрядные
                    -- tmp_in1 и tmp_in1, а 8 разрядные in1 и in2
            res := in1 * in2;
            -- Устанавливаем флаг OV
            calc_overflow_flag( res, res_ov );
            when alu_op_rol =>
            -- Циклический сдвиг влево
            res( 0 ) := tmp_in1( 7 );
            res( 7 downto 1 ) := tmp_in1( 6 downto 0 );
            when others =>
            -- Неизвестный код операции
            res := "ZZZZZZZZZZZZZZZZ";
        end case;
    end if;

    -- Выдаем в порты 8 младших бит результата и
    -- значения флагов
    out1 <= res( 7 downto 0 );
    flag_z <= res_z;
    flag_cy <= res_cy;
    flag_ov <= res_ov;
end process;
end behaviour;