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
        variable input_count : integer := 0;
    begin
        wait for 20 ns;
        reset <= '0';

        -- aes
        for i in 0 to 3 loop
            wait for 10 ns;
            data_in <= std_logic_vector(to_unsigned(i, 128));
            key     <= x"2b7e151628aed2a6abf7158809cf4f3c";
            enable  <= '1';
            wait for clk_period;
            enable  <= '0';
            wait until ready = '1';
            report "AES#" & integer'image(i) & " => " & to_hstring(data_out);
        end loop;

        -- Fuerza cambio
        wait for 50 ns;
        suspicious <= '1';
        wait for clk_period;
        suspicious <= '0';

        -- Ejecuta una entrada con Kyber
        data_in <= x"99999999999999999999999999999999";
        key     <= x"00112233445566778899aabbccddeeff";
        enable  <= '1';
        wait for clk_period;
        enable  <= '0';
        wait until ready = '1';
        report "Kyber (por suspicious) => " & to_hstring(data_out);

        -- Vuelve a AES automáticamente tras 200 bloques
        -- Forzamos contador alto
        for i in 0 to 200 loop
            wait for 10 ns;
            data_in <= std_logic_vector(to_unsigned(i, 128));
            enable  <= '1';
            wait for clk_period;
            enable  <= '0';
            wait until ready = '1';
        end loop;

        wait for 50 ns;
        report "Debería haber vuelto a AES";

        -- Cambia con rand_toggle
        rand_toggle <= '1';
        wait for clk_period;
        rand_toggle <= '0';

        data_in <= x"AABBCCDDEEFF00112233445566778899";
        enable  <= '1';
        wait for clk_period;
        enable  <= '0';
        wait until ready = '1';
        report "Salida tras rand_toggle => " & to_hstring(data_out);

        wait for 100 ns;
        assert false report "Simulación terminada correctamente." severity failure;
    end process;

end sim;
