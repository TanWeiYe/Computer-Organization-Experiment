`timescale 1ps/1ps

module tb_template;
    reg clk = 1'b0;
    reg rst_n = 1'b0;
    wire [7:0] out;

    // 实例化 DUT
    template dut (
        .clk(clk), .rst_n(rst_n), .out(out)
    );

    initial begin
        $dumpfile("wave/template.vcd");
        $dumpvars(0, tb_template);

        // 初始化和重置信号
        rst_n = 1'b0;
        #100 rst_n = 1'b1;

        // 运行若干周期观察
        #1000 $display("Finished");
        $finish;
    end

    always #50 clk = ~clk; // 100ps 周期时钟
endmodule
