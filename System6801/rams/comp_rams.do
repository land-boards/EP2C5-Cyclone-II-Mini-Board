#
#	ModelSim Compiler 'DO'
#
#	Build the Altera LPM_RAM Wishbone wrapper model
vcom -93 -work WORK {../rams/wb_lpm_ram.vhd}

#	Build the Wishbone External RAM wrapper
vcom -93 -work WORK {../rams/wb_ram.vhd}
