PACKAGES = \
    sbox_pkg.vhd \
    key_expansion_pkg.vhd \
    aes_transform_pkg.vhd

TOP = aes_128
TOP_VHD = aes_128.vhd


all:
	ghdl -a $(PACKAGES)
	ghdl -a $(TOP_VHD)
	ghdl -e $(TOP)


clean:
	rm -f *.o *.cf $(TOP)
