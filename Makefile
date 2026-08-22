Q ?= @
CC = arm-none-eabi-gcc
BUILD_DIR = output
NWLINK = npx --yes -- nwlink@latest

# Dossier où sera téléchargé le SDK NumWorks
EADK_DIR = eadk

define object_for
$(addprefix $(BUILD_DIR)/,$(addsuffix .o,$(basename $(1))))
endef

src = $(addprefix src/, \
  main.c \
)

# On inclut les dossiers de l'EADK cloné
CFLAGS = -std=c99 -I$(EADK_DIR)/include -I$(EADK_DIR)
CFLAGS += -Os -Wall -ggdb
CFLAGS += -mcpu=cortex-m7 -mthumb -mfloat-abi=hard -mfpu=fpv5-sp-d16
CFLAGS += -fdata-sections -ffunction-sections

LDFLAGS = -Wl,--relocatable
LDFLAGS += -nostartfiles
LDFLAGS += --specs=nano.specs
# Symboles obligatoires pour que NumWorks reconnaisse l'app
LDFLAGS += -Wl,-e,main -Wl,-u,eadk_app_name -Wl,-u,eadk_app_icon -Wl,-u,eadk_api_level
LDFLAGS += -Wl,--gc-sections

.PHONY: build
build: $(BUILD_DIR)/app.nwa

# Règle automatique : si le dossier eadk n'existe pas, on le clone
$(EADK_DIR):
	@echo "CLONING EADK..."
	$(Q) git clone https://github.com/numworks/eadk.git $(EADK_DIR)

$(BUILD_DIR)/app.nwa: $(call object_for,$(src)) $(BUILD_DIR)/icon.o
	@echo "LD $@"
	$(Q) $(CC) $(CFLAGS) $(LDFLAGS) $^ -o $@

# Ajout de $(EADK_DIR) comme dépendance pour garantir le clonage avant la compilation
$(BUILD_DIR)/%.o: %.c | $(BUILD_DIR) $(EADK_DIR)
	@echo "CC $<"
	$(Q) mkdir -p $(dir $@)
	$(Q) $(CC) $(CFLAGS) -c $< -o $@

$(BUILD_DIR)/icon.o: src/icon.png | $(BUILD_DIR)
	@echo "ICON $<"
	$(Q) $(NWLINK) png-icon-o $< $@

$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)

clean:
	rm -rf $(BUILD_DIR) $(EADK_DIR)
