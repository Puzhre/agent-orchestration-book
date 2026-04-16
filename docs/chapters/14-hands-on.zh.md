# 第十四章 实战：搭建你的第一个编排器

> 理论讲了这么多，来动手做一个。我们从零开始，用最简单的工具搭建一个能让Agent持续工作的编排器。

## 13.1 目标

搭建一个双Agent编排器：
- **架构师Agent**（Hermes）：规划任务、审阅结果
- **执行者Agent**（Codex）：写代码、跑测试
- **编排器守护进程**（Bash脚本）：监控、恢复、驱动

## 13.2 最小可行编排器（30行代码）

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

## 13.3 加上通信（+20行）

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

## 13.4 加上活跃检测（+15行）

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

## 13.5 加上systemd守护（+10行配置）

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

## 13.6 完整编排器的演进路径

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

## 13.7 小结

从30行到数百行，编排器的演化路径清晰：

1. **先让它跑起来**：最小可用的自动重启
2. **加上通信**：Agent之间能传消息
3. **加上检测**：知道Agent是否卡住
4. **加上守护**：编排器本身不怕崩溃
5. **加上约束**：铁律、冷却、崩溃保护
6. **持续迭代**：每个新问题都是新特性的种子
