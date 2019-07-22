#!/usr/bin/perl -l

# usage:
# $0 <build_dir> <app_name> <ld.in> <ld.out>
# build dir is relative to kernel path
use strict;
use File::Basename qw(dirname basename);
use Cwd  qw(abs_path);

my $kernel_src_root = dirname(abs_path($0)) . "/../";

my $build_dir = shift;
my $app_name  = shift;
my $ld_in     = shift;
my $ld_out    = shift;

open(INLD, "<", $ld_in) or die "unable to input ldscript file for reading $!";
open(OUTLD, ">", $ld_out) or die "unable to open output ldscript file for writing $!";

while (my $line = <INLD>) {
    chomp($line);
    if ($line =~ m/(.*)FLASHMAP_KERN(.*)/) {
        my $prefix = $1;
        my $suffix = $2;
        my ($mode) = ${app_name} =~ /\.(.*)$/;
        $line =    "${prefix}\U${mode}\E_KERN${suffix}";
        print OUTLD "$line";
    }
    elsif ($line =~ m/^INCLUDE (.*)/) {
        my $layoutfile = $line =~ /^INCLUDE (.*)$/;
        my $data=`cat $build_dir/layout.ld`;
        print OUTLD "$data";
    }
    else {
        print OUTLD "$line";
    }
}

close(OUTLD);
close(INLD);
