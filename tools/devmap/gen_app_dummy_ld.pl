#!/usr/bin/perl -l
#

use strict;
use File::Path qw(make_path);

#---
# Usage: ./gen_app_layout.pl <build_dir> <dummy_layout> <mode> <.config_file>
#---

# Check the inputs
@ARGV == 4 or usage();
( -d "$ARGV[0]" ) or die "$ARGV[0] is not a directory as is ought to be";
( -f "$ARGV[1]" ) or die "$ARGV[1] is not a regular as is ought to be";
( -f "$ARGV[3]" ) or die "$ARGV[2] is not a regular as is ought to be";

my $builddir = shift;
my $dummy    = shift;
my $mode     = shift;
my %hash;

my $DEBUG = 0;

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

    if ($DEBUG) { print "[+] opening output ldscript $builddir/apps/\L$i/$i.dummy.$mode\E.ld"; }
    make_path("$builddir/apps/\L$i");
    open(OUTLD, '>', "$builddir/apps/\L$i/$i.dummy.$mode\E.ld")
        or die "unable to open $builddir/apps/\L$i/$i.$mode\E.ld";

    if ($DEBUG) { print "[+] opening intput dummy ldscript $dummy"; }
    open(INLD, '<',"$dummy") or die "unable to open $dummy";

    my $stacksize = $hash{"${i}_STACKSIZE"} // 8192; # fallbacking to 8192
    my $heapsize = $hash{"${i}_HEAPSIZE"} // 0;

    while (my $line = <INLD>) {
        chomp($line);
        if ($line =~ m/^__is_flip = \@SELECTMODE\@/) {
            $line = "__is_flip = $is_flip;"
        }
        if ($line =~ m/^__is_flop = \@SELECTMODE\@/) {
            $line =    "__is_flop = $is_flop;"
        }
        if ($line =~ m/^__is_fw   = \@SELECTMODE\@/) {
            $line =    "__is_fw   = $is_fw;"
        }
        if ($line =~ m/^__is_dfu  = \@SELECTMODE\@/) {
            $line =    "__is_dfu  = $is_dfu;"
        }
        if ($line =~ m/\. = \. \+ \@STACKSIZE\@/) {
            $line =~ s/\. = \. \+ \@STACKSIZE\@/. = . + $stacksize;/;
        }
        if ($line =~ m/\@HEAPSIZE\@/) {
            $line =~ s/\@HEAPSIZE\@/$heapsize/;
        }
        print OUTLD "$line";
    }
    close OUTLD;
    close INLD;
} # End of inner for



#---
# Utility functions
#---

sub usage()
{
  print STDERR "usage: $0  <build_dir> <dummy_layout> <mode> <.config_file>";
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
