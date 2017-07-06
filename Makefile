BUILDER=genesis-builder
CONTAINER=genesis
# Run QEMU connecting VM ttyS1 to stdio
QEMU=qemu-system-x86_64 --enable-kvm -smp 2 -m 2048 -kernel output/genesis-vmlinuz -initrd output/genesis-initrd.img -serial null -serial stdio -monitor null
BASE_ARGS=rootflags=loop root=live:/genesis.iso rootfstype=auto ro vga=791 rd_NO_LUKS rd_NO_MD rd_NO_DM GENESIS_MODE=util console=tty1

.PHONY: help clean run-serial run-serial-notail run-tty1 run-tty1-notail

help:
	@echo 'Did you mean "make output"?'

docker-image:
	sudo docker build -t $(BUILDER) .
	touch docker-image

output: docker-image
	mkdir $@
	sudo docker run --name $(CONTAINER) --privileged=true -v $(PWD)/$@:/output $(BUILDER)
	sudo chown -R $(USER) $@

clean:
	sudo losetup -a | cut -d: -f1 | xargs -r -n 1 sudo losetup -d
	sudo rm -rf output docker-image
	sudo docker rm $(CONTAINER) || true
	sudo docker rmi $(BUILDER) || true

run-serial: output
	# Note: ttyS1 must come last for the serial port to get agetty on it.
	@echo This test should result in automatic tailing of log on both tty1 and ttyS1
	$(QEMU) -append "$(BASE_ARGS) console=ttyS1 GENESIS_AUTOTAIL"

run-serial-notail: output
	# Note: ttyS1 must come last for the serial port to get agetty on it.
	@echo This test should result in login prompts on both tty1 and ttyS1
	$(QEMU) -append "$(BASE_ARGS) console=ttyS1"

run-tty1: output
	@echo This test should result in automatic tailing of log on tty1 only
	$(QEMU) -append "$(BASE_ARGS) GENESIS_AUTOTAIL"

run-tty1-notail: output
	@echo This test should result in login prompt on tty1 only
	$(QEMU) -append "$(BASE_ARGS)"

