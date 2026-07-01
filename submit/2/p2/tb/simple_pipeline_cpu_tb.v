`timescale 1ps/1ps

// simple_pipeline_cpu_tb.v - P2 五级流水线测试平台
// 测试序列包含 ALU/STORE/LOAD，显式 NOP 解决数据冒险

module simple_pipeline_cpu_tb;

    parameter CLK_PERIOD = 100;

    reg             clk;
    reg             rst_n;
    reg             instr_valid;
    reg  [1:0]      instr_op_type;
    reg  [2:0]      instr_rs1, instr_rs2, instr_rd;
    reg  [15:0]     instr_imm;
    reg  [2:0]      instr_alu_op;
    reg  [1:0]      instr_byte_en;
    reg             init_we;
    reg  [2:0]      init_addr;
    reg  [15:0]     init_data;
    reg  [2:0]      debug_reg_addr;
    wire [15:0]     debug_reg_data;
    reg  [4:0]      debug_mem_addr;
    wire [15:0]     debug_mem_data;
    wire [15:0]     debug_if_id_imm;
    wire [15:0]     debug_id_ex_src_a;
    wire [15:0]     debug_id_ex_src_b;
    wire [15:0]     debug_ex_mem_alu_result;
    wire [15:0]     debug_mem_wb_wb_data;

    // 实例化 CPU
    simple_pipeline_cpu dut (
        .clk                    (clk),
        .rst_n                  (rst_n),
        .instr_valid            (instr_valid),
        .instr_op_type          (instr_op_type),
        .instr_rs1              (instr_rs1),
        .instr_rs2              (instr_rs2),
        .instr_rd               (instr_rd),
        .instr_imm              (instr_imm),
        .instr_alu_op           (instr_alu_op),
        .instr_byte_en          (instr_byte_en),
        .init_we                (init_we),
        .init_addr              (init_addr),
        .init_data              (init_data),
        .debug_reg_addr         (debug_reg_addr),
        .debug_reg_data         (debug_reg_data),
        .debug_mem_addr         (debug_mem_addr),
        .debug_mem_data         (debug_mem_data),
        .debug_if_id_imm        (debug_if_id_imm),
        .debug_id_ex_src_a      (debug_id_ex_src_a),
        .debug_id_ex_src_b      (debug_id_ex_src_b),
        .debug_ex_mem_alu_result(debug_ex_mem_alu_result),
        .debug_mem_wb_wb_data   (debug_mem_wb_wb_data)
    );

    // 时钟
    initial begin
        clk = 1'b0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end

    // 主测试流程
    integer cycle;
    reg [7:0] errors;

    initial begin
        errors = 0;
        $dumpfile("wave/simple_pipeline_cpu.vcd");
        $dumpvars(0, simple_pipeline_cpu_tb);

        // ====================================
        // 复位
        // ====================================
        cycle = 0;
        rst_n         = 1'b0;
        instr_valid   = 1'b0;
        instr_op_type = 2'b00;
        instr_rs1     = 3'd0;
        instr_rs2     = 3'd0;
        instr_rd      = 3'd0;
        instr_imm     = 16'd0;
        instr_alu_op  = 3'b000;
        instr_byte_en = 2'b00;
        init_we       = 1'b0;
        init_addr     = 3'd0;
        init_data     = 16'd0;

        @(posedge clk);
        rst_n = 1'b1;
        $display("[Cycle %0d] Reset released", cycle);

        // ====================================
        // 初始化寄存器: R1=0x0004, R2=0x0006, R3=0x1234, R7=0x00FF
        // ====================================
        // 使用 init_we 逐个初始化
        init_reg(1, 16'h0004);
        init_reg(2, 16'h0006);
        init_reg(3, 16'h1234);
        init_reg(7, 16'h00FF);

        // 验证初始化
        debug_reg_addr = 3'd1; #1; check_reg(1, 16'h0004);
        debug_reg_addr = 3'd2; #1; check_reg(2, 16'h0006);
        debug_reg_addr = 3'd3; #1; check_reg(3, 16'h1234);
        debug_reg_addr = 3'd7; #1; check_reg(7, 16'h00FF);

        // ====================================
        // 测试序列（每个周期发一条指令）
        // ====================================

        // Cycle 1: R4 = R1 + R2
        send_instr(1, 2'b01, 3'd1, 3'd2, 3'd4, 16'd0, 3'b000, 2'b00);
        $display("[Cycle %0d] IF: R4 = R1 + R2      ", cycle);

        // Cycle 2: Mem[R1+0] = R3
        send_instr(1, 2'b11, 3'd1, 3'd3, 3'd0, 16'd0, 3'b000, 2'b11);
        $display("[Cycle %0d] IF: Mem[R1+0] = R3    ", cycle);

        // Cycle 3: R5 = Mem[R1+0]
        send_instr(1, 2'b10, 3'd1, 3'd0, 3'd5, 16'd0, 3'b000, 2'b00);
        $display("[Cycle %0d] IF: R5 = Mem[R1+0]    ", cycle);

        // Cycle 4-6: NOP (等待前面的指令完成 WB)
        repeat (3) begin
            send_nop();
            $display("[Cycle %0d] IF: NOP               ", cycle);
        end

        // Cycle 7: R6 = R4 - R2
        send_instr(1, 2'b01, 3'd4, 3'd2, 3'd6, 16'd0, 3'b001, 2'b00);
        $display("[Cycle %0d] IF: R6 = R4 - R2      ", cycle);

        // Cycle 8-13: NOP (等待流水线排空)
        repeat (6) begin
            send_nop();
            $display("[Cycle %0d] IF: NOP               ", cycle);
        end

        // ====================================
        // 验证最终结果
        // ====================================
        $display("\n=== Final Results ===");

        // 每个寄存器检查保持一整周期，便于波形观察
        debug_reg_addr = 3'd4; @(posedge clk); #1; check_reg(4, 16'h000A);
        debug_reg_addr = 3'd5; @(posedge clk); #1; check_reg(5, 16'h1234);
        debug_reg_addr = 3'd6; @(posedge clk); #1; check_reg(6, 16'h0004);
        debug_reg_addr = 3'd0; @(posedge clk); #1; check_reg(0, 16'h0000);
        debug_reg_addr = 3'd7; @(posedge clk); #1; check_reg(7, 16'h00FF);

        debug_mem_addr = 5'd4; @(posedge clk); #1; check_mem(4, 16'h1234);

        $display("\n=== P2 Testbench Complete: %0d errors ===", errors);
        $finish;
    end

    // ============================================================
    // 辅助任务
    // ============================================================

    // 发送一条指令并推进一个周期
    task send_instr;
        input        v;
        input [1:0]  op;
        input [2:0]  rs1, rs2, rd;
        input [15:0] imm;
        input [2:0]  alu;
        input [1:0]  be;
    begin
        @(negedge clk);  // 在时钟下降沿设置，下一个上升沿采样
        instr_valid   = v;
        instr_op_type = op;
        instr_rs1     = rs1;
        instr_rs2     = rs2;
        instr_rd      = rd;
        instr_imm     = imm;
        instr_alu_op  = alu;
        instr_byte_en = be;
        cycle = cycle + 1;
        @(posedge clk);
        #1;  // 等待组合逻辑稳定
    end
    endtask

    // 发送 NOP
    task send_nop;
    begin
        @(negedge clk);
        instr_valid   = 1'b0;
        instr_op_type = 2'b00;
        instr_rs1     = 3'd0;
        instr_rs2     = 3'd0;
        instr_rd      = 3'd0;
        instr_imm     = 16'd0;
        instr_alu_op  = 3'b000;
        instr_byte_en = 2'b00;
        cycle = cycle + 1;
        @(posedge clk);
        #1;
    end
    endtask

    // 初始化一个寄存器
    task init_reg;
        input [2:0]  addr;
        input [15:0] data;
    begin
        @(negedge clk);
        init_we   = 1'b1;
        init_addr = addr;
        init_data = data;
        @(posedge clk);
        #1;
        init_we = 1'b0;
        $display("[Init] R%0d = 0x%04h", addr, data);
    end
    endtask

    // 检查寄存器值
    task check_reg;
        input [2:0]  idx;
        input [15:0] expected;
    begin
        if (debug_reg_data !== expected) begin
            $error("FAIL: R%0d = 0x%04h, expected 0x%04h", idx, debug_reg_data, expected);
            errors = errors + 1;
        end
        else begin
            $display("  PASS: R%0d = 0x%04h", idx, debug_reg_data);
        end
    end
    endtask

    // 检查存储器值
    task check_mem;
        input [4:0]  addr;
        input [15:0] expected;
    begin
        if (debug_mem_data !== expected) begin
            $error("FAIL: Mem[%0d] = 0x%04h, expected 0x%04h", addr, debug_mem_data, expected);
            errors = errors + 1;
        end
        else begin
            $display("  PASS: Mem[%0d] = 0x%04h", addr, debug_mem_data);
        end
    end
    endtask

endmodule
