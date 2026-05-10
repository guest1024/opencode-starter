# 工具分析手册：superpowers vs gstack vs oh-my-openagent

> 最后更新：2026-05-09

## 概述

本手册分析 OpenCode 生态中三个核心工具的定位、功能重叠、冲突风险及使用建议。

| 工具 | 作者 | 定位 | 目标平台 | 安装方式 |
|------|------|------|----------|----------|
| **superpowers** | obra | 技能集（Skills） | OpenCode | `opencode.json` plugin |
| **gstack** | Garry Tan (YC CEO) | 软件工厂工作流 | Claude Code 为主，也支持 OpenCode | git clone + `./setup` |
| **oh-my-openagent** | code-yeongyu | Agent 编排框架 | OpenCode | `opencode.json` plugin |

---

## 1. superpowers 深度分析

### 是什么

superpowers 是一组 OpenCode **技能包**，提供预定义的 Agent 行为模板。

### 提供的能力

- **brainstorming** — 头脑风暴技能
- **writing-skills** — 写作技能（Anthropic 最佳实践、说服原则等）
- **subagent-driven-development** — 子 Agent 驱动开发（实现者、审查者、规格审查）
- **requesting-code-review** — 代码审查技能
- **systematic-debugging** — 系统化调试技能
- **using-superpowers** — 工具映射参考

### 与 oh-my-openagent 的关系

**无冲突，互补关系。** superpowers 提供的是"技能内容"（做什么），oh-my-openagent 提供的是"Agent 编排"（谁来做、怎么做）。两者叠加使用时，oh-my-openagent 的 Sisyphus Agent 可以调用 superpowers 的技能来执行特定任务。

### 什么时候用

- 需要快速获得一组高质量 Agent 技能模板
- 使用 OpenCode 的原生 skill 工具
- 作为 oh-my-openagent 的补充技能源

---

## 2. gstack 深度分析

### 是什么

gstack 是 YC CEO Garry Tan 开源的个人"软件工厂"——一套完整的 AI 辅助开发流程。包含 23+ 个 Specialist 角色和 8 个 Power Tools，全部通过 slash 命令触发。

### 提供的能力

| 阶段 | 技能 | 角色 |
|------|------|------|
| 思考 | `/office-hours` | YC Office Hours |
| 规划 | `/plan-ceo-review`, `/plan-eng-review`, `/plan-design-review`, `/plan-devex-review`, `/autoplan` | CEO / 架构师 / 设计师 |
| 设计 | `/design-consultation`, `/design-shotgun`, `/design-html` | 设计合伙人 |
| 审查 | `/review`, `/design-review`, `/devex-review` | Staff Engineer |
| 测试 | `/qa`, `/qa-only`, `/browse` | QA Lead |
| 安全 | `/cso` | 安全官 |
| 发布 | `/ship`, `/land-and-deploy`, `/document-release` | Release Engineer |
| 调试 | `/investigate` | Debugger |
| 工具 | `/codex`, `/careful`, `/freeze`, `/guard`, `/benchmark`, `/canary` | Power Tools |

### 与 oh-my-openagent 的冲突分析

| 冲突维度 | 分析 |
|----------|------|
| **Slash 命令命名空间** | gstack 注册大量无前缀 slash 命令（`/review`, `/qa`, `/ship` 等），oh-my-openagent 注册 `/start-work`, `/init-deep`, `/ulw-loop` 等。如果两者同时安装在 OpenCode 中，可能冲突。gstack 的 `--prefix` 选项可加 `/gstack-` 前缀缓解 |
| **工作流哲学** | gstack 是"线性 sprint 流程"（Think→Plan→Build→Review→Test→Ship→Reflect），oh-my-openagent 是"Agent 编排"（Sisyphus 调度 Hephaestus/Oracle/Librarian 等）。两者可以互补，但容易混淆谁负责什么 |
| **模型依赖** | gstack 的 Agent 角色假设你有 Claude Opus / GPT-5 级别的模型。在 `opencode/gpt-5-nano` 级别下，`/review`、`/qa` 等技能效果会严重受限 |
| **安装目标** | gstack 主要为 Claude Code 设计，OpenCode 支持是次要的（`--host opencode`）。oh-my-openagent 是 OpenCode 原生插件 |

### 冲突等级：⚠️ 中等

**结论：不建议同时安装 gstack 和 oh-my-openagent。** 除非：
- 你拥有高质量模型订阅（Claude Opus / GPT-5）
- 用 `--prefix` 隔离命令空间
- 明确划分使用场景（gstack 做独立 sprint，oh-my-openagent 做持续开发）

---

## 3. oh-my-openagent 深度分析

### 是什么

oh-my-openagent 是 OpenCode 的 Agent 编排框架。提供 Discipline Agents（Sisyphus、Hephaestus、Prometheus 等）、Team Mode、背景 Agent、Ralph Loop、Hashline 编辑等核心能力。

### 提供的能力

| 能力 | 说明 |
|------|------|
| **Sisyphus Agent** | 主编排 Agent，规划、委派、驱动任务完成 |
| **Hephaestus** | 自主深度工作 Agent，给目标不给步骤 |
| **Prometheus** | 战略规划 Agent，面试式需求澄清 |
| **Oracle** | 架构/调试 Agent |
| **Librarian** | 文档/代码搜索 Agent |
| **Explore** | 快速代码搜索 Agent |
| **Team Mode** | 多 Agent 并行协作，tmux 可视化 |
| **Ralph Loop** | 自我循环直到 100% 完成 |
| **Hashline** | 基于哈希的编辑验证，零脏行错误 |
| **LSP + AST-Grep** | IDE 精度的 Agent 工具 |
| **Background Agents** | 并行 Specialist |
| **IntentGate** | 意图分析，防止字面误解 |
| **`/init-deep`** | 自动生成层级 AGENTS.md |

### 适用场景

- 需要强大的 Agent 编排能力
- 习惯"说做什么，Agent 自己搞定"的工作方式
- 有或没有优质模型都能运行（通过 fallback 链自动降级）

---

## 4. 综合对比表

| 维度 | superpowers | gstack | oh-my-openagent |
|------|------------|--------|-----------------|
| **类型** | 技能集 | 工作流框架 | Agent 编排框架 |
| **安装复杂度** | 低（一行配置） | 中（git clone + setup） | 低（一行配置） |
| **OpenCode 原生度** | ★★★★★ | ★★★☆☆ | ★★★★★ |
| **模型要求** | 低 | 高（需 Opus/GPT-5） | 中（自动降级） |
| **命令冲突风险** | 低 | 高 | — |
| **与 oh-my-openagent 互补性** | ★★★★★ | ★★☆☆☆ | — |
| **并行能力** | 无 | 无（单 Agent 流程） | ★★★★★（Team Mode） |
| **学习曲线** | 低 | 中 | 中高 |
| **订阅依赖** | 无 | 高 | 中 |

---

## 5. 最终建议

### 当前配置（推荐）

```json
{
  "plugin": [
    "superpowers@git+https://github.com/obra/superpowers.git",
    "oh-my-openagent@latest"
  ]
}
```

| 组件 | 建议 | 理由 |
|------|------|------|
| **superpowers** | ✅ **保留** | 与 oh-my-openagent 无冲突，提供高质量技能模板 |
| **oh-my-openagent** | ✅ **保留** | 当前核心 Agent 编排框架 |
| **gstack** | ❌ **暂不安装** | 需要优质模型订阅才能发挥价值；技能命名空间可能冲突；作为 Claude Code 工具，OpenCode 支持为次要 |

### 什么时候考虑 gstack

- ✅ 你获得了 Claude Pro/Max 订阅
- ✅ 你有明确的 sprint 式开发流程需求
- ✅ 你理解 gstack 是"流程工具"而非"Agent 编排工具"
- ✅ 你用 `--prefix` 隔离命令命名空间

### 什么时候考虑移除 superpowers

- 需要极致精简的插件列表（极少数情况）
- superpowers 中的技能与你的工作流不匹配
