# p2 - 作业说明与运行指南

本目录为 assignments/1 的 p2 题目模板，包含示例设计与测试平台。

运行方法：在仓库根目录执行（Windows）：

```powershell
.\scripts\run-sim.bat assignments\1\p2
```

会生成波形文件 `wave/p2.vcd`，并自动打开 GTKWave（若安装）。

文件说明：

- `src/verilog/p2_design.sv`：示例设计（同步计数器）
- `tb/p2_tb.sv`：对应 testbench，生成 `wave/p2.vcd`

接下来建议：

1. 根据 p2 题目要求替换或实现 `p2_design.sv`。
2. 在 GTKWave 中保存示例截图到 `assignments/1/p2/docs/wave_s<N>.png` 并在 `assignments/1/docs/ALU16_REPORT.md` 或新的报告文件中引用。
