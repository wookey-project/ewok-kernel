About this directory
====================

All arch-specific content should be written here.

The difference with drivers & periphericals is that this part is the ASP
(Architecture Support Package), which implements the basics of the target
triplet (board-soc-core). It should not contain neither a given external
nor complex IP support (e.g. Ethernel controler, USB controler, etc.),
such IP being potentially usable in various boards based on various SoC.

We keep here what is the lonely property of a given:
 - boards: e.g. led position
 - Socs: e.g. memory layout
 - cores: generic support (MPU, FPU...)

Any IP (commercial Intelectual Property - that can be a part of various SoC)
support has to be written in the drivers/ dir

The boards dir contains one dir per target board. The directory name should
correspond to the name given in the KCONFIG CONFIG_BOARDNAME config option.

The socs dir contains (by now) a flat directory for all SoC layout header files.
These files describe the memory layout for each SoC.

the cores dir contains one directory per core, using a core named that should
correspond to the name given in the KCONFIG CONFIG_ARCH config option (e.g.
armv7-m) It contains all the core specific implementations (initialization functions
for GIC, MPU, FPU, TZ, etc.)

the function names should be generic enough to be the same between each
arch_specific support (e.g. irq_enable, FPU_IRQHandler, etc.). heach arch
header should propose the same set of function to avoid modification in the
arch-independent code.
