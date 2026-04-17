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

## 10.2 Hermes Skill系统架构

Hermes Agent的Skill系统是目前最成熟的软编排Skill实现：

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

## 10.3 Skill的生命周期

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
