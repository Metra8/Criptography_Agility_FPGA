
CRYPTO-AGILE HARDWARE CRYPTOGRAPHIC WRAPPER
================================================================================

OVERVIEW
--------

This project presents a crypto-agile hardware architecture capable of dynamically switching between two cryptographic algorithms: AES-128 (a symmetric block cipher) and Kyber-512 (a lattice-based post-quantum key encapsulation mechanism). The selection mechanism is driven by runtime security conditions and user-controlled inputs. All components are implemented in synthesizable VHDL and are compatible with AMD FPGA toolchains (Vivado and GHDL).

**Note**: Due to the significant complexity of implementing Kyber-512 in hardware—particularly its polynomial arithmetic, noise sampling, and reconciliation mechanisms—the current version includes **Kyber as a behavioral stub**. This stub emulates Kyber’s interface (ports, timing, and control signals) to support full system testing and integration with the crypto-agility FSM. This decision preserves the project’s architectural integrity while focusing development effort on the crypto-agility mechanism.


PROJECT FEATURES
----------------

• Hybrid integration of AES-128 and Kyber-512 (Kyber as a behavioral stub)
• Crypto-agility mechanism using hardware finite state machine (FSM)
• Runtime decision logic based on:
    - Suspicious data input detection
    - External override signal
    - Randomized toggling
    - Encrypted block counters
• Default preference for AES (high speed), with automatic fallback to Kyber (high security)
• Fully synthesizable and reusable RTL design


CRITERIA COMPLIANCE
-------------------

The project was designed to meet all evaluation criteria specified by the organizers:

1. TECHNICAL COMPLEXITY
   ---------------------
   The system involves advanced concepts in hardware cryptography including:
   • Hybrid cryptographic integration (symmetric and post-quantum asymmetric)
   • Runtime cipher switching using FSM logic
   • Secure fallback and recovery mechanisms
   • Timing control, protocol interfacing, and secure multiplexing

   The Kyber component, although stubbed, follows the correct I/O and control structure, enabling future implementation or replacement with synthesized Kyber logic. The wrapper’s FSM ensures safe integration and algorithm switching regardless of backend complexity.

2. IMPLEMENTATION
   ----------------
   The design is fully implemented in VHDL and has been verified using both simulation and synthesis tools. All modules are modular, parametrizable, and conform to synchronous design practices. The design can be directly targeted to AMD FPGAs using Vivado.

   The Kyber stub enables meaningful simulation of hybrid crypto-agile behavior without requiring a complete Kyber implementation, which would involve NTT hardware, centered binomial sampling, and reconciliation logic beyond the current scope.

3. MARKETABILITY / INNOVATION
   ---------------------------
   The system addresses the emerging need for **crypto-agility** in hardware, especially in environments where future threats from quantum computing must be mitigated in real time. The idea of using AES as the fast path and Kyber as the secure fallback aligns well with current industrial trends in hybrid cryptography.

   This architecture could be deployed in:
   • Secure IoT and embedded systems
   • Military and aerospace communication modules
   • Data centers and post-quantum transition hardware

4. DOCUMENTATION AND WRITTEN REPORT
   ----------------------------------
   A complete written report is included in the `doc/` directory. This report explains the architectural decisions, state machine logic, cryptographic rationale, testing methodology, and implementation details. All code is thoroughly commented, and test benches demonstrate system behavior under varied runtime conditions.

   A concise 2-minute YouTube video (with optional extended version) summarizes the project’s core contributions.

5. REUSABILITY
   ------------
   • The project is open-source under the MIT License.
   • Each cryptographic module (AES, Kyber stub) can be reused independently.
   • Utility components such as the S-box and FSM control logic are cleanly abstracted for future integration.
   • The `crypto_wrapper` is designed to be easily extendable to support additional algorithms once implemented.


CONTACT & ATTRIBUTION
---------------------

Project Lead: Antonio Blasco Valenti
Collaborators: Álvaro Masa Fernandez
Email: blascovalenti@gmail.com

This project is submitted to the Adaptive
Computing Track hosted by AMD.
We would like to thank the organizers for promoting innovation in FPGA.
