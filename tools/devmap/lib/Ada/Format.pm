package Ada::Format;

use strict;
# getting back script path
use File::Basename qw(dirname basename);
use Cwd  qw(abs_path);
# and update @INC
use lib dirname(dirname abs_path $0) . '/devmap/lib';


###########################################################
# format hex string (0x[0-9a-f]{8}) into Ada formated hexadecimal
#
sub format_ada_hex {
    my ($val) = @_;
    # iThe output is in Ada, we translate here from the
    # generic 0x08p format into Ada hexadecimal format
    if ($val =~ m/0x([0-9a-f]{1,4})([0-9a-f]{4})/) {
        $val =~ s/0x([0-9a-f]{1,4})([0-9a-f]{4})/16#$1_$2#/;
    } elsif ($val =~ m/0x([0-9a-f]{1,4})/) {
        $val =~ s/0x([0-9a-f]{1,4})/16#$1#/;
    }
    return $val;
}

#
# Formatting:
#
# format application generic info for Ada kernel record type
#
sub format_appinfo_for_kernel {
    my $appinfo = @_[0];

    my $name = uc($appinfo->{'name'});
    my $domain = $appinfo->{'domain'};
    # default domain is 0
    if ($domain eq "") {
        $domain = "0";
    }
    my $prio = $appinfo->{'prio'};
    # default prio is 0
    if ($prio eq "") {
        $prio = "0";
    }

    my $appline = sprintf("
      ID_APP%d => (
         %s_name,   -- application name
         %s,        -- task code offset in flash
         %s,        -- task code (.text) section size
         %s,        -- task RAM offset in memory
         %s,        -- .data section size
         %s,        -- .bss section size
         %s,        -- stack size
         %s,        -- entrypoint offset in .text
         %s,        -- isr entrypoint offset in .text
         %s,        -- task domain
         %s         -- task priority
      ),",
    $appinfo->{'id'}, ${name}, format_ada_hex($appinfo->{'text_off'}),
    format_ada_hex($appinfo->{'text_size'}), format_ada_hex($appinfo->{'data_off'}),
    format_ada_hex($appinfo->{'data_size'}), format_ada_hex($appinfo->{'bss_size'}),
    format_ada_hex($appinfo->{'stack_size'}), format_ada_hex($appinfo->{'entrypoint'}),
    format_ada_hex($appinfo->{'isr_entrypoint'}), $domain, $prio);

    # then we return the line to the caller
    return $appline;
}

sub format_appname_for_kernel {
    my $appinfo = @_[0];
    my $name = uc($appinfo->{'name'});

    my $appname = sprintf("
   ${name}_name : t_task_name :=
      \"${name}\" \& \"" . " " x (10 - length(${name})) . "\";");
    return $appname;
}

sub format_appid_for_kernel {
    my ($appinfo, $id) = @_;
    my $name = uc($appinfo->{'name'});
     

    my $appname = sprintf("   ${name} : constant t_real_task_id := ID_APP${id};");
    return $appname;
}

#
# Formatting:
#
# save generic application information into cfg file $FH
#
sub format_appinfo_for_cfg {
    local *FH = shift;
    my ($appinfo) = @_;
    
    my $id = $appinfo->{'id'};
    print FH "app$id.name=$appinfo->{'name'}";
    print FH "app$id.textoff=$appinfo->{'text_off'}";
    print FH "app$id.textsize=$appinfo->{'text_size'}";
    print FH "app$id.dataoff=$appinfo->{'data_off'}";
    print FH "app$id.datasize=$appinfo->{'data_size'}";
    print FH "app$id.bsssize=$appinfo->{'bss_size'}";
    print FH "app$id.stacksize=$appinfo->{'stack_size'}";
    print FH "app$id.entrypoint=$appinfo->{'entrypoint'}";
    print FH "app$id.isr_entrypoint=$appinfo->{'isr_entrypoint'}";
    print FH "app$id.domain=$appinfo->{'domain'}";
    print FH "app$id.prio=$appinfo->{'prio'}";
}

1;

__END__
