use strict;
use warnings;

package fatfinger;

use File::Spec;
use Path::Iterator::Rule;
use Text::Levenshtein::Damerau qw( edistance );

sub import {
    push @INC, sub {
        shift;
        my $name = shift;

        return if $name eq 'prefork.pm';

        # Don't recurse through directories if we're called inside an eval
        # Unfortunately, that's the interferes with our tests, so we'll
        # allow it when run under a test harness.

        return if !$ENV{FF_HARNESS_ACTIVE} && $^S;

        my @caller = caller(1);
        return
            if !$ENV{FF_HARNESS_ACTIVE}
            && ( ( $caller[3] && $caller[3] =~ m{eval} )
            || ( $caller[1] && $caller[1] =~ m{eval} ) );

        my $module = _maybe_find_module_in_INC($name);
        $module ||= _maybe_find_module_on_disk($name);
        return unless $module;

        $name =~ s{\.pm\z}{};
        $module =~ s{\.pm\z}{};

        my $msg = <<"EOF";

----------
The module "$name" could not be found. Perhaps you meant to "use $module"?
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
                my $path = shift;
                my $file = shift;

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
    print "$msg\n" if $ENV{FF_DEBUG};
}

1;

# ABSTRACT: Catch typos in module names

=head1 SYNOPSIS

    use strict;
    use warnings;
    use fatfinger;

=head1 DESCRIPTION

C<fatfinger> is a development tool which helps you spot typos in C<use>
statements.  It does this by adding an C<@INC> hook.  If a module which you
tried to C<use> cannot it be found, C<fatfinger> checks C<%INC> for similarly
named modules.  If this comes up empty C<fatfinger> will do some fuzzy matching
on the files in your C<@INC> directories.

In order for C<fatfinger> to be effective, C<use> it as early as possible in
your modules.

For example:

    use strict;
    use fatfinger;
    use warningz;

When running this code, you should get the following error message:

    ----------
    The module "warningz" could not be found. Perhaps you meant to "use warnings"?
    ----------

=head1 CAVEATS

This will add a (hopefully) small penalty to the run time of your code if a
module cannot be found.  Presently it seems to be fast enough for me, but it
may not be fast enough for you.

=head1 ACKNOWLEDGEMENTS

Thanks to Dave Rolsky, Greg Oschwald and Florian Ragwitz for helping me with
the logic behind this module.
