#!/usr/bin/perl -w

# f_rewrite.pl - Farly Script Tools - Interactive firewall rule rewrite
# Copyright (C) 2012  Trystan Johnson
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

use strict;
use warnings;
use Getopt::Long;
use Farly;
use Farly::ASA::ProtocolFormatter;
use Farly::Rules;
use Farly::Template::Cisco;
use Farly::ASA::PortFormatter;
use Farly::ASA::ProtocolFormatter;
use Farly::ASA::ICMPFormatter;

my %opts;

if ( GetOptions( \%opts, 'file=s', 'id=s', 'groupby=s', 'output=s', 'help|?' ) )
{
	if ( defined $opts{'help'} || defined $opts{'?'} ) {
		usage();
	}

	if ( !defined $opts{'file'} ) {
		usage("Please specify a configuration file");
	}

	if ( !-f $opts{'file'} ) {
		usage("Please specify a valid configuration file");
	}

	if ( !defined $opts{'id'} ) {
		usage("Please specify an access-list ID");
	}

	if ( !defined $opts{'groupby'} ) {
		usage("Please specify a 'group by' property");
	}

	if ( $opts{'groupby'} !~ /DST_PORT|SRC_IP|DST_IP|SRC_PORT/ ) {
		usage("Please check the 'group by' property");
	}

	if ( !defined $opts{'output'} ) {
		usage("Please specify an output file name");
	}
}
else {
	usage();
}

my $property = $opts{'groupby'};
my $output   = $opts{'output'};

print "\nimporting ", $opts{'file'}, "\n";

my $importer = Farly->new();

my $container = $importer->process( "ASA", $opts{'file'} );

my $search = Object::KVC::Hash->new();
$search->set( "ID", Object::KVC::String->new( $opts{'id'} ) );

my $search_result = Object::KVC::List->new();

$container->matches(  $search, $search_result );

my $acl = filter_comments($search_result);

if ( $property eq 'SRC_PORT' || $property eq 'DST_PORT' ) {
	$acl = filter_layer4( $search_result );
}

if ( $acl->size == 0 ) {
	die "\n",$opts{'id'}, " is not a valid access-list id\n";
}

# group the rules into an @ of ::Sets using the "group by property"
my @grouped_rules;
group_by_property( $acl, $property, \@grouped_rules );

# track pre-existing and new groups
# <string> => { Object::KVC::Set }
my %groups;
existings_groups($container, \%groups);

#new rules to add
my @keep;             # [ $object<Object::KVC::Hash> ]

#old rules to remove
my @remove;           # [ $set<Object::KVC::Set> ] (the grouped rules)

my $ANY = Farly::IPv4::Network->new('0.0.0.0 0.0.0.0');

# used the list of rule sets to create and name new groups
foreach my $set (@grouped_rules) {

	next if ( $set->size == 1 );

	next if ( $set->[0]->get( $property )->equals($ANY) );

	print "\n";

	# create and object group for the specified property
	# from the set of rules
	my $group = create_group( $set, $property );

	my $id;

	# see if this group already has an ID
	$id = current_group_id( $group, \%groups );

	if ( ! defined $id ) {

		# the group doesn't have an ID display the first rule
		print "hint :   ";
		display_object( $set->[0] );

		# get a new group ID from the user
		$id = name_new_group( $group, \%groups );
	}

	die "ERROR : id not defined" unless defined($id);

	# have the new rule use the new group
	# create a group reference
	my $group_ref = group_ref($id);

	# create a new rule which uses the group reference
	my $cloned_rule = $set->[0]->clone();
	$cloned_rule->set( $property, $group_ref );
	$cloned_rule->delete_key('LINE');

	# keep the new rule
	push @keep, $cloned_rule;

	# remove the rest of the old none grouped rules
	push @remove, $set;
}

print "\nprinting configuration to $output...\n";

open STDOUT, ">$output" or die "failed to open $output file";

#print the new groups
foreach my $id ( keys %groups ) {
	my $group = $groups{$id};
	foreach my $object ( $group->iter ) {
		next if ( $object->has_defined('EXISTS') );
		$object->set( 'ID', Object::KVC::String->new($id) );
		display_object($object);
	}
}

#print the new rules
foreach my $rule (@keep) {
	display_object($rule);
}

#remove the rules which are now grouped
foreach my $set (@remove) {
	remove($set);
}

close STDOUT;

sub filter_layer4 {
	my ($list) = @_;

	my $TCP = Farly::Transport::Protocol->new("6");
	my $UDP = Farly::Transport::Protocol->new("17");

	my $acl = Object::KVC::List->new();

	foreach my $rule ( $list->iter ) {

		next if ( $rule->has_defined('COMMENT') );

		if (   $rule->get('PROTOCOL')->equals($TCP)
			|| $rule->get('PROTOCOL')->equals($UDP) )
		{
			$acl->add($rule);
		}
	}

	return $acl;
}

sub filter_comments {
	my ($list) = @_;

	my $acl = Object::KVC::List->new();

	foreach my $rule ( $list->iter ) {

		if ( $rule->has_defined('COMMENT') ) {
			next;
		}
		else {
			$acl->add($rule);
		}
	}

	return $acl;
}

sub existings_groups {
	my ($container, $groups ) = @_;

	my $GROUP  = Object::KVC::String->new('GROUP');
	my $OBJECT = Object::KVC::String->new('OBJECT');

	foreach my $obj ( $container->iter() ) {
		if (   $obj->get('ENTRY')->equals($GROUP)
			|| $obj->get('ENTRY')->equals($OBJECT) )
		{
			
			$obj->set( 'EXISTS', Object::KVC::String->new('TRUE') );

			my $id = $obj->get('ID')->as_string();

			#print "id: $id\n";
			# if this ID has not been seen create a new ::Set for this group
			if ( ! defined $groups->{ $id } ) {
				$groups->{ $id } = Object::KVC::Set->new();
				#print "new set";
			}				
			
			$groups->{ $id }->add( $obj );
		}
	}
}

# create a new rule object, excluding the "group by" property
sub format_rule {
	my ( $rule, $p_list ) = @_;

	my $r = Object::KVC::Hash->new();

	foreach my $property (@$p_list) {
		if ( $rule->has_defined($property) ) {
			$r->set( $property, $rule->get($property) );
		}
	}

	return $r;
}

# create ::Set's of rules in @$grouped_rules where all properties
# are equal except the specified "group by property" which varies
# push the new ::Set's onto ARRAYREF $grouped_rules

sub group_by_property {
	my ( $acl, $property, $grouped_rules ) = @_;

	my $keep;

	my $acl_size = $acl->size;

	print "grouping rules\n";

	my %properties = (
		'ID'       => 1,
		'ACTION'   => 1,
		'PROTOCOL' => 1,
		'SRC_IP'   => 1,
		'SRC_PORT' => 1,
		'DST_IP'   => 1,
		'DST_PORT' => 1,
	);

	delete $properties{$property};

	my @p_list = keys %properties;

	while ( $acl->size != 0 ) {

		# keep the rule properties specified in %properties
		# except for the "group by property"
		my $rule_1 = format_rule( $acl->[0], \@p_list );

		undef $keep;

		$keep = Object::KVC::List->new();

		my $rule_group = Object::KVC::Set->new();

		# iterate over the rest of the rule ::Set
		for ( my $j = 0 ; $j != $acl->size ; $j++ ) {

			if ( $acl->[$j]->matches($rule_1) ) {

				# matches, therefore add it to the new group
				$rule_group->add( $acl->[$j] );
			}
			else {

				# doesn't match, keep this rule
				$keep->add( $acl->[$j] );
			}
		}

		undef $acl;

		# continue grouping the rest of the rules
		$acl = $keep;

		#print $acl_size - $acl->size, " rules processed\n";

		# save the new rule group
		push @$grouped_rules, $rule_group;
	}
}

# create a service group
sub service_group {
	my ( $object, $protocol ) = @_;

	my $group_protocol = Farly::ASA::ProtocolFormatter->new()->as_string($protocol);

	$object->set( "ENTRY",          Object::KVC::String->new("GROUP") );
	$object->set( "GROUP_TYPE",     Object::KVC::String->new("service") );
	$object->set( "OBJECT_TYPE",    Object::KVC::String->new("PORT") );
	$object->set( "GROUP_PROTOCOL", Object::KVC::String->new($group_protocol) );
}

# create a network group
sub network_group {
	my ($object) = @_;

	$object->set( "ENTRY",       Object::KVC::String->new("GROUP") );
	$object->set( "GROUP_TYPE",  Object::KVC::String->new("network") );
	$object->set( "OBJECT_TYPE", Object::KVC::String->new("NETWORK") );

}

# create a group reference
sub group_ref {
	my ($id) = @_;
	my $group_ref = Object::KVC::HashRef->new();
	$group_ref->set( 'ENTRY', Object::KVC::String->new('GROUP') );
	$group_ref->set( 'ID',    Object::KVC::String->new($id) );
	return $group_ref;
}

# given a set of rules, return a group for the given property
sub create_group {
	my ( $set, $property ) = @_;

	#the new group
	my $group = Object::KVC::Set->new();

	foreach my $rule ( $set->iter() ) {

		# skip COMMENTS
		next if $rule->has_defined('COMMENT');

		# the new group member
		my $object = Object::KVC::Hash->new();

		# set the new group member to the specified "group by property"
		$object->set( "OBJECT", $rule->get($property) );

		# populate the rest of the properties for the group members
		if ( $property eq 'SRC_PORT' || $property eq 'DST_PORT' ) {
			service_group( $object, $rule->get('PROTOCOL')->as_string() );
		}
		elsif ( $property eq 'SRC_IP' || $property eq 'DST_IP' ) {
			network_group($object);
		}

		# add this group member to the group if its not already there
		if ( !$group->includes($object) ) {
			$group->add($object);
		}

	}

	return $group;
}

sub get_group_id {
	my $input = '';

	while ( $input !~ /\S+/ ) {
		print "Enter new group ID : ";
		$input = <STDIN>;
	}
	
	return $input;
}

# print the new group and prompt the user for a group name
# make sure the new group name is not already used
sub name_new_group {
	my ( $group, $group_ids ) = @_;

	print "group members :\n";

	foreach my $object ( $group->iter() ) {
		if ( $object->has_defined('GROUP_PROTOCOL') ) {
			print " ", $object->get('GROUP_PROTOCOL')->as_string(), " ";
		}
		print " ",$object->get('OBJECT')->as_string() . "\n";
	}

	my $input = get_group_id();

	while ( defined $group_ids->{$input} ) {
		print "\n  that group ID is already used\n\n";
		$input = get_group_id();
	}

	$group_ids->{$input} = $group;

	print "OK\n";

	return $input;
}

# check if the given group already has a group ID
sub current_group_id {
	my ( $group, $existing_groups ) = @_;

	foreach my $group_id ( keys %$existing_groups ) {
		if ( $existing_groups->{$group_id}->includes($group) ) {
			return $group_id;
		}
	}
	
	return undef;
}

# process rules to remove
sub remove {
	my ($set) = @_;
	foreach my $rule ( $set->iter ) {
		my $clone = $rule->clone;
		$clone->set( 'REMOVE', Object::KVC::String->new('RULE') );
		$clone->delete_key('LINE');
		display_object($clone);
	}
}

sub display_object {
	my ($object) = @_;

	my $template = Farly::Template::Cisco->new('ASA');

	my $f = {
		'port_formatter'     => Farly::ASA::PortFormatter->new(),
		'protocol_formatter' => Farly::ASA::ProtocolFormatter->new(),
		'icmp_formatter'     => Farly::ASA::ICMPFormatter->new(),
	};

	$template->use_text(1);
	$template->set_formatters($f);

	my $line = $template->as_string($object);
	print "\n";
}

sub usage {
	my ($err) = @_;
	
	print qq{

  f_rewrite.pl  -  Interactively re-write an access-list using user specified
                   group ID's.

Usage:

  f_rewrite.pl --file <file> --id <access-list id> --groupby <DST_PORT|SRC_IP|DST_IP|SRC_PORT> --output <file>

Options:

  --help|?      This info

  --file        The firewall configuration file

  --id          The access-list id to rewrite

  --groupby     Must be one of DST_PORT, SRC_IP, DST_IP or SRC_PORT

  --output      Write the group by commands to this file

};

	if ( defined $err ) {
		print "Error:\n\n";
		print "$err\n";
	}

	exit;
}
