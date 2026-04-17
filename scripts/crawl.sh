#!/bin/bash
# crawl.sh — Fetch high-quality resources for agent-orchestration-book
# Runs every 4h via cron/orchestrator
# Only caches materials that can produce real insights — no dump, no filler

set -euo pipefail

BOOK_DIR="/home/ubuntu/agent-orchestration-book"
CACHE_DIR="$BOOK_DIR/.crawl-cache"
REPOS_DIR="$CACHE_DIR/repos"
PAPERS_DIR="$CACHE_DIR/papers"
BLOGS_DIR="$CACHE_DIR/blogs"
HN_DIR="$CACHE_DIR/hn"
META_DIR="$CACHE_DIR/meta"
LOG_FILE="$CACHE_DIR/crawl-log.txt"

MIRROR="https://gh-proxy.com/https://raw.githubusercontent.com"
API_MIRROR="https://gh-proxy.com/https://api.github.com"

# Monitored repos — agent orchestration related, high quality
MONITOR_REPOS=(
  "Jedward23/Tmux-Orchestrator"
  "ComposioHQ/agent-orchestrator"
  "jayminwest/overstory"
  "jnMetaCode/agency-agents-zh"
  "langchain-ai/langgraph"
  "openai/openai-agents-python"
  "crewAIInc/crewAI"
  "autogen-ai/autogen"
  "microsoft/semantic-kernel"
  "daveshap/OpenAI_Agent_Swarm"
  "kyegomez/swarms"
  "cameronmdotcom/AutoAgent"
  "joonspk-research/generative_agents"
  "Significant-Gravitas/AutoGPT"
)

# arXiv search queries
ARXIV_QUERIES=(
  "multi+agent+orchestration"
  "LLM+agent+coordination"
  "prompt+engineering+automated+agents"
  "agent+communication+protocol"
  "fault+tolerant+agent+systems"
)

# HN search queries
HN_QUERIES=(
  "agent orchestration"
  "multi agent LLM"
  "AI agent framework"
  "agent workflow"
)

# Max age for cache in days
MAX_CACHE_DAYS=7

mkdir -p "$REPOS_DIR" "$PAPERS_DIR" "$BLOGS_DIR" "$HN_DIR" "$META_DIR"

log() {
  echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] $1" >> "$LOG_FILE"
  echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] $1"
}

# --- GitHub Repos ---
crawl_repos() {
  log "=== Crawling GitHub repos ==="
  for repo in "${MONITOR_REPOS[@]}"; do
    safe_name=$(echo "$repo" | tr '/' '_')
    readme_file="$REPOS_DIR/${safe_name}_README.md"
    meta_file="$REPOS_DIR/${safe_name}_meta.json"
    
    # Skip if cached within MAX_CACHE_DAYS
    if [[ -f "$readme_file" ]]; then
      age=$(( ( $(date +%s) - $(stat -c %Y "$readme_file") ) / 86400 ))
      if [[ $age -lt $MAX_CACHE_DAYS ]]; then
        log "  SKIP $repo (cached ${age}d ago)"
        continue
      fi
    fi

    log "  FETCH $repo"
    
    # Fetch README
    curl -sfL --max-time 15 "${MIRROR}/${repo}/main/README.md" -o "$readme_file" 2>/dev/null || \
    curl -sfL --max-time 15 "${MIRROR}/${repo}/master/README.md" -o "$readme_file" 2>/dev/null || {
      log "  FAIL $repo README"
      rm -f "$readme_file"
      continue
    }

    # Fetch repo metadata (stars, description, updated_at)
    curl -sfL --max-time 15 "${API_MIRROR}/repos/${repo}" -o "$meta_file" 2>/dev/null || {
      log "  FAIL $repo metadata"
      rm -f "$meta_file"
    }

    sleep 1  # rate limit courtesy
  done
}

# --- arXiv Papers ---
crawl_papers() {
  log "=== Crawling arXiv papers ==="
  for query in "${ARXIV_QUERIES[@]}"; do
    safe_query=$(echo "$query" | tr '+' '_')
    result_file="$PAPERS_DIR/${safe_query}.xml"
    
    # Skip if cached within MAX_CACHE_DAYS
    if [[ -f "$result_file" ]]; then
      age=$(( ( $(date +%s) - $(stat -c %Y %Y "$result_file") ) / 86400 ))
      if [[ $age -lt $MAX_CACHE_DAYS ]]; then
        log "  SKIP arxiv:$query (cached)"
        continue
      fi
    fi

    log "  FETCH arxiv:$query"
    curl -sfL --max-time 20 "http://export.arxiv.org/api/query?search_query=all:${query}&sortBy=submittedDate&sortOrder=descending&max_results=15" \
      -o "$result_file" 2>/dev/null || {
      log "  FAIL arxiv:$query"
      rm -f "$result_file"
    }
    
    sleep 3  # arXiv rate limit
  done
}

# --- HN Discussions ---
crawl_hn() {
  log "=== Crawling HN discussions ==="
  for query in "${HN_QUERIES[@]}"; do
    safe_query=$(echo "$query" | tr ' ' '_')
    result_file="$HN_DIR/${safe_query}.json"
    
    if [[ -f "$result_file" ]]; then
      age=$(( ( $(date +%s) - $(stat -c %Y "$result_file") ) / 86400 ))
      if [[ $age -lt $MAX_CACHE_DAYS ]]; then
        log "  SKIP hn:$query (cached)"
        continue
      fi
    fi

    log "  FETCH hn:$query"
    curl -sfL --max-time 15 "https://hn.algolia.com/api/v1/search?query=${query}&tags=story&hitsPerPage=20" \
      -o "$result_file" 2>/dev/null || {
      log "  FAIL hn:$query"
      rm -f "$result_file"
    }
    
    sleep 1
  done
}

# --- Tech Blogs ---
crawl_blogs() {
  log "=== Crawling tech blogs ==="
  
  # Anthropic blog
  curl -sfL --max-time 15 "https://www.anthropic.com/research" -o "$BLOGS_DIR/anthropic_index.html" 2>/dev/null || true
  
  # OpenAI blog
  curl -sfL --max-time 15 "https://openai.com/blog" -o "$BLOGS_DIR/openai_index.html" 2>/dev/null || true
  
  # LangChain blog
  curl -sfL --max-time 15 "https://blog.langchain.dev" -o "$BLOGS_DIR/langchain_index.html" 2>/dev/null || true
  
  # CrewAI blog
  curl -sfL --max-time 15 "https://blog.crewai.com" -o "$BLOGS_DIR/crewai_index.html" 2>/dev/null || true
  
  # SweRex / AgentBench / related research
  curl -sfL --max-time 15 "https://gh-proxy.com/https://raw.githubusercontent.com/SWE-bench/SWE-bench/main/README.md" \
    -o "$REPOS_DIR/SWE-bench_README.md" 2>/dev/null || true
  curl -sfL --max-time 15 "https://gh-proxy.com/https://raw.githubusercontent.com/OpenBMB/AgentBench/main/README.md" \
    -o "$REPOS_DIR/AgentBench_README.md" 2>/dev/null || true

  log "  Blog crawling done"
}

# --- Summary ---
crawl_summary() {
  log "=== Crawl summary ==="
  local repos_count=$(find "$REPOS_DIR" -name "*.md" 2>/dev/null | wc -l)
  local papers_count=$(find "$PAPERS_DIR" -name "*.xml" 2>/dev/null | wc -l)
  local hn_count=$(find "$HN_DIR" -name "*.json" 2>/dev/null | wc -l)
  local blogs_count=$(find "$BLOGS_DIR" -name "*.html" 2>/dev/null | wc -l)
  log "  Cached: ${repos_count} repos, ${papers_count} paper queries, ${hn_count} HN queries, ${blogs_count} blog pages"
}

# --- Main ---
log "===== Crawl cycle starting ====="
crawl_repos
crawl_papers
crawl_hn
crawl_blogs
crawl_summary
log "===== Crawl cycle complete ====="
