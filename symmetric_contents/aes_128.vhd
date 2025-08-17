LIBRARY IEEE;
USE IEEE.std_logic_1164.all;
USE IEEE.numeric_std.all;
USE work.sbox_pkg.all;
USE work.key_expansion_pkg.all;
USE work.aes_transform_pkg.all;

entity aes_128 is
    Port(
        clk         : in std_logic;
        reset       : in std_logic;
        enable      : in std_logic;
        key         : in std_logic_vector(127 downto 0);
        data_in     : in std_logic_vector(127 downto 0);
        data_out    : out std_logic_vector(127 downto 0);
        ready       : out std_logic
    );
end aes_128;

architecture behavioral of aes_128 is

    -- Estados simples: solo IDLE y PROCESSING
    type state_type is (IDLE, PROCESSING, DONE);
    signal state : state_type := IDLE;

    -- Expansión de clave (se hace una sola vez)
    signal round_keys : key_array_t;
    
    -- Pipeline de rondas - cada señal representa el estado después de cada ronda
    signal round_0_out  : std_logic_vector(127 downto 0);  -- Después de AddRoundKey inicial
    signal round_1_out  : std_logic_vector(127 downto 0);  -- Después de ronda 1
    signal round_2_out  : std_logic_vector(127 downto 0);  -- Después de ronda 2
    signal round_3_out  : std_logic_vector(127 downto 0);  -- Después de ronda 3
    signal round_4_out  : std_logic_vector(127 downto 0);  -- Después de ronda 4
    signal round_5_out  : std_logic_vector(127 downto 0);  -- Después de ronda 5
    signal round_6_out  : std_logic_vector(127 downto 0);  -- Después de ronda 6
    signal round_7_out  : std_logic_vector(127 downto 0);  -- Después de ronda 7
    signal round_8_out  : std_logic_vector(127 downto 0);  -- Después de ronda 8
    signal round_9_out  : std_logic_vector(127 downto 0);  -- Después de ronda 9
    signal final_out    : std_logic_vector(127 downto 0);  -- Ronda final (sin MixColumns)

    -- Función para procesar una ronda completa (SubBytes + ShiftRows + MixColumns + AddRoundKey)
    function aes_round(
        input_state : std_logic_vector(127 downto 0);
        round_key   : std_logic_vector(127 downto 0)
    ) return std_logic_vector is
        variable sub_bytes_result : std_logic_vector(127 downto 0);
        variable shift_rows_result : std_logic_vector(127 downto 0);
        variable mix_columns_result : std_logic_vector(127 downto 0);
        variable final_result : std_logic_vector(127 downto 0);
    begin
        -- 1. SubBytes
        for i in 0 to 15 loop
            sub_bytes_result(8*i+7 downto 8*i) := sbox(input_state(8*i+7 downto 8*i));
        end loop;
        
        -- 2. ShiftRows
        shift_rows_result := ShiftRows(sub_bytes_result);
        
        -- 3. MixColumns
        mix_columns_result := MixColumns(shift_rows_result);
        
        -- 4. AddRoundKey
        final_result := mix_columns_result xor round_key;
        
        return final_result;
    end function;

    -- Función para la ronda final (SubBytes + ShiftRows + AddRoundKey, sin MixColumns)
    function aes_final_round(
        input_state : std_logic_vector(127 downto 0);
        round_key   : std_logic_vector(127 downto 0)
    ) return std_logic_vector is
        variable sub_bytes_result : std_logic_vector(127 downto 0);
        variable shift_rows_result : std_logic_vector(127 downto 0);
        variable final_result : std_logic_vector(127 downto 0);
    begin
        -- 1. SubBytes
        for i in 0 to 15 loop
            sub_bytes_result(8*i+7 downto 8*i) := sbox(input_state(8*i+7 downto 8*i));
        end loop;
        
        -- 2. ShiftRows
        shift_rows_result := ShiftRows(sub_bytes_result);
        
        -- 3. AddRoundKey (sin MixColumns)
        final_result := shift_rows_result xor round_key;
        
        return final_result;
    end function;

begin

    -- Proceso principal
    process(clk, reset)
    begin
        if reset = '1' then
            state <= IDLE;
            ready <= '0';
            data_out <= (others => '0');
            
        elsif rising_edge(clk) then
            case state is
                when IDLE =>
                    ready <= '0';
                    if enable = '1' then
                        state <= PROCESSING;
                    end if;
                    
                when PROCESSING =>
                    -- Toda la lógica AES se ejecuta en paralelo en este ciclo
                    state <= DONE;
                    
                when DONE =>
                    ready <= '1';
                    data_out <= final_out;
                    state <= IDLE;
                    
                when others =>
                    state <= IDLE;
            end case;
        end if;
    end process;

    -- **LÓGICA COMPLETAMENTE PARALELA**
    -- Toda esta lógica se ejecuta combinacionalmente (en paralelo)
    
    -- Expansión de clave (combinacional)
    round_keys <= key_expansion(key);
    
    -- Ronda inicial: AddRoundKey con clave original
    round_0_out <= data_in xor round_keys(0);
    
    -- Rondas 1-9: SubBytes + ShiftRows + MixColumns + AddRoundKey
    round_1_out <= aes_round(round_0_out, round_keys(1));
    round_2_out <= aes_round(round_1_out, round_keys(2));
    round_3_out <= aes_round(round_2_out, round_keys(3));
    round_4_out <= aes_round(round_3_out, round_keys(4));
    round_5_out <= aes_round(round_4_out, round_keys(5));
    round_6_out <= aes_round(round_5_out, round_keys(6));
    round_7_out <= aes_round(round_6_out, round_keys(7));
    round_8_out <= aes_round(round_7_out, round_keys(8));
    round_9_out <= aes_round(round_8_out, round_keys(9));
    
    -- Ronda final (sin MixColumns)
    final_out <= aes_final_round(round_9_out, round_keys(10));

end behavioral;
