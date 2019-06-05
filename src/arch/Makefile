LIB_NAME ?= libbsp

PROJ_FILES = ../../../
LIB_FULL_NAME = $(LIB_NAME).a

VERSION = 1
#############################

-include $(PROJ_FILES)/m_config.mk
-include $(PROJ_FILES)/m_generic.mk

-include $(PROJ_FILES)/kernel/src/arch/socs/$(SOC)/Makefile.objs
-include $(PROJ_FILES)/kernel/src/arch/cores/$(ARCH)/Makefile.objs
-include $(PROJ_FILES)/kernel/src/arch/boards/Makefile.objs

# use an app-specific build dir
ifeq ($(EXTRA_CFLAGS),-DKERNEL)
APP_BUILD_DIR = $(BUILD_DIR)/kernel/$(LIB_NAME)
else
APP_BUILD_DIR = $(BUILD_DIR)/loader/$(LIB_NAME)
endif

CFLAGS := $(KERN_CFLAGS)
CFLAGS += $(EXTRA_CFLAGS)
CFLAGS += -I.
CFLAGS += -I..
CFLAGS += -I../../src/
CFLAGS += -I$(CORE_DIR) -Icores/$(CONFIG_ARCH)/C -Isocs/$(CONFIG_SOCNAME)/C -Iboards/$(CONFIG_BOARDNAME) -Iboards
CFLAGS += -I$(PROJ_FILES)/include/generated
CFLAGS += -ffreestanding
CFLAGS += -MMD -MP

# Needed to optimize libc.c builtins
ifeq ($(USE_LLVM),y)
CFLAGS += -Os
else
CFLAGS += -O3
endif

LDFLAGS += -fno-builtin -nostdlib -nostartfiles
LD_LIBS +=

BUILD_DIR ?= $(PROJ_FILES)build

SRC_DIR = .
SRC = $(wildcard $(SRC_DIR)/*.c)
OBJ = $(patsubst %.c,$(APP_BUILD_DIR)/%.o,$(SRC))
DEP = $(OBJ:.o=.d)

CORE_SRC = $(core-bsp-y)
CORE_OBJ := $(patsubst C/%.c,$(APP_BUILD_DIR)/core/%.o,$(CORE_SRC))
CORE_DEP := $(CORE_OBJ:.o=.d)

# substitute Ada sources to C sources when they exists (Mix Ada/C libbsp)
CORE_ASRC = $(core-ada-bsp-y)

CORE_ADACEQ = $(patsubst Ada/%.adb,C/%.c,$(core-ada-bsp-y))
CORE_SRC := $(filter-out $(CORE_ADACEQ),$(core-bsp-y))
CORE_OBJ := $(patsubst C/%.c,$(APP_BUILD_DIR)/core/%.o,$(CORE_SRC))
CORE_DEP := $(CORE_OBJ:.o=.d)


SOC_SRC = $(socdrv-bsp-y)
SOC_OBJ := $(patsubst C/%.c,$(APP_BUILD_DIR)/soc/%.o,$(SOC_SRC))
SOC_OBJ := $(patsubst C/%.s,$(APP_BUILD_DIR)/soc/%.o,$(SOC_OBJ))
SOC_DEP := $(SOC_OBJ:.o=.d)


# to finish with Ada, declare the location of the Ada lib
ALIB = $(APP_BUILD_DIR)/Ada/lib/libabsp.a
ADIR = $(APP_BUILD_DIR)/Ada/lib

#C sources files
BOARD_SRC = $(board-bsp-y)
BOARD_OBJ = $(patsubst %.c,$(APP_BUILD_DIR)/board/%.o,$(BOARD_SRC))
BOARD_DEP = $(BOARD_OBJ:.o=.d)

#Rust sources files
RSSRC_DIR= rust/src
RSRC= $(wildcard $(RSRCDIR)/*.rs)
ROBJ = $(patsubst %.rs,$(APP_BUILD_DIR)/%.o,$(RSRC))

#ada sources files
ASRC_DIR = ada/src
ASRC= $(wildcard $(ASRC_DIR)/*.adb)
AOBJ = $(patsubst %.adb,$(APP_BUILD_DIR)/%.o,$(ASRC))

OUT_DIRS = $(dir $(OBJ)) $(dir $(BOARD_OBJ)) $(dir $(SOC_OBJ)) $(dir $(CORE_OBJ)) $(dir $(AOBJ)) $(dir $(ROBJ))

# file to (dist)clean
# objects and compilation related
TODEL_CLEAN += $(OBJ) $(ROBJ) $(SOC_OBJ) $(BOARD_OBJ) $(CORE_OBJ) $(DEP) $(TESTSDEP) $(SOC_DEP) $(BOARD_DEP) $(CORE_DEP)
# targets
TODEL_DISTCLEAN += $(APP_BUILD_DIR)

.PHONY: app __clean __distclean

default: all

all: $(APP_BUILD_DIR) lib

show:
	@echo
	@echo "\tAPP_BUILD_DIR\t=> " $(APP_BUILD_DIR)
	@echo
	@echo "C sources files:"
	@echo "\tSRC_DIR\t\t=> " $(SRC_DIR)
	@echo "\tSRC\t\t=> " $(SRC)
	@echo "\tOBJ\t\t=> " $(OBJ)
	@echo
	@echo "\tCORE_DIR\t=> " $(CORE_DIR)
	@echo "\tCORE_SRC\t=> " $(CORE_SRC)
	@echo "\tCORE_ASRC\t=> " $(CORE_ASRC)
	@echo "\tCORE_OBJ\t=> " $(CORE_OBJ)
	@echo
	@echo "\tSOC_DIR\t=> " $(SOC_DIR)
	@echo "\tSOC_SRC\t=> " $(SOC_SRC)
	@echo "\tSOC_ASRC\t=> " $(SOC_ASRC)
	@echo "\tSOC_OBJ\t=> " $(SOC_OBJ)
	@echo

lib: $(APP_BUILD_DIR)/$(LIB_FULL_NAME)

#############################################################
# build targets (driver, core, SoC, Board... and local)
# App C sources files

$(ADIR):
	$(call cmd,mkdir)

$(ALIB): libabsp $(ADIR)
	$(call cmd,ada_lib)

libabsp: libabsp.gpr


$(APP_BUILD_DIR)/%.o: %.c
	$(call if_changed,cc_o_c)

# Core C sources files
$(APP_BUILD_DIR)/core/%.o: $(CORE_DIR)/C/%.c
	$(call if_changed,cc_o_c)

# SoC C sources files
$(APP_BUILD_DIR)/soc/%.o: $(SOC_DIR)/C/%.c
	$(call if_changed,cc_o_c)

# SoC ASM sources files
$(APP_BUILD_DIR)/soc/%.o: $(SOC_DIR)/C/%.s
	$(call if_changed,cc_o_c)

# Board C sources files
$(APP_BUILD_DIR)/board/%.o: $(BOARD_DIR)/%.c
	$(call if_changed,cc_o_c)

# lib
$(APP_BUILD_DIR)/$(LIB_FULL_NAME): $(OBJ) $(AOBJ) $(ROBJ) $(SOC_OBJ) $(BOARD_OBJ) $(CORE_OBJ) $(ALIB)
	$(call if_changed,mklib)
	$(call if_changed,ranlib)

$(APP_BUILD_DIR):
	$(call cmd,mkdir)

__clean: libabsp.gpr
	$(call cmd,ada_clean)
	-rm -rf $(CORE_OBJ) $(SOC_OBJ) $(BOARD_OBJ)

__distclean: libabsp.gpr
	$(call cmd,ada_distclean)

-include $(DEP)
-include $(TESTSDEP)
