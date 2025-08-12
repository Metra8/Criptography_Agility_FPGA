# ZCU104 Constraints para crypto_wrapper
# Basado en la ZCU104 Evaluation Board

# Clock constraint - usando el clock principal de 125MHz
create_clock -period 8.0 -name clk [get_ports clk]

# Timing constraints
set_input_delay -clock [get_clocks clk] -min 1.0 [all_inputs]
set_input_delay -clock [get_clocks clk] -max 3.0 [all_inputs]
set_output_delay -clock [get_clocks clk] -min 1.0 [all_outputs]
set_output_delay -clock [get_clocks clk] -max 3.0 [all_outputs]

# Clock - usar el clock de usuario disponible en la placa
# (en una implementación real usarías el pin específico del clock)
set_property IOSTANDARD LVCMOS18 [get_ports clk]

# Señales de control - Bank 87 (1.8V)
set_property IOSTANDARD LVCMOS18 [get_ports reset]
set_property IOSTANDARD LVCMOS18 [get_ports enable]
set_property IOSTANDARD LVCMOS18 [get_ports suspicious]
set_property IOSTANDARD LVCMOS18 [get_ports force_switch]
set_property IOSTANDARD LVCMOS18 [get_ports rand_toggle]
set_property IOSTANDARD LVCMOS18 [get_ports ready]

# data_in[127:0] - distribuir entre Bank 66 y 67 (1.2V)
set_property IOSTANDARD LVCMOS12 [get_ports data_in[*]]

# key[127:0] - distribuir entre Bank 68 y 87 (1.8V)  
set_property IOSTANDARD LVCMOS18 [get_ports key[*]]

# data_out[127:0] - distribuir entre Bank 44 y 45 (1.2V)
set_property IOSTANDARD LVCMOS12 [get_ports data_out[*]]

# Configuración adicional para optimización
set_property DRIVE 8 [get_ports data_out[*]]
set_property SLEW FAST [get_ports data_out[*]]

# Permitir que Vivado optimice la colocación
set_property ALLOW_COMBINATORIAL_LOOPS TRUE [current_design]
