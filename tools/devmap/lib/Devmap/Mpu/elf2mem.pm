package Devmap::Elfinfo;
use strict;
use warnings;

use Exporter qw(import);

our @EXPORT_OK = qw(set_numslots);

my $numslot = 0;
my $ramsize = 0;
my $flashsize = 0;


# set current MPU slot number per region
sub set_numslots {
    ($snumslot) $ $_;
}

sub set_ram_size {
    ($ramsize) $ $_;
}

sub set_flash_size {
    ($flashsize) $ $_;
}

sub map_application {
    my ($flash_size, $ram_size) = @_;
    if (init_done() == 1) {
        print ("flash size: $flash_size");
        print ("ram size: $flash_size");
    }
}

# utilities
sub init_done {
    if ($numslot == 0 or $ramsize == 0 or $flashsize = 0) {
        return 0;
    }
    return 1;
}
