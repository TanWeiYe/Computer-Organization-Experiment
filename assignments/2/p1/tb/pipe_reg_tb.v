`timescale 1ps/1ps

// pipe_reg_tb.v - 流水线寄存器测试平台
// 验证: 正常传递、stall 保持、flush 清零、优先级（rst_n > flush > stall）
module pipe_reg_tb;

    parameter WIDTH = 8;
    parameter CLK_PERIOD = 100;  // 100ps

    reg             clk;
    reg             rst_n;
    reg             stall;
    reg             flush;
    reg  [WIDTH-1:0] din;
    wire [WIDTH-1:0] dout;

    // 实例化待测模块
    pipe_reg #(.WIDTH(WIDTH)) dut (
        .clk   (clk),
        .rst_n (rst_n),
        .stall (stall),
        .flush (flush),
        .din   (din),
        .dout  (dout)
    );

    // 时钟生成
    initial begin
        clk = 1'b0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end

    // 测试主流程
    initial begin
        // 导出波形
        $dumpfile("wave/pipe_reg.vcd");
        $dumpvars(0, pipe_reg_tb);

        // 初始化
        rst_n = 1'b0;  // 复位有效
        stall = 1'b0;
        flush = 1'b0;
        din   = 8'hAA;

        // ---- 周期 0: 复位状态 ----
        // 在时钟上升沿之前 rst_n=0，dout 应已在复位后为 0
        #(CLK_PERIOD/4);  // 等一小段让复位生效
        $display("[Cycle 0] rst_n=%b stall=%b flush=%b din=0x%02h dout=0x%02h (expect 0x00)",
                 rst_n, stall, flush, din, dout);
        check_output(0, 8'h00);

        // 释放复位，准备周期 1
        @(posedge clk);
        rst_n = 1'b1;
        din   = 8'h11;
        stall = 1'b0;
        flush = 1'b0;

        // ---- 周期 1: 正常传递 ----
        @(posedge clk);
        #1;
        $display("[Cycle 1] rst_n=%b stall=%b flush=%b din=0x%02h dout=0x%02h (expect 0x11)",
                 rst_n, stall, flush, din, dout);
        check_output(1, 8'h11);

        // ---- 周期 2: 正常传递 ----
        din = 8'h22;
        @(posedge clk);
        #1;
        $display("[Cycle 2] rst_n=%b stall=%b flush=%b din=0x%02h dout=0x%02h (expect 0x22)",
                 rst_n, stall, flush, din, dout);
        check_output(2, 8'h22);

        // ---- 周期 3: stall 保持 ----
        stall = 1'b1;
        din   = 8'h33;
        @(posedge clk);
        #1;
        $display("[Cycle 3] rst_n=%b stall=%b flush=%b din=0x%02h dout=0x%02h (expect 0x22 hold)",
                 rst_n, stall, flush, din, dout);
        check_output(3, 8'h22);

        // ---- 周期 4: stall 继续保持 ----
        din = 8'h44;
        @(posedge clk);
        #1;
        $display("[Cycle 4] rst_n=%b stall=%b flush=%b din=0x%02h dout=0x%02h (expect 0x22 hold)",
                 rst_n, stall, flush, din, dout);
        check_output(4, 8'h22);

        // ---- 周期 5: 恢复正常传递 ----
        stall = 1'b0;
        din   = 8'h55;
        @(posedge clk);
        #1;
        $display("[Cycle 5] rst_n=%b stall=%b flush=%b din=0x%02h dout=0x%02h (expect 0x55)",
                 rst_n, stall, flush, din, dout);
        check_output(5, 8'h55);

        // ---- 周期 6: flush 清零 ----
        flush = 1'b1;
        din   = 8'h66;
        @(posedge clk);
        #1;
        $display("[Cycle 6] rst_n=%b stall=%b flush=%b din=0x%02h dout=0x%02h (expect 0x00 flush)",
                 rst_n, stall, flush, din, dout);
        check_output(6, 8'h00);

        // ---- 周期 7: 恢复正常（退出 flush）----
        flush = 1'b0;
        din   = 8'h77;
        @(posedge clk);
        #1;
        $display("[Cycle 7] rst_n=%b stall=%b flush=%b din=0x%02h dout=0x%02h (expect 0x77)",
                 rst_n, stall, flush, din, dout);
        check_output(7, 8'h77);

        // ---- 周期 8: flush 优先级高于 stall ----
        stall = 1'b1;
        flush = 1'b1;
        din   = 8'h88;
        @(posedge clk);
        #1;
        $display("[Cycle 8] rst_n=%b stall=%b flush=%b din=0x%02h dout=0x%02h (expect 0x00 flush>stall)",
                 rst_n, stall, flush, din, dout);
        check_output(8, 8'h00);

        // ---- 周期 9: 确认退出 flush/stall ----
        stall = 1'b0;
        flush = 1'b0;
        din   = 8'h99;
        @(posedge clk);
        #1;
        $display("[Cycle 9] rst_n=%b stall=%b flush=%b din=0x%02h dout=0x%02h (expect 0x99)",
                 rst_n, stall, flush, din, dout);
        check_output(9, 8'h99);

        // 结束
        #(CLK_PERIOD);
        $display("\n=== P1 Testbench Complete ===");
        $finish;
    end

    // 结果检查
    reg [7:0] errors;
    initial errors = 0;

    task check_output;
        input [3:0] cycle;
        input [7:0] expected;
    begin
        if (dout !== expected) begin
            $error("FAIL: Cycle %0d - dout=0x%02h, expected=0x%02h", cycle, dout, expected);
            errors = errors + 1;
        end
    end
    endtask

endmodule
