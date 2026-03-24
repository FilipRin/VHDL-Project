module top #(
    parameter DIVISOR = 50_000_000,
    parameter FILE_NAME = "mem_init.mif",
    parameter ADDR_WIDTH = 6,
    parameter DATA_WIDTH = 16
)(
    input clk,             // 50MHz clock
    input rst_n,           // active low async reset
    input [2:0] btn,       // 3-bit input (using btn[2:0] verovatno)
    input [8:0] sw,        // 9-bit input
    output [9:0] led,      // 5-bit LED output
    output [27:0] hex      // 28-bit 7-seg display output
);

    wire cpu_we;
    wire [ADDR_WIDTH-1:0] cpu_addr;
    wire [DATA_WIDTH-1:0] cpu_data_out;
    wire [DATA_WIDTH-1:0] cpu_data_in;
    wire [ADDR_WIDTH-1:0] cpu_pc;
    wire [ADDR_WIDTH-1:0] cpu_sp;
    wire [DATA_WIDTH-1:0] cpu_out;
    wire clk_out;

    wire [3:0] ones_pc,tens_pc;
    wire [3:0] ones_sp,tens_sp;

    //CLKDIV instanca
    clk_div #(.DIVISOR(DIVISOR)) clk_slow(
        .clk(clk),
        .rst_n(rst_n),
        .out(clk_out)
    );

    // CPU instanca
    cpu #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH)
    ) cpu_inst (
        .clk(clk_out),
        .rst_n(rst_n),
        .mem(cpu_data_in),      // ulazni podaci iz mem
        .in({{(DATA_WIDTH-4){1'b0}}, sw[3:0]}),  // ulaz iz sw (10 bita, npr zero extend)
        .we(cpu_we),
        .addr(cpu_addr),
        .data(cpu_data_out),
        .out(cpu_out),
        .pc(cpu_pc),
        .sp(cpu_sp)
    );

    // MEMORIJA instanca
    memory #(
        .FILE_NAME(FILE_NAME),
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH)
    ) mem_inst (
        .clk(clk_out),
        .rst_n(rst_n),
        .we(cpu_we),
        .addr(cpu_addr),
        .data(cpu_data_out),
        .out(cpu_data_in)
    );

    assign led = {5'b0, cpu_out[4:0]};

    bcd bcd_pc( .in(cpu_pc), .ones(ones_pc), .tens(tens_pc));
    bcd bcd_sp( .in(cpu_sp), .ones(ones_sp), .tens(tens_sp));

    ssd ssd_pc_ones( .in(ones_pc), .out(hex[6:0]));
    ssd ssd_pc_tens( .in(tens_pc), .out(hex[13:7]));
    ssd ssd_sp_ones( .in(ones_sp), .out(hex[20:14]));
    ssd ssd_sp_tens( .in(tens_sp), .out(hex[27:21]));

endmodule
