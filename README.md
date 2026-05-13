# Code Tools

当前使用的 AI 编码工具链与最佳实践文档。

## 当前安装

| 插件 | 状态 | 定位 |
|------|------|------|
| **superpowers** | ✅ 已安装（全局） | 技能集（brainstorming, writing, debugging 等 14 个技能） |
| **oh-my-openagent** | ✅ 已安装（全局） | Agent 编排框架（Sisyphus, Prometheus, Team Mode 等） |
| **opencode-lisa** | ✅ 已安装（项目级） | 智能 Epic 工作流（spec → research → plan → execute） |
| **gstack** | ❌ 暂未安装 | Garry Tan 的软件工厂工作流（需要优质模型订阅） |

## 文档

| 文档 | 说明 |
|------|------|
| `docs/analysis-manual.md` | superpowers / gstack / oh-my-openagent 全面分析对比与建议 |
| `docs/migration-guide.md` | OMX (oh-my-codex) → OpenCode + superpowers + oh-my-openagent 迁移指南与最佳实践 |
| `docs/deployment-sop.md` | 部署 SOP — 环境要求、安装流程、配置规范、验证清单、维护与故障处理 |
| `docs/usage-sop.md` | 使用 SOP — 工作模式选择、日常开发流程、Agent 使用、Prompt 最佳实践 |
| `docs/project-config-guide.md` | **项目配置指南** — 项目级配置、Lisa 安装、Skills 配置、个性化设置、权限配置 |
| `docs/faq.md` | 常见问题 FAQ — 模型/Provider/插件/使用问题排查 + 代理 API 使用注意事项 |
| `docs/api-spec.md` | OpenAI-Compatible API 接口规范 — Chat Completions/Tool Calling/Streaming/Schema 校验/合规检查清单/cliproxy 评估 |
| `docs/cliproxy-dev-manual.md` | Cliproxy 开发手册 — Anthropic→OpenAI 协议转换、工具调用映射、流式响应处理 |

## 快速使用

### oh-my-openagent 工作流

```bash
# ultrawork — 一句话启动完整工作流
ultrawork 帮我实现 [功能描述]

# 需要规划时，按 Tab 进入 Prometheus Planner 模式
```

### Lisa Epic 工作流

```bash
# 创建或继续 Epic
/lisa user-authentication

# 查看所有 Epic
/lisa list

# 全自动模式
/lisa user-authentication yolo
```

### Superpowers 技能

```bash
# 加载技能（需要先配置 skills.paths）
skill(name="brainstorming")
skill(name="writing-plans")
skill(name="systematic-debugging")
```

## 配置

### 全局配置：~/.config/opencode/opencode.json

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
    "my-new-api": { /* ... */ }
  }
}
```

> **⚠️ 重要**：`skills.paths` 配置是必需的，否则 superpowers 技能无法通过 `skill` 工具加载。详见 [FAQ Q6.5](docs/faq.md#q65-superpowers-技能无法通过-skill-工具加载)。

### 项目配置：opencode.json

```json
{
  "$schema": "https://opencode.ai/config.json",
  "plugin": [
    "opencode-lisa"
  ]
}
```

### Agent 模型配置：~/.config/opencode/oh-my-openagent.json

模型按能力分级配置，重任务用强模型，轻任务用快模型。详见 [部署 SOP](docs/deployment-sop.md)。

## 项目结构

```
code-tools/
├── .opencode/              # 项目级 OpenCode 配置
│   ├── commands/
│   │   └── lisa.md         # /lisa 命令定义
│   └── skills/
│       └── lisa/           # Lisa 技能实现
│           └── SKILL.md
├── .lisa/                  # Lisa 运行时数据（首次运行时创建）
│   ├── config.jsonc        # Lisa 配置
│   └── epics/              # Epic 状态和任务
├── docs/                   # 完整文档集
│   ├── analysis-manual.md
│   ├── migration-guide.md
│   ├── deployment-sop.md
│   ├── usage-sop.md
│   ├── project-config-guide.md  # 项目配置指南
│   ├── faq.md
│   ├── api-spec.md
│   └── cliproxy-dev-manual.md
├── opencode.json           # 项目级插件配置
└── README.md               # 本文档
```

## 注意事项

- ✅ superpowers 与 oh-my-openagent 无冲突，可同时使用
- ✅ Lisa 是项目级插件，仅在本项目生效
- ⚠️ superpowers 技能需要配置 `skills.paths` 才能通过 `skill` 工具加载
- ⚠️ 无模型订阅时，自动使用 `opencode/big-pickle` 或 `opencode/gpt-5-nano` 作为 fallback
- ❌ gstack 需要 Claude Pro/Max 或等效订阅才能发挥价值，当前不建议安装

## 下一步

1. **验证 superpowers 技能加载**：重启 OpenCode 后运行 `skill(name="brainstorming")`
2. **测试 Lisa**：运行 `/lisa help` 查看可用命令
3. **阅读文档**：从 [部署 SOP](docs/deployment-sop.md) 和 [使用 SOP](docs/usage-sop.md) 开始
