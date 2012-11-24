#!/usr/bin/perl -w

# f_search.pl - Farly Script Tools - Firewall configuration search
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
use Farly::Rule::Expander;
use Farly::Template::Cisco;
use Farly::ASA::PortFormatter;
use Farly::ASA::ProtocolFormatter;
use Farly::ASA::ICMPFormatter;
use Farly::Opts::Search;
use Farly::Remove::Rule;

my %opts;
my $search_parser;
my $search;
my $search_method = 'search';

if ( GetOptions(
		\%opts,     'file=s',        'id=s',          'action=s',
		'p=s',      's=s',           'sport=s',       'd=s',
		'dport=s',  'matches',       'contains',      'remove',
		'outdir=s', 'exclude-src=s', 'exclude-dst=s', 'help|?' ) )
{

	if ( defined $opts{'help'} || defined $opts{'?'} ) {
		usage();
	}
	
	if ( ! defined $opts{'file'} ) {
		usage("Please specify a configuration file");
	}
	
	if ( !-f $opts{'file'} ) {
		usage("Please specify a valid configuration file");
	}
	
	if ( defined $opts{'matches'} ) {
		$search_method = 'matches';
	}
	
	if ( defined $opts{'contains'} ) {
		$search_method = 'contains';
	}
	
	if ( defined $opts{'remove'} ) {
		$search_method = 'contained_by';
	}

	eval {
		$search_parser = Farly::Opts::Search->new( \%opts );
		$search        = $search_parser->search();
	};
	if ($@) {
		usage($@);
	}

}
else {
	usage();
}

print "\nsearching...\n\n";

my $importer = Farly->new();

my $container = $importer->process( "ASA", $opts{'file'} );

my $rule_expander = Farly::Rule::Expander->new($container);

my $expanded_rules = $rule_expander->expand_all();

my $search_result = Object::KVC::List->new();

$expanded_rules->$search_method( $search, $search_result );

if ( $search_parser->filter->size > 0 ) {
	$search_result = filter( $search_result, $search_parser->filter() );
}

if ( defined $opts{'remove'} ) {
	$search_result = remove($container, $search_result);
}

display($search_result, \%opts);

# END MAIN

sub filter {
	my ( $search_result, $filter ) = @_;

	my $filtered_rule_set = Object::KVC::List->new();

	foreach my $rule_object ( $search_result->iter() ) {

		my $excluded;

		foreach my $exclude_object ( $filter->iter() ) {
			if ( $rule_object->contained_by($exclude_object) ) {
				$excluded = 1;
				last;
			}
		}

		if ( !$excluded ) {
			$filtered_rule_set->add($rule_object);
		}
	}

	return $filtered_rule_set;
}

sub remove {
	my ( $fw, $search_result ) = @_;
	
	my $remover = Farly::Remove::Rule->new($fw);
	$remover->remove( $search_result );

	return $remover->result();
}

sub display {
	my ($search_result, $opts) = @_;

	my $template = Farly::Template::Cisco->new('ASA');

	foreach my $rule_object ( $search_result->iter() ) {

		if ( ! defined $opts{'remove'} ) {
			
			my $f = {
				'port_formatter'     => Farly::ASA::PortFormatter->new(),
				'protocol_formatter' => Farly::ASA::ProtocolFormatter->new(),
				'icmp_formatter'     => Farly::ASA::ICMPFormatter->new(),
			};
		
			$template->use_text(1);
			$template->set_formatters($f);
		
			$rule_object->delete_key('LINE');
		}

		$template->as_string($rule_object);

		print "\n";
	}
}

sub usage {
	my ($err) = @_;

	print qq{

  f_search.pl  -  Search firewall configurations for all references to the
                  specified host, subnet, ports or protocols.

Usage:

  f_search.pl [option] [value]

Help:

  f_search.pl --help|-?

Mandatory configuration file:

  --file <file name>  The firewall configuration file

Layer 3 and 4 search options:

  -p <protocol>       Protocol
  -s <ip address>     Source IP Address or Network
  -d <ip>             Destination IP Address or Network
  --sport <port>      Source Port Name or Number
  --dport <port>      Destination Port Name or Number

  Usage of subnet mask format requires quotes, for
  example -d "192.168.1.0 255.255.255.0"

Configure the search:

  --id <string>            Specify an access-list ID
  --action <permit|deny>   Limit results to rules of the specified action
  --matches                Will match the IP addresses or Ports exactly
  --contains               Will only find rules which the firewall would match

  The default option is 'search.' Returns every rule that could possibly
  match the given Layer 3 or Layer 4 options

Removals:

  --remove    Generates commands to remove firewall rules which are returned
                by the specified search. Results are placed in a '<hostname>.txt'. 

Exclusions:

  --exclude-src <file>    Specify a list of source IPv4 networks
                            to exclude from the search results.

  --exclude-dst <file>    Specify a list of destination IPv4 networks
                            to exclude from the search results.
};

	if ( defined $err ) {
		print "Error:\n\n";
		print "$err\n";
	}
	exit;
}
