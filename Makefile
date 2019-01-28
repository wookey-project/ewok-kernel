APP_NAME ?= kernel
DIR_NAME = kernel

PROJ_FILES = ../
BIN_NAME = $(APP_NAME).bin
HEX_NAME = $(APP_NAME).hex
ELF_NAME = $(APP_NAME).elf


IMAGE_TYPE = IMAGE_TYPE0
VERSION = 1
#############################

-include $(PROJ_FILES)/Makefile.conf
-include $(PROJ_FILES)/Makefile.gen

-include $(PROJ_FILES)/kernel/arch/socs/$(SOC)/Makefile.objs
-include $(PROJ_FILES)/kernel/arch/cores/$(ARCH)/Makefile.objs
-include $(PROJ_FILES)/kernel/arch/boards/Makefile.objs

# use an app-specific build dir
APP_BUILD_DIR = $(BUILD_DIR)/$(DIR_NAME)

CFLAGS += $(EXTRA_CFLAGS)
CFLAGS += $(DEBUG_CFLAGS) -Wconversion
CFLAGS += -I. -Isyscalls -Igenerated -I$(CORE_DIR) -Iarch
CFLAGS += -MMD -MP
CFLAGS += $(KERN_CFLAGS)
CFLAGS += -fstack-protector-strong
CFLAGS += -I$(PROJ_FILES)/kernel/arch
CFLAGS += -I$(CORE_DIR) -Iarch -Iarch/cores/$(CONFIG_ARCH) -Iarch/socs/$(CONFIG_SOCNAME) -Iarch/boards/$(CONFIG_BOARDNAME) -Iarch/boards


CLANG_CFLAGS := -I../include/generated -I. -Isyscalls -Igenerated  -I$(CORE_DIR) -Iarch -Iarch/cores/$(ARCH) -Iarch/socs/$(SOC) -Iarch/boards/$(BOARD) -Iarch/boards

# if no specific ldscript is specified, using default one, if the SDK want to relink successively with
# varous ldscripts, this variable has to be passed to the Makefile commandline
EXTRA_LDFLAGS ?= -Tkernel.ld

LDFLAGS += $(EXTRA_LDFLAGS) -L$(APP_BUILD_DIR) $(AFLAGS) -fno-builtin -nostdlib -nostartfiles -Xlinker

# --unresolved-symbols=ignore-in-object-files
LD_LIBS += -lbsp -L$(BUILD_DIR)/kernel/libbsp

ifeq ($(CONFIG_ADAKERNEL),y)
LD_LIBS = -lkernel -L$(APP_BUILD_DIR)/Ada/lib
LD_LIBS += -lbsp -L$(BUILD_DIR)/kernel/libbsp
LD_LIBS += -lgnat -L$(BUILD_DIR)/kernel/libgnat
endif

BUILD_DIR ?= $(PROJ_FILE)build

SRC = $(wildcard *.c) $(wildcard syscalls/*.c)
OBJ := $(SRC:%.c=$(APP_BUILD_DIR)/%.o)
DEP := $(OBJ:%.o=%.d)

ifeq ($(CONFIG_ADAKERNEL),y)
#ada sources files
# all files in Ada dir will replace C equivalent
ASRC_DIR = Ada
ASRC = $(wildcard $(ASRC_DIR)/*.adb) $(wildcard $(ASRC_DIR)/syscalls/*.adb)
ALIB = $(APP_BUILD_DIR)/Ada/lib/libkernel.a
ADIR = $(APP_BUILD_DIR)/Ada/lib

# deleting C files having their Ada equivalent from the C/obj list
ADACEQ  = $(patsubst Ada/ewok-%.adb,%.c,$(ASRC))
ADACEQ += $(patsubst Ada/syscalls/ewok-%.adb,syscalls/%.c,$(ASRC))
SRC_TMP = $(filter-out $(ADACEQ),$(SRC))
SRC := $(SRC_TMP)
OBJ := $(SRC:%.c=$(APP_BUILD_DIR)/%.o)
DEP := $(OBJ:%.o=%.d)
endif

SOC_DIR := $(PROJ_FILES)/kernel/arch/socs/$(SOC)/
SOC_SRC := startup_$(SOC).s
SOC_OBJ := $(patsubst %.s,$(APP_BUILD_DIR)/asm/%.o,$(SOC_SRC))

OUT_DIRS = $(dir $(KERNEL_OBJ)) $(dir $(AALI)) $(dir $(ROBJ)) $(dir $(ALIB))

LDSCRIPT_NAME = $(APP_BUILD_DIR)/$(APP_NAME).ld

# file to (dist)clean
# objects and compilation related
TODEL_CLEAN += $(OBJ) $(ALDIR) $(ALIB) $(DEP) $(LDSCRIPT_NAME)
# targets
TODEL_DISTCLEAN += $(APP_BUILD_DIR)

.PHONY: __clean __distclean

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

ifeq ($(CONFIG_ADAKERNEL),y)
all: check_paradigm_switch $(APP_BUILD_DIR) libgnat libbsp kernel
else
all: check_paradigm_switch $(APP_BUILD_DIR) libbsp kernel
endif

endif

show:
	@echo
	@echo "\t\tAPP_BUILD_DIR\t=> " $(APP_BUILD_DIR)
	@echo
	@echo "C sources files:"
	@echo "\t\tKERNEL_ASRC\t=> $(ASRC)"
	@echo "\t\tKERNEL_SRC\t=> " $(SRC)
	@echo "\t\tKERNEL_OBJ\t=> " $(OBJ)
	@echo "\t\tKERNEL_DEP\t=> " $(DEP)
	@echo
	@echo "\t\tBUILD_DIR\t=> " $(BUILD_DIR)
	@echo "\t\tAPP_BUILD_DIR\t=> " $(APP_BUILD_DIR)
	@echo

libbsp:
	$(Q)$(MAKE) -C arch clean
	$(Q)$(MAKE) -C arch EXTRA_CFLAGS="-DKERNEL"
	$(Q)$(MAKE) -C arch EXTRA_CFLAGS="-DLOADER"

libgnat:
	$(Q)$(MAKE) -C Ada/libgnat all

kernel: $(APP_BUILD_DIR)/$(ELF_NAME) $(APP_BUILD_DIR)/$(HEX_NAME)

#############################################################
# build targets (driver, core, SoC, Board... and local)
# App C sources files
# kernel C sources files


check_paradigm_switch:
ifeq ($(CONFIG_ADAKERNEL),y)
	# when switching between kernel paradigm, we must clean any objects an bin files
	if test ! -d $(APP_BUILD_DIR)/Ada; then rm -rf $(APP_BUILD_DIR)/*.[od] $(APP_BUILD_DIR)/syscalls; rm -rf $(APP_BUILD_DIR)/libbsp; fi
else
	# when switching between kernel paradigm, we must clean any objects an bin files
	if test -d $(APP_BUILD_DIR)/Ada; then rm -rf $(APP_BUILD_DIR)/*.[od] $(APP_BUILD_DIR)/syscalls; rm -rf $(APP_BUILD_DIR)/libbsp; rm -rf $(APP_BUILD_DIR)/Ada; fi
endif



ifeq ($(CONFIG_ADAKERNEL),y)
$(ADIR):
	$(call cmd,mkdir)

$(ALIB): $(ADIR) libkernel

libkernel: libkernel.gpr
	$(call cmd,ada_lib)

endif

sanitize: $(SRC)
	clang -target armv7-m -mfloat-abi=hard -mcpu=cortex-m4 $(CLANG_CFLAGS) --analyze $(SRC)

$(APP_BUILD_DIR)/%.o: %.c
	$(call if_changed,cc_o_c)

# only for ASM startup file
$(APP_BUILD_DIR)/asm/%.o: $(SOC_DIR)/$(SOC_SRC)
	$(call if_changed,cc_o_c)

# LDSCRIPT. All are built in one time
$(LDSCRIPT_NAME):
	$(call if_changed,k_ldscript)

# ELF
$(APP_BUILD_DIR)/$(ELF_NAME): $(LDSCRIPT_NAME) $(OBJ) $(SOC_OBJ) $(ALIB)
	$(call if_changed,link_o_target)

# HEX
$(APP_BUILD_DIR)/$(HEX_NAME): $(APP_BUILD_DIR)/$(ELF_NAME)
	$(call if_changed,objcopy_ihex)

# BIN
$(APP_BUILD_DIR)/$(BIN_NAME): $(APP_BUILD_DIR)/$(ELF_NAME)
	$(call if_changed,objcopy_bin)

$(APP_BUILD_DIR):
	$(call cmd,mkdir)


ifeq ($(CONFIG_ADAKERNEL),y)
__clean: libkernel.gpr
	$(call cmd,ada_clean)
	-rm generated/*
	-rm Ada/generated/*
	-rm $(APP_BUILD_DIR)/$(BIN_NAME) $(HEX_NAME) $(OBJ) $(DEP)

__distclean: libkernel.gpr
	$(call cmd,ada_distclean)
endif

#
# As any modification in the user apps permissions or configuration impact the kernel
# generated headers, the kernel headers and as a consequence the kernel binaries need
# to be built again. We decide to require a kernel rebuilt at each all target to be
# sure that the last potential configuration or userspace layout upgrade is taken into
# account in the kernel
#
clean_headers: check_paradigm_switch
	rm -rf Ada/generated/*
	rm -rf generated/*
	rm -rf $(APP_BUILD_DIR)/kernel.*.hex
	rm -rf $(APP_BUILD_DIR)/*.elf

-include $(DEP)
# no deps for soc obj
$(SOC_OBJ):


