# OpenCode OpenAI-Compatible API 接口规范手册

> 定义 OpenCode 对 `@ai-sdk/openai-compatible` 接入的 OpenAI 格式 API 的具体要求

## 目录

1. [概述](#1-概述)
2. [Chat Completions API](#2-chat-completions-api)
3. [工具/函数调用（Tool Calling）](#3-工具函数调用-tool-calling)
4. [流式响应（Streaming）](#4-流式响应-streaming)
5. [Schema 校验要求](#5-schema-校验要求)
6. [合规检查清单](#6-合规检查清单)
7. [附录：cliproxy 兼容性评估指引](#7-附录cliproxy-兼容性评估指引)

---

## 1. 概述

OpenCode 通过 `@ai-sdk/openai-compatible` 适配器以 **OpenAI 原生 API 格式** 与第三方代理通信。这意味着代理 API 必须实现 OpenAI 标准的 `/v1/chat/completions` 接口，并正确支持以下能力：

| 能力 | 必须/可选 | 说明 |
|------|-----------|------|
| Chat Completions | ✅ **必须** | `/v1/chat/completions` 端点 |
| 多轮对话 | ✅ **必须** | system/user/assistant/tool 四种角色 |
| 工具/函数调用 | ✅ **必须** | `tools` 参数 + `tool_calls` 响应 |
| 并行工具调用 | ✅ **必须** | 单次响应返回多个 tool_calls |
| 流式响应 | ✅ **必须** | SSE 格式 `data: {...}` + `data: [DONE]` |
| 结构化输出 | ⚠️ 可选 | `strict: true` 模式 |
| 系统提示词 | ✅ **必须** | `role: "system"` |
| 视觉输入 | ⚠️ 可选 | `content: [{type: "image_url", ...}]` |

---

## 2. Chat Completions API

### 2.1 端点

```
POST /v1/chat/completions
```

### 2.2 请求体格式

```json
{
  "model": "string",
  "messages": [
    {
      "role": "system" | "user" | "assistant" | "tool",
      "content": "string | array",
      "tool_calls": [           // 仅 assistant 角色可用
        {
          "id": "string",
          "type": "function",
          "function": {
            "name": "string",
            "arguments": "string"  // JSON 序列化的参数字符串
          }
        }
      ],
      "tool_call_id": "string",   // 仅 tool 角色可用
      "name": "string"             // 仅 tool 角色可用
    }
  ],
  "tools": [
    {
      "type": "function",
      "function": {
        "name": "string",
        "description": "string",
        "parameters": {
          "type": "object",
          "properties": { },
          "required": [ "param1" ]   // 必须为数组，无必填时传 []
        },
        "strict": true | false
      }
    }
  ],
  "tool_choice": "none" | "auto" | "required" | {
    "type": "function",
    "function": { "name": "string" }
  },
  "stream": true | false,
  "max_tokens": 4096,
  "temperature": 0.0 ~ 2.0,
  "top_p": 0.0 ~ 1.0,
  "stop": "string | string[]",
  "presence_penalty": -2.0 ~ 2.0,
  "frequency_penalty": -2.0 ~ 2.0,
  "parallel_tool_calls": true | false
}
```

### 2.3 响应体格式（非流式）

```json
{
  "id": "chatcmpl-xxx",
  "object": "chat.completion",
  "created": 1234567890,
  "model": "model-name",
  "choices": [
    {
      "index": 0,
      "message": {
        "role": "assistant",
        "content": "string | null",
        "tool_calls": [
          {
            "id": "call_xxx",
            "type": "function",
            "function": {
              "name": "string",
              "arguments": "string"   // JSON 字符串，必须可 parse
            }
          }
        ]
      },
      "finish_reason": "stop" | "length" | "tool_calls" | "content_filter",
      "logprobs": null
    }
  ],
  "usage": {
    "prompt_tokens": 100,
    "completion_tokens": 50,
    "total_tokens": 150,
    "prompt_tokens_details": {          // ⚠️ 可选，但推荐
      "cached_tokens": 0
    },
    "completion_tokens_details": {      // ⚠️ 可选，但推荐
      "reasoning_tokens": 0
    }
  }
}
```

### 2.4 关键字段校验

| 字段 | 校验要求 |
|------|---------|
| `id` | 必须是非空字符串 |
| `object` | 必须是 `"chat.completion"` |
| `choices` | 必须是非空数组 |
| `choices[].message.role` | 必须是 `"assistant"` |
| `choices[].message.content` | 可以为 `null`（当有 tool_calls 时） |
| `choices[].finish_reason` | 必须是 `"stop"` / `"length"` / `"tool_calls"` 之一 |
| `usage` | 必须包含 `prompt_tokens` 和 `completion_tokens` |

---

## 3. 工具/函数调用（Tool Calling）

### 3.1 工具定义

OpenCode 将每个 tool 定义发送为 OpenAI 的 function：

```json
{
  "type": "function",
  "function": {
    "name": "tool_name",
    "description": "What this tool does",
    "parameters": {
      "type": "object",
      "properties": {
        "param1": {
          "type": "string",
          "description": "Parameter description"
        },
        "param2": {
          "type": "number",
          "description": "Parameter description"
        }
      },
      "required": ["param1"]     // ⚠️ 必须为数组
    },
    "strict": false               // ⚠️ 见 3.3 节
  }
}
```

### 3.2 工具调用响应

模型返回工具调用时，必须遵循以下格式：

```json
{
  "tool_calls": [
    {
      "id": "call_unique_id",
      "type": "function",
      "function": {
        "name": "tool_name",
        "arguments": "{\"param1\": \"value1\"}"
      }
    }
  ]
}
```

**强制要求**：

| 字段 | 必须 | 说明 |
|------|------|------|
| `id` | ✅ | 唯一标识，用于关联 tool 结果 |
| `type` | ✅ | 必须是 `"function"` |
| `function.name` | ✅ | 必须匹配已注册的 tool 名称 |
| `function.arguments` | ✅ | 必须是**有效的 JSON 字符串**（可被 `JSON.parse`） |

### 3.3 `strict` 模式说明

`strict: true` 启用 OpenAI 的结构化输出模式，对 tool schema 有更严格的校验：

| 校验项 | strict: true | strict: false |
|--------|-------------|---------------|
| `required` 必须为数组 | ✅ 强制 | ❌ 不强制 |
| `required` 可为空数组 `[]` | ✅ 允许 | ✅ 允许 |
| 属性类型必须具体 | ✅ 强制 | ❌ 不强制 |
| `additionalProperties` 必须为 false | ✅ 强制 | ❌ 不强制 |

**⚠️ 已知问题**：某些代理 API 在 `strict: true` 模式下，当 tool 没有 required 参数时，会将 `required` 错误转换为 `null` 而非 `[]`，导致 schema 校验失败。

**👉 推荐做法**：对所有代理 API，在 model 配置中设置 `"structuredOutputs": false`，或使用 `"strict": false`：

```json
{
  "models": {
    "your-model": {
      "name": "Your Model",
      "structuredOutputs": false
    }
  }
}
```

或直接在 tool 定义中使用：
```json
{
  "type": "function",
  "function": {
    "name": "tool_name",
    "parameters": { ... },
    "strict": false
  }
}
```

### 3.4 并行工具调用

OpenCode 支持单次响应中的多个并行工具调用：

```json
{
  "tool_calls": [
    {
      "id": "call_1",
      "type": "function",
      "function": { "name": "search", "arguments": "{\"q\":\"hello\"}" }
    },
    {
      "id": "call_2",
      "type": "function",
      "function": { "name": "read", "arguments": "{\"path\":\"/file\"}" }
    }
  ]
}
```

**要求**：
- 并行 tool_calls 数组中的每个元素必须有**唯一**的 `id`
- 代理 API **不能**忽略或合并并行调用（某些代理只支持单工具调用）

### 3.5 工具调用结果回传

OpenCode 会将工具执行结果以 `role: "tool"` 的消息发回：

```json
{
  "role": "tool",
  "tool_call_id": "call_1",
  "content": "工具执行结果字符串"
}
```

**要求**：
- `tool_call_id` 必须匹配前一步返回的 `id`
- `content` 通常是字符串（工具执行结果）

---

## 4. 流式响应（Streaming）

### 4.1 请求

必须设置 `"stream": true`：

```json
{
  "stream": true,
  "stream_options": {
    "include_usage": true    // 推荐：在最后 chunk 包含用量信息
  }
}
```

### 4.2 SSE 格式

每个数据行以 `data: ` 前缀开头，以 `\n\n` 双换行结束：

```
data: {"id":"chatcmpl-xxx","object":"chat.completion.chunk","choices":[{"index":0,"delta":{"role":"assistant","content":""},"finish_reason":null}],"usage":null}

data: {"id":"chatcmpl-xxx","object":"chat.completion.chunk","choices":[{"index":0,"delta":{"content":"Hello"},"finish_reason":null}]}

data: {"id":"chatcmpl-xxx","object":"chat.completion.chunk","choices":[{"index":0,"delta":{"tool_calls":[{"index":0,"id":"call_1","type":"function","function":{"name":"search","arguments":""}}]},"finish_reason":null}]}

data: {"id":"chatcmpl-xxx","object":"chat.completion.chunk","choices":[{"index":0,"delta":{"tool_calls":[{"index":0,"function":{"arguments":"{\"q\":"}}]},"finish_reason":null}]}

data: {"id":"chatcmpl-xxx","object":"chat.completion.chunk","choices":[{"index":0,"delta":{"tool_calls":[{"index":0,"function":{"arguments":"\"hello\"}"}}]},"finish_reason":null}]}

data: {"id":"chatcmpl-xxx","object":"chat.completion.chunk","choices":[{"index":0,"delta":{},"finish_reason":"tool_calls"}]}

data: {"id":"chatcmpl-xxx","object":"chat.completion.chunk","choices":[{"index":0,"delta":{},"finish_reason":"stop"}],"usage":{"prompt_tokens":100,"completion_tokens":50}}

data: [DONE]
```

### 4.3 Streaming 关键要求

| 要求 | 说明 |
|------|------|
| **前缀** | 每行必须以 `data: ` 开头，末尾 `\n\n` |
| **终止** | 最后发送 `data: [DONE]\n\n` |
| **角色** | 首个 chunk 必须送 `role: "assistant"` |
| **tool_calls** | 首帧送 `id` + `type` + `function.name`；后续帧逐片送 `function.arguments` |
| **index** | 多个并行 tool_calls 必须使用不同的 `index` |
| **finish_reason** | 最终帧必须送 `finish_reason` |
| **usage** | 推荐在最终帧或不带 choices 的独立帧回传 |
| **空行** | 不能有多余空行干扰 SSE 解析 |

### 4.4 Streaming Tool Calls 关键

工具调用的流式数据分片发送（Delta 格式）：

```
Chunk 1: delta: {"tool_calls":[{"index":0,"id":"call_1","type":"function","function":{"name":"search","arguments":""}}]}
Chunk 2: delta: {"tool_calls":[{"index":0,"function":{"arguments":"{\"param1\":"}}]}
Chunk 3: delta: {"tool_calls":[{"index":0,"function":{"arguments":"\"value1\"}"}}]}
Chunk 4: delta: {}, finish_reason: "tool_calls"
```

**注意**：
- `index` 用于区分同一响应中的多个并行工具调用
- 首个 chunk 必须包含 `id`、`type`、`function.name`
- 后续 chunk 只送 `function.arguments` 的增量部分
- 最终 `finish_reason` 必须为 `"tool_calls"`

---

## 5. Schema 校验要求

### 5.1 工具参数 Schema

OpenCode 使用 JSON Schema 描述工具参数。适配器对 schema 格式有校验：

```json
{
  "type": "object",
  "properties": {
    "param1": { "type": "string" },
    "param2": { "type": "number" },
    "param3": {
      "type": "array",
      "items": { "type": "string" }
    },
    "param4": {
      "type": "object",
      "properties": {
        "nested1": { "type": "string" }
      },
      "required": ["nested1"]
    }
  },
  "required": ["param1"]     // ⚠️ 必须为数组
}
```

### 5.2 `required` 字段红线

**这是最常见的兼容性问题**：

| 场景 | `required` 的值 | 合规 |
|------|----------------|------|
| 有必填参数 | `["param1", "param2"]` | ✅ |
| 无必填参数 | `[]` | ✅ |
| 无必填参数 | 不传该字段 | ⚠️ strict 模式下非法 |
| 无必填参数 | `null` | ❌ **触发 None is not of type 'array'** |
| 无必填参数 | `undefined` | ❌ **触发校验错误** |

> **代理 API 在处理 `strict: true` 的工具定义时，必须确保 `required` 字段为数组。**
>
> 如果代理在转发时将缺失的 `required` 转换为 `null` 或 `undefined`，会导致
> `Invalid schema for function 'xxx': None is not of type 'array'` 错误。

### 5.3 代理 API `required` 处理决策树

当 OpenCode 发送工具定义给代理 API 时，代理需要在传输过程中正确处理 schema：

```
OpenCode 发送的工具 Schema
     │
     ├─ required: ["param1"]   → 代理直接转发 ✅
     │
     ├─ required: []           → 代理必须保留空数组，不能丢弃 ✅
     │
     └─ (无 required 字段)     → 代理的处理方式：
         ├─ 保留无 required → 标准 JSON Schema，某些校验器可接受 ⚠️
         ├─ 补充 required: [] → 推荐做法 ✅
         └─ 补充 required: null → 触发错误 ❌
```

### 5.4 支持的 JSON Schema 类型

| JSON Schema 类型 | 对应 TypeScript | 说明 |
|-----------------|----------------|------|
| `"string"` | `string` | 基本字符串 |
| `"number"` | `number` | 数字（含整数） |
| `"boolean"` | `boolean` | 布尔值 |
| `"array"` | `T[]` | 数组，需指定 `items` |
| `"object"` | `Record<string, T>` | 嵌套对象 |
| `"enum"` | 联合类型 | 通过 `enum: [...]` 或 `oneOf` |
| `"null"` | `null` | 允许 null |

### 5.5 schema 传输生命周期

```
oh-my-openagent (Zod 定义)
     │
     ▼ 工具注册
OpenCode 运行时 (生成 JSON Schema)
     │
     ▼ @ai-sdk/openai-compatible (适配器)
适配器 (转为 OpenAI Function 格式)
     │
     ▼ HTTP POST /v1/chat/completions
代理 API (中转/翻译)
     │
     ▼ (如为 Anthropic 代理)
模型 API (Claude/GPT/其他)
```

**合规关键点**：
- 适配器 → 代理：OpenAI 格式必须正确
- 代理 → 模型：schema 在翻译过程中不能丢失/变形
- 代理 → 模型：`required` 必须保持为数组

---

## 6. 合规检查清单

### 6.1 基础 API ✅

- [ ] 实现 `POST /v1/chat/completions`
- [ ] 支持 `model` 参数
- [ ] 支持 `messages` 数组
- [ ] 支持 `stream: true` 和 `stream: false`
- [ ] 返回正确的 HTTP 状态码（200 成功，4xx 客户端错误，5xx 服务端错误）
- [ ] 返回 `Content-Type: application/json`（非流式）
- [ ] 返回 `Content-Type: text/event-stream`（流式）

### 6.2 消息角色 ✅

- [ ] `system` 角色：支持系统提示词
- [ ] `user` 角色：支持用户消息（文本）
- [ ] `assistant` 角色：支持助手回复
- [ ] `assistant` 角色：支持 `tool_calls`
- [ ] `tool` 角色：支持工具执行结果回传，含 `tool_call_id`
- [ ] 多轮对话：连续多轮交互无异常

### 6.3 工具调用 ✅

- [ ] 请求：支持 `tools` 参数
- [ ] 请求：支持 `tool_choice` 参数（auto/none/required/function）
- [ ] 请求：tool 的 `parameters` 中包含有效的 `required` 数组
- [ ] 响应：`tool_calls` 中每个元素含唯一 `id`
- [ ] 响应：`function.arguments` 为有效 JSON 字符串
- [ ] 响应：`finish_reason` 在 tool 调用时返回 `"tool_calls"`
- [ ] 并行：支持单个响应返回多个 `tool_calls`

### 6.4 流式响应 ✅

- [ ] SSE 格式：`data: {...}\n\n`
- [ ] 首个 chunk 含 `role: "assistant"`
- [ ] 流式工具调用：首帧含 `id` + `type` + `function.name`
- [ ] 流式工具调用：后续帧增量发送 `function.arguments`
- [ ] 流式工具调用：最终帧 `finish_reason: "tool_calls"`
- [ ] 流结束：发送 `data: [DONE]\n\n`
- [ ] 支持 `stream_options: { include_usage: true }`

### 6.5 Schema 合规 ✅

- [ ] `required` 字段始终为数组，不传 `null`
- [ ] 无必填参数时传 `required: []`（而非省略）
- [ ] `function.arguments` 是 JSON 字符串（非对象）
- [ ] `tool_calls` 的 `type` 为 `"function"`
- [ ] 流式响应中 delta 格式正确

### 6.6 错误处理 ✅

- [ ] 模型不可用时返回明确错误码
- [ ] 超时返回可识别的错误
- [ ] 认证失败返回 401
- [ ] 速率限制返回 429（含 Retry-After 头）
- [ ] 无效请求参数返回 400 + 错误描述

---

## 7. 附录：cliproxy 兼容性评估指引

### 7.1 评估方法

使用以下步骤评估代理 API 的兼容性：

**Step 1：基础连通性测试**
```bash
curl -s https://your-proxy.com/v1/models | jq '.data[].id'
```

**Step 2：简单对话测试**
```bash
curl -s -X POST https://your-proxy.com/v1/chat/completions \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $API_KEY" \
  -d '{
    "model": "model-name",
    "messages": [{"role": "user", "content": "Hello"}],
    "stream": false
  }' | jq .
```

**Step 3：工具调用测试**
```bash
curl -s -X POST https://your-proxy.com/v1/chat/completions \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $API_KEY" \
  -d '{
    "model": "model-name",
    "messages": [{"role": "user", "content": "What is the weather in Beijing?"}],
    "tools": [
      {
        "type": "function",
        "function": {
          "name": "get_weather",
          "description": "Get weather for a city",
          "parameters": {
            "type": "object",
            "properties": {
              "city": {"type": "string"}
            },
            "required": ["city"]
          }
        }
      }
    ],
    "tool_choice": "auto"
  }' | jq .
```

**Step 4：空 required 测试（关键！）**
```bash
curl -s -X POST https://your-proxy.com/v1/chat/completions \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $API_KEY" \
  -d '{
    "model": "model-name",
    "messages": [{"role": "user", "content": "List sessions"}],
    "tools": [
      {
        "type": "function",
        "function": {
          "name": "session_list",
          "description": "List sessions",
          "parameters": {
            "type": "object",
            "properties": {
              "limit": {"type": "number"},
              "from_date": {"type": "string"}
            },
            "required": []
          },
          "strict": true
        }
      }
    ],
    "tool_choice": "required"
  }' | jq .
```

**Step 5：流式工具调用测试**
```bash
curl -s -X POST https://your-proxy.com/v1/chat/completions \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $API_KEY" \
  -d '{
    "model": "model-name",
    "messages": [{"role": "user", "content": "What is the weather in Beijing and Shanghai?"}],
    "tools": [{
      "type": "function",
      "function": {
        "name": "get_weather",
        "parameters": {
          "type": "object",
          "properties": {"city": {"type": "string"}},
          "required": ["city"]
        }
      }
    }],
    "stream": true
  }' | head -20
```

### 7.2 常见代理问题速查

| 问题 | 可能原因 | 检出方法 |
|------|---------|---------|
| `None is not of type 'array'` | `required` 被转成 `null` | Step 4 测试 |
| 工具不调用 | tool_choice 被忽略 | Step 3 测试 |
| 流式不工作 | SSE 格式不对 | Step 5 测试 |
| arguments 不是 JSON | 响应中 arguments 是对象而非字符串 | Step 3 检查响应 |
| 并行调用失败 | 代理不支持多 tool_calls | Step 5 测试多城市 |
| 中文乱码 | UTF-8 编码问题 | Step 2 测试中文 |
| 超时频繁 | 代理性能不足 | 监控响应时间 |

### 7.3 推荐配置模板

```json
{
  "provider": {
    "my-proxy": {
      "npm": "@ai-sdk/openai-compatible",
      "name": "my-proxy",
      "options": {
        "baseURL": "https://your-proxy.com/v1",
        "apiKey": "${PROXY_API_KEY}"
      },
      "models": {
        "your-model": {
          "name": "Your Model Name",
          "structuredOutputs": false
        }
      }
    }
  }
}
```

> **核心原则**：对代理 API **始终设置 `structuredOutputs: false`**，除非你已通过 Step 4 验证其完整支持 strict 模式。
