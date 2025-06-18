// Formatting a hexdecimal number to string
module tb();

bit [7:0] x = 8'hab;
bit [7:0] y = 8'hcd;

string str;

initial begin
	str = $sformatf("%0h %0h",x,y);
	$display("%0s",str);
end
endmodule

