use strict;
use warnings;

use Test::Simple tests => 1;

use Log::Log4perl qw(:easy);
Log::Log4perl->easy_init($ERROR);

use Farly::Builder;

my $builder = Farly::Builder->new();
ok( $builder->isa('Farly::Builder'), "new" );
