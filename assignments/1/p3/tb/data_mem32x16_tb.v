`timescale 1ps/1ps

// 测试平台：data_mem32x16
module data_mem32x16_tb;

    reg clk;
    reg mem_we;
    reg [4:0] addr;
    reg [15:0] wdata;
    reg [1:0] byte_en;
    wire [15:0] rdata;

    // DUT
    data_mem32x16 dut (
        .clk(clk),
        .mem_we(mem_we),
        .addr(addr),
        .wdata(wdata),
        .byte_en(byte_en),
        .rdata(rdata)
    );

    // 波形输出
    initial begin
        $dumpfile("wave/p3_mem.vcd");
        $dumpvars(0, data_mem32x16_tb);
    end

    // 时钟
    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    // 主流程
    initial begin
        mem_we = 1'b0;
        addr = 5'd0;
        wdata = 16'h0000;
        byte_en = 2'b00;

        $display("=== data_mem32x16 testbench started ===");

        // 1) 写完整 16 位
        addr = 5'd4;
        wdata = 16'hABCD;
        byte_en = 2'b11;
        @(posedge clk);
        mem_we = 1'b1; @(posedge clk); mem_we = 1'b0;
        #1;
        if (rdata == 16'hABCD) $display("  [PASS] Read after full write: %h", rdata);
        else $display("  [FAIL] Read after full write: %h", rdata);

        // 2) 只写低字节
        wdata = 16'h00EF;
        byte_en = 2'b01;
        @(posedge clk);
        mem_we = 1'b1; @(posedge clk); mem_we = 1'b0;
        #1;
        if (rdata == 16'hABEF) $display("  [PASS] Read after low byte write: %h", rdata);
        else $display("  [FAIL] Read after low byte write: %h", rdata);

        // 3) 只写高字节
        wdata = 16'h1200;
        byte_en = 2'b10;
        @(posedge clk);
        mem_we = 1'b1; @(posedge clk); mem_we = 1'b0;
        #1;
        if (rdata == 16'h12EF) $display("  [PASS] Read after high byte write: %h", rdata);
        else $display("  [FAIL] Read after high byte write: %h", rdata);

        $display("=== data_mem32x16 testbench finished ===");
        $finish;
    end

endmodule
