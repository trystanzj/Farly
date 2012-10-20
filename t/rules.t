use strict;
use warnings;

use Test::Simple tests => 3;

use File::Spec; 

my $abs_path = File::Spec->rel2abs( __FILE__ );
our ($volume,$dir,$file) = File::Spec->splitpath( $abs_path );
my $path = $volume.$dir;

use Farly;
my $importer = Farly->new();


my $container = $importer->process( "ASA", "$path/test.cfg" );

ok( $container->size() == 43, "import");

use Farly::Rules;

my $rule_expander = Farly::Rules->new( $container );

ok( defined($rule_expander), "constructor" );

# get the raw rule entries

my $expanded_rules = $rule_expander->expand_all();

ok( $expanded_rules->size == 17, "expand_all" );
