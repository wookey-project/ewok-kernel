#!/usr/bin/perl -l
#
##---
# Usage: ./gen_app_layout.pl <build_dir> <mode> <action>
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


sub main {
    my @applines;
    print "$action";
    if ($action =~ m/action=genappcfg/) {
        # generate configuration file
        #   req: dummy ELF file
        open(CFGH, ">", "$builddir/apps/layout.\L$mode\E.cfg") or die "unable to open app cfg file for writing: $!";
        @applines = gen_application_layout($action);
        foreach my $appinfo (@applines) {
            format_appinfo_for_cfg(*CFGH, $appinfo);
        }
        close(CFGH);
    }
    elsif ($action =~ m/action=generic/) {
        @applines = gen_application_layout($action);
        foreach my $appinfo (@applines) {
            print format_appinfo_for_kernel($appinfo);
        }
    } elsif ($action =~ m/action=membackend/) {
        gen_kernel_membackend();
    } else {
        print ("unknown action $action !");
        exit 1;
    }
}

################################################################
# Iterate over all apps in current mode
#
#
sub gen_kernel_membackend {
    my @applines;
    my @cfglines;
    my @applications = <"$builddir/apps/*/*.dummy.\L$mode\E.elf">;
    my $appid = 1;

    # initialize memory layout
    Devmap::Mpu::elf2mem::set_numslots(8);
    Devmap::Mpu::elf2mem::set_ram_size(262144);
    Devmap::Mpu::elf2mem::set_flash_size(524288);


    foreach my $application (@applications) {
        # 1) open the ELF file
        Devmap::Elfinfo::openelf($application);

        # 2) get back the requested RAM and Flash size, using the ELF binary
        my $flash_size = get_flash_size();
        my $ram_size = get_ram_size();

        my %hash = Devmap::Mpu::elf2mem::map_application($flash_size, $ram_size);
        my $appline = sprintf("ID_APP%d => (%d, %d, %d, %d),",
            $appid, $hash{'flash_slot_start'}, $hash{'flash_slot_num'},
            $hash{'ram_slot_start'}, $hash{'ram_slot_num'});

        push @applines, $appline;

        $appid += 1;
    }
    foreach my $line (@applines) {
        print($line);
    }
}




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
#
sub gen_application_layout {
    my ($action) = @_;

    my @applines;
    my @applications = <"$builddir/apps/*/*.\L$mode\E.elf">;
    my $appid = 1;
    foreach my $application (@applications) {

        my $appname;


        # when generating cfg, we parse dummy ELF files to get back all
        # needed informations. This is the lonely time where we parse ELF
        # files
        if ($action =~ m/action=genappcfg/) {

            $appname = basename($application,  ".dummy.\L$mode\E.elf");
            next if ($application =~ m/.*\/[^.]*\.\L$mode\E.elf/);

            # 1) open the ELF file
            Devmap::Elfinfo::openelf($application);

        } elsif  ($action =~ m/action=generic/) {
            $appname = basename($application,  ".\L$mode\E.elf");
            next if ($application =~ m/.*\.dummy\.\L$mode\E.elf/);
        }

        # 3) Generate the arch-independent generic structure 'config.application_layout.ads

        my $appinfo = create_app_generic_info($action, $appname, $appid);
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
    my ($action, $application, $id) = @_;

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

    if ($action =~ m/action=genappcfg/) {
        # foreach requested sections, get back needed informations to
        # the hash table
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

        $appinfo{'name'} = $application;
        $appinfo{'id'} = $id;

    } elsif ($action =~ m/action=generic/) {
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

    }


    # now we create the Ada table line. This line will have to be added
    # to the corresponding template
    return \%appinfo;
}

sub format_ada_hex {
    my ($val) = @_;
    # iThe output is in Ada, we translate here from the
    # generic 0x08p format into Ada hexadecimal format
    $val =~ s/0x(\d{4})(\d{4})/16#$1_$2#/;
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
    print FH "app$id.datasize=$appinfo->{'data_addr'}";
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
