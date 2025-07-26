library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity crypto_wrapper is
    port(
        clk            : in  std_logic;
        reset          : in  std_logic;
        enable         : in  std_logic;
        select_cipher  : in  std_logic;  -- '0' => AES, '1' => KYBER
        key            : in  std_logic_vector(127 downto 0);
        data_in        : in  std_logic_vector(127 downto 0);
        data_out       : out std_logic_vector(127 downto 0);
        ready          : out std_logic
    );
end crypto_wrapper;

architecture structural of crypto_wrapper is

    -- Señales internas
    signal aes_data_out    : std_logic_vector(127 downto 0);
    signal kyber_data_out  : std_logic_vector(127 downto 0);
    signal aes_ready       : std_logic;
    signal kyber_ready     : std_logic;

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

    -- Instancia Kyber-512 (stub por ahora)
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

    -- Multiplexor de salida
    data_out <= aes_data_out   when select_cipher = '0' else
                kyber_data_out;

    ready    <= aes_ready      when select_cipher = '0' else
                kyber_ready;

end structural;
