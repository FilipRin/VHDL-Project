module memory #(
	parameter FILE_NAME = "mem_init.mif",
    parameter ADDR_WIDTH = 6,
    parameter DATA_WIDTH = 16
)(
    input clk,
    input rst_n,
    input we,
    input [ADDR_WIDTH - 1:0] addr,
    input [DATA_WIDTH - 1:0] data,
    output reg [DATA_WIDTH - 1:0] out
);

	(* ram_init_file = FILE_NAME *) reg [DATA_WIDTH - 1:0] mem [2**ADDR_WIDTH - 1:0];

    always @(posedge clk,negedge rst_n) begin
        if(!rst_n) begin
            out<={DATA_WIDTH{1'b0}};
        end
        else begin
            if (we) begin
                mem[addr] <= data; //mozda treba neblokirajuca dodela
            end
            else out <= mem[addr];
        end
        
    end

endmodule
