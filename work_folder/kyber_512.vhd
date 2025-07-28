--ESTO ES UN STUB DEL KYBER
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity kyber_512 is
    port(
        clk      : in  std_logic;
        reset    : in  std_logic;
        enable   : in  std_logic;
        key      : in  std_logic_vector(127 downto 0);
        data_in  : in  std_logic_vector(127 downto 0);
        data_out : out std_logic_vector(127 downto 0);
        ready    : out std_logic
    );
end kyber_512;

architecture behavioral of kyber_512 is
begin
    process(clk, reset)
    begin
        if reset = '1' then
            data_out <= (others => '0');
            ready    <= '0';
        elsif rising_edge(clk) then
            if enable = '1' then
                data_out <= x"CAFEBABECAFEBABECAFEBABECAFEBABE";  -- dummy output
                ready    <= '1';
            else
                ready <= '0';
            end if;
        end if;
    end process;
end behavioral;
