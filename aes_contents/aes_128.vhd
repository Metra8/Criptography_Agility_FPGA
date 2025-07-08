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
        --entradas y salidas del sbox respectivamente
        sbox_addr   : out std_logic_vector(7 downto 0);
        sbox_data   : in std_logic_vector(7 downto 0);
        data_out    : out std_logic_vector(127 downto 0);
        ready       : out std_logic
    );

end aes_128;


architecture behavioral of aes_128 is



    --hacemos una máquina de estados
    type state_type is (
        IDLE,
        KEY_EXPAND,
        INIT_ROUND,
        SUB_BYTES,
        SHIFT_ROWS,
        MIX_COLUMNS,
        ADD_ROUND_KEY,
        FINAL_ROUND,
        DONE
    );

    signal state : state_type := IDLE;

    --registros internos
    signal round_key        : std_logic_vector(127 downto 0);
    signal state_reg        : std_logic_vector(127 downto 0);
    signal round_keys       : key_array_t;
    signal round_counter    : integer range 0 to 10 := 0;

    --búferes
    signal subbytes_out     : std_logic_vector(127 downto 0);
    signal shiftrows_out    : std_logic_vector(127 downto 0);
    signal mixcolumns_out   : std_logic_vector(127 downto 0);


begin

    process(clk, reset)
    begin
        if reset = '1' then
            state <= IDLE;
            state_reg <= (others => '0');
            round_counter <= 0;
            ready <= '0';
        elsif rising_edge(clk) then
            case state is
                when IDLE =>
                    if enable = '1' then
                        state_reg <= data_in;
                        round_counter <= 0;
                        state <= KEY_EXPAND;
                    end if;
                
                when KEY_EXPAND =>
                    --lógica expansión de clave
                    round_keys <= key_expansion(key);
                    state <= INIT_ROUND;
                
                when INIT_ROUND =>
                    state_reg <= state_reg xor round_keys(0);
                    round_counter <= 1;
                    state <= SUB_BYTES;

                when SUB_BYTES =>
                    --lógica subbytes usando sbox externa
                    for i in 0 to 15 loop
                        --pasar 8 bits (un Byte) por iteración a la sbox
                        subbytes_out <= sbox(state_reg(8*i+7 downto 8*i));
                    end loop;
                    state <= SHIFT_ROWS;

                when SHIFT_ROWS =>
                    --lógica shift_rows
                    shiftrows_out <= ShiftRows(subbytes_out);

                    state <= MIX_COLUMNS;
                
                when MIX_COLUMNS =>
                    --lógica mix_columns
                    mixcolumns_out <= MixColumns(shiftrows_out);
                    state <= ADD_ROUND_KEY;

                when ADD_ROUND_KEY =>
                    state_reg <= mixcolumns_out xor round_keys (round_counter);
                    round_counter <= round_counter + 1;

                    if round_counter = 10 then
                        state <= FINAL_ROUND;
                    else
                        state <= SUB_BYTES;
                    end if;

                when FINAL_ROUND =>
                    --lo mismo pero sin mixcolumns
                    --subbytes
                    for i in 0 to 15 loop
                        --pasar 8 bits (un Byte) por iteración a la sbox
                        subbytes_out <= sbox(state_reg(8*i+7 downto 8*i));
                    end loop;
                    --shift rows
                    shiftrows_out <= ShiftRows(subbytes_out);
                    --sin mix columns
                    --add round key
                    state_reg <= mixcolumns_out xor round_keys (round_counter);
                    round_counter <= round_counter + 1;

                    state <= DONE;

                when DONE =>
                    data_out <= state_reg;
                    ready <= '1';
                    state <= IDLE;
                
                when others =>
                    state <= IDLE;
            end case;
        end if;
    end process;




end behavioral;
