#!/usr/bin/perl -l

#---
# Usage: ./gen_symhdr.pl <archname> <boardname> <firmnum> <.config_file>
#---

use strict;

# Add space between array element printing
$,=' ';

# Check the inputs
@ARGV == 4 or usage();
( -f "$ARGV[3]" ) or die "$ARGV[4] is not a regular as is ought to be";

my $arch    = shift;
my $board   = shift;
my $firmnum = shift;

my $out_h   = "kernel/src/C/generated/sections.h";
my $out_ads = "kernel/src/Ada/generated/sections.ads";
my $out_adb = "kernel/src/Ada/generated/sections.adb";

open my $OUT_H,   ">", "$out_h"     or die "unable to open $out_h";
open my $OUT_ADS, ">", "$out_ads"   or die "unable to open $out_ads";
open my $OUT_ADB, ">", "$out_adb"   or die "unable to open $out_adb";

my %hash;
{
  local $/;
  %hash = (<> =~ /^CONFIG_APP_([^=]+)=(.*)/mg);
}

#-----------------------------------------------------------------------------
# C header
#-----------------------------------------------------------------------------

print $OUT_H <<EOF
#ifndef APP_SECTIONS_H_
#define APP_SECTIONS_H_

#include "autoconf.h"
#include "types.h"
#include "libc.h"

EOF
;

#-----------------------------------------------------------------------------
# Ada .ads and .adb prologues
#-----------------------------------------------------------------------------

print $OUT_ADS <<EOF
with interfaces;     use interfaces;
with types;          use types;

package sections is
EOF
;

print $OUT_ADB <<EOF

package body sections is
EOF
;

#-----------------------------------------------------------------------------
# C & Ada body
#-----------------------------------------------------------------------------

my $slot = 1;

print $OUT_H "/* Applications data regions */\n";

print $OUT_ADS "
--
-- Applications data regions
--
";


foreach my $i (grep {!/_/} sort(keys(%hash))) {

    my ($data,       # .data @ in RAM
        $data_size,  # .data size
        $data_flash, # .data @ in FLASH
        $bss,        # .bss  @ in RAM
        $bss_size);  # .bss  size

    my $mode = uc($firmnum);
    chop($mode);

    next if (not defined($hash{"${i}_${mode}"}));

    $i = lc($i);

    open OBJDUMP, "$ENV{'CROSS_COMPILE'}objdump -h build/$arch/$board/apps/$i/$i.$firmnum.elf |"
        or die "Couldn't execute program: $!";

    while (defined (my $line = <OBJDUMP>)) {
        if ($line =~ /\.data/) {
            my @tab = split(/\s+/, $line);
            $data_size  = $tab[3];
            $data       = $tab[4];
            $data_flash = $tab[5];
        }
        elsif ($line =~ /\.bss/) {
            my @tab = split(/\s+/, $line);
            $bss_size   = $tab[3];
            $bss        = $tab[4];
        }
    }

    print $OUT_H "uint32_t* ${i}_data       \t= (uint32_t*) 0x$data;";
    print $OUT_H "uint32_t  ${i}_data_size  \t= 0x$data_size;";
    print $OUT_H "uint32_t* ${i}_data_flash \t= (uint32_t*) 0x$data_flash;";
    print $OUT_H "uint32_t* ${i}_bss        \t= (uint32_t*) 0x$bss;";
    print $OUT_H "uint32_t  ${i}_bss_size   \t= 0x$bss_size;";

    print $OUT_ADS "${i}_data       : constant system_address := 16#$data#;";
    print $OUT_ADS "${i}_data_size  : constant unsigned_32    := 16#$data_size#;";
    print $OUT_ADS "${i}_data_flash : constant system_address := 16#$data_flash#;";
    print $OUT_ADS "${i}_bss        : constant system_address := 16#$bss#;";
    print $OUT_ADS "${i}_bss_size   : constant unsigned_32    := 16#$bss_size#;";
}

print $OUT_H "
/* Copy applications .data and zerofiy .bss regions */

static inline void task_map_data(void) {
";

print $OUT_ADS "
-- Copy applications .data and zerofiy .bss regions
procedure task_map_data;
";

print $OUT_ADB "
   -- Copy applications .data and zerofiy .bss regions
   procedure task_map_data
   is
   begin

pragma warnings (off, \"condition is always True\");
pragma warnings (off, \"condition is always False\");
";

my $slot = 1;

foreach my $i (grep {!/_/} sort(keys(%hash))) {

    my $mode = uc($firmnum);
    chop($mode);

    next if (not defined($hash{"${i}_${mode}"}));

    $i = lc($i);


    print $OUT_H "
    if (${i}_data_size > 0) {
        memcpy(${i}_data, ${i}_data_flash, (uint32_t) ${i}_data_size);
    }

    if (${i}_bss_size > 0) {
        memset((void*) ${i}_bss, 0, ${i}_bss_size);
    }
";

    print $OUT_ADB "
      if ${i}_data_size > 0 then
         declare
            src         : byte_array (1 .. ${i}_data_size)
                                with address => to_address (${i}_data_flash);
            data_region : byte_array (1 .. ${i}_data_size)
                                with address => to_address (${i}_data);
         begin
            data_region := src;
         end;
      end if;

      if ${i}_bss_size > 0 then
         declare
            region : byte_array (1 .. ${i}_bss_size)
                                with address => to_address (${i}_bss);
         begin
            region := (others => 0);
         end;
      end if;
";

  $slot++;
}



print $OUT_H "}
#endif /*!APP_SECTION_H_*/
";

print $OUT_ADS "
end sections;
";

print $OUT_ADB "
pragma warnings (on);

   end task_map_data;

end sections;
";

#---
# Utility functions
#---

sub usage()
{
  print STDERR "usage: $0 <archname> <boardname> <firmnum> <.config_file>";
  exit(1);
}

