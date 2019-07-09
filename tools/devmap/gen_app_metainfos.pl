#!/usr/bin/perl -l
#

use strict;
# getting back script path
use File::Basename qw(dirname basename);
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

my @applines;
my @applications = <"$builddir/apps/*/*.\L$mode\E.elf">;
my $appid = 1;
foreach my $application (@applications) {
    next if ($application =~ m/.*\.dummy\.\L$mode\E.elf/);
    print("parsing ELF file: $application");

    # 1) open the ELF file
    Devmap::Elfinfo::openelf($application);

    # 2) get back the requested RAM and Flash size, using the ELF binary
    my $flash_size = get_flash_size();
    my $ram_size = get_ram_size();

    printf("flash size: 0x%X, ram_size: 0x%x\n", $flash_size, $ram_size);
    print("flash size: $flash_size, ram_size: $ram_size");

    # 3) Generate the arch-independent generic structure 'config.application_layout.ads

    push @applines, create_app_generic_info($application, $appid);


    # 4) Generate the arch-specific (MMU or MPU) structure 'config.(mpu|mpu).applications_layout.ads'
    #    by now, we handle the MPU layout
    #

    $appid += 1;

}

foreach my $line (@applines) {
    print($line);
}


#---
# Utility functions
#---

sub hex_to_ada {
    my $hexval = $_;


}

sub create_app_generic_info {
    my $application = $_[0];
    my $id = $_[1];
    my $appname = basename($application,  ".\L$mode\E.elf");
    my %appinfo = {
        text_addr   => '0',
        text_size   => '0',
        data_addr   => '0',
        data_size   => '0',
        bss_size    => '0',
        stack_size  => '0',
    };

    if (Devmap::Elfinfo::elf_section_exists('.text')) {
        my %hash = Devmap::Elfinfo::elf_get_section('.text');
        # then add its size
        $appinfo{'text_addr'} = $hash{'lma'};
        $appinfo{'text_size'} = $hash{'size'};
    }
    if (Devmap::Elfinfo::elf_section_exists('.data')) {
        my %hash = Devmap::Elfinfo::elf_get_section('.data');
        # then add its size
        $appinfo{'data_addr'} = $hash{'lma'};
        $appinfo{'data_size'} = $hash{'size'};
    }
    if (Devmap::Elfinfo::elf_section_exists('.bss')) {
        my %hash = Devmap::Elfinfo::elf_get_section('.bss');
        # then add its size
        $appinfo{'bss_size'} = $hash{'size'};
    }
    if (Devmap::Elfinfo::elf_section_exists('.stacking')) {
        my %hash = Devmap::Elfinfo::elf_get_section('.stacking');
        # then add its size
        $appinfo{'stack_size'} = $hash{'size'};
    }
    # formating as Ada hex format
    foreach (keys %appinfo) {
        $appinfo{$_} =~ s/0x(\d{4})(\d{4})/16#$1_$2#/;
    }

    $appname = "\U$appname\E";
    my $appline = sprintf("   ID_APP%d => (%s_name, %s, %s, %s, %s, %s, %s),",
    $id, $appname, $appinfo{'text_addr'}, $appinfo{'text_size'},
    $appinfo{'data_addr'}, $appinfo{'data_size'},$appinfo{'bss_size'},
    $appinfo{'stack_size'});

    return $appline;
}

sub get_section_size {
    if (Devmap::Elfinfo::elf_section_exists($_)) {
        my %hash = Devmap::Elfinfo::elf_get_section($_);
        return hex($hash{'size'});
    }
    return 0;
}

sub get_section_lma {
    if (Devmap::Elfinfo::elf_section_exists($_)) {
        my %hash = Devmap::Elfinfo::elf_get_section($_);
        return hex($hash{'lma'});
    }
    return 0;
}

# get flash size for current application
#
# @argument:     None
# @prerequisite: Devmap::Elfinfo::openelf() must have been previously called
# @return:       the flash requested size in bytes
#
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

# get the ram size of the current application
#
# @argument:     None
# @prerequisite: Devmap::Elfinfo::openelf() must have been previously called
# @return:       the RAM requested size in bytes
#
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

sub usage {
  print STDERR "usage: $0  <build_dir> <mode>";
  exit(1);
}
