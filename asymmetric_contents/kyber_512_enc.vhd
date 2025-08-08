-------------------------------------------------------------------------------
-- Name: kyber_512_enc
--
-- Description: entity that performs encryption in ML-KEM-512.
--
-- Inputs:
--      - clk: clock signal.
--      - reset: async reset signal.
--      - ss : source (unencrypted) text (serialized).
--      - pk : public key (serialized).
-- Outputs:
--      - valid : indicates that the output data is valid.
--      - ct : ciphertext (serialized).
--
-- Generics:
--      -SS_BITS: number of ss bits.
--      -PK_BITS: number of pk bits.
--      -CT_BITS: number of ct bits.
-------------------------------------------------------------------------------
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity kyber_512_enc is

    generic(
        SS_BITS : natural := 8;
        PK_BITS : natural := 8;
        CT_BITS : natural := 8
        );

    port(
        clk, reset      : in std_logic;
        ss              : in unsigned(SS_BITS - 1 downto 0);
        pk              : in unsigned(PK_BITS - 1 downto 0);
        valid           : out std_logic;
        ct              : out unsigned(CT_BITS - 1 downto 0)
        );

end kyber_512_enc;


architecture stub of kyber_512_enc is
begin
    process(clk)
    begin
        if rising_edge(clk) then
            if reset = '1' then
                ct    <= (others => '0');
                valid <= '0';
            else
                -- The stub behavior is that of an XOR
                ct    <= ss xor pk;
                valid <= '1';
            end if;
        end if;
    end process;
end architecture;
