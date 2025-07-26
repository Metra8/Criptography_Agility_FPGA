library IEEE;
USE IEEE.numeric_std.all;
USE IEEE.std_logic_1164.all;


package aes_transform_pkg is 

    function ShiftRows(state : std_logic_vector(127 downto 0)) return std_logic_vector;

    function MixColumns(state : std_logic_vector(127 downto 0)) return std_logic_vector;

end package;

package body aes_transform_pkg is

    function ShiftRows(state : std_logic_vector(127 downto 0)) return std_logic_vector is
        variable out_state : std_logic_vector(127 downto 0);
        type byte_array is array (0 to 15) of std_logic_vector(7 downto 0);
        variable bytes : byte_array;
    
    begin
        --extraer los bytes
        for i in 0 to 15 loop
            bytes(i) := state(8*(15-i) + 7 downto 8*(15-i));
        end loop;

        --shift rows
        --ejemplo:
        --[ a0  a4  a8  ac ]
        --[ a1  a5  a9  ad ]
        --[ a2  a6  aa  ae ]
        --[ a3  a7  ab  af ]

        --pasa a:
        --[ a0  a4  a8  ac ]
        --[ a5  a9  ad  a1 ]
        --[ aa  ae  a2  a6 ]
        --[ af  a3  a7  ab ]

        out_state(127 downto 120) := bytes(0);
        out_state(119 downto 112) := bytes(5);
        out_state(111 downto 104) := bytes(10);
        out_state(103 downto  96) := bytes(15);

        out_state(95  downto  88) := bytes(4);
        out_state(87  downto  80) := bytes(9);
        out_state(79  downto  72) := bytes(14);
        out_state(71  downto  64) := bytes(3);

        out_state(63  downto  56) := bytes(8);
        out_state(55  downto  48) := bytes(13);
        out_state(47  downto  40) := bytes(2);
        out_state(39  downto  32) := bytes(7);

        out_state(31  downto  24) := bytes(12);
        out_state(23  downto  16) := bytes(1);
        out_state(15  downto   8) := bytes(6);
        out_state(7   downto   0) := bytes(11);

        return out_state;
    end function;

    --FUNCIÓN AUXILIAR de multiplicación en GF(2^8)
    function xtime(x : std_logic_vector(7 downto 0)) return std_logic_vector is
        variable result : std_logic_vector(7 downto 0);
    begin
        result := x(6 downto 0) & '0';
        if x(7) = '1' then
            result := result xor x"1B";
        end if;
        return result;
    end function;

    --multiplicación en GF(2^8)
    function gmul(a, b : std_logic_vector(7 downto 0)) return std_logic_vector is
        variable result : std_logic_vector(7 downto 0) := (others => '0');
        variable aa : std_logic_vector(7 downto 0) := a;
        variable bb : std_logic_vector(7 downto 0) := b;
    begin
        for i in 0 to 7 loop
            if bb(0) = '1' then
                result := result xor aa;
            end if;
            bb := '0' & bb(7 downto 1);
            if aa(7) = '1' then
                aa := (aa(6 downto 0) & '0') xor x"1B";
            else
                aa := aa(6 downto 0) & '0';
            end if;
        end loop;
        return result;
    end function;

    --MixColumns
    function MixColumns(state : std_logic_vector(127 downto 0)) return std_logic_vector is
        type byte_array is array (0 to 15) of std_logic_vector(7 downto 0);
        variable s      : byte_array;
        variable result : std_logic_vector(127 downto 0);
    begin
        --descomponer en bytes
        for i in 0 to 15 loop
            s(i) := state(127 - 8*i downto 120 - 8*i);
        end loop;

        --procesar por columna
        for col in 0 to 3 loop
            result(127 - 32*col downto 120 - 32*col) := 
                gmul(x"02", s(col)) xor gmul(x"03", s(col+4)) xor s(col+8) xor s(col+12);
            result(119 - 32*col downto 112 - 32*col) := 
                s(col) xor gmul(x"02", s(col+4)) xor gmul(x"03", s(col+8)) xor s(col+12);
            result(111 - 32*col downto 104 - 32*col) := 
                s(col) xor s(col+4) xor gmul(x"02", s(col+8)) xor gmul(x"03", s(col+12));
            result(103 - 32*col downto 96 - 32*col) := 
                gmul(x"03", s(col)) xor s(col+4) xor s(col+8) xor gmul(x"02", s(col+12));
        end loop;

        return result;
    end function;

end package body;   

