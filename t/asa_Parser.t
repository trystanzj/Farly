use strict;
use warnings;
use Data::Dumper;
use Storable;
use Test::More tests => 29;
use Log::Log4perl qw(:easy);
Log::Log4perl->easy_init($ERROR);
use Farly::ASA::Parser;

my $tree;
my $string;
my $actual;
my $expected;
my $review_results;
my $store_results;
my $results = retrieve('asa_parser.results');

#
# constructor
#

my $test = 1;

my $parser = Farly::ASA::Parser->new();

ok( defined($parser), "constructor" );

#
# hostname
#

$test++;

$string = q{hostname test_fw};

$tree = $parser->parse($string);

$expected = $results->{$test};

is_deeply( $expected, $tree, 'hostname' );

if ($review_results) {
	print "Test $test \nString :\n $string\n";
	print Dumper($tree);
	$results->{$test} = $tree;
}

#
# name
#

$test++;

$string = q{name 192.168.10.0 net1 description This is a test};

$tree = $parser->parse($string);

$expected = $results->{$test};

is_deeply( $expected, $tree, 'name' );

if ($review_results) {
	print "Test $test \nString :\n $string\n";
	print Dumper($tree);
	$results->{$test} = $tree;
}

#
# interface nameif
#

$test++;

$string = q{interface Vlan2
 nameif outside
};

$tree = $parser->parse($string);

$expected = $results->{$test};

is_deeply( $expected, $tree, 'interface nameif' );

if ($review_results) {
	print "Test $test \nString :\n $string\n";
	print Dumper($tree);
	$results->{$test} = $tree;
}

#
# interface ip
#

$test++;

$string = q{interface Vlan2
 ip address 10.2.19.8 255.255.255.248 standby 10.2.19.9
};

$tree = $parser->parse($string);

$expected = $results->{$test};

is_deeply( $expected, $tree, 'interface ip' );

if ($review_results) {
	print "Test $test \nString :\n $string\n";
	print Dumper($tree);
	$results->{$test} = $tree;
}

#
# interface security-level
#

$test++;

$string = q{interface Vlan2
 security-level 0
};

$tree = $parser->parse($string);

$expected = $results->{$test};

is_deeply( $expected, $tree, 'interface security-level' );

if ($review_results) {
	print "Test $test \nString :\n $string\n";
	print Dumper($tree);
	$results->{$test} = $tree;
}

#
# object host
#

$test++;

$tree = $parser->parse($string);

$expected = $results->{$test};

is_deeply( $expected, $tree, 'object host' );

if ($review_results) {
	print "Test $test \nString :\n $string\n";
	print Dumper($tree);
	$results->{$test} = $tree;
}

#
# object subnet
#

$test++;

$string = q{object network test_net1
 subnet 10.1.2.0 255.255.255.0
};

$tree = $parser->parse($string);

$expected = $results->{$test};

is_deeply( $expected, $tree, 'object subnet' );

if ($review_results) {
	print "Test $test \nString :\n $string\n";
	print Dumper($tree);
	$results->{$test} = $tree;
}

#
# object range
#

$test++;

$string = q{object network test_net1_range
 range 10.1.2.13 10.1.2.28
};

$tree = $parser->parse($string);

$expected = $results->{$test};

is_deeply( $expected, $tree, 'object range' );

if ($review_results) {
	print "Test $test \nString :\n $string\n";
	print Dumper($tree);
	$results->{$test} = $tree;
}

#
# object service src dst
#

$test++;

$string = q{object service web_https
 service tcp source gt 1024 destination eq 443
};

$tree = $parser->parse($string);

$expected = $results->{$test};

is_deeply( $expected, $tree, 'object service src dst' );

if ($review_results) {
	print "Test $test \nString :\n $string\n";
	print Dumper($tree);
	$results->{$test} = $tree;
}

#
# object-group service src
#

$test++;

$string = q{object-group service NFS
 service-object 6 source eq 2046
};

$tree = $parser->parse($string);

$expected = $results->{$test};

is_deeply( $expected, $tree, 'object-group service src' );

if ($review_results) {
	print "Test $test \nString :\n $string\n";
	print Dumper($tree);
	$results->{$test} = $tree;
}

#
# object-group protocol
#

$test++;

$string = q{object-group protocol test65
 protocol-object tcp
};

$tree = $parser->parse($string);

$expected = $results->{$test};

is_deeply( $expected, $tree, 'object-group protocol' );

if ($review_results) {
	print "Test $test \nString :\n $string\n";
	print Dumper($tree);
	$results->{$test} = $tree;
}

#
# network-object named host
#

$test++;

$string = q{object-group network test_net
 network-object host server1
};

$tree = $parser->parse($string);

$expected = $results->{$test};

is_deeply( $expected, $tree, 'network-object named host' );

if ($review_results) {
	print "Test $test \nString :\n $string\n";
	print Dumper($tree);
	$results->{$test} = $tree;
}

#
# port-object
#

$test++;

$string = q{object-group service web tcp
 port-object eq www
};

$tree = $parser->parse($string);

$expected = $results->{$test};

is_deeply( $expected, $tree, 'port-object' );

if ($review_results) {
	print "Test $test \nString :\n $string\n";
	print Dumper($tree);
	$results->{$test} = $tree;
}

#
# network group-object
#

$test++;

$string = q{object-group network test_net
 group-object server1
};

$tree = $parser->parse($string);

$expected = $results->{$test};

is_deeply( $expected, $tree, 'network group-object' );

if ($review_results) {
	print "Test $test \nString :\n $string\n";
	print Dumper($tree);
	$results->{$test} = $tree;
}

#
# object-group description
#

$test++;

$string = q{object-group network test_net
 description test network
};

$tree = $parser->parse($string);

$expected = $results->{$test};

is_deeply( $expected, $tree, 'object-group description' );

if ($review_results) {
	print "Test $test \nString :\n $string\n";
	print Dumper($tree);
	$results->{$test} = $tree;
}

#
# object-group service dst
#

$test++;

$string = q{object-group service NFS
 service-object 6 destination eq 2046
};

$tree = $parser->parse($string);

$expected = $results->{$test};

is_deeply( $expected, $tree, 'object-group service dst' );

if ($review_results) {
	print "Test $test \nString :\n $string\n";
	print Dumper($tree);
	$results->{$test} = $tree;
}

#
# object-group service
#

$test++;

$string = q{object-group service www tcp
 group-object web
};

$tree = $parser->parse($string);

$expected = $results->{$test};

is_deeply( $expected, $tree, 'object-group service' );

if ($review_results) {
	print "Test $test \nString :\n $string\n";
	print Dumper($tree);
	$results->{$test} = $tree;
}

#
# access-list 1
#

$test++;

$string =
q{access-list acl-outside permit tcp OG_NETWORK customerX range 1024 65535 host server1 eq 80};

$tree = $parser->parse($string);

$expected = $results->{$test};

is_deeply( $expected, $tree, 'access-list 1' );

if ($review_results) {
	print "Test $test \nString :\n $string\n";
	print Dumper($tree);
	$results->{$test} = $tree;
}

#
# access-list 2
#

$test++;

$string =
q{access-list acl-outside line 1 extended permit ip host server1 eq 1024 any eq 80};

$tree = $parser->parse($string);

$expected = $results->{$test};

is_deeply( $expected, $tree, 'access-list 2' );

if ($review_results) {
	print "Test $test \nString :\n $string\n";
	print Dumper($tree);
	$results->{$test} = $tree;
}

#
# access-list 3
#

$test++;

$string =
q{access-list acl-outside permit tcp OG_NETWORK customerX OG_SERVICE high_ports host server1 eq 80};

$tree = $parser->parse($string);

$expected = $results->{$test};

is_deeply( $expected, $tree, 'access-list 3' );

if ($review_results) {
	print "Test $test \nString :\n $string\n";
	print Dumper($tree);
	$results->{$test} = $tree;
}

#
# access-list 4
#

$test++;

$string =
q{access-list acl-outside permit OG_SERVICE srv2 OG_NETWORK customerX OG_SERVICE high_ports host server1 eq 80};

$tree = $parser->parse($string);

$expected = $results->{$test};

is_deeply( $expected, $tree, 'access-list 4' );

if ($review_results) {
	print "Test $test \nString :\n $string\n";
	print Dumper($tree);
	$results->{$test} = $tree;
}

#
# access-list 5
#

$test++;

$string =
  q{access-list acl-outside permit object citrix any OG_NETWORK citrix_servers};

$tree = $parser->parse($string);

$expected = $results->{$test};

is_deeply( $expected, $tree, 'access-list 5' );

if ($review_results) {
	print "Test $test \nString :\n $string\n";
	print Dumper($tree);
	$results->{$test} = $tree;
}

#
# access-list 6
#

$test++;

$string =
q{access-list acl-outside permit OG_SERVICE srv2 OG_NETWORK customerX OG_SERVICE high_ports net1 255.255.255.0 eq www};

$tree = $parser->parse($string);

$expected = $results->{$test};

is_deeply( $expected, $tree, 'access-list 6' );

if ($review_results) {
	print "Test $test \nString :\n $string\n";
	print Dumper($tree);
	$results->{$test} = $tree;
}

#
# access-list 7
#

$test++;

$string =
  q{access-list acl-outside permit ip any range 1024 65535 host server1 gt www};

$tree = $parser->parse($string);

$expected = $results->{$test};

is_deeply( $expected, $tree, 'access-list 7' );

if ($review_results) {
	print "Test $test \nString :\n $string\n";
	print Dumper($tree);
	$results->{$test} = $tree;
}

#
# access-list 8
#

$test++;

$string =
q{access-list acl-outside extended permit OG_PROTOCOL sip_transport OG_NETWORK voip_nets OG_SERVICE high_ports OG_NETWORK voip_srvs OG_SERVICE sip_ports};

$tree = $parser->parse($string);

$expected = $results->{$test};

is_deeply( $expected, $tree, 'access-list 8' );

if ($review_results) {
	print "Test $test \nString :\n $string\n";
	print Dumper($tree);
	$results->{$test} = $tree;
}

#
# access-list object service
#

$test++;

$string =
q{access-list acl-outside line 1 extended permit object citrix object internal_net object citrix_net};

$tree = $parser->parse($string);

$expected = $results->{$test};

is_deeply( $expected, $tree, 'access-list object service' );

if ($review_results) {
	print "Test $test \nString :\n $string\n";
	print Dumper($tree);
	$results->{$test} = $tree;
}

#
# access-list icmp-type
#

$test++;

$string =
q{access-list acl-outside line 1 extended permit icmp any any OG_ICMP-TYPE safe-icmp};

$tree = $parser->parse($string);

$expected = $results->{$test};

is_deeply( $expected, $tree, 'access-list icmp-type' );

if ($review_results) {
	print "Test $test \nString :\n $string\n";
	print Dumper($tree);
	$results->{$test} = $tree;
}

#
# access-group
#

$test++;

$string = q{access-group acl-outside in interface outside};

$tree = $parser->parse($string);

$expected = $results->{$test};

is_deeply( $expected, $tree, 'access-group' );

if ($review_results) {
	print "Test $test \nString :\n $string\n";
	print Dumper($tree);
	$results->{$test} = $tree;
}

#
# Finished tests
#

if ( $store_results ) {
	print Dumper($results);
	store $results, 'asa_parser.results';
	exit;
}
