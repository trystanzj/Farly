package Farly;

use 5.008008;
use strict;
use warnings;
use Carp;
use IO::File;
use File::Spec;
use Log::Log4perl qw(get_logger);
use Object::KVC;
use Farly::Director;
use Farly::IPv4::Address;
use Farly::IPv4::Network;
use Farly::IPv4::Range;
use Farly::IPv4::ICMPType;
use Farly::Transport::Port;
use Farly::Transport::PortGT;
use Farly::Transport::PortLT;
use Farly::Transport::PortRange;
use Farly::Transport::Protocol;

our $VERSION = '0.10';

our ($volume,$dir,$file) = File::Spec->splitpath( $INC{'Farly.pm'} );
Log::Log4perl::init( $volume.$dir.'Farly/Log/Farly.conf');

sub new {
	my ( $class, $container ) = @_;

	my $self = { DIRECTOR => Farly::Director->new(), };
	bless $self, $class;

	my $logger = get_logger(__PACKAGE__);
	$logger->info("$self NEW");

	return $self;
}

sub director {
	return $_[0]->{DIRECTOR};
}

sub process {
	my ( $self, $type, $file_name ) = @_;

	croak "$file_name is not a file" unless ( -f $file_name );

	my $logger = get_logger(__PACKAGE__);

	my $location     = "Farly/$type/Builder.pm";
	my $builder_class = "Farly::".$type."::Builder";

	require $location;
	
	my $builder = $builder_class->new();

	my $file = IO::File->new($file_name);

	$self->director()->set_file($file);
	$self->director()->set_builder($builder);

	my $start = [ Time::HiRes::gettimeofday() ];

	my $container;
	
	eval {
		$container = $self->director()->run();
	};
	if ($@) {
		die "Import of $file_name failed\n",$@,"\n";
	}
	
	my $elapsed = Time::HiRes::tv_interval($start);

	$logger->info("parse time: $elapsed seconds");

	$logger->info("imported ",$container->size()," objects");

	return $container;
}

1;
__END__

=head1 NAME

Farly - Firewall Analysis and Rewrite Library

=head1 DESCRIPTION

Farly translates a vendor specific firewall configuration
into an easily searchable vendor independent firewall model.

Using the Farly firewall model, Perl scripts can be
written to perform tasks such as firewall security audits,
group or rule optimizations or large scale firewall 
configuration changes.

This module is a factory class which abstracts the 
construction of an Object::KVC::List<Object::KVC::Hash> based
firewall device model.

Farly dies on error.

=head1 SYNOPSIS

  use Farly;

  my $importer = Farly->new();

  my $container = $importer->process("ASA", "firewall-config.txt");

  foreach my $ce ( $container->iter() ) {
  	print $ce->dump();
  	print "\n"
  }

=head1 METHODS

=head2 new()
 
The constructor. No arguments required.
 
=head2 process( <firewall type>, <configuration file>)

 my $container = $importer->process("ASA", "firewall-config.txt");

Returns Object::KVC::List<Object::KVC::Hash> firewall device model.
 
Valid firewall types:
 ASA  - Cisco ASA firewall

=head1 AUTHOR

Trystan Johnson

=head1 CONTRIBUTORS

=over

=item *  Lukas Thiemeier <lukast@cpan.org>

=back

=head1 COPYRIGHT AND LICENCE

Farly
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
