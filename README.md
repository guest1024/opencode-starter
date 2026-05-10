# Code Tools

当前使用的 AI 编码工具链与最佳实践文档。

## 当前安装

| 插件 | 状态 | 定位 |
|------|------|------|
| **superpowers** | ✅ 已安装 | 技能集（brainstorming, writing, debugging 等） |
| **oh-my-openagent** | ✅ 已安装 | Agent 编排框架（Sisyphus, Prometheus, Team Mode 等） |
| **gstack** | ❌ 暂未安装 | Garry Tan 的软件工厂工作流（需要优质模型订阅） |

## 文档

| 文档 | 说明 |
|------|------|
| `docs/analysis-manual.md` | superpowers / gstack / oh-my-openagent 全面分析对比与建议 |
| `docs/migration-guide.md` | OMX (oh-my-codex) → OpenCode + superpowers + oh-my-openagent 迁移指南与最佳实践 |
| `docs/deployment-sop.md` | 部署 SOP — 环境要求、安装流程、配置规范、验证清单、维护与故障处理 |
| `docs/usage-sop.md` | 使用 SOP — 工作模式选择、日常开发流程、Agent 使用、Prompt 最佳实践 |
| `docs/faq.md` | 常见问题 FAQ — 模型/Provider/插件/使用问题排查 + 代理 API 使用注意事项 |
| `docs/api-spec.md` | OpenAI-Compatible API 接口规范 — Chat Completions/Tool Calling/Streaming/Schema 校验/合规检查清单/cliproxy 评估 |

## 快速使用

```bash
# ultrawork — 一句话启动完整工作流
# 在 OpenCode 中输入：
ultrawork 帮我实现 [功能描述]

# 需要规划时，按 Tab 进入 Prometheus Planner 模式

# 加载 superpowers 技能
加载 superpowers/brainstorming 技能
```

## 配置

### ~/.config/opencode/opencode.json

```json
{
  "plugin": [
    "superpowers@git+https://github.com/obra/superpowers.git",
    "oh-my-openagent@latest"
  ]
}
```

### ~/.config/opencode/oh-my-openagent.json

模型按能力分级配置，重任务用强模型，轻任务用快模型。

## 注意

- 无模型订阅时，自动使用 `opencode/big-pickle` 或 `opencode/gpt-5-nano` 作为 fallback
- gstack 需要 Claude Pro/Max 或等效订阅才能发挥价值，当前不建议安装
- superpowers 与 oh-my-openagent 无冲突，可同时使用
