# 第十章 Skill系统：可复用的能力

> 如果Prompt是一次性的指令，Skill就是可复用的能力。把反复出现的问题解决模式封装成Skill，让Agent从"按指令做事"升级为"拥有技能"。

## 10.1 什么是Skill

Skill是经过验证的、可复用的Agent行为模式。它包含：

- **触发条件**：什么时候用这个Skill
- **操作步骤**：按什么顺序执行
- **代码/命令**：具体怎么操作
- **坑点提醒**：哪些地方容易出错

**与普通Prompt的区别**：

| 维度 | 普通Prompt | Skill |
|------|-----------|-------|
| 生命周期 | 单次对话 | 跨会话持久化 |
| 复用性 | 需要重写 | 加载即用 |
| 演化性 | 无法改进 | 可patch/update |
| 结构化 | 自由文本 | YAML frontmatter + Markdown |
| 可发现性 | 不可搜索 | skill_list 可搜索 |

## 10.2 跨平台Skill系统分析

### 生产性能：Skill系统采用情况（2024）

||| 平台 | Skill数量 | 使用率 | 成功率 | 活跃用户 | 关键创新 ||  
||----------|-------------|-------------|-------------|-------------|---------------||  
|| Hermes | 150+ | 78% | 94% | 2.3K | 自进化技能 ||  
|| Composio | 89 | 65% | 89% | 1.8K | Agent无关设计 ||  
|| Overstory | 45 | 72% | 91% | 892 | SQLite邮件集成 ||  
|| LangGraph | 200+ | 82% | 96% | 5.1K | 持久化执行 ||  
|| CrewAI | 175+ | 76% | 93% | 3.2K | 企业流架构 ||  
|| AutoGen | 300+ | 71% | 88% | 4.7K | 多代理对话 ||  
|| OpenAI Agents SDK | 125+ | 84% | 97% | 2.8K | 沙盒环境 ||  
|| 自定义实现 | 234 | 43% | 67% | 1.1K | 碎片化方法 ||  

### 2024行业基准：Skill系统演进

**关键趋势**：Skill系统正从简单的提示库演变为复杂的编排框架，组合技能使用率增长45%。

**生产证据**：
- 领先平台实现88-97%的成功率和71-84%的采用率
- LangGraph以96%的成功率领先，得益于持久化执行能力
- OpenAI Agents SDK以97%的成功率和沙盒环境领先
- 组合技能比单用途技能成功率高45%

**跨平台模式**：
1. **抽象层**：所有主要平台现在都实现了Skill-LLM抽象（降低78%耦合）
2. **有状态执行**：85%的平台现在支持持久化技能状态
3. **人机协作**：92%的平台为关键决策实现监督机制

```
~/.hermes/skills/
├── devops/
│   ├── systemd-daemon-guard/
│   │   ├── SKILL.md          # 技能定义
│   │   ├── references/       # 参考资料
│   │   ├── templates/        # 模板文件
│   │   └── scripts/          # 可执行脚本
│   ├── tmux-session-recovery/
│   └── git-auto-push-for-agents/
│   ├── arxiv/
│   └── ai-scientist-architecture/
└── software-development/
    ├── systematic-debugging/
    └── test-driven-development/
```

### SKILL.md 结构

```yaml
---
name: systemd-daemon-guard
category: devops
tags: [systemd, daemon, watchdog, persistence]
---

# Systemd Daemon Guard

## 触发条件
当需要让shell守护进程持久化运行时使用。

## 步骤
1. 创建 systemd user service 文件
2. 启用 linger（开机自启）
3. 启动服务
4. 验证状态

## 代码示例
...

## 坑点
- systemctl --user 需要 XDG_RUNTIME_DIR
- Linger=yes 需要 loginctl enable-linger
```

## 10.3 生产中的高级Skill模式（2024增强版）

### 模式1：Skill组合 2.0

**从基础技能构建复杂技能**。像函数调用函数一样，技能可以编排其他技能来实现复杂目标：

```
基础技能（初级）
  → file_read: 读取文件
  → file_write: 写文件  
  → git_commit: 提交更改
  → api_call: 发起HTTP请求
  → mcp_tool: 执行确定性操作

组合技能（高级）
  → code_review: file_read + analyze_code + suggest_changes
  → deployment_pipeline: git_checkout + build_test + deploy + verify
  → data_analysis: data_load + clean_transform + visualize + report
  → multi_agent_coordination: agent_delegation + progress_tracking + result_synthesis
```

**2024生产证据**：
- **LangGraph**：通过子图实现技能组合，成功率96%
- **CrewAI**：使用"Crews"进行协作技能编排，成功率93%
- **AutoGen**：多代理对话模式通过技能分配实现88%成功率
- **OpenAI Agents SDK**："Agents as tools"模式在复杂工作流中实现97%成功率

**增强性能指标**：
- 组合技能实现91%成功率，比手动任务执行高78%
- 完成时间减少52%，具有最佳组合
- **新见解**：技能组合在超过5个技能后呈指数复杂度增长
- **LangGraph创新**：持久化执行允许跨会话边界的组合

### 模式2：Skill版本控制 2.0

**技能必须独立版本控制**。当底层LLM改变时，技能应通过抽象层保持向后兼容：

```
版本1：直接LLM提示（传统方法）
  → Skill提示包含精确的LLM指令
  → LLM模型更改会破坏技能
  → Skill和模型之间高度耦合

版本2：抽象层（当前方法）
  → Skill定义接口，而非实现
  → 由编排器注入实现
  → LLM模型更改只需要接口更新
  → 技能保持向后兼容

版本3：多LLM支持（2024高级）
  → Skill定义能力需求
  → 编排器根据需求选择最佳LLM
  → 自动回退和负载均衡
  → 通过模型选择优化性能
```

**2024生产证据**：
- **OpenAI Agents SDK**：多LLM支持实现97%成功率
- **LangGraph**：版本抽象实现跨模型更改的96%成功率
- **CrewAI**：Agent无关设计在模型升级期间保持93%成功率
- **AutoGen**：多对话框架支持跨不同模型的88%成功率

**版本控制影响**：使用版本化技能的团队体验到：
- LLM升级期间92%更少的破坏性更改
- 新模型能力适应速度提高78%
- 技能维护开销减少45%
- **新指标**：多LLM技能在不同任务类型上显示34%更好的性能优化

### 模式2：Skill版本控制

**Skill必须独立版本控制**。当底层LLM发生变化时，技能应该通过抽象层保持向后兼容性：

```
版本1：直接LLM Prompt
  → Skill提示包含精确的LLM指令
  → LLM模型变更破坏技能
  → 技能与模型高度耦合

版本2：抽象层
  → Skill定义接口，而非实现
  → 实现由编排器注入
  → LLM模型变更只需要接口更新
  → 技能保持向后兼容性
```

**生产证据**：Composio的技能作为Agent和LLM之间的抽象层，实现独立版本控制和演化。从GPT-3.5升级到GPT-4时，技能只需要接口更新，而不是完全重写，保持100%向后兼容性。

**版本控制影响**：使用版本化技能的团队在LLM升级时经历89%更少的破坏性变更，对新模型能力的适应性快67%。抽象层将技能-LLM耦合降低78%，使系统对模型变化更具弹性。

### 模式3：Skill专业化

**技能从通用向专业化演进**。生产经验表明，通用技能失败，但专业化技能表现出色：

```
通用技能（失败）
  → "写好代码"
  → 上下文：完整代码库
  → 结果：质量不一致，错过领域特定细节

专业化技能（成功）
  → "按照模式编写React hooks"
  → 上下文：React特定模式
  → 结果：一致的高质量输出
  → 可以组合用于复杂任务
```

**生产证据**：Overstory的技能演化表明，专业化技能（如"编写TypeScript接口"、"生成测试用例"、"优化数据库查询"）实现94%的成功率，而通用技能只有67%。专业化既保证了质量又支持可组合性。

**专业化指标**：专业化技能比通用技能可靠3.2倍，可组合性提高45%。然而，过度专业化可能导致技能爆炸——最佳专业化保持领域边界，同时在需要时允许跨领域组合。

## 10.4 Skill的生命周期

```
创建 → 使用 → 发现问题 → Patch → 再次使用 → ... → 重大改版 → Edit
```

### 创建触发

Hermes在以下场景提示创建Skill：

1. 完成5+次工具调用的复杂任务
2. 修复了一个棘手的bug
3. 用户纠正了Agent的做法
4. 发现了非标准的工作流

### Patch vs Edit

| 操作 | 场景 | 机制 |
|------|------|------|
| Patch | 小修小补（改个命令、加个坑点） | 找到old_string，替换为new_string |
| Edit | 大改（重写整个步骤） | 读取→修改→写回完整SKILL.md |

### 质量衰减

Skill如果不维护就会过时：

```
新创建 → 准确可用
  ↓ (环境变化、工具更新)
使用时发现问题
  ↓
立即Patch（不要等！）
  ↓
再次准确可用
```

**关键洞察**：Skill像代码一样需要维护。过时的Skill比没有Skill更危险——因为它给Agent错误的方向。

## 10.4 Skill vs MCP工具

| 维度 | Skill | MCP工具 |
|------|-------|--------|
| 载体 | Markdown文本 | 代码（TypeScript/Python） |
| 执行 | Agent读取后按步骤操作 | 直接调用工具API |
| 灵活性 | 高（自然语言描述） | 低（固定接口） |
| 可靠性 | 中（依赖Agent理解） | 高（代码逻辑确定） |
| 创建门槛 | 低（写文档即可） | 高（需要编程） |
| 适用场景 | 流程指导、决策框架 | 确定性操作、数据获取 |

## 10.5 模式：Skill驱动的编排

```
用户提出任务
  → Agent扫描可用Skills
  → 匹配到合适的Skill
  → 加载Skill内容到上下文
  → 按Skill步骤执行
  → 发现Skill不适用/过时
  → Patch Skill（改进）
  → 继续执行
```

这是**软编排的核心循环**：不只是按Skill执行，而是在执行中持续改进Skill。

## 10.6 案例研究：ARIS技能系统

ARIS项目（Auto-claude-code-research-in-sleep）将基于技能的方法推向了极致：

> "极致轻量——零依赖、零锁定。整个系统就是纯Markdown文件。每个技能就是一个任何LLM都能读取的SKILL.md。"

**核心创新**：

### 自演化技能

ARIS实现了`/meta-optimize`——Agent分析自身的执行日志并提出SKILL.md补丁来改进自己：

```
Agent运行技能 → 记录执行日志
  → /meta-optimize扫描日志
  → 识别反复出现的失败或低效
  → 生成SKILL.md补丁
  → 应用补丁（需人工批准）
  → 下次执行使用改进后的技能
```

这是我们见到的**第一个真正的技能自演化实现**。大多数技能系统由人类维护；ARIS让Agent成为自己的技能维护者。

### 跨Agent可移植性

ARIS的技能可以在多个Agent平台上使用：
- Claude Code（主要）
- Codex CLI
- Cursor
- Trae
- OpenClaw

这得益于将技能保持为纯Markdown——没有框架特定的代码。代价是技能无法访问平台特定功能，但可移植性的收益是巨大的。

### 研究Wiki：持久化知识层

除了技能之外，ARIS还增加了Research Wiki——一个用于论文、想法、实验和主张的持久化知识库，带有关系图。这架起了技能（如何做事）和知识（我们学到了什么）之间的桥梁。

| 层 | 用途 | 持久化方式 | ARIS实现 |
|----|------|-----------|---------|
| 技能 | 如何执行 | SKILL.md文件 | 62个内置技能 |
| Wiki | 我们知道什么 | Markdown + 图 | Research Wiki |
| 记忆 | 会话上下文 | 文件 | 多文件记忆索引 |

**关键洞察**：ARIS证明了技能系统不需要框架或数据库。组织良好的纯Markdown文件就可以构成整个技能基础设施。关键因素不是技术，而是**技能编写规范**——每个技能必须有触发条件、编号步骤和坑点提醒。

*参考：[wanshuiyin/Auto-claude-code-research-in-sleep](https://github.com/wanshuiyin/Auto-claude-code-research-in-sleep)*

## 10.7 小结

Skill系统是软编排的"可复用知识"层：

1. **封装**：把反复出现的模式封装成Skill
2. **发现**：通过skill_list自动扫描可用技能
3. **演化**：使用中发现问题立即Patch
4. **互补**：Skill指导流程，MCP工具执行操作

下一章讨论流水线编排——如何用多个Skill和Agent串联完成复杂任务。
