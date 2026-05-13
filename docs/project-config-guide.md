# OpenCode 项目级配置指南

> 如何在项目中独立配置 OpenCode、安装 Lisa、配置主题和个性化设置

## 目录

1. [项目级 vs 全局配置](#1-项目级-vs-全局配置)
2. [项目级配置结构](#2-项目级配置结构)
3. [安装和配置 Lisa](#3-安装和配置-lisa)
4. [Skills 配置](#4-skills-配置)
5. [个性化配置选项](#5-个性化配置选项)
6. [权限和工具配置](#6-权限和工具配置)
7. [最佳实践](#7-最佳实践)

---

## 1. 项目级 vs 全局配置

### 配置优先级

```
项目级配置 > 全局配置 > OpenCode 默认值
```

| 配置文件 | 位置 | 作用域 | 优先级 |
|---------|------|--------|--------|
| **项目级** | `<project>/.opencode/` 或 `<project>/opencode.json` | 仅当前项目 | 最高 |
| **全局** | `~/.config/opencode/opencode.json` | 所有项目 | 中 |
| **默认** | OpenCode 内置 | 所有项目 | 最低 |

### 何时使用项目级配置

**推荐使用项目级配置的场景：**

- ✅ 项目特定的 skills（如本项目的 Lisa skill）
- ✅ 项目特定的 commands（如 `/lisa`）
- ✅ 项目特定的 instructions（AGENTS.md、CLAUDE.md 等）
- ✅ 项目特定的工具权限（某些项目允许自动 git push，某些不允许）
- ✅ 团队协作项目（配置可以提交到 git，团队共享）

**推荐使用全局配置的场景：**

- ✅ AI Provider 配置（API keys、endpoints）
- ✅ 通用插件（superpowers、oh-my-openagent）
- ✅ 个人偏好设置（默认模型、日志级别等）

---

## 2. 项目级配置结构

### 方式一：单文件配置（简单项目）

```
my-project/
├── opencode.json          ← 项目级配置
├── src/
└── package.json
```

**`opencode.json` 示例：**

```json
{
  "$schema": "https://opencode.ai/config.json",
  "plugin": [
    "opencode-lisa"
  ]
}
```

### 方式二：目录配置（复杂项目）

```
my-project/
├── .opencode/
│   ├── commands/          ← 自定义命令（如 /lisa）
│   │   └── lisa.md
│   ├── skills/            ← 项目特定技能
│   │   └── lisa/
│   │       └── SKILL.md
│   └── instructions/      ← 项目指令（可选）
│       └── AGENTS.md
├── opencode.json          ← 主配置文件
├── src/
└── package.json
```

**当前项目结构（code-tools）：**

```
/home/user/code-tools/
├── .opencode/
│   ├── commands/
│   │   └── lisa.md        ← /lisa 命令定义
│   └── skills/
│       └── lisa/
│           └── SKILL.md   ← Lisa 技能完整实现
├── opencode.json          ← 插件注册
├── .lisa/                 ← Lisa 运行时数据（自动创建）
│   ├── config.jsonc       ← Lisa 配置
│   ├── .gitignore
│   └── epics/             ← Epic 状态和任务
├── docs/                  ← 文档
└── README.md
```

---

## 3. 安装和配置 Lisa

### 3.1 安装 Lisa 插件

**方式一：自动安装（推荐）**

```bash
cd /home/user/code-tools
npx opencode-lisa --opencode
# 或使用 Bun
bunx opencode-lisa --opencode
```

这会自动创建 `opencode.json` 并配置 Lisa 插件。

**方式二：手动配置**

编辑 `opencode.json`：

```json
{
  "$schema": "https://opencode.ai/config.json",
  "plugin": [
    "opencode-lisa"
  ]
}
```

重启 OpenCode，插件会自动下载到 `~/.cache/opencode/packages/opencode-lisa@latest/`。

### 3.2 验证 Lisa 安装

```bash
# 在项目目录启动 OpenCode
cd /home/user/code-tools
opencode

# 在 OpenCode 中运行
/lisa help
```

**预期输出：**

```
Lisa - Intelligent Epic Workflow

Available Commands:

/lisa list - List all epics and their status
/lisa <name> - Continue or create an epic (interactive)
/lisa <name> spec - Create/view the spec only
/lisa <name> status - Show detailed epic status
/lisa <name> yolo - Auto-execute mode (no confirmations)
...
```

### 3.3 Lisa 配置文件

Lisa 的运行时配置存储在 `.lisa/config.jsonc`（首次运行时自动创建）：

```jsonc
{
  "git": {
    // Git 完成模式
    // "none" - 不自动提交/PR
    // "commit" - 自动创建 commit
    // "pr" - 自动创建 PR
    "completionMode": "none"
  },
  "yolo": {
    // Yolo 模式最大迭代次数
    "defaultMaxIterations": 100
  }
}
```

**配置选项说明：**

| 选项 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `git.completionMode` | `"none"` \| `"commit"` \| `"pr"` | `"none"` | Epic 完成后的 Git 操作 |
| `yolo.defaultMaxIterations` | `number` | `100` | Yolo 模式最大任务执行次数 |

**推荐配置：**

```jsonc
{
  "git": {
    // 开发阶段：手动控制 Git
    "completionMode": "none"
    
    // 自动化场景：自动提交
    // "completionMode": "commit"
  },
  "yolo": {
    // 根据项目复杂度调整
    "defaultMaxIterations": 50  // 小项目
    // "defaultMaxIterations": 200  // 大项目
  }
}
```

### 3.4 Lisa 使用示例

```bash
# 1. 创建新 Epic
/lisa user-authentication

# 2. Lisa 会引导你完成 Spec 阶段（交互式问答）
# 3. 确认 Spec 后，Lisa 自动进入 Research → Plan → Execute

# 查看所有 Epic
/lisa list

# 查看 Epic 状态
/lisa user-authentication status

# Yolo 模式（全自动，无确认）
/lisa user-authentication yolo
```

---

## 4. Skills 配置

### 4.1 项目级 Skills

项目级 skills 存放在 `.opencode/skills/` 目录：

```
.opencode/
└── skills/
    └── my-skill/
        └── SKILL.md
```

**自动发现：** OpenCode 会自动发现 `.opencode/skills/` 下的所有技能。

**当前项目的 Lisa skill：**

```
.opencode/skills/lisa/SKILL.md
```

### 4.2 全局 Skills 路径配置

如果需要引用其他位置的 skills（如 superpowers），在 `opencode.json` 中配置：

```json
{
  "$schema": "https://opencode.ai/config.json",
  "skills": {
    "paths": [
      "/home/user/.cache/opencode/packages/superpowers@git+https:/github.com/obra/superpowers.git/node_modules/superpowers/skills"
    ]
  },
  "plugin": [
    "opencode-lisa"
  ]
}
```

**注意：** 这个配置通常放在全局配置 `~/.config/opencode/opencode.json` 中，而不是项目级配置。

### 4.3 Skills 优先级

```
项目级 skills (.opencode/skills/) > 全局 skills.paths > 插件 skills
```

如果项目级和全局有同名 skill，项目级优先。

---

## 5. 个性化配置选项

### 5.1 可用配置项

OpenCode 支持以下配置项（基于 config schema）：

| 配置项 | 类型 | 说明 |
|--------|------|------|
| `$schema` | `string` | Schema URL（自动补全支持） |
| `plugin` | `string[]` | 插件列表 |
| `skills.paths` | `string[]` | Skills 搜索路径 |
| `instructions` | `string[]` | 额外的指令文件或模式 |
| `model` | `string` | 默认模型 |
| `small_model` | `string` | 小模型（用于轻量任务） |
| `agent` | `string` | 默认 Agent |
| `default_agent` | `string` | 默认 Agent（同上） |
| `provider` | `object` | AI Provider 配置 |
| `permission` | `object` | 工具权限配置 |
| `tools` | `object` | 工具配置 |
| `logLevel` | `"DEBUG"` \| `"INFO"` \| `"WARN"` \| `"ERROR"` | 日志级别 |
| `shell` | `object` | Shell 配置 |
| `formatter` | `object` | 代码格式化配置 |
| `lsp` | `object` | LSP 配置 |
| `mcp` | `object` | MCP 服务器配置 |
| `autoupdate` | `boolean` | 自动更新 |
| `autoshare` | `boolean` | 自动分享 |
| `experimental` | `object` | 实验性功能 |

### 5.2 Instructions 配置

**用途：** 为 AI 提供项目特定的上下文和指令。

**示例：**

```json
{
  "instructions": [
    "AGENTS.md",
    "CLAUDE.md",
    ".opencode/instructions/*.md"
  ]
}
```

**常见 instruction 文件：**

- `AGENTS.md` - 项目结构、架构、约定
- `CLAUDE.md` - Claude 特定指令
- `GEMINI.md` - Gemini 特定指令
- `.opencode/instructions/coding-style.md` - 编码风格
- `.opencode/instructions/testing.md` - 测试规范

### 5.3 模型配置

**项目级模型配置：**

```json
{
  "model": "my-new-api/claude-opus-4.7",
  "small_model": "my-new-api/claude-sonnet-4.5"
}
```

**说明：**
- `model` - 主模型，用于复杂任务
- `small_model` - 小模型，用于简单任务（搜索、格式化等）

**注意：** Provider 配置（API keys）应该放在全局配置中，不要提交到 git。

### 5.4 日志配置

```json
{
  "logLevel": "INFO"
}
```

**级别说明：**
- `DEBUG` - 详细调试信息
- `INFO` - 一般信息（默认）
- `WARN` - 警告
- `ERROR` - 仅错误

### 5.5 主题和 UI 配置

**注意：** OpenCode v1.14.x 的配置文件**不支持主题/颜色配置**。

- `layout` 配置已废弃（始终使用 stretch layout）
- 没有 `theme`、`colors`、`appearance` 等配置项
- UI 主题由 OpenCode 内部控制，无法通过配置文件自定义

**如果需要自定义 UI：**
- 等待 OpenCode 未来版本支持
- 或使用 OpenCode Web 界面（可能有更多自定义选项）

---

## 6. 权限和工具配置

### 6.1 工具权限配置

控制 AI 可以使用哪些工具以及如何使用：

```json
{
  "permission": {
    "bash": "ask",
    "edit": "allow",
    "write": "ask",
    "read": "allow"
  }
}
```

**权限级别：**
- `"allow"` - 自动允许
- `"ask"` - 每次询问
- `"deny"` - 禁止使用

**推荐配置：**

```json
{
  "permission": {
    // 读取操作 - 自动允许
    "read": "allow",
    "grep": "allow",
    "glob": "allow",
    
    // 编辑操作 - 自动允许（可撤销）
    "edit": "allow",
    
    // 写入操作 - 询问（不可撤销）
    "write": "ask",
    
    // 命令执行 - 询问（可能有副作用）
    "bash": "ask",
    
    // Git 操作 - 询问
    "git": "ask"
  }
}
```

### 6.2 工具配置

```json
{
  "tools": {
    "bash": {
      "timeout": 120000
    }
  }
}
```

---

## 7. 最佳实践

### 7.1 项目配置模板

**最小配置（仅 Lisa）：**

```json
{
  "$schema": "https://opencode.ai/config.json",
  "plugin": [
    "opencode-lisa"
  ]
}
```

**完整配置（带个性化）：**

```json
{
  "$schema": "https://opencode.ai/config.json",
  
  "plugin": [
    "opencode-lisa"
  ],
  
  "instructions": [
    "AGENTS.md",
    ".opencode/instructions/*.md"
  ],
  
  "model": "my-new-api/claude-opus-4.7",
  "small_model": "my-new-api/claude-sonnet-4.5",
  
  "permission": {
    "read": "allow",
    "edit": "allow",
    "write": "ask",
    "bash": "ask"
  },
  
  "logLevel": "INFO"
}
```

### 7.2 配置分离原则

**项目级配置（可提交 git）：**
```json
{
  "plugin": ["opencode-lisa"],
  "instructions": ["AGENTS.md"],
  "permission": { "bash": "ask" }
}
```

**全局配置（不提交 git）：**
```json
{
  "skills": { "paths": [...] },
  "provider": {
    "my-new-api": {
      "apiKey": "${API_KEY}"
    }
  }
}
```

### 7.3 .gitignore 配置

```gitignore
# Lisa 运行时数据（可选提交）
.lisa/epics/*/

# 保留 Lisa 配置
!.lisa/config.jsonc
!.lisa/.gitignore

# OpenCode 缓存
.opencode/.cache/
```

### 7.4 团队协作配置

**提交到 git 的配置：**
- ✅ `opencode.json` - 插件、instructions、权限
- ✅ `.opencode/skills/` - 项目特定技能
- ✅ `.opencode/commands/` - 项目特定命令
- ✅ `.lisa/config.jsonc` - Lisa 配置
- ✅ `AGENTS.md` - 项目文档

**不提交到 git 的配置：**
- ❌ API keys、tokens
- ❌ 个人偏好（模型选择、日志级别）
- ❌ `.lisa/epics/` - Epic 运行时状态（可选）

### 7.5 配置验证

```bash
# 验证配置文件语法
cat opencode.json | jq .

# 验证 Lisa 安装
opencode run "/lisa help"

# 验证 skills 加载
opencode run "列出所有可用的技能"

# 查看当前配置
opencode config list
```

---

## 附录：完整配置示例

### 当前项目配置（code-tools）

**`/home/user/code-tools/opencode.json`：**

```json
{
  "plugin": [
    "opencode-lisa"
  ],
  "$schema": "https://opencode.ai/config.json"
}
```

**目录结构：**

```
/home/user/code-tools/
├── .opencode/
│   ├── commands/
│   │   └── lisa.md
│   └── skills/
│       └── lisa/
│           └── SKILL.md
├── opencode.json
├── .lisa/                    ← 首次运行 /lisa 时自动创建
│   ├── config.jsonc
│   ├── .gitignore
│   └── epics/
├── docs/
│   ├── analysis-manual.md
│   ├── migration-guide.md
│   ├── deployment-sop.md
│   ├── usage-sop.md
│   ├── faq.md
│   ├── api-spec.md
│   ├── cliproxy-dev-manual.md
│   └── project-config-guide.md  ← 本文档
└── README.md
```

### 推荐的全局配置

**`~/.config/opencode/opencode.json`：**

```json
{
  "$schema": "https://opencode.ai/config.json",
  
  "skills": {
    "paths": [
      "/home/user/.cache/opencode/packages/superpowers@git+https:/github.com/obra/superpowers.git/node_modules/superpowers/skills"
    ]
  },
  
  "plugin": [
    "superpowers@git+https://github.com/obra/superpowers.git",
    "oh-my-openagent@latest"
  ],
  
  "provider": {
    "my-new-api": {
      "npm": "@ai-sdk/openai-compatible",
      "name": "new-api",
      "options": {
        "baseURL": "${NEW_API_BASE_URL}",
        "apiKey": "${NEW_API_KEY}"
      },
      "models": {
        "claude-sonnet-4.6": {
          "name": "Claude Sonnet 4.6",
          "structuredOutputs": false
        }
      }
    }
  },
  
  "logLevel": "INFO"
}
```

---

## 相关文档

- [部署 SOP](./deployment-sop.md) - 完整部署流程
- [使用 SOP](./usage-sop.md) - 日常使用指南
- [FAQ](./faq.md) - 常见问题
- [Lisa README](https://github.com/obra/opencode-lisa) - Lisa 官方文档
