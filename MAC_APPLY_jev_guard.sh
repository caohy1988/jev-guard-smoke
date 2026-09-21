#!/usr/bin/env bash
# Run on Mac machineId e327005d-8fbc-48ca-bfcc-e9911ce35494 only.
# Installs stock jev-guard for Codex seat; configures key without echoing secrets.
set -euo pipefail
echo "== jev-guard Mac apply (Codex only) =="
npm i -g jev-guard
command -v jev-guard >/dev/null

# Resolve key preference: TypeSafe / Vercel gateway from existing env files — never invent.
pick_key() {
  local f k v
  for f in "$HOME/.dsh/.env" "$HOME/.jev-guard/.env" "$HOME/.config/jev/.env"; do
    [[ -f "$f" ]] || continue
    # shellcheck disable=SC1090
    set -a; source "$f"; set +a
  done
  if [[ -n "${JEV_API_KEY:-}" ]]; then echo typesafe; return; fi
  if [[ -n "${AI_GATEWAY_API_KEY:-}" ]]; then echo gateway; return; fi
  if [[ -n "${VERCEL_OIDC_TOKEN:-}" ]]; then echo oidc; return; fi
  # OpenRouter alone is unsupported by stock package
  if [[ -n "${OPENROUTER_API_KEY:-}" ]]; then echo openrouter_only; return; fi
  echo none
}

KIND=$(pick_key)
case "$KIND" in
  typesafe)
    # jev-guard key reads argv; avoid shell history: use env already set
    node -e 'const {writeFileSync,mkdirSync}=require("fs");const {homedir}=require("os");const {join}=require("path");const p=join(homedir(),".jev-guard");mkdirSync(p,{recursive:true,mode:0o700});writeFileSync(join(p,"config.json"),JSON.stringify({jevApiKey:process.env.JEV_API_KEY},null,2)+"\n",{mode:0o600});console.log("wrote ~/.jev-guard/config.json (typesafe, mode 0600)")'
    ;;
  gateway)
    node -e 'const {writeFileSync,mkdirSync}=require("fs");const {homedir}=require("os");const {join}=require("path");const p=join(homedir(),".jev-guard");mkdirSync(p,{recursive:true,mode:0o700});writeFileSync(join(p,"config.json"),JSON.stringify({aiGatewayApiKey:process.env.AI_GATEWAY_API_KEY},null,2)+"\n",{mode:0o600});console.log("wrote ~/.jev-guard/config.json (gateway, mode 0600)")'
    ;;
  oidc)
    echo "VERCEL_OIDC_TOKEN present — leave in env (expires ~12h); skip config.json"
    ;;
  openrouter_only)
    echo "BLOCKER: only OPENROUTER_API_KEY found. Stock jev-guard needs TypeSafe or vck_ key."
    echo "Optional: install Lab OpenRouter System One shim from repo (not fleet default)."
    exit 2
    ;;
  *)
    echo "BLOCKER: no JEV_API_KEY / AI_GATEWAY_API_KEY / VERCEL_OIDC_TOKEN / OPENROUTER_API_KEY in known env files"
    exit 2
    ;;
esac

# Fail-open: do NOT export JEV_GUARD_FAIL_CLOSED
unset JEV_GUARD_FAIL_CLOSED || true

jev-guard install codex
echo "Run /hooks inside Codex to trust. Do NOT install claude/cursor fleet from this script."

# Quick smoke (if key usable)
if jev-guard check Bash '{"command":"ls"}' >/tmp/jev-guard-smoke-ls.txt 2>&1; then
  echo "smoke ls: $(head -1 /tmp/jev-guard-smoke-ls.txt)"
else
  echo "smoke ls exit=$? — see /tmp/jev-guard-smoke-ls.txt (may be OpenRouter blocker)"
fi
echo "Done. Vault: update Ship/builds/2026-09-20-jev-guard-smoke.md after Mac proof."
