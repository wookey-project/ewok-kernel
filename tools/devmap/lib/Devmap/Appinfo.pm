package Devmap::Appinfo;

use strict;
# getting back script path
use File::Basename qw(dirname basename);
use Cwd  qw(abs_path);
# and update @INC
use lib dirname(dirname abs_path $0) . '/devmap/lib';

use Devmap::Elfinfo;
use Devmap::Mpu::elf2mem;
use Kconfig::Application;

my $builddir = "";
my $mode = "";
my $component = "";
my $socinfos;

#########################################################
# setters

sub set_builddir {
    ($builddir) = @_;
}

sub set_mode {
    ($mode) = @_;
}

sub set_component {
    ($component) = @_;
}

sub set_socinfos {
    ($socinfos) = @_;
}

########################################################
# get back current architecture specific information
# in hashtab format
#
sub get_arch_informations {
    # get back current SoC specificites into sochash hash table
    #
    my $socinfo = dirname(abs_path $0) . "/../../src/arch/socs/" . $ENV{SOC} . "/socinfo.cfg";

    open(SOCINFO, "<", "$socinfo") or die("unable to open $socinfo: $!");
    my %sochash;
    while (<SOCINFO>)
    {
        chomp;
        if ($_ =~ m/^[a-z]+\..+=.+/) {
            my ($key, $val) = split (/=/, $_);
            $sochash{$key} = $val;
        }
    }
    close(SOCINFO);
    $socinfos = \%sochash;
    return \%sochash;

}

################################################################
# This function dump all dummy ELF applications of a given
# mode (FW1, FW2, DFU1 or DFU2) and get back various informations
# needed by the kernel:
#    o generic memory footprint
#       - sections size (.text, .rodata, .data, .bss, .stack)
#    o SoC specific memory constraints
#       - memory slotting for MPU-based SoCs
#       - memory paging for MMU-based SoCs
#    o Application generic metainfo (domain...) from current config
#
# All these informations are saved into a hashtable in
# the application build directory ($builddir/apps/) under
# the name layout.<mode>.cfg, where mode is the curent firmware
# mode construct (fw1, fw2, dfu1 dfu2).
#
# In order to be informed of the requested input informations
# (including the storage memory mapping and size, the RAM physical
# address and the slotting constraints for MPU-based devices, this
# script use a SoC specific configuration file, saved in the kernel
# arch/socs/$(SOC)/soclayout.cfg file, through a hashtable format.
#
# When this file is generated, dummy ELF files are no more needed and
# final application LDScripts can be generated using this file as an
# autonomous input.
#
sub dump_elf_metainfo {
    my ($application, $appid) = @_;
    my $appname;
    my $appprefix;
    my %appinfo;

    # when generating cfg, we parse dummy ELF files to get back all
    # needed informations. This is the lonely time where we parse ELF
    # files

    $appname = basename($application,  ".dummy.\L$mode\E.elf");
    next if ($application =~ m/.*\/[^.]*\.\L$mode\E.elf/);

    $appprefix = $appname;
    $appprefix =~ s/(.*)\.dummy.*/$1/;
    print "appprefix is $appprefix";

    # 1) open the ELF file
    Devmap::Elfinfo::openelf($application);

    # 2) get back the generic info (sections size are valid but not
    #    correctly memory mapped)
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
    $appinfo{'rodata_addr'} = 0;
    $appinfo{'rodata_size'} = 0;
    if (Devmap::Elfinfo::elf_section_exists('.rodata')) {
        my %hash = Devmap::Elfinfo::elf_get_section('.rodata');
        # then add its size
        $appinfo{'rodata_addr'} = $hash{'lma'};
        $appinfo{'rodata_size'} = $hash{'size'};
    }
    $appinfo{'got_addr'} = 0;
    $appinfo{'got_size'} = 0;
    if (Devmap::Elfinfo::elf_section_exists('.got')) {
        my %hash = Devmap::Elfinfo::elf_get_section('.got');
        # then add its size
        $appinfo{'got_addr'} = $hash{'lma'};
        $appinfo{'got_size'} = $hash{'size'};
    }
    $appinfo{'vdso_addr'} = 0;
    $appinfo{'vdso_size'} = 0;
    if (Devmap::Elfinfo::elf_section_exists('.vdso')) {
        my %hash = Devmap::Elfinfo::elf_get_section('.vdso');
        # then add its size
        $appinfo{'vdso_addr'} = $hash{'lma'};
        $appinfo{'vdso_size'} = $hash{'size'};
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
    if (Devmap::Elfinfo::elf_section_exists('.heap')) {
        my %hash = Devmap::Elfinfo::elf_get_section('.heap');
        print(%hash);
        # then add its size
        $appinfo{'heap_size'} = $hash{'size'};
    } else {
        $appinfo{'heap_size'} = 0;
        print("section HEAP not found !\n");
    }
    # These offsets can then be used in a PIE mode
    $appinfo{'entrypoint'} = sprintf("0x%x", hex(Devmap::Elfinfo::elf_get_symbol_address("do_starttask")) - hex($appinfo{'text_addr'}));
    $appinfo{'isr_entrypoint'} = sprintf("0x%x", hex(Devmap::Elfinfo::elf_get_symbol_address("do_startisr")) - hex($appinfo{'text_addr'}));

    $appinfo{'name'} = $appname;
    $appinfo{'id'} = $appid;

    # 3) calculate flash and RAM consumption of the task (in bytes)
    my $app_flash_size = hex($appinfo{'text_size'}) +
    hex($appinfo{'data_size'}) + hex($appinfo{'got_size'}) +
        hex($appinfo{'rodata_size'}) + hex($appinfo{'vdso_size'});

    my $app_ram_size   = hex($appinfo{'data_size'}) +
    hex($appinfo{'bss_size'}) +
    hex($appinfo{'stack_size'}) +
    hex($appinfo{'heap_size'});

    # 4) Now that the application constraints in term of memory footprint are
    #    knwon, let's map it to the SoC memory
    my %app_memorymap = Devmap::Mpu::elf2mem::map_application($app_flash_size, $app_ram_size);

    # 5) the memory mapper has returned informations about. Here, this information is calculated in offset
    #    starting with the begining of the user flash/ram region of the current session
    $appinfo{'text_off'} = hex($app_memorymap{'flash_slot_addr'}) - hex($socinfos->{"memory.flash.\L$mode\E.\L$component\E.addr"});
    $appinfo{'text_addr'} = $app_memorymap{'flash_slot_addr'};
    $appinfo{'data_addr'} = sprintf("0x%08x", (hex($app_memorymap{'flash_slot_addr'}) + hex($appinfo{'text_size'}) + hex($appinfo{'got_size'}) + hex($appinfo{'vdso_size'})));
    $appinfo{'data_off'} = hex($app_memorymap{'ram_slot_addr'}) - hex($socinfos->{"memory.ram.\L$component\E.addr"});


    # 6) now get back .config info for app

    my $appcfginfo = Kconfig::Application::dump_application_config(dirname(abs_path($0)) . "/../../../.config", $appprefix);

    $appinfo{'domain'} = $appcfginfo->{'domain'};
    $appinfo{'prio'} = $appcfginfo->{'prio'};

    # push the hashtable for higher level treatment (including Ada file generation) into an
    # applications list
    return \%appinfo;
}


1;

__END__
