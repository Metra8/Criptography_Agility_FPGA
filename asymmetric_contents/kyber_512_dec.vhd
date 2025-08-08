-------------------------------------------------------------------------------
-- Name: kyber_512_dec
--
-- Description: entity that performs decryption in ML-KEM-512.
--
-- Inputs:
--      - clk: clock.
--      - reset: async reset.
--      - ct: ciphertext.
-- Outputs:
--      - valid: indicates the output data is valid.
--      - ss: source text (unencrypted).
-- Generics:
--      - CT_BITS: number of ct bits.
--      - SK_BITS: number of sk bits.
--      - SS_BITS: number of ss bits.
-------------------------------------------------------------------------------
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity kyber_512_dec is

    generic(
        CT_BITS, SK_BITS, SS_BITS : natural := 8
    );

    port(
        clk, reset      : in std_logic;
        ct              : in unsigned(CT_BITS - 1 downto 0);
        sk              : in unsigned(SK_BITS - 1 downto 0);
        valid           : out std_logic;
        ss              : out unsigned(SS_BITS - 1 downto 0)
    );

end kyber_512_dec;


architecture stub of kyber_512_dec is
    signal counter : integer := 0;
begin
    process(clk, reset)
    begin
        if reset = '1' then
            ss    <= (others => '0');
            valid <= '0';
            counter <= 0;

        elsif rising_edge(clk) then
            if counter = 1 then
                ss    <= ct(SS_BITS - 1 downto 0) xor sk(SS_BITS - 1 downto 0);  -- Falsa descifrado
                valid <= '1';
            else
                valid <= '0';
            end if;

            counter <= counter + 1;
        end if;
    end process;
end stub;
