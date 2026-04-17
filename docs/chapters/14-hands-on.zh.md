# 第十四章 实战：搭建你的第一个编排器

> 理论讲了这么多，来动手做一个。我们从零开始，用最简单的工具搭建一个能让Agent持续工作的编排器。

## 14.1 目标

搭建一个双Agent编排器：
- **架构师Agent**（Hermes）：规划任务、审阅结果
- **执行者Agent**（Codex）：写代码、跑测试
- **编排器守护进程**（Bash脚本）：监控、恢复、驱动

## 14.2 最小可行编排器（30行代码）

```bash
#!/bin/bash
# minimal-orchestrator.sh — 30行最小编排器

PROJECT_DIR="$1"
cd "$PROJECT_DIR" || exit 1

# 启动两个Agent
tmux new-session -d -s architect "hermes chat --yolo"
tmux new-session -d -s executor "codex"

while true; do
    # 检查Agent是否还活着
    if ! tmux has-session -t architect 2>/dev/null; then
        echo "[$(date)] 架构师挂了，重启..."
        tmux new-session -d -s architect "hermes chat --yolo"
    fi
    
    if ! tmux has-session -t executor 2>/dev/null; then
        echo "[$(date)] 执行者挂了，重启..."
        tmux new-session -d -s executor "codex"
    fi
    
    sleep 60  # 每分钟检查一次
done
```

**这30行代码解决了什么？**
- Agent崩溃后自动重启 ✓
- 不需要人盯着 ✓

**还缺什么？**
- 不知道Agent在做什么（没有通信）
- Agent可能卡住但进程还在（没有活跃检测）
- Agent可能违反规则（没有规则守护）

## 14.3 加上通信（+20行）

```bash
# 给架构师发消息的函数
send_to_architect() {
    local msg="$1"
    tmpf=$(mktemp)
    printf '\e[200~%s\e[201~' "$msg" > "$tmpf"
    tmux load-buffer -t architect "$tmpf"
    rm -f "$tmpf"
    tmux paste-buffer -t architect
    sleep 1
    tmux send-keys -t architect Enter
}

# 给执行者发消息的函数
send_to_executor() {
    local msg="$1"
    tmpf=$(mktemp)
    printf '\e[200~%s\e[201~' "$msg" > "$tmpf"
    tmux load-buffer -t executor "$tmpf"
    rm -f "$tmpf"
    tmux paste-buffer -t executor
    sleep 1
    tmux send-keys -t executor Enter
}
```

**bracket-paste是什么？**
普通的send-keys会把多行文本的每行当作一次Enter键，导致Agent收到碎片化的消息。bracket-paste用`\e[200~`和`\e[201~`包裹文本，告诉终端"这是一次性粘贴"，避免换行被误解析。

## 14.4 加上活跃检测（+15行）

```bash
# 检测Agent是否卡住
STALE_THRESHOLD=1800  # 30分钟无变化视为卡住

check_stale() {
    local session="$1"
    local hash_file="/tmp/${session}_screen_hash"
    local current_hash
    
    current_hash=$(tmux capture-pane -t "$session" -p | md5sum)
    
    if [ -f "$hash_file" ]; then
        local old_hash last_change
        old_hash=$(cat "$hash_file")
        if [ "$current_hash" = "$old_hash" ]; then
            last_change=$(cat "/tmp/${session}_last_change" 2>/dev/null || echo "0")
            local now=$(date +%s)
            if [ $((now - last_change)) -gt "$STALE_THRESHOLD" ]; then
                echo "[$(date)] $session 卡住${STALE_THRESHOLD}秒，强制重启"
                tmux kill-session -t "$session"
                return 1
            fi
        else
            echo $(date +%s) > "/tmp/${session}_last_change"
        fi
    fi
    
    echo "$current_hash" > "$hash_file"
    return 0
}
```

## 14.5 加上systemd守护（+10行配置）

```ini
# ~/.config/systemd/user/minimal-orchestrator.service
[Unit]
Description=Minimal Agent Orchestrator
After=network.target

[Service]
Type=simple
ExecStart=/usr/local/bin/minimal-orchestrator.sh /path/to/project
Restart=always
RestartSec=15

[Install]
WantedBy=default.target
```

```bash
# 启用
systemctl --user daemon-reload
systemctl --user enable minimal-orchestrator
systemctl --user start minimal-orchestrator

# 确保用户不注销时也运行
loginctl enable-linger $(whoami)
```

## 14.6 完整编排器的演进路径

```
30行最小编排器
  → +通信（bracket-paste）
  → +活跃检测（screen hash）
  → +systemd守护
  → +铁律检查（git checkout恢复）
  → +Rate Limit处理（冷却持久化）
  → +快速崩溃保护（重启频率限制）
  → +问题催促（等待人工时自动决策）
  → 这就是一个从简单到复杂的自然演化过程
```

**关键原则**：每个特性都是因为真实踩坑才加的，不是预先设计的。

## 14.7 小结

从30行到数百行，编排器的演化路径清晰：

1. **先让它跑起来**：最小可用的自动重启
2. **加上通信**：Agent之间能传消息
3. **加上检测**：知道Agent是否卡住
4. **加上守护**：编排器本身不怕崩溃
5. **加上约束**：铁律、冷却、崩溃保护
6. **持续迭代**：每个新问题都是新特性的种子

## 14.8 模式：剧本驱动编排（Playbook-Driven Orchestration）

在脚本化方式之外，agency-agents-zh展示了一种**剧本模式（Playbook）**——预定义的工作流，引导Agent完成复杂的多步骤任务：

```markdown
# playbook: feature-implementation.md
## 触发条件
当通过Sprint规划请求新功能时

## 步骤
1. **侦察Agent**：研究现有代码，识别集成点
   - 输出：research-brief.md
   - 关口：必须识别至少2个集成点
   
2. **架构师Agent**：设计实现方案
   - 输入：research-brief.md
   - 输出：impl-plan.md  
   - 关口：必须覆盖错误处理+测试策略
   
3. **构建者Agent**：实现功能
   - 输入：impl-plan.md
   - 输出：代码变更
   - 关口：所有测试通过 + lint清洁
   
4. **QA Agent**：审阅和测试
   - 输入：代码变更
   - 输出：qa-report.md
   - 关口：无P0/P1问题
   
5. **部署Agent**：发布上线
   - 输入：qa-report.md（已通过）
   - 输出：部署确认
```

### 剧本 vs 脚本：何时使用哪种

| 维度 | 脚本编排 | 剧本编排 |
|------|---------|---------|
| 执行方式 | 确定性、自动化 | 引导式、半自动化 |
| 灵活性 | 低（硬编码步骤） | 高（Agent解读步骤） |
| 人工参与 | 最少 | 在质量关口处参与 |
| 最适用于 | 重复性、定义明确的任务 | 复杂、需要判断的任务 |
| 错误恢复 | 从检查点重启 | Agent自适应并重试 |

### 在Bash中实现剧本

```bash
#!/bin/bash
# playbook-runner.sh — 简单剧本执行器

PLAYBOOK_DIR="./playbooks"
CURRENT_STEP_FILE="/tmp/playbook_current_step"

run_playbook() {
    local playbook="$1"
    local step=1
    
    if [ -f "$CURRENT_STEP_FILE" ]; then
        step=$(cat "$CURRENT_STEP_FILE")
        echo "[PLAYBOOK] 从步骤 $step 恢复"
    fi
    
    while true; do
        local step_file="${PLAYBOOK_DIR}/${playbook}/step${step}.md"
        [ ! -f "$step_file" ] && echo "[PLAYBOOK] 所有步骤完成！" && break
        
        echo "[PLAYBOOK] 执行步骤 $step..."
        send_to_architect "$(cat "$step_file")"
        
        # 等待Agent发出完成信号（通过SPRINT.md或文件创建）
        wait_for_step_completion "$step"
        
        # 运行质量关口
        if ! run_gate "$playbook" "$step"; then
            echo "[PLAYBOOK] 步骤 $step 关口未通过，要求返工"
            send_to_architect "步骤 $step 质量关口未通过，请返工。"
            continue  # 重试同一步骤
        fi
        
        echo "$((step + 1))" > "$CURRENT_STEP_FILE"
        step=$((step + 1))
    done
    
    rm -f "$CURRENT_STEP_FILE"
}
```

## 14.9 下一步

现在你有了基础，考虑添加：

- **规则检查**：监控规则违规并采取行动
- **Rate Limit处理**：实现智能冷却管理
- **进度追踪**：监控项目进度，检测停滞
- **跨项目协调**：在多个编排器之间共享资源
- **自愈能力**：自动从常见故障模式中恢复
- **剧本**：为常见任务类型定义可复用的多步骤工作流

记住：好的编排器是打磨出来的，不是设计出来的。每次崩溃、每次429、每次Agent偷懒——它们都在告诉你下一步该改进什么。
