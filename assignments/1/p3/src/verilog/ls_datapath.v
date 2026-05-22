`timescale 1ps/1ps

// 模块：支持 Load/Store 的简化数据通路
module ls_datapath (
    input  wire clk,
    input  wire rst_n,

    input  wire reg_we,
    input  wire mem_we,
    input  wire mem_to_reg,
    input  wire alu_src_imm,

    input  wire [2:0] rs1,
    input  wire [2:0] rs2,
    input  wire [2:0] rd,
    input  wire [15:0] imm,
    input  wire [2:0] alu_op,
    input  wire [1:0] byte_en,

    input  wire init_we,
    input  wire [2:0] init_addr,
    input  wire [15:0] init_data,

    output wire [15:0] src_a,
    output wire [15:0] src_b,
    output wire [15:0] alu_result,
    output wire [15:0] mem_rdata,
    output wire [15:0] wb_data,
    output wire zero
);

    // ALU 第二操作数选择
    wire [15:0] alu_b;

    // 写回选择与寄存器堆写控制（init 优先）
    wire [2:0] real_waddr;
    wire [15:0] real_wdata;
    wire real_we;

    // 选择 ALU 第二操作数
    assign alu_b = alu_src_imm ? imm : src_b;

    // 写回数据选择
    assign wb_data = mem_to_reg ? mem_rdata : alu_result;

    // init_we 优先
    assign real_waddr = init_we ? init_addr : rd;
    assign real_wdata = init_we ? init_data : wb_data;
    assign real_we = init_we | reg_we;

    // 实例化寄存器堆
    regfile8x16 regfile (
        .clk(clk),
        .rst_n(rst_n),
        .we(real_we),
        .waddr(real_waddr),
        .wdata(real_wdata),
        .raddr1(rs1),
        .raddr2(rs2),
        .rdata1(src_a),
        .rdata2(src_b)
    );

    // 实例化 ALU
    alu16 alu_inst (
        .a(src_a),
        .b(alu_b),
        .alu_op(alu_op),
        .result(alu_result),
        .zero(zero),
        .carry(),
        .negative(),
        .overflow()
    );

    // 实例化数据存储器（地址使用 alu_result[4:0]）
    data_mem32x16 data_mem (
        .clk(clk),
        .mem_we(mem_we),
        .addr(alu_result[4:0]),
        .wdata(src_b),
        .byte_en(byte_en),
        .rdata(mem_rdata)
    );

endmodule
