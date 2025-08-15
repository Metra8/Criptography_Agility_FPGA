PACKAGES = \
    sbox_pkg.vhd \
    key_expansion_pkg.vhd \
    aes_transform_pkg.vhd \
    to_hexadecimal_pkg.vhd

SOURCES = \
    $(PACKAGES) \
    aes_128.vhd \
    kyber_512_keypair.vhd \
    kyber_512_dec.vhd \
    kyber_512_enc.vhd \
    bus_adapter.vhd \
    crypto_wrapper.vhd

TOP = crypto_wrapper

all:
	ghdl -a $(SOURCES)
	ghdl -e $(TOP)

clean:
	rm -f *.o *.cf $(TOP)
