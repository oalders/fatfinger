use strict;
use warnings;
use feature qw( say );
package fatfinger;

use File::Spec;
use Path::Iterator::Rule;
use Text::Levenshtein::Damerau qw( edistance );

sub import {
    push @INC, sub {
        shift;
        my $name = shift;

        return if $name eq 'prefork.pm';

        my $module = _maybe_find_module_in_INC($name);

        my @caller = caller(1);

        # Don't recurse through directories if we're called inside an eval
        # Unfortunately, that's the interferes with our tests, so we'll
        # allow it when run under a test harness.

        return if !$module && !$ENV{HARNESS_ACTIVE} && $caller[3];

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
    for my $file ( keys %INC ) {
        if ( edistance( lc($file), lc($module) ) <= 2 ) {
            $file =~ s{/}{::}g;
            return $file if $file;
        }
    }
}

sub _maybe_find_module_on_disk {
    my $module = shift;

    my $rule = Path::Iterator::Rule->new( depth_first => 1 );
    $rule->perl_module;

    my @module_parts = File::Spec->splitdir($module);
    my $module_depth = @module_parts;

    # don't iterate over any @INC hooks
    my @dirs = grep { !ref $_ } @INC;

    foreach my $inc_dir (@dirs) {
        _debug($inc_dir);
        my $this_rule = $rule->clone;

        $this_rule->and(
            sub {
                my $path          = shift;
                my $file          = shift;
                my $original_path = $path;

                _debug($path);

                return \0 if $file =~ m{\A\.};

                $path =~ s{^$inc_dir/}{};

                # top level directory?
                return 0 if $path eq q{};

                my @path_parts = grep { m{\w} } File::Spec->splitdir($path);
                shift @path_parts if @path_parts && $path_parts[0] eq 'auto';

                my $path_depth = @path_parts;
                return \0 if $path_depth > $module_depth;
                return 0  if $path_depth < $module_depth;

                my $joined_path = join( '/', @path_parts );
                my $distance = edistance( lc($joined_path), lc($module) );

                return $distance <= 2 ? \1 : 0;
            }
        );

        my $next = $this_rule->iter($inc_dir);
        while ( defined( my $file = $next->() ) ) {
            $file =~ s{^$inc_dir/}{}g;

            my @parts = grep { m{\w} } File::Spec->splitdir($file);
            $file = join '::', @parts;
            $file =~ s{\.pm\z}{};
            return $file;
        }
    }
}

sub _debug {
    my $msg = shift;
    say $msg if $ENV{FF_DEBUG};
}

1;
