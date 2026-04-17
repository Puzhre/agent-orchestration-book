     1|# 第十四章 实战：搭建你的第一个编排器
     2|
     3|> 理论讲了这么多，来动手做一个。我们从零开始，用最简单的工具搭建一个能让Agent持续工作的编排器。
     4|
     5|## 14.1 目标
     6|
     7|搭建一个双Agent编排器：
     8|- **架构师Agent**（Hermes）：规划任务、审阅结果
     9|- **执行者Agent**（Codex）：写代码、跑测试
    10|- **编排器守护进程**（Bash脚本）：监控、恢复、驱动
    11|
    12|## 14.2 最小可行编排器（30行代码）
    13|
    14|```bash
    15|#!/bin/bash
    16|# minimal-orchestrator.sh — 30行最小编排器
    17|
    18|PROJECT_DIR="$1"
    19|cd "$PROJECT_DIR" || exit 1
    20|
    21|# 启动两个Agent
    22|tmux new-session -d -s architect "hermes chat --yolo"
    23|tmux new-session -d -s executor "codex"
    24|
    25|while true; do
    26|    # 检查Agent是否还活着
    27|    if ! tmux has-session -t architect 2>/dev/null; then
    28|        echo "[$(date)] 架构师挂了，重启..."
    29|        tmux new-session -d -s architect "hermes chat --yolo"
    30|    fi
    31|    
    32|    if ! tmux has-session -t executor 2>/dev/null; then
    33|        echo "[$(date)] 执行者挂了，重启..."
    34|        tmux new-session -d -s executor "codex"
    35|    fi
    36|    
    37|    sleep 60  # 每分钟检查一次
    38|done
    39|```
    40|
    41|**这30行代码解决了什么？**
    42|- Agent崩溃后自动重启 ✓
    43|- 不需要人盯着 ✓
    44|
    45|**还缺什么？**
    46|- 不知道Agent在做什么（没有通信）
    47|- Agent可能卡住但进程还在（没有活跃检测）
    48|- Agent可能违反规则（没有规则守护）
    49|
    50|## 14.3 加上通信（+20行）
    51|
    52|```bash
    53|# 给架构师发消息的函数
    54|send_to_architect() {
    55|    local msg="$1"
    56|    tmpf=$(mktemp)
    57|    printf '\e[200~%s\e[201~' "$msg" > "$tmpf"
    58|    tmux load-buffer -t architect "$tmpf"
    59|    rm -f "$tmpf"
    60|    tmux paste-buffer -t architect
    61|    sleep 1
    62|    tmux send-keys -t architect Enter
    63|}
    64|
    65|# 给执行者发消息的函数
    66|send_to_executor() {
    67|    local msg="$1"
    68|    tmpf=$(mktemp)
    69|    printf '\e[200~%s\e[201~' "$msg" > "$tmpf"
    70|    tmux load-buffer -t executor "$tmpf"
    71|    rm -f "$tmpf"
    72|    tmux paste-buffer -t executor
    73|    sleep 1
    74|    tmux send-keys -t executor Enter
    75|}
    76|```
    77|
    78|**bracket-paste是什么？**
    79|普通的send-keys会把多行文本的每行当作一次Enter键，导致Agent收到碎片化的消息。bracket-paste用`\e[200~`和`\e[201~`包裹文本，告诉终端"这是一次性粘贴"，避免换行被误解析。
    80|
    81|## 14.4 加上活跃检测（+15行）
    82|
    83|```bash
    84|# 检测Agent是否卡住
    85|STALE_THRESHOLD=1800  # 30分钟无变化视为卡住
    86|
    87|check_stale() {
    88|    local session="$1"
    89|    local hash_file="/tmp/${session}_screen_hash"
    90|    local current_hash
    91|    
    92|    current_hash=$(tmux capture-pane -t "$session" -p | md5sum)
    93|    
    94|    if [ -f "$hash_file" ]; then
    95|        local old_hash last_change
    96|        old_hash=$(cat "$hash_file")
    97|        if [ "$current_hash" = "$old_hash" ]; then
    98|            last_change=$(cat "/tmp/${session}_last_change" 2>/dev/null || echo "0")
    99|            local now=$(date +%s)
   100|            if [ $((now - last_change)) -gt "$STALE_THRESHOLD" ]; then
   101|                echo "[$(date)] $session 卡住${STALE_THRESHOLD}秒，强制重启"
   102|                tmux kill-session -t "$session"
   103|                return 1
   104|            fi
   105|        else
   106|            echo $(date +%s) > "/tmp/${session}_last_change"
   107|        fi
   108|    fi
   109|    
   110|    echo "$current_hash" > "$hash_file"
   111|    return 0
   112|}
   113|```
   114|
   115|## 14.5 加上systemd守护（+10行配置）
   116|
   117|```ini
   118|# ~/.config/systemd/user/minimal-orchestrator.service
   119|[Unit]
   120|Description=Minimal Agent Orchestrator
   121|After=network.target
   122|
   123|[Service]
   124|Type=simple
   125|ExecStart=/usr/local/bin/minimal-orchestrator.sh /path/to/project
   126|Restart=always
   127|RestartSec=15
   128|
   129|[Install]
   130|WantedBy=default.target
   131|```
   132|
   133|```bash
   134|# 启用
   135|systemctl --user daemon-reload
   136|systemctl --user enable minimal-orchestrator
   137|systemctl --user start minimal-orchestrator
   138|
   139|# 确保用户不注销时也运行
   140|loginctl enable-linger $(whoami)
   141|```
   142|
   143|## 14.6 完整编排器的演进路径
   144|
   145|```
   146|30行最小编排器
   147|  → +通信（bracket-paste）
   148|  → +活跃检测（screen hash）
   149|  → +systemd守护
   150|  → +铁律检查（git checkout恢复）
   151|  → +Rate Limit处理（冷却持久化）
   152|  → +快速崩溃保护（重启频率限制）
   153|  → +问题催促（等待人工时自动决策）
   154|  → 这就是一个从简单到复杂的自然演化过程
   155|```
   156|
   157|**关键原则**：每个特性都是因为真实踩坑才加的，不是预先设计的。
   158|
   159|## 14.7 小结
   160|
   161|从30行到数百行，编排器的演化路径清晰：
   162|
   163|1. **先让它跑起来**：最小可用的自动重启
   164|2. **加上通信**：Agent之间能传消息
   165|3. **加上检测**：知道Agent是否卡住
   166|4. **加上守护**：编排器本身不怕崩溃
   167|5. **加上约束**：铁律、冷却、崩溃保护
   168|6. **持续迭代**：每个新问题都是新特性的种子
   169|
   170|## 14.8 模式：剧本驱动编排
   171|
   172|在脚本化方式之外，agency-agents-zh展示了一种**剧本模式（Playbook）**——预定义的工作流，引导Agent完成复杂的多步骤任务：
   173|
   174|```markdown
   175|# playbook: feature-implementation.md
   176|## 触发条件
   177|当通过Sprint规划请求新功能时
   178|
   179|## 步骤
   180|1. **侦察Agent**：研究现有代码，识别集成点
   181|   - 输出：research-brief.md
   182|   - 关口：必须识别至少2个集成点
   183|   
   184|2. **架构师Agent**：设计实现方案
   185|   - 输入：research-brief.md
   186|   - 输出：impl-plan.md  
   187|   - 关口：必须覆盖错误处理+测试策略
   188|   
   189|3. **构建者Agent**：实现功能
   190|   - 输入：impl-plan.md
   191|   - 输出：代码变更
   192|   - 关口：所有测试通过 + lint清洁
   193|   
   194|4. **QA Agent**：审阅和测试
   195|   - 输入：代码变更
   196|   - 输出：qa-report.md
   197|   - 关口：无P0/P1问题
   198|   
   199|5. **部署Agent**：发布上线
   200|   - 输入：qa-report.md（已通过）
   201|   - 输出：部署确认
   202|```
   203|
   204|### 剧本 vs 脚本：何时使用哪种
   205|
   206|| 维度 | 脚本编排 | 剧本编排 |
   207||------|---------|---------|
   208|| 执行方式 | 确定性、自动化 | 引导式、半自动化 |
   209|| 灵活性 | 低（硬编码步骤） | 高（Agent解读步骤） |
   210|| 人工参与 | 最少 | 在质量关口处参与 |
   211|| 最适用于 | 重复性、定义明确的任务 | 复杂、需要判断的任务 |
   212|| 错误恢复 | 从检查点重启 | Agent自适应并重试 |
   213|
   214|### 在Bash中实现剧本
   215|
   216|```bash
   217|#!/bin/bash
   218|# playbook-runner.sh — 简单剧本执行器
   219|
   220|PLAYBOOK_DIR="./playbooks"
   221|CURRENT_STEP_FILE="/tmp/playbook_current_step"
   222|
   223|run_playbook() {
   224|    local playbook="$1"
   225|    local step=1
   226|    
   227|    if [ -f "$CURRENT_STEP_FILE" ]; then
   228|        step=$(cat "$CURRENT_STEP_FILE")
   229|        echo "[PLAYBOOK] 从步骤 $step 恢复"
   230|    fi
   231|    
   232|    while true; do
   233|        local step_file="${PLAYBOOK_DIR}/${playbook}/step${step}.md"
   234|        [ ! -f "$step_file" ] && echo "[PLAYBOOK] 所有步骤完成！" && break
   235|        
   236|        echo "[PLAYBOOK] 执行步骤 $step..."
   237|        send_to_architect "$(cat "$step_file")"
   238|        
   239|        # 等待Agent发出完成信号（通过SPRINT.md或文件创建）
   240|        wait_for_step_completion "$step"
   241|        
   242|        # 运行质量关口
   243|        if ! run_gate "$playbook" "$step"; then
   244|            echo "[PLAYBOOK] 步骤 $step 关口未通过，要求返工"
   245|            send_to_architect "步骤 $step 质量关口未通过，请返工。"
   246|            continue  # 重试同一步骤
   247|        fi
   248|        
   249|        echo "$((step + 1))" > "$CURRENT_STEP_FILE"
   250|        step=$((step + 1))
   251|    done
   252|    
   253|    rm -f "$CURRENT_STEP_FILE"
   254|}
   255|```
   256|
   257|## 14.9 下一步
   258|
   259|现在你有了基础，考虑添加：
   260|
   261|- **规则检查**：监控规则违规并采取行动
   262|- **Rate Limit处理**：实现智能冷却管理
   263|- **进度追踪**：监控项目进度，检测停滞
   264|- **跨项目协调**：在多个编排器之间共享资源
   265|- **自愈能力**：自动从常见故障模式中恢复
   266|- **剧本**：为常见任务类型定义可复用的多步骤工作流
   267|
   268|记住：好的编排器是打磨出来的，不是设计出来的。每次崩溃、每次429、每次Agent偷懒——它们都在告诉你下一步该改进什么。
   269|