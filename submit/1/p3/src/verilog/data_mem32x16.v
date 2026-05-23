`timescale 1ps/1ps

// 模块：32x16 数据存储器（同步写、组合读）
module data_mem32x16 (
    input  wire clk,
    input  wire mem_we,
    input  wire [4:0] addr,
    input  wire [15:0] wdata,
    input  wire [1:0] byte_en,
    output reg  [15:0] rdata
);
    // 存储阵列
    reg [15:0] mem [0:31];

    // 初始化存储器内容为 0
    integer i;
    initial begin
        for (i = 0; i < 32; i = i + 1) begin
            mem[i] = 16'h0000;
        end
    end

    // 组合读
    always @(*) begin
        rdata = mem[addr];
    end

    // 同步写（按字节使能）
    always @(posedge clk) begin
        // 写入行为在 mem_we=1 时生效
        if (mem_we) begin
            case (byte_en)
                2'b11: mem[addr] <= wdata;
                2'b01: mem[addr] <= {mem[addr][15:8], wdata[7:0]};
                2'b10: mem[addr] <= {wdata[15:8], mem[addr][7:0]};
                default: mem[addr] <= mem[addr];
            endcase
        end
    end

endmodule
