`timescale 1ps/1ps

// pipe_reg.v - 通用流水线寄存器模块
// 支持 stall（保持）、flush（清零）、异步复位
// 优先级: rst_n > flush > stall
module pipe_reg #(
    parameter WIDTH = 32
) (
    input  wire             clk,
    input  wire             rst_n,      // 异步复位，低有效，最高优先级
    input  wire             stall,      // 保持当前值
    input  wire             flush,      // 清零（插入气泡），优先级高于 stall
    input  wire [WIDTH-1:0] din,
    output reg  [WIDTH-1:0] dout
);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // 异步复位：立即清零，与 clk/stall/flush 无关
            dout <= {WIDTH{1'b0}};
        end
        else if (flush) begin
            // 清零气泡：优先级高于 stall
            dout <= {WIDTH{1'b0}};
        end
        else if (stall) begin
            // 保持当前值不变
            dout <= dout;
        end
        else begin
            // 正常传递
            dout <= din;
        end
    end

endmodule
