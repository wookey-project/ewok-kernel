#!/usr/bin/perl


#-------------------------------------------------------------
# Purpose:
# - generating a C and Ada header containing both ressource
#   and communication permissions for userspace tasks
# Requirements:
# - a fullfilled IPC matrix in apps/ipc.config
# - a fullfilled DMA SHM matrix in apps/dmashm.config
# - a configured MosEsley project (i.e. correct .config file)
# Method:
# - In mosesley, this script is automatically called by the
#   prepare target
# Syntax: permission.pl <.config> <matrix> <...>
# Notes:
# - IPC and DMA_SHM matrix argument order is not impacting
# - This script is able to generate one, two or any matrix
#   as needed, if some new communication matrices appear
# Todo:
# - activating use strict require to clean %hashperm param
#   reference passing
#--------------------------------------------------------------

#
# This Global variable contains the current selected apps.
# It applies to all the config files
#

my %hash;
my $mode = shift;

#
# Parse the config file and extract all needed items
#
# This block extract all activated application related options
# (including name) in hash
#

sub parse_config
{
  local $/;
  open my $configfile, $ARGV[0] or die "unable to open config file";

  %hash = (<$configfile> =~ /^CONFIG_APP_([^=]+)=(.*)/mg);
}


#
# Parse ressources permissions from config
#
# All ressources permissions are set through Kconfig. These permissions are
# then stored as a 32 bit register for earch application.
#

sub parse_ressource_perms
{
  my $app = shift;
  my $register = 0b00000000000000000000000000000000;

  # get back permission values
  my $perm_dev_dma = 0;
  my $perm_dev_crypto = 0;
  my $perm_dev_exti = 0;
  my $perm_dev_bus = 0;
  my $perm_dev_tim = 0;
  my $perm_tim_cycles = 0;
  my $perm_tsk_fisr = 0;
  my $perm_tsk_fipc = 0;
  my $perm_tsk_rst = 0;
  my $perm_tsk_upg = 0;
  my $perm_tsk_rng = 0;
  my $perm_mem_dmap = 0;

  if ($hash{"${app}_PERM_DEV_DMA"} eq "y") {
      $perm_dev_dma = 1;
  }
  if ($hash{"${app}_PERM_DEV_CRYPTO"} != undef) {
      $perm_dev_crypto = $hash{"${app}_PERM_DEV_CRYPTO"};
  }
  if ($hash{"${app}_PERM_DEV_BUSES"} eq "y") {
      $perm_dev_bus = 1;
  }
  if ($hash{"${app}_PERM_DEV_EXTI"} eq "y") {
      $perm_dev_exti = 1;
  }
  if ($hash{"${app}_PERM_DEV_TIM"} eq "y") {
      $perm_dev_tim = 1;
  }
  if ($hash{"${app}_PERM_TIM_GETCYCLES"} != undef) {
      $perm_tim_cycles = $hash{"${app}_PERM_TIM_GETCYCLES"};
  }
  if ($hash{"${app}_PERM_TSK_FISR"} eq "y") {
      $perm_tsk_fisr = 1;
  }
  if ($hash{"${app}_PERM_TSK_FIPC"} eq "y") {
      $perm_tsk_fipc = 1;
  }
  if ($hash{"${app}_PERM_TSK_RST"} eq "y") {
      $perm_tsk_rst = 1;
  }
  if ($hash{"${app}_PERM_TSK_UPGRADE"} eq "y") {
      $perm_tsk_upg = 1;
  }
  if ($hash{"${app}_PERM_TSK_RNG"} eq "y") {
      $perm_tsk_rng = 1;
  }
  if ($hash{"${app}_PERM_MEM_DYNAMIC_MAP"} eq "y") {
      $perm_mem_dmap = 1;
  }
  # generate the register
  $register = ($perm_dev_dma << 31) | ($perm_dev_crypto << 29) | ($perm_dev_bus << 28) | ($perm_dev_exti << 27) | ($perm_dev_tim << 26) | ($perm_tim_cycles << 22) | ($perm_tsk_fisr << 15) | ($perm_tsk_fipc << 14) | ($perm_tsk_rst << 13) | ($perm_tsk_upg << 12) | ($perm_tsk_rng << 11) | ($perm_mem_dmap << 7);
  return $register;
}


#
# Parse text matrix
#
# Matrix must respect the structure define in EwoK permission API
# documentation. Application order is not impacting. If an application
# is not in the matrix and is enabled in the conf, it will not be able
# to communicate with others. If an application is configured in the
# matrix but is not enabled in the configuration, it will be dropped from
# the generated header matrix
#
# Parse_matrix is language-independent.
#

sub parse_matrix
{
  my $text=shift;
  my $hashperm=shift;
  $text=~s/^#.*//;
  my @preprocessed=($text=~/"(.*)"/g);
  my @colnam=$preprocessed[0]=~/(\S+)/g;
  shift @colnam;# colnam contains the columns names
  map {s/.*/\U$&/} @colnam; #upcase every name

  shift @preprocessed;
  for my $i (@preprocessed)
  {
    my ($name)=($i=~/(\w+)/);
    my @columns=$i=~/\[(.)\]/g;
    uc($name);
    my $cpt=0;
    for my $j (@columns)
     {
       $hashperm{$name}{$colnam[$cpt]}=($j==1)+0;
       $cpt++;
     }
  }
}

#######################################################
# ADA HEADER FILE RELATED FUNCTIONS
# This functions are used to generate the Ada header file
#######################################################


#
# \brief generate the table of ressource registers based on the configuration
#
# Each application has its own ressource permission register. This function
# generate the Ada format ressource table for all applications
#
# Here we don't generate a uint32 register as the register is declared as a
# fully-typed Ada record instead of a bitfield.
#
sub generate_ada_ressource_perm
{
  my $outfile=shift;
  my $register = 0;

  my $string = "   ressource_perm_register_tab : constant array (t_real_task_id'range) of t_ressource_reg :=\n      (\n";
  my $appid = 1;

  foreach my $app (grep {!/_/} sort(keys(%hash)))
  {
    next if (not defined($hash{"${app}_${mode}"}));
    # array of dev ressources
    my @devperms = ("DMA", "CRYPTO", "BUSES", "EXTI", "TIM");

    # array of task ressources
    my @tskperms = ("FISR", "FIPC", "RESET", "UPGRADE", "RNG");

    $string .= "       -- ressource_perm_register for $app\n";
    $string .= "       ID_APP$appid => (\n";
    $appid = $appid + 1;

    #
    # looping on array ressources
    #
    if ($hash{"${app}_PERM_DEV_DMA"} eq "y") {
      $string .= "        DEV_DMA        => 1,\n";
    } else {
      $string .= "        DEV_DMA        => 0,\n";
    }

    if ($hash{"${app}_PERM_DEV_CRYPTO"} != undef) {
      $string .= "        DEV_CRYPTO     => $hash{\"${app}_PERM_DEV_CRYPTO\"},\n";
    } else {
      $string .= "        DEV_CRYPTO     => 0,\n";
    }

    if ($hash{"${app}_PERM_DEV_BUSES"} eq "y") {
      $string .= "        DEV_BUS        => 1,\n";
    } else {
      $string .= "        DEV_BUS        => 0,\n";
    }

    if ($hash{"${app}_PERM_DEV_EXTI"} eq "y") {
      $string .= "        DEV_EXTI       => 1,\n";
    } else {
      $string .= "        DEV_EXTI       => 0,\n";
    }

    if ($hash{"${app}_PERM_DEV_TIM"} eq "y") {
      $string .= "        DEV_TIM        => 1,\n";
    } else {
      $string .= "        DEV_TIM        => 0,\n";
    }


    $string .= "        DEV_reserved   => 0,\n";

    #
    # time ressource
    #
    if ($hash{"${app}_PERM_TIM_GETCYCLES"} != undef) {
        $string .= "        TIM_TIME       => $hash{\"${app}_PERM_TIM_GETCYCLES\"},\n";
    } else {
        $string .= "        TIM_TIME       => 0,\n";
    }
    $string .= "        TIM_reserved   => 0,\n";

    #
    # looping on task ressources
    #
    for (@tskperms) {
      if ($hash{"${app}_PERM_TSK_$_"} eq "y") {
          $string .= "        TSK_$_       => 1,\n";
      } else {
          $string .= "        TSK_$_       => 0,\n";
      }
    }
    $string .= "        TSK_reserved   => 0,\n";

    #
    # mem ressource
    #
    if ($hash{"${app}_PERM_MEM_DYNAMIC_MAP"} eq "y") {
        $string .= "        MEM_DYNAMIC_MAP => 1,\n";
    } else {
        $string .= "        MEM_DYNAMIC_MAP => 0,\n";
    }
    $string .= "        MEM_reserved   => 0),\n";
  }
  $string =~ s/,\n$/);\n\n/;
  print $outfile $string;
}


#
# \brief generate a boolean matrix for Ada header
#
# This function is based on the output of parse_matrix.
#
sub generate_ada_matrix
{
  my $hashperm=shift;
  my $tabname=shift;
  my $outfile=shift;

  # ass bool tab[][] is not allowed in C, we must
  # fixed one of the table depth. As te matrix is
  # a square based on the number of applications,
  # we use it for table depth
  my @apps = (grep {/.*_${mode}$/} (sort keys %hash));
  my $appnum = @apps;

  my $string="   -- $tabname communication permissions
   com_${tabname}_perm : constant t_com_matrix := \n      (";

  for my $i (grep {!/_/} (sort keys %hash))
  {
    next if (not defined($hash{"${i}_${mode}"}));
    my $appid=1;
    $string .= "$i\t=> (";
    for my $j (grep {!/_/} (sort keys %hash))
    {
      next if (not defined($hash{"${j}_${mode}"}));
      if (($hashperm{$i}{$j}) == 1) {
        $string .= "ID_APP$appid => true,  ";
      } else {
        $string .= "ID_APP$appid => false, ";
      }
      $appid += 1;
    }
    $string =~ s/, +$/),\n       /;
  }

  $string =~ s/,\n       $/);\n\n/;
  print $outfile $string;
}

#
# \brief generate C header first lines
#
# This function add preprocessing content at the begining of the
# header file
#
sub generate_ada_header
{
  my $outfile=shift;
  my @apps = (grep {!/_/} (sort keys %hash));

  my $head_string="
with applications;      use applications;
with ewok.tasks_shared; use ewok.tasks_shared;

package ewok.perm_auto
   with spark_mode => on
is

   -- ressource register definition
   type t_ressource_reg is record
      DEV_DMA         : bit;
      DEV_CRYPTO      : bits_2;
      DEV_BUS         : bit;
      DEV_EXTI        : bit;
      DEV_TIM         : bit;
      DEV_reserved    : bits_2;
      TIM_TIME        : bits_2;
      TIM_reserved    : bits_6;
      TSK_FISR        : bit;
      TSK_FIPC        : bit;
      TSK_RESET       : bit;
      TSK_UPGRADE     : bit;
      TSK_RNG         : bit;
      TSK_reserved    : bits_3;
      MEM_DYNAMIC_MAP : bit;
      MEM_reserved    : bits_7;
   end record
      with Size => 32;

   for t_ressource_reg use record
      DEV_DMA         at 0 range 31 .. 31;
      DEV_CRYPTO      at 0 range 29 .. 30;
      DEV_BUS         at 0 range 28 .. 28;
      DEV_EXTI        at 0 range 27 .. 27;
      DEV_TIM         at 0 range 26 .. 26;
      DEV_reserved    at 0 range 24 .. 25;
      TIM_TIME        at 0 range 22 .. 23;
      TIM_reserved    at 0 range 16 .. 21;
      TSK_FISR        at 0 range 15 .. 15;
      TSK_FIPC        at 0 range 14 .. 14;
      TSK_RESET       at 0 range 13 .. 13;
      TSK_UPGRADE     at 0 range 12 .. 12;
      TSK_RNG         at 0 range 11 .. 11;
      TSK_reserved    at 0 range  8 .. 10;
      MEM_DYNAMIC_MAP at 0 range  7 .. 7;
      MEM_reserved    at 0 range  0 .. 6;
   end record;

   type t_com_matrix is
     array (t_real_task_id'range, t_real_task_id'range) of Boolean;\n\n";

  print $outfile $head_string;
}

#
# \brief generate C header last lines
#
# This function add preprocessing content at the end of the
# header file
#
sub generate_ada_footer
{
  my $outfile=shift;
  my $foot_string="

end ewok.perm_auto;
";

  print $outfile $foot_string;
}


#
# Main program
#
sub main
{
  parse_config;
  local $/;
  # We shift the config file from argv as it has been parsed
  shift @ARGV;

  my $ada_header = "kernel/src/Ada/generated/ewok-perm_auto.ads";

  #
  # Ada header file generation
  #
  open my $ADA_HEADER, ">", "$ada_header" or die "Unable to open $ada_header";

  # Starting file
  generate_ada_header($ADA_HEADER);

  # Generate ressource permission registers table
  generate_ada_ressource_perm($ADA_HEADER);

  #
  # Generate communication matrices
  #

  # Aliases
  my $count = 1;
  for my $i (grep {!/_/} (sort keys %hash))
  {
    next if (not defined($hash{"${i}_${mode}"}));
    print $ADA_HEADER "   $i : constant t_real_task_id := ID_APP$count;\n";
    $count++;
  }
  print $ADA_HEADER "\n";

  while (@ARGV)
  {
    my $file = $ARGV[0];
    my $configfile=<>;
    my $hashperm;

    $file =~ s/(.*\/)(.*)\..*/\2/g;

    parse_matrix($configfile,\%hashperm);
    generate_ada_matrix($hashperm, $file, $ADA_HEADER);
  }

  # End of file
  generate_ada_footer($ADA_HEADER);

  close $ADA_HEADER;

  #
  # Ada header file generation
  #
}

main();
