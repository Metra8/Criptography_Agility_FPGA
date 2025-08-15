library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity crypto_wrapper is
    port(
        --------------------------------------------------------------------
        -- Señales de sistema
        --------------------------------------------------------------------
        clk                : in  std_logic;
        reset              : in  std_logic;

        --------------------------------------------------------------------
        -- Interfaz externa de datos (32 bits)
        --------------------------------------------------------------------
        ext_data_in        : in  std_logic_vector(31 downto 0);
        ext_valid_in       : in  std_logic;
        ext_ready_out      : out std_logic;
        ext_data_out       : out std_logic_vector(31 downto 0);
        ext_valid_out      : out std_logic;
        ext_ready_in       : in  std_logic;

        --------------------------------------------------------------------
        -- Interfaz externa de clave (32 bits)
        --------------------------------------------------------------------
        ext_key_in         : in  std_logic_vector(31 downto 0);
        ext_key_valid      : in  std_logic;
        ext_key_ready      : out std_logic;
        ext_key_out        : out std_logic_vector(31 downto 0);
        ext_key_valid_out  : out std_logic;
        ext_key_ready_in   : in  std_logic;

        --------------------------------------------------------------------
        -- Señales de control de cripto-agilidad
        --------------------------------------------------------------------
        suspicious         : in  std_logic;
        force_switch       : in  std_logic;
        rand_toggle        : in  std_logic
    );
end crypto_wrapper;


architecture behavioral of crypto_wrapper is

    --------------------------------------------------------------------
    -- Señales internas entre bus_adapter y core AES/Kyber (128 bits)
    --------------------------------------------------------------------
    signal core_data_in    : std_logic_vector(127 downto 0);
    signal core_data_out   : std_logic_vector(127 downto 0);
    signal core_valid_in   : std_logic;
    signal core_ready_out  : std_logic;
    signal core_valid_out  : std_logic;
    signal core_ready_in   : std_logic;

    --------------------------------------------------------------------
    -- Señales internas del core
    --------------------------------------------------------------------
    type k_state_t is (K_IDLE, K_START_KP, K_WAIT_KP, K_WAIT_ENC, K_WAIT_DEC, K_UPDATE_KEY);
    signal k_state : k_state_t := K_IDLE;

    -- AES
    signal aes_data_out : std_logic_vector(127 downto 0);
    signal aes_ready    : std_logic;
    signal aes_key_reg  : std_logic_vector(127 downto 0);

    -- Kyber Keypair
    signal kyber_pk_keypair    : unsigned(127 downto 0);
    signal kyber_sk_keypair    : unsigned(127 downto 0);
    signal kyber_valid_keypair : std_logic;
    signal kyber_start_keypair : std_logic;

    -- Kyber Enc
    signal kyber_ss_enc    : unsigned(127 downto 0);
    signal kyber_ct_enc    : unsigned(127 downto 0);
    signal kyber_valid_enc : std_logic;

    -- Kyber Dec
    signal kyber_ss_dec    : unsigned(127 downto 0);
    signal kyber_ct_dec    : unsigned(127 downto 0);
    signal kyber_valid_dec : std_logic;

    -- Common
    signal current_cipher : std_logic := '0'; -- 0: AES, 1: Kyber
    signal block_count    : integer := 0;

    constant aes   : std_logic := '0';
    constant kyber : std_logic := '1';

    --------------------------------------------------------------------
    -- Señales internas entre bus_adapter y core AES/Kyber (KEY 128 bits)
    --------------------------------------------------------------------
    signal core_key_in        : std_logic_vector(127 downto 0);
    signal core_key_out       : std_logic_vector(127 downto 0);
    signal core_key_valid_in  : std_logic;
    signal core_key_ready_out : std_logic;
    signal core_key_valid_out : std_logic;
    signal core_key_ready_in  : std_logic;


begin

    --------------------------------------------------------------------
    -- Instancia del bus_adapter (32 <-> 128 bits)
    --------------------------------------------------------------------
    bus_inst : entity work.bus_adapter
        port map (
            clk           => clk,
            reset         => reset,

            -- Interfaz externa DATA
            ext_data_in   => ext_data_in,
            ext_valid_in  => ext_valid_in,
            ext_ready_out => ext_ready_out,
            ext_data_out  => ext_data_out,
            ext_valid_out => ext_valid_out,
            ext_ready_in  => ext_ready_in,

            -- Interfaz externa KEY
            ext_key_in    => ext_key_in,
            ext_key_valid => ext_key_valid,
            ext_key_ready => ext_key_ready,
            ext_key_out   => ext_key_out,
            ext_key_valid_out => ext_key_valid_out,
            ext_key_ready_in  => ext_key_ready_in,

            -- Interfaz interna DATA (hacia el core AES/Kyber)
            int_data_in   => core_data_out,
            int_valid_in  => core_valid_out,
            int_ready_out => core_ready_in,
            int_data_out  => core_data_in,
            int_valid_out => core_valid_in,
            int_ready_in  => core_ready_out,

            -- Interfaz interna KEY (hacia el core AES/Kyber)
            int_key_in        => core_key_out,
            int_key_valid     => core_key_valid_out,
            int_key_ready     => core_key_ready_in,
            int_key_out       => core_key_in,
            int_key_valid_out => core_key_valid_in,
            int_key_ready_in  => core_key_ready_out
        );


    --------------------------------------------------------------------
    -- Instancia AES-128
    --------------------------------------------------------------------
    aes_inst : entity work.aes_128
        port map (
            clk      => clk,
            reset    => reset,
            enable   => core_valid_in,
            key      => aes_key_reg,
            data_in  => core_data_in,
            data_out => aes_data_out,
            ready    => aes_ready
        );

    --------------------------------------------------------------------
    -- Instancia Kyber Keypair
    --------------------------------------------------------------------
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

    --------------------------------------------------------------------
    -- Instancia Kyber Encoder
    --------------------------------------------------------------------
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

    --------------------------------------------------------------------
    -- Instancia Kyber Decoder
    --------------------------------------------------------------------
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

    
    --------------------------------------------------------------------
    -- Multiplexor de salida hacia el bus_adapter
    --------------------------------------------------------------------
    core_data_out  <= aes_data_out when current_cipher = aes else std_logic_vector(kyber_ss_enc);
    core_valid_out <= aes_ready    when current_cipher = aes else kyber_valid_enc;
    core_ready_out <= '1'; -- siempre listo para recibir datos del adapter

    --------------------------------------------------------------------
    -- FSM de control de cripto-agilidad
    --------------------------------------------------------------------
    process(clk, reset)
    begin
        if reset = '1' then
            kyber_start_keypair <= '0';
            kyber_ss_enc        <= (others => '0');
            aes_key_reg         <= (others => '0');
            block_count         <= 0;
            k_state             <= K_IDLE;
            current_cipher      <= aes;
        elsif rising_edge(clk) then
            kyber_start_keypair <= '0';

            if (aes_ready = '1') and (k_state = K_IDLE) then
                block_count <= block_count + 1;
            end if;

            case k_state is
                when K_IDLE =>
                    current_cipher <= aes;
                    if core_valid_in = '1' then
                        if (force_switch = '1') or (suspicious = '1') or (block_count >= 1000) or (rand_toggle = '1') then
                            kyber_start_keypair <= '1';
                            k_state <= K_WAIT_KP;
                        end if;
                    end if;

                when K_WAIT_KP =>
                    current_cipher <= kyber;
                    if kyber_valid_keypair = '1' then
                        kyber_ss_enc <= unsigned(core_data_in);
                        k_state <= K_WAIT_ENC;
                    end if;

                when K_WAIT_ENC =>
                    current_cipher <= kyber;
                    if kyber_valid_enc = '1' then
                        k_state <= K_WAIT_DEC;
                    end if;

                when K_WAIT_DEC =>
                    current_cipher <= kyber;
                    if kyber_valid_dec = '1' then
                        k_state <= K_UPDATE_KEY;
                    end if;

                when K_UPDATE_KEY =>
                    aes_key_reg <= std_logic_vector(kyber_ss_dec(127 downto 0));
                    block_count <= 0;
                    k_state <= K_IDLE;

                when others =>
                    k_state <= K_IDLE;
            end case;
        end if;
    end process;

end behavioral;
