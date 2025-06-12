-- key_types.vhd
LIBRARY IEEE;
USE IEEE.std_logic_1164.all;

package key_types is
    type key_array_t is array (0 to 10) of std_logic_vector(127 downto 0);
end package;
