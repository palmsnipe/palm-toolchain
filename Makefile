SHELL := /bin/bash

.PHONY: setup prerequisites fetch bootstrap-core bootstrap debugger install-sdk \
	check-core check-arm check-sdk check example example-clean clean

setup: prerequisites
	@scripts/bootstrap.sh all

prerequisites:
	@scripts/prerequisites.sh

fetch:
	@scripts/fetch-sources.sh

bootstrap-core: prerequisites
	@scripts/bootstrap.sh core

bootstrap: setup

debugger: prerequisites
	@scripts/bootstrap.sh debugger

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
	@state="$${PALM_TOOLCHAIN_STATE:-$(CURDIR)/.toolchain}"; \
		case "$$state" in ""|"/"|"."|"..") \
			echo "Refusing unsafe toolchain state path: $$state" >&2; exit 1 ;; \
		esac; \
		rm -rf -- "$$state/build"; \
		echo "Removed $$state/build; downloads, sources, SDK, and installed tools were retained."
	@$(MAKE) -C examples/hello-world clean
