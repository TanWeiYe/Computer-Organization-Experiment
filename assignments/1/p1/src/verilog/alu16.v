`timescale 1ps/1ps

// alu16 模块：实现 16-bit ALU（8 种操作）
// 操作码（alu_op）：
//  3'b000 : ADD  -> result = a + b (无符号 carry-out 有效，signed overflow 有效)
//  3'b001 : SUB  -> result = a - b (carry 表示无借位，即 a >= b，signed overflow 有效)
//  3'b010 : AND  -> result = a & b
//  3'b011 : OR   -> result = a | b
//  3'b100 : XOR  -> result = a ^ b
//  3'b101 : SLL  -> logical left shift: result = a << (b[3:0])
//  3'b110 : SRL  -> logical right shift: result = a >> (b[3:0])
//  3'b111 : CMPU -> unsigned compare: result = (a < b) ? 1 : 0
// 输入：a[15:0], b[15:0], alu_op[2:0]
// 输出：result[15:0], zero, carry, negative, overflow
module alu16 (
    input  wire [15:0] a,
    input  wire [15:0] b,
    input  wire [2:0]  alu_op,
    output reg  [15:0] result,
    output wire        zero,
    output wire         carry,
    output wire        negative,
    output wire        overflow
);

// 结果为 0 的标志
assign zero = (result == 16'h0000);
// 负号由最高位表示
assign negative = result[15];

// 中间信号用于加法/减法的扩展运算
wire [16:0] sum_u; // 无符号扩展用于计算 carry
wire [16:0] sub_u;
assign sum_u = {1'b0, a} + {1'b0, b};
assign sub_u = {1'b0, a} + {1'b0, (~b)} + 17'd1; // a - b = a + (~b) + 1

// 有符号中间结果用于判断 overflow
// 注：不需要额外的有符号中间值，直接用位检测判断 overflow

// 组合逻辑：根据 alu_op 计算 result 与标志
always @(*) begin
    // 默认值
    result = 16'h0000;
    // carry 在外部通过组合逻辑计算

    case (alu_op)
        3'b000: begin // 加法
            result = sum_u[15:0];
            // carry 在外部通过组合逻辑计算
        end
        3'b001: begin // 减法 a - b
            result = sub_u[15:0];
            // carry 在外部通过组合逻辑计算
        end
        3'b010: begin // 与
            result = a & b;
        end
        3'b011: begin // 或
            result = a | b;
        end
        3'b100: begin // 异或
            result = a ^ b;
        end
        3'b101: begin // 左移，逻辑左移
            result = a << b[3:0];
        end
        3'b110: begin // 逻辑右移
            result = a >> b[3:0];
        end
        3'b111: begin // 无符号比较：如果 a < b (unsigned) 则 1 否则 0
            result = (a < b) ? 16'h0001 : 16'h0000;
        end
        default: begin
            result = 16'h0000;
        end
    endcase
end

// overflow 的组合逻辑：仅对加法/减法有效
assign overflow = (alu_op == 3'b000) ? ((a[15] == b[15]) && (result[15] != a[15])) :
                  (alu_op == 3'b001) ? ((a[15] != b[15]) && (result[15] != a[15])) : 1'b0;

// carry 的组合逻辑：加法使用 sum_u[16]，减法使用 sub_u[16]，其它为 0
assign carry = (alu_op == 3'b000) ? sum_u[16] :
               (alu_op == 3'b001) ? sub_u[16] : 1'b0;

endmodule
