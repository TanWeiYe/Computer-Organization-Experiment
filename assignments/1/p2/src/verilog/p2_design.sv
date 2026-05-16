`timescale 1ps/1ps

// p2_design.sv
// 示例模块：简单计数器模板，作为 p2 的起始实现。
module p2_design(
    input  wire clk,
    input  wire rst_n,
    output reg  [7:0] out
);

    // 简短说明：这是一个示例同步计数器，复位后从 0 开始计数。
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            out <= 8'd0;
        end else begin
            out <= out + 1'b1;
        end
    end

endmodule
