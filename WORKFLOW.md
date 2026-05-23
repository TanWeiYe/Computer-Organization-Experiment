# 标准工作流

本文件说明作业从编译、仿真到报告更新的完整流程。

## 1. 编译与仿真

统一使用脚本 `scripts/run-sim.bat`（Windows）：

```powershell
.\scripts\run-sim.bat
```

指定题目目录（推荐写完整路径层级 `assignments/<n>/pX`）：

```powershell
.\scripts\run-sim.bat assignments\1\p1
```

脚本默认会：

1. 编译 `src/verilog/*.sv` 与 `tb/*.sv`
2. 运行仿真并生成 `wave/<top>.vcd`
3. 自动打开 GTKWave 查看波形

## 2. 波形截图

在 GTKWave 中手动截图：File → Write → Save Image

保存到：

```
assignments/<n>/pX/docs/wave_s<N>.png
```

## 3. 数据通路图生成

数据通路图由 draw.io（diagrams.net）与 PowerPoint 共同完成：

1. 在 draw.io/PowerPoint 绘制并保存源文件到 `assignments/<n>/pX/docs/`（`.drawio`）
2. 从 draw.io/PowerPoint 导出 SVG 到同目录（`.drawio.svg`）
3. 在报告中引用 SVG

## 4. 报告撰写

报告统一放在：

```
assignments/<n>/docs/
```

报告撰写流程：先写 Markdown，完成后转换为 PDF。

报告中的图片统一使用相对路径（从 `assignments/<n>/docs/` 指向 `pX/docs/`），格式如下：

```
![说明文字](../pX/docs/filename.png)
![说明文字](../pX/docs/filename.svg)
```

在报告中：

- 写清楚测试向量与期望输出
- 引用 `pX/docs/` 下的波形截图
- 填写“实际结果/实际标志/是否正确”对照表

## 5. Markdown 转 PDF

使用 VS Code 的 Markdown PDF 插件导出：

1. 打开 `assignments/<n>/docs/*.md`
2. 右键编辑器 → Markdown PDF: Export (pdf)
3. PDF 会输出到同目录

## 6. 提交材料

提交材料包含以下内容，并按对应目录整理：

- Verilog 代码（`.v`）：`assignments/<n>/pX/src/verilog/`
- Testbench（`.v`）：`assignments/<n>/pX/tb/`
- 仿真波形截图（ModelSim/Vivado/Quartus/GTKWave）：`assignments/<n>/pX/docs/`
- 实验报告 PDF：`assignments/<n>/docs/`
