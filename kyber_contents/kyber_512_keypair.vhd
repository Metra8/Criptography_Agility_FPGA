-------------------------------------------------------------------------------
-- Name: kyber_512_keypair
--
-- Description: entity for the ML-KEM-512 keypair module. It generates an
--      1632-byte secret key and an 800-byte public key. By default, it
--      outputs these keys one byte at a time, but it can be sped up if
--      desired.
--
-- Input:
--      - clk : system clock.
--      - reset : reset signal.
--      - start : start signal to indicate the entity to start the computation.
-- Output:
--      - pk : public key (serialized).
--      - sk : secret key (serialized).
--      - valid : signal to indicate the upper level that the output data is
--              valid.
-- Generics:
--      - PK_BITS: number of public key bits.
--      - SK_BITS : number of secret key bits.
-------------------------------------------------------------------------------

entity kyber_512_keypair is
    generic ( PK_BITS : natural := 8;
              SK_BITS : natural := 8 );
    port ( clk, reset : in std_logic;
           start : in std_logic;
           sk : out unsigned(SK_BITS - 1 downto 0);
           pk : out unsigned(PK_BITS - 1 downto 0);
           valid : out std_logic );
end kyber_512_keypair;
