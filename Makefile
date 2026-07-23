SHELL := /bin/bash

.PHONY: prerequisites fetch bootstrap-core bootstrap install-sdk check-core \
	check-arm check-sdk check example example-clean clean

prerequisites:
	@scripts/prerequisites.sh

fetch:
	@scripts/fetch-sources.sh

bootstrap-core: prerequisites
	@scripts/bootstrap.sh compiler
	@scripts/bootstrap.sh arm
	@scripts/bootstrap.sh debugger

bootstrap: prerequisites
	@scripts/bootstrap.sh all

install-sdk:
	@scripts/install-sdk.sh "$(PALM_SDK_SOURCE)"

check-core:
	@scripts/check-core.sh

check-arm:
	@scripts/check-arm.sh

check-sdk:
	@scripts/check-sdk.sh

check: check-core check-arm check-sdk
	@echo "Toolchain checks passed."

example:
	@$(MAKE) -C examples/hello-world

example-clean:
	@$(MAKE) -C examples/hello-world clean

clean:
	@echo "Generated state is contained in .toolchain/."
	@echo "It is ignored by Git and is not removed automatically."
