#!/usr/bin/perl -w

# f_remove.pl - Farly Script Tools - Retired address removal
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
use Farly::Remove::Address;
use Farly::Template::Cisco;

my %opts;
my $ip;

if ( GetOptions( \%opts, 'file=s', 'host=s', 'net=s', 'help|?' ) ) {

	if ( defined $opts{'help'} || defined $opts{'?'} ) {
		usage();
	}

	if ( ! defined $opts{'file'} ) {
		usage("Please specify a configuration file");
	}
	
	if ( !-f $opts{'file'} ) {
		usage("Please specify a valid configuration file");
	}

	if ( ! defined $opts{'host'} &&  ! defined $opts{'net'} ) {
		usage("Please specify a host or address to remove");	
	}

	eval {
		if ( $opts{'host'} ) {
			$ip = Farly::IPv4::Address->new( $opts{'host'} );
		}
		elsif ( $opts{'net'} ) {
			$ip = Farly::IPv4::Network->new( $opts{'net'} );
		}
	};
	if ($@) {
		usage($@);
	}
}
else {
	usage();
}

print "\n! remove\n\n";

my $fw;
eval {
	my $importer = Farly->new();
	$fw = $importer->process( "ASA", $opts{'file'} );
};
if ($@) {
	usage($@);
}

my $remover = Farly::Remove::Address->new($fw);

$remover->remove($ip);

display( $remover->result() );

sub display {
	my ($remove) = @_;

	my $template = Farly::Template::Cisco->new('ASA');

	foreach my $rule_object ( $remove->iter() ) {
		$template->as_string($rule_object);
		print "\n";
	}
}

sub usage {
	my ($err) = @_;

	print qq{

  f_remove.pl - Generates firewall configurations needed to remove
                all references to the specified host or subnet.

Usage:

  f_remove.pl -f <file> [ -h <ip> | -n <network> ]

Help:

  f_remove.pl --help|-?

Options:

  --file <file name>    The firewall configuration file

  --host <ip address>   Host IPv4 address

  --net  <network>      IPv4 Network in CIDR or subnet mask format

};

	if ( defined $err ) {
		print "Error:\n\n";
		print "$err\n";
	}
	exit;
}
