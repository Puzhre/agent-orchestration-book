# 第十一章 知识积累与进化：怎么越用越好

## 11.1 为什么知识积累很重要

AI Agent每次启动都是"白纸"——它不知道上次犯了什么错，不知道哪些方案行不通，不知道项目的决策历史。没有知识积累，编排器永远在做重复的事，犯重复的错。

五大项目中，有三种不同的知识积累范式：

## 11.2 范式一：自然语言经验文档（Tmux-Orchestrator）

### LEARNINGS.md

Tmux-Orchestrator用一个Markdown文件持续积累经验教训：

```markdown
## Learnings

### Web搜索超时
如果Agent在一个问题上卡了10分钟以上，建议它使用Web搜索。
很多时候卡住是因为缺少外部信息，而不是逻辑错误。

### 3次失败即升级
如果一个Agent连续3次尝试同一任务失败，立即升级。
不要让Agent陷入循环。

### 验证实际错误
PM必须问"具体错误信息是什么？"，而不是让Engineer猜测问题。
防止过度工程化——Engineer可能"修复"一个不存在的问题。

### Claude Plan Mode
复杂实现前先进入规划模式（Shift+Tab+Tab）。
强制先想后做，避免"边想边写"导致的返工。
```

**优点**：
- 极简：一个Markdown文件
- 人类和Agent都能读
- 积累自然，不需要特殊机制

**缺点**：
- 无结构：经验是自由文本，难以程序化利用
- 无分类：好的经验和坏的经验混在一起
- 无自动化：需要人（或Agent主动）写入

## 11.3 范式二：结构化知识库（Overstory）

### Mulch知识库

Overstory的Mulch是一个结构化的知识积累系统，专门用于存储和复用项目知识：

```typescript
// 知识库客户端
mulch.client.query({
  domain: "conflict-patterns",     // 冲突模式
  query: "src/auth merge conflicts",
  format: "json"
});
```

**Mulch存储的知识类型**：

1. **冲突模式**：哪些文件经常冲突、哪些合并策略历史上失败率高
2. **失败模式**：哪些类型的任务容易失败、失败原因是什么
3. **项目知识**：代码库结构、依赖关系、常见陷阱

**在合并中的应用**：

```typescript
// 合并时查询历史冲突模式
const patterns = await mulch.query("conflict-patterns", filePath);
// 跳过历史上失败率高的策略
// 选择历史成功率高的策略
```

**在Overlay注入中的应用**：

```typescript
// 将项目特定知识注入到Agent的指令中
const projectKnowledge = await mulch.query("project", projectName);
overlay.render(baseDefinition, projectKnowledge, taskAssignment);
```

**优点**：
- 结构化：可程序化查询和利用
- 持久化：跨会话、跨Agent复用
- 形成正反馈循环：越用越准

**缺点**：
- 需要额外基础设施（Mulch服务）
- 知识质量依赖输入质量
- 冷启动问题：新项目没有历史数据

## 11.4 范式三：语义记忆（agency-agents-zh）

### MCP记忆服务器

agency-agents-zh集成了MCP(Model Context Protocol)记忆服务器，实现语义级知识存储和检索：

```
三个核心操作：

1. remember(内容, 标签)
   - 存储决策、交付物和上下文快照
   - 标签格式：项目名 + 智能体名 + 交付物类型
   - 例如：remember("选择了JWT而非Session", ["auth", "decision"])

2. recall(查询)
   - 按关键词/标签/语义相似度搜索记忆
   - 后续智能体用recall获取前序智能体的产出
   - 例如：recall("auth decision")

3. rollback(检查点)
   - 回滚到已知良好状态
   - QA失败时，智能体可recall之前的反馈 + rollback到检查点
   - 无需人工追踪版本变更
```

**记忆的生命周期**：

```
智能体A完成工作
  → remember(交付物+决策+上下文, 标签)
  → 打标签：[项目名, 智能体名, 交付物类型]

智能体B启动
  → recall(按标签搜索)
  → 获取智能体A的产出作为输入

QA失败
  → recall(之前的反馈)
  → rollback(到检查点)
  → 基于反馈重新工作
```

**优点**：
- 语义搜索：不只是关键词匹配，能理解意图
- 自动上下文传递：消除手动copy-paste
- rollback：独特的回滚能力

**缺点**：
- 依赖外部MCP服务器
- 语义搜索的准确性取决于嵌入模型
- 记忆可能过期（项目决策已经改变但旧记忆还在）

## 11.5 三种范式的对比

| 维度 | 经验文档 | 结构化知识库 | 语义记忆 |
|------|---------|------------|---------|
| **存储格式** | 自由文本Markdown | 结构化JSON/数据库 | 语义嵌入+元数据 |
| **查询方式** | 人类阅读 | 程序化查询 | 语义搜索 |
| **写入方式** | 手动/Agent主动 | 自动采集 | Agent主动remember |
| **跨会话** | 是 | 是 | 是 |
| **跨项目** | 困难 | 是 | 是 |
| **可操作性** | 低（只读） | 高（驱动决策） | 中（提供上下文） |
| **实现成本** | 极低 | 中 | 高 |
| **冷启动** | 无 | 有 | 有 |

## 11.6 Overlay注入：知识到Agent的桥梁

Overstory的Overlay注入机制将知识"嵌入"到Agent的指令中，这是知识积累的"最后一公里"——有了知识还得让Agent知道。

### 三层叠加

```
Layer 1（角色特异 HOW）：基础Agent定义(.md文件)
  描述角色的行为规范、技术偏好

Layer 2（部署特异 WHAT KIND）：Canopy profile
  项目/部署特定的上下文、代码规范、技术栈

Layer 3（任务特异 WHAT）：具体任务分配
  文件范围、质量门禁、特定约束
```

```typescript
// 渲染过程
function renderOverlay(base: AgentDefinition, profile: ProjectProfile, task: TaskAssignment): string {
  return `
# ${base.name}

## 你的角色规范
${base.instructions}

## 项目上下文
${profile.codebaseStructure}
${profile.conventions}
${profile.knownPitfalls}  // ← 来自Mulch知识库

## 当前任务
${task.description}
${task.fileScope}
${task.qualityGates}
  `;
}
```

**关键洞察**：Overlay注入是知识积累的"消费端"。知识存储（Mulch/LEARNINGS.md/MCP）是"生产端"。只存储不消费，知识积累就没有价值。Overlay机制确保了每个新启动的Agent都携带了最新的项目知识。

## 11.7 FEATURES.md：隐性的知识积累

FEATURES.md看似只是"特性追踪"，实际上它是一种隐性的知识积累——记录了"项目已经实现了什么"：

```markdown
# FEATURES.md

## 已实现
- [x] 用户认证 (JWT)
- [x] API端点 /api/v1/auth
- [x] 数据库迁移脚本

## 进行中
- [ ] 用户资料编辑页面
```

**防止重复开发**：架构师在派任务前检查FEATURES.md，避免让执行者重复实现已有功能。这是一种最简单的知识复用。

## 11.8 知识积累的设计原则

### 原则一：存储和消费必须闭环

知识只在被使用时才有价值。LEARNINGS.md虽然简单，但如果不被注入到Agent的prompt中，就是死知识。Overlay注入机制确保了知识消费。

### 原则二：结构化优于自由文本

自然语言经验文档人类可读，但Agent难以程序化利用。结构化知识库可以被合并策略、任务分配、风险评估等模块直接消费。

### 原则三：失败比成功更有价值

知道"什么行不通"比"什么行得通"更重要。Mulch的冲突模式和失败记录、快速崩溃时间戳、agency-agents-zh的QA失败反馈——这些都是"从失败中学习"。

### 原则四：知识有保质期

项目决策会变、代码库会演进、依赖会更新。过期的知识比没有知识更危险。MCP记忆的语义搜索可以缓解但无法完全解决这个问题。需要定期清理或标注过期。

### 原则五：最低成本起步

不需要一开始就上Mulch或MCP。从LEARNINGS.md + Overlay注入开始，当经验积累到手动管理不过来时再升级到结构化知识库。
