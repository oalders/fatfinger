use strict;
use warnings;

use Test::Fatal;
use Test::More;

use fatfinger;

use lib 't/lib';

like(
    exception { require FF::Truncated; },
    qr{Did you really mean strict\.pm},
    'recommends strict.pm',
);

#use FF::Truncated;
#require FF::Truncated;

done_testing();
