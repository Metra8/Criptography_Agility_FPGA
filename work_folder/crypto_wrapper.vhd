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


    type k_state_t is (K_IDLE, K_START_KP, K_WAIT_KP, K_SEND_SS, K_WAIT_ENC, K_WAIT_DEC, K_UPDATE_KEY);
    signal k_state : k_state_t := K_IDLE;   


    --aes
    signal aes_data_out    : std_logic_vector(127 downto 0);
    signal aes_ready       : std_logic;
    signal aes_key_reg : std_logic_vector(127 downto 0);


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


    --kyber_ct_enc <= (others => '0');
    --kyber_ct_dec <= kyber_ct_enc;
    --kyber_ss_enc <= (others => '0');




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


    process(clk, reset, key)
    begin
        if reset = '1' then
            kyber_start_keypair <= '0';
            kyber_ss_enc        <= (others => '0');
            aes_key_reg         <= key;   -- seed AES key from external port on reset
            block_count         <= 0;
            k_state             <= K_IDLE;
            current_cipher      <= aes;
        elsif rising_edge(clk) then
            -- default: deassert one-cycle pulses / keep previous values where appropriate
            kyber_start_keypair <= '0';

            -- increment block counter when AES produced a block and we are idle (not renegotiating)
            if (aes_ready = '1') and (k_state = K_IDLE) then
                block_count <= block_count + 1;
            end if;

            -- FSM transitions and actions
            case k_state is
                when K_IDLE =>
                    current_cipher <= aes;
                    if enable = '1' then
                        if (force_switch = '1') or (suspicious = '1') or (block_count >= 1000) or (rand_toggle = '1') then
                            -- start the keypair generation (pulse start)
                            kyber_start_keypair <= '1';
                            k_state <= K_WAIT_KP;
                        end if;
                    end if;

                when K_WAIT_KP =>
                    -- waiting for keypair generator to assert valid
                    current_cipher <= kyber;
                    if kyber_valid_keypair = '1' then
                        -- provide SS to encoder: here we choose data_in as SS for the stub
                        -- (in real implementation use RNG/KDF)
                        kyber_ss_enc <= unsigned(data_in);
                        k_state <= K_WAIT_ENC;
                    end if;

                when K_WAIT_ENC =>
                    current_cipher <= kyber;
                    -- wait for encoder to assert valid and produce ct
                    if kyber_valid_enc = '1' then
                        -- ciphertext forwarded concurrently to decoder
                        k_state <= K_WAIT_DEC;
                    end if;

                when K_WAIT_DEC =>
                    current_cipher <= kyber;
                    if kyber_valid_dec = '1' then
                        k_state <= K_UPDATE_KEY;
                    end if;

                when K_UPDATE_KEY =>
                    -- update AES key from kyber_ss_dec (lower 128 bits)
                    aes_key_reg <= std_logic_vector(kyber_ss_dec(127 downto 0));
                    block_count <= 0;  -- reset usage counter after key rotation
                    k_state <= K_IDLE;

                when others =>
                    k_state <= K_IDLE;
            end case;
        end if;
    end process;


end behavioral;
