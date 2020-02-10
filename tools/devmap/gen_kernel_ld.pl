#!/usr/bin/perl -l

# usage:
# $0 <build_dir> <mode> <ld.in>
# build dir is relative to kernel path
use strict;
# getting back script path
use File::Basename qw(dirname basename);
use File::Path qw(make_path);
use File::Path qw(make_path);
use Cwd  qw(abs_path);
# and update @INC
use lib dirname(dirname abs_path $0) . '/devmap/lib';

use File::Basename qw(dirname basename);
use Cwd  qw(abs_path);

use Devmap::Appinfo;


sub usage()
{
  print STDERR "usage: $0  <build_dir> <mode> <ld_in>";
  exit(1);
}


@ARGV == 3 or usage();


my $build_dir = shift;
my $mode      = shift;
my $ld_in     = shift;


open(INLD, '<',"$ld_in") or die "unable to open $ld_in";
my $final_ldscript;
{
    local $/;
    $final_ldscript=<INLD>;
}
close INLD;

# get back soc informations
my $socinfos = Devmap::Appinfo::get_arch_informations();

$final_ldscript =~ s/\@ORIGIN_FLASH\@/(sprintf("0x%08x", (hex($socinfos->{"memory.flash.\L$mode\E.kern.addr"}))))/e;
$final_ldscript =~ s/\@LENGTH_FLASH\@/(sprintf("0x%08x", $socinfos->{"memory.flash.\L$mode\E.kern.size"}))/e;
$final_ldscript =~ s/\@ORIGIN_RAM\@/(sprintf("0x%08x", hex($socinfos->{"memory.ram.kernel.addr"})))/e;
$final_ldscript =~ s/\@LENGTH_RAM\@/(sprintf("0x%08x", $socinfos->{"memory.ram.kernel.size"}))/e;


open(OUTLD, ">", "$build_dir/kernel/kernel.\L$mode\E.ld") or die "unable to open output ldscript file for writing $!";
print OUTLD "$final_ldscript";
close OUTLD;
