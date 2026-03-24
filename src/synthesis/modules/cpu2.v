module cpu #(parameter ADDR_WIDTH = 6,
             parameter DATA_WIDTH = 16)
            (input clk,
             input rst_n,
             input [DATA_WIDTH-1:0] mem,
             input [DATA_WIDTH-1:0] in,
             output reg we,
             output [ADDR_WIDTH-1:0] addr,
             output [DATA_WIDTH-1:0] data,
             output [DATA_WIDTH-1:0] out,
             output [ADDR_WIDTH-1:0] pc,
             output [ADDR_WIDTH-1:0] sp);
    
    

    wire [ADDR_WIDTH-1:0] pc_regout,sp_regout,mar_regout;
    wire [DATA_WIDTH-1:0] mdr_regout,ac_regout;
    wire [31:0] ir_regout;

    //pc
    reg pc_cl,pc_ld,pc_inc,pc_dec,pc_sr,pc_ir,pc_sl,pc_il;
    reg [ADDR_WIDTH-1:0] pc_in;
    register #(ADDR_WIDTH) reg_pc(.clk(clk),.rst_n(rst_n),.cl(pc_cl),.ld(pc_ld),.inc(pc_inc),.dec(pc_dec),.sr(pc_sr),.ir(pc_ir),.sl(pc_sl),.il(pc_il),.out(pc_regout),.in(pc_in));

    //sp
    reg sp_cl, sp_ld, sp_inc, sp_dec, sp_sr, sp_ir, sp_sl, sp_il;
    reg [ADDR_WIDTH-1:0] sp_in;
    register #(ADDR_WIDTH) reg_sp(.clk(clk),.rst_n(rst_n),.cl(sp_cl),.ld(sp_ld),.inc(sp_inc),.dec(sp_dec),.sr(sp_sr),.ir(sp_ir),.sl(sp_sl),.il(sp_il),.out(sp_regout),.in(sp_in));

    //ir
    reg ir_cl, ir_ld, ir_inc, ir_dec, ir_sr, ir_ir, ir_sl, ir_il;
    reg [31:0] ir_in;
    register #(32) reg_ir (
        .clk(clk),
        .rst_n(rst_n),
        .cl(ir_cl),
        .ld(ir_ld),
        .in(ir_in),
        .inc(ir_inc),
        .dec(ir_dec),
        .sr(ir_sr),
        .ir(ir_ir),
        .sl(ir_sl),
        .il(ir_il),
        .out(ir_regout)
    );

    //mar
    reg mar_cl, mar_ld, mar_inc, mar_dec, mar_sr, mar_ir, mar_sl, mar_il;
    reg [ADDR_WIDTH-1:0] mar_in;
    register #(ADDR_WIDTH) reg_mar (
        .clk(clk),
        .rst_n(rst_n),
        .cl(mar_cl),
        .ld(mar_ld),
        .in(mar_in),
        .inc(mar_inc),
        .dec(mar_dec),
        .sr(mar_sr),
        .ir(mar_ir),
        .sl(mar_sl),
        .il(mar_il),
        .out(mar_regout)
    );

    //mdr
    reg mdr_cl, mdr_ld, mdr_inc, mdr_dec, mdr_sr, mdr_ir, mdr_sl, mdr_il;
    reg [DATA_WIDTH-1:0] mdr_in;
    register #(DATA_WIDTH) reg_mdr (
        .clk(clk),
        .rst_n(rst_n),
        .cl(mdr_cl),
        .ld(mdr_ld),
        .in(mdr_in),
        .inc(mdr_inc),
        .dec(mdr_dec),
        .sr(mdr_sr),
        .ir(mdr_ir),
        .sl(mdr_sl),
        .il(mdr_il),
        .out(mdr_regout)
    );

    //ac
    reg ac_cl,ac_ld,ac_inc,ac_dec,ac_sr,ac_ir,ac_sl,ac_il;
    reg [DATA_WIDTH-1:0] ac_in;
    register #(DATA_WIDTH) reg_ac (
        .clk(clk),
        .rst_n(rst_n),
        .cl(ac_cl),
        .ld(ac_ld),
        .in(ac_in),
        .inc(ac_inc),
        .dec(ac_dec),
        .sr(ac_sr),
        .ir(ac_ir),
        .sl(ac_sl),
        .il(ac_il),
        .out(ac_regout)
    );

    // ALU
    reg [2:0] alu_op;
    reg [DATA_WIDTH-1:0] alu_a,alu_b;
    wire [DATA_WIDTH-1:0] alu_res;
    alu #(DATA_WIDTH) alu_inst (
        .oc(alu_op),
        .a(alu_a),
        .b(alu_b),
        .f(alu_res)
    );


    localparam FETCH1 = 5'h00; //procitaj instrukciju
    localparam FETCH_WAIT = 5'h01; //cekamo 1 takt
    localparam INSTRUCTION_FETCH = 5'h02; //IR ← MEM[PC]; PC++
    localparam DECODE = 5'h03; //izdvajanje x i y adrese i D/I bitove
    localparam MOV_Y_ADDR = 5'h04; //adresa drugog operanda
    localparam MOV_Y_WAIT = 5'h05; //cekaj MEM[MAR]
    localparam MOV_Y_ADDR_CHECK = 5'h06;//provera indirektnosti
    localparam MOV_X_ADDR = 5'h07;

    localparam INIT = 5'h09;
    localparam MOV_X_WRITE = 5'h0B;
    localparam ALU_Y_WAIT = 5'h0A;
    localparam ALU_Y_ADDR = 5'h0C; 
    localparam ALU_Y_ADDR_CHECK = 5'h0D;
    localparam ALU_Z_ADDR = 5'h0E;
    localparam ALU_Z_WAIT = 5'h0F;
    localparam ALU_Z_CHECK_ADDR = 5'h10;
    localparam ALU_X_ADDR = 5'h11;
    localparam ALU_X_WRITE = 5'h12;

    localparam MOV = 4'h0;
    localparam ADD = 4'h1;
    localparam SUB = 4'h2;
    localparam MUL = 4'h3;
    localparam DIV = 4'h4;
    localparam IN = 4'h7;
    localparam OUT = 4'h8;
    localparam STOP = 4'hF;

    reg [4:0] state_reg,state_next;

    //Delovi instrukcije
    wire [15:0] instruction=ir_regout[15:0];
    wire [3:0] op_code=instruction[15:12];

    wire [2:0] x_addr=instruction[10:8];
    wire [2:0] y_addr=instruction[6:4];
    wire[2:0] z_addr=instruction[2:0];
    wire x_di=instruction[11];
    wire y_di=instruction[7];
    wire z_di=instruction[3];

    //indikatori za STOP
    wire x_non_null= x_di || x_addr[0] || x_addr[1] || x_addr[2];
    wire y_non_null= y_di || y_addr[0] || y_addr[1] || y_addr[2];
    wire z_non_null= z_di || z_addr[0] || z_addr[1] || z_addr[2];

    //assign pc=pc_out;
    //assign sp=sp_out;

    assign addr = mar_regout;
    assign data = mdr_regout;
    assign pc = pc_regout;
    assign sp = sp_regout;
    

    always @(posedge clk,negedge rst_n) begin
        if(!rst_n) begin
            state_reg<=INIT;
        end
        else
            state_reg<=state_next;
    end

    always @(*) begin
        //addr=mar_regout;
        //data=mdr_regout;
        state_next=state_reg;

        //podrazumevani kontrolni signali
        {pc_cl,pc_ld,pc_inc,pc_dec} = 4'b0000;
        {sp_cl,sp_ld,sp_inc,sp_dec} = 4'b0000;
        {mar_cl, mar_ld} = 2'b00;
        {mdr_cl, mdr_ld} = 2'b00;
        {ir_cl, ir_ld} = 2'b00;
        {ac_cl, ac_ld} = 2'b00;
        we = 1'b0;
        alu_op=3'b000;
        alu_a  = ac_regout;
        alu_b  = mdr_regout;


        //podrazumevani ulazi u reg
        pc_in = pc_regout;
        sp_in = sp_regout;
        mar_in = mar_regout;
        mdr_in = mdr_regout;
        ac_in = ac_regout;
        ir_in = ir_regout;

        case (state_reg)
            INIT:begin
                pc_in = 6'd8;
                sp_in = 6'd63;
                ir_in = 32'd0;
                mar_in = {ADDR_WIDTH{1'b0}};
                mdr_in = {DATA_WIDTH{1'b0}};
                ac_in = {DATA_WIDTH{1'b0}};

                pc_ld = 1'b1;
                sp_ld = 1'b1;
                ir_cl = 1'b1;
                ac_cl  = 1'b1;
                mar_cl= 1'b1;
                mdr_cl= 1'b1;
                state_next = FETCH1;
            end
            FETCH1: begin
                mar_in=pc_regout;
                mar_ld=1'b1;
                state_next=FETCH_WAIT;
            end

            FETCH_WAIT:begin
                state_next=INSTRUCTION_FETCH;
            end

            INSTRUCTION_FETCH:begin
                mdr_in = mem;
                mdr_ld=1'b1;
                ir_in={16'd0,mem}; //mem je MEM[PC], prosirena na 32b
                ir_ld=1;
                pc_inc=1;
                state_next=DECODE;
            end

            DECODE: begin
                case (op_code)
                    MOV: state_next=MOV_Y_ADDR;
                    ADD,SUB,MUL,DIV: state_next=ALU_Y_ADDR;
                    /*IN: state_next=IN_X_ADDR;
                    OUT: state_next=OUT_X_ADDR;
                    STOP: begin
                        if(x_non_null) state_next=STOP_X_ADDR;
                        else if(y_non_null) state_next=STOP_Y_ADDR;
                        else if(z_non_null) state_next=STOP_Z_ADDR;
                        //else state_next=FETCH1;
                    end*/
                    default: state_next=FETCH1; //NOP
                endcase
            end

            MOV_Y_ADDR: begin
                mar_in = {{ADDR_WIDTH-3{1'b0}}, y_addr};
                mar_ld = 1;
                state_next=MOV_Y_WAIT;
            end

            MOV_Y_WAIT: begin
                state_next=MOV_Y_ADDR_CHECK;
            end

            MOV_Y_ADDR_CHECK: begin
                if(y_di)begin
                    mdr_in=mem;
                    mdr_ld=1'b1;
                    mar_in=mem[ADDR_WIDTH-1:0];
                    mar_in=1'b1;
                    state_next=MOV_Y_WAIT;
                end else begin
                    mdr_in=mem;
                    mdr_ld=1'b1;
                    state_next=MOV_X_ADDR;
                end
            end
            MOV_X_ADDR: begin
                if(x_di) begin
                    mar_in={{ADDR_WIDTH-3{1'b0}}, x_addr};
                    mar_ld=1'b1;
                    state_next=ALU_Y_WAIT;
                end else begin
                    mar_in= {{ADDR_WIDTH-3{1'b0}}, x_addr};
                    mar_ld=1'b1;
                    state_next=MOV_X_WRITE;
                end
            end
            MOV_X_WRITE:begin
                if(x_di)begin
                    mar_in=mem[ADDR_WIDTH-1:0];
                    mar_ld=1'b1;
                    state_next=ALU_Z_WAIT;
                end else begin
                    we=1'b1;
                    state_next=FETCH1;
                end
            end
            ALU_Y_ADDR: begin
                mar_in={{ADDR_WIDTH-3{1'b0}}, y_addr};
                mar_ld=1'b1;
                state_next=ALU_Y_WAIT;
            end
            ALU_Y_WAIT:begin
                state_next=ALU_Y_ADDR_CHECK;
            end
            ALU_Y_ADDR_CHECK:begin
                if(y_di)begin
                    mar_in=mem[ADDR_WIDTH-1:0];
                    mar_ld=1'b1;
                    state_next=ALU_Y_WAIT;
                end else begin
                    mdr_in=mem;
                    mdr_ld=1'b1;
                    ac_in=mem;
                    ac_ld=1'b1;
                    state_next=ALU_Z_ADDR;
                end
            end
            ALU_Z_ADDR:begin
                mar_in={{ADDR_WIDTH-3{1'b0}}, z_addr};
                mar_ld=1'b1;
                state_next=ALU_Z_WAIT;
            end
            ALU_Z_WAIT:begin
                state_next=ALU_Z_CHECK_ADDR;
            end
            ALU_Z_CHECK_ADDR:begin
                if(z_di)begin
                    mar_in=mem[ADDR_WIDTH-1:0];
                    mar_ld=1'b1;
                    state_next=ALU_Z_WAIT;
                end else begin
                    mdr_in=mem;
                    mdr_ld=1'b1;
                    alu_a=ac_regout;
                    alu_b=mem;
                    case (op_code)
                        ADD: alu_op=3'b000;
                        SUB: alu_op=3'b001;
                        MUL: alu_op=3'b010;
                        //DIV: alu_op=3'b011; ne radi se
                        default: alu_op=3'b000;
                    endcase
                    ac_in=alu_res;
                    ac_ld=1'b1;
                    mdr_in=alu_res;
                    mdr_ld=1'b1;
                    state_next=ALU_X_ADDR;
                end
            end
            ALU_X_ADDR:begin
                mar_in={{ADDR_WIDTH-3{1'b0}}, x_addr};
                mar_ld=1'b1;
                state_next=ALU_X_WRITE;
            end
            ALU_X_WRITE:begin
                if(x_di)begin
                    mar_in = mem[ADDR_WIDTH-1:0];
                    mar_ld = 1'b1;
                    state_next = ALU_X_ADDR;
                end else begin
                    we=1'b1;
                    state_next=FETCH1;
                end
            end
            /*IN_X_ADDR:begin
                mar_in={{ADDR_WIDTH-3{1'b0}}, x_addr};
                mar_ld=1'b1;
                state_next=IN_X_WRITE;
            end
            IN_X_WRITE:begin
                if(x_di)begin
                    mar_in=mem[ADDR_WIDTH-1:0];
                    mar_ld=1'b1;
                    state_next=IN_X_ADDR;
                end else begin
                    
                end
            end*/
        endcase

    end

endmodule
