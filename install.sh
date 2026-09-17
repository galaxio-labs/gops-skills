#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Install skills from gops-skills into agent skills directories.

Usage: $0 [skill-name] [options]

Arguments:
  skill-name    Name of the skill under skills/ to install.
                Omit to install the whole collection (default).

Options:
  --codex       Install to Codex (~/.codex/skills/)
  --claude      Install to Claude Code (~/.claude/skills/)
  --zed         Install to Zed (~/.agents/skills/)
  --all         Install to all available platforms (default)
  --dir <path>  Install to a custom skills directory
  --symlink     Symlink to the source instead of copying (local source only)
  -h, --help    Show this help message

Environment:
  GOPS_SKILLS_REF     Branch or tag to install (default: main)
  GOPS_SKILLS_SOURCE  Source GitHub repo (default: galaxio-labs/gops-skills)
EOF
}

skill_name=""
target_dirs=()
install_mode="copy"

while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help)
      usage
      exit 0
      ;;
    --codex)
      target_dirs+=("$HOME/.codex/skills")
      shift
      ;;
    --claude)
      target_dirs+=("$HOME/.claude/skills")
      shift
      ;;
    --zed)
      target_dirs+=("$HOME/.agents/skills")
      shift
      ;;
    --all)
      shift
      ;;
    --dir)
      if [[ -z "${2:-}" ]]; then
        echo "Error: --dir requires a path argument" >&2
        exit 2
      fi
      target_dirs+=("$2")
      shift 2
      ;;
    --symlink)
      install_mode="symlink"
      shift
      ;;
    -*)
      echo "Error: Unknown option $1" >&2
      usage
      exit 2
      ;;
    *)
      if [[ -z "$skill_name" ]]; then
        skill_name="$1"
      else
        echo "Error: Unexpected argument $1" >&2
        usage
        exit 2
      fi
      shift
      ;;
  esac
done

repo_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

src_dir=""
tmp_dir=""

cleanup() {
  if [[ -n "$tmp_dir" && -d "$tmp_dir" ]]; then
    rm -rf "$tmp_dir"
  fi
}
trap cleanup EXIT

# 目标目录：显式 --codex/--claude/--zed/--dir 优先；
# 否则 --all（或默认）自动探测已存在的平台目录，全都没有时回退到全部三个。
if [[ ${#target_dirs[@]} -eq 0 ]]; then
  if [[ -d "$HOME/.codex/skills" ]]; then
    target_dirs+=("$HOME/.codex/skills")
  fi
  if [[ -d "$HOME/.claude/skills" ]]; then
    target_dirs+=("$HOME/.claude/skills")
  fi
  if [[ -d "$HOME/.agents/skills" ]]; then
    target_dirs+=("$HOME/.agents/skills")
  fi
  if [[ ${#target_dirs[@]} -eq 0 ]]; then
    target_dirs+=("$HOME/.codex/skills" "$HOME/.claude/skills" "$HOME/.agents/skills")
  fi
fi

resolve_local_src() {
  local candidate
  if [[ -z "$skill_name" ]]; then
    # 安装整个 collection（顶层路由 + skills/）
    candidate="$repo_root"
  else
    candidate="$repo_root/skills/$skill_name"
  fi
  if [[ -d "$candidate" ]]; then
    src_dir="$candidate"
    return 0
  fi
  return 1
}

resolve_remote_src() {
  local ref="${GOPS_SKILLS_REF:-main}"
  local source_repo="${GOPS_SKILLS_SOURCE:-galaxio-labs/gops-skills}"
  tmp_dir="$(mktemp -d "${TMPDIR:-/tmp}/gops-skills.XXXXXX")"

  echo "Cloning $source_repo (ref: $ref)..."
  if ! git clone --depth 1 --branch "$ref" "https://github.com/$source_repo.git" "$tmp_dir/repo" 2>/dev/null; then
    if ! git clone --depth 1 "https://github.com/$source_repo.git" "$tmp_dir/repo" 2>/dev/null; then
      echo "Failed to clone $source_repo" >&2
      exit 1
    fi
  fi

  if [[ -z "$skill_name" ]]; then
    src_dir="$tmp_dir/repo"
  else
    src_dir="$tmp_dir/repo/skills/$skill_name"
    if [[ ! -d "$src_dir" ]]; then
      echo "Skill not found: $skill_name" >&2
      ls -1 "$tmp_dir/repo/skills/" 2>/dev/null >&2 || true
      exit 1
    fi
  fi
}

if ! resolve_local_src; then
  resolve_remote_src
fi

# 安装单个 skill 时，目标名 = skill_name；安装整个 collection 时 = gops-skills。
dest_name="${skill_name:-gops-skills}"

for target_base in "${target_dirs[@]}"; do
  dst_dir="$target_base/$dest_name"
  mkdir -p "$target_base"
  rm -rf "$dst_dir"

  if [[ "$install_mode" == "symlink" && "$src_dir" == "$repo_root"* && -z "$tmp_dir" ]]; then
    # 本地源且未走远程 clone：用符号链接指向 checkout
    ln -s "$src_dir" "$dst_dir"
  else
    cp -R "$src_dir" "$dst_dir"
  fi

  platform="custom"
  case "$target_base" in
    */.codex/skills) platform="codex" ;;
    */.claude/skills) platform="claude-code" ;;
    */.agents/skills) platform="zed" ;;
  esac

  echo "Installed: $dest_name"
  echo "Platform:  $platform"
  echo "Location:  $dst_dir"
  echo ""
done

echo "Installed files:"
find "$dst_dir" -type f 2>/dev/null | sed "s|$dst_dir||" | sed 's|^/|  - |' | head -20
