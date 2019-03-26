#
#	ModelSim Compiler 'DO'
#
#	Build the miniUart support moduals
vcom -93 -work WORK {../miniuart/acia/clkunit.vhd}
vcom -93 -work WORK {../miniuart/acia/rxunit.vhd}
vcom -93 -work WORK {../miniuart/acia/txunit.vhd}

#	Build the miniUart / ACIA
vcom -93 -work WORK {../miniuart/acia/miniuart.vhd}

#	Build the Wishbone wrapper
vcom -93 -work WORK {../miniuart/acia/wb_acia.vhd}
