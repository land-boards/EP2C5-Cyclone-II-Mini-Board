#
#	ModelSim Compiler 'DO'
#
#	Build the Altera LPM_ROM Wishbone wrapper model
vcom -93 -work WORK {../roms/wb_lpm_rom.vhd}

#	Build the Wishbone External ROM wrapper
vcom -93 -work WORK {../roms/wb_rom.vhd}
