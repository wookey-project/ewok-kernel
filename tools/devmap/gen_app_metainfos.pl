#!/usr/bin/perl -l
#

use strict;
# getting back script path
use File::Basename qw(dirname);
use Cwd  qw(abs_path);
# and update @INC
use lib dirname(dirname abs_path $0) . '/devmap/lib';
# now include local modules
use Devmap::Elfinfo;

#---
# Usage: ./gen_app_layout.pl <build_dir> <mode>
#---

# Check the inputs
@ARGV == 2 or usage();
( -d "$ARGV[0]" ) or die "$ARGV[0] is not a directory as is ought to be";

my $builddir = shift;
my $mode     = shift;

################################################################
# Iterate over all apps in current mode
#
# Here we get back each application dummy LD script in order to
# calculate each application sizing informations.
# We get back:
# - .text size
# - .rodata size
# - .got size
# - .data size
# - .bss size
# - .stack size
# All these sections size together define the application memory
# footprint, which permit to generates:
# - EwoK applications metainformations for task initialization
# - EwoK memory module SoC specific informations to handle
#   slotting/paging (depending on the current SoC).
#

my @applications = <"$builddir/apps/*/*.dummy.\L$mode\E.elf">;
foreach my $application (@applications) {
    print("parsing ELF file: $application");
    Devmap::Elfinfo::openelf($application);
    my $flash_size = get_flash_size();
    my $ram_size = get_ram_size();
    print("flash size: $flash_size, ram_size: $ram_size");
    printf("flash size: 0x%X, ram_size: 0x%x\n", $flash_size, $ram_size);
}

# get flash size for current application
sub get_flash_size {
    my %hash;
    my $size = 0;
    foreach (('.text', '.rodata', '.got', '.data')) {
        if (Devmap::Elfinfo::elf_section_exists($_)) {
            %hash = Devmap::Elfinfo::elf_get_section($_);
            # align the section properly first
            $size += ($size % hex($hash{'align'}));
            # then add its size
            $size += hex($hash{'size'});
        }
    }
    return $size;
}

sub get_ram_size {
    my %hash;
    my $size = 0;
    foreach (('.stack', '.data', '.bss')) {
        if (Devmap::Elfinfo::elf_section_exists($_)) {
            %hash = Devmap::Elfinfo::elf_get_section($_);
            # align the section properly first
            $size += ($size % hex($hash{'align'}));
            # then add its size
            $size = $size + hex($hash{'size'});
        }
    }
    return $size;
}

#---
# Utility functions
#---

sub usage()
{
  print STDERR "usage: $0  <build_dir> <mode>";
  exit(1);
}
