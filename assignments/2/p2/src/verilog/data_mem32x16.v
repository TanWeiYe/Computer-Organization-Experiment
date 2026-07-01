`timescale 1ps/1ps

// data_mem32x16.v - 32x16 Data Memory (sync write, combo read)
// byte_en controls which bytes to write (only for STORE)
module data_mem32x16 (
    input  wire        clk,
    input  wire        rst_n,

    input  wire        we,          // 写使能
    input  wire [4:0]  addr,        // 地址（5-bit，32 深）
    input  wire [15:0] wdata,       // 写数据
    input  wire [1:0]  byte_en,     // 字节使能: [1]=high byte, [0]=low byte

    output wire [15:0] rdata,       // 组合读

    // 调试端口
    input  wire [4:0]  debug_addr,
    output wire [15:0] debug_data
);

    reg [15:0] mem [0:31];

    // 同步写
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            integer i;
            for (i = 0; i < 32; i = i + 1)
                mem[i] <= 16'h0000;
        end
        else if (we) begin
            case (byte_en)
                2'b01: mem[addr] <= {mem[addr][15:8], wdata[7:0]};        // 只写低字节
                2'b10: mem[addr] <= {wdata[15:8], mem[addr][7:0]};        // 只写高字节
                2'b11: mem[addr] <= wdata;                                 // 写整字
                default: mem[addr] <= mem[addr];                           // byte_en=00: 不写
            endcase
        end
    end

    // 组合读
    assign rdata      = mem[addr];
    assign debug_data = mem[debug_addr];

endmodule
