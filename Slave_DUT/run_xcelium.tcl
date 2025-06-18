database -open waves -into waves.shm -default -incsize 131072
probe -create axilite_s_tb_top -depth all -tasks -functions -uvm -packed 128k -unpacked 128k -all -memories -dynamic -database waves
