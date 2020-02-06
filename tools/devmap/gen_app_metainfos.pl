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
use Devmap::Appinfo;
use Devmap::Mpu::elf2mem;
use Kconfig::Application;
use Ada::Format;

# Check the inputs
@ARGV == 3 or usage();
( -d "$ARGV[0]" ) or die "$ARGV[0] is not a directory as is ought to be";

my    $builddir = shift;
my    $mode     = shift;
my    $action   = shift;


#
# main entry point. There is three possible actions:
# all of them depend on the previously executed gen_app_dummy_ld.pl
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
    mkdir(dirname(abs_path($0)) .  "/../../kernel/src/generated/",0755) if !-d "kernel/src/generated/";
    if ($action =~ m/action=genappcfg/) {
        # generate configuration file
        #   req: dummy ELF file
        open(CFGH, ">", "$builddir/apps/layout.\L$mode\E.cfg") or die "unable to open app cfg file for writing: $!";
        Devmap::Appinfo::set_builddir($builddir);
        Devmap::Appinfo::set_mode($mode);

        my @applines;
        my @applications = <"$builddir/apps/*/*.\L$mode\E.elf">;
        my $appinfo;
        my $socinfos = Devmap::Appinfo::get_arch_informations();

        # initialize memory layout for MPU-based device, setting requested properties
        Devmap::Mpu::elf2mem::set_numslots($socinfos->{"mpu.subregions_number"});
        Devmap::Mpu::elf2mem::set_ram_size($socinfos->{"memory.ram.size"});
        Devmap::Mpu::elf2mem::set_ram_addr($socinfos->{"memory.ram.addr"});
        Devmap::Mpu::elf2mem::set_flash_size($socinfos->{"memory.flash.\L$mode\E.size"});
        Devmap::Mpu::elf2mem::set_flash_addr($socinfos->{"memory.flash.\L$mode\E.addr"});

        my $appid = 1;
        foreach my $application (@applications) {
            my $appinfo = Devmap::Appinfo::dump_elf_metainfo($application, $appid);
            push @applines, $appinfo;
            $appid += 1;
        }

        foreach my $appinfo (@applines) {
            Ada::Format::format_appinfo_for_cfg(*CFGH, $appinfo);
        }
        close(CFGH);
    }
    elsif ($action =~ m/action=generic/) {
        #
        # Here we generate the config.applications.ads, based on the
        # applines metainformations we get back
        # These informations are language independent and are formated
        # for Ada output here
        #
        #
        open(KERN_GENAPP, ">", dirname(abs_path($0)) . "/../../src/generated/config-applications.ads") or die "unable to open output ada file for writing $!";
        @applines = gen_kernel_generic();

        #
        # First we print the template constant content into the file
        #
        open(KERN_GENAPP_TPL, "<", dirname(abs_path($0)) . "/templates/config.applications.ads.tpl") or die "unable to open output ada file for writing $!";
        while (<KERN_GENAPP_TPL>) {
            chomp;
            print KERN_GENAPP "$_";
        }
        close(KERN_GENAPP_TPL);

        # then we add the app number to the end of the task_real_id_t type
 
        print KERN_GENAPP "      range ID_APP1 .. ID_APP" . ($#applines + 1) . ";\n";

        for my $id (0 .. $#applines) {
            # In Ada, index start at 1
            print KERN_GENAPP Ada::Format::format_appid_for_kernel($applines[$id], $id + 1);
        }

        # then we define, for each application, an association between the app id and its name
        foreach my $appinfo (@applines) {
            print KERN_GENAPP Ada::Format::format_appname_for_kernel($appinfo);
        }

        # now create the list of applications portable metainformations
 
        print KERN_GENAPP "\n   list : constant array (t_real_task_id'range) of t_application := (";
        for my $id (0 .. $#applines) {
            if ($id == $#applines) {
                # delete the ',' char of the last application line
                my $line = Ada::Format::format_appinfo_for_kernel($applines[$id]);
                chop($line);
                print KERN_GENAPP $line;
            } else {
                print KERN_GENAPP Ada::Format::format_appinfo_for_kernel($applines[$id]);
            }
        }
        print KERN_GENAPP "   );\n";

        my $prefix="\U${mode}\L";
        print KERN_GENAPP "
     txt_kern_region_base : constant unsigned_32   := soc.layout.${prefix}_KERN_BASE;
     txt_kern_region_size : constant m4.mpu.t_region_size := soc.layout.${prefix}_KERN_REGION_SIZE;
     txt_kern_size        : constant unsigned_32   := soc.layout.${prefix}_KERN_SIZE;

     txt_user_region_base : constant unsigned_32   := soc.layout.${prefix}_USER_BASE;
     txt_user_region_size : constant m4.mpu.t_region_size := soc.layout.${prefix}_USER_REGION_SIZE;
     txt_user_size        : constant unsigned_32   := soc.layout.${prefix}_USER_SIZE;
";

        printf KERN_GENAPP "end config.applications;";
        # now we can close the file
        close(KERN_GENAPP);

    } elsif ($action =~ m/action=membackend/) {
        # Here we build the membackend file. This file is arch-specific and complete
        # the config.applications.ads file, which is portable.
        #

      my $socinfos = Devmap::Appinfo::get_arch_informations();
      @applines = @{gen_kernel_membackend()};
      print "cacaboudin @applines";
        open(KERN_ARCHAPP, ">", dirname(abs_path($0)) . "/../../src/generated/config-memlayout.ads") or die "unable to open output ada file for writing $!";

        #
        # First we print the template constant content into the file
        #
        open(KERN_ARCHAPP_TPL, "<", dirname(abs_path($0)) . "/templates/config.memlayout.ads.tpl") or die "unable to open output ada file for writing $!";
        while (<KERN_ARCHAPP_TPL>) {
            chomp;
            print KERN_ARCHAPP "$_";
        }
        close(KERN_ARCHAPP_TPL);

        my $i = 0;
        foreach my $line (@applines) {
            chop $line if (++$i == @applines);
            print KERN_ARCHAPP "      $line";
        }

        print KERN_ARCHAPP "   );

end config.memlayout;\n";

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

    my $socinfos = Devmap::Appinfo::get_arch_informations();

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
                         hex($hash{"app${appid}.stacksize"}) +
                         hex($hash{"app${appid}.heapsize"});

        my %hash = Devmap::Mpu::elf2mem::map_application($flash_size, $ram_size);

        my $appline = sprintf("ID_APP%d => (%d, %d, %d, %d, %s),",
            $appid, $hash{'flash_slot_start'}, $hash{'flash_slot_num'},
            $hash{'ram_slot_start'}, $hash{'ram_slot_num'}, Ada::Format::format_ada_hex($hash{'ram_free_space'}));

        push @applines, $appline;

        $appid += 1;
    }
    return \@applines;
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
        text_off    => '0',
        text_size   => '0',
        got_off     => '0',
        got_size    => '0',
        data_off    => '0',
        data_size   => '0',
        bss_size    => '0',
        heap_size   => '0',
        stack_size  => '0',
        entrypoint  => '0',
        isr_entrypoint => '0',
        domain      => '0',
        prio        => '0'
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
        text_off    => $hash{"app${id}.textoff"},
        text_size   => $hash{"app${id}.textsize"},
        got_off     => $hash{"app${id}.gotoff"},
        got_size    => $hash{"app${id}.gotsize"},
        data_off    => $hash{"app${id}.dataoff"},
        data_size   => $hash{"app${id}.datasize"},
        bss_size    => $hash{"app${id}.bsssize"},
        heap_size   => $hash{"app${id}.heapsize"},
        stack_size  => $hash{"app${id}.stacksize"},
        entrypoint  => $hash{"app${id}.entrypoint"},
        isr_entrypoint  => $hash{"app${id}.isr_entrypoint"},
        domain      => $hash{"app${id}.domain"},
        prio        => $hash{"app${id}.prio"}
    );


    # now we create the Ada table line. This line will have to be added
    # to the corresponding template
    return \%appinfo;
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
