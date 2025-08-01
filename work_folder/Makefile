PACKAGES = \
    sbox_pkg.vhd \
    key_expansion_pkg.vhd \
    aes_transform_pkg.vhd \
    to_hexadecimal_pkg.vhd

SOURCES = \
    $(PACKAGES) \
    aes_128.vhd \
    kyber_512.vhd \
    crypto_wrapper.vhd

TOP = crypto_wrapper

all:
	ghdl -a $(SOURCES)
	ghdl -e $(TOP)

clean:
	rm -f *.o *.cf $(TOP)
