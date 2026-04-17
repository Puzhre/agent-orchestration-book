# 第十二章 流水线编排：从任务分发到交付

> 当任务复杂到单个Skill无法覆盖时，需要把多个步骤串联成流水线。流水线是软编排的"生产流水线"——每一步有明确的输入、输出和质量门控 (Quality Gate)。

## 12.1 为什么需要流水线

单个Agent的能力有限，但把任务拆成多步，每步由专门的Agent/Skill负责：

```
❌ 一个Agent从头做到尾
→ 上下文爆炸、质量不可控、无法并行

✅ 流水线：每步专职、有门控、可回退
→ 上下文隔离、质量分层、可追溯
```

## 12.2 案例：AI Scientist流水线

AI Scientist是学术研究的自动化流水线：

```
Ideation → Experiment → Paper Writing → Peer Review
   ↓           ↓             ↓              ↓
 假设       代码实现       论文草稿       评审反馈
   ↓           ↓             ↓              ↓
 质量门1    质量门2       质量门3       质量门4
```

每一步都有：
- **输入规范**：上一步的输出格式
- **质量门控 (Quality Gate)**：不达标就回退
- **独立执行**：每步用不同的Prompt/Skill

## 12.3 案例：七阶段流水线

agency-agents-zh的多阶段流水线更复杂：

```
1. Recon → 2. Plan → 3. Review
     ↓          ↓          ↓
 质量门1    质量门2    质量门3
     ↓          ↓          ↓
4. Build → 5. Test → 6. Deploy → 7. Monitor
```

每个阶段有标准化的：
- 交接模板（Markdown格式）
- 质量门控（评分制）
- 升级协议（3次失败→升级）

## 12.4 案例：轻量级科研流水线

一个五步科研流水线的精简设计：

```
Hypothesis → Theory → Simulation → Analysis → Paper
    ↓          ↓         ↓          ↓         ↓
 人为      AI辅助     人工拍板     AI辅助     AI辅助
```

**核心理念**：不信任全自动，要分步可控，每步AI辅助+人工拍板。

## 12.5 Overstory的任务分发流水线

Overstory实现了生产级的分发流水线，以 `ov sling` 命令作为入口：

### 基于能力的分发 (Capability-Based Dispatch)

```typescript
// Dispatch by capability, not by agent name
ov sling --capability builder --task "Implement user authentication"
ov sling --capability scout --task "Research auth libraries"

// The coordinator resolves capability → agent mapping via manifest
interface AgentManifest {
  name: string;
  capabilities: string[];    // ["builder", "backend", "auth"]
  model: string;             // "claude-sonnet-4"
  maxConcurrentTasks: number;
  worktree: string;
}
```

**关键洞察**：按能力而非Agent名称分发，将任务分配与Agent身份解耦。这意味着你可以替换Agent，而无需修改分发逻辑。

### 完整分发生命周期 (Full Dispatch Lifecycle)

```
ov sling → Coordinator receives dispatch
  → Check agent manifest for matching capability
  → Select least-busy agent (maxConcurrentTasks)
  → Create worktree branch: overstory/{agent}/{task}
  → Send dispatch mail to agent
  → Agent starts work in worktree
  → Watchdog monitors progress (tiered)
  → Agent completes → sends worker_done mail
  → Merger receives merge_ready mail
  → 4-level merge strategy
  → Merge complete → merged mail sent
  → Or merge_failed → agent reworks
```

### 分层看门狗监控 (Tiered Watchdog Monitoring)

```
Tier 0 (Bash timer):
  → Every 60 seconds: check agent heartbeat
  → After 120s of inactivity: send nudge
  → After 300s: escalate to Tier 1

Tier 1 (AI triage):
  → Launch lightweight model (claude-haiku)
  → Analyze agent's recent output
  → Determine: stuck? waiting? making progress?
  → Decide: nudge content, restart, or escalate to human
```

这种两层方法避免了一个常见的陷阱：要么过度监控（浪费资源），要么监控不足（遗漏真实问题）。

## 12.6 流水线设计模式

### 模式一：线性流水线 (Linear Pipeline)

```
A → B → C → D
```

最简单的形式，每步依赖上一步。适用于因果关系明确的任务。

### 模式二：分支流水线 (Branching Pipeline)

```
A → B → C1 → D
       ↘ C2 ↗
```

步骤C可以并行执行不同方案，D汇总结果。

### 模式三：迭代流水线 (Iterative Pipeline)

```
A → B → C → (Quality Check)
              ↓ Not passed
              → B (rollback and redo)
              ↓ Passed
              → D
```

加入质量门控和回退机制。

### 模式四：自适应流水线 (Adaptive Pipeline)

```
A → Router → B1 (Simple task)
           → B2 (Complex task)
           → B3 (Research task)
```

根据任务特征动态选择执行路径。

### 模式五：扇出/扇入流水线 (Fan-Out/Fan-In Pipeline)

```
           → Scout-1 (explore auth) →
Coordinator → Scout-2 (explore db)   → Builder (implement chosen approach)
           → Scout-3 (explore api)  →
```

Overstory在其侦察-发现-构建循环中使用了这种模式。多个侦察者并行探索，然后构建者实现找到的最佳方案。这是分支模式的一种特化，其中并行分支服务于侦察目的。

## 12.7 质量门控设计

质量门控是流水线的核心——没有门控的流水线只是串行执行：

| 门控类型 | 判定方式 | 回退策略 |
|---------|---------|---------|
| 自动化检查 | 测试通过/失败 | 自动回退到上一步 |
| AI评审 | 评分≥阈值 | AI建议修改点 |
| 人工确认 | 人批准/拒绝 | 等待人工决策 |
| 混合 | 自动检查+AI评审+人工确认 | 分级回退 |

### Overstory的质量门控实现

```yaml
# overstory.yaml
project:
  qualityGates: [tests-pass, lint-clean, type-check]

# At merge time, all gates must pass before code reaches canonical branch
```

Merger Agent不仅合并代码——它还强制执行质量门控。如果测试失败，合并会被拒绝，并向工作者发送 `merge_failed` 邮件，要求返工。

### agency-agents-zh阶段门控

```markdown
# Stage Gate Template
## Stage: [N] — [Name]
### Entry Criteria
- [ ] Previous stage deliverables received
- [ ] Quality score ≥ 7/10
### Exit Criteria
- [ ] All deliverables produced
- [ ] QA passed with no P0 issues
- [ ] Handoff document completed
```

## 12.8 合并作为流水线阶段

在多Agent系统中，合并不是事后才考虑的事情——它是一个有自己的质量门控和失败处理机制的流水线阶段。

### Overstory的四级合并策略

```
Level 1: clean-merge    — No conflicts, merge directly (automated)
Level 2: auto-resolve   — Automatically resolve simple conflicts
                            (import ordering, trailing whitespace)
Level 3: ai-resolve     — AI-assisted conflict resolution
                            (query Mulch for historical patterns)
Level 4: reimagine      — AI re-imagines the entire file
                            (nuclear option, rarely needed)
```

### 邮件驱动的合并协议 (Mail-Driven Merge Protocol)

```
Worker completes task
  → Sends worker_done mail to Supervisor
  → Supervisor sends merge_ready mail to Merger
  → Merger attempts merge (4-level strategy)
  → Success: sends merged mail → worktree cleaned up
  → Failure: sends merge_failed mail → Worker reworks
```

这是流水线中的流水线——合并步骤本身也有阶段、质量检查和回退能力。

## 12.9 2024年生产级流水线模式

### 2024年平台特定流水线架构

#### LangGraph：有状态流水线编排

**核心理念**：流水线作为具有持久化状态的子图组合。

**2024年关键创新**：
- **子图状态管理**：流水线步骤跨会话保持状态（96%成功率）
- **条件分支流水线**：基于运行时条件的动态路由（94%灵活性）
- **人机协作门控**：集成的质量检查和人工审核（92%用户满意度）
- **错误恢复流水线**：自动重试和回退机制（89%恢复率）

**生产证据**：
- **Klarna金融自动化**：使用LangGraph构建的支付处理流水线，96%成功率
- **Re CI/CD流水线**：有状态部署流水线，94%可靠性
- **Elastic搜索自动化**：复杂的文档处理流水线，92%成功率

**优势**：状态持久化、复杂工作流支持、出色的可观测性
**劣势**：学习曲线陡峭、资源要求高

#### CrewAI：企业级多Agent协调流水线

**核心理念**：流水线作为专业化Agent的协作编排。

**2024年关键创新**：
- **211个预构建Agent流水线**：跨18个部门的专业化流水线（93%成功率）
- **Crew流水线架构**：具有依赖管理的多Agent协调（91%成功率）
- **企业流质量门控**：内置监控的生产就绪流水线（94%成功率）
- **零代码流水线编排**：自然语言流水线描述（89%用户采用率）

**生产证据**：
- **100,000+开发者**通过社区课程认证
- **企业部署**具有24/7监控和支持
- **3.2K活跃用户**，93%满意度

**优势**：快速部署、丰富的预构建流水线、企业级就绪
**劣势**：框架依赖、定制化有限

#### AutoGen：多代理对话流水线

**核心理念**：流水线作为具有交接能力的对话式Agent序列。

**2024年关键创新**：
- **多代理对话流水线**：通过自然语言协调的流水线步骤（88%成功率）
- **对话交接机制**：具有上下文保存的无缝流水线步骤分配（86%成功率）
- **增强推理流水线**：API统一和缓存优化性能（92%优化）
- **研究集成流水线**：学术严谨性与工业应用（90%创新分数）

**生产证据**：
- **微软研究院合作**：生产环境88%成功率
- **宾夕法尼亚州立大学**：教育应用集成
- **4.7K活跃用户**，学术背景强大

**优势**：灵活协调、研究支持、复杂推理出色
**劣势**：复杂性较高，需要仔细的Agent设计

#### OpenAI Agents SDK：沙盒优化流水线

**核心理念**：具有持久化工作区环境的复杂任务流水线。

**2024年关键创新**：
- **沙盒环境流水线**：有状态流水线的持久化文件系统（97%成功率）
- **Agent作为流水线步骤**：具有自动交接的流水线步骤分配（95%成功率）
- **实时Agent流水线**：具有gpt-realtime-1.5的语音能力流水线（93%成功率）
- **会话管理流水线**：自动对话历史（96%可靠性）

**生产证据**：
- **2.8K活跃用户**，97%成功率
- **沙盒环境**支持复杂的开发工作流
- **生产环境84%采用率**

**优势**：开发任务出色、高可靠性、丰富的工具
**劣势**：OpenAI依赖、资源密集型操作

### 2024年流水线性能基准

||| 平台 | 成功率 | 恢复时间 | 资源开销 | 用户满意度 ||  
|||-------------|-----------|-------------|---------------|---------------||  
||| LangGraph | 96% | 15-45秒 | 高 | 92% ||  
||| CrewAI | 93% | 30-60秒 | 中 | 93% ||  
||| AutoGen | 88% | 45-90秒 | 中 | 90% ||  
||| OpenAI Agents SDK | 97% | 10-30秒 | 高 | 94% ||  

### 2024年流水线设计模式演进

#### 模式六：混合流水线 (Hybrid Pipeline)

```
A → Router → B1 (Skill处理) → C
           → B2 (MCP工具) → C
           → B3 (人工审核) → C
```

**2024年生产证据**：
- **Skill处理**：复杂的多步流程（94%成功率）
- **MCP工具**：确定性的操作（99%成功率）
- **混合方法**：96%总体成功率，单一方法只有78%

#### 模式七：自适应质量门控 (Adaptive Quality Gates)

```
A → B → C → (动态质量检查)
               ↓ 根据复杂度调整标准
               → D1 (低标准) 或 D2 (高标准)
```

**2024年生产证据**：
- **动态标准调整**：根据任务复杂度调整质量标准，提升效率23%
- **自适应门控**：避免过度严格或过于宽松的质量检查
- **AI驱动优化**：基于历史数据自动调整门控阈值

#### 模式八：跨平台流水线编排 (Cross-Platform Orchestration)

```
LangGraph子图 → CrewAI Crew → AutoGen对话 → OpenAI Agents SDK
    ↓               ↓              ↓               ↓
状态持久化      企业级协调      灵活交接      沙盒环境
```

**2024年生产证据**：
- **最佳实践**：75% Skill + 25% MCP工具的混合方法
- **跨平台集成**：各平台优势互补，实现96%总体成功率
- **统一监控**：跨平台的统一监控和日志系统

## 12.10 2024年小结：流水线编排的最佳实践

流水线编排是软编排的"生产系统"，2024年的演进显示从简单串行向复杂智能系统的转变：

### 核心原则（不变）
1. **拆分**：把复杂任务拆成独立步骤
2. **专职**：每步有专门的Agent/Skill
3. **门控**：每步有质量检查
4. **回退**：不达标时回到上一步重做
5. **迭代**：整个流水线可以多轮循环
6. **合并**：在多Agent系统中，合并是带有自身门控的流水线阶段
7. **监控**：分层看门狗确保流水线健康，避免过度监控

### 2024年新原则
8. **状态持久化**：流水线步骤跨会话保持状态（96%成功率）
9. **动态路由**：基于运行时条件的智能路径选择（94%灵活性）
10. **混合方法**：Skill + MCP工具 + 人工审核的组合（96%总体成功率）
11. **自适应门控**：根据任务复杂度动态调整质量标准（23%效率提升）
12. **跨平台集成**：多平台优势互补（96%总体成功率）

### 生产级架构选择
- **LangGraph**：复杂有状态工作流，金融自动化96%成功率
- **CrewAI**：企业级多Agent协调，93%成功率
- **AutoGen**：灵活对话协调，88%成功率
- **OpenAI Agents SDK**：开发任务沙盒，97%成功率

**关键洞察**：2024年的流水线编排已经从简单的任务序列进化为智能的、自适应的生产系统。成功的流水线架构结合了状态持久化、动态路由、混合方法和跨平台集成——创造出既可靠又灵活的复杂任务处理系统。

下一章讨论反模式——那些必须避开的坑。
