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

# use an app-specific build dir
APP_BUILD_DIR = $(BUILD_DIR)/$(DIR_NAME)

CFLAGS += $(EXTRA_CFLAGS)
CFLAGS += $(DEBUG_CFLAGS) -Wconversion
CFLAGS += -I. -Isyscalls -Igenerated -I$(CORE_DIR) -Iarch
CFLAGS += -MMD -MP
CFLAGS += $(KERN_CFLAGS)

CLANG_CFLAGS := -I. -Isyscalls -Igenerated  -I$(CORE_DIR) -Iarch -Iarch/core/$(CONFIG_ARCH) -Iarch/socs/$(CONFIG_SOCNAME) -Iarch/boards/$(CONFIG_BOARDNAME) -Iarch/boards

# if no specific ldscript is specified, using default one, if the SDK want to relink successively with
# varous ldscripts, this variable has to be passed to the Makefile commandline
EXTRA_LDFLAGS ?= -Tkernel.ld

LDFLAGS += $(EXTRA_LDFLAGS) -L$(APP_BUILD_DIR) $(AFLAGS) -fno-builtin -nostdlib -nostartfiles -Xlinker

# --unresolved-symbols=ignore-in-object-files
LD_LIBS += -lbsp -L$(BUILD_DIR)/kernel/libbsp

ifeq ($(CONFIG_ADAKERNEL),y)
LD_LIBS = -lkernel -L$(APP_BUILD_DIR)/Ada/lib
LD_LIBS += -lbsp -L$(BUILD_DIR)/kernel/libbsp
LD_LIBS += -labsp -L$(BUILD_DIR)/kernel/libbsp/Ada/lib
LD_LIBS += -lgnat -L$(BUILD_DIR)/kernel/libgnat
endif

BUILD_DIR ?= $(PROJ_FILE)build

SRC = $(wildcard *.c) $(wildcard syscalls/*.c)
OBJ := $(patsubst %.c,$(APP_BUILD_DIR)/%.o,$(SRC))

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
OBJ := $(patsubst %.c,$(APP_BUILD_DIR)/%.o,$(SRC))

endif

#Rust sources files
RSSRC_DIR= rust/src
RSRC= $(wildcard $(RSRCDIR)/*.rs)
ROBJ = $(patsubst %.rs,$(APP_BUILD_DIR)/%.o,$(RSRC))

SOC_DIR := $(PROJ_FILES)/kernel/arch/socs/$(SOC)/
SOC_SRC := startup_$(SOC).s
SOC_OBJ := $(patsubst %.s,$(APP_BUILD_DIR)/%.o,$(SOC_SRC))

CORE_DIR := $(PROJ_FILES)/kernel/arch/cores/$(ARCH)/
CORE_SRC := $(core-kernel-y)
CORE_OBJ := $(patsubst %.c,$(APP_BUILD_DIR)/core/%.o,$(CORE_SRC))

#test sources files
TESTSSRC_DIR = tests
TESTSSRC = tests.c tests_cryp.c tests_dma.c tests_queue.c tests_sd.c tests_systick.c
TESTSOBJ = $(patsubst %.c,$(APP_BUILD_DIR)/%.o,$(TESTSSRC))
TESTSDEP = $(TESTSSOBJ:.o=.d)

OUT_DIRS = $(dir $(KERNEL_OBJ)) $(dir $(AALI)) $(dir $(ROBJ)) $(dir $(ALIB))

LDSCRIPT_NAME = $(APP_BUILD_DIR)/$(APP_NAME).ld

# file to (dist)clean
# objects and compilation related
TODEL_CLEAN += $(OBJ) $(ALDIR) $(ALIB) $(ROBJ) $(DEP) $(TESTSDEP) $(LDSCRIPT_NAME)
# targets
TODEL_DISTCLEAN += $(APP_BUILD_DIR)

.PHONY: kernel __clean __distclean

ifeq ($(CONFIG_ADAKERNEL),y)
all: $(APP_BUILD_DIR) libgnat libbsp kernel
else
all: $(APP_BUILD_DIR) libbsp kernel
endif


show:
	@echo
	@echo "\t\tAPP_BUILD_DIR\t=> " $(APP_BUILD_DIR)
	@echo
	@echo "C sources files:"
	@echo "\t\tKERNEL_ASRC\t=> $(ASRC)"
	@echo "\t\tKERNEL_SRC\t=> " $(SRC)
	@echo "\t\tKERNEL_OBJ\t=> " $(OBJ)
	@echo
	@echo "\t\tBUILD_DIR\t=> " $(BUILD_DIR)
	@echo "\t\tAPP_BUILD_DIR\t=> " $(APP_BUILD_DIR)
	@echo
	@echo "Rust sources files:"
	@echo "\t" $(RSRC)
	@echo "\t\t=> " $(ROBJ)

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

$(APP_BUILD_DIR)/%.o: $(SOC_DIR)/$(SOC_SRC)
	$(call if_changed,cc_o_c)

# Core C sources files
$(APP_BUILD_DIR)/core/%.o: $(CORE_DIR)/%.c
	$(call if_changed,cc_o_c)

# Test sources files
$(APP_BUILD_DIR)/tests/%.o: $(TESTSSRC_DIR)/%.c
	$(call if_changed,cc_o_c)

# RUST FILES
$(ROBJ): $(RSRC)
	$(call if_changed,rc_o_rs)

# LDSCRIPT. All are built in one time
$(LDSCRIPT_NAME): $(OBJ) $(ROBJ) $(SOBJ) $(SOC_OBJ) $(CORE_OBJ) $(ALIB)
	$(call if_changed,k_ldscript)

# ELF
$(APP_BUILD_DIR)/$(ELF_NAME): $(LDSCRIPT_NAME)
	$(call if_changed,link_o_target)

# HEX
$(APP_BUILD_DIR)/$(HEX_NAME): $(APP_BUILD_DIR)/$(ELF_NAME)
	$(call if_changed,objcopy_ihex)

# BIN
$(APP_BUILD_DIR)/$(BIN_NAME): $(APP_BUILD_DIR)/$(ELF_NAME)
	$(call if_changed,objcopy_bin)

$(APP_BUILD_DIR):
	$(call cmd,mkdir)

# TEST TARGETS
tests_suite: CFLAGS += -Itests/ -DTESTS
tests_suite: $(TESTSOBJ) $(ROBJ) $(OBJ) $(SOBJ) $(DRVOBJ)

tests: clean tests_suite
	$(CC) $(LDFLAGS) -o $(APP_NAME).elf $(ROBJ) $(SOBJ) $(OBJ) $(DRVOBJ) $(TESTSOBJ)
	$(GDB) -x gdbfile_run $(APP_NAME).elf

ifeq ($(CONFIG_ADAKERNEL),y)
__clean: libkernel.gpr
	$(call cmd,ada_clean)

__distclean: libkernel.gpr
	$(call cmd,ada_distclean)
endif


-include $(DEP)
-include $(DRVDEP)
-include $(TESTSDEP)
