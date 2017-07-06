# Testing Genesis

## Testing Genesis framework and tasks

See [Genesis test environment](testenv/)

## Testing the live Linux environment

At one point, changes were made to how Genesis gets run in the live Linux
environment with the goal of improving serial console behavior.

Verification of those changes involved booting the live Linux environment with
four different variations on kernel command line arguments to verify behavior.

Those variations are (excerpted here from the [Makefile](Makefile)):
```make
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
```
