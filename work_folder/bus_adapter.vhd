library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity bus_adapter is
    port(
        clk           : in  std_logic;
        reset         : in  std_logic;

        -- Interfaz externa de 32 bits
        ext_data_in   : in  std_logic_vector(31 downto 0);
        ext_valid_in  : in  std_logic;
        ext_ready_out : out std_logic;
        ext_data_out  : out std_logic_vector(31 downto 0);
        ext_valid_out : out std_logic;
        ext_ready_in  : in  std_logic;

        -- Interfaz interna de 128 bits
        int_data_in   : in  std_logic_vector(127 downto 0);
        int_valid_in  : in  std_logic;
        int_ready_out : out std_logic;
        int_data_out  : out std_logic_vector(127 downto 0);
        int_valid_out : out std_logic;
        int_ready_in  : in  std_logic
    );
end bus_adapter;

architecture behavioral of bus_adapter is

    -- Buffers internos para ensamblar/desensamblar
    signal rx_buffer       : std_logic_vector(127 downto 0) := (others => '0');
    signal rx_word_count   : integer range 0 to 3 := 0;
    signal rx_valid_full   : std_logic := '0';

    signal tx_buffer       : std_logic_vector(127 downto 0) := (others => '0');
    signal tx_word_count   : integer range 0 to 3 := 0;
    signal tx_busy         : std_logic := '0';

    -- Señales espejo para puertos de entrada
    signal ext_ready_in_sig  : std_logic;
    signal ext_valid_out_sig : std_logic;

begin
    --------------------------------------------------------------------
    -- Entrada: ensamblar 4 palabras de 32 bits a 128 bits
    --------------------------------------------------------------------
    process(clk, reset)
    begin
        if reset = '1' then
            rx_buffer     <= (others => '0');
            rx_word_count <= 0;
            rx_valid_full <= '0';
        elsif rising_edge(clk) then
            if (ext_valid_in = '1') and (rx_valid_full = '0') then
                rx_buffer(127 - rx_word_count*32 downto 96 - rx_word_count*32) <= ext_data_in;
                if rx_word_count = 3 then
                    rx_valid_full <= '1';
                    rx_word_count <= 0;
                else
                    rx_word_count <= rx_word_count + 1;
                end if;
            end if;

            -- Transferencia hacia el core
            if (rx_valid_full = '1') and (int_ready_in = '1') then
                int_data_out  <= rx_buffer;
                int_valid_out <= '1';
                rx_valid_full <= '0';
            else
                int_valid_out <= '0';
            end if;
        end if;
    end process;

    ext_ready_out <= '1' when rx_valid_full = '0' else '0';

    --------------------------------------------------------------------
    -- Salida: desensamblar 128 bits a 4 palabras de 32 bits
    --------------------------------------------------------------------
    process(clk, reset)
    begin
        if reset = '1' then
            tx_buffer     <= (others => '0');
            tx_word_count <= 0;
            tx_busy       <= '0';
            ext_data_out  <= (others => '0');
            ext_valid_out <= '0';
        elsif rising_edge(clk) then
            -- Cargar nuevo bloque desde el core
            if (int_valid_in = '1') and (tx_busy = '0') then
                tx_buffer <= int_data_in;
                tx_busy   <= '1';
                tx_word_count <= 0;
                ext_valid_out <= '1';
                ext_data_out  <= int_data_in(127 downto 96);
            elsif tx_busy = '1' then
                if ext_ready_in = '1' then
                    tx_word_count <= tx_word_count + 1;
                    case tx_word_count is
                        when 0 => ext_data_out <= tx_buffer(95 downto 64);
                        when 1 => ext_data_out <= tx_buffer(63 downto 32);
                        when 2 => ext_data_out <= tx_buffer(31 downto 0);
                        when others =>
                            ext_valid_out <= '0';
                            tx_busy <= '0';
                    end case;
                end if;
            end if;
        end if;
    end process;

    int_ready_out <= '1' when tx_busy = '0' else '0';

end behavioral;
