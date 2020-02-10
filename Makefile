APP_NAME ?= kernel
DIR_NAME = kernel

PROJ_FILES = ../
BIN_NAME = $(APP_NAME).bin
HEX_NAME = $(APP_NAME).hex
ELF_NAME = $(APP_NAME).elf


IMAGE_TYPE = IMAGE_TYPE0
VERSION = 1
#############################

-include $(PROJ_FILES)/m_config.mk
-include $(PROJ_FILES)/m_generic.mk

# use an app-specific build dir
APP_BUILD_DIR = $(BUILD_DIR)/$(DIR_NAME)

BUILD_DIR ?= $(PROJ_FILE)build

AFLAGS += -I$(PROJ_FILES)include/generated

EXTRA_LDFLAGS ?= -Tkernel.ld
LDFLAGS += $(EXTRA_LDFLAGS) -L$(APP_BUILD_DIR) $(AFLAGS_GCC) -fno-builtin -nostdlib -nostartfiles -Xlinker

LD_LIBS = -lkernel -L$(APP_BUILD_DIR)/Ada/lib
LD_LIBS += -lgnat -L$(BUILD_DIR)/kernel/libgnat

SOC_ASM := startup.S
SOC_DIR := src/arch/socs/$(SOC)
SOC_OBJ := $(patsubst %.S,$(APP_BUILD_DIR)/asm/%.o,$(SOC_ASM))

# all files in Ada dir will replace C equivalent
ALIB = $(APP_BUILD_DIR)/Ada/lib/libkernel.a
ADIR = $(APP_BUILD_DIR)/Ada/lib

OUT_DIRS = $(dir $(KERNEL_OBJ)) $(dir $(ALIB))

LDSCRIPT_NAME = $(APP_BUILD_DIR)/$(APP_NAME).ld

# file to (dist)clean
# objects and compilation related
TODEL_CLEAN += $(OBJ) $(ALDIR) $(ALIB) $(DEP) $(LDSCRIPT_NAME)
# targets
TODEL_DISTCLEAN += $(APP_BUILD_DIR)

.PHONY: __clean __distclean doc prove libgnat


#############################################################
# build targets (driver, core, SoC, Board... and local)
# App C sources files
# kernel C sources files


default: all

ifeq (,$(CONFIG_PROJ_FILES))
# let's detect if the kernel is trying to be compiled out of any SDK...
all:
	@echo "The Ewok kernel is not made to be compiled out of any SDK"
	@echo "please use the following command:"
	@echo "  repo init -u https://github.com/wookey-project/manifest.git -m default.xml"
	@echo "  repo sync"
	@echo
	@echo "This will create a wookey directory in which the whole SDK (including kernel)"
	@echo "is downloaded and can be compiled"
else
all: prepare $(APP_BUILD_DIR) libgnat kernel

endif

doc:
	$(Q)$(MAKE) BUILDDIR=../$(APP_BUILD_DIR)/doc  -C doc html latexpdf

libgnat:
	$(Q)$(MAKE) -C libgnat all

prepare:
	@mkdir -p src/generated

show:
	$(Q)$(MAKE) -C src show

prove:
	$(Q)$(MAKE) -C $@ all

__clean: libkernel.gpr
	$(call cmd,ada_clean)
	-rm src/generated/*
	-rm $(APP_BUILD_DIR)/$(BIN_NAME) $(HEX_NAME) $(SOC_OBJ)

__distclean: libkernel.gpr
	$(call cmd,ada_distclean)

kernel: $(APP_BUILD_DIR)/$(ELF_NAME) $(APP_BUILD_DIR)/$(HEX_NAME)

$(ADIR):
	$(call cmd,mkdir)

$(ALIB): $(ADIR) libkernel

libkernel: libkernel.gpr
	$(call cmd,ada_lib)

sanitize: $(SRC)
	clang -target armv7-m -mfloat-abi=hard -mcpu=cortex-m4 $(CLANG_CFLAGS) --analyze $(SRC)

# only for ASM startup file
$(SOC_OBJ): $(SOC_DIR)/$(SOC_ASM)
	$(call if_changed,cc_o_asm)

# LDSCRIPT. All are built in one time
$(LDSCRIPT_NAME):
	$(call if_changed,k_ldscript)

# ELF
$(APP_BUILD_DIR)/$(ELF_NAME): $(LDSCRIPT_NAME) $(SOC_OBJ) $(ALIB)
	$(call if_changed,link_o_target)

# HEX
$(APP_BUILD_DIR)/$(HEX_NAME): $(APP_BUILD_DIR)/$(ELF_NAME)
	$(call if_changed,objcopy_ihex)

# BIN
$(APP_BUILD_DIR)/$(BIN_NAME): $(APP_BUILD_DIR)/$(ELF_NAME)
	$(call if_changed,objcopy_bin)

$(APP_BUILD_DIR):
	$(call cmd,mkdir)


#
# As any modification in the user apps permissions or configuration impact the kernel
# generated headers, the kernel headers and as a consequence the kernel binaries need
# to be built again. We decide to require a kernel rebuilt at each all target to be
# sure that the last potential configuration or userspace layout upgrade is taken into
# account in the kernel
#
clean_headers:
	-rm src/generated/*
	rm -rf $(APP_BUILD_DIR)/kernel.*.hex
	rm -rf $(APP_BUILD_DIR)/*.elf

