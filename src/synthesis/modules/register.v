module register #(parameter DATA_WIDTH = 16)
                (input clk,
                  input rst_n,
                  input cl,
                  input ld,
                  input [DATA_WIDTH-1:0] in,
                  input inc,
                  input dec,
                  input sr,
                  input ir,
                  input sl,
                  input il,
                  output [DATA_WIDTH-1:0] out);
    
    reg [DATA_WIDTH-1:0] reg_out,reg_next;
    assign out = reg_out;
    
    always @(posedge clk,negedge rst_n) begin
        if (!rst_n)
            reg_out <= {DATA_WIDTH{1'b0}};
        else
            reg_out <= reg_next;
    end
    
    always @(*) begin
        reg_next = reg_out;
        if (cl)
            reg_next = {DATA_WIDTH{1'b0}};
        else begin
            if (ld)
                reg_next = in;
            else begin
                if (inc)
                    reg_next = reg_next+1;
                else begin
                    if (dec)
                        reg_next = reg_next-1;
                    else begin
                        if (sr)
                            reg_next = {ir,reg_next[DATA_WIDTH-1:1]};
                        else begin
                            if (ir)
                                reg_next = {reg_next[DATA_WIDTH-2:0],il};
                        end
                    end
                end
            end
        end
    end
    
endmodule
