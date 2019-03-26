#
#	ModelSim Compiler 'DO'
#
#	Build the Programable I/O port model
vcom -93 -work WORK {../ioport/ioport.vhd}

#	Build the Wishbone wrapper
vcom -93 -work WORK {../ioport/wb_ioport.vhd}
