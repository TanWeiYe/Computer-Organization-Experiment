`timescale 1ps/1ps

// simple_pipeline_cpu.v - 简化五级流水线 CPU（P2）
// 流水级: IF -> ID -> EX -> MEM -> WB
// 无转发/阻塞，需显式插入 NOP 解决数据冒险
//
// 指令格式（外部输入，每周期一条）:
//   op_type: 00=NOP  01=ALU(rd=rs1 op rs2)  10=LOAD(rd=Mem[rs1+imm])  11=STORE(Mem[rs1+imm]=rs2)

module simple_pipeline_cpu (
    input  wire        clk,
    input  wire        rst_n,

    // 外部指令输入
    input  wire        instr_valid,
    input  wire [1:0]  instr_op_type,
    input  wire [2:0]  instr_rs1,
    input  wire [2:0]  instr_rs2,
    input  wire [2:0]  instr_rd,
    input  wire [15:0] instr_imm,
    input  wire [2:0]  instr_alu_op,
    input  wire [1:0]  instr_byte_en,

    // 寄存器初始化（优先级高于 WB）
    input  wire        init_we,
    input  wire [2:0]  init_addr,
    input  wire [15:0] init_data,

    // 调试端口
    input  wire [2:0]  debug_reg_addr,
    output wire [15:0] debug_reg_data,
    input  wire [4:0]  debug_mem_addr,
    output wire [15:0] debug_mem_data,

    output wire [15:0] debug_if_id_imm,
    output wire [15:0] debug_id_ex_src_a,
    output wire [15:0] debug_id_ex_src_b,
    output wire [15:0] debug_ex_mem_alu_result,
    output wire [15:0] debug_mem_wb_wb_data
);

    // ============================================================
    // 流水线寄存器宽度定义
    // ============================================================
    // IF/ID: valid|op_type|rs1|rs2|rd|imm|alu_op|byte_en
    localparam IF_ID_W  = 1 + 2 + 3 + 3 + 3 + 16 + 3 + 2;  // 33
    // ID/EX: valid|op_type|rd|src_a|src_b|imm|alu_op|byte_en
    localparam ID_EX_W  = 1 + 2 + 3 + 16 + 16 + 16 + 3 + 2; // 59
    // EX/MEM: valid|op_type|rd|alu_result|src_b|byte_en|zero|carry|negative|overflow
    localparam EX_MEM_W = 1 + 2 + 3 + 16 + 16 + 2 + 1 + 1 + 1 + 1;  // 44
    // MEM/WB: valid|op_type|rd|wb_data|zero|carry|negative|overflow
    localparam MEM_WB_W = 1 + 2 + 3 + 16 + 1 + 1 + 1 + 1;          // 26

    // ============================================================
    // 流水线寄存器信号
    // ============================================================
    // IF stage -> IF/ID reg
    wire [IF_ID_W-1:0] if_id_din, if_id_dout;

    // ID stage -> ID/EX reg
    wire [ID_EX_W-1:0] id_ex_din, id_ex_dout;

    // EX stage -> EX/MEM reg
    wire [EX_MEM_W-1:0] ex_mem_din, ex_mem_dout;

    // MEM stage -> MEM/WB reg
    wire [MEM_WB_W-1:0] mem_wb_din, mem_wb_dout;

    // ============================================================
    // IF 阶段: 打包指令到 IF/ID
    // ============================================================
    // 当 instr_valid=0 时，op_type=NOP
    wire [1:0] if_op_type;
    assign if_op_type = instr_valid ? instr_op_type : 2'b00;  // 无效→NOP

    assign if_id_din = {
        instr_valid,            // [32]
        if_op_type,             // [31:30]
        instr_rs1,              // [29:27]
        instr_rs2,              // [26:24]
        instr_rd,               // [23:21]
        instr_imm,              // [20:5]
        instr_alu_op,           // [4:2]
        instr_byte_en           // [1:0]
    };

    pipe_reg #(.WIDTH(IF_ID_W)) IF_ID (
        .clk  (clk),
        .rst_n(rst_n),
        .stall(1'b0),           // P2 中不使用 stall
        .flush(1'b0),           // P2 中不使用 flush
        .din  (if_id_din),
        .dout (if_id_dout)
    );

    // 提取 IF/ID 字段
    wire        id_valid;
    wire [1:0]  id_op_type;
    wire [2:0]  id_rs1, id_rs2, id_rd;
    wire [15:0] id_imm;
    wire [2:0]  id_alu_op;
    wire [1:0]  id_byte_en;

    assign {id_valid, id_op_type, id_rs1, id_rs2, id_rd, id_imm, id_alu_op, id_byte_en} = if_id_dout;
    assign debug_if_id_imm = id_imm;

    // ============================================================
    // ID 阶段: 读寄存器堆，准备操作数
    // ============================================================
    wire [15:0] rf_src_a, rf_src_b;

    regfile8x16 regfile (
        .clk        (clk),
        .rst_n      (rst_n),
        .we         (wb_reg_we),
        .waddr      (wb_rd),
        .wdata      (wb_data),
        .init_we    (init_we),
        .init_addr  (init_addr),
        .init_data  (init_data),
        .rs1        (id_rs1),
        .src_a      (rf_src_a),
        .rs2        (id_rs2),
        .src_b      (rf_src_b),
        .debug_addr (debug_reg_addr),
        .debug_data (debug_reg_data)
    );

    // ID/EX 打包
    assign id_ex_din = {
        id_valid,               // [58]
        id_op_type,             // [57:56]
        id_rd,                  // [55:53]
        rf_src_a,               // [52:37]
        rf_src_b,               // [36:21]
        id_imm,                 // [20:5]
        id_alu_op,              // [4:2]
        id_byte_en              // [1:0]
    };

    pipe_reg #(.WIDTH(ID_EX_W)) ID_EX (
        .clk  (clk),
        .rst_n(rst_n),
        .stall(1'b0),
        .flush(1'b0),
        .din  (id_ex_din),
        .dout (id_ex_dout)
    );

    // 提取 ID/EX 字段
    wire        ex_valid;
    wire [1:0]  ex_op_type;
    wire [2:0]  ex_rd;
    wire [15:0] ex_src_a, ex_src_b, ex_imm;
    wire [2:0]  ex_alu_op;
    wire [1:0]  ex_byte_en;

    assign {ex_valid, ex_op_type, ex_rd, ex_src_a, ex_src_b, ex_imm, ex_alu_op, ex_byte_en} = id_ex_dout;
    assign debug_id_ex_src_a = ex_src_a;
    assign debug_id_ex_src_b = ex_src_b;

    // ============================================================
    // EX 阶段: ALU 运算 / 地址计算
    // ============================================================
    // MUX: ALU 第二操作数来源
    //   LOAD/STORE → imm（地址计算）
    //   ALU → src_b
    wire        ex_alu_src_imm;
    assign ex_alu_src_imm = (ex_op_type == 2'b10) || (ex_op_type == 2'b11); // LOAD or STORE

    wire [15:0] alu_b;
    assign alu_b = ex_alu_src_imm ? ex_imm : ex_src_b;

    wire [15:0] alu_result;
    wire        alu_zero, alu_carry, alu_negative, alu_overflow;

    alu16 alu (
        .a        (ex_src_a),
        .b        (alu_b),
        .alu_op   (ex_alu_op),
        .result   (alu_result),
        .zero     (alu_zero),
        .carry    (alu_carry),
        .negative (alu_negative),
        .overflow (alu_overflow)
    );

    // EX/MEM 打包
    assign ex_mem_din = {
        ex_valid,               // [43]
        ex_op_type,             // [42:41]
        ex_rd,                  // [40:38]
        alu_result,             // [37:22]
        ex_src_b,               // [21:6]  (STORE 数据)
        ex_byte_en,             // [5:4]
        alu_zero,               // [3]
        alu_carry,              // [2]
        alu_negative,           // [1]
        alu_overflow            // [0]
    };

    pipe_reg #(.WIDTH(EX_MEM_W)) EX_MEM (
        .clk  (clk),
        .rst_n(rst_n),
        .stall(1'b0),
        .flush(1'b0),
        .din  (ex_mem_din),
        .dout (ex_mem_dout)
    );

    // 提取 EX/MEM 字段
    wire        mem_valid;
    wire [1:0]  mem_op_type;
    wire [2:0]  mem_rd;
    wire [15:0] mem_alu_result, mem_src_b;
    wire [1:0]  mem_byte_en;
    wire        mem_zero, mem_carry, mem_negative, mem_overflow;

    assign {mem_valid, mem_op_type, mem_rd, mem_alu_result, mem_src_b, mem_byte_en,
            mem_zero, mem_carry, mem_negative, mem_overflow} = ex_mem_dout;
    assign debug_ex_mem_alu_result = mem_alu_result;

    // ============================================================
    // MEM 阶段: 数据存储器访问
    // ============================================================
    // 地址取 alu_result[4:0]
    wire [4:0] mem_addr;
    assign mem_addr = mem_alu_result[4:0];

    wire mem_we;
    assign mem_we = mem_valid && (mem_op_type == 2'b11); // STORE

    wire [15:0] mem_rdata;

    data_mem32x16 data_mem (
        .clk        (clk),
        .rst_n      (rst_n),
        .we         (mem_we),
        .addr       (mem_addr),
        .wdata      (mem_src_b),
        .byte_en    (mem_byte_en),
        .rdata      (mem_rdata),
        .debug_addr (debug_mem_addr),
        .debug_data (debug_mem_data)
    );

    // MEM/WB 打包
    // wb_data 根据 op_type 选择: LOAD→mem_rdata, ALU→mem_alu_result
    wire [15:0] mem_wb_data_raw;
    assign mem_wb_data_raw = (mem_op_type == 2'b10) ? mem_rdata : mem_alu_result;

    assign mem_wb_din = {
        mem_valid,              // [25]
        mem_op_type,            // [24:23]
        mem_rd,                 // [22:20]
        mem_wb_data_raw,        // [19:4]
        mem_zero,               // [3]
        mem_carry,              // [2]
        mem_negative,           // [1]
        mem_overflow            // [0]
    };

    pipe_reg #(.WIDTH(MEM_WB_W)) MEM_WB (
        .clk  (clk),
        .rst_n(rst_n),
        .stall(1'b0),
        .flush(1'b0),
        .din  (mem_wb_din),
        .dout (mem_wb_dout)
    );

    // 提取 MEM/WB 字段
    wire        wb_valid;
    wire [1:0]  wb_op_type;
    wire [2:0]  wb_rd;
    wire [15:0] wb_data;
    wire        wb_zero, wb_carry, wb_negative, wb_overflow;

    assign {wb_valid, wb_op_type, wb_rd, wb_data,
            wb_zero, wb_carry, wb_negative, wb_overflow} = mem_wb_dout;
    assign debug_mem_wb_wb_data = wb_data;

    // ============================================================
    // WB 阶段: 写回寄存器堆
    // ============================================================
    // reg_we: ALU 或 LOAD 且 valid 且 rd != 0
    wire wb_reg_we;
    assign wb_reg_we = wb_valid && (wb_op_type == 2'b01 || wb_op_type == 2'b10) && (wb_rd != 3'd0);

endmodule
