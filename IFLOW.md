# IFLOW.md - lds-gen 项目指南

## 项目概述

`lds-gen` 是一个用于生成低差异序列（Low Discrepancy Sequence）的 Python 库。该库实现了多种低差异序列生成器，用于创建比随机数更均匀分布的数字序列。这些序列在计算机图形学、数值积分和蒙特卡洛模拟等领域非常有用。

主要实现的序列类型包括：
1. Van der Corput 序列
2. Halton 序列
3. Circle 序列
4. Disk 序列
5. Sphere 序列
6. 3-Sphere Hopf 序列
7. N维 Halton 序列

## 项目结构

```
/home/luk036/github/py/lds-gen/
├── _config.yml
├── .coveragerc
├── .gitignore
├── .isort.cfg
├── .pre-commit-config.yaml
├── .readthedocs.yml
├── AUTHORS.md
├── CHANGELOG.md
├── CONTRIBUTING.md
├── environment.yml
├── GEMINI.md
├── LICENSE
├── LICENSE.txt
├── mypy.ini
├── pyproject.toml
├── README.md
├── requirements.txt
├── setup.cfg
├── setup.py
├── tox.ini
├── .benchmarks/
├── .git/...
├── .github/
│   └── workflows/
├── .mypy_cache/
├── .pytest_cache/
├── docs/
├── experiment/
├── requirements/
├── src/
│   └── lds_gen/
│       ├── __init__.py
│       ├── ilds.py
│       ├── lds.py
│       ├── py.typed
│       ├── skeleton.py
│       └── __pycache__/
└── tests/
    ├── conftest.py
    ├── test_ilds.py
    ├── test_lds.py
    ├── test_skeleton.py
    └── __pycache__/
```

## 核心模块

- `src/lds_gen/lds.py`：包含所有主要的低差异序列生成器类和函数
- `src/lds_gen/ilds.py`：可能包含整数版本的低差异序列生成器
- `src/lds_gen/skeleton.py`：可能包含示例或骨架代码

## 主要功能

### Van der Corput 序列
- `vdc(k, base)` 函数：将整数 k 转换为指定基数的 Van der Corput 序列值
- `VdCorput` 类：Van der Corput 序列生成器，包含 `pop()` 和 `reseed()` 方法

### Halton 序列
- `Halton` 类：使用不同基数的二维低差异序列生成器

### 几何序列
- `Circle` 类：单位圆上的序列生成器
- `Disk` 类：单位圆盘上的序列生成器
- `Sphere` 类：单位球面上的序列生成器
- `Sphere3Hopf` 类：使用 Hopf 纤维化的三维球面序列生成器

### 高维序列
- `HaltonN` 类：N维 Halton 序列生成器

### 工具
- `PRIME_TABLE`：包含前1000个质数的列表，可用于序列的基数

## 使用方法

每个序列生成器类都有 `pop()` 方法来生成序列的下一个值，以及 `reseed()` 方法来重置序列的起始点。

## 构建和测试

### 安装依赖
```
pip install -r requirements.txt
```

### 运行测试
```
pytest tests/
```

### 执行 doctest
由于代码中包含 doctest 示例，可以运行：
```
python -m doctest src/lds_gen/lds.py
```

## 开发约定

- 项目使用 PyScaffold 4.5 创建
- 代码包含类型注解
- 包含 doctest 示例用于文档和测试
- 遵循 PEP 8 代码风格
- 使用 mypy 进行类型检查

## 版本控制

- 主要版本：PyScaffold 4.5
- 使用 setuptools_scm 进行版本管理
- 包含 GitHub Actions 配置文件