# 计组作业仓库

本仓库及其中作业在 GitHub Copilot 辅助下完成。

本 README 仅说明仓库结构与约定。具体工作流请看根目录的 [WORKFLOW.md](WORKFLOW.md)。

## 1. 目录结构

跳转：见第 3 节 [assignments/<n> 结构说明（最小模板）](#assignments-n-structure)

```
.
├─ assignments/
│  └─ <n>/                      # 见第 3 节
├─ submit/                      # 提交材料（按作业号归档）
├─ build/                       # 编译产物（统一输出）
├─ wave/                        # 波形输出（统一输出 .vcd）
├─ scripts/                     # 一键脚本
├─ src/                         # 顶层源码
├─ tb/                          # 顶层测试
├─ .vscode/                     # VS Code 任务/配置
├─ README.md
└─ WORKFLOW.md
```

## 2. 工具清单

- Icarus Verilog：`iverilog` / `vvp`
- GTKWave：`gtkwave`

## 2.1 提交材料目录

提交材料统一放在 `submit/<n>/`，可直接压缩为 zip 提交。

每次作业在 `submit/<n>/docs/` 中新增：`2419040125-谭炜烨.txt`。
内容为：

```
完整工程请参考以下仓库：
https://github.com/TanWeiYe/Computer-Organization-Experiment
```

```
submit/<n>/
├─ docs/                         # 汇总报告 PDF
└─ p1/
   ├─ src/verilog/               # 题目源码
   ├─ tb/                        # 题目测试平台
   └─ docs/                      # 波形截图/图表

```

<a id="assignments-n-structure"></a>

## 3. assignments/<n> 结构说明（最小模板）

新建一个题目时建议包含以下最小结构，并保持命名一致，方便脚本自动识别：

```
assignments/<n>/
├─ docs/                         # 本次作业汇总报告（MD/PDF）
└─ p1/                            # 题目目录（p1/p2/p3...）
 ├─ src/verilog/                 # 设计源码
 │  └─ <design>.v
 ├─ tb/                          # 测试平台
 │  └─ <design>_tb.v
 └─ docs/                        # 题目素材（截图/图表）
```

推荐约定：

- `docs/` 下只放报告与导出的 PDF，不混放素材。
- 题目素材统一放在 `pX/docs/`，便于引用与复用。
- 设计源码与 testbench 保持 1:1 对应命名，便于脚本自动编译。
