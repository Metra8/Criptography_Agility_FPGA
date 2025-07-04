LIBRARY IEEE;
USE IEEE.std_logic_1164.all;
USE IEEE.numeric_std.all;

USE work.sbox_pkg.all;

package key_expansion_pkg is

    --array de round keys (OUT)
    type key_array_t is array (0 to 10) of std_logic_vector(127 downto 0);

    --función principal
    function key_expansion(key : std_logic_vector(127 downto 0)) return key_array_t;

end package key_expansion_pkg;

package body key_expansion_pkg is

    type word_array is array (0 to 43) of std_logic_vector(31 downto 0);

    --constante Rcon (valores de 8 bits) (round constant) => 01, 02, 04, 08, 10, 20, 40, 80, 1B, 36;
    constant Rcon : std_logic_vector(8*10-1 downto 0) := x"01020408102040801B36";

    --función SubWord (sustitución)
    function SubWord(input : std_logic_vector(31 downto 0)) return std_logic_vector is
        variable output : std_logic_vector(31 downto 0);
    begin
        for i in 0 to 3 loop
            output(8*i+7 downto 8*i) := sbox(input(8*i+7 downto 8*i));
        end loop;
        return output;
    end function;

    
    --función RotWord (rotación)
    --ejemplo: entrada => ABCD (cada uno 1B). Salida => BCDA
    function RotWord(input : std_logic_vector(31 downto 0)) return std_logic_vector is
    begin
        return input (23 downto 0) & input (31 downto 24);
    end function;

    --función key expansion
    function key_expansion(key : std_logic_vector(127 downto 0)) return key_array_t is
        variable w          : word_array;
        variable rk         : key_array_t;
        variable temp       : std_logic_vector(31 downto 0);
        variable rcon_byte  : std_logic_vector(7 downto 0);
    begin
        --asignar la clave a el word array
        for i in 0 to 3 loop
            w(i) := key(32*i+31 downto 32*i);
        end loop;

        --expansión de claves
        for i in 4 to 43 loop
            temp := w(i-1);
            --cada 4 iteraciones aplicamos una transformación especial
            if (i mod 4 = 0) then
                rcon_byte := Rcon (8*((i/4)-1)+7 downto 8*((i/4)-1));
                temp := SubWord(RotWord(temp)) xor (rcon_byte & x"00000000");
            end if;
            w(i) := w(i-4) xor temp;
        end loop;
        
        -- agrupar round keys
        for i in 0 to 10 loop
            rk(i) := w(4*i+3) & w(4*i+2) & w(4*i+1) & w(4*i);
        end loop;

        return rk;
    end function;

end package body key_expansion_pkg;
