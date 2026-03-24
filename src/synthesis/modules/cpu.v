module cpu #(parameter ADDR_WIDTH = 6,
             parameter DATA_WIDTH = 16)
            (input clk,
             input rst_n,
             input [DATA_WIDTH-1:0] mem,
             input [DATA_WIDTH-1:0] in,
             output reg we,
             output [ADDR_WIDTH-1:0] addr,
             output [DATA_WIDTH-1:0] data,
             output reg [DATA_WIDTH-1:0] out,
             output [ADDR_WIDTH-1:0] pc,
             output [ADDR_WIDTH-1:0] sp);
    
    // --- REGISTER INSTANCES (isto kao kod tebe) ---
    wire [ADDR_WIDTH-1:0] pc_regout, sp_regout, mar_regout;
    wire [DATA_WIDTH-1:0] mdr_regout, ac_regout;
    wire [31:0] ir_regout;

    //pc
    reg pc_cl,pc_ld,pc_inc,pc_dec,pc_sr,pc_ir,pc_sl,pc_il;
    reg [ADDR_WIDTH-1:0] pc_in;
    register #(ADDR_WIDTH) reg_pc(.clk(clk),.rst_n(rst_n),.cl(pc_cl),.ld(pc_ld),
                                  .inc(pc_inc),.dec(pc_dec),.sr(pc_sr),.ir(pc_ir),
                                  .sl(pc_sl),.il(pc_il),.out(pc_regout),.in(pc_in));

    //sp
    reg sp_cl, sp_ld, sp_inc, sp_dec, sp_sr, sp_ir, sp_sl, sp_il;
    reg [ADDR_WIDTH-1:0] sp_in;
    register #(ADDR_WIDTH) reg_sp(.clk(clk),.rst_n(rst_n),.cl(sp_cl),.ld(sp_ld),
                                  .inc(sp_inc),.dec(sp_dec),.sr(sp_sr),.ir(sp_ir),
                                  .sl(sp_sl),.il(sp_il),.out(sp_regout),.in(sp_in));

    //ir
    reg ir_cl, ir_ld, ir_inc, ir_dec, ir_sr, ir_ir, ir_sl, ir_il;
    reg [31:0] ir_in;
    register #(32) reg_ir(.clk(clk),.rst_n(rst_n),.cl(ir_cl),.ld(ir_ld),
                          .in(ir_in),.inc(ir_inc),.dec(ir_dec),.sr(ir_sr),
                          .ir(ir_ir),.sl(ir_sl),.il(ir_il),.out(ir_regout));

    //mar
    reg mar_cl, mar_ld, mar_inc, mar_dec, mar_sr, mar_ir, mar_sl, mar_il;
    reg [ADDR_WIDTH-1:0] mar_in;
    register #(ADDR_WIDTH) reg_mar(.clk(clk),.rst_n(rst_n),.cl(mar_cl),.ld(mar_ld),
                                   .in(mar_in),.inc(mar_inc),.dec(mar_dec),.sr(mar_sr),
                                   .ir(mar_ir),.sl(mar_sl),.il(mar_il),.out(mar_regout));

    //mdr
    reg mdr_cl, mdr_ld, mdr_inc, mdr_dec, mdr_sr, mdr_ir, mdr_sl, mdr_il;
    reg [DATA_WIDTH-1:0] mdr_in;
    register #(DATA_WIDTH) reg_mdr(.clk(clk),.rst_n(rst_n),.cl(mdr_cl),.ld(mdr_ld),
                                   .in(mdr_in),.inc(mdr_inc),.dec(mdr_dec),.sr(mdr_sr),
                                   .ir(mdr_ir),.sl(mdr_sl),.il(mdr_il),.out(mdr_regout));

    //ac
    reg ac_cl,ac_ld,ac_inc,ac_dec,ac_sr,ac_ir,ac_sl,ac_il;
    reg [DATA_WIDTH-1:0] ac_in;
    register #(DATA_WIDTH) reg_ac(.clk(clk),.rst_n(rst_n),.cl(ac_cl),.ld(ac_ld),
                                  .in(ac_in),.inc(ac_inc),.dec(ac_dec),.sr(ac_sr),
                                  .ir(ac_ir),.sl(ac_sl),.il(ac_il),.out(ac_regout));

    // ALU
    reg [2:0] alu_op;
    reg [DATA_WIDTH-1:0] alu_a, alu_b;
    wire [DATA_WIDTH-1:0] alu_res;
    alu #(DATA_WIDTH) alu_inst(.oc(alu_op), .a(alu_a), .b(alu_b), .f(alu_res));

    // --- OPCODES ---
    localparam MOV  = 4'h0;
    localparam ADD  = 4'h1;
    localparam SUB  = 4'h2;
    localparam MUL  = 4'h3;
    localparam DIV  = 4'h4;
    localparam IN   = 4'h7;
    localparam OUT  = 4'h8;
    //proveriti opcode za modif instrukciju
    localparam JSR  = 4'hD;
    localparam RTS  = 4'hE;
    //
    localparam STOP = 4'hF;

    // --- STATES ---
    localparam INIT            = 6'h00;
    localparam FETCH1          = 6'h01;
    localparam FETCH_WAIT      = 6'h02;
    localparam INSTRUCTION_FETCH = 6'h03;
    localparam DECODE          = 6'h04;
    localparam MOV_Y_ADDR      = 6'h05;
    localparam MOV_Y_WAIT      = 6'h06;
    localparam MOV_Y_CHECK     = 6'h07;
    localparam MOV_X_ADDR      = 6'h08;
    localparam MOV_X_WRITE     = 6'h09;
    localparam ALU_Y_ADDR      = 6'h0A;
    localparam ALU_Y_WAIT      = 6'h0B;
    localparam ALU_Y_CHECK     = 6'h0C;
    localparam ALU_Z_ADDR      = 6'h0D;
    localparam ALU_Z_WAIT      = 6'h0E;
    localparam ALU_Z_CHECK     = 6'h0F;
    localparam ALU_X_ADDR      = 6'h10;
    localparam ALU_X_WRITE     = 6'h11;
    localparam IN_X_ADDR       = 6'h12;
    localparam IN_X_WRITE      = 6'h13;
    localparam OUT_X_ADDR      = 6'h14;
    localparam OUT_X_WAIT      = 6'h15;
    localparam STOP_X_ADDR     = 6'h16;
    localparam STOP_Y_ADDR     = 6'h17;
    localparam STOP_Z_ADDR     = 6'h18;
    localparam HALT            = 6'h19;
    localparam MOV_Y_INDIRECT  = 6'h1A;
    localparam MOV_X_INDIRECT  = 6'h1B;
    localparam IN_LOAD         = 6'h1C;
    localparam OUT_X_LOAD      = 6'h1D;
    localparam OUT_X_CHECK     = 6'h1E;
    localparam ALU_X_WAIT      = 6'h1F;
    localparam ALU_X_CHECK     = 6'h20;
    localparam ALU_EXEC        = 6'h21;
    localparam MOV_X_WAIT      = 6'h22;
    localparam MOV_X_CHECK     = 6'h23;
    localparam MOV_Y_LOAD_WAIT = 6'h24;

    //za modif
    localparam JSR_FETCH_ADDR  = 6'h26;
    localparam JSR_FETCH_WAIT  = 6'h27;
    localparam JSR_FETCH_LOAD  = 6'h28;
    localparam JSR_PUSH        = 6'h29;
    localparam JSR_SET_PC      = 6'h2A;

    localparam RTS_POP_ADDR    = 6'h2B;
    localparam RTS_POP_WAIT    = 6'h2C;
    localparam RTS_POP_LOAD    = 6'h2D;
    localparam RTS_SET_PC      = 6'h2E;
    //localparam IN_X_WAIT       = 6'h25;
    //localparam IN_X_CHECK      = 6'h26;

    reg [5:0] state_reg, state_next;

    // --- INSTRUCTION FIELDS ---
    wire [15:0] instr = ir_regout[15:0];
    wire [3:0] op_code = instr[15:12];
    wire [2:0] x_addr = instr[10:8];
    wire [2:0] y_addr = instr[6:4];
    wire [2:0] z_addr = instr[2:0];
    wire x_di = instr[11];
    wire y_di = instr[7];
    wire z_di = instr[3];

    // --- STOP flags ---
    wire x_non_null = x_di | |x_addr;
    wire y_non_null = y_di | |y_addr;
    wire z_non_null = z_di | |z_addr;

    assign addr = mar_regout;
    assign data = mdr_regout;
    assign pc   = pc_regout;
    assign sp   = sp_regout;

    // --- SEQ ---
    always @(posedge clk or negedge rst_n)
        if(!rst_n) state_reg <= INIT;
        else state_reg <= state_next;

    // --- FSM ---
    always @(*) begin
        // default control
        {pc_cl,pc_ld,pc_inc,pc_dec} = 4'b0;
        {sp_cl,sp_ld,sp_inc,sp_dec} = 4'b0;
        {mar_cl,mar_ld} = 2'b0;
        {mdr_cl,mdr_ld} = 2'b0;
        {ir_cl,ir_ld} = 2'b0;
        {ac_cl,ac_ld} = 2'b0;
        we = 0;
        alu_op = 3'b000;
        alu_a  = ac_regout;
        //alu_b  = mdr_regout;  IZMENA
        alu_b  = mem;
        state_next = state_reg;

        // defaults inputs
        pc_in = pc_regout;
        sp_in = sp_regout;
        mar_in = mar_regout;
        mdr_in = mdr_regout;
        ac_in  = ac_regout;
        ir_in  = ir_regout;
        ////////nova izmena
        //out = 0;
        // Bolje je napraviti register: reg [DATA_WIDTH-1:0] out_reg;
        // pa out = out_reg; a onda ga menjati u FSM
        out=out;

        case (state_reg)
            INIT: begin
                pc_in = 6'd8; pc_ld=1;
                sp_in = 6'd63; sp_ld=1;
                ir_cl=1; ac_cl=1; mar_cl=1; mdr_cl=1;
                state_next = FETCH1;
            end

            FETCH1: begin
                mar_in = pc_regout; mar_ld=1;
                state_next = FETCH_WAIT;
            end

            FETCH_WAIT: state_next = INSTRUCTION_FETCH;

            INSTRUCTION_FETCH: begin
                mdr_in = mem; mdr_ld=1;
                ir_in = {16'd0, mem}; ir_ld=1;
                pc_inc = 1;
                state_next = DECODE;
            end

            DECODE: begin
                case (op_code)
                    MOV: state_next = MOV_Y_ADDR;
                    ADD, SUB, MUL, DIV: state_next = ALU_Y_ADDR;
                    IN: state_next = IN_X_ADDR;
                    OUT: state_next = OUT_X_ADDR;
                    JSR: state_next = JSR_FETCH_ADDR;
                    RTS: state_next = RTS_POP_ADDR;
                    STOP: if(x_non_null) state_next=STOP_X_ADDR;
                          else if(y_non_null) state_next=STOP_Y_ADDR;
                          else if(z_non_null) state_next=STOP_Z_ADDR;
                          else state_next=HALT;
                    default: state_next = FETCH1;
                endcase
            end

            // --- MOV ---
            MOV_Y_ADDR: begin
                mar_in = {{ADDR_WIDTH-3{1'b0}}, y_addr};
                mar_ld = 1;
                state_next = MOV_Y_WAIT;
            end

            MOV_Y_WAIT: state_next = MOV_Y_CHECK;

            MOV_Y_CHECK: begin
                if(y_di) begin
                    //mar_in = mem[ADDR_WIDTH-1:0]; mar_ld=1;
                    state_next = MOV_Y_INDIRECT;
                end else begin
                    mdr_in = mem; mdr_ld=1;
                    state_next = MOV_Y_LOAD_WAIT;
                end
            end

            MOV_Y_LOAD_WAIT: begin
                state_next = MOV_X_ADDR;
            end

            MOV_Y_INDIRECT: begin
                mar_in = mem[ADDR_WIDTH-1:0];
                mar_ld = 1;
                state_next = MOV_Y_WAIT;
            end

            MOV_X_ADDR: begin
                mar_in = {{ADDR_WIDTH-3{1'b0}}, x_addr};
                mar_ld = 1;
                state_next = MOV_X_WAIT;
            end

            MOV_X_WAIT: begin
                state_next=MOV_X_CHECK;
            end

            MOV_X_CHECK: begin
                if(x_di) begin
                    //mar_in = mem[ADDR_WIDTH-1:0]; mar_ld=1;
                    state_next = MOV_X_INDIRECT;
                end else begin
                    state_next = MOV_X_WRITE;
                end
            end
            
            MOV_X_INDIRECT: begin
                mar_in = mem[ADDR_WIDTH-1:0];
                mar_ld = 1;
                state_next = MOV_X_WAIT;
            end

            MOV_X_WRITE: begin
                we=1;
                state_next=FETCH1;
            end

            // --- ALU ---
            ALU_Y_ADDR: begin
                mar_in={{ADDR_WIDTH-3{1'b0}}, y_addr};
                mar_ld=1; state_next=ALU_Y_WAIT;
            end

            ALU_Y_WAIT: state_next=ALU_Y_CHECK;

            ALU_Y_CHECK: begin
                if(y_di) begin
                    mar_in=mem[ADDR_WIDTH-1:0]; mar_ld=1;
                    state_next=ALU_Y_WAIT;
                end else begin
                    ac_in=mem; ac_ld=1;
                    state_next=ALU_Z_ADDR;
                end
            end

            ALU_Z_ADDR: begin
                mar_in={{ADDR_WIDTH-3{1'b0}}, z_addr};
                mar_ld=1; state_next=ALU_Z_WAIT;
            end

            ALU_Z_WAIT: state_next=ALU_Z_CHECK;

            ALU_Z_CHECK: begin
                if(z_di) begin
                    mar_in=mem[ADDR_WIDTH-1:0]; mar_ld=1;
                    state_next=ALU_Z_WAIT;
                end else begin
                    state_next=ALU_EXEC;
                end
            end

            ALU_EXEC: begin
                alu_a=ac_regout;
                alu_b=mem;
                case(op_code)
                    ADD: alu_op=3'b000;
                    SUB: alu_op=3'b001;
                    MUL: alu_op=3'b010;
                    DIV: alu_op=3'b011; // ignoriše se rezultat (po Postavci „ne radi“)
                endcase
                ac_in=alu_res; ac_ld=1;
                mdr_in=alu_res; mdr_ld=1;
                state_next=ALU_X_ADDR;
            end

            ALU_X_ADDR: begin
                mar_in={{ADDR_WIDTH-3{1'b0}}, x_addr};
                mar_ld=1; state_next=ALU_X_WAIT;
            end

            ALU_X_WAIT: begin
                state_next=ALU_X_CHECK;
            end

            ALU_X_CHECK: begin
                if(x_di) begin
                    mar_in=mem[ADDR_WIDTH-1:0]; mar_ld=1;
                    state_next=ALU_X_WAIT;
                end else begin
                    state_next=ALU_X_WRITE;
                end
            end

            ALU_X_WRITE: begin
                we=1; state_next=FETCH1;
            end

            // --- IN ---
            IN_X_ADDR: begin
                mar_in={{ADDR_WIDTH-3{1'b0}}, x_addr};
                mar_ld=1; state_next=IN_LOAD;
            end

            IN_LOAD: begin
                mdr_in=in;
                mdr_ld=1;
                state_next=IN_X_WRITE;
            end

            IN_X_WRITE: begin
                we=1;
                state_next=FETCH1;
            end

            // --- OUT ---
            OUT_X_ADDR: begin
                mar_in={{ADDR_WIDTH-3{1'b0}}, x_addr};
                mar_ld=1; state_next=OUT_X_WAIT;
            end

            OUT_X_WAIT: begin
                state_next=OUT_X_CHECK;
            end
            //Probati za indirektno adr
            OUT_X_CHECK: begin
                if (x_di) begin
                    mar_in = mem[ADDR_WIDTH-1:0];
                    mar_ld = 1;
                    state_next = OUT_X_WAIT;
                end else begin
                    state_next = OUT_X_LOAD;
                end
            end

            OUT_X_LOAD: begin
                out = mem; state_next=FETCH1;
            end
            //---------------------------------------
            // JSR
            JSR_FETCH_ADDR: begin
                mar_in = pc_regout;
                mar_ld = 1;
                state_next = JSR_FETCH_WAIT;
            end

            JSR_FETCH_WAIT: begin
                state_next = JSR_FETCH_LOAD;
            end

            JSR_FETCH_LOAD: begin
                mdr_in = mem;
                mdr_in = 1;
                pc_inc = 1;
                state_next = JSR_PUSH;
            end

            JSR_PUSH: begin
                mar_in = sp_regout;
                mar_ld = 1;
                mdr_in = pc_regout;
                mdr_in = 1;
                sp_dec = 1;
                state_next = JSR_SET_PC;
            end

            JSR_SET_PC: begin
                pc_in = mdr_regout;
                pc_ld = 1;
                state_next = FETCH1;
            end

            // RTS
            RTS_POP_ADDR: begin
                sp_inc = 1;
                mar_in = sp_regout;
                mar_ld = 1;
                state_next = RTS_POP_WAIT;
            end

            RTS_POP_WAIT: begin
                state_next = RTS_POP_LOAD;
            end

            RTS_POP_LOAD: begin
                mdr_in = mem;
                mdr_ld = 1;
                state_next = RTS_SET_PC;
            end

            RTS_SET_PC: begin
                pc_in = mdr_regout;
                pc_ld = 1;
                state_next = FETCH1;
            end
            //----------------------------------
            // --- STOP ---
            STOP_X_ADDR: begin
                mar_in={{ADDR_WIDTH-3{1'b0}}, x_addr};
                mar_ld=1; out=mem;
                if(y_non_null) state_next=STOP_Y_ADDR;
                else if(z_non_null) state_next=STOP_Z_ADDR;
                else state_next=HALT;
            end

            STOP_Y_ADDR: begin
                mar_in={{ADDR_WIDTH-3{1'b0}}, y_addr};
                mar_ld=1; out=mem;
                if(z_non_null) state_next=STOP_Z_ADDR;
                else state_next=HALT;
            end

            STOP_Z_ADDR: begin
                mar_in={{ADDR_WIDTH-3{1'b0}}, z_addr};
                mar_ld=1; out=mem; state_next=HALT;
            end

            HALT: begin
                we=0; state_next=HALT; // CPU stopped
            end
        endcase
    end
endmodule