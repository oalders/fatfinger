use strict;
use warnings;
use feature qw( say );
package fatfinger;

use File::Spec;
use Path::Iterator::Rule;
use Text::Levenshtein qw(distance);

sub import {
    push @INC, sub {
        shift;
        my $name = shift;

        return if $name eq 'prefork.pm';

        my $module = _maybe_find_module_in_INC($name);

        # Don't recurse through directories if we're called inside an eval or a
        # sub.  Unfortunately, that's the interferes with our tests, so we'll
        # allow it when run under a test harness.
        return if !$module && !$ENV{HARNESS_ACTIVE} && caller;

        $module ||= _maybe_find_module_on_disk($name);
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

sub _maybe_find_module_on_disk {
    my $module = shift;

    my $rule = Path::Iterator::Rule->new;
    $rule->perl_module;

    # iterator interface
    my @dirs = grep { !ref $_ } @INC;

    foreach my $dir (@dirs) {
        my $modules = 0;
        my $next    = $rule->iter($dir);
        while ( defined( my $file = $next->() ) ) {
            my $orig_file = $file;

            # remove top level path
            $file =~ s{^$dir}{}g;
            my @parts = reverse( File::Spec->splitdir($file) );

            # work from the bottom up until we hit illegal chars
            my @name;
            my $count = 0;
            for my $part (@parts) {
                if ( $count > 0 && ( $part !~ m{\w} || $part =~ m{[\.\-]} ) )
                {
                    last;
                }
                push @name, $part;
                ++$count;
            }
            $file = join '::', reverse @name;

            if ( $ENV{FF_DEBUG} ) {
                say "f: $file m: $module " . distance( $file, $module );
            }

            if ( distance( lc($file), lc($module) ) <= 2 ) {
                $file =~ s{\.pm\z}{};
                return $file;
            }
        }
    }
}

1;
