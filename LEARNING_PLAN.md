# Vibe Coding 嗅觉训练计划

> 目标：在 AI 辅助开发的真实项目中，建立对前后端全栈架构的"嗅觉"——当 AI 写出有问题的代码时能闻到味道，能在关键时候发现问题所在。
>
> 核心理念：不是成为"古法编程高手"，而是成为"AI 时代的有效驾驭者"。不需要写出每一行代码，但需要判断 AI 写的代码是否合理。

---

## 一、当前状态与目标

### 已有基础
- 熟练使用 R Shiny 做全栈开发（~6600 行 app.R）
- 理解 PostgreSQL + Nginx + Docker 部署架构
- 已通过 STUDY_NOTES_FULLSTACK.md 梳理了 Vue + FastAPI 全链路接口调用规则
- 对 async/await、SSE、Nginx 路径重写、SPA 前端路由等概念有理论理解

### 核心短板
- 前端语言（HTML/CSS/JS/Vue）几乎零实战经验
- Python 后端（FastAPI/Pydantic/asyncpg）没有亲手写过
- "理论理解"和"能动手排查问题"之间的鸿沟

### 目标定位
**不做古法编程高手，做 AI 时代的有效驾驭者。**

| | 古法编程高手 | AI 时代的有效驾驭者 |
|---|---|---|
| 核心能力 | 从零写出正确代码 | 判断 AI 写的代码是否合理 |
| 对语言的掌握 | 语法烂熟于心 | 能读懂即可，不需要盲写 |
| 对架构的理解 | 会设计 | 知道什么改动会波及什么模块 |
| 知识面要求 | 精细深入 | 广泛但不必深入，关键路径要熟 |

### 关键认知
**AI 在代码中植入破坏、git push。你来读代码、调试、定位、修复。需要学 debug 工具就问，AI 只回答你问的。在这个反复折腾的过程中加深对整个框架机制的理解。**

页面卡顿时，不同位置发生的卡顿的"质感"是不一样的——这种甚至很难用语言描述的微妙差异，才是人类能够比 AI 更快确定问题的关键。

---

## 二、学习方式：以"破坏→观察→修复"为核心

### 基本原则

| 角色 | 职责 |
|------|------|
| **AI** | 在代码中植入 1 处破坏 → git push |
| **你** | 读代码、跑起来、观察症状、定位根因、亲手修复 |
| **AI** | 你提问时才回答（debug 工具用法、概念解释等），不主动给方向 |

**你不问，我不说。你需要什么工具就问什么工具，剩下的自己来。**

### 例外
- **初始项目搭建**：目录结构、nginx.conf、vite.config.ts 等配置文件由 AI 生成——这类东西的价值在理解规则不在记忆语法
- **破坏阶段**：AI 只做破坏和 push，不说谜底

### "破坏"的分级

破坏按排查难度分四档：

| 档位 | 特征 | 典型示例 |
|------|------|---------|
| 一档：立刻报错 | 浏览器/终端明确报错，症状=原因 | 关掉后端进程 → 502 |
| 二档：症状明确需推理 | 不出错但行为明显异常，需要一点推理 | 去掉 proxy_buffering off → 不逐字了 |
| 三档：不报错行为诡异 | 能跑但偶尔出错，或"感觉不对" | buffer 逻辑错误 → 概率性丢字符 |
| 四档：跨层联动 | 多个层面交互导致的微妙问题 | generator 中途抛异常 → 流中断但连接没关 |

---

## 三、学习项目：纯 QA Agent（骨架版）

### 为什么选这个

对比了三个候选方案：

| 方案 | 优点 | 缺点 |
|------|------|------|
| **纯 QA Agent** ✅ | 覆盖生产项目最脆弱的链环（SSE streaming），可逐步扩展 | 略过 CRUD 层的练习 |
| Todo/笔记 CRUD | 覆盖 REST 全套路 | 没有 streaming，不缺 CRUD 经验 |
| 审计日志查看器 | 真实数据，可接现有 DB | 读/查为主，复杂度在 SQL 而非 streaming |

**streaming 是全栈里最新、最脆弱、也最能体现"AI 时代需要人类判断力"的东西。CRUD 从 R Shiny 迁移到 FastAPI 主要是语法问题，优先级的差异。**

### 与技术栈的关系

```
练习项目用到的技术           生产项目对应的技术
─────────────────────       ─────────────────────
FastAPI + SSE               ← 完全一致
Vue 3 + fetch + ReadableStream ← 完全一致
Nginx 反向代理               ← 完全一致（去掉负载均衡）
LangGraph Agent（阶段 B）    ← 完全一致（阉割掉 pipeline + 数据库查询）
```

### 项目架构

```
浏览器 → localhost:80 (Nginx)
              │
              ├── /         → serve 静态文件目录 dist/
              │               try_files $uri /index.html （SPA 兜底）
              │
              └── /api/     → localhost:8000 (FastAPI)
```

**与生产环境的关系**：

| 层 | 生产环境 | 练习环境 | 差异 |
|----|---------|---------|------|
| Nginx 配置 | `nginx_agent.conf` | `nginx.conf` | 去掉负载均衡 upstream 和 auth 子请求，其余一致 |
| 静态文件 serve | agent-web 容器（也是 Nginx） | 本地 Nginx 直接 serve `dist/` | 无容器，逻辑一致 |
| `try_files` SPA 兜底 | `frontend/nginx-spa.conf` | `nginx.conf` | **完全一致** |
| `proxy_pass` 路径重写 | `location /agent-api/` → `proxy_pass http://agent-api:8000/api/` | `location /api/` → `proxy_pass http://127.0.0.1:8000/api/` | 只改了目标地址，重写规则一致 |
| `proxy_buffering off` | `nginx_agent.conf` | `nginx.conf` | **完全一致** |
| SSE 相关 headers | `Connection ''`, `proxy_read_timeout` | 同 | **完全一致** |

**核心原则：能复用生产结构的地方绝不做简化，避免制造盲区。**

唯一去掉的是 Docker 容器化——两个进程本地跑，因为容器不影响 Nginx 配置语法，练完阶段 B 后可在阶段 C 加上。

**启动流程（与生产一致）**：

```
用户浏览器输入 http://localhost
    │
    ▼
Nginx location / 匹配
    │  serve dist/index.html（近乎空白的 SPA 入口）
    ▼
浏览器加载 dist/assets/app.xxx.js
    │  main.ts 点火 → createApp(App) → app.mount('#app')
    ▼
App.vue onMounted() 触发
    │  loadSessions() → fetch('/api/chat/sessions')
    │  → Nginx location /api/ → proxy_pass → FastAPI
    ▼
页面渲染完成，用户看到聊天界面
```

**两个进程，一份 nginx.conf，没有 Vite dev server，没有 Docker。**

---

## 步骤 0：建立"正常行为"的基线（破坏前必须先做）

在 AI 搞任何破坏之前，先把项目跑起来，花 1-2 小时主动观察它正确的样子。

**为什么这一步不能跳过**：没有基线就没有对照。破坏之后你分不清"这是 bug"还是"本来就这样"。

**操作方式**：AI 搭好项目骨架后，把项目跑通。然后逐层观察正常状态，记录下你看到的。

### 观察清单

| 观察点 | 怎么看 | 记录什么 |
|--------|-------|---------|
| 首次加载页面 | 浏览器打开 `http://localhost` | 页面是否正常渲染？Network 面板里看到几个请求？index.html 和 app.js 的大小？ |
| SSE 逐字输出 | 发一条消息，看 AI 回复 | 逐字打出的节奏是什么样的？一个字一个字还是几个字几个字？Network 面板 EventStream 标签页里 `data:` 行怎么出现的？ |
| Nginx access log | `tail -f /var/log/nginx/access.log` | 发一条消息时产生了哪些请求？`/api/chat` 是 POST，状态码多少？ |
| Nginx error log | `tail -f /var/log/nginx/error.log` | 正常情况下应该为空或只有 info。记下"干净的状态"——以后这里出现红色就是异常 |
| FastAPI 终端输出 | 启动 uvicorn 的终端窗口 | 每次请求时输出什么？有没有请求方法、路径、状态码？ |
| `nginx -t` | 在终端运行 | 正常输出是什么？确认配置文件路径 |
| 前端 Console | 浏览器 F12 → Console | 有没有报错或 warning？正常应该干净 |

---

## Debug 工具箱：全栈逐层速查

以下是你在这个练习项目中会反复用到的调试命令和工具。不需要一次记住全部——每次需要时回来查，用得多了自然记住。

### 1. 浏览器 DevTools（F12）

**最核心的调试入口。90% 的问题从这里开始。**

| 面板 | 看什么 | 典型场景 |
|------|--------|---------|
| **Network** | 所有 HTTP 请求的完整信息 | "请求发出去了吗？" "后端返回了什么？" "哪个请求耗时最长？" |
| Network → 点击某个请求 → **Headers** | 请求头、响应头、状态码 | 确认 `Content-Type: text/event-stream`（SSE）、`X-User` 有没有透传 |
| Network → 点击某个请求 → **Preview / Response** | 响应内容的格式化/原始视图 | 看后端返回的 JSON 结构是否正确 |
| Network → 点击 SSE 请求 → **EventStream** | SSE 事件的逐条列表 | **这是看"逐字输出是否正常"的最直接入口**——每收到一个 `data:` 行就是一条 |
| Network → 点击某个请求 → **Timing** | 请求各阶段耗时分解 | "是 DNS 慢？还是等服务器响应慢？" |
| **Console** | JS 报错、`console.log` 输出 | 前端逻辑错误、未捕获的异常 |
| **Elements** | 当前页面的 DOM 树 | 检查 Vue 渲染出来的 HTML 结构是否符合预期 |
| **Application** | localStorage、Cookie、IndexedDB | 检查前端存储的状态 |

### 2. Nginx

| 命令 / 文件 | 作用 | 典型场景 |
|-------------|------|---------|
| `nginx -t` | 测试配置文件语法是否正确 | **改完 nginx.conf 第一步就跑这个**，语法报错会有具体行号 |
| `nginx -s reload` | 热重载配置（不中断服务） | 改完配置后生效 |
| `tail -f /var/log/nginx/access.log` | 实时看访问日志 | 确认请求是否到达了 Nginx、匹配了哪个 location、状态码是多少 |
| `tail -f /var/log/nginx/error.log` | 实时看错误日志 | upstream 连不上、权限问题、配置错误——全在这里 |
| `tail -100 /var/log/nginx/error.log` | 看最近 100 行错误 | 快速扫一眼有没有异常 |
| `ps aux \| grep nginx` | 看 Nginx 是否在运行 | "Nginx 到底起了没？" |

**access log 格式示例**（默认 combined 格式）：
```
127.0.0.1 - - [22/May/2026:10:30:45 +0800] "POST /api/chat HTTP/1.1" 200 0 "-" "Mozilla/5.0..."
                                              │            │
                                              路径         状态码（200=成功，502=后端挂了）
```

### 3. FastAPI / Uvicorn 后端

| 看什么 | 在哪看 | 典型场景 |
|--------|-------|---------|
| uvicorn 终端输出 | 启动 uvicorn 的那个终端 | 每次请求自动打印：`POST /api/chat 200`。**如果请求发出去了但这里没动静，说明请求没到** |
| Python traceback | 同上，终端里直接显示 | FastAPI 报错时，traceback 会打印在这里。**从最下面开始读**，最后一行是实际的异常 |
| `print()` / `logging` | 同上 | 在代码里插 `print(f"DEBUG: {variable=}")` 是最快的临时调试方式 |
| `curl` 直接打后端 | 终端运行 curl 命令（见下方） | 绕过 Nginx 直接请求 FastAPI，判断"问题在 Nginx 还是在后端" |

**curl 调试命令**：
```bash
# 绕过 Nginx，直接打 FastAPI 的 8000 端口
curl -X POST http://localhost:8000/api/chat \
  -H "Content-Type: application/json" \
  -d '{"message": "你好"}'

# 带 -v 看完整请求/响应头
curl -v -X POST http://localhost:8000/api/chat \
  -H "Content-Type: application/json" \
  -d '{"message": "你好"}'

# 通过 Nginx 打（对比行为差异）
curl -X POST http://localhost/api/chat \
  -H "Content-Type: application/json" \
  -d '{"message": "你好"}'
```

### 4. 进程管理

| 命令 | 作用 |
|------|------|
| `ps aux \| grep uvicorn` | FastAPI 进程在不在 |
| `ps aux \| grep nginx` | Nginx 进程在不在 |
| `lsof -i :80` | 谁在监听 80 端口 |
| `lsof -i :8000` | 谁在监听 8000 端口 |

### 5. Git 差分

| 命令 | 作用 | 典型场景 |
|------|------|---------|
| `git diff` | 查看未 staged 的改动 | 最常用——看 AI 改了哪些文件 |
| `git diff --staged` | 查看已 staged 的改动 | AI commit 之前先看一眼 |
| `git log --oneline -5` | 最近 5 个 commit | 确认 AI push 了哪个 commit |
| `git show HEAD` | 查看最新 commit 的完整 diff | **这是你每轮破坏练习的起点**——看 AI 上一次 commit 改了什么 |

### 6. 排查流程：请求到哪了？

问题发生时，按这个顺序逐层排查：

```
1. 浏览器 Network 面板 → 请求发出去了吗？状态码是多少？
   ├── 请求没发出去 → 前端 JS 问题（Console 看报错）
   ├── 状态码 502 → Nginx 连不上 FastAPI（FastAPI 进程是否在？8000 端口是否在监听？）
   ├── 状态码 404 → Nginx location 没匹配到（检查 nginx.conf 的 location 配置）
   ├── 状态码 200 但数据不对 → 问题在 FastAPI 逻辑或 SSE generator
   └── 状态码 200 但"感觉不对"（节奏异常）→ Nginx proxy_buffering 或 ReadableStream 解析

2. Nginx access log → 请求到达 Nginx 了吗？匹配的路径是什么？
3. Nginx error log → 有没有 upstream 连接失败？
4. uvicorn 终端输出 → 请求到达 FastAPI 了吗？有没有 traceback？
5. curl 直接打 FastAPI → 绕过 Nginx，确认问题在哪一层
```

---

## 四、阶段性学习计划

### 阶段 A：SSE Echo（预计 1-2 天）

**目标**：把"前端发消息 → 后端 yield → Nginx 透传 → 前端逐字收到"这根管子完全吃透。

**不涉及**：LLM、LangGraph、数据库。

**实现**：
- FastAPI：收到 POST 消息后，用 `asyncio.sleep` 模拟延迟，逐字 yield 回去
- Vue：输入框 + 发送按钮 + 消息列表 + ReadableStream 读取 SSE。`npm run build` 产出 `dist/` 由 Nginx 直接 serve
- Nginx：一份 `nginx.conf`，包含 `location /`（SPA 静态文件 + `try_files` 兜底）和 `location /api/`（反向代理 + `proxy_buffering off` + SSE 相关配置），与生产 `nginx_agent.conf` 结构一致

**代码量**：后端 ~40 行 + 前端 ~60 行 + nginx.conf ~25 行

**破坏点练习**：AI 每轮在代码中植入 1 处破坏并 push。破坏按难度递增，覆盖 Nginx 配置、FastAPI 端点行为、SSE 生成器逻辑、前端 ReadableStream 解析、竞态条件、跨层异常传播等。你不提前知道被改了什么。

### 阶段 B：接入 LangGraph（预计 2-3 天）

**目标**：把阶段 A 的模拟 yield 换成真实 LLM streaming，引入 LangGraph 的最简图结构。

**实现**：
- LangGraph 最小图：`chat` 节点 + `START` → `chat` → `END`
- 去掉 router、tool calling、RAG——纯 LLM 对话
- 前端无需改动（接口保持 SSE 兼容）

**破坏点练习**：引入 LangGraph 后的新破坏维度——LLM API 异常传播、graph 状态机错误、async 超时处理、API 版本差异等。规则同阶段 A：AI 破坏并 push，你定位修复。

### 阶段 C：加入更多真实复杂度（可选，按需）

| 扩展方向 | 练什么 | 预计时间 |
|---------|--------|---------|
| 加入对话历史（SQLite 单表） | 参数化查询、数据库连接池、前后端状态同步 | 1-2 天 |
| 加入简单的工具调用（一个 tool） | LangGraph tool calling 的最小实现 | 1-2 天 |
| 加入用户认证（简化版 X-User header） | Nginx auth 透传 + FastAPI Depends | 1 天 |
| Docker 化（Dockerfile + compose） | 镜像构建、容器间网络 | 1 天 |

### 阶段 D：回到生产项目（持续）

当你在练习项目中积累了一定的"破坏→修复"经验后，回到 IVD Agent 生产项目：

1. **用练习项目里学到的手感去读生产代码**——Nginx 配置、chat.ts 的 SSE 解析、chat.py 的 event_generator
2. **在生产环境里刻意做小改动观察行为变化**——保守的、可回滚的改动
3. **每次 AI 在生产项目里提交改动，对照架构图审查耦合点**

---

## 五、前端语言的最低必要知识

不需要成为 CSS/HTML 专家。日常写 Vue 时只需要：

### 必须能盲写（~20%）
- HTML：`div`、`span`、`input`、`button`、`table`、`form`
- CSS：`display: flex`、`gap`、`padding/margin`、`width/height`、`color/background`、`font-size`
- JS：`const/let`、`if/for/function`、`async/await`、`fetch`、模板字符串、数组方法（`map/filter/find/push`）

### 知道有这个东西就行（~80%）
- CSS Grid、`position: sticky`、`overflow`、伪类 `:hover`
- 事件冒泡、`localStorage`、`Date` 对象、解构赋值
- Element Plus 组件库封装了大部分复杂 UI

### 核心心态
你现在写 R Shiny 时也不是每个 CSS 属性都背下来的，但照样能干活。前端同理——不需要变成 CSS 专家才开始写代码，边写边查才是正常流程。

---

## 六、与生产项目的对照表

练习中每学一个概念，对应到生产项目的具体位置：

| 练习项目概念 | 生产项目对应文件/位置 |
|-------------|-------------------|
| FastAPI `@router.post("/chat")` | `app/api/chat.py:63` |
| `EventSourceResponse(event_generator())` | `app/api/chat.py:168` |
| `yield {"data": "..."}` | `app/api/chat.py:119-172` |
| Nginx `location /api/` + `proxy_pass` | `nginx_agent.conf` |
| Nginx `proxy_buffering off` | `nginx_agent.conf` |
| Nginx `try_files $uri /index.html` | `frontend/nginx-spa.conf` |
| 前端 `fetch` + `ReadableStream` | `frontend/src/api/chat.ts:36-124` |
| 前端 `API_BASE` 环境切换 | `frontend/src/api/base.ts` |
| `import.meta.env.PROD` | `frontend/src/api/base.ts` |
| LangGraph `astream_events(version="v2")` | `app/api/chat.py` |
| `on_chat_model_stream` 事件过滤 | `app/api/chat.py` |

---

## 七、节奏建议

- **每天 1-2 小时**，不追求进度，只追求"今天破坏的东西我完全理解"
- **每周一个阶段内的破坏点完成 3-5 个**
- **周末可以做阶段性整合**（比如把阶段 A 所有破坏点过一遍）
- **阶段 A 预计 1-2 周**完成全部 14 个破坏点
- **阶段 B 预计 1-2 周**完成全部 5 个破坏点
- **全部阶段 A+B 预计 1 个月内**建立基本的全栈"嗅觉"
