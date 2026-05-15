@echo off
REM ============================================================
REM Verilog 仿真一键脚本 - Windows 版本
REM 用途: 自动完成编译 -> 仿真 -> 波形查看的全流程
REM 用法: run-sim.bat [顶层模块名] [Verilog源文件] [测试平台文件]
REM ============================================================

setlocal enabledelayedexpansion

REM 设置默认参数
if "%~1"=="" (
    rem 默认指向 assignments/1/p1
    set PROBLEM=assignments\1\p1
    set TOP=alu16
    set VERILOG=%PROBLEM%\src\verilog\*.sv
    set TESTBENCH=%PROBLEM%\tb\*.sv
) else (
    rem 如果第一个参数是目录，则视为作业或题目目录
    if exist "%~1" (
        set PROBLEM=%~1
        rem 如果直接包含 src\verilog，则使用它
        if exist "%PROBLEM%\src\verilog" (
            set VERILOG=%PROBLEM%\src\verilog\*.sv
            set TESTBENCH=%PROBLEM%\tb\*.sv
        ) else (
            rem 否则查找 p* 子目录中的第一个
            for /d %%D in ("%PROBLEM%\p*") do (
                set PROBLEM=%%~fD
                goto :FOUND_PROBLEM
            )
            :FOUND_PROBLEM
            set VERILOG=%PROBLEM%\src\verilog\*.sv
            set TESTBENCH=%PROBLEM%\tb\*.sv
        )
        rem 顶层名取目录名
        for %%F in ("%PROBLEM%") do set TOP=%%~nxf
    ) else (
        rem 回退到老接口：传入 TOP VERILOG TESTBENCH
        set TOP=%~1
        set VERILOG=%~2
        set TESTBENCH=%~3
    )
)

REM 定义输出目录
set BUILD_DIR=build\sim
set WAVE_DIR=wave

echo.
echo ============================================================
echo Verilog 仿真管道
echo ============================================================
echo 顶层模块: %TOP%
echo Verilog 源: %VERILOG%
echo 测试平台: %TESTBENCH%
echo.

REM 创建输出目录（如果不存在）
mkdir "%BUILD_DIR%" 2>nul
mkdir "%WAVE_DIR%" 2>nul

REM 第 1 步：编译 Verilog 源码
echo [1/3] 正在编译 Verilog...
iverilog -g2012 -Wall -o "%BUILD_DIR%\%TOP%.vvp" "%VERILOG%" "%TESTBENCH%"
if errorlevel 1 (
    echo.
    echo 错误：编译失败！请检查源文件语法。
    exit /b 1
)
echo 完成！
echo.

REM 第 2 步：运行仿真
echo [2/3] 正在运行仿真...
vvp "%BUILD_DIR%\%TOP%.vvp"
if errorlevel 1 (
    echo.
    echo 错误：仿真失败！
    exit /b 1
)
echo 完成！
echo.

REM 第 3 步：打开波形查看器
echo [3/3] 打开波形查看器...
if exist "%WAVE_DIR%\%TOP%.vcd" (
    gtkwave "%WAVE_DIR%\%TOP%.vcd"
) else (
    echo 警告：未找到波形文件 %WAVE_DIR%\%TOP%.vcd
)

echo.
echo 流程结束！
echo ============================================================
