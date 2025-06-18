module tb();
  bit [7:0] val1=8'h12;
  bit [7:0] val2=8'hcd;
  string val11,val22, val;

initial begin
$display("%h", val1);
$display("%h", val2);
val11.hextoa(val1);
val22.hextoa(val2);
val = {val11,val22};
$display("%s", val);
end
  
endmodule
