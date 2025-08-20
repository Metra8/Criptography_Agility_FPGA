library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.to_hexadecimal_pkg.all;

entity tb_crypto_wrapper is
end tb_crypto_wrapper;

architecture sim of tb_crypto_wrapper is

    --------------------------------------------------------------------
    -- Señales para conectar al DUT
    --------------------------------------------------------------------
    signal clk              : std_logic := '0';
    signal reset            : std_logic := '1';

    -- Interfaz externa de datos
    signal ext_data_in      : std_logic_vector(31 downto 0) := (others => '0');
    signal ext_valid_in     : std_logic := '0';
    signal ext_ready_out    : std_logic;
    signal ext_data_out     : std_logic_vector(31 downto 0);
    signal ext_valid_out    : std_logic;
    signal ext_ready_in     : std_logic := '0';

    -- Interfaz externa de clave
    signal ext_key_in       : std_logic_vector(31 downto 0) := (others => '0');
    signal ext_key_valid    : std_logic := '0';
    signal ext_key_ready    : std_logic;
    signal ext_key_out      : std_logic_vector(31 downto 0);
    signal ext_key_valid_out: std_logic;
    signal ext_key_ready_in : std_logic := '0';

    -- Señales de control
    signal suspicious       : std_logic := '0';
    signal force_switch     : std_logic := '0';
    signal rand_toggle      : std_logic := '0';

    constant clk_period     : time := 10 ns;

    --------------------------------------------------------------------
    -- DUT
    --------------------------------------------------------------------
    component crypto_wrapper
        port(
            clk                : in  std_logic;
            reset              : in  std_logic;

            ext_data_in        : in  std_logic_vector(31 downto 0);
            ext_valid_in       : in  std_logic;
            ext_ready_out      : out std_logic;
            ext_data_out       : out std_logic_vector(31 downto 0);
            ext_valid_out      : out std_logic;
            ext_ready_in       : in  std_logic;

            ext_key_in         : in  std_logic_vector(31 downto 0);
            ext_key_valid      : in  std_logic;
            ext_key_ready      : out std_logic;
            ext_key_out        : out std_logic_vector(31 downto 0);
            ext_key_valid_out  : out std_logic;
            ext_key_ready_in   : in  std_logic;

            suspicious         : in  std_logic;
            force_switch       : in  std_logic;
            rand_toggle        : in  std_logic
        );
    end component;

begin

    --------------------------------------------------------------------
    -- Instancia del DUT
    --------------------------------------------------------------------
    uut: crypto_wrapper
        port map(
            clk              => clk,
            reset            => reset,
            ext_data_in      => ext_data_in,
            ext_valid_in     => ext_valid_in,
            ext_ready_out    => ext_ready_out,
            ext_data_out     => ext_data_out,
            ext_valid_out    => ext_valid_out,
            ext_ready_in     => ext_ready_in,
            ext_key_in       => ext_key_in,
            ext_key_valid    => ext_key_valid,
            ext_key_ready    => ext_key_ready,
            ext_key_out      => ext_key_out,
            ext_key_valid_out=> ext_key_valid_out,
            ext_key_ready_in => ext_key_ready_in,
            suspicious       => suspicious,
            force_switch     => force_switch,
            rand_toggle      => rand_toggle
        );

    --------------------------------------------------------------------
    -- Reloj
    --------------------------------------------------------------------
    clk_process: process
    begin
        while now < 5000 ns loop
            clk <= '0'; wait for clk_period/2;
            clk <= '1'; wait for clk_period/2;
        end loop;
        wait;
    end process;

    --------------------------------------------------------------------
    -- Estímulos
    --------------------------------------------------------------------
    stim_proc: process
        variable output_block : std_logic_vector(127 downto 0);
    begin
        wait for 20 ns;
        reset <= '0';

        ----------------------------------------------------------------
        -- Enviar primer bloque AES
        ----------------------------------------------------------------
        for i in 0 to 3 loop
            ext_data_in  <= x"00000000";
            ext_valid_in <= '1';
            wait until rising_edge(clk) and ext_ready_out = '1';
        end loop;
        ext_valid_in <= '0';

        -- Recibir bloque de salida
        for i in 0 to 3 loop
            ext_ready_in <= '1';
            wait until rising_edge(clk) and ext_valid_out = '1';
            output_block(127 - i*32 downto 96 - i*32) := ext_data_out;
        end loop;
        ext_ready_in <= '0';

        report "AES initial => " & to_hstring(output_block);

        ----------------------------------------------------------------
        -- Forzar suspicious para saltar a Kyber
        ----------------------------------------------------------------
        suspicious <= '1';
        wait for clk_period;
        suspicious <= '0';

        -- Nuevo bloque de entrada
        for i in 0 to 3 loop
            ext_data_in  <= x"00012300";
            ext_valid_in <= '1';
            wait until rising_edge(clk) and ext_ready_out = '1';
        end loop;
        ext_valid_in <= '0';

        -- Recibir salida
        for i in 0 to 3 loop
            ext_ready_in <= '1';
            wait until rising_edge(clk) and ext_valid_out = '1';
            output_block(127 - i*32 downto 96 - i*32) := ext_data_out;
        end loop;
        ext_ready_in <= '0';

        report "AES after Kyber(suspicious) => " & to_hstring(output_block);

        ----------------------------------------------------------------
        -- Toggle aleatorio
        ----------------------------------------------------------------
        rand_toggle <= '1';
        wait for clk_period;
        rand_toggle <= '0';

        for i in 0 to 3 loop
            ext_data_in  <= x"03333001";
            ext_valid_in <= '1';
            wait until rising_edge(clk) and ext_ready_out = '1';
        end loop;
        ext_valid_in <= '0';

        for i in 0 to 3 loop
            ext_ready_in <= '1';
            wait until rising_edge(clk) and ext_valid_out = '1';
            output_block(127 - i*32 downto 96 - i*32) := ext_data_out;
        end loop;
        ext_ready_in <= '0';

        report "AES after rand_toggle => " & to_hstring(output_block);

        wait for 100 ns;
        assert false report "Simulation finished OK." severity failure;
    end process;

end sim;
