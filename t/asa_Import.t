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

ok( defined $container, "container defined");
ok( $container->isa("Farly::Object::List"), "container type");
ok( $container->size() == 65, "import ok");


foreach my $obj ( $container->iter() ) {
    print $obj->dump(),"\n";
}