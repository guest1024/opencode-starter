# OpenCode + superpowers + oh-my-openagent 部署 SOP

> 标准操作流程 — 从零搭建到日常维护

## 目录

1. [环境要求](#1-环境要求)
2. [部署流程](#2-部署流程)
3. [配置规范](#3-配置规范)
4. [验证清单](#4-验证清单)
5. [日常维护](#5-日常维护)
6. [故障处理](#6-故障处理)

---

## 1. 环境要求

### 硬件

| 项目 | 最低要求 | 推荐 |
|------|---------|------|
| CPU | 4 核 | 8 核+ |
| 内存 | 8GB | 16GB+ |
| 磁盘 | 10GB 可用 | 20GB+ SSD |
| 网络 | 宽带连接 | 低延迟连接 |

### 软件

| 组件 | 版本要求 | 说明 |
|------|---------|------|
| OS | Linux / macOS / Windows | 本文以 Linux 为例 |
| [Bun](https://bun.sh) | >= 1.0 | 运行时，oh-my-openagent 安装依赖 |
| [Node.js](https://nodejs.org) | >= 18 | OpenCode 底层依赖（Windows 需要） |
| [Git](https://git-scm.com) | >= 2.0 | 插件版本管理 |
| [OpenCode](https://opencode.ai) | >= 1.0.150 | AI 编码助手 |
| curl / wget | 最新 | 脚本下载 |

### 网络要求

- 可访问 `github.com`（插件下载）
- 可访问 LLM API endpoint（模型调用）
- 可访问 `opencode.ai`（OpenCode 下载）

---

## 2. 部署流程

### 2.1 安装 Bun

```bash
# 安装 Bun
curl -fsSL https://bun.sh/install | bash

# 重新加载 shell 配置
source ~/.zshrc  # 或 exec /usr/bin/zsh

# 验证安装
bun --version
```

### 2.2 安装 OpenCode

```bash
# 方式一：通过 npm 安装（推荐）
npm install -g @opencode-ai/cli

# 方式二：直接下载二进制
# 参考 https://opencode.ai/docs

# 验证安装
opencode --version
# 期望输出：>= 1.0.150
```

### 2.3 配置 OpenCode 插件

```bash
# 创建（或编辑）OpenCode 配置文件
mkdir -p ~/.config/opencode
```

编辑 `~/.config/opencode/opencode.json`：

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
    // 在此配置你的 LLM Provider
  }
}
```

> **⚠️ 关于 `skills.paths` 配置**：
> 
> 由于 OpenCode v1.14.x 的 `skill` 工具存在设计缺陷（不搜索插件通过 config hook 注册的路径），需要显式声明 `skills.paths` 才能让 superpowers 的 14 个技能（brainstorming, writing-plans 等）通过 `skill(name="...")` 按名加载。
> 
> - **路径说明**：`/home/user/.cache/opencode/packages/superpowers@git+https:/github.com/obra/superpowers.git/node_modules/superpowers/skills` 是 superpowers 插件安装后的实际路径。如果你的用户名不是 `user`，需要替换为实际的 home 目录路径。
> - **版本更新注意**：superpowers 更新到新版本时，git hash 会变化，路径也会变化。届时需要手动更新此配置。
> - **验证方法**：配置后重启 OpenCode，运行 `skill(name="brainstorming")` 应该能成功加载。
> 
> 详见 [FAQ Q6.5](./faq.md#q65-superpowers-技能无法通过-skill-工具加载)。

### 2.4 安装 oh-my-openagent

```bash
# 运行安装器（按提示选择订阅情况）
# 无订阅的情况：
export PATH="$HOME/.bun/bin:$PATH"
bunx oh-my-openagent install --no-tui \
  --claude=no \
  --openai=no \
  --gemini=no \
  --copilot=no \
  --opencode-zen=no \
  --zai-coding-plan=no \
  --opencode-go=no \
  --kimi-for-coding=no \
  --vercel-ai-gateway=no \
  --skip-auth

# 验证安装
bunx oh-my-openagent doctor
```

### 2.5 配置 Agent 模型

编辑 `~/.config/opencode/oh-my-openagent.json`：

```jsonc
{
  "$schema": "https://raw.githubusercontent.com/code-yeongyu/oh-my-openagent/dev/assets/oh-my-opencode.schema.json",
  "agents": {
    "sisyphus": {
      "model": "opencode/big-pickle"
    },
    "hephaestus": {
      "model": "opencode/gpt-5-nano"
    },
    "oracle": {
      "model": "opencode/gpt-5-nano"
    },
    "librarian": {
      "model": "opencode/gpt-5-nano"
    },
    "explore": {
      "model": "opencode/gpt-5-nano"
    },
    "multimodal-looker": {
      "model": "opencode/gpt-5-nano"
    },
    "prometheus": {
      "model": "opencode/big-pickle"
    },
    "momus": {
      "model": "opencode/gpt-5-nano"
    },
    "atlas": {
      "model": "opencode/gpt-5-nano"
    }
  },
  "categories": {
    "visual-engineering": { "model": "opencode/gpt-5-nano" },
    "ultrabrain": { "model": "opencode/big-pickle" },
    "deep": { "model": "opencode/big-pickle" },
    "quick": { "model": "opencode/gpt-5-nano" },
    "unspecified-high": { "model": "opencode/big-pickle" },
    "unspecified-low": { "model": "opencode/gpt-5-nano" }
  }
}
```

> **模型分配原则**：重任务（Sisyphus、Prometheus、ultrabrain、deep）用强模型；轻任务（Explore、Librarian、quick）用快模型。

### 2.6 重启 OpenCode

```bash
# 重启 OpenCode 使插件生效
opencode
```

### 2.7 验证部署

```bash
# 1. 检查插件加载
opencode run --print-logs "hello" 2>&1 | grep -E "superpowers|oh-my-openagent"

# 2. 运行 oh-my-openagent 诊断
bunx oh-my-openagent doctor

# 3. 检查配置文件
cat ~/.config/opencode/opencode.json
cat ~/.config/opencode/oh-my-openagent.json

# 4. 测试 ultrawork
# 在 OpenCode 中输入：
ultrawork 输出 hello world
```

---

## 3. 配置规范

### 3.1 文件位置总览

| 文件/目录 | 用途 |
|-----------|------|
| `~/.config/opencode/opencode.json` | OpenCode 主配置（插件、Provider） |
| `~/.config/opencode/oh-my-openagent.json` | oh-my-openagent Agent 和分类配置 |
| `~/.config/opencode/package.json` | OpenCode 插件依赖 |
| `~/.config/opencode/node_modules/` | 插件依赖模块 |
| `~/.cache/opencode/packages/` | 插件包缓存 |
| `.opencode/oh-my-openagent.json` | 项目级 oh-my-openagent 配置（覆盖全局） |

### 3.2 opencode.json 配置模板

```json
{
  "$schema": "https://opencode.ai/config.json",
  "plugin": [
    "superpowers@git+https://github.com/obra/superpowers.git",
    "oh-my-openagent@latest"
  ],
  "provider": {
    "my-provider": {
      "npm": "@ai-sdk/openai-compatible",
      "name": "provider-name",
      "options": {
        "baseURL": "https://api.example.com/v1",
        "apiKey": "${MY_API_KEY}"
      },
      "models": {
        "model-name": { "name": "Display Name" }
      }
    }
  }
}
```

> **安全提示**：始终使用环境变量 `${VAR}` 引用 API Key，不要硬编码。

### 3.3 项目级配置

在项目根目录创建 `.opencode/oh-my-openagent.json` 可覆盖全局配置：

```jsonc
{
  "agents": {
    "sisyphus": {
      "model": "opencode/big-pickle",
      "temperature": 0.3
    }
  },
  "categories": {
    "visual-engineering": {
      "model": "opencode/gpt-5-nano"
    }
  }
}
```

### 3.4 AGENTS.md 规范

每个项目应包含 AGENTS.md，这是 Agent 理解项目的入口：

```markdown
# 项目名称

## 技术栈
- 语言/框架版本
- 关键依赖

## 项目结构
```
src/       — 源代码
docs/      — 文档
tests/     — 测试
scripts/   — 工具脚本
```

## 开发约定
- 代码风格：ESLint + Prettier
- 提交规范：Conventional Commits
- 测试要求：单元测试覆盖率 > 80%

## 工作流
- 简单任务直接对话
- 复杂任务用 ultrawork 启动
- 需要规划时按 Tab 进入 Prometheus 模式
```

---

## 4. 验证清单

### 4.1 环境验证

- [ ] `bun --version` — Bun 已安装
- [ ] `opencode --version` — OpenCode >= 1.0.150
- [ ] `node --version` — Node.js >= 18
- [ ] `git --version` — Git 已安装

### 4.2 安装验证

- [ ] `cat ~/.config/opencode/opencode.json` — 包含 `"oh-my-openagent"` 和 `"superpowers"`
- [ ] `cat ~/.config/opencode/oh-my-openagent.json` — Agent 配置完整
- [ ] `bunx oh-my-openagent doctor` — 通过（无错误）
- [ ] 重启 OpenCode 后插件正常加载

### 4.3 功能验证

- [ ] 输入 `ultrawork` 确认 Sisyphus Agent 激活
- [ ] 加载 superpowers 技能：`加载 superpowers/brainstorming 技能`
- [ ] 打开 OpenCode 后无插件加载错误日志
- [ ] LLM Provider 连接正常

### 4.4 项目验证

- [ ] 项目根目录有 AGENTS.md
- [ ] 项目级 `.opencode/oh-my-openagent.json` 已配置（如需）
- [ ] `.gitignore` 中忽略 `.cache/` `.opencode/tmp/`

---

## 5. 日常维护

### 5.1 更新插件

```bash
# 更新 oh-my-openagent 到最新版本
# 方式一：重新安装
bunx oh-my-openagent install --no-tui --skip-auth

# 方式二：清除缓存后重启 OpenCode
rm -rf ~/.cache/opencode/packages/oh-my-openagent@latest
# 重启 OpenCode 后自动重新下载
```

### 5.2 更新 superpowers

```bash
# 清除 superpowers 缓存后重启 OpenCode
rm -rf ~/.cache/opencode/packages/superpowers@git+https:/
# 重启 OpenCode 后自动重新下载
```

### 5.3 更新 Bun

```bash
bun upgrade
```

### 5.4 日志管理

```bash
# oh-my-openagent 运行日志
cat /tmp/oh-my-opencode.log

# OpenCode 插件加载日志
opencode run --print-logs "hello" 2>&1 | grep -E "superpowers|oh-my-openagent"

# 日志文件大小检查
du -sh /tmp/oh-my-opencode.log 2>/dev/null
du -sh ~/.cache/opencode/
```

### 5.5 配置文件备份

```bash
# 备份 OpenCode 配置
cp ~/.config/opencode/opencode.json ~/.config/opencode/opencode.json.bak
cp ~/.config/opencode/oh-my-openagent.json ~/.config/opencode/oh-my-openagent.json.bak
```

### 5.6 定期检查

| 检查项 | 频率 | 操作 |
|--------|------|------|
| oh-my-openagent 诊断 | 每周 | `bunx oh-my-openagent doctor` |
| 插件版本 | 每月 | 检查 GitHub Releases |
| 日志大小 | 每月 | `du -sh /tmp/oh-my-opencode.log` |
| 配置备份 | 每次变更 | `cp *.json *.json.bak` |
| 磁盘空间 | 每月 | `df -h` |

---

## 5.5 代理 API 使用红线

> 使用 `@ai-sdk/openai-compatible` 接入第三方代理 API 时，以下几点是**必须注意**的：

### ❗ 函数调用 Schema 兼容性

第三方代理对 OpenAI 函数调用格式的翻译**不一定完整**。常见踩坑：

- **`structuredOutputs` 必须关闭**：所有代理类 API 建议在 model 配置中添加 `"structuredOutputs": false`，否则可能遇到 `None is not of type 'array'` 等 schema 校验错误
- **模型名必须精确映射**：代理侧有自己的模型命名，确保 `models` 中的 key 与代理 API 要求的标识符一致
- **先测试再使用**：首次接入时，先用带有 tool call 的 prompt 测试函数调用是否正常

> 详细 FAQ 见 `docs/faq.md` → [Q1: Invalid schema for function 'session_list'](faq.md#q1-invalid-schema-for-function-session_list-none-is-not-of-type-array) 和 [附录：代理 API 使用注意事项](faq.md#附录代理-api-使用注意事项)

---

## 6. 故障处理

### 6.1 Oh-my-openagent 不加载

**症状**：OpenCode 中 oh-my-openagent 功能不可用

**排查步骤**：

```bash
# 1. 检查插件配置
cat ~/.config/opencode/opencode.json

# 2. 检查 oh-my-openagent 安装
ls ~/.cache/opencode/packages/oh-my-openagent@latest/

# 3. 查看日志
opencode run --print-logs "hello" 2>&1 | grep -i "openagent"

# 4. 运行诊断
bunx oh-my-openagent doctor

# 5. 重新安装
bunx oh-my-openagent install --no-tui --skip-auth
```

### 6.2 superpowers 技能找不到

**症状**：`技能未找到` 或 `unknown skill`

**解决方案**：

```bash
# 1. 确认技能文件存在
ls ~/.cache/opencode/packages/superpowers@git+https:/github.com/obra/superpowers.git/node_modules/superpowers/skills/

# 2. 检查插件配置
cat ~/.config/opencode/opencode.json

# 3. 重启 OpenCode 后重试
```

### 6.3 OpenCode 启动报错

**症状**：OpenCode 启动时显示插件加载错误

**解决方案**：

```bash
# 1. 查看详细日志
opencode run --print-logs "hello" 2>&1

# 2. 临时禁用插件排查（注释掉 opencode.json 中的 plugin 条目）

# 3. 检查 Bun 和 Node.js 版本
bun --version
node --version
```

### 6.4 Provider 连接失败

**症状**：模型调用超时或返回错误

**排查步骤**：

```bash
# 1. 检查 Provider 配置
cat ~/.config/opencode/opencode.json

# 2. 确认 API Key 有效（使用环境变量）
echo ${MY_API_KEY:0:5}...  # 只输出前5位验证

# 3. 测试 API 连通性
curl -s -o /dev/null -w "%{http_code}" <API_BASE_URL>/v1/models

# 4. 检查网络代理
echo $http_proxy
echo $https_proxy
```

### 6.5 Agent 行为异常

**症状**：Agent 不按预期工作，决策质量下降

**排查步骤**：

```bash
# 1. 检查模型配置是否合理
cat ~/.config/opencode/oh-my-openagent.json

# 2. 确认 AGENTS.md 内容正确
cat AGENTS.md

# 3. 检查模型提供商状态
# 4. 尝试在 prompt 中明确指定工作模式：
# "使用 ultrawork 模式"
```

### 6.6 性能问题

**症状**：Agent 响应慢，Token 消耗大

**优化方案**：

```jsonc
// 1. 轻任务使用快速模型
{
  "agents": {
    "explore": { "model": "opencode/gpt-5-nano" },
    "librarian": { "model": "opencode/gpt-5-nano" }
  }
}

// 2. AGENTS.md 保持简洁，只写 Agent 需要知道的信息
// 3. 避免不必要的 Team Mode（默认关闭）
```

---

## 附录 A：完整安装脚本

```bash
#!/bin/bash
set -e

echo "=== OpenCode + superpowers + oh-my-openagent 一键部署 ==="

# 1. 安装 Bun
if ! command -v bun &> /dev/null; then
    echo ">>> 安装 Bun..."
    curl -fsSL https://bun.sh/install | bash
    export PATH="$HOME/.bun/bin:$PATH"
fi

# 2. 验证环境
echo ">>> 验证环境..."
echo "Bun: $(bun --version)"
echo "Node: $(node --version)"
echo "Git: $(git --version)"

# 3. 检查 OpenCode
if ! command -v opencode &> /dev/null; then
    echo ">>> 请先安装 OpenCode: https://opencode.ai/docs"
    exit 1
fi
echo "OpenCode: $(opencode --version)"

# 4. 配置 opencode.json
mkdir -p ~/.config/opencode
if [ ! -f ~/.config/opencode/opencode.json ]; then
    echo ">>> 创建 opencode.json..."
    cat > ~/.config/opencode/opencode.json << 'CONFIG'
{
  "$schema": "https://opencode.ai/config.json",
  "plugin": [
    "superpowers@git+https://github.com/obra/superpowers.git",
    "oh-my-openagent@latest"
  ]
}
CONFIG
fi

# 5. 安装 oh-my-openagent
echo ">>> 安装 oh-my-openagent..."
bunx oh-my-openagent install --no-tui --claude=no --openai=no --gemini=no --copilot=no --skip-auth

# 6. 验证
echo ">>> 验证安装..."
bunx oh-my-openagent doctor

echo "=== 部署完成！重启 OpenCode 后生效 ==="
```

## 附录 B：故障速查表

| 症状 | 最可能原因 | 最快解决 |
|------|-----------|---------|
| 插件不加载 | opencode.json 语法错误 | `jsonlint ~/.config/opencode/opencode.json` |
| agent 不响应 | 模型配置错误 | 检查 oh-my-openagent.json 中的 model 字段 |
| ultrawork 无效 | oh-my-openagent 未更新 | `bunx oh-my-openagent install --no-tui --skip-auth` |
| 技能找不到 | superpowers 缓存问题 | 清除 `~/.cache/opencode/packages/superpowers*` 后重启 |
| 日志过大 | 未清理 | `truncate -s 0 /tmp/oh-my-opencode.log` |
| bun 命令找不到 | PATH 未更新 | `export PATH="$HOME/.bun/bin:$PATH"` |
