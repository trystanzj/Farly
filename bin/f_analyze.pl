#!/usr/bin/perl -w

# f_analyze.pl  -  Farly Script Tools - Duplicate and shadowed
#                  firewall rule analysis
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
use Farly::Rules;
use Farly::Optimizer;
use Farly::Remove::Rule;
use Farly::Template::Cisco;
use Farly::ASA::PortFormatter;
use Farly::ASA::ProtocolFormatter;
use Farly::ASA::ICMPFormatter;

my %opts;
my $search = Object::KVC::Hash->new();

if ( GetOptions( \%opts, 'file=s', 'id=s', 'verbose', 'new', 'remove', 'help|?' ) )
{
	if ( defined $opts{'help'} || defined $opts{'?'} ) {
		usage();
	}
	
	if ( ! defined $opts{'file'} ) {
		usage("Please specify a valid configuration file");
	}
	
	if ( !-f $opts{'file'} ) {
		usage("Please specify a valid configuration file");
	}

	if ( ! defined $opts{'id'} ) {
		usage("Please specify an access-list ID");
	}

	eval {
		$search->set( 'ENTRY' => Object::KVC::String->new( 'RULE' ) );
		$search->set( 'ID'    => Object::KVC::String->new( $opts{'id'} ) );
	};
	if ($@) {
		usage($@);
	}
}
else {
	usage();
}

my $file = $opts{'file'};

my $importer = Farly->new();

my $container = $importer->process( "ASA", $file );

my $rule_expander = Farly::Rules->new($container);

my $expanded_rules = $rule_expander->expand_all();

my $search_result = Object::KVC::List->new();

$expanded_rules->matches( $search, $search_result );

my $optimizer = Farly::Optimizer->new($search_result);

if ( defined $opts{'verbose'} ) {
	$optimizer->verbose(1);
}

if ( defined $opts{'new'} ) {

	print "\n! analyzing...\n\n";
	$optimizer->run();

	print "\n! new\n\n";
	display( $optimizer->optimized() );
}
elsif ( defined $opts{'remove'} ) {
	
	my $config = Object::KVC::List->new();
	$container->matches( $search, $config );

	print "\n! analyzing...\n\n";	
	$optimizer->run();

	print "\n! remove\n\n";	
	my $result = replace( $config, $optimizer->optimized(), $optimizer->removed() );

	display( $result, \%opts );
}
else {
	print "\nPlease specifiy a report type: [--new|--remove] \n";
}

#replace the configuration rule with the expanded optimised rules
sub replace {
	my ($config, $optimised, $remove) = @_;

	my $result = Object::KVC::List->new();

	#return an empty list if not removing anything 
	return $result if ( $remove->size() == 0 );

	my $config_index = Object::KVC::Index->new($config);
	$config_index->make_index('LINE');

	my $optimised_index = Object::KVC::Index->new($optimised);
	$optimised_index->make_index('LINE');

	my $removed_index = Object::KVC::Index->new($remove);
	$removed_index->make_index('LINE');

	# get an array of the rule line numbers that have errors
	my @remove_rules = sort { $a <=> $b } keys %{ $removed_index->get_index };

	# check each config rule to see if it uses a group or not
	foreach my $line_number (@remove_rules) {

		# get the config rule
		my $config_rule_set = $config_index->fetch($line_number);
		my $config_rule = $config_rule_set->[0];

		# are there optimised rules for this line?
		if ( defined $optimised_index->get_index->{$line_number} ) {
	
			my $optimised_rule_set = $optimised_index->fetch($line_number);	
			
			foreach my $rule_object ( $optimised_rule_set->iter() ) {
				$result->add($rule_object);
			}
		}

		$config_rule->set( 'REMOVE', Object::KVC::String->new('RULE') );
		$config_rule->delete_key('LINE');
		
		$result->add($config_rule);
	}

	return $result;
}

sub display {
	my ($search_result, $opts) = @_;
	
	my $template = Farly::Template::Cisco->new('ASA');

	my $f = {
		'port_formatter'     => Farly::ASA::PortFormatter->new(),
		'protocol_formatter' => Farly::ASA::ProtocolFormatter->new(),
		'icmp_formatter'     => Farly::ASA::ICMPFormatter->new(),
	};

	$template->use_text(1);
	$template->set_formatters($f);

	foreach my $rule_object ( $search_result->iter() ) {
		if ( ! defined $opts{'remove'} ) {
			$rule_object->delete_key('LINE');
		}
		$template->as_string($rule_object);
		print "\n";
	}
}

sub usage {
	my ($err) = @_;

	print qq{

  f_analyze.pl  -  Find duplicate and shadowed firewall rules

Usage:

  f_analyze.pl --file <file name> --id <id> --verbose {--new|--remove}

  --help|?            Help information

Required Options:

  --file <hostname>   Run optimization for specified firewall
  --id <id>           Run optimization the specified firewall rule set

Report type:

  --verbose           "verbose" displays all errors found along with the duplicate
                      or shadowing rule

  --new               "new" returns an optimised rule set in expanded format

  --remove            "remove" returns all expanded rules which are errors 

};

	if ( defined $err ) {
		print "Error:\n\n";
		print "$err\n";
	}
	exit;
}
