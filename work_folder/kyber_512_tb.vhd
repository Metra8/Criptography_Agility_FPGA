library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_kyber is
end tb_kyber;

architecture sim of tb_kyber is

    -- Señales del DUT (Device Under Test)
    signal clk      : std_logic := '0';
    signal reset    : std_logic := '1';
    signal enable   : std_logic := '0';
    signal key      : std_logic_vector(127 downto 0);
    signal data_in  : std_logic_vector(127 downto 0);
    signal data_out : std_logic_vector(127 downto 0);
    signal ready    : std_logic;

    -- Clock period
    constant clk_period : time := 10 ns;

    -- Componente Kyber
    component kyber
        port(
            clk       : in std_logic;
            reset     : in std_logic;
            enable    : in std_logic;
            key       : in std_logic_vector(127 downto 0);
            data_in   : in std_logic_vector(127 downto 0);
            data_out  : out std_logic_vector(127 downto 0);
            ready     : out std_logic
        );
    end component;

begin

    -- Instancia
    uut: kyber
        port map (
            clk     => clk,
            reset   => reset,
            enable  => enable,
            key     => key,
            data_in => data_in,
            data_out => data_out,
            ready   => ready
        );

    -- Clock
    clk_process: process
    begin
        while now < 5000 ns loop
            clk <= '0'; wait for clk_period / 2;
            clk <= '1'; wait for clk_period / 2;
        end loop;
        wait;
    end process;

    -- Estímulos
    stim_proc: process
    begin
        wait for 20 ns;
        reset <= '0';

        wait for 20 ns;
        key      <= x"00112233445566778899aabbccddeeff";
        data_in  <= x"3243f6a8885a308d313198a2e0370734";
        enable   <= '1';

        wait for 10 ns;
        enable <= '0';

        -- Esperar hasta que el cifrado esté listo
        wait until ready = '1';

        -- Fin de simulación
        wait for 100 ns;
        assert false report "Simulación terminada." severity failure;
    end process;

end sim;
