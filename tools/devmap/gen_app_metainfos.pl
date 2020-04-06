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

my $DEBUG = 0;

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
        # Here, we handle userspace applications informations (memory layouting
        # including MPU-related information).
        # Kernel memory layout is handled after.
        #
        my $component = "apps";

        open(CFGH, ">", "$builddir/$component/layout.\L$mode\E.cfg") or die "unable to open $component cfg file for writing: $!";
        Devmap::Appinfo::set_builddir($builddir);
        Devmap::Appinfo::set_mode($mode);
        # here we handle applications (not kernel)
        Devmap::Appinfo::set_component($component);

        my @applines;
        my @applications = <"$builddir/$component/*/*.\L$mode\E.elf">;
        my $appinfo;
        my $socinfos = Devmap::Appinfo::get_arch_informations();

        if ($socinfos->{"soc.memorymodel"} =~  m/mpu/) {
            # initialize memory layout for MPU-based device, setting requested properties
            Devmap::Mpu::elf2mem::set_numslots($socinfos->{"mpu.subregions_number"});
            Devmap::Mpu::elf2mem::set_ram_size($socinfos->{"memory.ram.$component.size"});
            Devmap::Mpu::elf2mem::set_ram_addr($socinfos->{"memory.ram.$component.addr"});
            Devmap::Mpu::elf2mem::set_flash_size($socinfos->{"memory.flash.\L$mode\E.$component.size"});
            Devmap::Mpu::elf2mem::set_flash_addr($socinfos->{"memory.flash.\L$mode\E.$component.addr"});
        } elsif ($socinfos->{"soc.memorymodel"} =~  m/mmu/) {
            # initialize memory layout for MMU-based device, setting requested properties
            # TODO
        } else {
            print "Error! Unsupported memory model " . $socinfos->{"soc.memorymodel"} . "!";
            exit 1;
        }

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

        printf KERN_GENAPP "end config.applications;";
        # now we can close the file
        close(KERN_GENAPP);

    } elsif ($action =~ m/action=membackend/) {
        # Here we build the membackend file. This file is arch-specific and complete
        # the config.applications.ads file, which is portable.
        #

      my $socinfos = Devmap::Appinfo::get_arch_informations();
      @applines = @{gen_kernel_membackend()};
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
      print KERN_ARCHAPP "   );\n";

      # let's now, create kernel region information. This handle kernel memory
      # this hold flash and RAM memory address and size.
      print KERN_ARCHAPP "   kernel_region : constant t_kernel_region := (
      " . Ada::Format::format_ada_hex($socinfos->{"memory.flash.\L$mode\E.kern.addr"}) . ",
      " . $socinfos->{"memory.flash.\L$mode\E.kern.size"} . ",
      " . $socinfos->{"memory.flash.\L$mode\E.kern.regionsize"} . ",
      " . Ada::Format::format_ada_hex($socinfos->{"memory.ram.kernel.addr"}) . ",
      " . $socinfos->{"memory.flash.\L$mode\E.kern.size"} . ",
      " . $socinfos->{"memory.ram.kernel.regionsize"} .");\n";

      #
      # let's now, create applications region informations
      print KERN_ARCHAPP "   apps_region : constant t_applications_region := (
      " . Ada::Format::format_ada_hex($socinfos->{"memory.flash.\L$mode\E.apps.addr"}) . ",
      " . $socinfos->{"memory.flash.\L$mode\E.apps.size"} . ",
      " . $socinfos->{"memory.flash.\L$mode\E.apps.regionsize"} . ",
      " . Ada::Format::format_ada_hex($socinfos->{"memory.ram.apps.addr"}) . ",
      " . $socinfos->{"memory.ram.apps.size"} . ",
      " . $socinfos->{"memory.ram.apps.regionsize"} .");\n";


       print KERN_ARCHAPP "end config.memlayout;";

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
    # Here we handle membackend for applications, not kernel.
    #
    my @applications = <"$builddir/apps/*/*.dummy.\L$mode\E.elf">;
    my $appid = 1;
    my $component = "apps";

    my $socinfos = Devmap::Appinfo::get_arch_informations();

    if ($socinfos->{"soc.memorymodel"} =~  m/mpu/) {
        if ($DEBUG) { print "[+] Handling MPU based memory model"; }
        # initialize memory layout
        Devmap::Mpu::elf2mem::set_numslots($socinfos->{'mpu.subregions_number'});
        Devmap::Mpu::elf2mem::set_ram_size($socinfos->{"memory.ram.$component.size"});
        Devmap::Mpu::elf2mem::set_ram_addr($socinfos->{"memory.ram.$component.addr"});
        Devmap::Mpu::elf2mem::set_flash_size($socinfos->{"memory.flash.\L$mode\E.$component.size"});
        Devmap::Mpu::elf2mem::set_flash_addr($socinfos->{"memory.flash.\L$mode\E.$component.addr"});
    } elsif ($socinfos->{"soc.memorymodel"} =~  m/mmu/) {
        # initialize memory layout for MMU-based device, setting requested properties
        # TODO
        if ($DEBUG) { print "[+] MMU based memory model not yet supported"; }
        exit 1;
    } else {
        print "Error! Unsupported memory model " . $socinfos->{"soc.memorymodel"} . "!";
        exit 1;
    }


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
        my %hash;
        if ($socinfos->{"soc.memorymodel"} =~ m/mpu/) {
            if ($DEBUG) { print "[+] mapping application to MPU based memory model"; }
            %hash = Devmap::Mpu::elf2mem::map_application($flash_size, $ram_size);
        } elsif ($socinfos->{"soc.memorymodel"} =~ m/mmu/) {
            # initialize memory layout for MMU-based device, setting requested properties
            # TODO
            exit 1;
        } else {
            print "Error! Unsupported memory model " . $socinfos->{"soc.memorymodel"} . "!";
            exit 1;
        }

        my $appline = sprintf("ID_APP%d => (%d, %d, %d, %d, %s),",
            $appid, $hash{'flash_slot_start'}, $hash{'flash_slot_num'},
            $hash{'ram_slot_start'}, $hash{'ram_slot_num'}, Ada::Format::format_ada_hex($hash{'ram_free_space'}));

        if ($socinfos->{"soc.memorymodel"} =~  m/mpu/) {
            # let's check that there is no overflow
            if (($hash{'flash_slot_start'} + $hash{'flash_slot_num'} - 1) > $socinfos->{'mpu.subregions_number'}) {
                print "Error! Unable to map application $appid in flash! too many slots consumed for backend architecture!";
                exit 1;
            }
            if (($hash{'ram_slot_start'} + $hash{'ram_slot_num'} - 1) > $socinfos->{'mpu.subregions_number'}) {
                print "Error! Unable to map application $appid in RAM! too many slots consumed for backend architecture!";
                exit 1;
            }
        }
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


sub usage {
  print STDERR "usage: $0  <build_dir> <mode> <action>";
  exit(1);
}



main();
