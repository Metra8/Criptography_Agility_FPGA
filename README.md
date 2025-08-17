
# Crypto-agility for post-quantum transition

## Overview

This project presents an idea for a dynamically switching algorithm between two cryptographic cyphers: AES-128 (a symmetric block cipher) and Kyber-512 (a lattice-based post-quantum key encapsulation mechanism). The selection mechanism is driven by runtime security conditions and user-controlled inputs. All components are implemented in synthesizable VHDL and are compatible with AMD FPGA toolchains (Vivado and GHDL). As kyber is assymetric, this cypher provides a unique role in the dinamic switching. This means that the kyber cypher will provide the renewal of safe keys for AES to use.
Switching conditions are to be simulated, but ideally would be implemented in a .ipynb environment.

**Note**: Due to the significant complexity of implementing Kyber-512 in hardware—particularly its polynomial arithmetic, noise sampling, and reconciliation mechanisms—the current version includes **Kyber as a behavioral stub**. This stub emulates Kyber’s interface (ports, timing, and control signals) to support full system testing and integration with the crypto-agility FSM. This decision preserves the project’s architectural integrity while focusing development effort on the crypto-agility mechanism.


## Project features

- Implementation of the AES cypher in vhdl using 128 bits.
- Crypto-agility mechanisms using runtime decision logic.
- Default preference for AES (due to cypher speed), with automatic fallback to Kyber.
- Fully synthesizable and reusable RTL design.
- Parallel criteria met on the AES cypher.
- Fully implemented design

## Implementation

This project has been fully implemented in vhdl with the AMD Zynq UltraScale+™ MPSoC ZCU104 evaluation kit. All relevant AES operations have been listed in vhd packages for legibility and reutilization. This includes the following:

### AES implementation

- AES top level. Management of logic and order of operations (FSM).
- Transform package to shift rows, mix columns and multiply in Galois Field (8 bits).
- Sbox package (256 different values). Implemented with the polynomial: 1 + x + x**3 + x**4 + x**8.
- Key expansion package to rotate words and replace words using the sbox package.
- Simple binary to hexadecimal converter package.

### Crypto wrapper implementation
- Data bus. To fullfil the I/O ports limitation the data and key vectors were reduced from 128 to 32.
- Crypto wrapper vhd. Includes instances of AES, Kyber and data bus implementations. Runs all runtime logic (FSM).

### Kyber stub implementation
- 3 stubs made for 512 bits. This includes a encoder, a decoder and a keypair.

### ZCU104 implementation
- Constraints file for testing. No differential ports (LVDS) have been used.

## Instructions to build and test the proyect
Step 1: Start a new project in Vivado.

Step 2: Import the vhdl files. This includes:

    - All kyber files (3 vhd files)
    - All AES files without the test bench or the makefile (5 vhd files)
    - All top level files (2 vhd files [include the testbench file for simulation if wanted])
    - The constraint file (.xdc)
    
Step 3: Select VHDL 2008 as the programming language.

Step 4: Constrain the design.

Step 5: Generate bitstream.

If done correctly, vivado should generate the same files as the ones provided (bitstream_files).

Contact & attribution
---------------------

Project Lead: Antonio Blasco Valenti

Collaborators: Álvaro Masa Fernandez

Contact information: blascovalenti@gmail.com
