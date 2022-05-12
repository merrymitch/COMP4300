vsim -gui work.reg_file
add wave -position insertpoint \
sim:/reg_file/data_in \
sim:/reg_file/clock \
sim:/reg_file/data_out \
sim:/reg_file/readnotwrite \
sim:/reg_file/reg_number \

force -freeze sim:/reg_file/reg_number 4'h05 0
force -freeze sim:/reg_file/data_in 32'hffffffff 0
force -freeze sim:/reg_file/readnotwrite 0 0
run
force -freeze sim:/reg_file/clock 1 0
run
force -freeze sim:/reg_file/clock 0 0
run
force -freeze sim:/reg_file/readnotwrite 1 0
force -freeze sim:/reg_file/clock 1 0
run

force -freeze sim:/reg_file/clock 0 0
run

force -freeze sim:/reg_file/reg_number 4'h0A 0
force -freeze sim:/reg_file/data_in 32'h55555555 0
force -freeze sim:/reg_file/readnotwrite 0 0
run
force -freeze sim:/reg_file/clock 1 0
run
force -freeze sim:/reg_file/clock 0 0
run
force -freeze sim:/reg_file/readnotwrite 1 0
force -freeze sim:/reg_file/clock 1 0
run