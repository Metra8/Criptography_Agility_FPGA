library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity crypto_wrapper is
    port(
        clk            : in  std_logic;
        reset          : in  std_logic;
        enable         : in  std_logic;
        key            : in  std_logic_vector(127 downto 0);
        data_in        : in  std_logic_vector(127 downto 0);
        suspicious     : in  std_logic;
        force_switch   : in  std_logic;
        rand_toggle    : in  std_logic;
        data_out       : out std_logic_vector(127 downto 0);
        ready          : out std_logic
    );
end crypto_wrapper;

architecture behavioral of crypto_wrapper is


    signal aes_data_out    : std_logic_vector(127 downto 0);
    signal kyber_data_out  : std_logic_vector(127 downto 0);
    signal aes_ready       : std_logic;
    signal kyber_ready     : std_logic;

    signal current_cipher  : std_logic := '0'; -- '0': AES, '1': Kyber
    signal block_count     : integer := 0;

    constant aes           : std_logic := '0';
    constant kyber         : std_logic := '1';

begin

    -- Instancia AES-128
    aes_inst : entity work.aes_128
        port map (
            clk      => clk,
            reset    => reset,
            enable   => enable,
            key      => key,
            data_in  => data_in,
            data_out => aes_data_out,
            ready    => aes_ready
        );

    -- Instancia Kyber-512
    kyber_inst : entity work.kyber_512
        port map (
            clk      => clk,
            reset    => reset,
            enable   => enable,
            key      => key,
            data_in  => data_in,
            data_out => kyber_data_out,
            ready    => kyber_ready
        );

    -- Multiplexor de salida según cifrado
    data_out <= aes_data_out when current_cipher = aes else kyber_data_out;
    ready    <= aes_ready    when current_cipher = aes else kyber_ready;

    -- Lógica de selección dinámica de cifrado
    process(clk)
    begin
        if rising_edge(clk) then
            if reset = '1' then
                current_cipher <= aes;  -- AES por defecto
                block_count    <= 0;
            elsif enable = '1' then
                -- Actualiza contador si ready está a '1'
                if current_cipher = aes and aes_ready = '1' then
                    block_count <= block_count + 1;
                elsif current_cipher = kyber and kyber_ready = '1' then
                    block_count <= block_count + 1;
                end if;

                -- Reglas de cambio
                if force_switch = '1' or suspicious = '1' then
                    current_cipher <= kyber;
                    block_count    <= 0;
                elsif block_count >= 1000 then
                    current_cipher <= kyber; --seguridad
                    block_count    <= 0;
                elsif rand_toggle = '1' then
                    current_cipher <= not current_cipher;  -- Cambio aleatorio
                    block_count    <= 0;
                elsif current_cipher = kyber and block_count >= 200 then
                    current_cipher <= aes;  -- vuelve a AES
                    block_count    <= 0;
                end if;
            end if;
        end if;
    end process;

end behavioral;
