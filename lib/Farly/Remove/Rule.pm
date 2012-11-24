package Farly::Remove::Rule;

use 5.008008;
use strict;
use warnings;
use Carp;
use Farly::Rule::Expander;

our $VERSION = '0.11';

# one object per firewall
sub new {
	my ( $class, $container ) = @_;

	confess "firewall configuration container object required"
	  unless ( defined($container) );

	confess "Object::KVC::List object required"
	  unless ( $container->isa("Object::KVC::List") );

	my $self = {
		CONFIG => $container,
		RESULT => Object::KVC::List->new(),
	};
	bless $self, $class;

	return $self;
}

# given a config container ::List and a ::List of rules to remove
# modify the configuration to remove the remove rules
# if the config has a group, then remove the rule with the group
# and keep the expanded rules in the configuration

sub config { return $_[0]->{CONFIG} }
sub result { return $_[0]->{RESULT} }

sub _fetch_config_acl {
	my ( $self, $id ) = @_;

	my $search = Object::KVC::Hash->new();
	$search->set( 'ENTRY', Object::KVC::String->new('RULE') );
	$search->set( 'ID',    $id );

	my $search_result = Object::KVC::List->new();

	$self->config->matches( $search, $search_result );

	return $search_result;
}

sub _has_group {
	my ( $self, $rule_object ) = @_;

	my $GROUP = Object::KVC::HashRef->new();
	$GROUP->set( 'ENTRY', Object::KVC::String->new('GROUP') );

	foreach my $property ( $rule_object->get_keys() ) {
		if ( $rule_object->get($property)->isa('Object::KVC::HashRef') ) {
			if ( $rule_object->get($property)->matches($GROUP) ) {
				return 1;
			}
		}
	}
}

sub _is_unique {
	my ( $self, $rule_set, $id ) = @_;

	foreach my $object ( $rule_set->iter() ) {
		if ( !$object->get('ID')->equals($id) ) {
			confess "more than one rule $id ", $object->get('ID')->as_string(),
			  "\n";
		}
	}
}

sub _is_expanded {
	my ( $self, $rule_set ) = @_;

	foreach my $object ( $rule_set->iter() ) {
		if ( $self->_has_group($object) ) {
			confess "ruleset not expanded ", $object->get('ID')->as_string(),
			  "\n";
		}
	}
}

sub remove {
	my ( $self, $remove_list ) = @_;

	# $remove_list isa Object::KVC::List of expanded Rules (not config rules)
	confess "remove list of rules container object required"
	  unless ( defined($remove_list) );

	confess "Object::KVC::List object required"
	  unless ( $remove_list->isa("Object::KVC::List") );

	#$remove_list must contain one expanded rule set only
	my $id = $remove_list->[0]->get('ID');
	$self->_is_unique( $remove_list, $id );

	#$remove_list must be expanded rules, it must not contain groups
	$self->_is_expanded($remove_list);

	# get the configuration rule set
	my $config_list = $self->_fetch_config_acl($id);

	# create indexes by LINE,  'LINE NO.' => ::Set
	my $config_index = Object::KVC::Index->new($config_list);
	$config_index->make_index("LINE");

	my $removed_index = Object::KVC::Index->new($remove_list);
	$removed_index->make_index("LINE");

	# get an array of the rule line numbers that have errors
	my @remove_rules = sort { $a <=> $b } keys %{ $removed_index->get_index };

	# create a rule expander object
	my $rule_expander = Farly::Rule::Expander->new( $self->config );

	# check each config rule to see if it uses a group or not
	foreach my $line_number (@remove_rules) {

		# get the config rule
		my $config_rule_set = $config_index->fetch($line_number);
		if ( $config_rule_set->size != 1 ) {
			confess "config rule set size not 1. that was unexpected!";
		}
		my $config_rule = $config_rule_set->[0];

		#get the rule entries that need to be removed from the config
		my $remove_set = $removed_index->fetch($line_number);

		#if the config rule has an object-group then replace the config
		#rule with all expanded rule entries that need to be kept
		if ( $self->_has_group($config_rule) ) {

			# clone and expand the config rule, putting the rule
			# entries into a ::Set
			my $clone = $config_rule->clone();

			my $exp_config_rule_set = Object::KVC::Set->new();
			$rule_expander->expand( $clone, $exp_config_rule_set );

			# ::Set difference is all rule entries in the config that
			#  are not in remove, i.e. that need to be kept
			my $diff = $exp_config_rule_set->difference($remove_set);

			# the rule entries to be kept are added to the config in raw form
			# diff is empty if the entire config rule needs to be removed
			foreach my $keep_object ( $diff->iter() ) {
				$self->result->add($keep_object);
			}

		}

		#the running config rule had an error, so remove it
		#use the expanded rule entries instead
		my $r = $config_rule->clone();
		$r->set( 'REMOVE', Object::KVC::String->new('RULE') );
		$r->delete_key('LINE');
		$self->result->add($r);
	}
}

1;
__END__

=head1 NAME

Farly::Remove::Rule - Removes a list firewall rule entries

=head1 DESCRIPTION

Farly::Remove::Rule calculates dependencies and generates the commands needed
to remove a $list<Object::KVC::List<Object::KVC::Hash>> of firewall rule entries
from the given firewall configuration.

If the firewall configuration rule uses a group, then the configuration rule is removed
and the expanded firewall rule entries are used in the configuration.

=head1 METHODS

=head2 new( $list<Object::KVC::List<Object::KVC::Hash>> )

The constructor. A firewall configuration $list must be provided.

  $rule_remover = Farly::Remove::Rule->new( $list );

=head2 remove( $list<Object::KVC::List<Object::KVC::Hash>> )

Resolves dependencies and removes the list of firewall rule entries from the 
current Farly firewall model.

  $remover->remove( $list );

=head2 result()

Returns an Object::KVC::Set<Object::KVC::Hash> object containing all objects
which need to be removed or added to the current Farly firewall model in order
to remove all references to the list of removed firewall rule entries.

  $remove_result_set = $remover->result();

=head2 config()

Return the current configuration Object::KVC::List<Object::KVC::Hash> object.

  $fw_config = $remover->config();
  
After calling remove() this will be the up to date configuration, with configuration
rules removed and expanded rule entries added in.

=head1 COPYRIGHT AND LICENCE

Farly::Remove::Rule
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
