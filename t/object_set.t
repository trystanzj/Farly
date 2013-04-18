use strict;
use warnings;

use Test::Simple tests => 13;

use Object::KVC::Set;
use Object::KVC::Hash;
use Object::KVC::String;

my $s1 = Object::KVC::Hash->new();
my $s2 = Object::KVC::Hash->new();
my $s3 = Object::KVC::Hash->new();
my $s4 = Object::KVC::Hash->new();
my $s5 = Object::KVC::Hash->new();

$s1->set( "OBJECT", Object::KVC::String->new("10.1.2.3") );
$s2->set( "OBJECT", Object::KVC::String->new("10.1.2.3") );
$s3->set( "OBJECT", Object::KVC::String->new("10.1.1.3") );
$s4->set( "OBJECT", Object::KVC::String->new("10.1.3.3") );
$s5->set( "OBJECT", Object::KVC::String->new("10.1.3.4") );

ok( $s1->equals($s2), "equals" );

my $set1 = Object::KVC::Set->new();
my $set2 = Object::KVC::Set->new();

$set1->add($s1);
$set2->add($s2);

ok( $set1->equals($set2), "equals" );

$set2->add($s3);

ok( !$set1->equals($set2), "!equals - Set" );

ok( $set2->contains($set1), "contains - Set" );

ok( !$set1->contains($set2), "!contains - Set" );

ok( !$set1->equals($s1), "!equals - object" );

my $union = $set1->union($set2);

ok( $union->equals($set2), "union" );

my $isect = $set1->intersection($set2);

ok( $isect->includes($s1) && $isect->size() == 1, "intersection" );

my $diff = $set2->difference($set1);

ok( $diff->includes($s3) && $diff->size() == 1, "difference" );

my $set3 = Object::KVC::Set->new();

$set3->add($s4);
$set3->add($s5);

ok( $set1->disjoint($set3), "disjoint" );

$set3->add($s2);
$set3->add($s3);

ok( $set3->size() == 4, "size" );

ok( $set3->includes($s2), "includes string" );

ok( $set3->includes($set2), "includes set" );

