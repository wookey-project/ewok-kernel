.. _faq_build:

EwoK build process
==================

.. contents::

When I switch between C-based and Ada-based kernels, the compilation is not performed?
--------------------------------------------------------------------------------------

When changing the compilation mode of the kernel, the *$(OBJS)* objects files
list of the kernel is modified to point to the Ada (or C) object files. As a
consequence, the clean target does not do its work properly as its variables
has changed.
To be sure to rebuild the kernel in the other language, you can either:

   * delete the kernel/ dir from the build directory
   * execute a make distclean before calling the defconfig
   * remove the build directory manually
