use strict;
use warnings;

use Test::Simple tests => 9;

use Object::KVC::List;
use Object::KVC::Hash;
use Object::KVC::String;
use Object::KVC::Aggregate qw(NEXTVAL);

my $ce1 = Object::KVC::Hash->new();
my $ce2 = Object::KVC::Hash->new();
my $ce3 = Object::KVC::Hash->new();
my $ce4 = Object::KVC::Hash->new();

$ce1->set( "S1", Object::KVC::String->new("string11") );
$ce1->set( "D1", Object::KVC::String->new("string12") );

$ce2->set( "S1", Object::KVC::String->new("string21") );
$ce2->set( "D1", Object::KVC::String->new("string22") );

$ce3->set( "S1", Object::KVC::String->new("string31") );
$ce3->set( "D1", Object::KVC::String->new("string32") );

$ce4->set( "S1", Object::KVC::String->new("string31") );
$ce4->set( "D1", Object::KVC::String->new("string32") );

my $container = Object::KVC::List->new();

$container->add($ce1);
$container->add($ce3);
$container->add($ce2);
$container->add($ce4);

my $agg = Object::KVC::Aggregate->new( $container );

$agg->groupby('S1', 'D1', 'C');

ok ( scalar( $agg->iter() ) == 0, "_has_defined_keys" );

$agg->groupby('S1', 'D1' );

ok ( scalar( $agg->iter() ) == 3, "two keys" );

$agg->groupby('S1' );

ok ( scalar( $agg->iter() ) == 3, "single key" );

my $it = $agg->iterator();

ok( ref($it) eq 'CODE', "iterator code ref");

my $set_count = 0;
my $object_count = 0;

while ( my $set = NEXTVAL($it) ) {
    $set_count++;
    $object_count += $set->size(); 
}

ok( $set_count == 3, "set iterator" );

ok( $object_count == 4, "set iterator objects" );

my $id = Object::KVC::Hash->new();

$id->set( "S1", Object::KVC::String->new("string31") );

my $result_set = $agg->matches( $id );

ok ($result_set->isa('Object::KVC::Set'), "matches result type" );

ok ( $result_set->size() == 2, "matches" );

my $new_set = Object::KVC::Set->new();
$new_set->add($ce4);

$agg->update( $id, $new_set );

$result_set = $agg->matches( $id );
ok ( $result_set->equals($new_set), "update" );

