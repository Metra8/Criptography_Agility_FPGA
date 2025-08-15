library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity crypto_wrapper is
    port(
        clk            : in  std_logic;
        reset          : in  std_logic;
        enable         : in  std_logic;
        -- Interfaz multiplexada (32 bits en lugar de 128)
        key            : in  std_logic_vector(31 downto 0);
        data_in        : in  std_logic_vector(31 downto 0);
        key_valid      : in  std_logic;    -- indica que key[31:0] es válido
        data_valid     : in  std_logic;    -- indica que data_in[31:0] es válido
        key_ready      : out std_logic;    -- solicita siguiente parte de key
        data_ready     : out std_logic;    -- solicita siguiente parte de data_in
        
        suspicious     : in  std_logic;
        force_switch   : in  std_logic;
        rand_toggle    : in  std_logic;
        
        -- Salida multiplexada
        data_out       : out std_logic_vector(31 downto 0);
        data_out_valid : out std_logic;    -- indica que data_out[31:0] es válido
        data_out_ready : in  std_logic;    -- el receptor está listo para el siguiente
        ready          : out std_logic
    );
end crypto_wrapper;

architecture behavioral of crypto_wrapper is

    type k_state_t is (K_IDLE, K_START_KP, K_WAIT_KP, K_SEND_SS, K_WAIT_ENC, K_WAIT_DEC, K_UPDATE_KEY);
    signal k_state : k_state_t := K_IDLE;   

    -- Registros internos completos (128 bits) - NO CAMBIA LA LÓGICA INTERNA
    signal key_internal      : std_logic_vector(127 downto 0);
    signal data_in_internal  : std_logic_vector(127 downto 0);
    signal data_out_internal : std_logic_vector(127 downto 0);
    signal ready_internal    : std_logic;

    -- Contadores para multiplexación
    signal key_count      : integer range 0 to 3 := 0;      -- 0 a 3 para 4 transferencias de 32 bits
    signal data_in_count  : integer range 0 to 3 := 0;
    signal data_out_count : integer range 0 to 3 := 0;
    
    -- Estados de recepción
    signal key_complete      : std_logic := '0';
    signal data_in_complete  : std_logic := '0';
    signal enable_internal   : std_logic := '0';

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
    -- LÓGICA DE MULTIPLEXACIÓN DE ENTRADA
    ---------------------------------------------------------------------------
    
    -- Recepción de key (128 bits en 4 transferencias de 32 bits)
    process(clk, reset)
    begin
        if reset = '1' then
            key_count <= 0;
            key_complete <= '0';
            key_internal <= (others => '0');
            key_ready <= '1';  -- listo para recibir primera parte
        elsif rising_edge(clk) then
            if key_valid = '1' and key_ready = '1' then
                case key_count is
                    when 0 => key_internal(31 downto 0)   <= key; key_count <= 1;
                    when 1 => key_internal(63 downto 32)  <= key; key_count <= 2;
                    when 2 => key_internal(95 downto 64)  <= key; key_count <= 3;
                    when 3 => key_internal(127 downto 96) <= key; key_count <= 0; key_complete <= '1';
                end case;
            end if;
            
            -- Manejar ready signal
            if key_count = 3 and key_valid = '1' then
                key_ready <= '0';  -- no más datos hasta próximo reset/ciclo
            elsif key_count < 3 then
                key_ready <= '1';  -- listo para siguiente parte
            end if;
        end if;
    end process;

    -- Recepción de data_in (128 bits en 4 transferencias de 32 bits)
    process(clk, reset)
    begin
        if reset = '1' then
            data_in_count <= 0;
            data_in_complete <= '0';
            data_in_internal <= (others => '0');
            data_ready <= '1';
        elsif rising_edge(clk) then
            if data_valid = '1' and data_ready = '1' then
                case data_in_count is
                    when 0 => data_in_internal(31 downto 0)   <= data_in; data_in_count <= 1;
                    when 1 => data_in_internal(63 downto 32)  <= data_in; data_in_count <= 2;
                    when 2 => data_in_internal(95 downto 64)  <= data_in; data_in_count <= 3;
                    when 3 => data_in_internal(127 downto 96) <= data_in; data_in_count <= 0; data_in_complete <= '1';
                end case;
            end if;
            
            if data_in_count = 3 and data_valid = '1' then
                data_ready <= '0';
            elsif data_in_count < 3 then
                data_ready <= '1';
            end if;

            -- Reset complete flags cuando empezamos nuevo procesamiento
            if enable_internal = '1' and ready_internal = '1' then
                data_in_complete <= '0';
                data_ready <= '1';
                data_in_count <= 0;
            end if;
        end if;
    end process;

    -- Enable interno solo cuando ambos buses están completos
    enable_internal <= enable and key_complete and data_in_complete;

    ---------------------------------------------------------------------------
    -- LÓGICA DE MULTIPLEXACIÓN DE SALIDA
    ---------------------------------------------------------------------------
    
    process(clk, reset)
    begin
        if reset = '1' then
            data_out_count <= 0;
            data_out_valid <= '0';
            data_out <= (others => '0');
        elsif rising_edge(clk) then
            -- Cuando tenemos resultado interno listo, empezar transmisión
            if ready_internal = '1' and data_out_count = 0 and data_out_valid = '0' then
                data_out_internal <= aes_data_out when current_cipher = aes else std_logic_vector(kyber_ss_enc);
                data_out <= data_out_internal(31 downto 0);
                data_out_valid <= '1';
            -- Continuar transmisión si receptor está listo
            elsif data_out_valid = '1' and data_out_ready = '1' then
                if data_out_count < 3 then
                    data_out_count <= data_out_count + 1;
                    case data_out_count + 1 is
                        when 1 => data_out <= data_out_internal(63 downto 32);
                        when 2 => data_out <= data_out_internal(95 downto 64);
                        when 3 => data_out <= data_out_internal(127 downto 96);
                        when others => data_out <= (others => '0');
                    end case;
                else
                    -- Transmisión completa
                    data_out_count <= 0;
                    data_out_valid <= '0';
                end if;
            end if;
        end if;
    end process;

    ---------------------------------------------------------------------------
    -- INSTANCIAS - SIN CAMBIOS
    ---------------------------------------------------------------------------

    -- instancia AES-128
    aes_inst : entity work.aes_128
        port map (
            clk      => clk,
            reset    => reset,
            enable   => enable_internal,  -- usar enable_internal
            key      => key_internal,     -- usar key_internal
            data_in  => data_in_internal, -- usar data_in_internal
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
    -- LÓGICA PRINCIPAL - SIN CAMBIOS (excepto usar señales internas)
    ---------------------------------------------------------------------------

    -- Multiplexor de salida según cifrado
    ready_internal <= aes_ready when current_cipher = aes else kyber_valid_enc;
    ready <= '1' when (ready_internal = '1' and data_out_count = 3 and data_out_valid = '1' and data_out_ready = '1') 
                   or (ready_internal = '0') else '0';

    -- Lógica de selección dinámica de cifrado - SIN CAMBIOS
    process(clk, reset, key_internal)  -- usar key_internal
    begin
        if reset = '1' then
            kyber_start_keypair <= '0';
            kyber_ss_enc        <= (others => '0');
            aes_key_reg         <= key_internal;   -- usar key_internal
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
                    if enable_internal = '1' then  -- usar enable_internal
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
                        kyber_ss_enc <= unsigned(data_in_internal);  -- usar data_in_internal
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

    -- Conectar ct_dec con ct_enc para el decoder
    kyber_ct_dec <= kyber_ct_enc;

end behavioral;
