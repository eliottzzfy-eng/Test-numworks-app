Q ?= @
CC = arm-none-eabi-gcc
BUILD_DIR = output
NWLINK = npx --yes -- nwlink@latest

define object_for
$(addprefix $(BUILD_DIR)/,$(addsuffix .o,$(basename $(1))))
endef

src = $(addprefix src/, \
  main.c \
)

CFLAGS = -std=c99
# nwlink inclut le SDK, sinon on cherche dans le dossier courant (-I.)
CFLAGS += -I$(shell $(NWLINK) eadk-include-path 2>/dev/null || echo ".") -I.
CFLAGS += -Os -Wall -ggdb
CFLAGS += -mcpu=cortex-m7 -mthumb -mfloat-abi=hard -mfpu=fpv5-sp-d16
CFLAGS += -fdata-sections -ffunction-sections

LDFLAGS = -Wl,--relocatable
LDFLAGS += -nostartfiles
LDFLAGS += --specs=nano.specs
LDFLAGS += -Wl,-e,main -Wl,-u,eadk_app_name -Wl,-u,eadk_app_icon -Wl,-u,eadk_api_level
LDFLAGS += -Wl,--gc-sections

.PHONY: build
build: $(BUILD_DIR)/app.nwa

# Téléchargement de secours direct depuis le dépôt principal de NumWorks
eadk.h:
	@echo "DOWNLOADING eadk.h fallback..."
	$(Q) curl -sL -o $@ https://raw.githubusercontent.com/numworks/epsilon/master/eadk/include/eadk.h

$(BUILD_DIR)/app.nwa: $(call object_for,$(src)) $(BUILD_DIR)/icon.o
	@echo "LD $@"
	$(Q) $(CC) $(CFLAGS) $(LDFLAGS) $^ -o $@

# eadk.h est requis avant de compiler main.c
$(BUILD_DIR)/%.o: %.c eadk.h | $(BUILD_DIR)
	@echo "CC $<"
	$(Q) mkdir -p $(dir $@)
	$(Q) $(CC) $(CFLAGS) -c $< -o $@

$(BUILD_DIR)/icon.o: src/icon.png | $(BUILD_DIR)
	@echo "ICON $<"
	$(Q) $(NWLINK) png-icon-o $< $@

$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)

clean:
	rm -rf $(BUILD_DIR) eadk.h
