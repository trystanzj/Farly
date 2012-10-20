use strict;
use warnings;

use Test::Simple tests => 1;

use Log::Log4perl qw(:easy);
Log::Log4perl->easy_init($ERROR);

use Farly::ASA::Builder;

my $builder = Farly::ASA::Builder->new();
ok( $builder->isa('Farly::ASA::Builder'), "new" );
