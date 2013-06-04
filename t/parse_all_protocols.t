use strict;
use warnings;

use Test::Simple tests => 3;

use File::Spec; 

my $abs_path = File::Spec->rel2abs( __FILE__ );
our ($volume,$dir,$file) = File::Spec->splitpath( $abs_path );
my $path = $volume.$dir;

use Farly;
my $importer = Farly->new();
my $container = $importer->process( "ASA", "$path/test_protocols.cfg" );

ok defined $container;
ok $container->isa("Farly::Object::List");
ok $container->size == 15;
