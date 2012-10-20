use strict;
use warnings;

use Data::Dumper;
use Scalar::Util 'blessed';
use Test::Simple tests => 29;
use Log::Log4perl qw(:easy);
Log::Log4perl->easy_init($ERROR);
use Farly::ASA::Parser;

my $parser = Farly::ASA::Parser->new();

ok( defined($parser), "constructor" );

my $string;
my $tree;
my $actual;
my $expected;

#
# hostname
#

$string = q{hostname test_fw};

$tree   = $parser->parse($string);
$actual = visit($tree);

$expected = { 'hostname' => 'test_fw' };

ok( equals( $expected, $actual ), "hostname" );

#
# name
#

$string = q{name 192.168.10.0 net1 description This is a test};
$tree   = $parser->parse($string);
$actual = visit($tree);

$expected = {
	'ip'          => '192.168.10.0',
	'name'        => 'net1',
	'description' => 'This is a test'
};

ok( equals( $expected, $actual ), "name" );

#
# interface nameif
#

$string = q{
interface Vlan2
 nameif outside
};

$tree = $parser->parse($string);

$actual = visit($tree);

$expected = {
	'if_name'   => 'outside',
	'interface' => 'Vlan2'
};

ok( equals( $expected, $actual ), "interface nameif" );

#
# interface ip
#

$string = q{
interface Vlan2
 ip address 10.2.19.8 255.255.255.248 standby 10.2.19.9
};
$tree = $parser->parse($string);

$actual = visit($tree);

$expected = {
	'if_ip'      => '10.2.19.8',
	'if_mask'    => '255.255.255.248',
	'interface'  => 'Vlan2',
	'if_standby' => '10.2.19.9'
};

ok( equals( $expected, $actual ), "interface ip" );

#
# interface security-level
#

$string = q{
interface Vlan2
 security-level 0
};

$tree   = $parser->parse($string);
$actual = visit($tree);

$expected = {
	'sec_level' => '0',
	'interface' => 'Vlan2'
};

ok( equals( $expected, $actual ), "interface security-level" );

#
# object host
#

$string = q{
object network TestFW
 host 192.168.5.219
};

$tree   = $parser->parse($string);
$actual = visit($tree);

$expected = {
	'object_host' => '192.168.5.219',
	'object'      => 'network',
	'object_id'   => 'TestFW'
};

ok( equals( $expected, $actual ), "object host" );

#
# object subnet
#

$string = q{
object network test_net1
 subnet 10.1.2.0 255.255.255.0
};

$tree   = $parser->parse($string);
$actual = visit($tree);

$expected = {
	'object_network' => '10.1.2.0 255.255.255.0',
	'object'         => 'network',
	'object_id'      => 'test_net1'
};

ok( equals( $expected, $actual ), "object subnet" );

#
# object range
#

$string = q{
object network test_net1_range
 range 10.1.2.13 10.1.2.28
};

$tree   = $parser->parse($string);
$actual = visit($tree);

$expected = {
	'object_range' => '10.1.2.13 10.1.2.28',
	'object'       => 'network',
	'object_id'    => 'test_net1_range'
};

ok( equals( $expected, $actual ), "object range" );

#
# object service src dst
#

$string = q{
object service web_https
 service tcp source gt 1024 destination eq 443
};

$tree   = $parser->parse($string);
$actual = visit($tree);

$expected = {
	'object_service_protocol' => 'tcp',
	'object'                  => 'service',
	'object_service_dst'      => '443',
	'object_id'               => 'web_https',
	'object_service_src'      => '1024'
};

ok( equals( $expected, $actual ), "object service src dst" );

#
# object-group service src
#

$string = q{object-group service NFS
 service-object 6 source eq 2046
};
$tree = $parser->parse($string);

$actual = visit($tree);

$expected = {
	'og_so_src_port' => '2046',
	'og_id'          => 'NFS',
	'og_so_protocol' => '6',
	'object_group'   => 'service'
};

ok( equals( $expected, $actual ), "object-group service src" );

#
# object-group protocol
#

$string = q{
object-group protocol test65
 protocol-object tcp
};

$tree   = $parser->parse($string);
$actual = visit($tree);

$expected = {
	'og_id'        => 'test65',
	'og_object'    => 'tcp',
	'object_group' => 'protocol'
};

ok( equals( $expected, $actual ), "object-group protocol" );

#
# network-object named host
#
$string = q{
object-group network test_net
 network-object host server1
};

$tree   = $parser->parse($string);
$actual = visit($tree);

$expected = {
	'og_id'        => 'test_net',
	'og_object'    => 'server1',
	'object_group' => 'network'
};

ok( equals( $expected, $actual ), "network-object named host" );

#
# port-object
#

$string = q{
object-group service web tcp
 port-object eq www
};

$tree   = $parser->parse($string);
$actual = visit($tree);

$expected = {
	'og_protocol'  => 'tcp',
	'og_id'        => 'web',
	'og_object'    => 'www',
	'object_group' => 'service'
};

ok( equals( $expected, $actual ), "port-object" );

#
# network group-object
#

$string = q{
object-group network test_net
 group-object server1
};

$tree   = $parser->parse($string);
$actual = visit($tree);

$expected = {
	'og_id'        => 'test_net',
	'og_object'    => 'server1',
	'object_group' => 'network'
};

ok( equals( $expected, $actual ), "network group-object" );

#
# object-group description
#

$string = q{
object-group network test_net
 description test network
};

$tree   = $parser->parse($string);
$actual = visit($tree);

$expected = {
	'og_id'        => 'test_net',
	'og_object'    => 'test network',
	'object_group' => 'network'
};

ok( equals( $expected, $actual ), "object-group description" );

#
# object-group service dst
#

$string = q{object-group service NFS
 service-object 6 destination eq 2046
};

$tree   = $parser->parse($string);
$actual = visit($tree);

$expected = {
	'og_id'          => 'NFS',
	'og_so_protocol' => '6',
	'object_group'   => 'service',
	'og_so_dst_port' => '2046'
};

ok( equals( $expected, $actual ), "object-group service dst" );

#
# object-group service
#

$string = q{
object-group service www tcp
 group-object web
};

$tree   = $parser->parse($string);
$actual = visit($tree);

$expected = {
	'og_protocol'  => 'tcp',
	'og_id'        => 'www',
	'og_object'    => 'web',
	'object_group' => 'service'
};

ok( equals( $expected, $actual ), "object-group service" );

#
# access-list 1
#

$string =
q{access-list acl-outside permit tcp OG_NETWORK customerX range 1024 65535 host server1 eq 80};

$tree   = $parser->parse($string);
$actual = visit($tree);

$expected = {
	'acl_action'   => 'permit',
	'acl_id'       => 'acl-outside',
	'acl_dst_port' => '80',
	'acl_src_port' => '1024 65535',
	'acl_dst_ip'   => 'server1',
	'acl_protocol' => 'tcp',
	'acl_src_ip'   => 'customerX'
};

ok( equals( $expected, $actual ), "access-list 1" );

#
# access-list 2
#

$string =
q{access-list acl-outside line 1 extended permit ip host server1 eq 1024 any eq 80};

$tree   = $parser->parse($string);
$actual = visit($tree);

$expected = {
	'acl_dst_ip'   => 'any',
	'acl_id'       => 'acl-outside',
	'acl_action'   => 'permit',
	'acl_dst_port' => '80',
	'acl_src_port' => '1024',
	'acl_line'     => '1',
	'acl_protocol' => 'ip',
	'acl_src_ip'   => 'server1',
	'acl_type'     => 'extended'
};

ok( equals( $expected, $actual ), "access-list 2" );

#
# access-list 3
#

$string =
q{access-list acl-outside permit tcp OG_NETWORK customerX OG_SERVICE high_ports host server1 eq 80};

$tree   = $parser->parse($string);
$actual = visit($tree);

$expected = {
	'acl_action'   => 'permit',
	'acl_id'       => 'acl-outside',
	'acl_dst_port' => '80',
	'acl_src_port' => 'high_ports',
	'acl_dst_ip'   => 'server1',
	'acl_protocol' => 'tcp',
	'acl_src_ip'   => 'customerX'
};

ok( equals( $expected, $actual ), "access-list 3" );

#
# access-list 4
#

$string =
q{access-list acl-outside permit OG_SERVICE srv2 OG_NETWORK customerX OG_SERVICE high_ports host server1 eq 80};

$tree   = $parser->parse($string);
$actual = visit($tree);

$expected = {
	'acl_action'   => 'permit',
	'acl_id'       => 'acl-outside',
	'acl_dst_port' => '80',
	'acl_src_port' => 'high_ports',
	'acl_dst_ip'   => 'server1',
	'acl_src_ip'   => 'customerX',
	'acl_protocol' => 'srv2'
};

ok( equals( $expected, $actual ), "access-list 4" );

#
# access-list 5
#

$string =
  q{access-list acl-outside permit object citrix any OG_NETWORK citrix_servers};

$tree   = $parser->parse($string);
$actual = visit($tree);

$expected = {
	'acl_action'   => 'permit',
	'acl_id'       => 'acl-outside',
	'acl_dst_ip'   => 'citrix_servers',
	'acl_protocol' => 'citrix',
	'acl_src_ip'   => 'any'
};

ok( equals( $expected, $actual ), "access-list 5" );

#
# access-list 6
#

$string =
q{access-list acl-outside permit OG_SERVICE srv2 OG_NETWORK customerX OG_SERVICE high_ports net1 255.255.255.0 eq www};

$tree   = $parser->parse($string);
$actual = visit($tree);

$expected = {
	'acl_action'   => 'permit',
	'acl_id'       => 'acl-outside',
	'acl_dst_port' => 'www',
	'acl_src_port' => 'high_ports',
	'acl_dst_ip'   => 'net1 255.255.255.0',
	'acl_src_ip'   => 'customerX',
	'acl_protocol' => 'srv2'
};

ok( equals( $expected, $actual ), "access-list 6" );

#
# access-list 7
#

$string =
  q{access-list acl-outside permit ip any range 1024 65535 host server1 gt www};

$tree = $parser->parse($string);

$actual = visit($tree);

$expected = {
	'acl_action'   => 'permit',
	'acl_id'       => 'acl-outside',
	'acl_dst_port' => 'www',
	'acl_src_port' => '1024 65535',
	'acl_dst_ip'   => 'server1',
	'acl_protocol' => 'ip',
	'acl_src_ip'   => 'any'
};

ok( equals( $expected, $actual ), "access-list 7" );

#
# access-list 8
#

$string =
q{access-list acl-outside extended permit OG_PROTOCOL sip_transport OG_NETWORK voip_nets OG_SERVICE high_ports OG_NETWORK voip_srvs OG_SERVICE sip_ports};

$tree = $parser->parse($string);

$actual = visit($tree);

$expected = {
	'acl_dst_ip'   => 'voip_srvs',
	'acl_id'       => 'acl-outside',
	'acl_action'   => 'permit',
	'acl_src_port' => 'high_ports',
	'acl_dst_port' => 'sip_ports',
	'acl_protocol' => 'sip_transport',
	'acl_src_ip'   => 'voip_nets',
	'acl_type'     => 'extended'
};

ok( equals( $expected, $actual ), "access-list 8" );

#
# access-list object service
#

$string =
q{access-list acl-outside line 1 extended permit object citrix object internal_net object citrix_net};

$tree   = $parser->parse($string);
$actual = visit($tree);

$expected = {
	'acl_action'   => 'permit',
	'acl_id'       => 'acl-outside',
	'acl_dst_ip'   => 'citrix_net',
	'acl_protocol' => 'citrix',
	'acl_line'     => '1',
	'acl_src_ip'   => 'internal_net',
	'acl_type'     => 'extended'
};

ok( equals( $expected, $actual ), "access-list object service" );

#
# access-list icmp-type
#

$string =
q{access-list acl-outside line 1 extended permit icmp any any OG_ICMP-TYPE safe-icmp};

$tree   = $parser->parse($string);
$actual = visit($tree);

$expected = {
	'acl_dst_ip'    => 'any',
	'acl_icmp_type' => 'safe-icmp',
	'acl_id'        => 'acl-outside',
	'acl_action'    => 'permit',
	'acl_line'      => '1',
	'acl_protocol'  => 'icmp',
	'acl_src_ip'    => 'any',
	'acl_type'      => 'extended'
};

ok( equals( $expected, $actual ), "access-list icmp-type" );

#
# access-group
#
$string = q{
access-group acl-outside in interface outside
};

$tree   = $parser->parse($string);
$actual = visit($tree);

$expected = {
	'ag_interface' => 'outside',
	'ag_direction' => 'in',
	'ag_id'        => 'acl-outside'
};

ok( equals( $expected, $actual ), "access-group" );

#
# Finished tests
#

sub visit {
	my ($node) = @_;

	my $Rule_To_Key_Map = {
		"hostname"                => 1,
		"names"                   => 1,
		"NAME"                    => 1,
		"interface"               => 1,
		"if_name"                 => 1,
		"sec_level"               => 1,
		"if_ip"                   => 1,
		"if_mask"                 => 1,
		"if_standby"              => 1,
		"object"                  => 1,
		"object_id"               => 1,
		"object_host"             => 1,
		"object_range"            => 1,
		"object_network"          => 1,
		"object_service_protocol" => 1,
		"object_service_src"      => 1,
		"object_service_dst"      => 1,
		"object_icmp"             => 1,
		"object_group"            => 1,
		"og_id"                   => 1,
		"og_protocol"             => 1,
		"og_object"               => 1,
		"og_so_protocol"          => 1,
		"og_so_src_port"          => 1,
		"og_so_dst_port"          => 1,
		"acl_action"              => 1,
		"acl_id"                  => 1,
		"acl_line"                => 1,
		"acl_type"                => 1,
		"acl_protocol"            => 1,
		"acl_protocol_group"      => 1,
		"acl_service_group"       => 1,
		"acl_service_object"      => 1,
		"acl_src_ip"              => 1,
		"acl_src_port"            => 1,
		"acl_dst_ip"              => 1,
		"acl_dst_port"            => 1,
		"acl_icmp_type"           => 1,
		"acl_remark"              => 1,
		"ag_id"                   => 1,
		"ag_direction"            => 1,
		"ag_interface"            => 1,
	};

	my $parent_key;
	my $result;

	# set s of explored vertices
	my %seen;

	#stack is all neighbors of s
	my @stack;
	push @stack, [ $node, $parent_key ];

	my $key;

	while (@stack) {

		my $rec = pop @stack;

		$node       = $rec->[0];
		$parent_key = $rec->[1];    #undef for root

		next if ( $seen{$node}++ );

		my $rule_id = ref($node);

		if ( exists( $Rule_To_Key_Map->{$rule_id} ) ) {
			$parent_key = $rule_id;
		}

		if ( $rule_id eq "names" ) {
			$result->{'name'}        = $node->{NAME}->{__VALUE__};
			$result->{'ip'}          = $node->{IPADDRESS}->{__VALUE__};
			$result->{'description'} = $node->{REMARKS}->{__VALUE__};
			return $result;
		}

		foreach my $key ( keys %$node ) {

			next if ( $key eq "EOL" );

			my $next = $node->{$key};

			if ( blessed($next) ) {

				if ( exists( $next->{__VALUE__} ) ) {

			   #print ref($node), " ", ref($next), " ", $next->{__VALUE__},"\n";
					my $rule  = ref($node);
					my $token = $next->{__VALUE__};
					$result->{$parent_key} = $token;

					#print $rule, " ", $result->{$rule}, "\n";
				}

				push @stack, [ $next, $parent_key ];

				#push @stack, $next;
			}
		}
	}

	return $result;
}

sub equals {
	my ( $hash1, $hash2 ) = @_;

	if ( scalar( keys %$hash1 ) != scalar( keys %$hash2 ) ) {
		return undef;
	}

	foreach my $key ( keys %$hash2 ) {
		if ( !defined( $hash1->{$key} ) ) {
			return undef;
		}
		if ( $hash1->{$key} ne $hash2->{$key} ) {
			return undef;
		}
	}
	return 1;
}
