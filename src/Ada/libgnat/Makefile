LIB_NAME ?= libgnat
PROJ_FILES = ../../../../
LIB_FULL_NAME = $(LIB_NAME).a

include $(PROJ_FILES)/m_config.mk
include $(PROJ_FILES)/m_generic.mk

APP_BUILD_DIR = $(BUILD_DIR)/kernel/$(LIB_NAME)
GNATLIB = $(APP_BUILD_DIR)/libabsp.a
OBJ_DIR = $(BUILD_DIR)/objs

SRC_ADB = $(wildcard gnat/*.adb)
SRC_ADS = $(wildcard gnat/*.ads)


default: all

show:
	@echo "\tAPP_BUILD_DIR\t=> " $(APP_BUILD_DIR)

all: $(APP_BUILD_DIR) $(APP_BUILD_DIR)/obj $(APP_BUILD_DIR)/libgnat.a

$(APP_BUILD_DIR):
	$(call cmd,mkdir)

$(APP_BUILD_DIR)/obj:
	$(call cmd,mkdir)

$(APP_BUILD_DIR)/libgnat.a: gnat.gpr $(SRC_ADB) $(SRC_ADS)
	$(call cmd,ada_lib)

__clean: gnat.gpr
	$(call cmd,ada_clean)
