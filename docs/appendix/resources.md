# Reference Resources

> Recommended resources for learning AI Agent orchestration

## Books and Long-form Articles

- [Building Effective Agents](https://www.anthropic.com/research/building-effective-agents) — Anthropic's official Agent design guide, covers workflow patterns vs autonomous agents
- [OpenAI Agents Guide](https://platform.openai.com/docs/guides/agents) — OpenAI's Agent best practices
- [LangChain Agent Docs](https://python.langchain.com/docs/concepts/agents/) — LangChain Agent concepts and orchestration patterns
- [The AI Scientist](https://arxiv.org/abs/2408.06292) — Sakana AI's automated research pipeline, a key case study for multi-stage agent orchestration
- [Designing Agentive Technology](https://book.agentive.tech/) — AI agent design patterns from a UX perspective

## Academic Papers

- **Multi-Agent Coordination**
  - Park, J.S., et al. "Generative Agents: Interactive Simulacra of Human Behavior." UIST 2023. — Foundation for believable agent behavior and social coordination
  - Wu, Q., et al. "AutoGen: Enabling Next-Gen LLM Applications via Multi-Agent Conversation." COLM 2024. — Conversational multi-agent orchestration framework
  - Talebirad, Y., & Nadiri, A. "Multi-Agent Collaboration: Harnessing the Power of Intelligent LLM Agents." 2023. — Taxonomy of multi-agent collaboration patterns

- **Orchestration Architectures**
  - Hong, S., et al. "MetaGPT: Meta Programming for A Multi-Agent Collaborative Framework." ICLR 2024. — Role-based SOP for multi-agent systems
  - Chen, W., et al. "AgentVerse: Facilitating Multi-Agent Collaboration and Exploring Emergent Behaviors." 2023. — Dynamic agent recruitment and collaboration
  - Wang, L., et al. "A Survey on Large Language Model based Autonomous Agents." FCS 2024. — Comprehensive survey of agent architectures

- **Fault Tolerance & Reliability**
  - Shinn, N., et al. "Reflexion: Language Agents with Verbal Reinforcement Learning." NeurIPS 2023. — Self-reflection for error correction
  - Madaan, A., et al. "Self-Refine: Iterative Refinement with Self-Feedback." NeurIPS 2023. — Iterative improvement without external feedback

- **Communication & Knowledge**
  - Li, J., et al. "Chain of Agents: Large Language Models Collaborating on Long-Context Tasks." 2024. — Agent-to-agent communication for context-heavy tasks
  - Liu, X., et al. "Communicative Agents for Software Development." 2023. — ChatDev's communication protocol design

- **Planning & Reasoning**
  - Yao, S., et al. "ReAct: Synergizing Reasoning and Acting in Language Models." ICLR 2023. — Reasoning-action interleaving for agent planning
  - Significant Gravitas. "AutoGPT." 2023. — Pioneer in autonomous agent execution loops

## Open Source Projects

See [Project Index](./project-index.md)

Key repositories beyond the book's core projects:

- [CrewAI](https://github.com/crewAIInc/crewAI) — Role-based agent collaboration with shared memory
- [LangGraph](https://github.com/langchain-ai/langgraph) — Graph-based workflow orchestration
- [AutoGen](https://github.com/microsoft/autogen) — Multi-agent conversation framework
- [OpenAI Swarm](https://github.com/openai/swarm) — Minimal agent handoff framework
- [AgentScope](https://github.com/modelscope/agentscope) — Multi-agent platform with distributed support
- [Camel](https://github.com/camel-ai/camel) — Communicative agents for mind exploration
- [MetaGPT](https://github.com/geekan/MetaGPT) — SOP-driven multi-agent framework
- [Devon](https://github.com/entropy-research/Devon) — Open-source coding agent with orchestration

## Blogs and Communities

- [Simon Willison's Weblog](https://simonwillison.net/) — Agent pattern observations and LLM tooling insights
- [Latent Space](https://www.latent.space/) — AI engineering trends and agent architecture discussions
- [LangChain Blog](https://blog.langchain.dev/) — Orchestration insights and LangGraph updates
- [r/LocalLLaMA](https://www.reddit.com/r/LocalLLaMA/) — Local LLM community, agent experiments
- [AI Engineer Foundation](https://www.aiengineerfoundation.org/) — Agent standards and best practices
- [Anthropic Blog](https://www.anthropic.com/research) — Frontier agent research and safety
- [Lilian Weng's Blog](https://lilianweng.github.io/) — LLM Agent survey and architecture deep dives

## Tools and Frameworks

| Tool | Type | Best For |
|------|------|----------|
| Claude Code | CLI Agent | Local development, single-agent coding |
| Codex CLI | CLI Agent | Autonomous code generation |
| OpenCode | CLI Agent | Feature implementation |
| Hermes Agent | CLI Orchestrator | Multi-profile agent management |
| MCP Servers | Protocol | Tool/context sharing across agents |
| tmux | Terminal | Multi-session agent hosting |
| systemd | Service Manager | Daemon persistence and auto-restart |
