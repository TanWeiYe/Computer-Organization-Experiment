# 数字电路作业仓库（统一脚本 + 作业源码分离）

本 README 说明工作流与文件夹架构，目标是让你下次仅依靠此文档即可独立完成作业。

## 1. 目录结构

```
.
├─ assignments/
│  ├─ <n>/
│  │  ├─ docs/                # 作业报告（Markdown / PDF 等）
│  │  └─ p1/                   # 题目目录（p1/p2/...
│  │     ├─ src/verilog/       # 设计源码（.sv）
│  │     ├─ tb/                # 测试平台（testbench）
│  │     └─ docs/              # 波形截图等素材（wave_s*.png）
├─ build/                      # 编译产物（统一输出）
├─ wave/                       # 波形输出（统一输出 .vcd）
├─ scripts/                    # 一键脚本
└─ .vscode/                    # VS Code 任务/配置
```

## 2. 工具清单

- Icarus Verilog：`iverilog` / `vvp`
- GTKWave：`gtkwave`

## 3. 标准工作流

### 3.1 编译与仿真

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

### 3.2 波形截图

在 GTKWave 中选择 File → Write → Save Image，将截图保存到：

```
assignments/<n>/pX/docs/wave_s<N>.png
```

示例：

```
assignments/1/p1/docs/wave_s1.png
```

### 3.3 报告更新

报告统一放在：

```
assignments/<n>/docs/
```

建议在报告中：

- 写清楚测试向量与期望输出
- 引用 `pX/docs/` 下的波形截图
- 填写“实际结果/实际标志/是否正确”对照表

## 4. 新作业的最小模板

新建一个题目时建议包含以下最小结构：

```
assignments/<n>/
├─ docs/
└─ p1/
 ├─ src/verilog/
 │  └─ <design>.sv
 ├─ tb/
 │  └─ <design>_tb.sv
 └─ docs/
```
