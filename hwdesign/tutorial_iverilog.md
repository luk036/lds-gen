# Icarus Verilog (iverilog) 使用教程

## 概述

本教程介绍如何使用 Icarus Verilog (iverilog) 来编译和仿真低差异序列 (Low Discrepancy Sequence) 的硬件实现。我们将以 VdCorput、Halton 和 Circle 序列生成器为例，展示完整的开发流程。

## 目录

1. [安装 Icarus Verilog](#安装-icarus-verilog)
2. [项目结构](#项目结构)
3. [VdCorput 序列示例](#vdcorput-序列示例)
4. [Halton 序列示例](#halton-序列示例)
5. [Circle 序列示例](#circle-序列示例)
6. [常见问题与调试](#常见问题与调试)
7. [最佳实践](#最佳实践)

## 安装 Icarus Verilog

### Windows 安装

1. 下载 Icarus Verilog for Windows:
   - 访问 http://bleyer.org/icarus/
   - 下载最新版本的安装程序

2. 运行安装程序，按照提示完成安装

3. 验证安装:
   ```bash
   iverilog -v
   vvp -v
   ```

### Linux/macOS 安装

```bash
# Ubuntu/Debian
sudo apt-get install iverilog

# macOS (使用 Homebrew)
brew install icarus-verilog
```

## 项目结构

```
hwdesign/
├── vdcorput_fsm_32bit_simple.v      # VdCorput 主模块
├── halton_fsm_32bit_simple.v        # Halton 主模块
├── circle_fsm_32bit_simple.v        # Circle 主模块
├── div_mod_3.v                      # 除以3的模块
├── div_mod_7.v                      # 除以7的模块
├── trig_lut_16bit_1024.v            # 三角函数查找表
├── test_vdcorput.v                  # VdCorput 测试文件
├── test_halton.v                    # Halton 测试文件
├── test_circle.v                    # Circle 测试文件
└── tutorial_iverilog.md             # 本教程
```

## VdCorput 序列示例

### 1. 理解 VdCorput 模块

VdCorput (Van der Corput) 序列是最基本的低差异序列。我们的实现特点：
- 32位定点数 (16.16 格式)
- FSM (有限状态机) 顺序实现
- 支持基数 2、3、7

### 2. 编译 VdCorput 测试

```bash
# 进入项目目录
cd hwdesign

# 编译测试文件
iverilog -o vdcorput_test test_vdcorput.v vdcorput_fsm_32bit_simple.v div_mod_3.v div_mod_7.v
```

**参数解释：**
- `-o vdcorput_test`: 指定输出文件名
- `test_vdcorput.v`: 测试文件
- `vdcorput_fsm_32bit_simple.v`: 主模块
- `div_mod_3.v div_mod_7.v`: 依赖模块

### 3. 运行仿真

```bash
# 运行仿真
vvp vdcorput_test
```

**预期输出：**
```
Testing VdCorput sequence generator
===================================
PASS: count=1, base=2, result=00008000, expected=00008000
PASS: count=2, base=2, result=00004000, expected=00004000
PASS: count=3, base=2, result=0000c000, expected=0000c000
...
All tests passed
```

### 4. 查看波形文件 (可选)

如果需要查看详细的波形：

```bash
# 在测试文件中添加波形输出
initial begin
    $dumpfile("vdcorput.vcd");
    $dumpvars(0, test_vdcorput);
end

# 重新编译并运行
iverilog -o vdcorput_test test_vdcorput.v vdcorput_fsm_32bit_simple.v div_mod_3.v div_mod_7.v
vvp vdcorput_test

# 使用 GTKWave 查看波形 (需要安装)
gtkwave vdcorput.vcd
```

## Halton 序列示例

### 1. 理解 Halton 模块

Halton 序列是二维低差异序列，使用两个不同基数的 VdCorput 序列。

### 2. 编译 Halton 测试

```bash
# 编译 Halton 测试
iverilog -o halton_test test_halton.v halton_fsm_32bit_simple.v vdcorput_fsm_32bit_simple.v div_mod_3.v div_mod_7.v
```

**依赖关系：**
- Halton 模块需要 VdCorput 模块
- VdCorput 模块需要 div_mod_3 和 div_mod_7

### 3. 运行仿真

```bash
vvp halton_test
```

**预期输出：**
```
Testing Halton sequence generator
=================================
Testing base combination [2,3]:
PASS: count=1, bases=[2,3], result_x=00008000, result_y=00005555
PASS: count=2, bases=[2,3], result_x=00004000, result_y=0000aaaa
...
All tests passed
```

## Circle 序列示例

### 1. 理解 Circle 模块

Circle 序列在单位圆上生成均匀分布的点，使用 VdCorput 生成角度，然后计算余弦和正弦值。

### 2. 编译 Circle 测试

```bash
# 编译 Circle 测试
iverilog -o circle_test test_circle.v circle_fsm_32bit_simple.v vdcorput_fsm_32bit_simple.v div_mod_3.v div_mod_7.v trig_lut_16bit_1024.v
```

**注意：** Circle 模块需要三角函数查找表 (trig_lut_16bit_1024.v)

### 3. 运行仿真

```bash
vvp circle_test
```

**预期输出：**
```
Testing Circle sequence generator
=================================
Testing base=2:
PASS: count=1, base=2, result_x=ffff0000, result_y=00000000
PASS: count=2, base=2, result_x=00000000, result_y=00010000
...
All tests passed
```

## 常见问题与调试

### 1. 编译错误：语法错误

**问题：**
```
test_file.v:25: syntax error
test_file.v:25: error: malformed statement
```

**解决方案：**
- 检查 Verilog 语法，确保使用兼容的语法
- 避免使用 SystemVerilog 特有的特性
- 检查分号、括号是否匹配

### 2. 编译错误：模块未找到

**问题：**
```
error: Unknown module type: some_module
These modules were missing:
    some_module referenced 1 times.
```

**解决方案：**
- 确保所有依赖模块都在编译命令中
- 检查模块名称拼写是否正确
- 确认文件路径正确

### 3. 仿真错误：无限循环

**问题：** 仿真卡住，不结束

**解决方案：**
- 在测试文件中添加超时保护：
  ```verilog
  initial begin
      #1000000; // 1ms 超时
      $display("Timeout!");
      $finish;
  end
  ```
- 检查 FSM 状态机是否正确转换
- 添加调试输出查看状态

### 4. 定点数精度问题

**问题：** 计算结果与预期有偏差

**解决方案：**
- 检查定点数格式 (16.16)
- 验证乘法和移位操作
- 使用 Python 脚本计算参考值进行对比

## 最佳实践

### 1. 模块化设计

- 每个功能一个模块
- 清晰的接口定义
- 参数化设计便于重用

### 2. 测试驱动开发

- 先写测试，再实现功能
- 覆盖所有边界情况
- 自动化测试流程

### 3. 调试技巧

- 使用 `$display` 输出调试信息
- 生成波形文件分析时序
- 分步验证各个模块

### 4. 性能优化

- 使用流水线设计
- 优化状态机状态数
- 合理使用查找表

## 示例测试文件模板

```verilog
`timescale 1ns/1ps

module test_module;

    parameter CLK_PERIOD = 10;
    reg clk;
    reg rst_n;
    // ... 其他信号

    // 实例化被测模块
    dut_module dut (
        .clk(clk),
        .rst_n(rst_n),
        // ... 其他连接
    );

    // 时钟生成
    always begin
        #(CLK_PERIOD/2) clk = ~clk;
    end

    // 测试任务
    task run_test;
        input [31:0] test_input;
        input [31:0] expected;
        begin
            // 设置输入
            // 启动测试
            // 等待完成
            // 检查结果
            if (result == expected) begin
                $display("PASS: input=%h, result=%h", test_input, result);
            end else begin
                $display("FAIL: input=%h, result=%h, expected=%h",
                         test_input, result, expected);
            end
        end
    endtask

    initial begin
        // 初始化
        clk = 0;
        rst_n = 0;

        // 复位
        #(CLK_PERIOD * 2);
        rst_n = 1;
        #(CLK_PERIOD * 2);

        // 运行测试
        $display("Starting tests...");

        run_test(32'd1, 32'h00008000);
        run_test(32'd2, 32'h00004000);
        // ... 更多测试

        $display("All tests completed");
        $finish;
    end

endmodule
```

## 总结

通过本教程，您应该能够：

1. 安装和配置 Icarus Verilog
2. 编译和仿真低差异序列模块
3. 理解模块间的依赖关系
4. 调试常见问题
5. 编写有效的测试文件

这些技能不仅适用于低差异序列项目，也适用于其他数字电路设计项目。实践是掌握这些工具的最佳方式，建议从简单的模块开始，逐步增加复杂度。

## 扩展学习

1. **官方文档**: 查看 Icarus Verilog 官方文档了解更多特性
2. **波形分析**: 学习使用 GTKWave 进行波形分析
3. **性能分析**: 学习如何分析设计的时序和面积
4. **自动化脚本**: 编写 Makefile 或 Python 脚本自动化测试流程

祝您学习愉快！