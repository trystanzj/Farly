package Farly::Optimizer;

use 5.008008;
use strict;
use warnings;
use Carp;
use Log::Log4perl qw(get_logger);

use Farly::Template::Cisco;

our $VERSION = '0.09';

sub new {
	my ( $class, $rule_list ) = @_;

	confess "configuration container object required"
	  unless ( defined($rule_list) );

	confess "Object::KVC::List object required"
	  unless ( $rule_list->isa("Object::KVC::List") );

	my $self = {
		ORIGINAL  => $rule_list,
		PERMITS   => Object::KVC::List->new(),
		DENIES    => Object::KVC::List->new(),
		OPTIMIZED => Object::KVC::List->new(),
		REMOVED   => Object::KVC::List->new(),
		P_ACTION  => "permit",
		D_ACTION  => "deny",
		PROTOCOLS => [ 0, 6, 17 ],
		VERBOSE   => undef,
	};

	bless $self, $class;

	my $logger = get_logger(__PACKAGE__);
	$logger->info("$self NEW");
	$logger->info("$self ORIGINAL ", $self->{ORIGINAL});

	#validate input rule set
	$self->_is_valid_rule_set();
	$self->_is_expanded();

	return $self;
}

sub original  { return $_[0]->{ORIGINAL}; }
sub _permits  { return $_[0]->{PERMITS}; }
sub _denies   { return $_[0]->{DENIES}; }
sub optimized { return $_[0]->{OPTIMIZED}; }
sub removed   { return $_[0]->{REMOVED}; }
sub p_action  { return $_[0]->{P_ACTION}; }
sub d_action  { return $_[0]->{D_ACTION}; }
sub protocols { return $_[0]->{PROTOCOLS}; }
sub _is_verbose { return $_[0]->{VERBOSE}; }

sub verbose { 
	my ( $self, $flag ) = @_;
	$self->{VERBOSE} = $flag; 
}

sub set_permit_action {
	my ( $self, $action ) = @_;
	confess "invalid action" unless ( defined($action) && length($action) );
	$self->{P_ACTION} = $action;
	my $logger = get_logger(__PACKAGE__);
	$logger->debug("set permit action to $action");
}

sub set_deny_action {
	my ( $self, $action ) = @_;
	confess "invalid action" unless ( defined($action) && length($action) );
	$self->{D_ACTION} = $action;
	my $logger = get_logger(__PACKAGE__);
	$logger->debug("set deny action to $action");
}

#check if its a single acl
sub run {
	my ($self) = @_;
	
	$self->_do_search();
	$self->_optimize();

	$self->{OPTIMIZED} = $self->_re_add();
}

sub _is_valid_rule_set {
	my ($self) = @_;

	my $id = $self->original->[0]->get("ID");
		
	my $search = Object::KVC::Hash->new();
	$search->set( "ENTRY", Object::KVC::String->new("RULE") );
	$search->set( "ID", $id );

	foreach my $rule ( $self->original->iter() ) {
		if ( ! $rule->matches( $search) ) {
			die "found invalid object in firewall ruleset ",$rule->dump();
		}
	}
}

sub _is_expanded {
	my ($self) = @_;
	foreach my $rule ( $self->original->iter() ) {
		foreach my $key ( $rule->get_keys() ) {
			if ( $rule->get($key)->isa("Object::KVC::HashRef") ) {
				die "an expanded firewall ruleset is required";
			}
		}
	}
}

sub _do_search {
	my ($self) = @_;

	my $search = Object::KVC::Hash->new();

	# 0, 6, 17 or ip, tcp, udp
	foreach my $protocol ( @{ $self->protocols } ) {

		$search->set( "PROTOCOL", Farly::Transport::Protocol->new($protocol) );

		$search->set( "ACTION", Object::KVC::String->new( $self->p_action ) );
		$self->original->matches( $search, $self->_permits );

		$search->set( "ACTION", Object::KVC::String->new( $self->d_action ) );
		$self->original->matches( $search, $self->_denies );
	}
}

sub _re_add {
	my ($self) = @_;

	my $IP   = Farly::Transport::Protocol->new('0');
	my $TCP  = Farly::Transport::Protocol->new('6');
	my $UDP  = Farly::Transport::Protocol->new('17');
	
	#add non ip, tcp, and udp rules back in
	foreach my $rule ( $self->original->iter() ) {
	
		if ( $rule->has_defined('COMMENT') ) {
			$self->optimized->add( $rule );
		 	next;
		}

		if ( ! ( $rule->get('PROTOCOL')->equals($IP) ||
			  $rule->get('PROTOCOL')->equals($TCP) ||
			 $rule->get('PROTOCOL')->equals($UDP) ) )
		{
			$self->optimized->add( $rule );
		 	next;
		}
	}

	my @full_list = sort _ascending_LINE $self->optimized->iter();
	
	my $new_optimized = Object::KVC::List->new();
	
	foreach my $rule ( @full_list ) {
		$new_optimized->add($rule);
	}	

	return $new_optimized;
}

# sort rules in ascending order by line number
sub _ascending_LINE {
	$a->get("LINE")->number() <=> $b->get("LINE")->number();
}

# sort rules in ascending order so that current can contain next
# but next can't contain current
sub _ascending_l4 {
	     $a->get("DST_IP")->first() <=> $b->get("DST_IP")->first()
	  || $b->get("DST_IP")->last() <=> $a->get("DST_IP")->last()
	  || $a->get("SRC_IP")->first() <=> $b->get("SRC_IP")->first()
	  || $b->get("SRC_IP")->last() <=> $a->get("SRC_IP")->last()
	  || $a->get("DST_PORT")->first() <=> $b->get("DST_PORT")->first()
	  || $b->get("DST_PORT")->last() <=> $a->get("DST_PORT")->last()
	  || $a->get("SRC_PORT")->first() <=> $b->get("SRC_PORT")->first()
	  || $b->get("SRC_PORT")->last() <=> $a->get("SRC_PORT")->last()
	  || $a->get("PROTOCOL")->protocol() <=> $b->get("PROTOCOL")->protocol();
}

sub _five_tuple {
	my ( $self, $rule ) = @_;

	my $logger = get_logger(__PACKAGE__);

	my $r = Object::KVC::Hash->new();

	my @rule_properties = qw(PROTOCOL SRC_IP SRC_PORT DST_IP DST_PORT);

	foreach my $property (@rule_properties) {
		if ( $rule->has_defined($property) ) {
			$r->set( $property, $rule->get($property) );
		}
		else {
			$logger->warn("property $property not defined in ", $rule->dump());
		}
	}

	return $r;
}

# Given rule X, Y, where X precedes Y in the ACL
# X and Y are inconsistent if:
# Xp contains Yd
# Xd contains Yp

sub _inconsistent {
	my ( $self, $s_a, $s_an ) = @_;

	# $s_a = ARRAY ref of rules of action a
	# $s_an = ARRAY ref of rules of action !a
	# $s_a and $s_an are sorted by line number and must be readonly

	# hash of rule indexes to keep or remove
	my %remove;

	my $rule_x;
	my $rule_y;

	# iterate over rules of action a
	for ( my $x = 0 ; $x != scalar( @{$s_a} ) ; $x++ ) {

		$rule_x = $s_a->[$x];

		# iterate over rules of action !a
		for ( my $y = 0 ; $y != scalar( @{$s_an} ) ; $y++ ) {

			#skip check if rule_y is already removed
			next if $remove{$y};

			$rule_y = $s_an->[$y];

			# if $rule_x comes before $rule_y in the rule set
			# then check if $rule_x contains $rule_y

			if ( $rule_x->get('LINE')->number() <= $rule_y->get('LINE')->number() )
			{

				# $rule_x1 is rule_x with layer 3 and 4 properties only
				my $rule_x1 = $self->_five_tuple($rule_x);

				if ( $rule_y->contained_by($rule_x1) ) {

					# note removal of rule_y and the
					# rule_x which caused the inconsistency
					$remove{$y} = $rule_x;
				}
			}
		}
	}

	# list of action !a rules to be removed
	return %remove;
}

# Given rule X, Y, where X precedes Y in the ACL
# if Yp contains Xp and there does not exist rule Zd between
# Xp and Yp such that Zd intersect Xp and Xp !contains Zd

sub _can_remove {
	my ( $self, $rule_x, $rule_y, $s_an ) = @_;

	# $rule_x = the rule contained by $rule_y
	# $s_an = rules of action !a sorted by ascending DST_IP

	# $rule_x1 is rule_x with layer 3 and 4 properties only
	my $rule_x1 = $self->_five_tuple($rule_x);

	foreach my $rule_z ( @{$s_an} ) {

		if ( ! $rule_z->get("DST_IP")->gt( $rule_x1->get("DST_IP") ) ) {

			#is Z between X and Y?
			if ( ( $rule_z->get('LINE')->number() >= $rule_x->get('LINE')->number() )
				&& ( $rule_z->get('LINE')->number() <= $rule_y->get('LINE')->number() ) )
			{
				# Zd intersect Xp?
				if ( $rule_z->intersects($rule_x1) ) {
					# Xp ! contain Zd
					if ( !$rule_z->contained_by($rule_x1) ) {
						return undef;
					}
				}
			}
		}
		else {
			# $rule_z is greater than $rule_x1 therefore rule_x and rule_z are disjoint
			last;
		}
	}

	return 1;
}

# Given rule X, Y, where X precedes Y in the ACL
# a is the action type of the rule
# if X contains Y then Y can be removed
# if Y contains X then X can be removed if there are no rules Z
# in $s_an that intersect X and exist between X and Y in the ACL

sub _redundant {
	my ( $self, $s_a, $s_an ) = @_;

	# $s_a = ARRAY ref of rules of action a to be validated
	# $s_an = ARRAY ref of rules of action !a
	# $s_a and $s_an are sorted by ascending and must be readonly

	# hash of rules to keep or remove
	my %remove;

	# iterate over rules of action a
	for ( my $x = 0 ; $x != scalar( @{$s_a} ) ; $x++ ) {

		#skip check if rule_y is already removed
		next if $remove{$x};

		# $rule_x1 is rule_x with layer 3 and 4 properties only
		my $rule_x = $s_a->[$x];

		# remove non layer 3/4 rule properties
		my $rule_x1 = $self->_five_tuple( $s_a->[$x] );

		for ( my $y = $x + 1 ; $y != scalar( @{$s_a} ) ; $y++ ) {

			my $rule_y = $s_a->[$y];

			if ( !$rule_y->get("DST_IP")->gt( $rule_x->get("DST_IP") ) ) {

				# $rule_x comes before rule_y in the rule array
				# therefore x might contain y

				if ( $rule_y->contained_by($rule_x1) ) {

					# rule_x is before rule_y in the rule set so remove rule_y
					if ( $rule_x->get('LINE')->number() <= $rule_y->get('LINE')->number() )	{
						$remove{$y} = $rule_x;
					}
					else {
						# rule_y is actually after rule_x in the rule set
						if ( $self->_can_remove( $rule_y, $rule_x, $s_an ) ) {
							$remove{$y} = $rule_x;
						}
					}
				}
			}
			else {
				# rule_y DST_IP is greater than rule_x DST_IP then rule_x can't
				# contain rule_y or any rules after rule_y (they are disjoint)
				last;
			}
		}
	}

	return %remove;
}

# copies rules in @{$a_ref} except for the rules
# whose index exists in remove, which are not copied
sub _remove_copy_exists {
	my ( $self, $a_ref, $remove ) = @_;

	my $r = Object::KVC::List->new();

	for ( my $i = 0 ; $i != scalar( @{$a_ref} ) ; $i++ ) {
		if ( !exists( $remove->{$i} ) ) {
			$r->add( $a_ref->[$i] );
		}
		else {
			$self->removed->add( $a_ref->[$i] );
		}
	}

	return $r;
}

sub _log_remove {
	my ( $self, $keep, $remove ) = @_;

	my $logger = get_logger(__PACKAGE__);

	my $string = '';
	my $template = Farly::Template::Cisco->new( 'ASA', 'OUTPUT' => \$string );

	foreach my $i ( sort keys %$remove ) {
		$string .= " ! ";
		$template->as_string( $remove->{$i} );
		$string .= "\n";
		$string .= "no ";
		$template->as_string( $keep->[$i] );
		$string .= "\n";
	}

	if ( $self->_is_verbose() ) {
		print $string;
	}

	$logger->info("analysis result :\n$string");
}

sub _optimize {
	my ($self) = @_;

	my $logger = get_logger(__PACKAGE__);
	
	my @arr_permits;
	my @arr_denys;

	@arr_permits = sort _ascending_LINE $self->_permits->iter();
	@arr_denys   = sort _ascending_LINE $self->_denies->iter();

	# remove is a hash with the index number of
	# rules which are to be removed. the value is the
	# rule object causing the redundancy
	my %remove;    # %remove<index, Object::KVC::Hash>

	# find permit rules that contain deny rules
	# that are defined further down in the rule set
	$logger->info("Checking for deny rule inconsistencies...");
	%remove = $self->_inconsistent( \@arr_permits, \@arr_denys );

	# create a new list of deny rules which are being kept
	$self->{DENIES} = $self->_remove_copy_exists( \@arr_denys, \%remove );
	$self->_log_remove( \@arr_denys, \%remove );

	# the consistent deny list sorted by LINE again
	@arr_denys = sort _ascending_LINE $self->_denies->iter();

	# find deny rules which contain permit
	# rules further down in the rule set
	$logger->info("Checking for permit rule inconsistencies...");
	%remove = $self->_inconsistent( \@arr_denys, \@arr_permits );

	# create the list of permit rules which are being kept
	$self->{PERMITS} = $self->_remove_copy_exists( \@arr_permits, \%remove );
	$self->_log_remove( \@arr_permits, \%remove );

	# sort the rule in ascending order
	@arr_permits = sort _ascending_l4 $self->_permits->iter();
	@arr_denys   = sort _ascending_l4 $self->_denies->iter();

	$logger->info("Checking for permit rule redundancies...");
	%remove = $self->_redundant( \@arr_permits, \@arr_denys );

	$self->{PERMITS} = $self->_remove_copy_exists( \@arr_permits, \%remove );
	$self->_log_remove( \@arr_permits, \%remove );

	# sort the permits again
	@arr_permits = sort _ascending_l4 $self->_permits->iter();

	$logger->info("Checking for deny rule redundancies...");
	%remove = $self->_redundant( \@arr_denys, \@arr_permits );

	$self->{DENIES} = $self->_remove_copy_exists( \@arr_denys, \%remove );
	$self->_log_remove( \@arr_denys, \%remove );

	# combine the permit and deny rules into the optimized rule set
	foreach my $rule ( $self->_permits->iter() ) {
		$self->optimized->add( $rule->clone() );
	}

	foreach my $rule ( $self->_denies->iter() ) {
		$self->optimized->add( $rule->clone() );
	}
}

1;
=head1 NAME

Farly::Optimizer - Optimize a raw firewall rule set

=head1 SYNOPSIS

  use Farly;
  use Farly::Rules;
  use Farly::Optimizer;

  my $file = "test.cfg";
  my $importer = Farly->new();
  my $container = $importer->process("ASA",$file);

  my $rule_expander = Farly::Rules->new( $container );
  my $expanded_rules = $rule_expander->expand_all();  

  my $search = Object::KVC::Hash->new();
  $search->set( "ID", Object::KVC::String->new("outside-in") );
  my $search_result = Object::KVC::List->new();
  $expanded_rules->matches( $search, $search_result );

  my $optimizer = Farly::Optimizer->new( $search_result );
  $optimizer->run();
  my $optimized_ruleset = $optimizer->optimized();

  my $template = Farly::Template::Cisco->new('ASA');
  foreach my $rule ( $optimized_ruleset->iter ) {
    $template->as_string( $rule );
    print "\n";
  }

=head1 DESCRIPTION

Farly::Optimizer finds duplicate and contained IP, TCP, and UDP firewall
rules in a raw rule set.

Farly::Optimizer stores the list of optimized rules, as well as the list 
of rule entries which can be removed from the rule set without affecting the
traffic filtering properties of the firewall.

The 'optimized' and 'removed' rule sets are expanded rule entries and may
not correspond to the actual configuration on the device.

To view Farly::Optimizer actions and results add the following to "Log/Farly.conf"

 log4perl.logger.Farly.Optimizer=INFO,Screen
 log4perl.appender.Screen=Log::Log4perl::Appender::Screen 
 log4perl.appender.Screen.mode=append
 log4perl.appender.Screen.layout=Log::Log4perl::Layout::PatternLayout
 log4perl.appender.Screen.layout.ConversionPattern=%d %p> %F{1}:%L %M - %m%n

Logged rules are currently displayed in Cisco ASA format.

=head1 METHODS

=head2 new()

The constructor. A single expanded rule list is required.

  $optimizer = Farly::Optimizer->new( $expanded_rules<Object::KVC::List> );

=head2 verbose()

Have the optimizer all analysis results in Cisco ASA format

	$optimizer->verbose(1);

=head2 run()

Run the optimizer.

	$optimizer->run();

=head2 set_permit_action()

Change the default permit string. The default permit string is "permit."

	$optimizer->set_permit_action("accept");

=head2 set_deny_action()

Change the default deny string. The default deny string is "deny."

	$optimizer->set_permit_action("drop");

=head2 optimized()

Returns an Object::KVC::List<Object::KVC::Hash> container of all
expanded firewall rules, excluding duplicate and overlapping rule objects,
in the current Farly firewall model.

  $optimized_ruleset = $optimizer->optimized();

=head2 removed()

Returns an Object::KVC::List<Object::KVC::Hash> container of all
duplicate and overlapping firewall rule objects which could be removed.

  $remove_rules = $optimizer->removed();

=head1 ACKNOWLEDGEMENTS

Farly::Optimizer is based on the "optimise" algorithm in the following
paper:

Qian, J., Hinrichs, S., Nahrstedt K. ACLA: A Framework for Access
Control List (ACL) Analysis and Optimization, Communications and 
Multimedia Security, 2001

=head1 COPYRIGHT AND LICENCE

Farly::Optimizer
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
