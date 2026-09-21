# Lab OpenRouter System One shim (NOT fleet default)

Stock `leepokai/jev-guard@0.3.1` talks to TypeSafe (`api.typesafe.ai`) or Vercel AI Gateway (`vck_` / OIDC).
The harness OpenRouter key is rejected by those backends (401).

## Lab-only workaround

Patch `TYPESAFE_URL` resolution to:

```js
const TYPESAFE_URL = process.env.JEV_TYPESAFE_URL || "https://openrouter.ai/api/v1/systemone";
```

Then for Lab smoke / single Codex seat:

```bash
export JEV_TYPESAFE_URL=https://openrouter.ai/api/v1/systemone
export JEV_MODEL=typesafe/jev-1.13
export JEV_API_KEY="$OPENROUTER_API_KEY"   # never commit this
unset JEV_GUARD_FAIL_CLOSED                 # fail-open
# install THIS Lab build for Codex only — not Claude/Cursor fleet
```

Prefer a real TypeSafe or `vck_` key in `~/.jev-guard/config.json` (mode 0600) when available.
This shim matches the live harness `jev-route` OpenRouter System One path.

## Non-goals

- Not a fleet default
- Does not replace `grok-tmux-run` / stream-json / watchdog
- Never authorize merge / pay / send
