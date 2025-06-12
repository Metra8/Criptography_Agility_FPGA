LIBRARY IEEE;
USE IEEE.std_logic_1164.all;
USE IEEE.numeric_std.all;
USE work.key_types.all;


entity key_expansion is

    Port(
        clk         : in std_logic;
        reset       : in std_logic;
        key         : in std_logic_vector(127 downto 0);
        round_keys  : out key_array_t

    );

end key_expansion;

architecture behavioral of key_expansion is

begin






end behavioral;

