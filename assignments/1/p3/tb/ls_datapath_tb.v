`timescale 1ps/1ps

// 测试平台：ls_datapath
module ls_datapath_tb;

    reg clk;
    reg rst_n;

    reg reg_we;
    reg mem_we;
    reg mem_to_reg;
    reg alu_src_imm;

    reg [2:0] rs1;
    reg [2:0] rs2;
    reg [2:0] rd;
    reg [15:0] imm;
    reg [2:0] alu_op;
    reg [1:0] byte_en;

    reg init_we;
    reg [2:0] init_addr;
    reg [15:0] init_data;

    wire [15:0] src_a;
    wire [15:0] src_b;
    wire [15:0] alu_result;
    wire [15:0] mem_rdata;
    wire [15:0] wb_data;
    wire zero;

    // DUT
    ls_datapath dut (
        .clk(clk),
        .rst_n(rst_n),
        .reg_we(reg_we),
        .mem_we(mem_we),
        .mem_to_reg(mem_to_reg),
        .alu_src_imm(alu_src_imm),
        .rs1(rs1),
        .rs2(rs2),
        .rd(rd),
        .imm(imm),
        .alu_op(alu_op),
        .byte_en(byte_en),
        .init_we(init_we),
        .init_addr(init_addr),
        .init_data(init_data),
        .src_a(src_a),
        .src_b(src_b),
        .alu_result(alu_result),
        .mem_rdata(mem_rdata),
        .wb_data(wb_data),
        .zero(zero)
    );

    // 波形输出
    initial begin
        $dumpfile("wave/p3.vcd");
        $dumpvars(0, ls_datapath_tb);
    end

    // 时钟
    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    // 主流程
    initial begin
        // 初始化控制信号
        rst_n = 1'b0;
        reg_we = 1'b0;
        mem_we = 1'b0;
        mem_to_reg = 1'b0;
        alu_src_imm = 1'b0;
        rs1 = 3'b000;
        rs2 = 3'b000;
        rd = 3'b000;
        imm = 16'h0000;
        alu_op = 3'b000;
        byte_en = 2'b11;
        init_we = 1'b0;
        init_addr = 3'b000;
        init_data = 16'h0000;

        // 复位
        #10 rst_n = 1'b1;

        $display("=== p3 testbench started ===");

        // 1) 初始化寄存器
        $display("\n[Step 1] Init registers:");
        init_we = 1'b1;
        init_addr = 3'b001; init_data = 16'h0004; @(posedge clk);
        init_addr = 3'b010; init_data = 16'h0006; @(posedge clk);
        init_addr = 3'b011; init_data = 16'hABCD; @(posedge clk);
        init_we = 1'b0;
        rs1 = 3'b011; rs2 = 3'b000; // 读取 R3 验证初始化
        #1;
        if (src_a == 16'hABCD) $display("  [PASS] R3 init = 0xABCD");
        else $display("  [FAIL] R3 init = %h", src_a);

        // 2) R4 = R1 + R2 -> 0x000A
        $display("\n[Step 2] R4 = R1 + R2");
        rs1 = 3'b001; rs2 = 3'b010; rd = 3'b100;
        alu_op = 3'b000; // ADD
        alu_src_imm = 1'b0;
        mem_to_reg = 1'b0;
        mem_we = 1'b0;
        @(posedge clk); // 等待 ALU 稳定
        reg_we = 1'b1; @(posedge clk); reg_we = 1'b0;
        if (alu_result == 16'h000A) $display("  [PASS] ALU result = 0x000A");
        else $display("  [FAIL] ALU result = %h", alu_result);

        // 3) R5 = R4 - R1 -> 0x0006
        $display("\n[Step 3] R5 = R4 - R1");
        rs1 = 3'b100; rs2 = 3'b001; rd = 3'b101;
        alu_op = 3'b001; // SUB
        alu_src_imm = 1'b0;
        mem_to_reg = 1'b0;
        mem_we = 1'b0;
        @(posedge clk);
        reg_we = 1'b1; @(posedge clk); reg_we = 1'b0;
        if (alu_result == 16'h0006) $display("  [PASS] ALU result = 0x0006");
        else $display("  [FAIL] ALU result = %h", alu_result);

        // 4) Store: Mem[R1+0] = R3 (addr=4)
        $display("\n[Step 4] Store R3 -> Mem[R1+0]");
        rs1 = 3'b001; rs2 = 3'b011; imm = 16'h0000;
        alu_op = 3'b000; // ADD
        alu_src_imm = 1'b1;
        mem_to_reg = 1'b0;
        byte_en = 2'b11;
        #1;
        $display("  addr=%0d alu_result=%h src_b=%h", alu_result[4:0], alu_result, src_b);
        @(posedge clk);
        mem_we = 1'b1; @(posedge clk); mem_we = 1'b0;
        @(posedge clk); // 等待存储器完成写入

        // 5) Load: R6 = Mem[R1+0] -> 0xABCD
        $display("\n[Step 5] Load Mem[R1+0] -> R6");
        rs1 = 3'b001; imm = 16'h0000; rd = 3'b110;
        alu_op = 3'b000; // ADD
        alu_src_imm = 1'b1;
        mem_to_reg = 1'b1;
        mem_we = 1'b0;
        @(posedge clk);
        reg_we = 1'b1; @(posedge clk); reg_we = 1'b0;
        #1; // 等待组合读稳定
        if (mem_rdata == 16'hABCD) $display("  [PASS] mem_rdata = 0xABCD");
        else $display("  [FAIL] mem_rdata = %h", mem_rdata);

        // 6) Low byte store: Mem[R1+1] low byte = R2[7:0]
        $display("\n[Step 6] Store low byte to Mem[R1+1]");
        rs1 = 3'b001; rs2 = 3'b010; imm = 16'h0001;
        alu_op = 3'b000; // ADD
        alu_src_imm = 1'b1;
        byte_en = 2'b01;
        @(posedge clk);
        mem_we = 1'b1; @(posedge clk); mem_we = 1'b0;
        @(posedge clk); // 等待存储器完成写入

        // 7) High byte store: Mem[R1+1] high byte = R3[15:8]
        $display("\n[Step 7] Store high byte to Mem[R1+1]");
        rs1 = 3'b001; rs2 = 3'b011; imm = 16'h0001;
        alu_op = 3'b000; // ADD
        alu_src_imm = 1'b1;
        byte_en = 2'b10;
        #1;
        $display("  addr=%0d alu_result=%h src_b=%h byte_en=%b", alu_result[4:0], alu_result, src_b, byte_en);
        @(posedge clk);
        mem_we = 1'b1; @(posedge clk); mem_we = 1'b0;
        @(posedge clk); // 等待存储器完成写入

        // 8) Load Mem[R1+1] -> R7 (expect 0xAB06)
        $display("\n[Step 8] Load Mem[R1+1] -> R7");
        rs1 = 3'b001; imm = 16'h0001; rd = 3'b111;
        alu_op = 3'b000; // ADD
        alu_src_imm = 1'b1;
        mem_to_reg = 1'b1;
        mem_we = 1'b0;
        @(posedge clk);
        reg_we = 1'b1; @(posedge clk); reg_we = 1'b0;
        #1; // 等待组合读稳定
        if (mem_rdata == 16'hAB06) $display("  [PASS] mem_rdata = 0xAB06");
        else $display("  [FAIL] mem_rdata = %h", mem_rdata);

        // 9) 尝试写 R0
        $display("\n[Step 9] Write R0 protection");
        rs1 = 3'b001; rs2 = 3'b010; rd = 3'b000;
        alu_op = 3'b000; // ADD
        alu_src_imm = 1'b0;
        mem_to_reg = 1'b0;
        @(posedge clk);
        reg_we = 1'b1; @(posedge clk); reg_we = 1'b0;
        rs1 = 3'b000; rs2 = 3'b000;
        #2;
        if (src_a == 16'h0000) $display("  [PASS] R0 remains 0");
        else $display("  [FAIL] R0 = %h", src_a);

        // 10) 产生 zero 标志
        $display("\n[Step 10] Zero flag check");
        rs1 = 3'b001; rs2 = 3'b001; rd = 3'b001;
        alu_op = 3'b001; // SUB (R1 - R1)
        alu_src_imm = 1'b0;
        mem_to_reg = 1'b0;
        #1; // 等待组合结果更新
        if (zero) $display("  [PASS] zero flag set");
        else $display("  [FAIL] zero flag not set");

        $display("\n=== p3 testbench finished ===");
        $finish;
    end

endmodule
