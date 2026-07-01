`timescale 1ps/1ps

// alu_reg_datapath.v - ALU 与寄存器堆组合的数据通路
// 功能：从寄存器堆读取两个操作数，送入 ALU 进行运算，将结果写回寄存器堆
module alu_reg_datapath (
    input  wire clk,
    input  wire rst_n,

    input  wire reg_we,
    input  wire [2:0] rs1,
    input  wire [2:0] rs2,
    input  wire [2:0] rd,
    input  wire [2:0] alu_op,

    input  wire init_we,
    input  wire [2:0] init_addr,
    input  wire [15:0] init_data,

    output wire [15:0] src_a,
    output wire [15:0] src_b,
    output wire [15:0] alu_result,
    output wire zero,
    output wire carry,
    output wire negative,
    output wire overflow
);

    // 寄存器堆的写地址和写数据逻辑（init_we 优先于 reg_we）
    wire [2:0] real_waddr;
    wire [15:0] real_wdata;
    wire real_we;
    
    // init_we 优先
    assign real_waddr = init_we ? init_addr : rd;
    assign real_wdata = init_we ? init_data : alu_result;
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
    
    // 实例化 ALU（来自题目一）
    alu16 alu_inst (
        .a(src_a),
        .b(src_b),
        .alu_op(alu_op),
        .result(alu_result),
        .zero(zero),
        .carry(carry),
        .negative(negative),
        .overflow(overflow)
    );

endmodule
