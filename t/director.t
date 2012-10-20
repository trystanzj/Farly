use strict;
use warnings;

use Test::Simple tests => 1;

use Log::Log4perl qw(:easy);
Log::Log4perl->easy_init($ERROR);

use Farly::Director;

my $director = Farly::Director->new();
ok( $director->isa('Farly::Director'), "new" );
