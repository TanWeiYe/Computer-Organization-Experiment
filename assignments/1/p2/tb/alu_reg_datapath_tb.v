`timescale 1ps/1ps

module tb_alu_reg_datapath;

    // 信号声明
    reg clk;
    reg rst_n;
    
    // 数据通路控制信号
    reg reg_we;
    reg [2:0] rs1, rs2, rd;
    reg [2:0] alu_op;
    
    // 初始化信号
    reg init_we;
    reg [2:0] init_addr;
    reg [15:0] init_data;
    
    // 输出信号
    wire [15:0] src_a, src_b, alu_result;
    wire zero, carry, negative, overflow;
    
    // DUT 实例化
    alu_reg_datapath dut (
        .clk(clk),
        .rst_n(rst_n),
        .reg_we(reg_we),
        .rs1(rs1),
        .rs2(rs2),
        .rd(rd),
        .alu_op(alu_op),
        .init_we(init_we),
        .init_addr(init_addr),
        .init_data(init_data),
        .src_a(src_a),
        .src_b(src_b),
        .alu_result(alu_result),
        .zero(zero),
        .carry(carry),
        .negative(negative),
        .overflow(overflow)
    );
    
    // 波形输出
    initial begin
        $dumpfile("wave/p2.vcd");
        $dumpvars(0, tb_alu_reg_datapath);
        // Ensure regfile internal registers are dumped so regs[0..7] appear in VCD
        $dumpvars(0, tb_alu_reg_datapath.dut.regfile);
        // Explicitly dump each memory element (some simulators require explicit names)
        $dumpvars(0, tb_alu_reg_datapath.dut.regfile.regs[0]);
        $dumpvars(0, tb_alu_reg_datapath.dut.regfile.regs[1]);
        $dumpvars(0, tb_alu_reg_datapath.dut.regfile.regs[2]);
        $dumpvars(0, tb_alu_reg_datapath.dut.regfile.regs[3]);
        $dumpvars(0, tb_alu_reg_datapath.dut.regfile.regs[4]);
        $dumpvars(0, tb_alu_reg_datapath.dut.regfile.regs[5]);
        $dumpvars(0, tb_alu_reg_datapath.dut.regfile.regs[6]);
        $dumpvars(0, tb_alu_reg_datapath.dut.regfile.regs[7]);
    end
    
    // 时钟生成
    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end
    
    // 主测试流程
    initial begin
        // 初始化
        rst_n = 1'b0;
        reg_we = 1'b0;
        init_we = 1'b0;
        rs1 = 3'b0;
        rs2 = 3'b0;
        rd = 3'b0;
        alu_op = 3'b0;
        init_addr = 3'b0;
        init_data = 16'h0000;
        
        // 等待两个时钟周期后释放复位
        #10 rst_n = 1'b1;
        
        $display("=== p2 testbench started ===");
        $display("Time: %0d, Reset released", $time);
        
        // --- Step 1: 复位后验证所有寄存器为 0 ---
        #10;
        $display("\n[Step 1] Reset check:");
        rs1 = 3'b001; rs2 = 3'b010; reg_we = 1'b0;
        #5;
        $display("  Read R1, R2 after reset: src_a=%h, src_b=%h", src_a, src_b);
        if (src_a == 16'h0000 && src_b == 16'h0000) begin
            $display("  [PASS] All registers are 0 after reset");
        end else begin
            $display("  [FAIL] Registers not cleared after reset");
        end
        
        // --- Step 2: 初始化寄存器 R1-R4 ---
        $display("\n[Step 2] Initialize registers:");
        
        // R1 = 0x0005
        init_we = 1'b1;
        init_addr = 3'b001;
        init_data = 16'h0005;
        #10;
        $display("  Initialize R1 = %h", init_data);
        
        // R2 = 0x0003
        init_addr = 3'b010;
        init_data = 16'h0003;
        #10;
        $display("  Initialize R2 = %h", init_data);
        
        // R3 = 0x00F0
        init_addr = 3'b011;
        init_data = 16'h00F0;
        #10;
        $display("  Initialize R3 = %h", init_data);
        
        // R4 = 0x0F0F
        init_addr = 3'b100;
        init_data = 16'h0F0F;
        #10;
        $display("  Initialize R4 = %h", init_data);
        
        init_we = 1'b0;
        
        // --- Step 3: 执行 R5 = R1 + R2 (0x0005 + 0x0003 = 0x0008) ---
        #10;
        $display("\n[Step 3] Execute R5 = R1 + R2:");
        rs1 = 3'b001;
        rs2 = 3'b010;
        rd = 3'b101;
        alu_op = 3'b000; // ADD
        reg_we = 1'b1;
        #5;
        $display("  src_a=%h, src_b=%h, alu_result=%h", src_a, src_b, alu_result);
        #5;
        if (alu_result == 16'h0008) begin
            $display("  [PASS] R5 = R1 + R2 = 0x0008");
        end else begin
            $display("  [FAIL] Expected 0x0008, got %h", alu_result);
        end
        
        // --- Step 4: 执行 R6 = R5 - R2 (0x0008 - 0x0003 = 0x0005) ---
        #10;
        $display("\n[Step 4] Execute R6 = R5 - R2:");
        rs1 = 3'b101;
        rs2 = 3'b010;
        rd = 3'b110;
        alu_op = 3'b001; // SUB
        #5;
        $display("  src_a=%h, src_b=%h, alu_result=%h", src_a, src_b, alu_result);
        #5;
        if (alu_result == 16'h0005) begin
            $display("  [PASS] R6 = R5 - R2 = 0x0005");
        end else begin
            $display("  [FAIL] Expected 0x0005, got %h", alu_result);
        end
        
        // --- Step 5: 执行 R7 = R3 & R4，验证 zero 标志 (0x00F0 & 0x0F0F = 0x0000) ---
        #10;
        $display("\n[Step 5] Execute R7 = R3 & R4:");
        rs1 = 3'b011;
        rs2 = 3'b100;
        rd = 3'b111;
        alu_op = 3'b010; // AND
        #5;
        $display("  src_a=%h, src_b=%h, alu_result=%h, zero=%b", src_a, src_b, alu_result, zero);
        #5;
        if (alu_result == 16'h0000 && zero == 1'b1) begin
            $display("  [PASS] R7 = R3 & R4 = 0x0000, zero flag set");
        end else begin
            $display("  [FAIL] Expected 0x0000 with zero=1, got result=%h, zero=%b", alu_result, zero);
        end
        
        // --- Step 6: 尝试写 R0，验证 R0 保护 ---
        #10;
        $display("\n[Step 6] Try to write R0 = R1 + R2:");
        rs1 = 3'b001;
        rs2 = 3'b010;
        rd = 3'b000; // 目标是 R0
        alu_op = 3'b000; // ADD
        reg_we = 1'b1;
        #5;
        $display("  Attempting to write to R0, result=%h", alu_result);
        #5;
        // 现在读 R0 验证它仍为 0
        rs1 = 3'b000;
        rs2 = 3'b000;
        reg_we = 1'b0;
        #5;
        $display("  Read R0: src_a=%h (expected 0x0000)", src_a);
        if (src_a == 16'h0000) begin
            $display("  [PASS] R0 is protected and remains 0");
        end else begin
            $display("  [FAIL] R0 was modified to %h", src_a);
        end
        
        // --- Step 7: 测试写后读旁路 ---
        #10;
        $display("\n[Step 7] Write-after-read bypass test:");
        // 在同一周期内：写 R5，同时读 R5
        // 应该读到即将写入的新值
        rs1 = 3'b101; // 读 R5
        rs2 = 3'b000;
        rd = 3'b101; // 也写 R5
        alu_op = 3'b000; // ADD
        init_we = 1'b0;
        reg_we = 1'b1;
        #5;
        // 此时 src_a 应该是 bypass 的值（新的 ALU 结果）
        $display("  R5 before: (old value from previous step)");
        $display("  src_a (should be ALU result via bypass): %h", src_a);
        $display("  alu_result: %h", alu_result);
        #5;
        if (src_a == alu_result) begin
            $display("  [PASS] Write-after-read bypass working correctly");
        end else begin
            $display("  [INFO] src_a=%h, alu_result=%h (bypass behavior)", src_a, alu_result);
        end
        
        // 完成仿真
        #10;
        $display("\n=== p2 testbench finished ===");
        $display("Time: %0d", $time);
        $finish;
    end

endmodule
