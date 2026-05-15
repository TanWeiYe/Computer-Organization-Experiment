// 简单计数器模块 - 用于测试编译、仿真、波形观看的完整链路
module top (
    input  logic       clk,    // 时钟输入
    input  logic       rst_n,  // 复位信号（低有效）
    output logic [7:0] led     // 8 位计数器输出
);
    // 内部计数器变量
    logic [7:0] counter;

    // 时序逻辑：在时钟上升沿或复位信号下降沿触发
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // 复位时，计数器清零
            counter <= 8'd0;
        end
        else begin
            // 正常工作时，计数器每个时钟周期加 1
            counter <= counter + 8'd1;
        end
    end

    // 输出端口与计数器直接连接
    assign led = counter;
endmodule
