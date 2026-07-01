`timescale 1ps/1ps

// pipeline_cpu_hazard_tb.v - P3 转发与阻塞测试平台（4 组测试）

module pipeline_cpu_hazard_tb;

    parameter CLK_PERIOD = 100;

    reg             clk, rst_n;
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
    wire [1:0]      debug_forward_a;
    wire [1:0]      debug_forward_b;
    wire            debug_stall;

    pipeline_cpu_hazard dut (
        .clk(clk), .rst_n(rst_n),
        .instr_valid(instr_valid), .instr_op_type(instr_op_type),
        .instr_rs1(instr_rs1), .instr_rs2(instr_rs2), .instr_rd(instr_rd),
        .instr_imm(instr_imm), .instr_alu_op(instr_alu_op), .instr_byte_en(instr_byte_en),
        .init_we(init_we), .init_addr(init_addr), .init_data(init_data),
        .debug_reg_addr(debug_reg_addr), .debug_reg_data(debug_reg_data),
        .debug_mem_addr(debug_mem_addr), .debug_mem_data(debug_mem_data),
        .debug_if_id_imm(debug_if_id_imm),
        .debug_id_ex_src_a(debug_id_ex_src_a),
        .debug_id_ex_src_b(debug_id_ex_src_b),
        .debug_ex_mem_alu_result(debug_ex_mem_alu_result),
        .debug_mem_wb_wb_data(debug_mem_wb_wb_data),
        .debug_forward_a(debug_forward_a),
        .debug_forward_b(debug_forward_b),
        .debug_stall(debug_stall)
    );

    initial begin clk = 1'b0; forever #(CLK_PERIOD/2) clk = ~clk; end

    integer error_count;
    integer cycle;

    initial begin
        error_count = 0;
        $dumpfile("wave/pipeline_cpu_hazard.vcd");
        $dumpvars(0, pipeline_cpu_hazard_tb);

        cycle = 0;
        rst_n = 1'b0; reset_inputs();
        @(posedge clk); rst_n = 1'b1;
        $display("=== P3: Forwarding & Hazard Detection ===");

        test1_alu_forwarding();
        test2_exmem_priority();
        test3_load_use_stall();
        test4_no_dependency();

        $display("\n=== P3 Complete: %0d errors ===", error_count);
        $finish;
    end

    // ================================================================
    // 辅助任务
    // ================================================================
    task reset_inputs;
    begin
        instr_valid=0; instr_op_type=0; instr_rs1=0; instr_rs2=0;
        instr_rd=0; instr_imm=0; instr_alu_op=0; instr_byte_en=0;
        init_we=0;
    end
    endtask

    task tick;
    begin
        @(negedge clk);
        cycle = cycle + 1;
        @(posedge clk); #1;
    end
    endtask

    task send_instr;
        input [1:0] op; input [2:0] rs1,rs2,rd;
        input [15:0] imm; input [2:0] alu; input [1:0] be;
    begin
        @(negedge clk);
        instr_valid=1; instr_op_type=op;
        instr_rs1=rs1; instr_rs2=rs2; instr_rd=rd;
        instr_imm=imm; instr_alu_op=alu; instr_byte_en=be;
        cycle = cycle + 1;
        @(posedge clk); #1;
    end
    endtask

    task send_nop;
    begin
        @(negedge clk);
        instr_valid=0; instr_op_type=0; instr_rs1=0; instr_rs2=0;
        instr_rd=0; instr_imm=0; instr_alu_op=0; instr_byte_en=0;
        cycle = cycle + 1;
        @(posedge clk); #1;
    end
    endtask

    task do_init;
        input [2:0] addr; input [15:0] data;
    begin
        @(negedge clk);
        init_we=1; init_addr=addr; init_data=data;
        @(posedge clk); #1;
        init_we=0;
    end
    endtask

    task drain;
        input integer n;
        integer i;
    begin
        for (i=0; i<n; i=i+1) send_nop();
    end
    endtask

    task check_reg;
        input [2:0] idx; input [15:0] expected; input [8*6:1] name;
    begin
        debug_reg_addr = idx; @(posedge clk); #1;
        if (debug_reg_data !== expected) begin
            $error("FAIL: %0s(R%0d)=0x%04h expect 0x%04h", name, idx, debug_reg_data, expected);
            error_count = error_count+1;
        end else $display("  [OK] %0s = 0x%04h", name, debug_reg_data);
    end
    endtask

    task check_mem;
        input [4:0] addr; input [15:0] expected;
    begin
        debug_mem_addr = addr; #1;
        if (debug_mem_data !== expected) begin
            $error("FAIL: Mem[%0d]=0x%04h expect 0x%04h", addr, debug_mem_data, expected);
            error_count = error_count+1;
        end else $display("  [OK] Mem[%0d] = 0x%04h", addr, debug_mem_data);
    end
    endtask

    // ================================================================
    // 测试 1: ALU→ALU 转发
    //   R4=R1+R2, R5=R4+R3 → EX/MEM 转发 R4
    // ================================================================
    task test1_alu_forwarding;
    begin
        $display("\n--- Test1: ALU->ALU Forwarding ---");
        reset_inputs();
        do_init(1,16'h0004); do_init(2,16'h0006); do_init(3,16'h0003);
        send_nop();
        send_instr(2'b01,1,2,4, 0,3'b000,0); $display("  T1: R4=R1+R2");
        send_instr(2'b01,4,3,5, 0,3'b000,0); $display("  T1: R5=R4+R3 (forward EX/MEM)");
        drain(6);
        check_reg(4,16'h000A,"R4");
        check_reg(5,16'h000D,"R5");
    end
    endtask

    // ================================================================
    // 测试 2: 连续相关 + EX/MEM 优先级
    //   R4=R1+R2, R4=R4+R3, R5=R4+R2
    //   最终 R5 应取 c2 的 R4(7) 而非 c1 的 R4(3)
    // ================================================================
    task test2_exmem_priority;
    begin
        $display("\n--- Test2: EX/MEM Priority ---");
        reset_inputs();
        do_init(1,16'h0001); do_init(2,16'h0002); do_init(3,16'h0004);
        send_nop();
        send_instr(2'b01,1,2,4, 0,3'b000,0); $display("  T2: R4=R1+R2  (=3)");
        send_instr(2'b01,4,3,4, 0,3'b000,0); $display("  T2: R4=R4+R3  (fwd EX/MEM→7)");
        send_instr(2'b01,4,2,5, 0,3'b000,0); $display("  T2: R5=R4+R2  (EX/MEM>MEM/WB)");
        drain(6);
        check_reg(4,16'h0007,"R4");
        check_reg(5,16'h0009,"R5");
    end
    endtask

    // ================================================================
    // 测试 3: Load-use 阻塞
    //   R4=Mem[R1+0], R5=R4+R2 → stall=1 → MEM/WB 转发
    //   先 STORE 初始化 Mem[4]=0x0010
    // ================================================================
    task test3_load_use_stall;
    begin
        $display("\n--- Test3: Load-Use Stall ---");
        reset_inputs();

        // 初始化 R1=4, R3=0x0010(数据), R2=6
        do_init(1,16'h0004);
        do_init(2,16'h0006);
        do_init(3,16'h0010);
        send_nop();

        // 用 STORE 写 Mem[4]=0x0010
        send_instr(2'b11,1,3,0, 0,3'b000,2'b11); $display("  T3: Mem[R1+0]=R3 (Mem[4]=0x0010)");
        drain(4);  // 等 STORE 完成

        // 实际测试: R4=Mem[R1+0], R5=R4+R2
        send_instr(2'b10,1,0,4, 0,3'b000,0); $display("  T3: R4=Mem[R1+0] (LOAD)");
        send_instr(2'b01,4,2,5, 0,3'b000,0); $display("  T3: R5=R4+R2 (load-use→stall)");
        drain(8);
        check_reg(4,16'h0010,"R4");
        check_reg(5,16'h0016,"R5");
    end
    endtask

    // ================================================================
    // 测试 4: 无相关
    //   R4=R1+R2, R5=R3+R6 → forward_a/b=00, stall=0
    // ================================================================
    task test4_no_dependency;
    begin
        $display("\n--- Test4: No Dependency ---");
        reset_inputs();
        do_init(1,16'h0004); do_init(2,16'h0006);
        do_init(3,16'h0002); do_init(6,16'h0008);
        send_nop();
        send_instr(2'b01,1,2,4, 0,3'b000,0); $display("  T4: R4=R1+R2");
        send_instr(2'b01,3,6,5, 0,3'b000,0); $display("  T4: R5=R3+R6 (no dep)");
        drain(6);
        check_reg(4,16'h000A,"R4");
        check_reg(5,16'h000A,"R5");
    end
    endtask

endmodule
