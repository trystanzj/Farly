use strict;
use warnings;

use Test::Simple tests => 16;

use Object::KVC::Integer;

my $i1 = Object::KVC::Integer->new("1");
my $i2 = Object::KVC::Integer->new("1");
my $i3 = Object::KVC::Integer->new("3");
my $i4 = Object::KVC::Integer->new("3");

ok( $i1->equals($i2), "equals" );

ok( !$i1->equals($i3), "!equals" );

ok( $i2->contains($i1), "contains" );

ok ( $i1->as_string() == 1, "as_string");

ok( $i3->gt($i1), "gt" );

ok ( $i1->lt($i4), "lt");

ok ( !$i1->gt($i2), "!gt");

$i1->incr();

ok ( $i1->number() == 2, "incr");

$i1->decr();

ok ( $i1->number() == 1, "decr");

eval { my $i4 = Object::KVC::Integer->new("string"); };

ok ( $@ =~ /not an integer/, "string");

eval { my $i4 = Object::KVC::Integer->new(); };

ok ( $@ =~ /integer required/, "null");

my $i5 = Object::KVC::Integer->new("31");

my $i6 = Object::KVC::Integer->new("11");

ok ( $i1->intersects($i2), "intersects");

ok ( ! $i5->intersects($i6), "!intersects");

ok( $i3->compare( $i4 ) == 0, "compare equal");

ok( $i2->compare( $i3 ) == -1, "compare less than");

ok( $i3->compare( $i2 ) == 1, "compare greater than");
