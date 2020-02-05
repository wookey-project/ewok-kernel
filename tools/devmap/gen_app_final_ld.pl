#!/usr/bin/perl -l
#

use strict;
# getting back script path
use File::Basename qw(dirname basename);
use File::Path qw(make_path);
use File::Path qw(make_path);
use Cwd  qw(abs_path);
# and update @INC
use lib dirname(dirname abs_path $0) . '/devmap/lib';

use Devmap::Appinfo;
use Devmap::Mpu::elf2mem;

#---
# Usage: ./gen_app_layout.pl <build_dir> <final_layout> <mode> <.config_file>
#---

# Check the inputs
@ARGV == 4 or usage();
( -d "$ARGV[0]" ) or die "$ARGV[0] is not a directory as it ought to be";
( -f "$ARGV[1]" ) or die "$ARGV[1] is not a regular as it ought to be";
( -f "$ARGV[3]" ) or die "$ARGV[2] is not a regular as it ought to be";

my $builddir = shift;
my $final    = shift;
my $mode     = shift;
my %hash;

my $DEBUG = 1;

#---
# Generate dummy ldscript file
#---

# Slurp the config file and parse it
get_apps_from_config();

# Iterate over all modes
my $is_flip = 0;
my $is_flop = 0;
my $is_fw   = 0;
my $is_dfu  = 0;

if ($mode =~ "FW1") {
    $is_flip = 0xf0;
    $is_fw   = 0xf0;
}
if ($mode =~ "FW2") {
    $is_flop = 0xf0;
    $is_fw   = 0xf0;
}
if ($mode =~ "DFU1") {
    $is_flip = 0xf0;
    $is_dfu  = 0xf0;
}
if ($mode =~ "DFU2") {
    $is_flop = 0xf0;
    $is_dfu  = 0xf0;
}


# Iterate over all apps
for my $i (grep {!/_/} sort(keys(%hash))) {
    
    if ($DEBUG) { print "[+] handling $i"; }
    # Leave if this app is not for current mode
    my $stem_mode=($mode=~s/[12]$//r);
    next if (not defined($hash{"${i}_${stem_mode}"}));
      
    if ($DEBUG) { print "[+] $i has to be handled in $mode"; }

    if ($DEBUG) { print "[+] opening output ldscript $builddir/apps/\L$i/$i.final.$mode\E.ld"; }
    make_path("$builddir/apps/\L$i");
    open(OUTLD, '>', "$builddir/apps/\L$i/$i.final.$mode\E.ld")
        or die "unable to open $builddir/apps/\L$i/$i.$mode\E.ld";

    if ($DEBUG) { print "[+] opening input final ldscript $final"; }
    
    open APPCFG, "$builddir/apps/layout.\L$mode\E.cfg" or die "Unable to open layout $!";
    #extract obly the relevant configuration informations
    my $appcfg;
    {
      local $/;
      my @tmp;
      @tmp=(<APPCFG>=~/((app\d+).*=$i\n(\2.*?\n)*)/im);
      $appcfg=$tmp[0];
    }
    #make it a hash :-)
    #delete "appXX." prefix 
    $appcfg=~s/^app\d+\.//gm;
    my %hashcfg=($appcfg=~/([^=]+)=(.*)\n/g);
    open(INLD, '<',"$final") or die "unable to open $final";
    my $final_ldscript;
    {
      local $/;
      $final_ldscript=<INLD>;
    }
    close INLD;
    # SET FLASH and RAM at the right value

    my $stacksize = $hash{"${i}_STACKSIZE"} // 8192; # fallbacking to 8192
    my $heapsize = $hash{"${i}_HEAPSIZE"} // 0;
    my $socinfos = Devmap::Appinfo::get_arch_informations();
    
    
   $final_ldscript =~ s/__is_flip\s+=\s+\@SELECTMODE\@/__is_flip = $is_flip/;
   $final_ldscript =~ s/__is_flop\s+=\s+\@SELECTMODE\@/__is_flop = $is_flop/;
   $final_ldscript =~ s/__is_fw\s+=\s+\@SELECTMODE\@/__is_fw = $is_fw/;
   $final_ldscript =~ s/__is_dfu\s+=\s+\@SELECTMODE\@/__is_dfu = $is_dfu/;
   $final_ldscript =~ s/\@STACKSIZE\@/$stacksize/;
   $final_ldscript =~ s/\@HEAPSIZE\@/$heapsize/;

   print( "memory.flash." . lc($mode) . ".addr" . " => " . $socinfos->{"memory.flash." . lc($mode) . ".addr"});

   my $mode2=lc($mode);
   $final_ldscript =~ s/\@ORIGIN_FLASH\@/(sprintf("0x%08x", (hex($socinfos->{"memory.flash.$mode2.addr"})+$hashcfg{"textoff"})))/e;
   $final_ldscript =~ s/\@LENGTH_FLASH\@/(sprintf("0x%08x", hex($hashcfg{"textsize"})+hex($hashcfg{"datasize"})+hex($hashcfg{"gotsize"})))/e;
   $final_ldscript =~ s/\@ORIGIN_RAM\@/(sprintf("0x%08x", hex($socinfos->{"memory.ram.addr"})+$hashcfg{"dataoff"}))/e;
   # INFO: why +wordsize here ???? Good question :-)
   # ldscripts hold _s_data, _e_data, _s_bss, _e_bss, and so one symbols, which permit to get back addresses of various sections in RAM.
   # This sections are used in order to calculate application mapping and typically used by the allocator.
   # Although, if some of these symbols address are hold in the corresponding section, there is an exception for _e_data, because this section
   # is specific, having a differenciate VMA & LMA and being calculated differently from the other by the Ldscript. As a consequence, the
   # .bss section start wordsize bytes *after* the end of the .data section, instead of directly after it. This particularity is hold here.
   $final_ldscript =~ s/\@LENGTH_RAM\@/(sprintf("0x%08x", hex($hashcfg{"stacksize"})+hex($hashcfg{"datasize"})+hex($hashcfg{"bsssize"})+hex($hashcfg{"heapsize"}) + $socinfos->{"arch.wordsize"} ))/e;

   print OUTLD "$final_ldscript";
   close OUTLD;
} # End of inner for



#---
# Utility functions
#---

sub usage()
{
  print STDERR "usage: $0  <build_dir> <final_layout> <mode> <.config_file>";
  exit(1);
}

sub get_apps_from_config()
{
  local $,=' ';
  local $/;
  my $tmp=<>;

  # A config file line can be one of : empty/start with # /or start with CONFIG
  $tmp =~ /^(\s*\n|\s*#.*\n|\s*CONFIG([^=]+)=(.*)\n)*$/
  	or die "WARNING: your config file does not look correct";

  %hash = ($tmp =~ /^CONFIG_APP_([^=]+)=(.*)/mg);
}
