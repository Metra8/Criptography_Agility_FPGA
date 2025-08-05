-------------------------------------------------------------------------------
-- Name: kyber_512_dec
--
-- Description: entity that performs decryption in ML-KEM-512.
--
-- Inputs:
--      - clk: clock.
--      - reset: async reset.
--      - ct: cyphertext.
-- Outputs:
--      - valid: indicates the output data is valid.
--      - ss: source text (unencrypted).
-- Generics:
--      - CT_BITS: number of ct bits.
--      - SK_BITS: number of sk bits.
--      - SS_BITS: number of ss bits.
-------------------------------------------------------------------------------

entity kyber_512_dec is
    generic ( CT_BITS : natural := 8;
              SK_BITS : natural := 8;
              SS_BITS : natural := 8 );
    port ( clk, reset : in std_logic;
           ct : in unsigned(CT_BITS - 1 downto 0);
           sk : in unsigned(SK_BITS - 1 downto 0);
           valid : out std_logic;
           ss : out unsigned(SS_BITS - 1 downto 0);
           );
end kyber_512_dec;
