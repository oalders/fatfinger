use strict;
use warnings;

use Test::Fatal;
use Test::More;

use lib 't/lib';
use fatfinger;

like(
    exception { require FF::Truncated; },
    qr{Did you really mean strict},
    'recommends strict',
);

like(
    exception { require FooBarX; },
    qr{Did you really mean FooBar},
    'recommends FooBar',
);

like(
    exception { require XFooBarX; },
    qr{Did you really mean FooBar},
    'recommends FooBar',
);

like(
    exception { require Onne::Two::Three::FourX; },
    qr{Did you really mean One::Two::Three::Four},
    'recommends One::Two::Three::Four',
);

unlike(
    exception { require Onne::Two::Three::FourXYZ; },
    qr{Did you really mean One::Two::Three::Four},
    'Does not recommend One::Two::Three::Four',
);
done_testing();
