Q ?= @
CC = arm-none-eabi-gcc
BUILD_DIR = output
NWLINK = npx --yes -- nwlink@latest
LINK_GC = 1
LTO = 1

define object_for
$(addprefix $(BUILD_DIR)/,$(addsuffix .o,$(basename $(1))))
endef

src = $(addprefix src/, \
  main.c \
)

CFLAGS = -std=c99
CFLAGS += -Os -Wall -ggdb
CFLAGS += -mcpu=cortex-m7 -mthumb -mfloat-abi=hard -mfpu=fpv5-sp-d16

LDFLAGS = -Wl,--relocatable
LDFLAGS += -nostartfiles
LDFLAGS += --specs=nano.specs

ifeq ($(LINK_GC),1)
CFLAGS += -fdata-sections -ffunction-sections
LDFLAGS += -Wl,-e,main -Wl,-u,eadk_app_name -Wl,-u,eadk_app_icon -Wl,-u,eadk_api_level
LDFLAGS += -Wl,--gc-sections
endif

ifeq ($(LTO),1)
CFLAGS += -flto -fno-fat-lto-objects
CFLAGS += -fwhole-program
CFLAGS += -fvisibility=internal
LDFLAGS += -flinker-output=nolto-rel
endif

.PHONY: build
build: $(BUILD_DIR)/app.nwa

$(BUILD_DIR)/app.nwa: $(call object_for,$(src)) $(BUILD_DIR)/icon.o
	@echo "LD $@"
	$(Q) $(CC) $(CFLAGS) $(LDFLAGS) $^ -o $@

$(BUILD_DIR)/%.o: %.c | $(BUILD_DIR)
	@echo "CC $^"
	$(Q) mkdir -p $(dir $@)
	$(Q) $(CC) $(CFLAGS) -c $^ -o $@

$(BUILD_DIR)/icon.o: src/icon.png | $(BUILD_DIR)
	@echo "ICON $<"
	$(Q) $(NWLINK) png-icon-o $< $@

$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)

clean:
	rm -rf $(BUILD_DIR)
