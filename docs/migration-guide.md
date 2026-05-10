# OMX → OpenCode + superpowers + oh-my-openagent 迁移指南

> 从 oh-my-codex (OMX) 迁移到 OpenCode 生态

## 什么是 OMX？

**OMX (oh-my-codex)** 是一个基于 OpenAI Codex CLI 的多 Agent 编排和工作流层。提供 `$ralph`、`$team`、`$deep-interview` 等模式，通过 hooks、MCP servers 和 `.omx/` 运行时目录管理状态。

## 为什么迁移？

| 对比维度 | OMX (oh-my-codex) | OpenCode + oh-my-openagent |
|----------|-------------------|---------------------------|
| **底层** | Codex CLI | OpenCode |
| **编排方式** | $ 关键字 + 模式切换 | Discipline Agents (Sisyphus 自动编排) |
| **并行执行** | `$team N:role` | Team Mode (最多 8 并行) |
| **状态管理** | `.omx/` 文件系统 | oh-my-openagent.json + 会话状态 |
| **编辑验证** | 无 | Hashline (LINE#ID 哈希锚定) |
| **模型支持** | GPT 优先 | Claude + GPT + Gemini + Kimi + GLM 多模型 |
| **技能系统** | SKILL.md | OpenCode 原生 skill + 插件 |
| **维护状态** | v0.16.2 (社区) | v4.0.0 (活跃开发) |
| **插件生态** | 有限 | superpowers + 社区插件 |

---

## 迁移步骤

### 第一步：了解对应关系

| OMX 概念 | oh-my-openagent 对应 |
|----------|---------------------|
| `$ralph` | `ultrawork` / `ulw` — 一句话启动完整工作流 |
| `$team` | Team Mode — 配置 `team_mode.enabled: true` |
| `$deep-interview` | Prometheus Planner — `/start-work` |
| `$ralplan` | `/init-deep` + Prometheus 自动规划 |
| `$ultragoal` | `ultrawork` 自动管理多目标 |
| `omx explore` | Explore Agent (自动路由到最快模型) |
| `.omx/state/` | 由 oh-my-openagent 运行时自动管理 |
| `.omx/plans/` | oh-my-openagent.json 中配置 |
| `.omx/notepad.md` | 会话上下文自动管理 |
| **OMX MCP Servers** | **oh-my-openagent 内置 MCP** |
| `omx_state` | 由 oh-my-openagent 运行时替代 |
| `omx_memory` | 由 oh-my-openagent 上下文管理替代 |
| `omx_code_intel` | LSP + AST-Grep 内置工具 |
| `omx_trace` | oh-my-openagent 会话历史工具 |
| `omx_wiki` | 由 `/init-deep` 生成的 AGENTS.md 替代 |

### 第二步：清理 OMX 残留

```bash
# 1. 在原有项目中移除 OMX hooks（如果有）
omx uninstall

# 2. 移除 OMX 全局安装（可选）
npm uninstall -g oh-my-codex

# 3. 清理项目中遗留的 .omx 目录
# 注意：如果里面有需要保留的计划/文档，先备份
mv /path/to/project/.omx/plans /path/to/project/docs/omx-archive/
rm -rf /path/to/project/.omx/

# 4. 清理 Codex 配置中的 OMX 引用
# 编辑 ~/.codex/config.toml，移除 OMX MCP 服务器配置
```

### 第三步：安装 OpenCode + 插件

```bash
# 1. 安装 OpenCode（如未安装）
# 参考: https://opencode.ai/docs

# 2. 配置 opencode.json
```

```json
{
  "plugin": [
    "superpowers@git+https://github.com/obra/superpowers.git",
    "oh-my-openagent@latest"
  ]
}
```

```bash
# 3. 安装 oh-my-openagent 并配置
bunx oh-my-openagent install --no-tui --claude=no --openai=no --gemini=no --copilot=no

# 4. 验证安装
bunx oh-my-openagent doctor
```

### 第四步：迁移项目配置

对于使用了 OMX 的已有项目（如 `ai-books`）：

1. **保留 AGENTS.md** — oh-my-openagent 也使用 AGENTS.md 作为项目上下文
2. **迁移计划文件**：将 `.omx/plans/` 内容移到 `docs/plans/` 或项目中合适位置
3. **适配 AGENTS.md**：将 OMX 特有指令替换为 oh-my-openagent 对应写法：

```markdown
<!-- OMX 旧写法 -->
你运行在 oh-my-codex (OMX) 之上。
使用 $ralph 进入持续执行模式。

<!-- oh-my-openagent 新写法 -->
你运行在 oh-my-openagent 之上。
使用 ultrawork (ulw) 进入自动执行模式。
```

---

## 最佳实践

### 1. 按任务规模选择模式

| 任务类型 | 推荐做法 |
|----------|---------|
| 简单改动（修复 typo、单文件修改） | 直接对话，不需要特殊模式 |
| 明确需求的常规功能 | `ultrawork` / `ulw` — 一句话启动 |
| 需要规划的复杂任务 | 按 Tab 进入 Prometheus Planner → `/start-work` |
| 大型多模块任务 | 启用 Team Mode，Sisyphus 自动调度 |
| 需持续迭代到完成 | `ulw-loop`（Ralph Loop 对应） |

**核心原则**：能直接做就别过度编排。oh-my-openagent 会自动判断什么时候需要什么级别的处理。

### 2. AGENTS.md 最佳实践

oh-my-openagent 会自动读取 AGENTS.md 作为项目上下文。推荐结构：

```markdown
# 项目名称

## 技术栈
- 语言/框架
- 关键依赖

## 项目结构
- src/ — 源代码
- docs/ — 文档
- tests/ — 测试

## 约定
- 代码风格
- 命名规范
- 测试要求

## 工作流
- 使用 `ultrawork` 启动完整工作流
- 复杂变更前使用 Prometheus 规划
```

### 3. 配置分层管理

```jsonc
// oh-my-openagent.json
{
  "agents": {
    "sisyphus": { "model": "opencode/big-pickle" },
    "explore": { "model": "opencode/gpt-5-nano" },
    "librarian": { "model": "opencode/gpt-5-nano" }
  },
  "categories": {
    "ultrabrain": { "model": "opencode/big-pickle" },
    "quick": { "model": "opencode/gpt-5-nano" }
  }
}
```

原则：
- **重任务用强模型**（Sisyphus、Prometheus、ultrabrain）
- **轻任务用快模型**（Explore、Librarian、quick）
- 模型升级后只需改 model 字段，无需改 Agent 逻辑

### 4. 善用 superpowers 技能

oh-my-openagent 的 Agent 可以调用 superpowers 的技能：

- **brainstorming** — 需要创意发散时加载
- **writing-skills** — 需要高质量写作时加载
- **systematic-debugging** — 遇到复杂 Bug 时加载
- **requesting-code-review** — 需要结构化审查时加载

```markdown
在 prompt 中使用：
"加载 superpowers/brainstorming 技能，帮我头脑风暴这个功能的实现方案"
```

### 5. 从 OMX Ralph 过渡到 ultrawork

| OMX Ralph 做法 | oh-my-openagent 做法 |
|---------------|---------------------|
| 先写 `prd-*.md` 和 `test-spec-*.md` | 按 Tab 让 Prometheus 自动访谈规划 |
| 然后 `$ralph` | 然后输入 `ultrawork` |
| 等待 Ralph 循环执行 | Sisyphus 自动调度子 Agent 并行执行 |
| 手动验证结果 | Hashline 验证 + Agent 自动验证 |

### 6. 状态和文档管理

| 职责 | OMX 位置 | oh-my-openagent 建议位置 |
|------|----------|------------------------|
| 长期文档 | `docs/` | `docs/` |
| 开发计划 | `.omx/plans/` | `docs/plans/` 或 AGENTS.md |
| 运行时状态 | `.omx/state/` | 由 oh-my-openagent 自动管理 |
| 会话记录 | `.omx/logs/` | 由 OpenCode 会话系统管理 |
| 项目记忆 | `.omx/project-memory.json` | AGENTS.md + oh-my-openagent 上下文 |

### 7. 常见误区

| 误区 | 正确做法 |
|------|---------|
| 一上来就用 ultrawork | 简单任务直接对话即可 |
| 同时启太多 Agent | 按需启用，oh-my-openagent 会自动管理 |
| 手动管理 .omx 状态 | 交给 oh-my-openagent 自动管理 |
| 把 OMX 配置直接搬过来 | 理解对应关系后重新配置 |
| 忽略 AGENTS.md | AGENTS.md 是 Agent 理解项目的关键入口 |

### 8. 模型有限时的策略

当前环境只有 `opencode/big-pickle` 和 `opencode/gpt-5-nano`，建议：

- **Sisyphus / Prometheus** 用 `opencode/big-pickle`（更强）
- **Explore / Librarian** 用 `opencode/gpt-5-nano`（更快，够用）
- 避免同时启动 Team Mode（多 Agent 会分摊模型能力）
- 优先用 `ultrawork` 替代手动多 Agent 调度

---

## 检查清单

迁移完成后逐项确认：

- [ ] OMX hooks 已移除（`omx uninstall`）
- [ ] `.omx/` 目录已清理或备份
- [ ] `opencode.json` 已配置 superpowers + oh-my-openagent
- [ ] `oh-my-openagent.json` 已按模型情况配置
- [ ] 项目 AGENTS.md 已适配 oh-my-openagent 格式
- [ ] `bunx oh-my-openagent doctor` 通过
- [ ] OpenCode 重启后插件正常加载
- [ ] 测试运行 `ultrawork` 是否正常

---

## 参考资源

- [oh-my-openagent 安装指南](https://raw.githubusercontent.com/code-yeongyu/oh-my-openagent/refs/heads/dev/docs/guide/installation.md)
- [superpowers 项目](https://github.com/obra/superpowers)
- [OpenCode 文档](https://opencode.ai/docs)
- [Oh My OpenAgent Feature Overview](https://github.com/code-yeongyu/oh-my-openagent#readme)
