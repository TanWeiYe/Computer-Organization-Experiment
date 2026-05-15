`timescale 1ns/1ps
module tb_alu16;
    // DUT 接口
    reg  [15:0] a;
    reg  [15:0] b;
    reg  [2:0]  alu_op;
    wire [15:0] result;
    wire        zero;
    wire        carry;
    wire        negative;
    wire        overflow;

    // 实例化 ALU
    alu16 dut (
        .a(a), .b(b), .alu_op(alu_op), .result(result),
        .zero(zero), .carry(carry), .negative(negative), .overflow(overflow)
    );

    // 波形
    initial begin
        $dumpfile("wave/alu16.vcd");
        $dumpvars(0, tb_alu16);
    end

    // 简单断言任务：比较 DUT 输出与期望
    task check;
        input [15:0] exp_res;
        input        exp_zero;
        input        exp_carry;
        input        exp_negative;
        input        exp_overflow;
        input [256:0] note;
        begin
            #5; // 等待组合逻辑稳定
            if (result !== exp_res || zero !== exp_zero || carry !== exp_carry || negative !== exp_negative || overflow !== exp_overflow) begin
                $display("[FAIL] %s : a=%h b=%h op=%b -> got res=%h z=%b c=%b n=%b o=%b, expected res=%h z=%b c=%b n=%b o=%b",
                    note, a, b, alu_op, result, zero, carry, negative, overflow, exp_res, exp_zero, exp_carry, exp_negative, exp_overflow);
            end else begin
                $display("[PASS] %s : a=%h b=%h op=%b -> res=%h z=%b c=%b n=%b o=%b",
                    note, a, b, alu_op, result, zero, carry, negative, overflow);
            end
        end
    endtask

    initial begin
        // 初始化
        a = 16'h0000; b = 16'h0000; alu_op = 3'b000;
        #10;

        // 测试向量：加法 0003 + 0005 = 0008
        a = 16'h0003; b = 16'h0005; alu_op = 3'b000; check(16'h0008, 1'b0, 1'b0, 1'b0, 1'b0, "add simple"); #10;

        // 加法：FFFF + 0001 = 0000, carry=1, overflow=0
        a = 16'hFFFF; b = 16'h0001; alu_op = 3'b000; check(16'h0000, 1'b1, 1'b1, 1'b0, 1'b0, "add wrap carry"); #10;

        // 加法：7FFF + 0001 = 8000, carry=0, overflow=1 (signed)
        a = 16'h7FFF; b = 16'h0001; alu_op = 3'b000; check(16'h8000, 1'b0, 1'b0, 1'b1, 1'b1, "add signed overflow"); #10;

        // 减法：0008 - 0003 = 0005, carry=1 (no borrow), overflow=0
        a = 16'h0008; b = 16'h0003; alu_op = 3'b001; check(16'h0005, 1'b0, 1'b1, 1'b0, 1'b0, "sub simple"); #10;

        // 减法：0005 - 0005 = 0000，验证 zero 标志
        a = 16'h0005; b = 16'h0005; alu_op = 3'b001; check(16'h0000, 1'b1, 1'b1, 1'b0, 1'b0, "sub zero"); #10;

        // 与：00F0 & 0F0F = 0000 (zero)
        a = 16'h00F0; b = 16'h0F0F; alu_op = 3'b010; check(16'h0000, 1'b1, 1'b0, 1'b0, 1'b0, "and zero"); #10;

        // 或：00F0 | 0F0F = 0FFF
        a = 16'h00F0; b = 16'h0F0F; alu_op = 3'b011; check(16'h0FFF, 1'b0, 1'b0, 1'b0, 1'b0, "or"); #10;

        // 异或：00FF ^ 0F0F = 0FF0
        a = 16'h00FF; b = 16'h0F0F; alu_op = 3'b100; check(16'h0FF0 , 1'b0, 1'b0, 1'b0, 1'b0, "xor"); #10;

        // 左移：0001 << 4 = 0010
        a = 16'h0001; b = 16'h0004; alu_op = 3'b101; check(16'h0010, 1'b0, 1'b0, 1'b0, 1'b0, "lshift"); #10;

        // 逻辑右移：8000 >> 4 = 0800 (logical)
        a = 16'h8000; b = 16'h0004; alu_op = 3'b110; check(16'h0800, 1'b0, 1'b0, 1'b0, 1'b0, "lshr"); #10;

        // 无符号比较：0xFFFE (65534) < 0x0001 (1) -> false (result=0)
        a = 16'hFFFE; b = 16'h0001; alu_op = 3'b111; check(16'h0000, 1'b1, 1'b0, 1'b0, 1'b0, "cmpu false"); #10;

        // 无符号比较：0x0005 (5) < 0xFFFF (65535) -> true (result=1)
        a = 16'h0005; b = 16'hFFFF; alu_op = 3'b111; check(16'h0001, 1'b0, 1'b0, 1'b0, 1'b0, "cmpu true"); #10;

        $display("Testbench finished.");
        $finish;
    end

endmodule
