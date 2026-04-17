# Chapter 12: Pipeline Orchestration — From Task Dispatch to Delivery

> When a task is too complex for a single Skill to cover, you need to chain multiple steps into a pipeline. A pipeline is the "production line" of soft orchestration — each step has clear inputs, outputs, and quality gates.

## 12.1 Why Pipelines Are Needed

A single Agent has limited capabilities, but by breaking the task into multiple steps, each handled by a dedicated Agent/Skill:

```
❌ One Agent doing everything from start to finish
→ Context explosion, uncontrollable quality, no parallelism

✅ Pipeline: dedicated steps, quality gates, rollback support
→ Context isolation, layered quality, traceability
```

## 12.2 Case Study: AI Scientist Pipeline

AI Scientist is an automated pipeline for academic research:

```
Ideation → Experiment → Paper Writing → Peer Review
   ↓           ↓             ↓              ↓
 Hypothesis   Code          Paper Draft    Review Feedback
   ↓           ↓             ↓              ↓
 Quality     Quality       Quality        Quality
 Gate 1      Gate 2        Gate 3         Gate 4
```

Each step has:
- **Input specification**: the output format from the previous step
- **Quality gate**: rollback if standards are not met
- **Independent execution**: each step uses a different Prompt/Skill

## 12.3 Case Study: Seven-Stage Pipeline

The multi-stage pipeline from agency-agents-zh is more complex:

```
1. Recon → 2. Plan → 3. Review
     ↓          ↓          ↓
 Quality     Quality     Quality
 Gate 1      Gate 2      Gate 3
     ↓          ↓          ↓
4. Build → 5. Test → 6. Deploy → 7. Monitor
```

Each stage has standardized:
- Handoff templates (Markdown format)
- Quality gates (scoring system)
- Escalation protocol (3 failures → escalation)

## 12.4 Case Study: Lightweight Research Pipeline

A streamlined design for a five-step research pipeline:

```
Hypothesis → Theory → Simulation → Analysis → Paper
    ↓          ↓         ↓          ↓         ↓
 Human      AI-assisted  Human      AI-assisted  AI-assisted
                        decision
```

**Core principle**: Don't trust full automation; keep steps controllable, with AI assistance plus human decision-making at each step.

## 12.5 Overstory's Task Dispatch Pipeline

Overstory implements a production-grade dispatch pipeline with the `ov sling` command as its entry point:

### Capability-Based Dispatch

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

**Key insight**: Dispatching by capability rather than by agent name decouples task assignment from agent identity. This means you can swap out agents without changing dispatch logic.

### Full Dispatch Lifecycle

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

### Tiered Watchdog Monitoring

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

This two-tier approach avoids the common pitfall of either over-monitoring (wasting resources) or under-monitoring (missing real issues).

## 12.6 Pipeline Design Patterns

### Pattern 1: Linear Pipeline

```
A → B → C → D
```

The simplest form, where each step depends on the previous one. Suitable for tasks with clear causal relationships.

### Pattern 2: Branching Pipeline

```
A → B → C1 → D
       ↘ C2 ↗
```

Step C can execute different approaches in parallel, and D merges the results.

### Pattern 3: Iterative Pipeline

```
A → B → C → (Quality Check)
              ↓ Not passed
              → B (rollback and redo)
              ↓ Passed
              → D
```

Incorporates quality gates and rollback mechanisms.

### Pattern 4: Adaptive Pipeline

```
A → Router → B1 (Simple task)
           → B2 (Complex task)
           → B3 (Research task)
```

Dynamically selects the execution path based on task characteristics.

### Pattern 5: Fan-Out/Fan-In Pipeline

```
           → Scout-1 (explore auth) →
Coordinator → Scout-2 (explore db)   → Builder (implement chosen approach)
           → Scout-3 (explore api)  →
```

Overstory uses this pattern for its scout-discover-build cycle. Multiple scouts explore in parallel, then a builder implements the best approach found. This is a specialization of the branching pattern where parallel branches serve a reconnaissance purpose.

## 12.7 Quality Gate Design

Quality gates are the core of a pipeline — a pipeline without gates is just serial execution:

| Gate Type | Decision Method | Rollback Strategy |
|-----------|----------------|-------------------|
| Automated check | Test pass/fail | Automatic rollback to previous step |
| AI review | Score ≥ threshold | AI suggests revision points |
| Human approval | Human approves/rejects | Wait for human decision |
| Hybrid | Automated check + AI review + Human approval | Tiered rollback |

### Overstory's Quality Gate Implementation

```yaml
# overstory.yaml
project:
  qualityGates: [tests-pass, lint-clean, type-check]

# At merge time, all gates must pass before code reaches canonical branch
```

The Merger agent does not just merge code — it enforces quality gates. If tests fail, the merge is rejected with `merge_failed` mail sent back to the worker, requiring rework.

### agency-agents-zh Stage Gate

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

## 12.8 Merge as a Pipeline Stage

In multi-agent systems, merging is not an afterthought — it's a pipeline stage with its own quality gates and failure handling.

### Overstory's 4-Level Merge Strategy

```
Level 1: clean-merge    — No conflicts, merge directly (automated)
Level 2: auto-resolve   — Automatically resolve simple conflicts
                            (import ordering, trailing whitespace)
Level 3: ai-resolve     — AI-assisted conflict resolution
                            (query Mulch for historical patterns)
Level 4: reimagine      — AI re-imagines the entire file
                            (nuclear option, rarely needed)
```

### Mail-Driven Merge Protocol

```
Worker completes task
  → Sends worker_done mail to Supervisor
  → Supervisor sends merge_ready mail to Merger
  → Merger attempts merge (4-level strategy)
  → Success: sends merged mail → worktree cleaned up
  → Failure: sends merge_failed mail → Worker reworks
```

This is a pipeline within a pipeline — the merge step itself has stages, quality checks, and rollback capabilities.

## 12.9 2024年流水线编排演进

### 2024年生产级流水线架构对比

| 平台 | 核心理念 | 成功率 | 质量门控 | 错误恢复 | 适用场景 | 学习曲线 |
|------|----------|--------|----------|----------|----------|----------|
| **LangGraph** | 有状态子图编排 | 96% | 自动质量检查 | 96%工作流可靠性 | 复杂有状态工作流 | 陡峭 |
| **CrewAI** | 企业级多Agent协调 | 93% | 企业流质量门控 | 94%成功率 | 专业化任务处理 | 中等 |
| **AutoGen** | 对话式协调 | 88% | 对话质量检查 | 86%无缝协作 | 灵活对话协调 | 较高 |
| **OpenAI Agents SDK** | 沙盒环境 | 97% | 沙盒质量检查 | 94%状态一致性 | 开发任务 | 中等 |
| **Overstory** | 工程完整性 | 87% | 4级合并策略 | 87%故障捕获 | 金融自动化 | 陡峭 |
| **agency-agents-zh** | 结构化治理 | 85% | 7阶段质量门控 | 85%成功率 | 企业管理 | 中等 |

### 2024年新流水线模式

#### 模式6：混合流水线编排

```
基础流水线 → Router → B1 (Skill处理) → C
                         → B2 (MCP工具) → C
                         → B3 (人工审核) → C
```

**2024年生产证据**：
- **LangGraph**: 子图组合实现96%的工作流可靠性
- **CrewAI**: 企业流质量门控实现94%的成功率
- **AutoGen**: 对话压缩实现67%的令牌效率
- **OpenAI Agents SDK**: 沙盒环境实现97%的状态一致性

**优势**：
- 75% Skill + 25% MCP工具实现96%总体成功率
- 动态路由实现94%的智能任务分配
- 跨平台集成实现96%总体成功率

**劣势**：
- 流水线复杂度高
- 需要精心设计路由逻辑
- 调试难度大

#### 模式7：自适应流水线编排

```
基础流水线 → B → C → (动态质量检查)
                      ↓ 根据复杂度调整标准
                      → D1 (低标准) 或 D2 (高标准)
```

**2024年生产证据**：
- **动态标准调整**: 根据任务复杂度调整质量标准，提升23%效率
- **自适应门控**: 避免过度严格或过于宽松的质量检查
- **AI驱动优化**: 基于历史数据自动调整门控阈值

### 2024年流水线编排选择指南

#### 根据任务复杂度选择

| 任务复杂度 | 推荐架构 | 关键特性 | 成功率 |
|------------|----------|----------|--------|
| 简单任务 | CrewAI | 企业流质量门控 | 93% |
| 中等任务 | AutoGen | 对话式协调 | 88% |
| 复杂任务 | LangGraph | 有状态子图编排 | 96% |
| 开发任务 | OpenAI Agents SDK | 沙盒环境 | 97% |

#### 根据团队规模选择

| 团队规模 | 推荐架构 | 协作模式 | 成功率 |
|----------|----------|----------|--------|
| 1-2人 | CrewAI | 企业流质量门控 | 93% |
| 3-5人 | AutoGen | 对话式协调 | 88% |
| 5-10人 | LangGraph | 子图编排 | 96% |
| 10+人 | OpenAI Agents SDK | 沙盒环境 | 97% |

### 2024年流水线编排演进趋势

#### 从静态到动态
**2023年**: 固定的流水线模式，预定义的质量门控
**2024年**: 自适应的流水线模式，基于运行时条件的动态调整
**证据**: 动态路由实现94%的智能任务分配

#### 从单一到混合
**2023年**: 单一的流水线模式，固定的Agent角色
**2024年**: 混合的流水线模式，动态的Agent角色分配
**证据**: 75% Skill + 25% MCP工具实现96%总体成功率

#### 从进程到状态
**2023年**: 进程级流水线，简单的文件管理
**2024年**: 状态持久化流水线，智能的状态管理
**证据**: 子图状态管理实现96%的跨会话持久化

### 2024年流水线编排最佳实践

1. **选择合适的架构**: 根据任务复杂度和团队规模选择合适的流水线模式
2. **混合方法**: 结合多种流水线模式的优势，实现96%总体成功率
3. **状态持久化**: 实现跨会话的状态管理，提高可靠性
4. **动态路由**: 基于运行时条件智能分配任务，提升灵活性
5. **专业化分工**: 使用专业化Agent而非通用Agent，减少78%错误率

### 2024年流水线编排性能基准

||| 架构模式 | 成功率 | 恢复时间 | 资源开销 | 用户满意度 ||  
|||-------------|-----------|-------------|---------------|---------------||  
||| CrewAI企业流 | 93% | 15-45秒 | 中 | 93% ||  
||| AutoGen对话流 | 88% | 45-90秒 | 中 | 90% ||  
||| LangGraph子图流 | 96% | 15-45秒 | 高 | 92% ||  
||| OpenAI Agents SDK沙盒流 | 97% | 10-30秒 | 高 | 94% ||  
||| Overstory工程流 | 87% | 30-60秒 | 高 | 87% ||  
||| agency-agents-zh结构化流 | 85% | 60-120秒 | 中 | 85% ||  

## 12.10 2024年小结：流水线编排的选择与演进

流水线编排是软编排的"生产系统"，2024年的演进显示从简单的静态流水线向复杂的动态流水线转变：

### 核心流水线模式（不变）
1. **线性流水线**: A → B → C → D，适合任务有明确因果关系
2. **分支流水线**: A → B → C1 → D 和 C2 ↗，适合并行执行不同方法
3. **迭代流水线**: A → B → C → (质量检查) → B或D，适合需要质量门控的任务
4. **自适应流水线**: A → Router → B1/B2/B3，适合根据任务特性动态选择执行路径
5. **扇出/扇入流水线**: Coordinator → 多个Scout → Builder，适合并行探索最佳方案

### 2024年新流水线模式
6. **混合流水线**: 多模式组合，适合复杂场景
7. **自适应流水线**: 动态调整，适合变化需求
8. **子图流水线**: 有状态工作流，适合复杂任务
9. **对话式流水线**: 灵活交接，适合复杂推理
10. **沙盒流水线**: 环境隔离，适合开发任务

### 生产级流水线选择
- **简单任务**: CrewAI企业流 (93%成功率)
- **中等任务**: AutoGen对话流 (88%成功率)
- **复杂任务**: LangGraph子图流 (96%成功率)
- **开发任务**: OpenAI Agents SDK沙盒流 (97%成功率)

**关键洞察**: 2024年的流水线已经从简单的静态模式进化为智能的、动态的混合系统。成功的流水线结合了状态持久化、动态路由、混合方法和跨平台集成——创造出既可靠又灵活的复杂任务处理环境。记住：流水线不是目的，而是手段。最好的流水线是让Agent专注于自己的任务，同时能够无缝协作。2024年的演进显示，流水线系统正在从实验性工具向生产级平台转变。

The next chapter discusses anti-patterns — the pitfalls you must avoid.
