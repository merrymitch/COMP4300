vsim -gui work.dlx_register
add wave -position insertpoint \
sim:/dlx_register/in_val \
sim:/dlx_register/clock \
sim:/dlx_register/out_val \


force -freeze sim:/dlx_register/in_val 32'h0000000A 0
run
#When clock goes to 1, the output should be A
force -freeze sim:/dlx_register/clock 1 0 
run
#When clock goes to 0, the output remains A until the clock changes
force -freeze sim:/dlx_register/clock 0 0
run
force -freeze sim:/dlx_register/in_val 32'h00000005 0
run
force -freeze sim:/dlx_register/in_val 32'h00000001 0
run
#When the clock goes to 1, the most recent input will be the output
force -freeze sim:/dlx_register/clock 1 0
run
