use strict;
use warnings;

use Test::Simple tests => 16;

use Object::KVC::Hash;
use Object::KVC::String;

my $keys;

# ce = configuration element or container element

my $ce = Object::KVC::Hash->new();
	
$ce->{"S1"} = Object::KVC::String->new("stringA1");
$ce->set( "D1", Object::KVC::String->new("stringB2") );

my $search = Object::KVC::Hash->new();
	
$search->set( "S1", Object::KVC::String->new("stringA1"));
$search->set( "D1", Object::KVC::String->new("stringB2") );

ok( $ce->matches($search), "matches");
ok( $ce->equals($search), "equals");

$keys = join(" ", $ce->get_keys());

ok( $keys =~ /D1/ && $keys =~ /S1/, "get_keys" );

ok ( $ce->get("S1")->as_string() eq "stringA1", "get");

$ce->delete_key("D1");

$keys = join(" ", keys( %$ce ));

ok( $keys eq "S1", "delete_key" );

ok( $search->matches($ce), "matches smaller");

my $clone = $search->clone();

ok ( $clone->equals($search) && ($clone ne $search), "clone");

ok ( $search->contains($ce), "contains");

ok ( $search->contained_by($ce), "contained_by");

ok ( !$ce->contains($search), "!contains");

ok ( !$ce->contains("a string"), "!contains other type");

ok ( $search->intersects($ce), "intersects");


my $ce1 = Object::KVC::Hash->new();
my $ce2 = Object::KVC::Hash->new();
my $ce3 = Object::KVC::Hash->new();
my $ce4 = Object::KVC::Hash->new();

$ce1->set( "S1", Object::KVC::String->new("string11") );
$ce1->set( "D1", Object::KVC::String->new("string12") );

$ce2->set( "D1", Object::KVC::String->new("string32") );

$ce3->set( "S1", Object::KVC::String->new("string31") );
$ce3->set( "D1", Object::KVC::String->new("string32") );

$ce4->set( "S1", Object::KVC::String->new("string31") );
$ce4->set( "D1", Object::KVC::String->new("string32") );

ok ( ! $ce4->intersects($ce1), "!intersects" );

ok ( $ce3->intersects($ce2), "intersects" );

ok ( $ce3->intersects($ce4), "!intersects" );

ok ( $ce3->intersects($ce4), "!intersects" );
