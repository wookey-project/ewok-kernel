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

my $cur_ram_slot = 1;
my $cur_flash_slot = 1;

# set current MPU slot number per region
sub set_numslots {
    my ($val) = @_;
    $numslot = $val;
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
    my ($app_flash_size, $app_ram_size, $app_name, $app_id) = @_;
    my $ram_slot_consumed = 1;
    my $flash_slot_consumed = 1;

    my $ram_slot_size = $ramsize / $numslot;
    my $flash_slot_size = $flashsize / $numslot;
    printf("---> map application (name = %s, id = %d): flash size: 0x%x, ram size: 0x%x\n", $app_name, $app_id, $app_flash_size, $app_ram_size);

    while ($app_flash_size > ($flash_slot_size * $flash_slot_consumed)) {
        $flash_slot_consumed += 1;
    }
    while ($app_ram_size > ($ram_slot_size * $ram_slot_consumed)) {
        $ram_slot_consumed += 1;
    }

    my %appslotting = (
        ram_slot_addr  => sprintf("0x%08x", (hex($ramaddr) + (($cur_ram_slot - 1) * ($ramsize / $numslot)))),
        ram_slot_start => $cur_ram_slot,
        ram_slot_num   => $ram_slot_consumed,
        ram_free_space => sprintf("0x%08x",(($ram_slot_size * $ram_slot_consumed) - $app_ram_size)),
        flash_slot_addr  =>  sprintf("0x%08x", (hex($flashaddr) + (($cur_flash_slot - 1) * ($flashsize / $numslot)))),
        flash_slot_start => $cur_flash_slot,
        flash_slot_num   => $flash_slot_consumed
    );

    $cur_ram_slot += $ram_slot_consumed;
    if ($cur_ram_slot > ($numslot + 1)) {
        print "[-] Error! Too many memory space consumed! application can't be mapped in RAM!";
        exit 1;
    }

    $cur_flash_slot += $flash_slot_consumed;
    if ($cur_ram_slot > ($numslot + 1)) {
        print "[-] Error! Too many memory space consumed! application can't be mapped in FLASH!";
        exit 1;
    }

    return %appslotting;
}


1;
