# 常见问题 FAQ

> 使用 OpenCode + superpowers + oh-my-openagent 过程中遇到的典型问题及解决方案

## 目录

1. [模型/Provider 相关](#1-模型provider-相关)
2. [插件/安装相关](#2-插件安装相关)
3. [功能/使用相关](#3-功能使用相关)

---

## 1. 模型/Provider 相关

### Q1: Invalid schema for function 'session_list': None is not of type 'array'

**症状**：切换模型后出现此错误，函数调用功能不可用。

```
Invalid schema for function 'session_list': None is not of type 'array'
```

**原因**：
oh-my-openagent 中的 `session_list` 函数所有参数都是可选的（`.optional()`），序列化成 JSON Schema 后没有 `required` 字段。当使用 `@ai-sdk/openai-compatible` 适配器配合某些代理 API（如 `claude.aiapis.help/v1`）时，代理开启了 OpenAI 的 `strict: true`（结构化输出）模式。此模式强制要求 `required` 字段必须是一个数组，即使是空数组 `[]`。代理在翻译过程中将缺失的 `required` 设置成了 `null`，触发了 JSON Schema 校验失败。

**影响范围**：所有参数全为 optional 的工具函数（`session_list`、`session_search`、`session_info` 等）。

**解决方案**：

在 `opencode.json` 的对应 model 配置中添加 `"structuredOutputs": false`：

```json
{
  "provider": {
    "my-provider": {
      "npm": "@ai-sdk/openai-compatible",
      "name": "my-provider",
      "options": {
        "baseURL": "https://your-proxy-api.com/v1",
        "apiKey": "${API_KEY}"
      },
      "models": {
        "your-model": {
          "name": "Your Model",
          "structuredOutputs": false
        }
      }
    }
  }
}
```

**原理**：`structuredOutputs: false` 会关闭 OpenAI 的 strict 函数调用模式，代理不再强制校验 `required` 字段，schema 验证通过。

**验证**：重启 OpenCode 后错误消失。

---

### Q2: Model not found: xxx. Did you mean: yyy?

**症状**：
```
Model not found: new-api/claude-sonnet-4-6. Did you mean: my-new-api?
```

**原因**：Provider 配置中的 key 名称与模型中引用的 provider 前缀不匹配。例如 opencode.json 中 provider key 是 `my-new-api`，但在 oh-my-openagent.json 的 model 字段中写成了 `new-api/claude-sonnet-4-6`。

**解决方案**：确保 model 字符串中的 provider 前缀与 opencode.json 中的 provider key 完全一致。

```jsonc
// opencode.json
{
  "provider": {
    "my-new-api": {  // ← 这是 key
      ...
      "models": {
        "claude-sonnet-4-6": { ... }
      }
    }
  }
}

// oh-my-openagent.json — model 字段必须是 my-new-api/claude-sonnet-4-6
{
  "agents": {
    "sisyphus": { "model": "my-new-api/claude-sonnet-4-6" }
  }
}
```

---

### Q3: Provider 连接失败 / API 返回 401

**症状**：模型调用时返回 401 Unauthorized 或连接超时。

**排查步骤**：

```bash
# 1. 测试 API 连通性
curl -s -o /dev/null -w "HTTP %{http_code}" https://your-api.com/v1/models

# 2. 确认 API Key 有效（不要泄露完整 key）
echo ${API_KEY:0:5}...

# 3. 检查网络代理
echo $http_proxy
echo $https_proxy

# 4. 查看 OpenCode 日志
cat /tmp/oh-my-opencode.log
```

---

## 2. 插件/安装相关

### Q4: oh-my-openagent 插件不加载

**症状**：OpenCode 中没有 oh-my-openagent 的功能（ultrawork 不生效）。

**排查步骤**：

```bash
# 1. 检查配置文件
cat ~/.config/opencode/opencode.json
# 确认包含 "oh-my-openagent@latest" 在 plugin 数组中

# 2. 运行诊断
bunx oh-my-openagent doctor

# 3. 查看插件加载日志
opencode run --print-logs "hello" 2>&1 | grep -i openagent

# 4. 重新安装
bunx oh-my-openagent install --no-tui --skip-auth
```

---

### Q5: Doctor 报 "Comment checker unavailable"

**症状**：
```
Comment checker binary is not installed.
```

**说明**：这是 oh-my-openagent 的可选功能（检查 AI 生成的注释质量）。不影响核心功能。

**修复**（可选）：
```bash
npm install -g @code-yeongyu/comment-checker
```

---

### Q6: Doctor 报 "GitHub CLI not authenticated"

**症状**：
```
GitHub CLI is not installed or not authenticated.
```

**说明**：gh CLI 用于 GitHub 自动化（创建 PR、star 仓库等）。不影响核心开发功能。

**修复**：
```bash
# 安装 gh CLI
sudo apt-get install gh   # Debian/Ubuntu
brew install gh           # macOS

# 登录 GitHub
gh auth login
```

---

### Q6.5: Superpowers 技能无法通过 `skill` 工具加载

**症状**：

```bash
skill(name="brainstorming")
# 返回: Skill or command "brainstorming" not found.
```

所有 superpowers 技能（brainstorming, writing-plans, systematic-debugging 等 14 个）都无法通过 `skill` 工具按名加载，但 AI 的系统提示中能看到这些技能。

**根因**：

OpenCode 的技能发现机制分为两层：

1. **Prompt 构建层**：读取 `config.skills.paths`（包括插件通过 config hook 注册的路径），将技能元数据注入 AI 的 `available_skills` 上下文 → ✅ 工作正常
2. **`skill` 工具层**：按名查找技能时，只搜索内置命令（playwright, frontend-ui-ux, git-master, review-work, ai-slop-remover + 10 个 slash 命令），不搜索 `config.skills.paths` → ❌ 找不到 superpowers 技能

这是 **OpenCode v1.14.x `skill` 工具的设计缺陷**：插件通过 config hook 注册的路径（内存级修改）对 prompt 构建可见，但对 `skill` 工具不可见。

**影响范围**：

- ✅ **AI 不受影响**：所有 14 个 superpowers 技能已在系统提示中可见，AI 可以直接读取 SKILL.md 文件并遵循其指令
- ❌ **用户交互受限**：无法通过 `skill(name="...")` 按需加载技能内容
- ❌ **工具一致性问题**：技能发现与工具查找机制不一致

**解决方案（Workaround）**：

在 `~/.config/opencode/opencode.json` 中显式声明 `skills.paths`（持久化到磁盘，绕过插件 config hook）：

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
  ...
}
```

**注意事项**：

1. **路径会随 superpowers 版本变化**：如果 superpowers 更新到新版本（如从 v5.1.0 到 v5.2.0），git hash 会变，缓存路径也会变。需要手动更新 `skills.paths`。
2. **需要重启 OpenCode**：修改 opencode.json 后必须重启才能生效。
3. **验证方法**：重启后运行 `skill(name="brainstorming")`，应该能成功加载。

**更优雅的方案探讨**：

| 方案 | 优点 | 缺点 | 可行性 |
|------|------|------|--------|
| **当前 workaround**（显式 skills.paths） | 简单直接，立即生效 | 路径硬编码，版本更新需手动维护 | ✅ 已实施 |
| **修复 OpenCode `skill` 工具** | 根本解决，插件机制完整 | 需要等待上游修复 | ⏳ 需提 issue |
| **项目级 opencode.json** | 便携性好，不污染全局配置 | 每个项目都要配置 | ✅ 可选方案 |
| **符号链接到标准路径** | 路径固定 | superpowers 已废弃此方案 | ❌ 不推荐 |
| **插件直接写入 opencode.json** | 自动化 | 违反插件边界，可能冲突 | ❌ 架构不当 |

**推荐行动**：

1. **短期**：使用当前 workaround（已应用）
2. **中期**：向 OpenCode 提交 issue，要求 `skill` 工具支持搜索 `config.skills.paths`
3. **长期**：等待 OpenCode 修复后移除 workaround

**相关 Issue 模板**（供提交给 OpenCode）：

```markdown
**Bug**: `skill` tool doesn't search plugin-registered `config.skills.paths`

**Environment**: OpenCode v1.14.46

**Steps to reproduce**:
1. Install superpowers plugin via `"plugin": ["superpowers@git+https://github.com/obra/superpowers.git"]`
2. Verify skills appear in AI's `available_skills` context
3. Try `skill(name="brainstorming")` → returns "not found"

**Expected**: `skill` tool should search paths registered by plugins via config hook

**Actual**: `skill` tool only searches builtin commands

**Workaround**: Manually add `skills.paths` to opencode.json
```

---

## 3. 功能/使用相关

### Q7: ultrawork 不生效 / Sisyphus Agent 不响应

**症状**：输入 `ultrawork` 后没有触发预期的多 Agent 编排。

**排查步骤**：

```bash
# 1. 检查 oh-my-openagent 安装
bunx oh-my-openagent doctor

# 2. 检查 Agent 配置
cat ~/.config/opencode/oh-my-openagent.json

# 3. 确认模型配置正确
# 确保所有 agent 引用的 model 在 opencode.json 中有定义

# 4. 重启 OpenCode
```

---

### Q8: Agent 回答质量差 / 决策错误

**症状**：Agent 给出的方案不合理，决策质量明显下降。

**可能原因**：

| 原因 | 表现 | 解决 |
|------|------|------|
| 模型能力不足 | 复杂推理错误 | 升级模型（如从 gpt-5-nano 升级到 big-pickle） |
| prompt 不清晰 | 理解偏差 | 提供更详细的上下文和约束 |
| AGENTS.md 缺失 | 不了解项目结构 | 创建 AGENTS.md 描述项目 |
| Provider 不稳定 | 响应时好时坏 | 切换到更稳定的 Provider |

---

## 附录：代理 API 使用注意事项

> 使用 `@ai-sdk/openai-compatible` 接入第三方代理 API（如 `claude.aiapis.help` 类）时，需要特别注意以下几点：

### ⚠️ 1. 函数调用（Function Calling）兼容性

不是所有代理都完整支持 OpenAI 的函数调用格式。常见问题：

| 问题 | 原因 | 表现 |
|------|------|------|
| `required` 字段校验失败 | 代理对 `strict` 模式的 `required` 数组处理不正确 | `None is not of type 'array'` |
| 工具响应格式错误 | 代理转换 Anthropic ↔ OpenAI 工具格式时精度丢失 | Tool call 解析失败 |
| 并行工具调用不支持 | 代理未实现 `parallel_tool_calls` | 模型一次只能调用一个工具 |

**建议**：
- 首次接入时用简单 prompt 测试工具调用功能
- 出现 schema 错误时优先尝试 `structuredOutputs: false`
- 记录代理 API 的厂商和版本，便于问题复现

### ⚠️ 2. 模型名称映射

代理 API 通常有自己的一套模型名称映射规则，与标准名称可能不同：

```json
{
  "models": {
    "custom-model-key": {
      "name": "模型在代理侧的显示名"
    }
  }
}
```

**建议**：
- 确认代理 API 文档中的模型标识符
- 在 `models` 中定义明确的 key-value 映射
- 避免在 oh-my-openagent.json 中使用未定义的模型名

### ⚠️ 3. API Key 安全

```bash
# ❌ 不安全：直接在配置文件中写明文
"apiKey": "sk-xxxxxxxxxxxxxxxx"

# ✅ 安全：使用环境变量
"apiKey": "${MY_API_KEY}"
```

**建议**：
- 始终使用 `${VAR}` 引用环境变量
- 不要在代码仓库中提交包含 API Key 的配置文件
- 定期轮换 API Key

### ⚠️ 4. 稳定性与速率限制

代理 API 通常存在以下风险：

- **速率限制**（Rate Limit）：比官方 API 更严格的调用频率限制
- **可用性**：依赖第三方服务稳定性
- **延迟**：多一层代理转发增加延迟
- **版本兼容**：代理可能落后于官方 API 版本更新

**建议**：
- 配置多个 Provider 作为 fallback
- 监控 API 响应时间和错误率
- 有计划地切换到稳定的 Provider

### ⚠️ 5. 供应商评估检查清单

> 详细 API 格式规范请参考 `docs/api-spec.md` → [OpenCode OpenAI-Compatible API 接口规范手册](api-spec.md)

接入新的代理 API 前，建议逐项确认：

- [ ] 是否完整支持 OpenAI 函数调用格式？
- [ ] 是否支持流式响应（streaming）？
- [ ] 是否支持并行工具调用？
- [ ] 是否支持 system prompt？
- [ ] 模型名称映射明确吗？
- [ ] 有明确的速率限制说明吗？
- [ ] 有 SLA 或可用性保证吗？
- [ ] 数据传输是否加密？
- [ ] 支持 API Key 轮换吗？
- [ ] 有中文或英文技术支持吗？
