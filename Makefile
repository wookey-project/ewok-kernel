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

-include $(PROJ_FILES)/kernel/src/arch/socs/$(SOC)/Makefile.objs
-include $(PROJ_FILES)/kernel/src/arch/cores/$(ARCH)/Makefile.objs
-include $(PROJ_FILES)/kernel/src/arch/boards/Makefile.objs

# use an app-specific build dir
APP_BUILD_DIR = $(BUILD_DIR)/$(DIR_NAME)

BUILD_DIR ?= $(PROJ_FILE)build
GENDIR     = generated/Ada

.PHONY: __clean __distclean $(GENDIR)

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
all: prepare
	$(Q)$(MAKE) -C src all

endif

prepare:
	@mkdir -p generated
	@mkdir -p generated/Ada

show:
	$(Q)$(MAKE) -C src show

libbsp:
	ADAKERNEL=$(ADAKERNEL) make LOADER=$(LOADER) -C src/arch

clean_headers:
	$(Q)$(MAKE) -C src clean_headers

__clean:
	$(Q)$(MAKE) -C src clean

__distclean:
	$(Q)$(MAKE) -C src distclean
