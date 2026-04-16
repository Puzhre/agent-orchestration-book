# Glossary

## Orchestrator Core Concepts

### Agent
- **Definition**: An AI program capable of autonomously executing tasks
- **Characteristics**: Goal-oriented, autonomous decision-making, environment-aware
- **Classification**:
  - Hermes Agent: Master Agent, responsible for strategy formulation
  - Codex Agent: Execution Agent, responsible for code implementation
  - Worker Agent: Worker Agent, responsible for specific tasks

### Orchestrator
- **Definition**: A control system that coordinates multiple Agents working together
- **Core Functions**: Task allocation, resource management, fault recovery, progress monitoring
- **Architecture Patterns**:
  - Dual-Agent Loop: Hermes + Codex alternating work
  - Orchestrator-Worker: Hierarchical management structure
  - Hub-and-Spoke: Central辐射 (hub-and-spoke) structure

### Orchestration
- **Definition**: The process of decomposing complex tasks into subtasks and executing them in logical order
- **Key Elements**:
  - Task Decomposition
  - Dependency Management
  - Concurrency Control
  - Fault Tolerance

## Architecture Terminology

### Session Management
- **Definition**: Managing the lifecycle of Agent runtime sessions
- **Implementation Methods**:
  - tmux sessions: Linux terminal multiplexing
  - systemd services: System daemons
  - Process groups: Collections of related processes

### Isolation Mechanism
- **Definition**: Mechanisms that prevent different Agents or tasks from interfering with each other
- **Types**:
  - **Process Isolation**: Separate process spaces
  - **File System Isolation**: Independent file views
  - **Network Isolation**: Independent network namespaces
  - **Resource Isolation**: CPU, memory limits

### Communication Mechanism
- **Definition**: How information is passed between Agents
- **Five Communication Patterns**:
  1. **Bracket-Paste**: Terminal clipboard interaction
  2. **Mail System**: Structured message passing
  3. **File Coordination**: Information exchange via files
  4. **MCP Memory**: Model Context Protocol
  5. **Copy-Paste Handoff**: Explicit information passing

## Fault Tolerance and Recovery Terminology

### Watchdog
- **Definition**: A daemon that monitors system health status
- **Hierarchy**:
  - L1: Process-level Watchdog (detects process liveness)
  - L2: Function-level Watchdog (detects functional correctness)
  - L3: System-level Watchdog (detects overall operation)
  - L4: Business-level Watchdog (detects business logic)

### Fault Recovery
- **Definition**: The automatic repair process after a system failure
- **Recovery Strategies**:
  - **Fast Crash Protection**: Immediate restart
  - **Progressive Remediation**: Gradually escalating handling intensity
  - **Self-Scheduling Chain**: Automatically scheduling recovery tasks

### Rate Limit
- **Definition**: A mechanism that controls the frequency of API calls
- **Handling Strategies**:
  - Exponential backoff: Gradually increasing wait time
  - Request batching: Processing requests in batches
  - Caching mechanism: Reducing repeated calls

## Knowledge Management Terminology

### LEARNINGS.md
- **Definition**: A document recording system runtime experience and lessons learned
- **Content Structure**:
  - Timestamp: When the event occurred
  - Problem Description: Fault or phenomenon description
  - Root Cause Analysis: Deep-rooted cause analysis
  - Solution: Effective resolution method
  - Prevention Measures: Methods to avoid recurrence

### Mulch Knowledge Base
- **Definition**: A structured knowledge management system
- **Characteristics**:
  - Version control: Git-managed
  - Categorical organization: Topic-based classification
  - Search functionality: Quick retrieval
  - Update mechanism: Automatic synchronization

### MCP (Model Context Protocol)
- **Definition**: Model Context Protocol, used for knowledge sharing between Agents
- **Functions**:
  - Memory storage: Persisting Agent memories
  - Context passing: Runtime information sharing
  - Tool integration: External tool invocation

## Deployment and Operations Terminology

### systemd Services
- **Definition**: Linux system daemon manager
- **Key Features**:
  - Auto-start: Automatically runs at system startup
  - Crash recovery: Automatically restarts after process crash
  - Resource limits: CPU, memory, and other resource controls
  - Status monitoring: Real-time service status

### tmux Sessions
- **Definition**: Terminal multiplexer supporting multiple terminal sessions
- **Role in the Orchestrator**:
  - Session persistence: Terminal sessions remain uninterrupted
  - Session recovery: Reconnection after disconnection
  - Multiplexing: Managing multiple Agents from a single terminal

### Self-Check Mechanism
- **Definition**: A mechanism for the system to self-inspect and verify
- **Check Types**:
  - **Health Check**: System running status
  - **Functional Check**: Whether core functions are normal
  - **Data Check**: Data integrity verification
  - **Configuration Check**: Configuration file validity

## Design Pattern Terminology

### Self-Scheduling
- **Definition**: A mechanism for Agents to autonomously arrange subsequent tasks
- **Implementation Methods**:
  - Timed wakeup: Background process periodically wakes up
  - Event-triggered: Specific events trigger scheduling
  - Condition-triggered: Scheduling when conditions are met

### Iron Law Guard
- **Definition**: A guardian mechanism that enforces system constraints
- **How It Works**:
  - Periodic checking: Verifying whether constraints have been modified
  - Automatic recovery: Restoring modified files from Git
  - Warning notifications: Sending warning messages to Agents

### Progressive Remediation
- **Definition**: A recovery strategy that gradually escalates handling intensity
- **Recovery Levels**:
  - Level 0: Warning (may just be thinking)
  - Level 1: Nudge (may be waiting for input)
  - Level 2: Triage (may be truly stuck)
  - Level 3: Kill (confirmed unrecoverable)

## Architecture Pattern Terminology

### Dual-Agent Loop
- **Definition**: A pattern where two Agents alternate their work
- **Workflow**:
  1. Agent A formulates strategy
  2. Agent B executes tasks
  3. Agent A evaluates results
  4. Agent B adjusts execution
  5. Repeat the cycle

### Orchestrator-Worker
- **Definition**: A hierarchical management architecture pattern
- **Role Division**:
  - Orchestrator: Strategy formulation, task allocation
  - Worker: Specific execution, status feedback

### Hub-and-Spoke
- **Definition**: A hub-and-spoke architecture pattern
- **Structural Characteristics**:
  - Hub: Central coordinator
  - Spoke: Peripheral execution nodes
  - Communication: All nodes communicate through the Hub

## Tools and Technology Terminology

### Git Worktree
- **Definition**: Git's branch isolation mechanism
- **Application in the Orchestrator**:
  - Concurrent development: Working on multiple branches simultaneously
  - Isolated environments: Independent development on different branches
  - Quick switching: Fast switching between branches

### ZFC Health Check
- **Definition**: Zero Fault Correction health check mechanism
- **Check Dimensions**:
  - Z (Zero): Zero fault target
  - F (Fault): Fault detection
  - C (Correction): Fault correction

### Adaptive Scheduling
- **Definition**: Dynamically adjusting scheduling strategies based on system state
- **Scheduling Strategies**:
  - Load-based: Adjusting based on task volume
  - Priority-based: Task priority ranking
  - Resource-based: Scheduling based on resource availability

## Performance Optimization Terminology

### Resource Utilization
- **Definition**: The efficiency of system resource usage
- **Key Metrics**:
  - CPU utilization: Computing resource usage rate
  - Memory utilization: Memory usage efficiency
  - Disk I/O: Disk read/write efficiency
  - Network bandwidth: Network usage efficiency

### Throughput
- **Definition**: The number of tasks completed per unit of time
- **Optimization Methods**:
  - Batch processing: Processing tasks in batches
  - Parallelization: Executing tasks in parallel
  - Caching mechanism: Reducing repeated computation

### Response Time
- **Definition**: The time from request to response
- **Components**:
  - Network latency: Transmission time
  - Processing time: Computation time
  - Wait time: Queue waiting time

## Security Terminology

### Session Isolation
- **Definition**: Data isolation between different sessions
- **Implementation Methods**:
  - Independent environments: Each session has an independent environment
  - Access control: Access permission control
  - Data encryption: Sensitive data encryption

### File Locking
- **Definition**: A mechanism to prevent concurrent file access
- **Lock Types**:
  - Mutex lock: Only one process can access at a time
  - Shared lock: Multiple processes can read simultaneously
  - Conditional lock: Locking only when conditions are met

### Access Control
- **Definition**: A mechanism that controls user or process access to resources
- **Control Methods**:
  - Role-Based Access Control (RBAC)
  - Attribute-Based Access Control (ABAC)
  - Discretionary Access Control (DAC)

## Monitoring and Alerting Terminology

### Metrics Monitoring
- **Definition**: Real-time monitoring of system runtime metrics
- **Monitoring Metrics**:
  - System metrics: CPU, memory, disk
  - Application metrics: Response time, error rate
  - Business metrics: Task completion rate, success rate

### Alert Threshold
- **Definition**: The critical metric value that triggers an alert
- **Threshold Types**:
  - Static threshold: Fixed value
  - Dynamic threshold: Adjusted based on historical data
  - Trend threshold: Based on change trends

### Log Aggregation
- **Definition**: Collecting and centrally managing system logs
- **Functions**:
  - Log collection: Collecting logs from multiple sources
  - Log storage: Centralized storage and management
  - Log analysis: Searching and analyzing logs

## Extensibility Terminology

### Plugin Architecture
- **Definition**: An architecture that supports dynamic loading of functional modules
- **Characteristics**:
  - Hot-pluggable: Loading/unloading at runtime
  - Standardized interfaces: Unified plugin interface
  - Version management: Plugin version control

### Microservices Architecture
- **Definition**: An architecture that decomposes a system into multiple independent services
- **Advantages**:
  - Independent deployment: Services can be deployed independently
  - Technology heterogeneity: Different services can use different technologies
  - Elastic scaling: Can scale independently

### Horizontal Scaling
- **Definition**: Scaling a system by adding more nodes
- **Implementation Methods**:
  - Load balancing: Distributing requests across multiple nodes
  - Data sharding: Distributed data storage
  - Stateless design: Making services stateless

## Summary

This glossary covers key terminology related to AI Agent orchestrator core concepts, architecture patterns, technical implementations, and more. These terms form the foundation for understanding and implementing orchestrator systems. It is recommended to continuously deepen your understanding of these concepts through learning and practice.

As technology evolves, this glossary will be continuously updated and refined to reflect the latest technology trends and practical experience.
