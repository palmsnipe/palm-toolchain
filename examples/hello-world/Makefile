SHELL := /bin/bash

ROOT := $(CURDIR)
TOOLCHAIN_ROOT := $(abspath $(ROOT)/../..)
PREFIX := $(if $(PALM_TOOLCHAIN_PREFIX),$(PALM_TOOLCHAIN_PREFIX),$(TOOLCHAIN_ROOT)/.toolchain/prefix)
SDK := $(PREFIX)/palmdev/sdk-5r3/include
CC := $(PREFIX)/bin/m68k-none-elf-gcc
OBJCOPY := $(PREFIX)/bin/m68k-none-elf-objcopy
SIZE := $(PREFIX)/bin/m68k-none-elf-size
PILRC := $(PREFIX)/bin/pilrc
BUILD_PRC := $(PREFIX)/bin/build-prc

APP_NAME := Hello World
APP_ID := HelloWorld
APP_CREATOR := Helo
APP_TYPE := appl
BUILD_DIR := $(ROOT)/build
ELF := $(BUILD_DIR)/code0001.68k.elf
CODE := $(BUILD_DIR)/code0001.bin
RESOURCES := $(BUILD_DIR)/HelloWorld.ro
PRC := $(BUILD_DIR)/$(APP_ID).prc
OBJECTS := $(BUILD_DIR)/main.o $(BUILD_DIR)/startup.o
DEPS := $(OBJECTS:.o=.d)

SDK_INCLUDES := -isystem$(SDK) -isystem$(SDK)/Core \
	-isystem$(SDK)/Core/Hardware -isystem$(SDK)/Core/System \
	-isystem$(SDK)/Core/UI -isystem$(SDK)/Dynamic \
	-isystem$(SDK)/Libraries
ABI_FLAGS := -Wno-multichar -m68000 -mno-align-int -mpcrel -fpic \
	-fshort-enums -mshort
CFLAGS := $(ABI_FLAGS) -Os -Wall -Wextra -Wno-unused-parameter \
	-Wno-old-style-declaration -MMD -MP -ffunction-sections -fdata-sections \
	-I$(ROOT)/resources $(SDK_INCLUDES)
LDFLAGS := $(ABI_FLAGS) -Os -nostartfiles -Wl,--gc-sections \
	-Wl,-T,$(ROOT)/linker.lkr -Wl,-Map,$(BUILD_DIR)/$(APP_ID).map

.PHONY: all test clean

all: $(PRC)

$(BUILD_DIR):
	@mkdir -p $@

$(BUILD_DIR)/%.o: src/%.c resources/resource.h | $(BUILD_DIR)
	@test -x "$(CC)" || { echo "Missing Palm compiler; run 'make bootstrap' from $(TOOLCHAIN_ROOT)" >&2; exit 1; }
	$(CC) $(CFLAGS) -c $< -o $@

$(ELF): $(OBJECTS) linker.lkr
	$(CC) -o $@.stage1 $(LDFLAGS) -Wl,--emit-relocs $(OBJECTS)
	node $(TOOLCHAIN_ROOT)/tools/generate-m68k-relocs.mjs \
		$@.stage1 $(BUILD_DIR)/reloc_offsets.s $(PREFIX)/bin/m68k-none-elf-readelf
	$(CC) $(ABI_FLAGS) -c $(BUILD_DIR)/reloc_offsets.s -o $(BUILD_DIR)/reloc_offsets.o
	$(CC) -o $@ $(LDFLAGS) -Wl,--emit-relocs $(OBJECTS) $(BUILD_DIR)/reloc_offsets.o
	rm -f $@.stage1

$(CODE): $(ELF)
	$(OBJCOPY) -O binary $< $@ -j .vec -j .text

$(RESOURCES): $(CODE) resources/app.rcp resources/resource.h
	cd $(BUILD_DIR) && $(PILRC) -ro -o $@ -creator $(APP_CREATOR) \
		-type $(APP_TYPE) -name '$(APP_NAME)' -I $(ROOT)/resources \
		$(ROOT)/resources/app.rcp

$(PRC): $(RESOURCES)
	$(BUILD_PRC) --no-check -o $@ -n '$(APP_NAME)' -c $(APP_CREATOR) \
		-t $(APP_TYPE) $(RESOURCES)
	$(SIZE) $(ELF)
	@echo "Built $@"

test: $(PRC)
	node $(TOOLCHAIN_ROOT)/tools/validate-prc.mjs \
		$(PRC) '$(APP_NAME)' $(APP_TYPE) $(APP_CREATOR)

clean:
	rm -rf $(BUILD_DIR)

-include $(DEPS)
