use strict;
use warnings;
package fatfinger;

use Text::Levenshtein qw(distance);

sub import {
    push @INC, sub {
        shift;
        my $name = shift;

        my $module = _maybe_find_module_in_INC($name);
        return unless $module;

        my $msg = <<"EOF";

----------
$name could not be found. Did you really mean $module?
----------

EOF
        die $msg;
    };
}

sub _maybe_find_module_in_INC {
    my $module = shift;
    $module =~ s{::}{/}g;
    my $file;
    for $file ( keys %INC ) {
        if ( distance( $file, $module ) <= 2 ) {
            $file =~ s{/}{::}g;
            return $file if $file;
        }
    }
}

1;
