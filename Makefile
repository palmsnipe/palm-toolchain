SHELL := /bin/bash

.PHONY: prerequisites fetch bootstrap check example example-clean clean

prerequisites:
	@scripts/prerequisites.sh

fetch:
	@scripts/fetch-sources.sh

bootstrap: prerequisites
	@scripts/bootstrap.sh all

check:
	@scripts/check.sh

example:
	@$(MAKE) -C examples/hello-world

example-clean:
	@$(MAKE) -C examples/hello-world clean

clean:
	@echo "Generated state is contained in .toolchain/."
	@echo "It is ignored by Git and is not removed automatically."
