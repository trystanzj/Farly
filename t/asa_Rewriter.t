use strict;
use warnings;
use Storable;
use Test::More tests => 1;
#use Data::Dumper;
use Log::Log4perl qw(:easy);
use Farly;
use Farly::ASA::Parser;
use Farly::ASA::Annotator;
use Farly::ASA::Rewriter;
 
Log::Log4perl->easy_init($ERROR);

my $abs_path = File::Spec->rel2abs( __FILE__ );
our ($volume,$dir,$file) = File::Spec->splitpath( $abs_path );
my $path = $volume.$dir;

my $parser = Farly::ASA::Parser->new();
my $annotator = Farly::ASA::Annotator->new();
my $rewriter = Farly::ASA::Rewriter->new();

my $string = q{access-list acl-outside line 1 extended permit tcp any range 1024 65535 OG_NETWORK citrix range 1 1024};

my $parse_tree = $parser->parse($string);

#print Dumper($parse_tree);

$annotator->visit($parse_tree);

#print Dumper($parse_tree);

my $ast = $rewriter->rewrite($parse_tree);

#print Dumper($ast);

#store $ast, 'expected.ast';

my $expected = retrieve("$path/expected.ast");

#print Dumper($expected);

is_deeply($ast, $expected, "abstract syntax tree");

