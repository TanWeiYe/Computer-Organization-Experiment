`timescale 1ps/1ps

module tb_p2;
    // 信号
    reg clk;
    reg rst_n;
    wire [7:0] out;

    // DUT
    p2_design dut (
        .clk(clk),
        .rst_n(rst_n),
        .out(out)
    );

    // 波形输出
    initial begin
        $dumpfile("wave/p2.vcd");
        $dumpvars(0, tb_p2);
    end

    // 主测试流程
    initial begin
        clk = 1'b0; rst_n = 1'b0;
        #10 rst_n = 1'b1;
        // 产生几个时钟周期并观察输出
        repeat (40) begin
            #5 clk = ~clk;
        end
        $display("p2 testbench finished. out=%0h", out);
        $finish;
    end

endmodule
