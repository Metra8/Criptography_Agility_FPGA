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


    --aes
    signal aes_data_out    : std_logic_vector(127 downto 0);
    signal aes_ready       : std_logic;


    -- Kyber Keypair
    signal kyber_pk_keypair    : unsigned(127 downto 0);
    signal kyber_sk_keypair    : unsigned(127 downto 0);
    signal kyber_valid_keypair : std_logic;
    signal kyber_start_keypair : std_logic;
    
    
    -- Kyber Enc
    signal kyber_ss_enc        : unsigned(127 downto 0);
    signal kyber_ct_enc        : unsigned(127 downto 0);
    signal kyber_valid_enc     : std_logic;
    
    
    
    -- Kyber Dec
    signal kyber_ss_dec        : unsigned(127 downto 0);
    signal kyber_ct_dec        : unsigned(127 downto 0);
    signal kyber_valid_dec     : std_logic;


    --common
    signal current_cipher  : std_logic := '0'; -- '0': AES, '1': Kyber
    signal block_count     : integer := 0;

    constant aes           : std_logic := '0';
    constant kyber         : std_logic := '1';

begin


    ---------------------------------------------------------------------------

    -- instancia AES-128
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

    -- instancias Kyber-512--
    --keypair
    kyber_keypair_inst : entity work.kyber_512_keypair
    generic map (
        PK_BITS => 128,
        SK_BITS => 128
    )

    port map (
        clk   => clk,
        reset => reset,
        start => kyber_start_keypair,
        pk    => kyber_pk_keypair,
        sk    => kyber_sk_keypair,
        valid => kyber_valid_keypair
    );

    --encoder
    kyber_enc_inst : entity work.kyber_512_enc
    generic map (
        SS_BITS => 128,
        PK_BITS => 128,
        CT_BITS => 128
    )
    port map (
        clk   => clk,
        reset => reset,
        ss    => kyber_ss_enc,
        pk    => kyber_pk_keypair,
        valid => kyber_valid_enc,
        ct    => kyber_ct_enc
    );

    --decoder
    kyber_dec_inst : entity work.kyber_512_dec
    generic map (
        CT_BITS => 128,
        SK_BITS => 128,
        SS_BITS => 128
    )
    port map (
        clk   => clk,
        reset => reset,
        ct    => kyber_ct_dec,
        sk    => kyber_sk_keypair,
        valid => kyber_valid_dec,
        ss    => kyber_ss_dec
    );

    ---------------------------------------------------------------------------

        -- Multiplexor de salida según cifrado
    data_out <= aes_data_out when current_cipher = aes else std_logic_vector(kyber_ss_enc);
    ready    <= aes_ready    when current_cipher = aes else kyber_valid_enc;

    -- Lógica de selección dinámica de cifrado

    -- Reglas de cambio de algoritmo:
    -- 1. cambiar a Kyber si force_switch='1', suspicious='1' o block_count >= 1000.
    -- 2. cambio aleatorio si rand_toggle='1'.
    -- 3. volver a AES si usando Kyber y block_count >= 200.
    -- AES es el algoritmo por defecto tras reset.


    process(clk)
    begin
        if rising_edge(clk) then
            if reset = '1' then
                current_cipher      <= aes;  -- AES por defecto
                block_count         <= 0;
                kyber_start_keypair <= '0';
            elsif enable = '1' then

                -- contador
                if current_cipher = aes and aes_ready = '1' then
                    block_count <= block_count + 1;
                elsif current_cipher = kyber and kyber_valid_enc = '1' then
                    block_count <= block_count + 1;
                end if;

                -- reglas de cambio
                if force_switch = '1' or suspicious = '1' then
                    current_cipher      <= kyber;
                    kyber_start_keypair <= '1';
                    block_count         <= 0;
                elsif block_count >= 1000 then
                    current_cipher      <= kyber; -- seguridad
                    kyber_start_keypair <= '1';
                    block_count         <= 0;
                elsif rand_toggle = '1' then
                    current_cipher      <= not current_cipher; -- cambio aleatorio
                    if current_cipher = aes then
                        kyber_start_keypair <= '1';
                    else
                        kyber_start_keypair <= '0';
                    end if;
                    block_count         <= 0;
                elsif current_cipher = kyber and block_count >= 200 then
                    current_cipher      <= aes;
                    block_count         <= 0;
                end if;
            end if;
        end if;
    end process;



end behavioral;
