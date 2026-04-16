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

## 10.6 小结

Skill系统是软编排的"可复用知识"层：

1. **封装**：把反复出现的模式封装成Skill
2. **发现**：通过skill_list自动扫描可用技能
3. **演化**：使用中发现问题立即Patch
4. **互补**：Skill指导流程，MCP工具执行操作

下一章讨论流水线编排——如何用多个Skill和Agent串联完成复杂任务。
