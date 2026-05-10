# cliproxy API 开发手册：Anthropic → OpenAI 协议转换

> 从零构建一个将 Claude API（Anthropic 格式）转换为 OpenAI 兼容格式的代理层

## 目录

1. [概述](#1-概述)
2. [协议对比总览](#2-协议对比总览)
3. [请求转换](#3-请求转换)
4. [响应转换](#4-响应转换)
5. [流式响应转换](#5-流式响应转换)
6. [工具/函数调用转换（核心难点）](#6-工具函数调用转换核心难点)
7. [Schema 处理技巧](#7-schema-处理技巧)
8. [错误处理](#8-错误处理)
9. [完整转换流程](#9-完整转换流程)
10. [测试验证](#10-测试验证)

---

## 1. 概述

### 1.1 为什么要做转换

OpenCode 及其生态工具使用 **OpenAI 格式** 的 Chat Completions API。Claude 模型使用 **Anthropic Messages API**。cliproxy 作为一个中间层，需要：

```
客户端 (OpenAI 格式) 
    → cliproxy (翻译层) 
    → Claude API (Anthropic 格式)
    → cliproxy (反向翻译) 
    → 客户端 (OpenAI 格式)
```

### 1.2 核心挑战

| 挑战 | 难度 | 说明 |
|------|------|------|
| 消息结构差异 | ⭐⭐ | Anthropic 的 `content` 是数组，OpenAI 的 `content` 可以是字符串或数组 |
| 工具定义格式 | ⭐⭐⭐⭐ | Anthropic 的 `input_schema` vs OpenAI 的 `parameters` + `strict` |
| 工具调用格式 | ⭐⭐⭐ | Anthropic 的 `content[].tool_use` vs OpenAI 的 `message.tool_calls[]` |
| 流式事件模型 | ⭐⭐⭐⭐⭐ | 完全不同的事件体系（Anthropic events vs OpenAI SSE chunks） |
| Schema 校验 | ⭐⭐⭐⭐ | 代理必须正确处理 `required` 数组以避免 `None is not of type 'array'` |
| 并行工具调用 | ⭐⭐⭐ | 两种格式的并行调用事件流不同 |
| 图像输入 | ⭐⭐ | Anthropic 的 `image` source vs OpenAI 的 `image_url` |

---

## 2. 协议对比总览

### 2.1 端点

| 功能 | Anthropic | OpenAI |
|------|-----------|--------|
| 对话 | `POST /v1/messages` | `POST /v1/chat/completions` |
| 模型列表 | `GET /v1/models` | `GET /v1/models` |
| 流式请求头 | `accept: text/event-stream` | `stream: true` 参数 |
| 认证 | `x-api-key` header | `Authorization: Bearer` header |

### 2.2 请求体对比

```jsonc
// Anthropic Messages API
{
  "model": "claude-sonnet-4-20250506",
  "max_tokens": 4096,              // 必填
  "messages": [
    {"role": "user", "content": "Hello"}
  ],
  "system": "You are helpful",      // 独立字段
  "temperature": 0.7,
  "top_p": 0.9,
  "metadata": { "user_id": "..." },
  "stop_sequences": ["\n\n"],
  "stream": true,
  "tools": [
    {
      "name": "get_weather",
      "description": "...",
      "input_schema": {             // ⚠️ 与 OpenAI 不同
        "type": "object",
        "properties": { ... },
        "required": ["city"]
      }
    }
  ],
  "tool_choice": {
    "type": "auto" | "any" | "tool",
    "name": "tool_name"             // 当 type= "tool" 时需要
  }
}
```

```jsonc
// OpenAI Chat Completions
{
  "model": "claude-sonnet-4-6",
  "max_tokens": 4096,              // 可选
  "messages": [
    {"role": "system", "content": "You are helpful"},  // system 在 messages 中
    {"role": "user", "content": "Hello"}
  ],
  "temperature": 0.7,
  "top_p": 0.9,
  "user": "...",
  "stop": ["\n\n"],
  "stream": true,
  "tools": [
    {
      "type": "function",           // ⚠️ 必须为 "function"
      "function": {
        "name": "get_weather",
        "description": "...",
        "parameters": {             // ⚠️ 与 Anthropic 不同
          "type": "object",
          "properties": { ... },
          "required": ["city"]
        },
        "strict": false
      }
    }
  ],
  "tool_choice": "auto" | "none" | "required" | {
    "type": "function",
    "function": { "name": "tool_name" }
  }
}
```

### 2.3 响应体对比

```jsonc
// Anthropic (成功)
{
  "id": "msg_xxx",
  "type": "message",
  "role": "assistant",
  "content": [
    {"type": "text", "text": "Hello"},
    {
      "type": "tool_use",
      "id": "toolu_xxx",
      "name": "get_weather",
      "input": {"city": "Beijing"}
    }
  ],
  "model": "claude-sonnet-4-20250506",
  "stop_reason": "end_turn" | "tool_use" | "max_tokens" | "stop_sequence",
  "stop_sequence": null,
  "usage": {
    "input_tokens": 10,
    "output_tokens": 20,
    "cache_creation_input_tokens": 0,
    "cache_read_input_tokens": 0
  }
}
```

```jsonc
// OpenAI (成功)
{
  "id": "chatcmpl-xxx",
  "object": "chat.completion",
  "created": 1234567890,
  "model": "claude-sonnet-4-6",
  "choices": [
    {
      "index": 0,
      "message": {
        "role": "assistant",
        "content": "Hello",                            // 与 tool_calls 互斥
        "tool_calls": [                                // 当有工具调用时
          {
            "id": "call_xxx",
            "type": "function",
            "function": {
              "name": "get_weather",
              "arguments": "{\"city\": \"Beijing\"}"   // ⚠️ 必须是 JSON 字符串
            }
          }
        ]
      },
      "finish_reason": "stop" | "tool_calls" | "length"
    }
  ],
  "usage": {
    "prompt_tokens": 10,
    "completion_tokens": 20,
    "total_tokens": 30
  }
}
```

### 2.4 核心差异速查表

| 维度 | Anthropic | OpenAI |
|------|-----------|--------|
| **系统提示词** | 请求顶层 `system` 字段 | `messages[0]` 中 `role: "system"` |
| **用户内容** | `content` 是数组：`[{type: "text"/"image", ...}]` | `content` 是字符串 或 数组：`[{type: "text"/"image_url", ...}]` |
| **助手内容** | `content` 是数组，可混合 text + tool_use | `content` 是字符串，`tool_calls` 在 message 顶层 |
| **工具定义** | 直接 `name`/`description`/`input_schema` | 包裹在 `{type: "function", function: {...}}` 中 |
| **工具参数名** | `input_schema` | `parameters` |
| **工具返回** | `content` 中 `type: "tool_result"` | `role: "tool"` 的消息 |
| **工具调用 ID** | `id` 以 `toolu_` 开头 | `id` 以 `call_` 开头 |
| **工具参数值** | `input` 是对象 | `arguments` 是 JSON 字符串 |
| **停止原因** | `stop_reason: "tool_use"` | `finish_reason: "tool_calls"` |
| **最大 Token** | 必填 `max_tokens` | 可选 `max_tokens` |
| **认证** | `x-api-key` header | `Authorization: Bearer` header |
| **流式** | SSE events（6 种事件类型） | SSE chunks（单一事件流 + `[DONE]`） |
| **模型名** | Anthropic 模型标识符 | 自定义映射后的名称 |
| **Token 用量** | 拆分 `input_tokens/output_tokens` | 合并 `prompt_tokens/completion_tokens` |

---

## 3. 请求转换

### 3.1 顶层字段映射

OpenAI 请求 → Anthropic 请求：

| OpenAI 字段 | → Anthropic 字段 | 处理逻辑 |
|-------------|-----------------|---------|
| `model` | `model` | 需要模型名映射表 |
| `messages` | `messages` + `system` | 拆分 system 消息 |
| `max_tokens` | `max_tokens` | 直接传递（Anthropic 必填，缺失则设默认值） |
| `temperature` | `temperature` | 直接传递 |
| `top_p` | `top_p` | 直接传递 |
| `stop` | `stop_sequences` | 数组格式 |
| `stream` | `stream` | 直接传递 |
| `tools` | `tools` | 格式转换（见 §6） |
| `tool_choice` | `tool_choice` | 格式转换（见 §6.4） |
| `user` | `metadata.user_id` | 映射到 metadata |
| `frequency_penalty` | ❌ | 不支持，忽略或警告 |
| `presence_penalty` | ❌ | 不支持，忽略或警告 |
| `logit_bias` | ❌ | 不支持，忽略 |
| `response_format` | ❌ | 不支持（Claude 不支持 JSON mode） |

### 3.2 系统提示词处理

```javascript
function convertMessages(openaiMessages) {
  const anthropicMessages = [];
  let systemPrompt = null;

  for (const msg of openaiMessages) {
    if (msg.role === 'system') {
      // OpenAI: system 是独立消息
      // Anthropic: system 在请求顶层
      systemPrompt = msg.content;
    } else if (msg.role === 'user') {
      anthropicMessages.push(convertUserMessage(msg));
    } else if (msg.role === 'assistant') {
      anthropicMessages.push(convertAssistantMessage(msg));
    } else if (msg.role === 'tool') {
      anthropicMessages.push(convertToolResult(msg));
    }
  }

  return { messages: anthropicMessages, system: systemPrompt };
}
```

### 3.3 用户消息转换

OpenAI 格式：
```json
{
  "role": "user",
  "content": "Hello"
}
// 或
{
  "role": "user",
  "content": [
    {"type": "text", "text": "What's this?"},
    {"type": "image_url", "image_url": {"url": "data:image/jpeg;base64,..."}}
  ]
}
```

Anthropic 格式：
```json
{
  "role": "user",
  "content": [
    {"type": "text", "text": "What's this?"},
    {
      "type": "image",
      "source": {
        "type": "base64",
        "media_type": "image/jpeg",
        "data": "..."
      }
    }
  ]
}
```

```javascript
function convertUserMessage(openaiMsg) {
  let content;
  if (typeof openaiMsg.content === 'string') {
    content = [{ type: 'text', text: openaiMsg.content }];
  } else {
    content = openaiMsg.content.map(block => {
      if (block.type === 'text') return block;
      if (block.type === 'image_url') {
        // 解析 data:image/{media_type};base64,{data}
        const match = block.image_url.url.match(/^data:(image\/\w+);base64,(.+)$/);
        if (match) {
          return {
            type: 'image',
            source: {
              type: 'base64',
              media_type: match[1],
              data: match[2]
            }
          };
        }
        throw new Error('Unsupported image URL format');
      }
      return block;
    });
  }
  return { role: 'user', content };
}
```

### 3.4 助手消息转换

OpenAI 格式：
```json
{
  "role": "assistant",
  "content": "Let me check...",
  "tool_calls": [
    {
      "id": "call_xxx",
      "type": "function",
      "function": {
        "name": "get_weather",
        "arguments": "{\"city\": \"Beijing\"}"
      }
    }
  ]
}
```

Anthropic 格式：
```json
{
  "role": "assistant",
  "content": [
    {"type": "text", "text": "Let me check..."},
    {
      "type": "tool_use",
      "id": "toolu_xxx",          // ⚠️ toolu_ 前缀
      "name": "get_weather",
      "input": {"city": "Beijing"} // ⚠️ 对象，非字符串
    }
  ]
}
```

```javascript
function convertAssistantMessage(openaiMsg) {
  const content = [];

  if (openaiMsg.content) {
    content.push({ type: 'text', text: openaiMsg.content });
  }

  if (openaiMsg.tool_calls) {
    for (const tc of openaiMsg.tool_calls) {
      content.push({
        type: 'tool_use',
        id: tc.id.replace(/^call_/, 'toolu_'),  // ID 前缀转换
        name: tc.function.name,
        input: JSON.parse(tc.function.arguments)  // 字符串 → 对象
      });
    }
  }

  return { role: 'assistant', content };
}
```

### 3.5 工具结果转换

OpenAI 格式：
```json
{
  "role": "tool",
  "tool_call_id": "call_xxx",
  "content": "Sunny, 25°C"
}
```

Anthropic 格式：
```json
{
  "role": "user",
  "content": [
    {
      "type": "tool_result",
      "tool_use_id": "toolu_xxx",
      "content": "Sunny, 25°C"
    }
  ]
}
```

```javascript
function convertToolResult(openaiMsg) {
  return {
    role: 'user',
    content: [{
      type: 'tool_result',
      tool_use_id: openaiMsg.tool_call_id.replace(/^call_/, 'toolu_'),
      content: openaiMsg.content
    }]
  };
}
```

---

## 4. 响应转换

### 4.1 非流式响应

Anthropic 响应 → OpenAI 响应：

```javascript
function convertResponse(anthropicResp) {
  const content = anthropicResp.content || [];
  const textParts = content.filter(c => c.type === 'text');
  const toolUseParts = content.filter(c => c.type === 'tool_use');

  const message = {
    role: 'assistant',
    content: textParts.map(t => t.text).join('') || null,
    tool_calls: toolUseParts.map((tc, idx) => ({
      id: tc.id.replace(/^toolu_/, 'call_'),    // 前缀转换
      type: 'function',
      function: {
        name: tc.name,
        arguments: JSON.stringify(tc.input)       // 对象 → JSON 字符串
      }
    }))
  };

  return {
    id: anthropicResp.id.replace(/^msg_/, 'chatcmpl-'),
    object: 'chat.completion',
    created: Math.floor(Date.now() / 1000),
    model: anthropicResp.model,
    choices: [{
      index: 0,
      message,
      finish_reason: mapStopReason(anthropicResp.stop_reason)
    }],
    usage: convertUsage(anthropicResp.usage)
  };
}

function mapStopReason(anthropicReason) {
  const map = {
    'end_turn': 'stop',
    'tool_use': 'tool_calls',
    'max_tokens': 'length',
    'stop_sequence': 'stop'
  };
  return map[anthropicReason] || 'stop';
}

function convertUsage(anthropicUsage) {
  return {
    prompt_tokens: anthropicUsage.input_tokens,
    completion_tokens: anthropicUsage.output_tokens,
    total_tokens: anthropicUsage.input_tokens + anthropicUsage.output_tokens,
    prompt_tokens_details: {
      cached_tokens: (anthropicUsage.cache_read_input_tokens || 0) +
                     (anthropicUsage.cache_creation_input_tokens || 0)
    }
  };
}
```

---

## 5. 流式响应转换

### 5.1 事件映射表

这是 **cliproxy 最复杂的部分**。Anthropic 有 6 种流式事件，需要映射到 OpenAI 的 SSE chunks。

| Anthropic 事件 | 触发时机 | → OpenAI SSE 输出 |
|---------------|---------|------------------|
| `message_start` | 消息开始 | 无直接映射（缓存 metadata） |
| `content_block_start` | 内容块开始 | text → `delta: {role: "assistant", content: ""}`；tool_use → `delta: {tool_calls: [{index, id, type, function}]}` |
| `content_block_delta` | 内容块增量 | text_delta → `delta: {content: "..."}`；input_json_delta → `delta: {tool_calls: [{index, function: {arguments: "..."}}]}` |
| `content_block_stop` | 内容块结束 | 无直接映射 |
| `message_delta` | 消息层增量 | 发送 `delta: {}` 含 `finish_reason` |
| `message_stop` | 消息结束 | 发送 `data: [DONE]` |

### 5.2 流式转换核心代码

```javascript
function handleAnthropicStream(anthropicStream, openaiResponse) {
  let messageId = null;
  let model = null;
  let currentToolCalls = {};    // index → {id, name, arguments}
  let hasSentRole = false;

  // Anthropic 流式响应：SSE events
  // event: message_start
  // data: { "type": "message_start", "message": { "id": "msg_xxx", "model": "...", ... } }
  //
  // event: content_block_start
  // data: { "type": "content_block_start", "index": 0, "content_block": { "type": "text", "text": "" } }
  // data: { "type": "content_block_start", "index": 1, "content_block": { "type": "tool_use", "id": "toolu_xxx", "name": "get_weather", "input": {} } }
  //
  // event: content_block_delta
  // data: { "type": "content_block_delta", "index": 0, "delta": { "type": "text_delta", "text": "Hello" } }
  // data: { "type": "content_block_delta", "index": 1, "delta": { "type": "input_json_delta", "partial_json": "{\"city\": \"Bei" } }
  //
  // event: content_block_stop
  // data: { "type": "content_block_stop", "index": 0 }
  //
  // event: message_delta
  // data: { "type": "message_delta", "delta": { "stop_reason": "end_turn", "stop_sequence": null }, "usage": { "output_tokens": 50 } }
  //
  // event: message_stop
  // data: { "type": "message_stop" }

  const sseParser = new SSEDecoder();

  for await (const chunk of anthropicStream) {
    const events = sseParser.decode(chunk);

    for (const event of events) {
      const data = JSON.parse(event.data);

      switch (data.type) {
        case 'message_start':
          messageId = data.message.id;
          model = data.message.model;
          // OpenAI 流式不需要在开始时发送内容
          break;

        case 'content_block_start': {
          const block = data.content_block;
          if (block.type === 'text') {
            // 发送角色标识 + 空内容（OpenAI 首个 chunk 必须包含 role）
            if (!hasSentRole) {
              writeOpenAIChunk(openaiResponse, {
                choices: [{
                  index: 0,
                  delta: { role: 'assistant', content: '' },
                  finish_reason: null
                }]
              });
              hasSentRole = true;
            }
          } else if (block.type === 'tool_use') {
            currentToolCalls[data.index] = {
              id: block.id.replace(/^toolu_/, 'call_'),
              name: block.name,
              arguments: ''
            };
            // 发送 tool_calls 首帧（含 id + type + name）
            if (!hasSentRole) {
              writeOpenAIChunk(openaiResponse, {
                choices: [{
                  index: 0,
                  delta: {
                    role: 'assistant',
                    tool_calls: [{
                      index: data.index,
                      id: currentToolCalls[data.index].id,
                      type: 'function',
                      function: {
                        name: currentToolCalls[data.index].name,
                        arguments: ''
                      }
                    }]
                  },
                  finish_reason: null
                }]
              });
              hasSentRole = true;
            } else {
              writeOpenAIChunk(openaiResponse, {
                choices: [{
                  index: 0,
                  delta: {
                    tool_calls: [{
                      index: data.index,
                      id: currentToolCalls[data.index].id,
                      type: 'function',
                      function: {
                        name: currentToolCalls[data.index].name,
                        arguments: ''
                      }
                    }]
                  },
                  finish_reason: null
                }]
              });
            }
          }
          break;
        }

        case 'content_block_delta': {
          const delta = data.delta;
          if (delta.type === 'text_delta') {
            writeOpenAIChunk(openaiResponse, {
              choices: [{
                index: 0,
                delta: { content: delta.text },
                finish_reason: null
              }]
            });
          } else if (delta.type === 'input_json_delta') {
            // 累加 arguments
            if (currentToolCalls[data.index]) {
              currentToolCalls[data.index].arguments += delta.partial_json;
            }
            writeOpenAIChunk(openaiResponse, {
              choices: [{
                index: 0,
                delta: {
                  tool_calls: [{
                    index: data.index,
                    function: {
                      arguments: delta.partial_json
                    }
                  }]
                },
                finish_reason: null
              }]
            });
          }
          break;
        }

        case 'content_block_stop':
          // 无操作 — 等待 message_delta 发送 finish_reason
          break;

        case 'message_delta': {
          // 发送 finish_reason + usage
          const stopReason = data.delta.stop_reason;
          const finishReason = mapStopReason(stopReason);
          const usage = data.usage ? {
            prompt_tokens: 0,  // 已从 message_start 获取
            completion_tokens: data.usage.output_tokens,
            total_tokens: data.usage.output_tokens
          } : null;

          writeOpenAIChunk(openaiResponse, {
            choices: [{
              index: 0,
              delta: {},
              finish_reason: finishReason
            }],
            usage: usage,
            id: messageId?.replace(/^msg_/, 'chatcmpl-')
          });
          break;
        }

        case 'message_stop':
          // 发送 [DONE] 终止
          writeOpenAIChunk(openaiResponse, 'data: [DONE]\n\n');
          break;
      }
    }
  }
}

function writeOpenAIChunk(response, data) {
  response.write(`data: ${JSON.stringify(data)}\n\n`);
}
```

### 5.3 流式并行工具调用

当 Claude 同时返回多个工具调用时：

```
Anthropic 流:
  content_block_start index=0 → tool_use {id: "toolu_a", name: "search"}
  content_block_start index=1 → tool_use {id: "toolu_b", name: "read"}
  content_block_delta index=0 → input_json_delta: "{\"q\":\"hello\"}"
  content_block_delta index=1 → input_json_delta: "{\"path\":\"/file\"}"
  content_block_stop index=0
  content_block_stop index=1
  message_delta → stop_reason: "tool_use"

OpenAI SSE 输出:
  data: {"choices":[{"delta":{"tool_calls":[{"index":0,"id":"call_a","type":"function","function":{"name":"search","arguments":""}}]}}]}
  data: {"choices":[{"delta":{"tool_calls":[{"index":1,"id":"call_b","type":"function","function":{"name":"read","arguments":""}}]}}]}
  data: {"choices":[{"delta":{"tool_calls":[{"index":0,"function":{"arguments":"{\"q\":\"hello\"}"}}]}}]}
  data: {"choices":[{"delta":{"tool_calls":[{"index":1,"function":{"arguments":"{\"path\":\"/file\"}"}}]}}]}
  data: {"choices":[{"delta":{},"finish_reason":"tool_calls"}]}
  data: [DONE]
```

---

## 6. 工具/函数调用转换（核心难点）

### 6.1 工具定义转换

这是 **最常见的兼容性故障点**，也是你遇到的 `None is not of type 'array'` 的根本原因。

```javascript
function convertTools(openaiTools) {
  if (!openaiTools || !openaiTools.length) return undefined;

  return openaiTools.map(tool => {
    if (tool.type !== 'function') {
      throw new Error(`Unsupported tool type: ${tool.type}`);
    }

    const fn = tool.function;

    // ⚠️ 关键：确保 required 始终为数组
    const parameters = { ...fn.parameters };
    if (!parameters.required) {
      // required 不存在或为 null/undefined → 设为空数组
      parameters.required = [];
    } else if (!Array.isArray(parameters.required)) {
      // required 存在但不是数组 → 强制转为数组
      console.warn(`Tool '${fn.name}': required is not an array, coercing to []`);
      parameters.required = [];
    }

    return {
      name: fn.name,
      description: fn.description || '',
      input_schema: parameters
    };
  });
}
```

### 6.2 `required` 处理黄金规则

| 输入（OpenAI `required`） | 处理 | 输出（Anthropic `required`） |
|--------------------------|------|----------------------------|
| `["param1"]` | 直接传递 | `["param1"]` |
| `[]` | 直接传递 | `[]` |
| `undefined` / 缺失 | **补充空数组** | `[]` |
| `null` | **补充空数组** | `[]` |

> **这条规则是代理 API 最常出错的地方。** 许多代理选择"保留原样"转发 `required` 字段，
> 当它为 null/undefined 时，触发 OpenAI 端的 `None is not of type 'array'` 错误。

### 6.3 工具调用结果转换（反向）

```javascript
function convertToolUseToToolCall(toolUseBlock, index) {
  return {
    id: toolUseBlock.id.replace(/^toolu_/, 'call_'),
    type: 'function',
    function: {
      name: toolUseBlock.name,
      arguments: JSON.stringify(toolUseBlock.input)   // 对象 → JSON 字符串
    }
  };
}
```

> ⚠️ **`arguments` 必须是字符串！** 如果代理将 `arguments` 作为对象返回，
> 某些客户端会解析失败。始终使用 `JSON.stringify()`。

### 6.4 tool_choice 转换

```javascript
function convertToolChoice(openaiChoice) {
  if (!openaiChoice) return { type: 'auto' };

  if (typeof openaiChoice === 'string') {
    const map = {
      'auto': { type: 'auto' },
      'none': { type: 'none' },   // Anthropic 不支持 none，需特殊处理
      'required': { type: 'any' } // OpenAI 的 required → Anthropic 的 any
    };
    return map[openaiChoice] || { type: 'auto' };
  }

  if (openaiChoice.type === 'function') {
    return {
      type: 'tool',
      name: openaiChoice.function.name
    };
  }

  return { type: 'auto' };
}
```

**⚠️ `tool_choice: "none"` 的特殊处理**：

OpenAI 的 `tool_choice: "none"` 表示模型不得调用任何工具。Anthropic 没有直接等价选项，最佳做法是：

1. 从请求中完全移除 `tools` 数组（这会导致模型不知道有工具存在）
2. 或者保留工具但在 system prompt 中强调不要调用工具

推荐做法：如果 `tool_choice: "none"`，则不发送 `tools` 给 Anthropic API。

---

## 7. Schema 处理技巧

### 7.1 JSON Schema 方言差异

Anthropic 和 OpenAI 对 JSON Schema 的支持程度略有不同：

| 特性 | Anthropic | OpenAI | 代理处理 |
|------|-----------|--------|---------|
| `$schema` | 忽略 | 可能校验 | 建议移除 |
| `additionalProperties` | 忽略 | strict 模式下校验 | 设为 `false`（strict）或移除 |
| `default` | 不支持 | 可能支持 | 建议保留，无害 |
| `examples` | 忽略 | 忽略 | 可保留 |
| `oneOf` / `anyOf` | 实验性 | 有限支持 | 有风险，测试后使用 |
| `const` | 支持 | 支持 | 直接传递 |
| `format` (如 `date-time`) | 忽略 | 可能校验 | 建议移除 |

**推荐做法**：在转发前对 JSON Schema 做清理：

```javascript
function sanitizeSchema(schema) {
  if (!schema || typeof schema !== 'object') return schema;

  const clean = { ...schema };

  // 移除可能引起问题的字段
  delete clean.$schema;
  delete clean.examples;

  // 确保 required 是数组
  if (!Array.isArray(clean.required)) {
    clean.required = [];
  }

  // 递归处理嵌套
  if (clean.properties) {
    for (const key of Object.keys(clean.properties)) {
      clean.properties[key] = sanitizeSchema(clean.properties[key]);
    }
  }
  if (clean.items) {
    clean.items = sanitizeSchema(clean.items);
  }

  return clean;
}
```

### 7.2 类型映射

```javascript
const TYPE_MAP = {
  // 标准类型
  'string': 'string',
  'number': 'number',
  'integer': 'number',       // Anthropic 用 integer
  'boolean': 'boolean',
  'array': 'array',
  'object': 'object',
  'null': 'null',

  // 特殊处理
  'any': undefined,          // 移除，可能导致问题
};
```

### 7.3 模型名映射

```javascript
const MODEL_MAP = {
  // OpenAI 请求中的模型名 → Anthropic API 的模型名
  'claude-sonnet-4-6': 'claude-sonnet-4-20250506',
  'claude-sonnet-4-5': 'claude-sonnet-4-20241022',
  'claude-opus-4-7': 'claude-opus-4-20250514',
  'claude-haiku-4-5': 'claude-haiku-4-20250506',

  // 也支持用户直接使用 Anthropic 模型名
  'claude-sonnet-4-20250506': 'claude-sonnet-4-20250506',
};

function mapModelName(openaiModel) {
  return MODEL_MAP[openaiModel] || openaiModel;
}
```

---

## 8. 错误处理

### 8.1 HTTP 错误映射

| Anthropic 错误 | HTTP | OpenAI 等价错误 | HTTP |
|---------------|------|----------------|------|
| `invalid_request_error` | 400 | 400 Bad Request | 400 |
| `authentication_error` | 401 | 401 Unauthorized | 401 |
| `permission_error` | 403 | 403 Forbidden | 403 |
| `not_found_error` | 404 | 404 Not Found | 404 |
| `rate_limit_error` | 429 | 429 Too Many Requests | 429 |
| `api_error` | 500 | 500 Internal Server Error | 500 |
| `overloaded_error` | 529 | 503 Service Unavailable | 503 |

```javascript
function convertError(anthropicError) {
  const statusMap = {
    'invalid_request_error': 400,
    'authentication_error': 401,
    'permission_error': 403,
    'not_found_error': 404,
    'rate_limit_error': 429,
    'api_error': 500,
    'overloaded_error': 503
  };

  const status = statusMap[anthropicError.type] || 500;

  return {
    status,
    body: {
      error: {
        message: anthropicError.message,
        type: anthropicError.type,
        code: anthropicError.type
      }
    }
  };
}
```

### 8.2 需要特殊处理的情况

| 场景 | 处理方式 |
|------|---------|
| Anthropic 响应超时 | 返回 OpenAI 格式的 504 Gateway Timeout |
| API Key 无效 | 返回 401 + `{"error": {"message": "Incorrect API key", "type": "invalid_request_error"}}` |
| 请求体过大 | 返回 413 Payload Too Large |
| Anthropic 服务过载 (529) | 转换为 503 + `Retry-After` header |
| 流式连接断开 | 关闭 SSE 连接，不发送不完整数据 |

### 8.3 API Key 转换

```javascript
// 客户端发来的请求：
// Authorization: Bearer sk-xxx

// 转换为 Anthropic 格式：
// x-api-key: sk-ant-xxx

function extractApiKey(openaiRequest) {
  const authHeader = openaiRequest.headers['authorization'];
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    throw new Error('Missing or invalid Authorization header');
  }
  return authHeader.slice(7);  // 去掉 "Bearer "
}

function forwardToAnthropic(apiKey, body) {
  return fetch('https://api.anthropic.com/v1/messages', {
    method: 'POST',
    headers: {
      'x-api-key': apiKey,
      'anthropic-version': '2023-06-01',
      'content-type': 'application/json',
      'accept': body.stream ? 'text/event-stream' : 'application/json'
    },
    body: JSON.stringify(body)
  });
}
```

---

## 9. 完整转换流程

### 9.1 请求处理流水线

```
客户端 (OpenAI 格式)
  │
  ├─ POST /v1/chat/completions
  │
  ▼
1. 参数校验
  │  ├─ 检查必要字段（model, messages）
  │  ├─ 验证 tool 格式
  │  └─ 检查 API Key
  │
  ▼
2. 模型名映射
  │  └─ MODEL_MAP[openaiModel] || openaiModel
  │
  ▼
3. 消息转换
  │  ├─ 提取 system prompt
  │  ├─ 转换 user/assistant/tool 消息
  │  └─ 处理 tool_calls（对象 ← JSON 字符串）
  │
  ▼
4. 工具转换
  │  ├─ type: "function" → 剥除外层
  │  ├─ parameters → input_schema
  │  ├─ 修复 required（数组检查！）
  │  └─ 处理 tool_choice
  │
  ▼
5. token 配额
  │  └─ 确保 max_tokens 有值（Anthropic 必填）
  │
  ▼
6. 调用 Anthropic API
  │  └─ POST /v1/messages
  │     ├─ 非流式 → 等待完整响应
  │     └─ 流式 → 逐块转换
  │
  ▼
7. 响应/流式转换
  ├─ 非流式：转换 content[].tool_use → tool_calls
  └─ 流式：逐一转换 6 种事件 → SSE chunks
  │
  ▼
客户端 (OpenAI 格式)
```

### 9.2 关键守护逻辑

```javascript
async function handleChatCompletion(openaiRequest) {
  try {
    // Step 1: 提取 API Key
    const apiKey = extractApiKey(openaiRequest);

    // Step 2: 转换请求体
    const anthropicBody = convertRequest(openaiRequest.body);

    // Step 3: 调用 Anthropic API
    if (openaiRequest.body.stream) {
      return await handleStreaming(apiKey, anthropicBody);
    } else {
      const response = await fetchAnthropic(apiKey, anthropicBody);
      const anthropicData = await response.json();
      // Step 4: 转换响应
      return convertResponse(anthropicData);
    }
  } catch (err) {
    return convertError(err);
  }
}
```

---

## 10. 测试验证

### 10.1 测试用例矩阵

```javascript
const testCases = [
  // 1. 简单对话
  { name: 'simple_chat', messages: [{ role: 'user', content: 'Hello' }] },

  // 2. 带系统的对话
  { name: 'with_system', messages: [
    { role: 'system', content: 'You are helpful' },
    { role: 'user', content: 'Hi' }
  ]},

  // 3. 单工具调用（有 required）
  { name: 'tool_with_required', messages: [
    { role: 'user', content: 'Weather in Beijing?' }
  ], tools: [{
    type: 'function',
    function: {
      name: 'get_weather',
      parameters: {
        type: 'object',
        properties: { city: { type: 'string' } },
        required: ['city']
      }
    }
  }]},

  // 4. 空 required（关键测试！）
  { name: 'tool_empty_required', messages: [
    { role: 'user', content: 'List sessions' }
  ], tools: [{
    type: 'function',
    function: {
      name: 'session_list',
      parameters: {
        type: 'object',
        properties: {
          limit: { type: 'number' },
          from_date: { type: 'string' }
        },
        required: []     // ⚠️ 空数组
      },
      strict: true
    }
  }]},

  // 5. 无 required 字段
  { name: 'tool_no_required', messages: [
    { role: 'user', content: 'Search' }
  ], tools: [{
    type: 'function',
    function: {
      name: 'search',
      parameters: {
        type: 'object',
        properties: { q: { type: 'string' } }
        // required 字段缺失
      }
    }
  }]},

  // 6. 并行工具调用
  { name: 'parallel_tools', messages: [
    { role: 'user', content: 'Weather in Beijing and Shanghai?' }
  ], tools: [{
    type: 'function',
    function: {
      name: 'get_weather',
      parameters: {
        type: 'object',
        properties: { city: { type: 'string' } },
        required: ['city']
      }
    }
  }]},

  // 7. 流式对话
  { name: 'streaming_chat', messages: [
    { role: 'user', content: 'Hello' }
  ], stream: true },

  // 8. 流式工具调用
  { name: 'streaming_tool', messages: [
    { role: 'user', content: 'Weather?' }
  ], tools: [/* ... */], stream: true },

  // 9. 图像输入
  { name: 'image_input', messages: [
    { role: 'user', content: [
      { type: 'text', text: 'What is this?' },
      { type: 'image_url', image_url: { url: 'data:image/jpeg;base64,...' } }
    ]}
  ]},

  // 10. tool_choice 测试
  { name: 'tool_choice_none', messages: [
    { role: 'user', content: 'Hello' }
  ], tools: [/* ... */], tool_choice: 'none' },
  { name: 'tool_choice_required', messages: [
    { role: 'user', content: 'Use tool' }
  ], tools: [/* ... */], tool_choice: 'required' },
];
```

### 10.2 端到端测试脚本

```bash
# 测试 1：基础对话
curl -s -X POST http://localhost:8080/v1/chat/completions \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $ANTHROPIC_API_KEY" \
  -d '{
    "model": "claude-sonnet-4-6",
    "messages": [{"role": "user", "content": "Hello"}],
    "max_tokens": 100
  }' | jq .

# 测试 2：空 required 工具（核心兼容性测试）
curl -s -X POST http://localhost:8080/v1/chat/completions \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $ANTHROPIC_API_KEY" \
  -d '{
    "model": "claude-sonnet-4-6",
    "messages": [{"role": "user", "content": "Call session_list"}],
    "tools": [{
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
    }],
    "tool_choice": "required"
  }' | jq .

# 测试 3：流式工具调用
curl -s -X POST http://localhost:8080/v1/chat/completions \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $ANTHROPIC_API_KEY" \
  -d '{
    "model": "claude-sonnet-4-6",
    "messages": [{"role": "user", "content": "Weather in Beijing and Shanghai?"}],
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
  }'

# 测试 4：多轮工具对话
curl -s -X POST http://localhost:8080/v1/chat/completions \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $ANTHROPIC_API_KEY" \
  -d '{
    "model": "claude-sonnet-4-6",
    "messages": [
      {"role": "user", "content": "Weather in Beijing?"},
      {"role": "assistant", "content": null, "tool_calls": [{
        "id": "call_1",
        "type": "function",
        "function": {"name": "get_weather", "arguments": "{\"city\":\"Beijing\"}"}
      }]},
      {"role": "tool", "tool_call_id": "call_1", "content": "Sunny, 25°C"}
    ],
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
    }]
  }' | jq .
```

### 10.3 常见问题排查

| 症状 | 原因 | 修复 |
|------|------|------|
| `None is not of type 'array'` | `required` 在转换中被设为 null | 在 convertTools 中确保 `required` 始终为数组 |
| `arguments` 解析失败 | `arguments` 是对象而非字符串 | 使用 `JSON.stringify(tc.input)` |
| 流式工具调用缺少 `id` | Anthropic 的 `content_block_start` 未正确映射 | 在 `content_block_start` 中捕获 `id` |
| 流式工具调用 `arguments` 断裂 | `input_json_delta` 的 `partial_json` 未正确拼接 | 累积 `partial_json` 片段发送 |
| 并行工具调用顺序错乱 | `index` 未正确传递 | 确保 `content_block_start` 和 `content_block_delta` 使用相同的 `index` |
| `finish_reason` 缺失 | `message_delta` 的 `stop_reason` 未映射 | 实现 `mapStopReason()` |
| Tool 调用后模型得不到结果 | `tool_result` 消息格式错误 | 检查 `tool_use_id` 前缀和 `content` 格式 |

---

## 附录：编码安全检查清单

- [ ] `required` 字段始终为数组，不传 null/undefined
- [ ] `function.arguments` 是 JSON 字符串（非对象）
- [ ] tool ID 前缀正确转换（`toolu_` ↔ `call_`）
- [ ] 流式响应首 chunk 包含 `role: "assistant"`
- [ ] 流式响应最后发送 `data: [DONE]`
- [ ] `max_tokens` 在 Anthropic 请求中始终有值
- [ ] `system` 提示词已从 messages 数组提取
- [ ] `tool_choice: "none"` 已特殊处理（移除 tools）
- [ ] 图像输入已从 `image_url` 格式转换为 `image` 格式
- [ ] API Key 已从 `Authorization: Bearer` 转为 `x-api-key`
- [ ] 错误响应使用 OpenAI 格式
- [ ] 响应使用 `JSON.stringify()` 序列化工具参数
- [ ] 流式中 `content_block_start` 的 `input: {}` 不会触发额外的 schema 处理
