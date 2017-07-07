BUILDER=genesis-builder
CONTAINER=genesis
UPSTREAM=tumblr/genesis-builder

# Fingerprint OS
OS=$(shell uname -s)

ifeq ($(OS),Darwin)
# Mac should never need sudo
SUDO=
else ifeq ($(OS),Linux)
# Check if Docker needs sudo
ifeq ($(shell docker info 2>/dev/null; echo $$?),1)
SUDO=sudo
endif
else
# Unsupported OS
SUDO=false
endif

.PHONY: help clean cleanup all-targets

help: .test-docker
	@echo
	@echo "try 'make output' to build everything from scratch"
	@echo "or 'make output-upstream' to use the $(UPSTREAM) Docker image"
	@echo

.test-docker:
ifeq ($(SUDO),sudo)
	@echo 'WARNING: docker appears to need sudo...'
	@echo
else ifeq ($(SUDO),false)
	@echo 'ERROR: $(OS) is unsupported'
	@false
endif
	@echo 'Testing Docker:'
	$(SUDO) docker info >/dev/null
	touch $@

.docker-image: .test-docker
	$(SUDO) docker build -t $(BUILDER) .
	touch .docker-image

output: .docker-image
	mkdir $@
	$(SUDO) docker rm $(CONTAINER) || true
	$(SUDO) docker run --rm --name $(CONTAINER) --privileged=true -v $(PWD)/$@:/output $(BUILDER)
	$(SUDO) chown -R $(USER) $@

output-upstream: .test-docker
	mkdir $@
	$(SUDO) docker rm $(CONTAINER) || true
	$(SUDO) docker pull $(UPSTREAM)
	$(SUDO) docker run --rm --name $(CONTAINER) --privileged=true -v $(PWD)/$@:/output $(UPSTREAM)
	$(SUDO) chown -R $(USER) $@

clean:
	$(SUDO) docker rm $(CONTAINER) || true
	$(SUDO) docker rmi $(BUILDER) || true
	rm -rf output output-upstream .docker-image .test-docker

cleanup:
ifeq ($(OS),Linux)
	sudo losetup -a | grep /genesis/bootcd/genesis.iso | cut -d: -f1 | xargs -t -r -n 1 sudo losetup -d
else
	@echo WARNING: If you see this, your Linux VM might have a dangling loop device still configured
	@sleep 1
endif

all-targets: clean output-upstream output cleanup

# The remaining targets are Linux specific
ifeq ($(OS),Linux)
.PHONY: test-serial test-serial-notail test-tty1 test-tty1-notail

# Run QEMU connecting VM ttyS1 to stdio
# ctrl-C will kill the VM
QEMU=qemu-system-x86_64 --enable-kvm -smp 2 -m 2048 -kernel output/genesis-vmlinuz -initrd output/genesis-initrd.img -serial null -serial stdio -monitor null
BASE_ARGS=rootflags=loop root=live:/genesis.iso rootfstype=auto ro vga=791 rd_NO_LUKS rd_NO_MD rd_NO_DM GENESIS_MODE=util console=tty1

test-serial: output
	# Note: ttyS1 must come last for the serial port to get agetty on it.
	@echo This test should result in automatic tailing of log on both tty1 and ttyS1
	$(QEMU) -append "$(BASE_ARGS) console=ttyS1 GENESIS_AUTOTAIL"

test-serial-notail: output
	# Note: ttyS1 must come last for the serial port to get agetty on it.
	@echo This test should result in login prompts on both tty1 and ttyS1
	$(QEMU) -append "$(BASE_ARGS) console=ttyS1"

test-tty1: output
	@echo This test should result in automatic tailing of log on tty1 only
	$(QEMU) -append "$(BASE_ARGS) GENESIS_AUTOTAIL"

test-tty1-notail: output
	@echo This test should result in login prompt on tty1 only
	$(QEMU) -append "$(BASE_ARGS)"
endif
