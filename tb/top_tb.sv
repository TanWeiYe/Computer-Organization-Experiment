`timescale 1ns/1ps  // 时间单位: 1ns，精度: 1ps

// 测试平台（Testbench）模块
module top_tb;
    // 声明测试信号
    logic clk = 1'b0;       // 时钟信号（初始化为 0）
    logic rst_n = 1'b0;     // 复位信号（初始化为 0，即复位有效）
    logic [7:0] led;        // 被测设计的输出

    // 实例化待测设计（DUT - Device Under Test）
    top dut (
        .clk   (clk),
        .rst_n (rst_n),
        .led   (led)
    );

    // 仿真主流程
    initial begin
        // 指定波形文件输出位置和文件名
        $dumpfile("wave/top.vcd");
        // 记录整个测试平台的所有信号变化
        $dumpvars(0, top_tb);

        // 时钟和主控制流程并行执行
        fork
            // 时钟生成：每 50ns 翻转一次（100ns 周期）- 改长便于在 GTKWave 中观察
            forever #50 clk = ~clk;
            
            // 主控制流程
            begin
                // 延迟 200ns 后释放复位（rst_n 从 0 变为 1）
                #200 rst_n = 1'b1;
                // 运行 2000ns 后结束仿真
                #2000 $finish;
            end
        join
    end

    // 在每个时钟上升沿打印当前的 led 值，便于调试
    always @(posedge clk) begin
        if (rst_n) begin
            // 只有复位释放后才打印（避免复位期间的噪音）
            $display("%0t ns led=%0d", $time, led);
        end
    end
endmodule
