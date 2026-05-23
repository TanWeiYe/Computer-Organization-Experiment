`timescale 1ps/1ps

// regfile8x16.sv - 8x16 寄存器堆模块
// 功能：包含8个16位寄存器（R0-R7），R0 恒为 0，支持写后读旁路
module regfile8x16 (
    input  wire clk,
    input  wire rst_n,
    input  wire we,
    input  wire [2:0] waddr,
    input  wire [15:0] wdata,
    input  wire [2:0] raddr1,
    input  wire [2:0] raddr2,
    output wire [15:0] rdata1,
    output wire [15:0] rdata2
);

    // 8 个 16 位寄存器
    reg [15:0] regs [0:7];
    
    // 写操作：同步写，时钟上升沿
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // 复位：所有寄存器清零
            regs[0] <= 16'h0000;
            regs[1] <= 16'h0000;
            regs[2] <= 16'h0000;
            regs[3] <= 16'h0000;
            regs[4] <= 16'h0000;
            regs[5] <= 16'h0000;
            regs[6] <= 16'h0000;
            regs[7] <= 16'h0000;
        end else if (we && waddr != 3'b000) begin
            // 写使能且地址不为 0（R0 恒为 0，不可写）
            regs[waddr] <= wdata;
        end
    end
    
    // 读操作：组合逻辑读出，包含写后读旁路
    // 若本周期内写入地址与读地址相同且写使能有效，应输出即将写入的新数据
    assign rdata1 = (we && waddr == raddr1 && waddr != 3'b000) ? wdata : 
                    (raddr1 == 3'b000) ? 16'h0000 : regs[raddr1];
    
    assign rdata2 = (we && waddr == raddr2 && waddr != 3'b000) ? wdata : 
                    (raddr2 == 3'b000) ? 16'h0000 : regs[raddr2];

endmodule
