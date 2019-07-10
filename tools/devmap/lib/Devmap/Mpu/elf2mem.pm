package Devmap::Mpu::elf2mem;
use strict;
use warnings;

use Exporter qw(import);

our @EXPORT_OK = qw(set_numslots set_ram_size set_flash_size map_application);

my $numslot = 0;
my $ramsize = 0;
my $ramaddr = 0;
my $flashsize = 0;
my $flashaddr = 0;

my $cur_ram_slot = 0;
my $cur_flash_slot = 0;

# set current MPU slot number per region
sub set_numslots {
    my ($val) = @_;
    $numslot = $val;
    $cur_ram_slot = 0;
    $cur_flash_slot = 0;
}

sub set_ram_size {
    my ($val) = @_;
    $ramsize = $val;
}

sub set_ram_addr {
    my ($val) = @_;
    $ramaddr = $val;
}

sub set_flash_size {
    my ($val) = @_;
    $flashsize = $val;
}

sub set_flash_addr {
    my ($val) = @_;
    $flashaddr = $val;
}

sub map_application {
    my ($app_flash_size, $app_ram_size) = @_;
    my $ram_slot_consumed = 1;
    my $flash_slot_consumed = 1;

    my $ram_slot_size = $ramsize / $numslot;
    my $flash_slot_size = $flashsize / $numslot;

    while ($app_flash_size > ($flash_slot_size * $flash_slot_consumed)) {
        $flash_slot_consumed += 1;
    }
    while ($app_ram_size > ($ram_slot_size * $ram_slot_consumed)) {
        $ram_slot_consumed += 1;
    }

    my %appslotting = (
        ram_slot_addr  => sprintf("0x%08x", (hex($ramaddr) + ($cur_ram_slot * ($ramsize / $numslot)))),
        ram_slot_start => $cur_ram_slot,
        ram_slot_num   => $ram_slot_consumed,
        ram_free_space => (($ram_slot_size * $ram_slot_consumed) - $app_ram_size),
        flash_slot_addr  =>  sprintf("0x%08x", (hex($flashaddr) + ($cur_flash_slot * ($flashsize / $numslot)))),
        flash_slot_start => $cur_flash_slot,
        flash_slot_num   => $flash_slot_consumed
    );

    print("slot size: $ram_slot_size, consumed: $app_ram_size");
    $cur_ram_slot += $ram_slot_consumed;
    $cur_flash_slot += $flash_slot_consumed;
    return %appslotting;
}


1;
