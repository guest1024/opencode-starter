# OpenCode + superpowers + oh-my-openagent 使用 SOP

> 日常使用标准操作流程

## 目录

1. [工作模式选择](#1-工作模式选择)
2. [日常开发流程](#2-日常开发流程)
3. [Agent 使用指南](#3-agent-使用指南)
4. [Lisa Epic 工作流使用](#4-lisa-epic-工作流使用)
5. [superpowers 技能使用](#5-superpowers-技能使用)
6. [Prompt 最佳实践](#6-prompt-最佳实践)
7. [常见场景 SOP](#7-常见场景-sop)
8. [效率提升技巧](#8-效率提升技巧)

---

## 1. 工作模式选择

oh-my-openagent 提供多种工作模式，根据任务复杂度选择：

```
任务复杂度
     │
     ├─ 简单（修复 typo、改一行配置）
     │   └─ 直接对话
     │
     ├─ 常规（新增小功能、重构单个文件）
     │   └─ ultrawork / ulw
     │
     ├─ 复杂（多文件改动、新模块）
     │   ├─ 按 Tab → Prometheus 规划 → /start-work
     │   └─ 或 ultrawork 自动编排
     │
     └─ 大型（跨模块、架构变更）
         └─ Tab → Prometheus 访谈 → 规划确认 → ultrawork
```

### 模式速查表

| 触发方式 | 模式 | 适用场景 |
|---------|------|---------|
| 直接输入 | 对话模式 | 简单问答、小改动 |
| `ultrawork <任务>` | Ultrawork 模式 | 大多数开发任务 |
| `ulw <任务>` | Ultrawork 简写 | 同上 |
| Tab 键 | Prometheus 规划模式 | 需要先规划的复杂任务 |
| `/start-work` | 执行规划 | Prometheus 规划完成后 |
| `ulw-loop` | Ralph 循环模式 | 需要持续迭代到完成 |
| `team` | Team Mode | 大型多模块并行任务 |

---

## 2. 日常开发流程

### 2.1 开始新功能

```
步骤 1: 明确需求
  输入: "帮我实现一个用户登录功能"

步骤 2: Agent 自动判断复杂度
  ├─ 简单 → 直接实现
  └─ 复杂 → 建议进入 Prometheus 规划

步骤 3: 按 Tab 进入规划（如需）
  Agent 会提问澄清需求、边界、验收标准

步骤 4: 确认规划后自动执行
  或输入: "/start-work"

步骤 5: 审查结果
  Agent 会报告改了哪些文件、做了什么验证
```

### 2.2 修复 Bug

```
输入: "修复登录页面的 500 错误"
Agent 行为:
  1. 搜索相关代码
  2. 分析可能原因
  3. 实施修复
  4. 验证修复效果
  5. 报告结果

高级: "加载 superpowers/systematic-debugging 技能，
       然后修复这个 Bug"
```

### 2.3 代码审查

```
方式一: Agent 自动审查
  输入: "审查我刚写的代码，检查潜在问题"

方式二: 加载审查技能
  输入: "加载 superpowers/requesting-code-review 技能，
        审查 src/auth.ts"
```

### 2.4 文档编写

```
输入: "为这个 API 编写使用文档，包含示例代码"

需要高质量写作时:
  "加载 superpowers/writing-skills 技能，
   然后为项目编写 README"
```

---

## 3. Agent 使用指南

### 3.1 Sisyphus（主 Agent）

**角色**：主编排 Agent，规划、委派、驱动任务完成

```text
适用场景：
  - 大多数开发任务
  - 需要多步骤完成的复杂功能
  - 需要协调多个子任务的场景

触发方式：
  - 输入 ultrawork
  - oh-my-openagent 自动将其作为主 Agent

用法示例：
  "ultrawork 帮我实现一个任务管理系统，
   包含 CRUD 操作和数据库持久化"
```

### 3.2 Prometheus（规划 Agent）

**角色**：战略规划 Agent，面试式需求澄清

```text
适用场景：
  - 需求不明确时
  - 复杂功能的前置规划
  - 需要评估实现方案的场景

触发方式：
  - 按 Tab 键进入 Prometheus 模式
  - 系统自动在复杂任务前建议使用

工作流程：
  1. Agent 提问澄清需求
  2. 识别范围和边界
  3. 输出实现方案
  4. 确认后执行 /start-work
```

### 3.3 Explore（搜索 Agent）

**角色**：快速代码搜索，不执行修改

```text
适用场景：
  - 查找代码位置
  - 理解代码结构
  - 搜索特定实现模式

特点：
  - 使用最快模型
  - 只读，不修改代码
  - 适合在修改前先了解代码库

用法示例：
  "explore 帮我找到所有用户认证相关的代码"
```

### 3.4 Librarian（文档 Agent）

**角色**：文档和代码搜索

```text
适用场景：
  - 查找文档
  - 搜索 API 用法
  - 理解项目结构

用法示例：
  "librarian 搜索项目中如何使用数据库"
```

---

## 4. Lisa Epic 工作流使用

### 4.1 Lisa 简介

Lisa 是项目级的智能 Epic 工作流插件，用于管理大型功能的实现。与 Ralph Wiggum 模式不同，Lisa 会先规划再行动。

**核心理念：** spec（规格） → research（研究） → plan（计划） → execute（执行）

### 4.2 Lisa 命令清单

| 命令 | 说明 |
|------|------|
| `/lisa help` | 显示帮助菜单 |
| `/lisa list` | 列出所有 Epic 及其状态 |
| `/lisa <name>` | 创建或继续一个 Epic（交互式） |
| `/lisa <name> spec` | 仅创建/查看规格文档 |
| `/lisa <name> status` | 显示 Epic 详细状态 |
| `/lisa <name> yolo` | 全自动模式（无确认） |
| `/lisa config view` | 查看当前配置 |
| `/lisa config init` | 初始化配置文件 |
| `/lisa config reset` | 重置配置为默认值 |

### 4.3 基本工作流

**标准流程（交互式）：**

```bash
# 1. 创建 Epic 并定义规格
/lisa user-authentication

# Lisa 会引导你完成：
# - 定义目标和范围
# - 明确验收标准
# - 确定技术约束

# 2. 确认规格后，Lisa 自动进行：
# - Research: 探索代码库，了解现有模式
# - Plan: 分解任务，定义依赖关系
# - Execute: 逐个执行任务

# 3. 查看进度
/lisa user-authentication status

# 4. 列出所有 Epic
/lisa list
```

**快速流程（仅创建规格）：**

```bash
# 仅创建规格文档，不继续后续阶段
/lisa user-authentication spec

# 之后可以手动编辑 .lisa/epics/user-authentication/spec.md
# 然后运行 /lisa user-authentication 继续
```

### 4.4 Yolo 模式（全自动）

**⚠️ 重要前提：Yolo 模式必须先有 spec 文件**

Yolo 模式是完全自动化执行，无需人工确认。但它**必须**先有一个 spec 文件才能运行。

**正确的 Yolo 工作流：**

```bash
# 步骤 1: 先创建 spec（必需）
/lisa add-user-auth spec

# Lisa 会交互式地帮你定义：
# - 目标是什么
# - 范围包含什么
# - 验收标准
# - 技术约束

# 步骤 2: 确认并保存 spec

# 步骤 3: 运行 yolo 模式
/lisa add-user-auth yolo

# Lisa 会自动完成：
# - Research（探索代码库）
# - Plan（创建任务计划）
# - Execute（执行所有任务）
# 
# 无需任何人工确认，直到完成或遇到阻塞
```

**❌ 常见错误：**

```bash
# 错误：直接运行 yolo 而没有 spec
/lisa add-user-auth yolo

# 结果：
# "No spec found at `.lisa/epics/add-user-auth/spec.md`.
#  Create one first: /lisa add-user-auth spec"
```

**Yolo 模式特点：**

- ✅ 完全自动化，无需人工干预
- ✅ 自动处理 research、plan、execute 所有阶段
- ✅ 遇到上下文限制时自动继续（由 Lisa 插件管理）
- ✅ 达到最大迭代次数或所有任务完成时停止
- ⚠️ **必须先有 spec** - 这是 yolo 模式的唯一前提条件
- ⚠️ 适合明确的、范围清晰的功能实现
- ⚠️ 不适合探索性、范围模糊的任务

### 4.5 Epic 状态和目录结构

**Epic 存储位置：** `.lisa/epics/<epic-name>/`

**目录结构：**

```
.lisa/epics/user-authentication/
├── .state              # Epic 状态（JSON）
├── spec.md             # 规格文档
├── research.md         # 研究结果
├── plan.md             # 实现计划
└── tasks/              # 任务文件
    ├── 01-setup.md
    ├── 02-api.md
    └── 03-ui.md
```

**状态文件示例（.state）：**

```json
{
  "name": "user-authentication",
  "currentPhase": "execute",
  "specComplete": true,
  "researchComplete": true,
  "planComplete": true,
  "executeComplete": false,
  "lastUpdated": "2026-05-13T10:00:00Z",
  "yolo": {
    "active": true,
    "iteration": 5,
    "maxIterations": 100,
    "startedAt": "2026-05-13T09:00:00Z"
  }
}
```

### 4.6 配置管理

**配置文件位置：**

- 全局：`~/.config/lisa/config.jsonc`
- 项目：`.lisa/config.jsonc`（提交到 git）
- 本地：`.lisa/config.local.jsonc`（gitignored）

**配置优先级：** 本地 > 项目 > 全局

**查看当前配置：**

```bash
/lisa config view
```

**关键配置项：**

```jsonc
{
  "execution": {
    "maxRetries": 3  // 任务失败重试次数
  },
  "git": {
    "completionMode": "none",  // "none" | "commit" | "pr"
    "branchPrefix": "epic/",
    "autoPush": true
  },
  "yolo": {
    "defaultMaxIterations": 100  // Yolo 模式最大迭代次数
  }
}
```

**Git 完成模式说明：**

- `"none"` - 不执行任何 git 操作（默认，最安全）
- `"commit"` - 创建分支和提交，但不推送
- `"pr"` - 创建分支、提交、推送并创建 PR（需要 `gh` CLI）

### 4.7 常见场景

**场景 1：实现新功能**

```bash
# 1. 创建 Epic 并定义规格
/lisa payment-integration spec

# 2. 查看状态
/lisa payment-integration status

# 3. 继续执行（交互式）
/lisa payment-integration

# 或全自动执行
/lisa payment-integration yolo
```

**场景 2：查看所有进行中的 Epic**

```bash
/lisa list

# 输出示例：
# - user-authentication (execute, 3/5 tasks done, yolo active)
# - payment-integration (plan, 0/8 tasks)
# - email-notifications (spec)
```

**场景 3：恢复中断的 Epic**

```bash
# Lisa 会自动从上次中断的地方继续
/lisa user-authentication

# 或使用 yolo 模式继续
/lisa user-authentication yolo
```

**场景 4：手动编辑 spec 后继续**

```bash
# 1. 创建初始 spec
/lisa api-refactor spec

# 2. 手动编辑 .lisa/epics/api-refactor/spec.md

# 3. 继续后续阶段
/lisa api-refactor
```

### 4.8 故障排查

**问题 1：Yolo 模式报错 "No spec found"**

**原因：** 直接运行 yolo 而没有先创建 spec

**解决：**
```bash
# 先创建 spec
/lisa <epic-name> spec

# 然后运行 yolo
/lisa <epic-name> yolo
```

**问题 2：任务被标记为 blocked**

**原因：** 任务执行失败超过最大重试次数（默认 3 次）

**解决：**
1. 查看任务文件：`.lisa/epics/<name>/tasks/XX-task.md`
2. 查看 `## Blocked Reason` 了解原因
3. 手动修复问题或修改任务
4. 将状态改回 `## Status: pending`
5. 继续执行：`/lisa <epic-name>`

**问题 3：Epic 目录不存在**

**原因：** 首次使用 Lisa，`.lisa/` 目录未创建

**解决：**
```bash
# Lisa 会在首次创建 Epic 时自动创建目录
/lisa my-first-epic spec

# 或手动初始化配置
/lisa config init
```

**问题 4：Yolo 模式达到最大迭代次数**

**原因：** 任务数量超过配置的 `defaultMaxIterations`（默认 100）

**解决：**
```bash
# 方法 1：增加最大迭代次数
# 编辑 .lisa/config.jsonc:
{
  "yolo": {
    "defaultMaxIterations": 200  // 或 0 表示无限制
  }
}

# 方法 2：使用交互式模式继续
/lisa <epic-name>
```

### 4.9 最佳实践

**✅ 推荐做法：**

1. **明确的 spec** - 在 spec 阶段花时间定义清晰的目标和范围
2. **小步快跑** - 将大功能拆分成多个小 Epic
3. **提交 spec 和 plan** - 将 `.lisa/epics/*/spec.md` 和 `plan.md` 提交到 git，便于团队协作
4. **使用 status 命令** - 定期检查进度：`/lisa <name> status`
5. **先 spec 后 yolo** - 交互式创建 spec，确认无误后再用 yolo 执行

**❌ 避免做法：**

1. **跳过 spec 直接 yolo** - 会失败，yolo 必须先有 spec
2. **spec 过于模糊** - 会导致 plan 质量差，任务执行困难
3. **scope 过大** - 单个 Epic 包含太多功能，建议拆分
4. **忽略 blocked 任务** - 及时处理被阻塞的任务，避免积累
5. **不查看 status** - 定期检查状态，了解进度和问题

---

## 5. superpowers 技能使用

### 4.1 技能清单

| 技能 | 用途 | 加载方式 |
|------|------|---------|
| brainstorming | 头脑风暴、创意生成 | `加载 superpowers/brainstorming 技能` |
| writing-skills | 高质量写作 | `加载 superpowers/writing-skills 技能` |
| requesting-code-review | 代码审查 | `加载 superpowers/requesting-code-review 技能` |
| systematic-debugging | 系统化调试 | `加载 superpowers/systematic-debugging 技能` |
| subagent-driven-development | 子 Agent 驱动开发 | `加载 superpowers/subagent-driven-development 技能` |

### 4.2 技能组合示例

**调试复杂 Bug：**

```
加载 superpowers/systematic-debugging 技能
加载 superpowers/requesting-code-review 技能
帮我排查这个内存泄漏问题
```

**功能设计与实现：**

```
加载 superpowers/brainstorming 技能
帮我设计这个功能的实现方案
然后执行 ultrawork 实现
```

**文档编写：**

```
加载 superpowers/writing-skills 技能
为这个模块编写 API 文档
```

### 4.3 技能使用原则

- **按需加载** — 不需要时不要加载，避免上下文膨胀
- **一个任务一个技能** — 不要同时加载多个无关技能
- **明确指定退出** — 使用完后告诉 Agent 卸载技能

### 4.4 技能加载验证

**验证 superpowers 技能是否可用：**

```bash
# 方法一：通过 AI 对话验证（推荐）
"列出所有可用的 superpowers 技能"

# 方法二：直接测试加载（需要配置 skills.paths）
skill(name="brainstorming")
# 如果返回 "not found"，说明 skills.paths 未正确配置
```

**常见问题：**

如果技能无法加载，检查：

1. **`skills.paths` 是否配置**：查看 `~/.config/opencode/opencode.json` 是否包含：
   ```json
   {
     "skills": {
       "paths": [
         "/home/user/.cache/opencode/packages/superpowers@git+https:/github.com/obra/superpowers.git/node_modules/superpowers/skills"
       ]
     }
   }
   ```

2. **路径是否正确**：替换 `/home/user` 为你的实际 home 目录

3. **是否重启 OpenCode**：配置修改后需要重启

4. **superpowers 版本是否更新**：版本更新后路径中的 git hash 会变化，需要更新配置

详见 [FAQ Q6.5](./faq.md#q65-superpowers-技能无法通过-skill-工具加载)。

---

## 6. Prompt 最佳实践

### 5.1 好 Prompt 的要素

```
✅ 优秀示例:
  "帮我实现用户注册功能
   - 邮箱 + 密码注册
   - 发送验证邮件
   - 使用 PostgreSQL 存储
   - 遵循现有代码风格"

❌ 差劲示例:
  "写个注册功能"
```

### 5.2 结构化 Prompt 模板

```
【任务类型】实现 / 修复 / 重构 / 优化
【目标】清晰描述要做什么
【约束】
  - 技术选型
  - 代码风格
  - 性能要求
  - 安全考虑
【验收标准】
  - 什么算完成
  - 需要哪些验证
```

### 5.3 常见 Prompt 模式

**模式一：直接执行**

```text
ultrawork 帮我实现 [具体功能]
约束：
- 使用 [技术栈]
- 遵循 [现有模式]
- 包含 [测试/文档]
```

**模式二：先规划后执行**

```text
帮我规划 [功能] 的实现方案
先分析现有代码结构
然后给出具体的实现步骤
确认后执行
```

**模式三：审查与优化**

```text
审查 [文件/模块] 的代码
检查：
- 潜在 Bug
- 性能问题
- 安全漏洞
- 代码风格
给出具体的改进建议
```

**模式四：学习与理解**

```text
explore 帮我分析这个模块的结构
- 核心类和函数
- 数据流
- 关键依赖
- 扩展点
```

---

## 7. 常见场景 SOP

### 6.1 新建项目

```text
步骤:
  1. ultrawork 帮我初始化一个 [技术栈] 项目
  2. 创建 AGENTS.md 描述项目结构
  3. 实现核心功能
  4. 添加测试
  5. 验证项目可运行
```

### 6.2 新增功能

```text
步骤:
  1. 明确需求描述
  2. 按 Tab 进入 Prometheus 规划（如需要）
  3. ultrawork 实现功能
  4. 审查输出结果
  5. 运行测试验证
```

### 6.3 重构代码

```text
步骤:
  1. "先分析当前实现的问题"
  2. "规划重构方案"
  3. "按方案逐步重构"
  4. "运行测试确保不破坏现有功能"
```

### 6.4 排查问题

```text
步骤:
  1. 加载 superpowers/systematic-debugging 技能
  2. 描述问题现象
  3. Agent 系统化排查
  4. 定位根因
  5. 实施修复
  6. 验证修复效果
```

### 6.5 代码审查

```text
步骤:
  1. 加载 superpowers/requesting-code-review 技能
  2. 指定审查范围
  3. Agent 输出审查结果
  4. 确认需要修改项
  5. ultrawork 修复问题
```

---

## 8. 效率提升技巧

### 7.1 常用快捷方式

| 快捷方式 | 效果 |
|---------|------|
| `ulw` | 代替 `ultrawork`，更短 |
| 按 Tab | 进入 Prometheus 规划模式 |
| `/init-deep` | 自动生成 AGENTS.md 层级文件 |
| `ulw-loop` | 持续迭代直到完成 |
| 加载技能 | 为当前任务注入专业能力 |

### 7.2 上下文管理

```text
✅ 好的做法:
  - 一个会话聚焦一个任务
  - 任务完成后总结关键信息
  - AGENTS.md 保存项目级知识

❌ 不好的做法:
  - 一个会话做多个无关任务
  - 让 Agent 记忆大量历史信息
  - 不做任何记录直接关闭会话
```

### 7.3 Token 优化

```text
节省 Token 的方法:
  1. AGENTS.md 保持精简（只写 Agent 需要知道的）
  2. 轻任务用快速模型（Explore、Librarian）
  3. 不需要时不要加载技能
  4. 明确告诉 Agent 完成时停止
  5. 使用 /init-deep 代替手动写大量上下文
```

### 7.4 质量保证

```text
每次完成应该确认:
  □ 修改了哪些文件
  □ 通过了什么验证（lint/test/typescript）
  □ 是否存在已知风险
  □ 是否更新了相关文档
```

### 7.5 提示词模板库

**Bug 修复：**

```text
[BUG] <问题描述>
重现步骤：
1. <步骤>
期望结果：<描述>
实际结果：<描述>
技术栈：<相关技术>
```

**功能实现：**

```text
[FEAT] <功能名称>
需求描述：<详细描述>
技术约束：<约束条件>
验收标准：
- [ ] <条件1>
- [ ] <条件2>
```

**性能优化：**

```text
[PERF] <优化目标>
当前表现：<数据>
目标表现：<数据>
限制条件：<不可改动的部分>
```

---

## 附录：命令速查卡

```text
=== 日常命令 ===
ultrawork <任务>     — 启动完整工作流
ulw <任务>           — ultrawork 简写
Tab                  — 进入 Prometheus 规划模式
/start-work          — 执行规划的方案
/init-deep           — 生成 AGENTS.md
ulw-loop             — 持续迭代直到完成

=== 技能加载 ===
加载 superpowers/brainstorming 技能
加载 superpowers/writing-skills 技能
加载 superpowers/requesting-code-review 技能
加载 superpowers/systematic-debugging 技能

=== 维护命令 ===
bunx oh-my-openagent doctor    — 诊断
bunx oh-my-openagent install   — 安装/更新
cat /tmp/oh-my-opencode.log    — 查看日志
```
