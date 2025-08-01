LIBRARY IEEE;
USE IEEE.std_logic_1164.all;
USE IEEE.numeric_std.all;


package to_hexadecimal_pkg is

    --función principal
    function to_hstring(signal_in: std_logic_vector) return string;

end package to_hexadecimal_pkg;

package body to_hexadecimal_pkg is


    function to_hstring(signal_in: std_logic_vector) return string is
        variable result: string(1 to signal_in'length / 4);
        variable temp  : std_logic_vector(3 downto 0);
    begin
        for i in 0 to (signal_in'length / 4 - 1) loop
            temp := signal_in((signal_in'length - 1) - i*4 downto (signal_in'length - 4) - i*4);
            case temp is
                when "0000" => result(i+1) := '0';
                when "0001" => result(i+1) := '1';
                when "0010" => result(i+1) := '2';
                when "0011" => result(i+1) := '3';
                when "0100" => result(i+1) := '4';
                when "0101" => result(i+1) := '5';
                when "0110" => result(i+1) := '6';
                when "0111" => result(i+1) := '7';
                when "1000" => result(i+1) := '8';
                when "1001" => result(i+1) := '9';
                when "1010" => result(i+1) := 'A';
                when "1011" => result(i+1) := 'B';
                when "1100" => result(i+1) := 'C';
                when "1101" => result(i+1) := 'D';
                when "1110" => result(i+1) := 'E';
                when "1111" => result(i+1) := 'F';
                when others => result(i+1) := 'X';
            end case;
        end loop;
        return result;
    end function;

end package body to_hexadecimal_pkg;
