#!/usr/bin/perl -l
#
##---
# ENV request: SOC holding soc name (e.g. stm32f439)
# Usage: SOC=<socname> ./gen_app_layout.pl <build_dir> <mode> <action>
#---

use strict;
# getting back script path
use File::Basename qw(dirname basename);
use Cwd  qw(abs_path);
# and update @INC
use lib dirname(dirname abs_path $0) . '/devmap/lib';
# now include local modules
use Devmap::Elfinfo;
use Devmap::Mpu::elf2mem;

# Check the inputs
@ARGV == 3 or usage();
( -d "$ARGV[0]" ) or die "$ARGV[0] is not a directory as is ought to be";

my    $builddir = shift;
my    $mode     = shift;
my    $action   = shift;


#
# main entry point. There is three possible actions:
# 1) action=genappcfg
#   This action generate the build dir apps/layout.<mode>.cfg config file by reading the generated dummy ELF file. Here,
#   we calculate each application section size and set it to this config file. This config file will be used by other
#   actions to calculate potential slotting/mapping and heap size constraints
# 2) action=generic
#   This action generate the arch-independent part of the kernel Ada headers (config.applications.ads)  for the kernel,
#   using the above config file. This header specify generic informations about tasks (identifier, size of various sections, etc.
# 3) action=membackend
#   This action generate the arch-specific part of the kernel Ada headers (config.memlayout.ads) for the kernel.
#   This header is handled by the memory arch-specific unit (mpu or mmu package) in order to handle memory mapping or
#   regions/subregion handling. It hold every informations which are specific to the way the memory is mapped for
#   applications (for example, number of MPU subregions for an application, and so on).
#
# All kernel headers table are indexed by the task identifier, which is the same for every kernel components (t_real_task_id).
#
sub main {
    my @applines;
    print "$action";
    if ($action =~ m/action=genappcfg/) {
        # generate configuration file
        #   req: dummy ELF file
        open(CFGH, ">", "$builddir/apps/layout.\L$mode\E.cfg") or die "unable to open app cfg file for writing: $!";
        @applines = dump_applications_metainfo();
        foreach my $appinfo (@applines) {
            format_appinfo_for_cfg(*CFGH, $appinfo);
        }
        close(CFGH);
    }
    elsif ($action =~ m/action=generic/) {
        @applines = gen_kernel_generic();
        open(KERN_GENAPP, ">", dirname(abs_path($0)) . "/../../src/generated/config.applications.ads") or die "unable to open output ada file for writing $!";
        foreach my $appinfo (@applines) {
            print KERN_GENAPP format_appinfo_for_kernel($appinfo);
        }
        close(KERN_GENAPP);
    } elsif ($action =~ m/action=membackend/) {
        @applines = gen_kernel_membackend();
        open(KERN_ARCHAPP, ">", dirname(abs_path($0)) . "/../../src/generated/config.memlayout.ads") or die "unable to open output ada file for writing $!";
        foreach my $line (@applines) {
            print KERN_ARCHAPP "$line";
        }
        close(KERN_ARCHAPP);
    } else {
        print ("unknown action $action !");
        exit 1;
    }
}

################################################################
# get back architecture specific informations from the current
# SoC given as environment variable (SOC)
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
sub dump_applications_metainfo {
    my @applines;
    my @applications = <"$builddir/apps/*/*.\L$mode\E.elf">;
    my $appid = 1;

    my $socinfos = get_arch_informations();

    # initialize memory layout for MPU-based device, setting requested properties
    Devmap::Mpu::elf2mem::set_numslots($socinfos->{"mpu.subregions_number"});
    Devmap::Mpu::elf2mem::set_ram_size($socinfos->{"memory.ram.size"});
    Devmap::Mpu::elf2mem::set_ram_addr($socinfos->{"memory.ram.addr"});
    Devmap::Mpu::elf2mem::set_flash_size($socinfos->{"memory.flash.\L$mode\E.size"});
    Devmap::Mpu::elf2mem::set_flash_addr($socinfos->{"memory.flash.\L$mode\E.addr"});


    foreach my $application (@applications) {

        my $appname;
        my %appinfo;

        # when generating cfg, we parse dummy ELF files to get back all
        # needed informations. This is the lonely time where we parse ELF
        # files

        $appname = basename($application,  ".dummy.\L$mode\E.elf");
        next if ($application =~ m/.*\/[^.]*\.\L$mode\E.elf/);

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

        $appinfo{'name'} = $appname;
        $appinfo{'id'} = $appid;

        # 3) calculate flash and RAM consumption of the task (in bytes)
        my $app_flash_size = hex($appinfo{'text_size'}) +
                             hex($appinfo{'data_size'});

        my $app_ram_size   = hex($appinfo{'data_size'}) +
                             hex($appinfo{'bss_size'}) +
                             hex($appinfo{'stack_size'});

        # 4) Now that the application constraints in term of memory footprint are
        #    knwon, let's map it to the SoC memory
        my %app_memorymap = Devmap::Mpu::elf2mem::map_application($app_flash_size, $app_ram_size);

        # 5) the memory mapper has returned informations about 
        $appinfo{'text_addr'} = $app_memorymap{'flash_slot_addr'};
        $appinfo{'data_addr'} = $app_memorymap{'ram_slot_addr'};


        # push the hashtable for higher level treatment (including Ada file generation) into an
        # applications list
        push @applines, \%appinfo;

        $appid += 1;

    }
    # return the applications metainformation lists to caller
    return @applines;
}




################################################
# construct the kernel arch-specific Ada header from the 
sub gen_kernel_membackend {
    my @applines;
    my @cfglines;
    # here we only get back the list of application. ELF file are not opened
    # FIXME: this could be obtain directly in the layout file, as the application list
    # can be dumped from it
    my @applications = <"$builddir/apps/*/*.dummy.\L$mode\E.elf">;
    my $appid = 1;

    my $socinfos = get_arch_informations();

    # initialize memory layout
    Devmap::Mpu::elf2mem::set_numslots($socinfos->{'mpu.subregions_number'});
    Devmap::Mpu::elf2mem::set_ram_size($socinfos->{'memory.ram.size'});
    Devmap::Mpu::elf2mem::set_flash_size($socinfos->{"memory.flash.\L$mode\E.size"});

    foreach my $application (@applications) {
        my %hash;
        open(CFGH, "<", "$builddir/apps/layout.\L$mode\E.cfg") or die "unable to open app cfg file for writing: $!";
        while (<CFGH>)
        {
            chomp;
            if ($_ =~ m/^app$appid\./) {
                my ($key, $val) = split (/=/, $_);
                $hash{$key} = $val;
            }
        }
        close(CFGH);

        # 2) get back the requested RAM and Flash size, using the ELF binary
        my $flash_size = hex($hash{"app${appid}.textsize"}) +
                         hex($hash{"app${appid}.datasize"});

        my $ram_size   = hex($hash{"app${appid}.datasize"}) +
                         hex($hash{"app${appid}.bsssize"}) +
                         hex($hash{"app${appid}.stacksize"});

        my %hash = Devmap::Mpu::elf2mem::map_application($flash_size, $ram_size);

        my $appline = sprintf("ID_APP%d => (%d, %d, %d, %d, %x),",
            $appid, $hash{'flash_slot_start'}, $hash{'flash_slot_num'},
            $hash{'ram_slot_start'}, $hash{'ram_slot_num'}, $hash{'ram_free_space'});

        push @applines, $appline;

        $appid += 1;
    }
    return @applines;
}




################################################################
sub gen_kernel_generic {
    my @applines;
    my @applications = <"$builddir/apps/*/*.\L$mode\E.elf">;
    my $appid = 1;

    foreach my $application (@applications) {

        my $appname;
        my $appinfo;

        # when generating cfg, we parse dummy ELF files to get back all
        # needed informations. This is the lonely time where we parse ELF
        # files
        $appname = basename($application,  ".\L$mode\E.elf");
        next if ($application =~ m/.*\.dummy\.\L$mode\E.elf/);

        $appinfo = create_app_generic_info($appname, $appid);

        # 3) Generate the arch-independent generic structure 'config.application_layout.ads

        push @applines, $appinfo;
        $appid += 1;
    }

    return @applines;
}


#---
# Utility functions
#---

# given an application, create the arch-generic, application specific layout
#
# @argument:     the application ELF file
# @prerequisite: Devmap::Elfinfo::openelf() must have been previously called
# @return:       a hash table corresponding to the application layout
#
sub create_app_generic_info {
    my ($application, $id) = @_;

    # preparing the application hashtab, with default values
    my %appinfo = {
        name        => "",
        id          => "",
        text_addr   => '0',
        text_size   => '0',
        data_addr   => '0',
        data_size   => '0',
        bss_size    => '0',
        stack_size  => '0',
    };

    # here the application config file has already been generated, we
    # can open it to get back all requested information. ELF are no more
    # needed

    my %hash;
    open(CFGH, "<", "$builddir/apps/layout.\L$mode\E.cfg") or die "unable to open app cfg file for writing: $!";
    while (<CFGH>)
    {
        chomp;
        if ($_ =~ m/^app$id\./) {
            my ($key, $val) = split (/=/, $_);
            $hash{$key} = $val;
        }
    }
    close(CFGH);

    %appinfo = (
        name        => $hash{"app${id}.name"},
        id          => "$id",
        text_addr   => $hash{"app${id}.textaddr"},
        text_size   => $hash{"app${id}.textsize"},
        data_addr   => $hash{"app${id}.dataaddr"},
        data_size   => $hash{"app${id}.datasize"},
        bss_size    => $hash{"app${id}.bsssize"},
        stack_size  => $hash{"app${id}.stacksize"}
    );


    # now we create the Ada table line. This line will have to be added
    # to the corresponding template
    return \%appinfo;
}

###########################################################
# format hex string (0x[0-9a-f]{8}) into Ada formated hexadecimal
#
sub format_ada_hex {
    my ($val) = @_;
    # iThe output is in Ada, we translate here from the
    # generic 0x08p format into Ada hexadecimal format
    $val =~ s/0x([0-9a-f]{4})([0-9a-f]{4})/16#$1_$2#/;
    return $val;
}

#
# Formatting:
#
# format application generic info for Ada kernel record type
#
sub format_appinfo_for_kernel {
    my $appinfo = @_[0];

    my $appline = sprintf("ID_APP%d => (%s_name, %s, %s, %s, %s, %s, %s),",
    $appinfo->{'id'}, $appinfo->{'name'}, format_ada_hex($appinfo->{'text_addr'}),
    format_ada_hex($appinfo->{'text_size'}), format_ada_hex($appinfo->{'data_addr'}),
    format_ada_hex($appinfo->{'data_size'}), format_ada_hex($appinfo->{'bss_size'}),
    format_ada_hex($appinfo->{'stack_size'}));

    # then we return the line to the caller
    return $appline;
}

#
# Formatting:
#
# save generic application information into cfg file $FH
#
sub format_appinfo_for_cfg {
    local *FH = shift;
    my ($appinfo) = @_;
    
    my $id = $appinfo->{'id'};
    print FH "app$id.name=$appinfo->{'name'}";
    print FH "app$id.textaddr=$appinfo->{'text_addr'}";
    print FH "app$id.textsize=$appinfo->{'text_size'}";
    print FH "app$id.dataaddr=$appinfo->{'data_addr'}";
    print FH "app$id.datasize=$appinfo->{'data_size'}";
    print FH "app$id.bsssize=$appinfo->{'bss_size'}";
    print FH "app$id.stacksize=$appinfo->{'stack_size'}";
}


# utility basics: get size of the given section
sub get_section_size {
    if (Devmap::Elfinfo::elf_section_exists($_)) {
        my %hash = Devmap::Elfinfo::elf_get_section($_);
        return hex($hash{'size'});
    }
    return 0;
}

# utility basics: get logical memory address of the current section
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
  print STDERR "usage: $0  <build_dir> <mode> <action>";
  exit(1);
}



main();
