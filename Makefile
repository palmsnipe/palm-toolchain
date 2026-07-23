SHELL := /bin/bash

.PHONY: prerequisites fetch bootstrap install-sdk check example example-clean clean

prerequisites:
	@scripts/prerequisites.sh

fetch:
	@scripts/fetch-sources.sh

bootstrap: prerequisites
	@scripts/bootstrap.sh all

install-sdk:
	@scripts/install-sdk.sh "$(PALM_SDK_SOURCE)"

check:
	@scripts/check.sh

example:
	@$(MAKE) -C examples/hello-world

example-clean:
	@$(MAKE) -C examples/hello-world clean

clean:
	@echo "Generated state is contained in .toolchain/."
	@echo "It is ignored by Git and is not removed automatically."
