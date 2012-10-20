use strict;
use warnings;

use Test::Simple tests => 8;

use Farly::IPv4::ICMPType;

my $all = Farly::IPv4::ICMPType->new( -1 );
my $t1 = Farly::IPv4::ICMPType->new("0");
my $t2 = Farly::IPv4::ICMPType->new("8");
my $t3 = Farly::IPv4::ICMPType->new("8");

ok( $all->contains($t2), "all contains" );

ok( !$t1->contains($t2), "!contains" );

ok( $t2->contains($t3), "contains" );

ok( !$t1->equals($t2), "!equals" );

ok( $t2->equals($t3), "equals" );

ok( $t2->intersects($all), "intersects" );

ok( $t2->intersects($t3), "intersects" );

ok( ! $t1->intersects($t2), "!intersects" );