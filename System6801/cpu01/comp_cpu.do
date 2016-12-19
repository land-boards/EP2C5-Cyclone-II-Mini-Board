#
#	ModelSim Compiler 'DO'
#
#	Build the CPU01 model
vcom -93 -work WORK {../cpu01/cpu01.vhd}

#	Build the Wishbone Wrapper
vcom -93 -work WORK {../cpu01/wb_cpu01.vhd}
