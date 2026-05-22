# 题目三：支持 Load/Store 的简化运算与存储数据通路设计

## 1. 设计概述

本题在题目二数据通路基础上加入数据存储器与访存控制信号，实现寄存器型运算、Load、Store 三类操作。

## 2. 模块组成

- `alu16`：16 位运算单元
- `regfile8x16`：8x16 寄存器堆（组合读、同步写，R0 恒为 0）
- `data_mem32x16`：32x16 数据存储器（组合读、同步写，支持字节写使能）

## 3. 关键控制逻辑

- ALU 第二操作数选择：`alu_src_imm` 选择 `imm` 或 `src_b`
- 写回数据选择：`mem_to_reg` 选择 `mem_rdata` 或 `alu_result`
- `init_we` 优先：写地址/写数据由 `init_addr/init_data` 覆盖常规写回

## 4. 测试步骤与预期结果

1. 复位系统
2. 初始化：R1=0x0004，R2=0x0006，R3=0xABCD
3. R4=R1+R2=0x000A
4. R5=R4-R1=0x0006
5. Store：Mem[R1+0]=R3
6. Load：R6=Mem[R1+0]=0xABCD
7. 低字节 Store：Mem[R1+1] 低字节写入 R2[7:0]
8. 高字节 Store：Mem[R1+1] 高字节写入 R3[15:8]
9. 写 R0 验证保护
10. 产生 ALU 结果为 0，验证 `zero` 标志

## 5. 仿真说明

- 波形输出：`wave/p3.vcd`
- 建议观察信号：`src_a`, `src_b`, `alu_result`, `mem_rdata`, `wb_data`, `reg_we`, `mem_we`, `byte_en`, `zero`
