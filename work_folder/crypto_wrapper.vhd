library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity crypto_wrapper is
    port(
        clk            : in  std_logic;
        reset          : in  std_logic;
        
        -- Interfaz serie para datos (32 bits por transferencia)
        data_in        : in  std_logic_vector(31 downto 0);
        data_valid     : in  std_logic;
        data_ready     : out std_logic;
        
        -- Interfaz serie para clave (32 bits por transferencia)  
        key_in         : in  std_logic_vector(31 downto 0);
        key_valid      : in  std_logic;
        key_ready      : out std_logic;
        
        -- Salida serie (32 bits por transferencia)
        data_out       : out std_logic_vector(31 downto 0);
        output_valid   : out std_logic;
        output_ready   : in  std_logic;
        
        -- Señales de control
        enable         : in  std_logic;
        suspicious     : in  std_logic;
        force_switch   : in  std_logic;
        rand_toggle    : in  std_logic;
        
        -- Estado
        ready          : out std_logic;
        busy           : out std_logic
    );
end crypto_wrapper;

architecture behavioral of crypto_wrapper is

    -- Registros internos completos
    signal data_reg     : std_logic_vector(127 downto 0);
    signal key_reg      : std_logic_vector(127 downto 0);
    signal output_reg   : std_logic_vector(127 downto 0);
    
    -- Contadores para transferencia serie
    signal data_count   : integer range 0 to 3 := 0;
    signal key_count    : integer range 0 to 3 := 0;
    signal output_count : integer range 0 to 3 := 0;
    
    -- Estados del protocolo serie
    type serial_state_t is (IDLE, LOADING_DATA, LOADING_KEY, PROCESSING, SENDING_OUTPUT);
    signal state : serial_state_t := IDLE;
    
    -- Instancia del crypto_wrapper original (renombrado para evitar conflicto)
    signal crypto_enable    : std_logic;
    signal crypto_data_out  : std_logic_vector(127 downto 0);
    signal crypto_ready     : std_logic;

begin

    -- Lógica de control serie
    process(clk, reset)
    begin
        if reset = '1' then
            data_reg <= (others => '0');
            key_reg <= (others => '0');
            output_reg <= (others => '0');
            data_count <= 0;
            key_count <= 0;
            output_count <= 0;
            state <= IDLE;
            crypto_enable <= '0';
            
        elsif rising_edge(clk) then
            -- Defaults
            crypto_enable <= '0';
            data_ready <= '0';
            key_ready <= '0';
            output_valid <= '0';
            ready <= '0';
            busy <= '1';
            
            case state is
                when IDLE =>
                    ready <= '1';
                    busy <= '0';
                    if enable = '1' then
                        state <= LOADING_KEY;
                        key_count <= 0;
                    end if;
                    
                when LOADING_KEY =>
                    key_ready <= '1';
                    if key_valid = '1' then
                        -- Cargar 32 bits de la clave
                        case key_count is
                            when 0 => key_reg(31 downto 0) <= key_in;
                            when 1 => key_reg(63 downto 32) <= key_in;
                            when 2 => key_reg(95 downto 64) <= key_in;
                            when 3 => key_reg(127 downto 96) <= key_in;
                        end case;
                        
                        if key_count = 3 then
                            state <= LOADING_DATA;
                            data_count <= 0;
                        else
                            key_count <= key_count + 1;
                        end if;
                    end if;
                    
                when LOADING_DATA =>
                    data_ready <= '1';
                    if data_valid = '1' then
                        -- Cargar 32 bits de datos
                        case data_count is
                            when 0 => data_reg(31 downto 0) <= data_in;
                            when 1 => data_reg(63 downto 32) <= data_in;
                            when 2 => data_reg(95 downto 64) <= data_in;
                            when 3 => data_reg(127 downto 96) <= data_in;
                        end case;
                        
                        if data_count = 3 then
                            state <= PROCESSING;
                            crypto_enable <= '1';
                        else
                            data_count <= data_count + 1;
                        end if;
                    end if;
                    
                when PROCESSING =>
                    if crypto_ready = '1' then
                        output_reg <= crypto_data_out;
                        output_count <= 0;
                        state <= SENDING_OUTPUT;
                    end if;
                    
                when SENDING_OUTPUT =>
                    output_valid <= '1';
                    if output_ready = '1' then
                        -- Enviar 32 bits de salida
                        case output_count is
                            when 0 => data_out <= output_reg(31 downto 0);
                            when 1 => data_out <= output_reg(63 downto 32);
                            when 2 => data_out <= output_reg(95 downto 64);
                            when 3 => data_out <= output_reg(127 downto 96);
                        end case;
                        
                        if output_count = 3 then
                            state <= IDLE;
                        else
                            output_count <= output_count + 1;
                        end if;
                    end if;
                    
            end case;
        end if;
    end process;

end behavioral;
