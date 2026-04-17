# 参考资源

> 学习AI Agent编排的推荐资源

## 书籍与长文

- [Building Effective Agents](https://www.anthropic.com/research/building-effective-agents) — Anthropic官方Agent设计指南，涵盖工作流模式与自主Agent
- [OpenAI Agents Guide](https://platform.openai.com/docs/guides/agents) — OpenAI的Agent最佳实践
- [LangChain Agent Docs](https://python.langchain.com/docs/concepts/agents/) — LangChain Agent概念与编排模式
- [The AI Scientist](https://arxiv.org/abs/2408.06292) — Sakana AI的自动化研究流水线，多阶段Agent编排的关键案例
- [Designing Agentive Technology](https://book.agentive.tech/) — 从UX视角看AI Agent设计模式

## 学术论文

- **多Agent协作**
  - Park, J.S., et al. "Generative Agents: Interactive Simulacra of Human Behavior." UIST 2023. — 可信Agent行为与社会协调的基础
  - Wu, Q., et al. "AutoGen: Enabling Next-Gen LLM Applications via Multi-Agent Conversation." COLM 2024. — 对话式多Agent编排框架
  - Talebirad, Y., & Nadiri, A. "Multi-Agent Collaboration: Harnessing the Power of Intelligent LLM Agents." 2023. — 多Agent协作模式分类学

- **编排架构**
  - Hong, S., et al. "MetaGPT: Meta Programming for A Multi-Agent Collaborative Framework." ICLR 2024. — 基于角色的多Agent系统SOP
  - Chen, W., et al. "AgentVerse: Facilitating Multi-Agent Collaboration and Exploring Emergent Behaviors." 2023. — 动态Agent招募与协作
  - Wang, L., et al. "A Survey on Large Language Model based Autonomous Agents." FCS 2024. — Agent架构综合综述

- **容错与可靠性**
  - Shinn, N., et al. "Reflexion: Language Agents with Verbal Reinforcement Learning." NeurIPS 2023. — 通过自我反思进行错误修正
  - Madaan, A., et al. "Self-Refine: Iterative Refinement with Self-Feedback." NeurIPS 2023. — 无需外部反馈的迭代改进

- **通信与知识**
  - Li, J., et al. "Chain of Agents: Large Language Models Collaborating on Long-Context Tasks." 2024. — 面向重上下文任务的Agent间通信
  - Liu, X., et al. "Communicative Agents for Software Development." 2023. — ChatDev的通信协议设计

- **规划与推理**
  - Yao, S., et al. "ReAct: Synergizing Reasoning and Acting in Language Models." ICLR 2023. — 推理-行动交错用于Agent规划
  - Significant Gravitas. "AutoGPT." 2023. — 自主Agent执行循环的先驱

## 开源项目

参见 [项目索引](./project-index.zh.md)

本书核心项目之外的关键仓库：

- [CrewAI](https://github.com/crewAIInc/crewAI) — 基于角色的Agent协作，共享记忆
- [LangGraph](https://github.com/langchain-ai/langgraph) — 基于图的工作流编排
- [AutoGen](https://github.com/microsoft/autogen) — 多Agent对话框架
- [OpenAI Swarm](https://github.com/openai/swarm) — 极简Agent交接框架
- [AgentScope](https://github.com/modelscope/agentscope) — 支持分布式的多Agent平台
- [Camel](https://github.com/camel-ai/camel) — 用于思维探索的通信式Agent
- [MetaGPT](https://github.com/geekan/MetaGPT) — SOP驱动的多Agent框架
- [Devon](https://github.com/entropy-research/Devon) — 带编排功能的开源编程Agent

## 博客与社区

- [Simon Willison's Weblog](https://simonwillison.net/) — Agent模式观察与LLM工具洞察
- [Latent Space](https://www.latent.space/) — AI工程趋势与Agent架构讨论
- [LangChain Blog](https://blog.langchain.dev/) — 编排洞察与LangGraph更新
- [r/LocalLLaMA](https://www.reddit.com/r/LocalLLaMA/) — 本地LLM社区，Agent实验
- [AI Engineer Foundation](https://www.aiengineerfoundation.org/) — Agent标准与最佳实践
- [Anthropic Blog](https://www.anthropic.com/research) — 前沿Agent研究与安全
- [Lilian Weng's Blog](https://lilianweng.github.io/) — LLM Agent综述与架构深度剖析

## 工具与框架

| 工具 | 类型 | 最适用场景 |
|------|------|-----------|
| Claude Code | CLI Agent | 本地开发，单Agent编程 |
| Codex CLI | CLI Agent | 自主代码生成 |
| OpenCode | CLI Agent | 功能实现 |
| Hermes Agent | CLI编排器 | 多配置Agent管理 |
| MCP Servers | 协议 | 跨Agent工具/上下文共享 |
| tmux | 终端 | 多会话Agent托管 |
| systemd | 服务管理器 | 守护进程持久化与自动重启 |
