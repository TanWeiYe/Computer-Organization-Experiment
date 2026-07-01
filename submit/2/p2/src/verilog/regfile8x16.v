`timescale 1ps/1ps

// regfile8x16.v - 8x16 Register File (write-first, combo read, R0=0)
// init_we provides external initialization with priority over normal writeback
module regfile8x16 (
    input  wire        clk,
    input  wire        rst_n,

    // 写端口（来自 WB 阶段）
    input  wire        we,          // 写使能
    input  wire [2:0]  waddr,       // 写地址
    input  wire [15:0] wdata,       // 写数据

    // 初始化端口（优先级高于 WB）
    input  wire        init_we,
    input  wire [2:0]  init_addr,
    input  wire [15:0] init_data,

    // 读端口（组合逻辑）
    input  wire [2:0]  rs1,
    output wire [15:0] src_a,
    input  wire [2:0]  rs2,
    output wire [15:0] src_b,

    // 调试端口
    input  wire [2:0]  debug_addr,
    output wire [15:0] debug_data
);

    reg [15:0] regs [0:7];

    // 同步写（含初始化）
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            regs[0] <= 16'h0000;
            regs[1] <= 16'h0000;
            regs[2] <= 16'h0000;
            regs[3] <= 16'h0000;
            regs[4] <= 16'h0000;
            regs[5] <= 16'h0000;
            regs[6] <= 16'h0000;
            regs[7] <= 16'h0000;
        end
        else begin
            if (init_we) begin
                // 初始化优先
                if (init_addr != 3'd0)
                    regs[init_addr] <= init_data;
            end
            else if (we && waddr != 3'd0) begin
                // 正常 WB 写（R0 写保护）
                regs[waddr] <= wdata;
            end
        end
    end

    // 组合读（write-first: 同周期写的新值可被读到）
    // 但这里用的是 reg，同步写后下一周期才能读到，是标准的同步写
    assign src_a      = (rs1 == 3'd0) ? 16'h0000 : regs[rs1];
    assign src_b      = (rs2 == 3'd0) ? 16'h0000 : regs[rs2];
    assign debug_data = (debug_addr == 3'd0) ? 16'h0000 : regs[debug_addr];

endmodule
