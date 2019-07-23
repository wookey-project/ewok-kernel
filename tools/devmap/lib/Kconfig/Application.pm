package Kconfig::Application;
use strict;
use warnings;

sub dump_application_config {
    my ($config, $appname) = @_;

    open(CONFIG, "<", $config) or die "unable to open config file: $!";

    # appname can be passed uppercase or not, the uppercase is
    # done here
    my $upappname = uc($appname);
    my %hash;
    print "handling config for $upappname";
    # let's dump the current application information into a hashtab
    while (<CONFIG>)
    {
        chomp;
        if ($_ =~ m/^CONFIG_APP_${upappname}_.+/) {
            # delete CONFIG_APP_ prefix
            $_ =~ s/CONFIG_APP_${upappname}_//;
            my ($key, $val) = split /=/;
            # downcasing the name
            $key = lc($key); 
            # add the current line to hashtab, handling collisions if
            # needed
            if (not exists $hash{$key}) {
                $hash{$key} = $val;
            }
        }
    }

    close(CONFIG);
    # and return it
    return \%hash;
}

1;

__END__
