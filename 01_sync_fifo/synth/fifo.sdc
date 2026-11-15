# Start with a clock you can plausibly meet, then tighten it until timing fails (that gives you Fmax).
create_clock -name clk -period 10.000 [get_ports clk]
derive_clock_uncertainty
# Inputs/outputs: constrain after the first run once you know what the reports show.
# set_input_delay  -clock clk 2.0 [all_inputs]
# set_output_delay -clock clk 2.0 [all_outputs]
