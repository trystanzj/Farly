use strict;
use warnings;

use Test::Simple tests => 7;

use File::Spec;

my $abs_path = File::Spec->rel2abs(__FILE__);
our ( $volume, $dir, $file ) = File::Spec->splitpath($abs_path);
my $path = $volume . $dir;

use Farly;
my $importer  = Farly->new();
my $container = $importer->process( "ASA", "$path/test.cfg" );

eval { my $optimizer1 = Farly::Rule::Optimizer->new($container); };

ok( $@ =~ /found invalid object/, "not expanded" );

ok( $container->size() == 45, "import" );

use Farly::Rule::Expander;

my $rule_expander = Farly::Rule::Expander->new($container);

ok( defined($rule_expander), "constructor" );

# get the raw rule entries

my $expanded_rules = $rule_expander->expand_all();

ok( $expanded_rules->size == 17, "expand_all" );

use Farly::Rule::Optimizer;

my $optimizer;

eval { $optimizer = Farly::Rule::Optimizer->new($expanded_rules); };

ok( $@ =~ /found invalid object/, "not single rule set" );

my $search = Object::KVC::Hash->new();
$search->set( "ID" => Object::KVC::String->new("outside-in") );

my $search_result = Object::KVC::List->new();

$expanded_rules->matches( $search, $search_result );

$optimizer = Farly::Rule::Optimizer->new($search_result);

$optimizer->run();

ok( $optimizer->optimized->size() == 15, "optimized" );

ok( $optimizer->removed->size() == 1, "removed" );

my $template = Farly::Template::Cisco->new('ASA');
