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
