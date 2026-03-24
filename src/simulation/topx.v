module topx; reg [2:0] dut_oc; reg [3:0] dut_a; reg [3:0] dut_b; wire [3:0] dut_f; reg[3:0] dut_in; reg dut_rst_n, dut_clk, dut_ld, dut_cl, dut_inc, dut_dec, dut_sr, dut_ir, dut_sl, dut_il; wire [3:0] dut_out; aluu dut1(.oc(dut_oc), .a(dut_a), .b(dut_b), .f(dut_f)); registerr dut2(.clk(dut_clk), .rst_n(dut_rst_n), .cl(dut_cl), .ld(dut_ld), .in(dut_in), .inc(dut_inc), .dec(dut_dec), .sr(dut_sr), .ir(dut_ir), .sl(dut_sl), .il(dut_il), .out(dut_out));

integer i;


initial begin
    for (i = 0; i<2**11; i = i+1) begin
        {dut_oc,dut_a,dut_b} = i;
        #5;
    end
    //zavrseno pobudjivanje kombinacionog modula
    $stop;
    
    dut_in       = 4'h0;
    dut_ld       = 1'b0;
    dut_cl       = 1'b0;
    dut_inc      = 1'b0;
    dut_dec      = 1'b0;
    dut_sr       = 1'b0;
    dut_ir       = 1'b0;
    dut_sl       = 1'b0;
    dut_il       = 1'b0;
    #7 dut_rst_n = 1'b1;
    repeat(1000)begin
        #10;
        dut_in  = $urandom %16;
        dut_ld  = $urandom_range(0,1);
        dut_cl  = $urandom_range(0,1);
        dut_inc = $urandom_range(0,1);
        dut_dec = $urandom_range(0,1);
        dut_sr  = $urandom_range(0,1);
        dut_ir  = $urandom_range(0,1);
        dut_sl  = $urandom_range(0,1);
        dut_il  = $urandom_range(0,1);
    end
    //zavrseno pobudjivanje sekvencijalnog modula
    $finish;
end

initial begin
    dut_rst_n = 1'b0;
    dut_clk   = 1'b0;
    forever begin
        #5 dut_clk = ~dut_clk;
    end
end

always @(dut_f) begin
    $display(
    "time = %0d, dut_oc = %b, dut_a = %b, dut_b = %b, dut_f = %b",
    $time,dut_oc,dut_a,dut_b,dut_f
    );
end

initial
    $monitor(
    "time = %0d, dut_in = %b, dut_cl = %b, dut_ld = %b, dut_inc = %b, dut_dec = %b, dut_sr = %b, dut_ir = %b, dut_sl = %b, dut_il = %b, dut_out = %b",
    $time,dut_in,dut_cl,dut_ld,dut_inc,dut_dec,dut_sr,dut_ir,dut_sl,dut_il,dut_out
    );

endmodule
