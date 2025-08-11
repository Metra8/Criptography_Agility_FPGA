
# CRYPTO-AGILE HARDWARE CRYPTOGRAPHIC WRAPPER

## OVERVIEW

This project presents an idea for a dynamically switching algorithm between two cryptographic cyphers: AES-128 (a symmetric block cipher) and Kyber-512 (a lattice-based post-quantum key encapsulation mechanism). The selection mechanism is driven by runtime security conditions and user-controlled inputs. All components are implemented in synthesizable VHDL and are compatible with AMD FPGA toolchains (Vivado and GHDL). As kyber is assymetric, this cypher provides a unique role in the dinamic switching, which means that the kyber cypher will provide the renewal of safe keys for AES to use.
Switching conditions are to be simulated, but ideally would be implemented in a .ipynb environment.

**Note**: Due to the significant complexity of implementing Kyber-512 in hardware—particularly its polynomial arithmetic, noise sampling, and reconciliation mechanisms—the current version includes **Kyber as a behavioral stub**. This stub emulates Kyber’s interface (ports, timing, and control signals) to support full system testing and integration with the crypto-agility FSM. This decision preserves the project’s architectural integrity while focusing development effort on the crypto-agility mechanism.


## Project features

- Implementation of the AES cypher in vhdl using 128 bits.
- Crypto-agility mechanisms using runtime decision logic
- Default preference for AES (due to cypher speed), with automatic fallback to Kyber.
- Fully synthesizable and reusable RTL design
- Serial synthesis due to lack of time

## Instructions to build and test the proyect
Step 1: Start a new project in Vivado.

Step 2: Import the vhdl files. This includes:

    - All kyber files (3 vhd files)
    - All AES files without the test bench or the makefile (5 vhd files)
    - All the top level files (2 vhd files)
    
Step 3: Select VHDL 2008 as the programming language.

Step 4: Constrain the design

Step 5: Generate bitstream.


CONTACT & ATTRIBUTION
---------------------

Project Lead: Antonio Blasco Valenti
Collaborators: Álvaro Masa Fernandez
Email: blascovalenti@gmail.com
