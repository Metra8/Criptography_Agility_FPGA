LIBRARY IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.aes_transform_pkg.all;
use work.sbox_pkg.all;
use work.key_expansion_pkg.all;

entity aes_128_tb is

end entity;


architecture behavioral of aes_128_tb is

    --señales DUT (decive under test)
    signal clk      : std_logic := '0';
    signal reset    : std_logic := '0';
    signal enable   : std_logic := '0';
    signal key      : std_logic_vector(127 downto 0);
    signal data_in  : std_logic_vector(127 downto 0);
    signal data_out : std_logic_vector(127 downto 0);
    signal ready    : std_logic;

    constant clk_semiperiod : time := 5 ns;


begin

    --instancia, uut <=> unit under test
    uut: entity work.aes_128
        port map (
            clk         => clk,
            reset       => reset,
            enable      => enable,
            key         => key,
            data_in     => data_in,
            data_out    => data_out,
            ready       => ready         
        );


    process
    begin
        while true loop
            clk <= '0';
            wait for clk_semiperiod;
            clk <= '1';
            wait for clk_semiperiod;
        end loop; 
    end process;

    process
    begin
        reset <= '1';
        wait for 20 ns;
        reset <= '0';
        wait for 10 ns;

        key     <= x"2b7e151628aed2a6abf7158809cf4f3c";
        data_in <= x"3243f6a8885a308d313198a2e0370734";

        enable <= '1';

        wait until ready = '1';

        report "Resultado AES = " & to_hstring(data_out);
        wait;
    end process;
end behavioral;
