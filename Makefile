SHELL := /bin/bash

.PHONY: prerequisites fetch bootstrap check clean

prerequisites:
	@scripts/prerequisites.sh

fetch:
	@scripts/fetch-sources.sh

bootstrap: prerequisites
	@scripts/bootstrap.sh all

check:
	@scripts/check.sh

clean:
	@echo "Generated state is contained in .toolchain/."
	@echo "It is ignored by Git and is not removed automatically."
