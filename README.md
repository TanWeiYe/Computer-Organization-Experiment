# 数字电路开发环境（统一脚本 + 作业源码分离）

本仓库约定：根目录保存工具、脚本与配置；每个作业放在 `assignments/<n>` 下，仅包含源码与测试平台（每道题目可放在 `p1/`、`p2/` 子目录）。

核心目录说明

- `assignments/`：所有作业目录（每份作业内只保留源码和测试平台）
- `build/`：编译产物（根目录共享）
- `wave/`：仿真波形（根目录共享）
- `scripts/`：一键运行与辅助脚本（统一复用）
- `.vscode/`：VS Code 任务与编辑器配置

工具链简介

- `iverilog` / `vvp`：Icarus Verilog 工具链，`iverilog` 将 Verilog/SystemVerilog 源编译为 `.vvp`，`vvp` 运行仿真并可生成 VCD 波形。
- `gtkwave`：打开 `.vcd` 波形文件查看波形。

一键运行（推荐）

根目录提供统一脚本 `scripts/run-sim.bat`（Windows）用于：编译 → 仿真 → 打开波形。使用方式：

1. 运行默认（示例）：

```powershell
.\scripts\run-sim.bat
```

1. 指定作业或题目目录，例如运行 assignments/1 下的 p1：

```powershell
.\scripts\run-sim.bat assignments\1\p1
```

1. 仍然可以使用老接口直接传入顶层和文件（向后兼容）：

```powershell
.\scripts\run-sim.bat top assignments\1\p1\src\verilog\alu16.sv assignments\1\p1\tb\alu16_tb.sv
```

VS Code 集成

- 在 VS Code 的运行任务中选择 `Run: Simulation (choose problem)`，会提示输入作业或题目目录（例如 `assignments\1\p1`）。

实践建议

- 每个作业只放源码和测试平台（`src/`、`tb/`）；所有脚本、工具检测、波形输出放根目录，便于统一维护和复用。
- 若需要保留示例或历史文件，可将其移动到 `examples/` 目录以便参考。

如果你想，我可以：

- 把根 README 增加一节「常见问题与故障排查」；或
- 把当前根任务改为交互式选择已检测到的 `assignments/<n>/p*` 列表。哪一个优先？
