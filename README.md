# nanovm

Minimal Linux VM (Alpine + QEMU) or Docker container for running **registered agents** on macOS Apple Silicon.

## Prerequisites

```bash
brew install qemu cdrtools   # QEMU path only
# Docker Desktop            # Docker path only
cp .env.example .env         # optional; required for `news` agent
```

---

## Path 1 — QEMU VM (full nanovm + multi-agent)

### First-time boot

```bash
cd /path/to/nanovm
make fresh          # download Alpine, reset disk, cloud-init seed, start VM
make status         # wait until "SSH: ok" (can take 1–2 min)
make deploy-agents  # copy platform/ + agents/ into guest, install nanovm-run
```

### Use agents on the VM

```bash
make vm-list              # list registered agents
make vm-run AGENT=example # smoke test (no secrets)
make vm-news              # Slack news (needs SLACK_WEBHOOK_URL in .env)
make ssh                  # shell on guest; then: nanovm-run run example
```

Inside the VM:

```bash
nanovm-run list
nanovm-run run news
nanovm-run sync-schedules   # install cron from manifest schedule: blocks
nanovm-run daemon <id>      # if manifest mode is daemon
nanovm-run stop <id>
```

Agent cron is configured in each `agents/<id>/manifest.yaml`:

```yaml
schedule:
  cron: "0 8 * * 1-5"
  timezone: America/Chicago
  enabled: true
```

After editing, run `make deploy-agents` or `make vm-sync-schedules`.

Logs: `/var/log/nanovm/<agent-id>.log`

### Day-to-day

```bash
make up                 # start VM if stopped (regenerates seed.iso)
make down               # stop QEMU
make deploy-agents      # after you change agents/ or platform/
```

---

## Path 2 — Docker (quick, no VM)

```bash
cp .env.example .env
make docker-build
make docker-news        # one-shot Slack post (legacy single-agent image)
make docker-up          # optional background container
make docker-shell
make docker-down
```

---

## Path 3 — Run on Mac without VM

Same agent code as the guest:

```bash
cp .env.example .env
make news               # runs agents/news via platform/nanovm-run on host
```

---

## Add a new agent

1. Create `agents/<id>/manifest.yaml`, `run.sh`, and any code.
2. `chmod +x agents/<id>/run.sh`
3. QEMU: `make deploy-agents` then `make vm-run AGENT=<id>`
4. Host test: `NANOVM_ROOT=. NANOVM_ENV_FILE=.env ./platform/nanovm-run run <id>`

See `agents/example/` for a minimal manifest.

---

## Layout

| Path | Role |
|------|------|
| `platform/nanovm-run` | Dispatcher (`list`, `run`, `daemon`, `stop`) |
| `agents/*/` | One folder per agent + `manifest.yaml` |
| `.nanovm/` | VM disk, SSH keys, seed (gitignored) |
| `.env` | Secrets (gitignored) |

## VM resources

- 512 MiB RAM, 2 vCPUs, SSH on `localhost:2222` (user `alpine`)
