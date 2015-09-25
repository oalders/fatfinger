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

done_testing();
