# enclawd

Claude Code for Engram Robotics, in two commands:

```sh
git clone git@github.com:Engram-Robotics-Company/enclawd.git
cd enclawd && ./setup.sh
```

Then:

- **`enclawd`** — Claude Code on the company AWS Bedrock account, with company
  skills and MCP servers from
  [claude-plugins](https://github.com/Engram-Robotics-Company/claude-plugins)
  enabled. Accepts all normal `claude` arguments (`enclawd -p "..."`, etc.).
- **`claude`** — completely unaffected. Your personal setup stays yours.
- **`enclawd doctor`** — verifies the whole chain (AWS auth → Bedrock access →
  model pins → marketplace → a real round-trip). Run it after setup, and any
  time something seems off.

## One-time steps setup can't do for you

1. AWS sign-in: when credentials are missing or expired, `enclawd` runs
   `aws sso login` for you — sign in with your Engram Google account.
   - **Locally**, your browser opens automatically.
   - **Over SSH / headless**, enclawd detects it and switches to the
     device-code flow: it prints a URL and code — open the URL in any browser
     (your laptop) and finish sign-in there. The default browser flow can't
     work remotely because its `127.0.0.1` callback lands on your laptop
     instead of the SSH host. Force either mode with `ENCLAWD_DEVICE_CODE=1`
     or `=0` if the detection guesses wrong.
   - Non-interactive runs fail with the exact command to run instead of
     hanging.
   - Mid-session expiry: locally Claude Code re-signs-in by itself
     (`awsAuthRefresh`); on remote machines that flow can't run, so the
     session shows an auth error — exit and re-run `enclawd`.
2. Inside `enclawd`, run `/mcp` and authenticate **linear, notion, figma**. OAuth is per-person and browser-based — once per server.
3. The first time you use Claude in a given repo it asks for folder trust. Once
   per folder.

Also worth knowing on Bedrock: there is no WebSearch, and no `/logout` — auth
lives on the AWS side.

## How it works

`setup.sh` symlinks `bin/enclawd` into `~/.local/bin` and installs Claude Code
if missing. That's all it does — **keep this clone**, and `git pull` to pick up
changes to the launcher or settings.

`enclawd` launches `claude` with `CLAUDE_CONFIG_DIR=~/.enclawd`, a separate
config profile. On every launch it deep-merges `settings.template.json` into
`~/.enclawd/settings.json` (managed keys win, your other tweaks survive). The
template carries:

- Bedrock env vars (`CLAUDE_CODE_USE_BEDROCK`, `AWS_PROFILE=engram-robotics`,
  `AWS_REGION=us-east-2`) — scoped to enclawd sessions, not your shell.
- Model pins, with `ANTHROPIC_MODEL` set to Sonnet as the everyday default
  (Opus is a `/model` away; it's a several-x cost difference).
- The `engram-tools` marketplace + `company-core` plugin, declared in settings
  so the install self-heals if the plugin cache is ever cleared.

Skills and MCP servers live in the `claude-plugins` repo and update on
everyone's machine automatically when that repo changes — nothing here needs
re-running for that.

## Maintainers

- **New skill / MCP server** → push to `claude-plugins`. Done.
- **Model migration or settings change** → edit `settings.template.json` here;
  employees get it on their next `git pull` of this repo. Verify exact
  inference profile IDs first: `enclawd doctor` lists what the account has.
- **Testing marketplace changes before pushing** →
  `ENCLAWD_MARKETPLACE_DIR=/path/to/claude-plugins enclawd`
  uses a local clone instead of GitHub. `ENCLAWD_CONFIG_DIR` and
  `ENCLAWD_SKIP_AWS_CHECK=1` exist for the same purpose.
- Governance is enforced AWS-side (dedicated account, per-employee roles,
  Bedrock model access as the allowlist, scoped IAM policy) — nothing in this
  repo is tamper-proof, and that's fine.
