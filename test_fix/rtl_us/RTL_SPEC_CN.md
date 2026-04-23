# `test_fix` 顺序双发射 RTL 中文 SPEC

## 1. 目标与边界
- 本版本在原始 `test_fix/rtl_us` 单发射 RV32I 子集 CPU 上，扩展为顺序双发射。
- 双发射规则固定为：
  - `slot0` 必须是 LOAD/STORE。
  - `slot1` 必须是非 LOAD/STORE、非 branch/jal/jalr 的执行类指令。
  - 两条指令必须保持程序顺序，且不存在 `RAW/WAW` 同拍冲突。
- 架构不引入 ROB/退休队列，不支持任意映射双发。
- 功能范围保持为原始 `maincontroller.v` 已支持的 37 条指令：
  - 算术逻辑：`add/sub/addi/and/andi/or/ori/xor/xori`
  - 比较：`slt/slti/sltu/sltiu`
  - 移位：`sll/slli/srl/srli/sra/srai`
  - 控制转移：`beq/bne/blt/bge/bltu/bgeu/jal/jalr`
  - 访存：`lb/lbu/lh/lhu/lw/sb/sh/sw`
  - 立即数高位：`lui/auipc`

## 2. 总体结构
- 顶层模块：[cpu_core.v](/f:/桌面/test/test_fix/rtl_us/cpu_core.v)
  - 负责连接前端、发射队列和后端。
  - 负责对前端取回的 1/2 条指令调用原有 `instr_Decode + maincontroller` 完成译码，并打包成 uop。
- 前端模块：[frontend_if_local.v](/f:/桌面/test/test_fix/rtl_us/frontend_if_local.v)
  - 使用本地 `instr_rom`，不走 Wishbone。
  - 使用原有 `Branch_PreDecode` 和 `BranchPredictor_1bit_SingleEntry`。
  - 当队列空位足够且当前取指点不是 `predicted-taken` 条件分支时，允许双取。
- 发射队列：[issue_queue.v](/f:/桌面/test/test_fix/rtl_us/issue_queue.v)
  - 存储 `pc / instr / uop`。
  - 只暴露队首两条作为 `head0/head1`。
- 发射选择：[issue_select.v](/f:/桌面/test/test_fix/rtl_us/issue_select.v)
  - 只决定当前拍 `slot0/slot1` 是否发射。
- 后端数据通路：[data_path.v](/f:/桌面/test/test_fix/rtl_us/data_path.v)
  - `LS lane`：统一承载所有老指令，保持 `EX -> MEM -> WB` 三段。
  - `X lane`：承载配对发射的年轻执行类指令，使用 `EX1 -> MEM1 -> WB1` 对齐提交。
- 前递和冒险：
  - [Forwarding_unit_fastcomp_dual.v](/f:/桌面/test/test_fix/rtl_us/Forwarding_unit_fastcomp_dual.v)
  - [Hazard_detection_fastcomp_dual.v](/f:/桌面/test/test_fix/rtl_us/Hazard_detection_fastcomp_dual.v)

## 3. 保留与复用的原始模块
- 原始组合译码器仍保留：
  - [instr_Decode.v](/f:/桌面/test/test_fix/rtl_us/instr_Decode.v)
  - [maincontroller.v](/f:/桌面/test/test_fix/rtl_us/maincontroller.v)
- 原始执行叶子模块仍保留：
  - [ALU.v](/f:/桌面/test/test_fix/rtl_us/ALU.v)
  - [sub_fastcomp.v](/f:/桌面/test/test_fix/rtl_us/sub_fastcomp.v)
- 原始控制辅助模块仍保留：
  - [Branch_PreDecode.v](/f:/桌面/test/test_fix/rtl_us/Branch_PreDecode.v)
  - [BranchPredictor_1bit_SingleEntry.v](/f:/桌面/test/test_fix/rtl_us/BranchPredictor_1bit_SingleEntry.v)
  - [general.v](/f:/桌面/test/test_fix/rtl_us/general.v) 中的 `ControlSignalUnbinder`
- 原始本地存储模型继续保留为当前框架的内存接口：
  - [instr_rom.v](/f:/桌面/test/test_fix/rtl_us/instr_rom.v)
  - [data_ram.v](/f:/桌面/test/test_fix/rtl_us/data_ram.v)

## 4. `issue_uop` 定义
- 头文件：[issue_uop.vh](/f:/桌面/test/test_fix/rtl_us/issue_uop.vh)
- 队列中每条 uop 的位域如下：
  - `rs1[4:0]`
  - `rs2[4:0]`
  - `rd[4:0]`
  - `imm[31:0]`
  - `ALUctrl[3:0]`
  - `control_bus[36:0]`
  - `use_rs1`
  - `use_rs2`
  - `writes_rd`
  - `is_ls`
  - `is_ctrl`
  - `is_pairable_x`
  - `pred_taken`
- 设计原则：
  - `pc` 和 `instr` 单独存放在队列中，便于调试与提交跟踪。
  - `control_bus` 继续沿用原始单发版本的 37-bit 编码，避免重写控制逻辑。

## 5. 发射队列与发射规则
### 5.1 `issue_queue`
- 参数化深度，当前默认 8。
- 单拍最多 `push2 + pop2`。
- `flush` 时清空整个队列。
- 只提供队首两条候选，不做深窗口挑选。

### 5.2 `issue_select`
- `slot0_issue = head0_valid && !slot0_blocked`
- `slot1_issue` 必须同时满足：
  - `dual_issue_enable = 1`
  - `slot0_issue = 1`
  - `head0.is_ls = 1`
  - `head1.is_pairable_x = 1`
  - `head1` 无同拍 `RAW/WAW` 冲突
  - `head1` 本身不被旧 load-use 冒险阻塞
- 因此只允许 `older LS -> younger X` 双发。

### 5.3 明确禁止的双发情况
- `ALU -> LS`
- `LS -> LS`
- `ALU -> ALU`
- 任意包含 `branch/jal/jalr` 的双发
- `head1` 读取 `head0.rd`
- `head0` 与 `head1` 同拍写同一个 `rd`

## 6. 冒险与前递
### 6.1 冒险检测
- 当前只对“前一拍进入 `EX0` 的 load”做阻塞判断。
- 若 `head0` 依赖 `EX0.load.rd`，则 `slot0_blocked=1`，整个发射停住。
- 若 `head1` 依赖 `EX0.load.rd`，则 `slot1_blocked=1`，允许 `slot0` 单发。

### 6.2 前递来源优先级
- `EX1`
- `EX0`（仅非 load）
- `MEM1`
- `MEM0`
- `WB1`
- `WB0`
- `RF`

### 6.3 分支比较前递
- 条件分支在发射点直接使用 `sub_fastcomp` 比较 `issue0_rs1_eff/issue0_rs2_eff`。
- 因此分支判断优先在发射阶段完成，而不是推迟到 MEM/WB。

## 7. 控制流与 Flush
- 条件分支继续用 IF 侧预解码 + 1-bit 预测器做投机取指。
- `jal/jalr` 不预测，到发射点一律重定向。
- `front_flush` 触发条件：
  - `jal`
  - `jalr`
  - 条件分支实际结果与 `pred_taken` 不一致
- Flush 时行为：
  - 清空 `issue_queue`
  - `frontend_if_local` 将取指 PC 重定向到实际下一条地址
- 条件分支预测正确时：
  - 不 flush
  - 仅更新 1-bit 预测器状态

## 8. 本地存储模型
### 8.1 `instr_rom`
- 通过 `+memhex=<path>` 从测试框架加载程序镜像。
- 支持单条读出 `rdata` 和顺序双取用的 `rdata_pair`。

### 8.2 `data_ram`
- 同样通过 `+memhex=<path>` 加载初始镜像。
- 使用本地数组模型，保持：
  - 组合读
  - 时钟写
  - `sb/sh/sw`
  - `lb/lbu/lh/lhu/lw`

## 9. 顶层提交接口
- `cpu_core` 对外新增两组提交信号：
  - `commit0_valid/pc/insn/rd/rd_wdata/mem_addr/mem_rmask/mem_wmask/mem_rdata/mem_wdata`
  - `commit1_valid/...`
- 语义：
  - `commit0` 永远代表更老的提交通路
  - `commit1` 只用于年轻的 `X lane`
  - `commit1` 的访存字段固定为 0

## 10. 本地测试框架
- 测试入口：
  - [tb_top_local.v](/f:/桌面/test/test_fix/tb/tb_top_local.v)
  - [run_test_local.py](/f:/桌面/test/test_fix/tools/run_test_local.py)
- 汇编构建与 trace 对比沿用之前工程的思路：
  - [build_test.py](/f:/桌面/test/test_fix/tools/build_test.py)
  - [compare_trace.py](/f:/桌面/test/test_fix/tools/compare_trace.py)
  - [rv32i_ref_subset37.py](/f:/桌面/test/test_fix/tools/rv32i_ref_subset37.py)

### 10.1 结束协议
- 不使用 trap 结束仿真。
- 约定向固定签名地址 `0x00001000` 执行 `sw`：
  - 写入 `1` 表示 PASS
  - 写入 `2` 表示 FAIL
- `tb_top_local` 监视 `commit0` 的 store 提交，一旦命中签名地址就结束仿真。

### 10.2 当前回归集
- [smoke_basic.S](/f:/桌面/test/test_fix/tests/smoke_basic.S)
- [hazard_data.S](/f:/桌面/test/test_fix/tests/hazard_data.S)
- [hazard_control.S](/f:/桌面/test/test_fix/tests/hazard_control.S)
- [dual_issue_load_alu.S](/f:/桌面/test/test_fix/tests/dual_issue_load_alu.S)
- [dual_issue_mixed.S](/f:/桌面/test/test_fix/tests/dual_issue_mixed.S)
- [dual_issue_seq.S](/f:/桌面/test/test_fix/tests/dual_issue_seq.S)
- [alu_then_ls_block.S](/f:/桌面/test/test_fix/tests/alu_then_ls_block.S)

## 11. 当前实现特性总结
- `+dual=0` 时，CPU 回到单发模式，`lane1` 不提交。
- `+dual=1` 时，仅允许 `LS -> X` 配对。
- 正向双发样例中 `lane1_commits > 0`。
- 负向样例中 `lane1_commits = 0`。
- `rtl_us` 目录当前可直接整目录通过 `iverilog` 编译，原先 `data_path.v` 与 `general.v` 的重复定义冲突已消除。
