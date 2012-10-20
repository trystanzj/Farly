package Farly::ASA::TokenPicker;

use 5.008008;
use strict;
use warnings;
use Carp;
use Scalar::Util qw(blessed);
use Log::Log4perl qw(get_logger);

our $VERSION = '0.09';
our $AUTOLOAD;

# when this method is called, create a new object
# with "ENTRY"  model meta data set to this
# "ENTRY" is roughly equivalent to a namespace
our $Create_Object_Methods = {
	'hostname'     => 'HOSTNAME',
	'names'        => 'NAME',
	'interface'    => 'INTERFACE',
	'object'       => 'OBJECT',
	'object_group' => 'GROUP',
	'access_list'  => 'RULE',
	'access_group' => 'ACCESS_GROUP',
	'route'        => 'ROUTE',
};

# when one of these methods are called set the
# OBJECT_TYPE meta data value to this
our $Object_Type_Map = {
	'object_service'     => 'SERVICE',
	'object_host'        => 'HOST',
	'object_range'       => 'RANGE',
	'object_network'     => 'NETWORK',
	'og_network_object'  => 'NETWORK',
	'og_port_object'     => 'PORT',
	'og_group_object'    => 'GROUP',
	'og_protocol_object' => 'PROTOCOL',
	'og_description'     => 'COMMENT',
	'og_icmp_object'     => 'ICMP_TYPE',
	'og_service_object'  => 'SERVICE',
};

# The $Rule_To_Key_Map hash key is the type of the parse tree node. 
# Any token / '__VALUE__' found in the parse tree beneath a node
# of this type becomes the value in an Object::KVC::Hash.
# The key for the Object::KVC::Hash which references the '__VALUE__' 
# defines the vendor to Farly model mapping.
our $Rule_To_Key_Map = {
	'hostname'                => 'ID',
	'interface'               => 'NAME',
	'if_name'                 => 'ID',
	'sec_level'               => 'SECURITY_LEVEL',
	'if_ip'                   => 'OBJECT',
	'if_mask'                 => 'MASK',
	'if_standby'              => 'STANDBY_IP',
	'object'                  => 'OBJECT_TYPE',      #this will be over written
	'object_id'               => 'ID',
	'object_address'          => 'OBJECT',
	'object_service_protocol' => 'PROTOCOL',
	'object_service_src'      => 'SRC_PORT',
	'object_service_dst'      => 'DST_PORT',
	'object_icmp'             => 'ICMP_TYPE',
	'object_group'            => 'GROUP_TYPE',
	'og_id'                   => 'ID',
	'og_protocol'             => 'GROUP_PROTOCOL',
	'og_object'               => 'OBJECT',
	'og_so_protocol'          => 'PROTOCOL',
	'og_so_src_port'          => 'SRC_PORT',
	'og_so_dst_port'          => 'DST_PORT',
	'acl_action'              => 'ACTION',
	'acl_id'                  => 'ID',
	'acl_line'                => 'LINE',
	'acl_type'                => 'TYPE',
	'acl_protocol'            => 'PROTOCOL',
	'acl_src_ip'              => 'SRC_IP',
	'acl_src_port'            => 'SRC_PORT',
	'acl_dst_ip'              => 'DST_IP',
	'acl_dst_port'            => 'DST_PORT',
	'acl_icmp_type'           => 'ICMP_TYPE',
	'acl_remark'              => 'COMMENT',
	'acl_logging'		      => 'LOG_LEVEL', #when its the default
	'acl_log_level'           => 'LOG_LEVEL',
	'acl_log_interval'	      => 'LOG_INTERVAL',
	'acl_time_range'          => 'TIME_RANGE',
	'acl_inactive'            => 'STATUS',
	'ag_id'                   => 'ID',
	'ag_direction'            => 'DIRECTION',
	'ag_interface'            => 'INTERFACE',
	'route_interface'         => 'INTERFACE',
	'route_dst'               => 'DESTINATION',
	'route_nexthop'           => 'NEXTHOP',
	'route_cost'              => 'COST',
	'route_track'             => 'TRACK',
	'route_tunneled'          => 'TUNNELED'
};

sub new {
	my ( $class ) = @_;

	my $self = {
		CONTAINER => Object::KVC::List->new(),    #store data here
	};
	bless $self, $class;

	my $logger = get_logger(__PACKAGE__);
	$logger->info("$self NEW");
	$logger->info( "$self CONTAINER is ", $self->container() );

	return $self;
}

sub container {
	return $_[0]->{CONTAINER};
}

sub visit {
	my ( $self, $node, $parent_key, $bucket ) = @_;

	my $logger = get_logger(__PACKAGE__);

	# set s of explored vertices
	my %seen;

	#stack is all neighbors of s
	my @stack;
	push @stack, [ $node, $parent_key, $bucket ];

	while (@stack) {

		my $rec = pop @stack;

		$node       = $rec->[0];
		$parent_key = $rec->[1];    #undef for root
		$bucket     = $rec->[2];	#Object::KVC::Hash

		next if ( $seen{$node}++ );

		my $rule_id = ref($node);

		next if ( $rule_id eq "names" );    #skip

		if ( exists( $Rule_To_Key_Map->{$rule_id} ) ) {
			$parent_key = $Rule_To_Key_Map->{$rule_id};
		}

		$logger->debug("parent key: $parent_key") if defined($parent_key);
		$logger->debug("bucket: $bucket")         if defined($bucket);
		$logger->debug("visiting node: $rule_id $node\n");

		$bucket = $self->$rule_id( $node, $parent_key, $bucket );

		foreach my $key ( keys %$node ) {

			# don't explore an EOL or token node
			next if ( $key eq "EOL" or $key eq "__VALUE__" );

			my $next = $node->{$key};

			#this is a branch
			if ( blessed($next) ) {
				
				$logger->debug("push stack next $next");
				$logger->debug("push stack parent key $parent_key") if defined($parent_key);
				
				push @stack, [ $next, $parent_key, $bucket ];
			}
		}
	}

	return 1;
}

sub AUTOLOAD {
	my ( $self, $node, $key, $bucket ) = @_;
	# $key = scalar string, $bucket = Object::KVC::Hash

	my $type = ref($self)
	  or confess "$self is not an object";

	defined($node)
	  or confess "tree node for $type required";

	my $logger = get_logger(__PACKAGE__);

	my $rule_id = ref($node);

	$logger->debug("called $rule_id");

	if ( exists( $Create_Object_Methods->{$rule_id} ) ) {

		# encounted a new object

		my $entry = $Create_Object_Methods->{$rule_id};

		$bucket = Object::KVC::Hash->new();
		$bucket->set( "ENTRY", Object::KVC::String->new($entry) );

		$logger->debug("$self - new object $rule_id, ENTRY => $entry");
		$logger->debug("$self - storing $bucket");

		$self->container()->add($bucket);
	}
	
	if ( exists( $Object_Type_Map->{$rule_id} ) ) {

		my $type = $Object_Type_Map->{$rule_id};

		$bucket->set( "OBJECT_TYPE", Object::KVC::String->new($type) );

		$logger->debug("$self - section OBJECT_TYPE => $type");
	}
	
	if ( exists( $node->{"__VALUE__"} ) ) {

		# found a token, check that a key exists for
		# the token and put the token in the bucket

		defined($key)
		  or confess "$self error: key not given for $rule_id\n";

		my $value = $node->{"__VALUE__"}
		  or confess "$self error: value not found for $rule_id, branch $key\n";

		$logger->debug("$self - $bucket setProperty $key => $value");

		$bucket->set( $key, $value );
	}

	return $bucket;
}

sub DESTROY { }

1;
__END__

=head1 NAME

Farly::ASA::TokenPicker - Collects value objects from the parse tree

=head1 DESCRIPTION

Farly::ASA::TokenPicker walks a Parse::RecDescent <autotree> parse tree
searching for Token value objects. Token objects are recognized by the presence
of the '__VALUE__' key (see <autotree>).

When a Token value object is found the parser rule name associated with that
token is used to look up a key. The returned key and token value are then
stored in an Object::KVC::Hash object.

A new Object::KVC::Hash object is created and added to an
Object::KVC::List every time the TokenPicker visit method
is called (i.e. for every line of configuration).

Farly::ASA::TokenPicker dies on error.

Farly::ASA::TokenPicker is used by the Farly::ASA::Builder only.

=head1 COPYRIGHT AND LICENCE

Farly::ASA::TokenPicker
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
