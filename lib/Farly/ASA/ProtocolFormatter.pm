package Farly::ASA::ProtocolFormatter;

use 5.008008;
use strict;
use warnings;

our $VERSION = '0.20';

our $Int_To_String = {
	51  => "ah",
	88  => "eigrp",
	50  => "esp",
	47  => "gre",
	1   => "icmp",
	58  => "icmp6",
	2   => "igmp",
	9   => "igrp",
	0   => "ip",
	4   => "ipinip",
	94  => "nos",
	89  => "ospf",
	108 => "pcp",
	103 => "pim",
	109 => "snp",
	6   => "tcp",
	17  => "udp",
};

our $String_To_Int = {
	"ah"     => 51,
	"eigrp"  => 88,
	"esp"    => 50,
	"gre"    => 47,
	"icmp"   => 1,
	"icmp6"  => 58,
	"igmp"   => 2,
	"igrp"   => 9,
	"ip"     => 0,
	"ipinip" => 4,
	"nos"    => 94,
	"ospf"   => 89,
	"pcp"    => 108,
	"pim"    => 103,
	"snp"    => 109,
	"tcp"    => 6,
	"udp"    => 17,
};

sub new {
	return bless {}, $_[0];
}

sub as_string {
	return $Int_To_String->{ $_[1] }; 
}

sub as_integer {
	return $String_To_Int->{ $_[1] };
}

1;
__END__

=head1 NAME

Farly::ASA::ProtocolFormatter - Associates protocol ID's and protocol numbers.

=head1 DESCRIPTION

Farly::ASA::ProtocolFormatter is like an enum class, but not. Is device specific.

=head1 METHODS

=head2 new()

The constructor.

=head2 as_string( <protocol number> )

Returns a protcol name for the given protocol number.

=head2 as_integer( <protocol ID> )

Returns a protcol number for the given protocol ID.

=head1 COPYRIGHT AND LICENCE

Farly::ASA::ProtocolFormatter
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