use strict;
use warnings;

use Test::Fatal;
use Test::More;

use lib 't/lib';
use fatfinger;

$ENV{FF_HARNESS_ACTIVE} = 1;

my $prefix = 'Perhaps you meant to "use';
like(
    exception { require FF::Truncated; },
    qr{$prefix strict},
    'recommends strict',
);

like(
    exception { require FooBarX; },
    qr{$prefix FooBar},
    'recommends FooBar',
);

like(
    exception { require XFooBarX; },
    qr{$prefix FooBar},
    'recommends FooBar',
);

like(
    exception { require Onne::Two::Three::FourX; },
    qr{$prefix One::Two::Three::Four},
    'recommends One::Two::Three::Four',
);

unlike(
    exception { require Onne::Two::Three::FourXYZ; },
    qr{$prefix One::Two::Three::Four},
    'Does not recommend One::Two::Three::Four',
);
done_testing();
