use strict;
use warnings;
package fatfinger;

# XXX remove before release
use feature qw( say state );

use Text::Levenshtein qw(distance);

$SIG{__DIE__} = sub {
    my $error = shift;
    state $counter = 0;
    ++$counter;

    say $counter;

    #    return if $counter > 1;

    my $name = _maybe_extract_module_name($error);
    return unless $name;

    my $module = _maybe_find_module_in_INC($name);
    return unless $module;

    my $msg = <<"EOF";


----------
$name could not be found. Did you really mean $module?
----------

EOF
    die $msg;
};

sub _maybe_extract_module_name {
    my $error = shift;
    if ( $error =~ m{locate (.*) in } ) {
        return $1;
    }
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
