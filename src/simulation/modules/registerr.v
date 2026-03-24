module registerr (input clk,
                 input rst_n,
                 input cl,
                 input ld,
                 input [3:0] in,
                 input inc,
                 input dec,
                 input sr,
                 input ir,
                 input sl,
                 input il,
                 output [3:0] out);
    
    reg [3:0] reg_out,reg_next;
    assign out = reg_out;
    
    always @(posedge clk,negedge rst_n) begin
        if (!rst_n)
            reg_out <= 4'b0;
        else
            reg_out <= reg_next;
    end
    
    always @(*) begin
        reg_next = reg_out;
        if (cl)
            reg_next = 4'h0;
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
                            reg_next = {ir,reg_next[3:1]};
                        else begin
                            if (ir)
                                reg_next = {reg_next[2:0],il};
                        end
                    end
                end
            end
        end
    end
    
endmodule
