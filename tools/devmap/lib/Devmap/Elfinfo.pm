package Devmap::Elfinfo;
use strict;
use warnings;
use Env qw(CROSS_COMPILE);

use Exporter qw(import);

our @EXPORT_OK = qw(openelf elf_get_section elf_section_exists);

my @objdump_raw;

my @objdump_syms;

sub openelf {
    my ($binary) = @_;
    @objdump_raw=`${CROSS_COMPILE}objdump -h $binary`;
    @objdump_syms=`${CROSS_COMPILE}objdump -j .text -j .init -j fini --syms $binary`
}

sub elf_section_exists {
    my ($section_name) = @_;
    foreach my $line (@objdump_raw) {
        if ($line =~ m/^\s+\d+\s+$section_name/) {
            return 1;
        }
    }
    return 0;
}


sub elf_get_symbol_address {
    my ($sym) = @_;
    foreach my $line (@objdump_syms) {
        if ($line =~ m/([0-9a-f]{8}).*$sym/) {
            return "0x$1";
        }
    }
    return "0";
}

sub elf_get_section {
    my ($section_name) = @_;
    my %sectioninfo;
    # does the section exists ?
    foreach my $line (@objdump_raw) {
        if ($line =~ m/^\s+\d+\s+$section_name/) {
            chomp($line);
            # forge section hashtable
            my $size = $line;
            $size =~ s/^\s+\d+\s+[\.0-9a-zA-Z_]+\s+([0-9a-f]+)\s+.*/0x$1/;
            my $vma = $line;
            $vma =~ s/^\s+\d+\s+[\.0-9a-zA-Z_]+\s+[0-9a-f]+\s+([0-9a-f]+)\s+.*/0x$1/;
            my $lma = $line;
            $lma =~ s/^\s+\d{1,}\s[\.0-9a-zA-Z_]+\s+[0-9a-f]+\s+[0-9a-f]+\s+([0-9a-f]+)\s+.*/0x$1/;
            my $offset = $line;
            $offset =~ s/^\s+\d{1,}\s[\.0-9a-zA-Z_]+\s+[0-9a-f]+\s+[0-9a-f]+\s+[0-9a-f]+\s+([0-9a-f]+)\s+.*/0x$1/;
            my $align = $line;
            $align =~ s/^\s+\d{1,}\s[\.0-9a-zA-Z_]+\s+[0-9a-f]+\s+[0-9a-f]+\s+[0-9a-f]+\s+[0-9a-f]+\s+2\*\*(.*)/$1/;
            $align = 2 ** $align;
            %sectioninfo = (
                name => "$section_name",
                size => $size,
                vma => $vma,
                lma => $lma,
                offset => $offset,
                align => $align
            );
        }
    }
    return %sectioninfo;
}

1;

__END__

=pod

=head1 NAME

Devmap::Elfinfo - A module to dump various ELF object section informations

=head1 SYNOPSYS

   use Devmap::Elfinfo

   Devmap::Elfinfo::openelf("my_binary.elf");

   foreach (('.text', '.data', '.stack')) {
        my %hash = Devmap::Elfinfo::elf_get_section($_i);
        print("$_ section has the following properties:");
        foreach (('name', 'size', 'vma', 'lma', 'offset', 'align')) {
            print("$_ : $hash{$_}");
        }
    }

=head1 DESCRIPTION

This module implement a basic ELF parser based on objdump binutils tool.
The goal is to extract various informations about the ELF or object sections,
including size, logical memory address, virtual memory address, offset in file and byte alignment constraint.

This module support the CROSS_COMPILE environment variable to allow cross-architecture dump using the cross-toolchain objdump tool instead of the native one.

=head1 FUNCTION

=over 1

=item B<openelf ($binary)>

This takes the binary file relative or absolute path name in order to prepare the objdump content into a module-local variable.

=item B<elf_section_exists ($section_name)>

Return false if the section doesn't exists, or true otherwhise.

=item B<elf_get_content ($section_name)>

Get back the given section name (don't forget the starting dot) metainformation into a hash table.

=back

The hash table returned by C<elf_get_content> contains the following keys:

=over 2

=item * C<name>: the section name

=item * C<size>: the section size in bytes (in hexadecimal value)

=item * C<vma>: the virtual memory address of the starting byte of the section

=item * C<lma>: the logical memory address of the starting byte of the sextion

=item * C<offset>: the section starting byte offset in the binary file

=item * C<align>: the requested bytes alignment of the section in memory

=back

=head1 AUTHORS

The wookey project team <wookey@ssi.gouv.fr>

Ryad     Benadjila
Arnauld  Michelizza
Mathieu  Renard
Philippe Thierry
Philippe Trebuchet

=head1 COPYRIGHT AND LICENSE

Copyright 2019 by the Wookey project Team

L<https://wookey-project.github.io>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

