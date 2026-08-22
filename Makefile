Q ?= @
CC = arm-none-eabi-gcc
BUILD_DIR = output
NWLINK = npx --yes -- nwlink@latest

# URL officielle des composants NumWorks EADK
EADK_URL = https://github.com/numworks/eadk/releases/latest/download

define object_for
$(addprefix $(BUILD_DIR)/,$(addsuffix .o,$(basename $(1))))
endef

src = $(addprefix src/, \
  main.c \
)

CFLAGS = -std=c99 -I.
CFLAGS += -Os -Wall -ggdb
CFLAGS += -mcpu=cortex-m7 -mthumb -mfloat-abi=hard -mfpu=fpv5-sp-d16
CFLAGS += -fdata-sections -ffunction-sections

LDFLAGS = -Wl,--relocatable
LDFLAGS += -nostartfiles
LDFLAGS += --specs=nano.specs
LDFLAGS += -Wl,--gc-sections

.PHONY: build
build: eadk.h libeadk.a $(BUILD_DIR)/app.nwa

# Téléchargement automatique de eadk.h
eadk.h:
	@echo "DOWNLOAD $@"
	$(Q) wget -q -O $@ $(EADK_URL)/eadk.h

# Téléchargement automatique de libeadk.a
libeadk.a:
	@echo "DOWNLOAD $@"
	$(Q) wget -q -O $@ $(EADK_URL)/libeadk.a

$(BUILD_DIR)/app.nwa: $(call object_for,$(src)) $(BUILD_DIR)/icon.o libeadk.a
	@echo "LD $@"
	$(Q) $(CC) $(CFLAGS) $(LDFLAGS) $^ -o $@

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
	rm -rf $(BUILD_DIR) eadk.h libeadk.a
