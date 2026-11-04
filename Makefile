.PHONY: deps image seed up down ssh status clean deploy-agent deploy-agents news vm-list vm-run vm-news vm-sync-schedules reset-disk fresh docker-build docker-up docker-down docker-shell docker-news

ALPINE_IMAGE ?= alpine-3.24.2-aarch64-cloudinit-r2.qcow2
ARCH ?= aarch64
VM_DIR := .nanovm
BASE_DISK := $(VM_DIR)/alpine-base.qcow2
DISK := $(VM_DIR)/alpine-disk.qcow2
SEED := $(VM_DIR)/seed.iso
PIDFILE := $(VM_DIR)/qemu.pid
SSH_PORT ?= 2222
AGENT ?= example

deps:
	@command -v qemu-system-aarch64 >/dev/null || (echo "Install QEMU: brew install qemu"; exit 1)
	@command -v mkisofs >/dev/null || command -v genisoimage >/dev/null || (echo "Install cdrtools: brew install cdrtools"; exit 1)

image: deps
	@NANOVM_IMAGE="$(ALPINE_IMAGE)" ./scripts/ensure-image.sh "$(VM_DIR)"

reset-disk: image
	@chmod +x scripts/reset-disk.sh
	@ALPINE_IMAGE="$(ALPINE_IMAGE)" ./scripts/reset-disk.sh

fresh: down reset-disk seed up

seed:
	@./scripts/make-seed.sh "$(VM_DIR)" "$(SEED)"

up: image seed
	@SSH_PORT=$(SSH_PORT) ./scripts/run-vm.sh "$(VM_DIR)" "$(DISK)" "$(SEED)" "$(PIDFILE)" "$(SSH_PORT)"

down:
	@./scripts/stop-vm.sh "$(PIDFILE)"

ssh:
	@ssh -p $(SSH_PORT) -i $(VM_DIR)/id_ed25519 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null alpine@127.0.0.1

status:
	@./scripts/status.sh "$(PIDFILE)" "$(SSH_PORT)" "$(VM_DIR)"

clean:
	@rm -rf $(VM_DIR)

deploy-agent: deploy-agents

deploy-agents:
	@chmod +x scripts/deploy-agents.sh scripts/install-vm-python-deps.sh platform/nanovm-run agents/*/*.sh
	@./scripts/deploy-agents.sh

install-vm-deps:
	@chmod +x scripts/install-vm-python-deps.sh
	@./scripts/install-vm-python-deps.sh

vm-list:
	@ssh -p $(SSH_PORT) -i $(VM_DIR)/id_ed25519 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
		alpine@127.0.0.1 nanovm-run list

vm-run:
	@chmod +x scripts/vm-run-agent.sh
	@./scripts/vm-run-agent.sh $(AGENT)

vm-news:
	@$(MAKE) vm-run AGENT=news

vm-sync-schedules:
	@ssh -p $(SSH_PORT) -i $(VM_DIR)/id_ed25519 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
		alpine@127.0.0.1 nanovm-run sync-schedules

news: vm-news

docker-build:
	docker compose build

docker-up:
	docker compose up -d

docker-down:
	docker compose down

docker-shell:
	docker compose exec nanovm shell

docker-news:
	docker compose run --rm nanovm news
