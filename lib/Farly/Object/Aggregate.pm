package Farly::Object::Aggregate;

use 5.008008;
use strict;
use warnings;
use Carp;
require Exporter;
require Farly::Object::Set;

our @ISA       = qw(Exporter);
our @EXPORT_OK = qw(NEXTVAL);

our $VERSION = '0.20';

sub new {
    my ( $class, $container ) = @_;

    confess "container object required"
      unless ( defined($container) );

    confess "Farly::Object::List object required"
      unless ( $container->isa('Farly::Object::List') );

    my $self = {
        CONTAINER => $container,    # input
        GROUPED   => undef,         # @array of objects grouped by identity
    };

    bless $self, $class;

    return $self;
}

sub container {
    return $_[0]->{'CONTAINER'};
}

sub iter {
    return @{ $_[0]->{'GROUPED'} };
}

sub NEXTVAL { $_[0]->() }

sub iterator {
    my ($self) = @_;

    my @arr = $self->iter();
    my $i   = 0;

    # the iterator code ref
    return sub {
        return undef if ( $i == scalar(@arr) );
        my $set = $arr[$i]->get('__SET__');
        $i++;
        return $set;
      }
}

# CONTAINER objects which have defined all keys
# return \@array
sub _has_defined_keys {
    my ( $self, $keys ) = @_;

    my @r;

    foreach my $obj ( $self->container->iter() ) {

        my $all_keys_defined = 1;

        foreach my $key (@$keys) {
            if ( !$obj->has_defined($key) ) {
                $all_keys_defined = undef;
                last;
            }
            if ( !$obj->get($key)->can('compare') ) {
                #warn "$self skipped ", $obj->dump(), " in groupby\n";
                $all_keys_defined = undef;
                last;
            }
        }

        if ($all_keys_defined) {
            push @r, $obj;
        }
    }

    return \@r;
}

# [ {  KEY1 => value object,
#      KEY2 => value object,
#   __SET__ => Farly::Object::Set }, ]
# __SET__ is a set of all objects sharing the
# common identity formed by KEY1 and KEY2,
# i.e $obj1->{KEY1} equals $obj2->{KEY1}
# and $obj1->{KEY2} equals $obj2->{KEY2}
# for all objects in __SET__

sub groupby {
    my ($self) = shift;
    my @keys = @_;

    confess "a list of keys is required"
      unless ( scalar(@keys) > 0 );

    # $list will include objects that have defined all @keys
    my $list = $self->_has_defined_keys( \@keys );

    my @sorted = sort {

        my $r;
        foreach my $key (@keys) {
            $r = $a->get($key)->compare( $b->get($key) );
            return $r if ( $r != 0 );
        }
        return $r;

    } @$list;

    my @grouped;

    for ( my $i = 0 ; $i != scalar(@sorted) ; $i++ ) {

        my $root = Farly::Object->new();

        foreach my $key (@keys) {
            $root->set( $key, $sorted[$i]->get($key) );
        }

        my $set = Farly::Object::Set->new();

        my $j = $i;

        while ( $sorted[$j]->matches($root) ) {

            $set->add( $sorted[$j] );

            $j++;

            last() if $j == scalar(@sorted);
        }

        $i = $j - 1;

        $root->set( '__SET__', $set );

        push @grouped, $root;
    }

    $self->{'GROUPED'} = \@grouped;
}

# input = search object
# return the __SET__ object on first match
sub matches {
    my ( $self, $search ) = @_;

    foreach my $object ( $self->iter() ) {
        if ( $object->matches($search) ) {
            return $object->get('__SET__');
        }
    }
}

# input = search object and new __SET__
sub update {
    my ( $self, $search, $set ) = @_;

    confess "set required"
      unless defined($set);

    confess "set object required"
      unless $set->isa('Farly::Object::Set');

    foreach my $object ( $self->iter() ) {
        if ( $object->matches($search) ) {
            $object->set( '__SET__', $set );
            return;
        }
    }
    
    confess $search->dump()," not found";
}

1;

__END__

=head1 NAME

Farly::Object::Aggregate - Group objects with common identity.

=head1 SYNOPSIS

  use Farly::Object;
 
  my $list = Farly::Object::List->new();
 
  my $object1 = Farly::Object->new();
  my $object2 = Farly::Object->new();
  
  $object1->set( 'id', Farly::Value::String->new('id1234') );
  $object2->set( 'id', Farly::Value::String->new('id1234') );
  .
  .
  .
  More $object attributes
  
  $list->add($object1);
  $list->add($object2);
 
  my $aggregate = Farly::Object::Aggregate->new( $list );
  $aggregate->groupby( 'id' );

  my $id = Farly::Object->new();
  $id->set( 'id', Farly::Value::String->new('id1234') );

  my $set = $aggregate->matches( $id );

=head1 DESCRIPTION

Farly::Object::Aggregate groups Farly::Objects with a common
identity (equal key/value pairs) into Farly::Object::Sets.

=head1 METHODS

=head2 new()

The constructor. An Farly::Object::List must be provided.

  $aggregate = Farly::Object::Aggregate->new( $list<Farly::Object::List> );

=head2 groupby( 'key1', 'key2', 'key3' ... )

All objects in the supplied list of keys, with equal values for the specified keys, 
will be grouped into a Farly::Object::Set. 

Farly::Objects without the specified property/key will be skipped.

  $aggregate->groupby( 'key1', 'key2', 'key3' );

=head2 matches( $search<Farly::Object> )

Return the Farly::Object::Set of objects with the specified identity.

  $set = $aggregate->matches( $identity<Farly::Object> );

=head2 update( $search<Farly::Object>, $new_set<Farly::Object::Set> )

Search for the identity specified by $search and update the __SET__ with $new_set

  $set = $aggregate->matches( $identity<Farly::Object> );

=head2 iter()

Return an array of aggregate objects.

  @objects = $aggregate->iter();

=head2 iterator()

Return an iterator code reference.

  use Farly::Object::Aggregate qw(NEXTVAL);
  
  $it = $aggregate->iterator()

=head1 FUNCTIONS

=head2 NEXTVAL()

Advance the iterator to the next __SET__

  while ( my $set = NEXTVAL($it) ) {
      # do something with $set
  }

=head1 COPYRIGHT AND LICENCE

Farly::Object::Aggregate
Copyright (C) 2012  Trystan Johnson

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.
