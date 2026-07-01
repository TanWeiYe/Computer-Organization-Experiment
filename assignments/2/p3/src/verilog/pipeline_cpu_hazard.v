`timescale 1ps/1ps

// pipeline_cpu_hazard.v - P3: 带转发与阻塞的五级流水线 CPU

module pipeline_cpu_hazard (
    input  wire        clk, rst_n,
    input  wire        instr_valid,
    input  wire [1:0]  instr_op_type,
    input  wire [2:0]  instr_rs1, instr_rs2, instr_rd,
    input  wire [15:0] instr_imm,
    input  wire [2:0]  instr_alu_op,
    input  wire [1:0]  instr_byte_en,
    input  wire        init_we,
    input  wire [2:0]  init_addr,
    input  wire [15:0] init_data,
    input  wire [2:0]  debug_reg_addr,
    output wire [15:0] debug_reg_data,
    input  wire [4:0]  debug_mem_addr,
    output wire [15:0] debug_mem_data,
    output wire [15:0] debug_if_id_imm,
    output wire [15:0] debug_id_ex_src_a,
    output wire [15:0] debug_id_ex_src_b,
    output wire [15:0] debug_ex_mem_alu_result,
    output wire [15:0] debug_mem_wb_wb_data,
    output wire [1:0]  debug_forward_a,
    output wire [1:0]  debug_forward_b,
    output wire        debug_stall
);

    // ============================================================
    // 流水线宽度
    // ============================================================
    localparam IF_ID_W  = 33;  // valid(1)+op_type(2)+rs1(3)+rs2(3)+rd(3)+imm(16)+alu_op(3)+be(2)
    localparam ID_EX_W  = 65;  // valid(1)+op_type(2)+rd(3)+rs1(3)+rs2(3)+src_a(16)+src_b(16)+imm(16)+alu_op(3)+be(2)
    localparam EX_MEM_W = 44;  // valid(1)+op_type(2)+rd(3)+alu_result(16)+src_b(16)+be(2)+flags(4)
    localparam MEM_WB_W = 26;  // valid(1)+op_type(2)+rd(3)+wb_data(16)+flags(4)

    // ============================================================
    // 流水线寄存器总线
    // ============================================================
    wire [IF_ID_W-1:0]  if_id_din,  if_id_dout;
    wire [ID_EX_W-1:0]  id_ex_din,  id_ex_dout;
    wire [EX_MEM_W-1:0] ex_mem_din, ex_mem_dout;
    wire [MEM_WB_W-1:0] mem_wb_din, mem_wb_dout;

    // ============================================================
    // 提前声明所有流水线字段 wire
    // ============================================================
    // IF/ID
    wire        id_valid;
    wire [1:0]  id_op_type;
    wire [2:0]  id_rs1, id_rs2, id_rd;
    wire [15:0] id_imm;
    wire [2:0]  id_alu_op;
    wire [1:0]  id_byte_en;

    // ID/EX
    wire        ex_valid;
    wire [1:0]  ex_op_type;
    wire [2:0]  ex_rd, ex_rs1, ex_rs2;
    wire [15:0] ex_src_a, ex_src_b, ex_imm;
    wire [2:0]  ex_alu_op;
    wire [1:0]  ex_byte_en;

    // EX/MEM
    wire        mem_valid;
    wire [1:0]  mem_op_type;
    wire [2:0]  mem_rd;
    wire [15:0] mem_alu_result, mem_src_b;
    wire [1:0]  mem_byte_en;
    wire        mem_zero, mem_carry, mem_negative, mem_overflow;

    // MEM/WB
    wire        wb_valid;
    wire [1:0]  wb_op_type;
    wire [2:0]  wb_rd;
    wire [15:0] wb_data;
    wire        wb_zero, wb_carry, wb_negative, wb_overflow;

    // ============================================================
    // 字段提取（assign，顺序无关但放一起清晰）
    // ============================================================
    assign {id_valid, id_op_type, id_rs1, id_rs2, id_rd, id_imm, id_alu_op, id_byte_en} = if_id_dout;
    assign {ex_valid, ex_op_type, ex_rd, ex_rs1, ex_rs2, ex_src_a, ex_src_b, ex_imm, ex_alu_op, ex_byte_en} = id_ex_dout;
    assign {mem_valid, mem_op_type, mem_rd, mem_alu_result, mem_src_b, mem_byte_en,
            mem_zero, mem_carry, mem_negative, mem_overflow} = ex_mem_dout;
    assign {wb_valid, wb_op_type, wb_rd, wb_data,
            wb_zero, wb_carry, wb_negative, wb_overflow} = mem_wb_dout;

    // 调试
    assign debug_if_id_imm         = id_imm;
    assign debug_id_ex_src_a       = ex_src_a;
    assign debug_id_ex_src_b       = ex_src_b;
    assign debug_ex_mem_alu_result = mem_alu_result;
    assign debug_mem_wb_wb_data    = wb_data;

    // ============================================================
    // IF 阶段：打包指令
    // ============================================================
    wire [1:0] if_op_type;
    assign if_op_type = instr_valid ? instr_op_type : 2'b00;
    assign if_id_din  = {instr_valid, if_op_type, instr_rs1, instr_rs2,
                         instr_rd, instr_imm, instr_alu_op, instr_byte_en};

    // ============================================================
    // Hazard Detection Unit + Stall/Flush
    // ============================================================
    wire load_use;
    assign load_use = id_ex_dout[64] &&                          // ex_valid
                      (id_ex_dout[63:62] == 2'b10) &&            // ex_op_type == LOAD
                      (id_ex_dout[61:59] != 3'd0) &&             // ex_rd != 0
                      ((id_ex_dout[61:59] == id_rs1) || (id_ex_dout[61:59] == id_rs2));

    wire stall, flush;
    assign stall = load_use;
    assign flush = load_use;
    assign debug_stall = stall;

    // ============================================================
    // IF/ID 流水线寄存器（stall 时保持）
    // ============================================================
    pipe_reg #(.WIDTH(IF_ID_W)) IF_ID (
        .clk(clk), .rst_n(rst_n), .stall(stall), .flush(1'b0),
        .din(if_id_din), .dout(if_id_dout)
    );

    // ============================================================
    // ID 阶段: 读寄存器堆
    // ============================================================
    wire [15:0] rf_src_a, rf_src_b;
    regfile8x16 regfile (
        .clk(clk), .rst_n(rst_n),
        .we(wb_reg_we), .waddr(wb_rd), .wdata(wb_data),
        .init_we(init_we), .init_addr(init_addr), .init_data(init_data),
        .rs1(id_rs1), .src_a(rf_src_a), .rs2(id_rs2), .src_b(rf_src_b),
        .debug_addr(debug_reg_addr), .debug_data(debug_reg_data)
    );

    assign id_ex_din = {id_valid, id_op_type, id_rd, id_rs1, id_rs2,
                        rf_src_a, rf_src_b, id_imm, id_alu_op, id_byte_en};

    // ============================================================
    // ID/EX 流水线寄存器（load-use 时 flush 插入气泡）
    // ============================================================
    pipe_reg #(.WIDTH(ID_EX_W)) ID_EX (
        .clk(clk), .rst_n(rst_n), .stall(1'b0), .flush(flush),
        .din(id_ex_din), .dout(id_ex_dout)
    );

    // ============================================================
    // 转发单元
    // ============================================================
    // EX/MEM 可转发: ALU 指令完成 EX, 结果在 alu_result
    wire ex_mem_fwd;
    assign ex_mem_fwd = mem_valid && (mem_op_type == 2'b01) && (mem_rd != 3'd0);

    // MEM/WB 可转发: ALU 或 LOAD 指令完成 MEM, 结果在 wb_data
    wire mem_wb_fwd;
    assign mem_wb_fwd = wb_valid && (wb_op_type == 2'b01 || wb_op_type == 2'b10) && (wb_rd != 3'd0);

    // forward_a
    reg [1:0] fwd_a;
    always @(*) begin
        if (ex_mem_fwd && (mem_rd == ex_rs1) && (ex_rs1 != 3'd0))
            fwd_a = 2'b01;       // EX/MEM
        else if (mem_wb_fwd && (wb_rd == ex_rs1) && (ex_rs1 != 3'd0))
            fwd_a = 2'b10;       // MEM/WB
        else
            fwd_a = 2'b00;       // regfile
    end

    // forward_b
    reg [1:0] fwd_b;
    always @(*) begin
        if (ex_mem_fwd && (mem_rd == ex_rs2) && (ex_rs2 != 3'd0))
            fwd_b = 2'b01;
        else if (mem_wb_fwd && (wb_rd == ex_rs2) && (ex_rs2 != 3'd0))
            fwd_b = 2'b10;
        else
            fwd_b = 2'b00;
    end

    assign debug_forward_a = ex_valid ? fwd_a : 2'b00;
    assign debug_forward_b = ex_valid ? fwd_b : 2'b00;

    // ============================================================
    // EX 阶段: ALU + 转发 MUX
    // ============================================================
    wire [15:0] alu_op_a, alu_op_b_raw;
    assign alu_op_a     = (fwd_a == 2'b01) ? mem_alu_result : (fwd_a == 2'b10) ? wb_data : ex_src_a;
    assign alu_op_b_raw = (fwd_b == 2'b01) ? mem_alu_result : (fwd_b == 2'b10) ? wb_data : ex_src_b;

    // LOAD/STORE 使用 imm 作为第二操作数（地址计算）
    wire alu_src_imm;
    assign alu_src_imm = (ex_op_type == 2'b10) || (ex_op_type == 2'b11);
    wire [15:0] alu_b;
    assign alu_b = alu_src_imm ? ex_imm : alu_op_b_raw;

    wire [15:0] alu_result;
    wire alu_zero, alu_carry, alu_negative, alu_overflow;
    alu16 alu (
        .a(alu_op_a), .b(alu_b), .alu_op(ex_alu_op),
        .result(alu_result), .zero(alu_zero), .carry(alu_carry),
        .negative(alu_negative), .overflow(alu_overflow)
    );

    assign ex_mem_din = {ex_valid, ex_op_type, ex_rd,
                         alu_result, alu_op_b_raw, ex_byte_en,
                         alu_zero, alu_carry, alu_negative, alu_overflow};

    // ============================================================
    // EX/MEM 流水线寄存器
    // ============================================================
    pipe_reg #(.WIDTH(EX_MEM_W)) EX_MEM (
        .clk(clk), .rst_n(rst_n), .stall(1'b0), .flush(1'b0),
        .din(ex_mem_din), .dout(ex_mem_dout)
    );

    // ============================================================
    // MEM 阶段: 数据存储器
    // ============================================================
    wire [4:0] mem_addr;
    assign mem_addr = mem_alu_result[4:0];
    wire mem_we;
    assign mem_we = mem_valid && (mem_op_type == 2'b11);

    wire [15:0] mem_rdata;
    data_mem32x16 data_mem (
        .clk(clk), .rst_n(rst_n),
        .we(mem_we), .addr(mem_addr), .wdata(mem_src_b), .byte_en(mem_byte_en),
        .rdata(mem_rdata),
        .debug_addr(debug_mem_addr), .debug_data(debug_mem_data)
    );

    wire [15:0] mem_wb_val;
    assign mem_wb_val = (mem_op_type == 2'b10) ? mem_rdata : mem_alu_result;
    assign mem_wb_din = {mem_valid, mem_op_type, mem_rd, mem_wb_val,
                         mem_zero, mem_carry, mem_negative, mem_overflow};

    // ============================================================
    // MEM/WB 流水线寄存器
    // ============================================================
    pipe_reg #(.WIDTH(MEM_WB_W)) MEM_WB (
        .clk(clk), .rst_n(rst_n), .stall(1'b0), .flush(1'b0),
        .din(mem_wb_din), .dout(mem_wb_dout)
    );

    // ============================================================
    // WB 阶段: 写回
    // ============================================================
    wire wb_reg_we;
    assign wb_reg_we = wb_valid && (wb_op_type == 2'b01 || wb_op_type == 2'b10) && (wb_rd != 3'd0);

endmodule
