library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_crypto_wrapper is
end tb_crypto_wrapper;

architecture sim of tb_crypto_wrapper is

    -- Señales de DUT
    signal clk        : std_logic := '0';
    signal reset      : std_logic := '1';
    signal enable     : std_logic := '0';
    signal selector   : std_logic_vector(1 downto 0);
    signal key        : std_logic_vector(127 downto 0);
    signal data_in    : std_logic_vector(127 downto 0);
    signal data_out   : std_logic_vector(127 downto 0);
    signal ready      : std_logic;

    -- Clock period
    constant clk_period : time := 10 ns;

    -- Componente a testear
    component crypto_wrapper
        port (
            clk       : in std_logic;
            reset     : in std_logic;
            enable    : in std_logic;
            selector  : in std_logic_vector(1 downto 0);
            key       : in std_logic_vector(127 downto 0);
            data_in   : in std_logic_vector(127 downto 0);
            data_out  : out std_logic_vector(127 downto 0);
            ready     : out std_logic
        );
    end component;

begin

    -- Instancia del wrapper
    uut: crypto_wrapper
        port map (
            clk       => clk,
            reset     => reset,
            enable    => enable,
            selector  => selector,
            key       => key,
            data_in   => data_in,
            data_out  => data_out,
            ready     => ready
        );

    -- Generación de reloj
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
    begin
        -- Inicialización
        wait for 20 ns;
        reset <= '0';

        -- === Prueba AES ===
        selector <= "00";  -- AES
        key      <= x"2b7e151628aed2a6abf7158809cf4f3c";
        data_in  <= x"3243f6a8885a308d313198a2e0370734";
        enable   <= '1';

        wait for 10 ns;
        enable <= '0';

        wait until ready = '1';
        report "AES Resultado: " & to_hstring(data_out);

        -- === Prueba Kyber ===
        wait for 100 ns;

        selector <= "01";  -- Kyber
        key      <= x"00112233445566778899aabbccddeeff";
        data_in  <= x"abcdef1234567890abcdef1234567890";
        enable   <= '1';

        wait for 10 ns;
        enable <= '0';

        wait until ready = '1';
        report "Kyber Resultado: " & to_hstring(data_out);

        -- Fin de simulación
        wait for 100 ns;
        assert false report "Simulación terminada correctamente." severity failure;
    end process;

end sim;
