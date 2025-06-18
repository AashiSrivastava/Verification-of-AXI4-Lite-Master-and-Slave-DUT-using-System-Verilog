module tb();

int arr_in [10][10];
int arr_out [3][3];

initial begin
for (int i=0; i<9; i++)begin
	for(int j=0; j<10; j++)begin
		arr_in[i][j]= $random();
	end
end

