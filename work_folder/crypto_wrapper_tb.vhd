library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.to_hexadecimal_pkg.all;

entity tb_crypto_wrapper is
end tb_crypto_wrapper;

architecture sim of tb_crypto_wrapper is

    signal clk          : std_logic := '0';
    signal reset        : std_logic := '1';
    signal enable       : std_logic := '0';
    signal key          : std_logic_vector(127 downto 0) := (others => '0');
    signal data_in      : std_logic_vector(127 downto 0) := (others => '0');
    signal suspicious   : std_logic := '0';
    signal force_switch : std_logic := '0';
    signal rand_toggle  : std_logic := '0';
    signal data_out     : std_logic_vector(127 downto 0);
    signal ready        : std_logic;

    constant clk_period : time := 10 ns;

    component crypto_wrapper
        port (
            clk          : in  std_logic;
            reset        : in  std_logic;
            enable       : in  std_logic;
            key          : in  std_logic_vector(127 downto 0);
            data_in      : in  std_logic_vector(127 downto 0);
            suspicious   : in  std_logic;
            force_switch : in  std_logic;
            rand_toggle  : in  std_logic;
            data_out     : out std_logic_vector(127 downto 0);
            ready        : out std_logic
        );
    end component;

begin

    -- Instancia del DUT
    uut: crypto_wrapper
        port map (
            clk          => clk,
            reset        => reset,
            enable       => enable,
            key          => key,
            data_in      => data_in,
            suspicious   => suspicious,
            force_switch => force_switch,
            rand_toggle  => rand_toggle,
            data_out     => data_out,
            ready        => ready
        );

    
    clk_process: process
    begin
        while now < 2000 ns loop
            clk <= '0'; wait for clk_period / 2;
            clk <= '1'; wait for clk_period / 2;
        end loop;
        wait;
    end process;

    -- Estímulos
    stim_proc: process
        variable old_output  : std_logic_vector(127 downto 0);
        variable new_output  : std_logic_vector(127 downto 0);
    begin
        wait for 20 ns;
        reset <= '0';

        -- first key with aes cypher
        data_in <= x"00000000000000000000000000000001";
        key     <= x"2b7e151628aed2a6abf7158809cf4f3c";
        enable  <= '1';
        wait until ready = '1';
        old_output := data_out;
        report "AES inicial => " & to_hstring(data_out);

        -- forced change
        suspicious <= '1';
        wait for clk_period;
        suspicious <= '0';

        -- regenerate key with kyber
        data_in <= x"00009320009999900007320003333001";
        wait until ready = '1';
        new_output := data_out;
        report "AES tras Kyber(suspicious) => " & to_hstring(data_out);


        old_output := new_output; -- guardamos para siguiente prueba

        -- intensive task**
        -- vuelve a AES automáticamente tras 200 bloques
        --for i in 0 to 200 loop
            --data_in <= std_logic_vector(to_unsigned(i, 128));
            --wait until ready = '1';
            --wait for clk_period;
        --end loop;

        data_in <= x"00000000000000000000000000000001";
        wait until ready = '1';
        new_output := data_out;
        report "AES tras rotación automática => " & to_hstring(data_out);

        old_output := new_output;


        -- cambia con rand_toggle
        rand_toggle <= '1';
        wait for clk_period;
        rand_toggle <= '0';

        data_in <= x"00012300000000000000000000000001";
        wait until ready = '1';
        new_output := data_out;
        report "AES tras rand_toggle => " & to_hstring(data_out);

        wait for 50 ns;
        assert false report "Simulación terminada correctamente." severity failure;
    end process;

end sim;
