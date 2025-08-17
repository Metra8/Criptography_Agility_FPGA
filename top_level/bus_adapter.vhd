library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity bus_adapter is
    port(
        clk           : in  std_logic;
        reset         : in  std_logic;

        -- Interfaz externa de 32 bits - DATA
        ext_data_in   : in  std_logic_vector(31 downto 0);
        ext_valid_in  : in  std_logic;
        ext_ready_out : out std_logic;
        ext_data_out  : out std_logic_vector(31 downto 0);
        ext_valid_out : out std_logic;
        ext_ready_in  : in  std_logic;

        -- Interfaz externa de 32 bits - KEY
        ext_key_in    : in  std_logic_vector(31 downto 0);
        ext_key_valid : in  std_logic;
        ext_key_ready : out std_logic;
        ext_key_out   : out std_logic_vector(31 downto 0);
        ext_key_valid_out : out std_logic;
        ext_key_ready_in  : in  std_logic;

        -- Interfaz interna de 128 bits - DATA
        int_data_in   : in  std_logic_vector(127 downto 0);
        int_valid_in  : in  std_logic;
        int_ready_out : out std_logic;
        int_data_out  : out std_logic_vector(127 downto 0);
        int_valid_out : out std_logic;
        int_ready_in  : in  std_logic;

        -- Interfaz interna de 128 bits - KEY
        int_key_in    : in  std_logic_vector(127 downto 0);
        int_key_valid : in  std_logic;
        int_key_ready : out std_logic;
        int_key_out   : out std_logic_vector(127 downto 0);
        int_key_valid_out : out std_logic;
        int_key_ready_in  : in  std_logic
    );
end bus_adapter;

architecture behavioral of bus_adapter is

    -- Buffers para DATA
    signal rx_buffer_data    : std_logic_vector(127 downto 0) := (others => '0');
    signal rx_word_count_d   : integer range 0 to 3 := 0;
    signal rx_valid_full_d   : std_logic := '0';

    signal tx_buffer_data    : std_logic_vector(127 downto 0) := (others => '0');
    signal tx_word_count_d   : integer range 0 to 3 := 0;
    signal tx_busy_d         : std_logic := '0';

    -- Buffers para KEY
    signal rx_buffer_key     : std_logic_vector(127 downto 0) := (others => '0');
    signal rx_word_count_k   : integer range 0 to 3 := 0;
    signal rx_valid_full_k   : std_logic := '0';

    signal tx_buffer_key     : std_logic_vector(127 downto 0) := (others => '0');
    signal tx_word_count_k   : integer range 0 to 3 := 0;
    signal tx_busy_k         : std_logic := '0';

begin
    --------------------------------------------------------------------
    -- Entrada DATA: ensamblar 4 palabras de 32 bits a 128 bits
    --------------------------------------------------------------------
    process(clk, reset)
    begin
        if reset = '1' then
            rx_buffer_data    <= (others => '0');
            rx_word_count_d   <= 0;
            rx_valid_full_d   <= '0';
            int_valid_out     <= '0';
        elsif rising_edge(clk) then
            if (ext_valid_in = '1') and (rx_valid_full_d = '0') then
                rx_buffer_data(127 - rx_word_count_d*32 downto 96 - rx_word_count_d*32) <= ext_data_in;
                if rx_word_count_d = 3 then
                    rx_valid_full_d <= '1';
                    rx_word_count_d <= 0;
                else
                    rx_word_count_d <= rx_word_count_d + 1;
                end if;
            end if;

            if (rx_valid_full_d = '1') and (int_ready_in = '1') then
                int_data_out  <= rx_buffer_data;
                int_valid_out <= '1';
                rx_valid_full_d <= '0';
            else
                int_valid_out <= '0';
            end if;
        end if;
    end process;

    ext_ready_out <= '1' when rx_valid_full_d = '0' else '0';

    --------------------------------------------------------------------
    -- Entrada KEY: ensamblar 4 palabras de 32 bits a 128 bits
    --------------------------------------------------------------------
    process(clk, reset)
    begin
        if reset = '1' then
            rx_buffer_key    <= (others => '0');
            rx_word_count_k  <= 0;
            rx_valid_full_k  <= '0';
            int_key_valid_out <= '0';
        elsif rising_edge(clk) then
            if (ext_key_valid = '1') and (rx_valid_full_k = '0') then
                rx_buffer_key(127 - rx_word_count_k*32 downto 96 - rx_word_count_k*32) <= ext_key_in;
                if rx_word_count_k = 3 then
                    rx_valid_full_k <= '1';
                    rx_word_count_k <= 0;
                else
                    rx_word_count_k <= rx_word_count_k + 1;
                end if;
            end if;

            if (rx_valid_full_k = '1') and (int_key_ready_in = '1') then
                int_key_out  <= rx_buffer_key;
                int_key_valid_out <= '1';
                rx_valid_full_k <= '0';
            else
                int_key_valid_out <= '0';
            end if;
        end if;
    end process;

    ext_key_ready <= '1' when rx_valid_full_k = '0' else '0';

    --------------------------------------------------------------------
    -- Salida DATA: desensamblar 128 bits a 4 palabras de 32 bits
    --------------------------------------------------------------------
    process(clk, reset)
    begin
        if reset = '1' then
            tx_buffer_data    <= (others => '0');
            tx_word_count_d   <= 0;
            tx_busy_d         <= '0';
            ext_data_out      <= (others => '0');
            ext_valid_out     <= '0';
        elsif rising_edge(clk) then
            if (int_valid_in = '1') and (tx_busy_d = '0') then
                tx_buffer_data <= int_data_in;
                tx_busy_d      <= '1';
                tx_word_count_d <= 0;
                ext_valid_out  <= '1';
                ext_data_out   <= int_data_in(127 downto 96);
            elsif tx_busy_d = '1' then
                if ext_ready_in = '1' then
                    tx_word_count_d <= tx_word_count_d + 1;
                    case tx_word_count_d is
                        when 0 => ext_data_out <= tx_buffer_data(95 downto 64);
                        when 1 => ext_data_out <= tx_buffer_data(63 downto 32);
                        when 2 => ext_data_out <= tx_buffer_data(31 downto 0);
                        when others =>
                            ext_valid_out <= '0';
                            tx_busy_d <= '0';
                    end case;
                end if;
            end if;
        end if;
    end process;

    int_ready_out <= '1' when tx_busy_d = '0' else '0';

    --------------------------------------------------------------------
    -- Salida KEY: desensamblar 128 bits a 4 palabras de 32 bits
    --------------------------------------------------------------------
    process(clk, reset)
    begin
        if reset = '1' then
            tx_buffer_key    <= (others => '0');
            tx_word_count_k  <= 0;
            tx_busy_k        <= '0';
            ext_key_out      <= (others => '0');
            ext_key_valid_out <= '0';
        elsif rising_edge(clk) then
            if (int_key_valid = '1') and (tx_busy_k = '0') then
                tx_buffer_key <= int_key_in;
                tx_busy_k     <= '1';
                tx_word_count_k <= 0;
                ext_key_valid_out <= '1';
                ext_key_out   <= int_key_in(127 downto 96);
            elsif tx_busy_k = '1' then
                if ext_key_ready_in = '1' then
                    tx_word_count_k <= tx_word_count_k + 1;
                    case tx_word_count_k is
                        when 0 => ext_key_out <= tx_buffer_key(95 downto 64);
                        when 1 => ext_key_out <= tx_buffer_key(63 downto 32);
                        when 2 => ext_key_out <= tx_buffer_key(31 downto 0);
                        when others =>
                            ext_key_valid_out <= '0';
                            tx_busy_k <= '0';
                    end case;
                end if;
            end if;
        end if;
    end process;

    int_key_ready <= '1' when tx_busy_k = '0' else '0';

end behavioral;
