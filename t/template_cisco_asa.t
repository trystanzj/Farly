use strict;

#use warnings;
use Log::Log4perl qw(:easy);
Log::Log4perl->easy_init($ERROR);

use Farly;
use Farly::ASA::Builder;
use Farly::Template::Cisco;
use Test::Simple tests => 2;

my $container = Object::KVC::List->new();

my $ce1 = Object::KVC::Hash->new();

$ce1->set( "REMOVE",         Object::KVC::String->new("OBJECT") );
$ce1->set( "ID",             Object::KVC::String->new("ms-rpc-locator") );
$ce1->set( "ENTRY",          Object::KVC::String->new("GROUP") );
$ce1->set( "GROUP_PROTOCOL", Object::KVC::String->new("tcp") );
$ce1->set( "OBJECT",         Farly::Transport::Port->new(445) );
$ce1->set( "GROUP_TYPE",     Object::KVC::String->new("service") );
$ce1->set( "OBJECT_TYPE",    Object::KVC::String->new("PORT") );

$container->add($ce1);

my $ce2 = Object::KVC::Hash->new();

my $obj_ref = Object::KVC::HashRef->new();
$obj_ref->set( "ENTRY", Object::KVC::String->new("GROUP") );
$obj_ref->set( "ID",    Object::KVC::String->new("test1") );

$ce2->set( "ID",          Object::KVC::String->new("ms-rpc-server") );
$ce2->set( "ENTRY",       Object::KVC::String->new("GROUP") );
$ce2->set( "OBJECT",      $obj_ref );
$ce2->set( "GROUP_TYPE",  Object::KVC::String->new("network") );
$ce2->set( "OBJECT_TYPE", Object::KVC::String->new("GROUP") );

$container->add($ce2);

my $ce3 = Object::KVC::Hash->new();

$ce3->set( "ID",          Object::KVC::String->new("ms-rpc-srv") );
$ce3->set( "ENTRY",       Object::KVC::String->new("GROUP") );
$ce3->set( "GROUP_TYPE",  Object::KVC::String->new("service") );
$ce3->set( "OBJECT_TYPE", Object::KVC::String->new("SERVICE") );
$ce3->set( "PROTOCOL",    Farly::Transport::Protocol->new(6) );
$ce3->set( "SRC_PORT",    Farly::Transport::PortRange->new("1024 65535") );
$ce3->set( "DST_PORT",    Farly::Transport::Port->new("80") );

$container->add($ce3);

my $ce4 = Object::KVC::Hash->new();

$ce4->set( "ID",          Object::KVC::String->new("INFO_ADDRESS") );
$ce4->set( "ENTRY",       Object::KVC::String->new("GROUP") );
$ce4->set( "GROUP_TYPE",  Object::KVC::String->new("service") );
$ce4->set( "OBJECT_TYPE", Object::KVC::String->new("SERVICE") );
$ce4->set( "PROTOCOL",    Farly::Transport::Protocol->new(1) );
$ce4->set( "ICMP_TYPE",   Object::KVC::String->new("17") );

$container->add($ce4);

my $ce5 = Object::KVC::Hash->new();

$ce5->set( "ENTRY",       Object::KVC::String->new("OBJECT") );
$ce5->set( "ID",          Object::KVC::String->new("test-srv2") );
$ce5->set( "OBJECT_TYPE", Object::KVC::String->new("HOST") );
$ce5->set( "OBJECT",      Farly::IPv4::Address->new("10.1.2.3") );

$container->add($ce5);

my $ce6 = Object::KVC::Hash->new();

$ce6->set( "ENTRY",       Object::KVC::String->new("OBJECT") );
$ce6->set( "ID",          Object::KVC::String->new("test-srv2") );
$ce6->set( "OBJECT_TYPE", Object::KVC::String->new("SERVICE") );
$ce6->set( "PROTOCOL",    Farly::Transport::Protocol->new(6) );
$ce6->set( "SRC_PORT",    Farly::Transport::PortRange->new("1024 65535") );
$ce6->set( "DST_PORT",    Farly::Transport::Port->new("80") );

$container->add($ce6);

my $ce7 = Object::KVC::Hash->new();

my $grp_ref = Object::KVC::HashRef->new();
$grp_ref->set( "ENTRY", Object::KVC::String->new("GROUP") );
$grp_ref->set( "ID",    Object::KVC::String->new("high-ports") );

$ce7->set( "ENTRY",        Object::KVC::String->new("RULE") );
$ce7->set( "ID",           Object::KVC::String->new("outside-in") );
$ce7->set( "LINE",         Object::KVC::String->new("1") );
$ce7->set( "ACTION",       Object::KVC::String->new("permit") );
$ce7->set( "PROTOCOL",     Farly::Transport::Protocol->new(6) );
$ce7->set( "SRC_IP",       Farly::IPv4::Network->new("0.0.0.0 0.0.0.0") );
$ce7->set( "SRC_PORT",     $grp_ref );
$ce7->set( "DST_IP",       Farly::IPv4::Address->new("192.168.1.1") );
$ce7->set( "DST_PORT",     Farly::Transport::Port->new("443") );
$ce7->set( "LOG_LEVEL",    Object::KVC::String->new("6") );
$ce7->set( "LOG_INTERVAL", Object::KVC::String->new("600") );
$ce7->set( "STATUS",       Object::KVC::String->new("inactive") );

$container->add($ce7);

my $ce8 = Object::KVC::Hash->new();

$ce8->set( "ENTRY",    Object::KVC::String->new("INTERFACE") );
$ce8->set( "NAME",     Object::KVC::String->new("Vlan10") );
$ce8->set( "ID",       Object::KVC::String->new("outside") );
$ce8->set( "SECURITY_LEVEL",   Object::KVC::String->new("0") );
$ce8->set( "OBJECT",       Farly::IPv4::Address->new("10.2.19.8") );
$ce8->set( "MASK",       Farly::IPv4::Address->new("255.255.255.0") );
$ce8->set( "STANDBY_IP",       Farly::IPv4::Address->new("10.2.19.9") );

$container->add($ce8);

my $ce9 = Object::KVC::Hash->new();

my $rule_ref = Object::KVC::HashRef->new();
$rule_ref->set( "ENTRY", Object::KVC::String->new("RULE") );
$rule_ref->set( "ID",    Object::KVC::String->new("outside-in") );

my $if_ref = Object::KVC::HashRef->new();
$if_ref->set( "ENTRY", Object::KVC::String->new("INTERFACE") );
$if_ref->set( "ID",    Object::KVC::String->new("outside") );

$ce9->set( "ENTRY",     Object::KVC::String->new("ACCESS_GROUP") );
$ce9->set( "ID",        $rule_ref );
$ce9->set( "DIRECTION", Object::KVC::String->new("in") );
$ce9->set( "INTERFACE", $if_ref );

$container->add($ce9);

my $ce10 = Object::KVC::Hash->new();

$ce10->set( "REMOVE",         Object::KVC::String->new("OBJECT") );
$ce10->set( "ENTRY",       Object::KVC::String->new("OBJECT") );
$ce10->set( "ID",          Object::KVC::String->new("test-srv2") );
$ce10->set( "OBJECT_TYPE", Object::KVC::String->new("SERVICE") );
$ce10->set( "PROTOCOL",    Farly::Transport::Protocol->new(6) );
$ce10->set( "SRC_PORT",    Farly::Transport::PortRange->new("1024 65535") );
$ce10->set( "DST_PORT",    Farly::Transport::Port->new("80") );

$container->add($ce10);

my $ce11 = Object::KVC::Hash->new();

$grp_ref = Object::KVC::HashRef->new();
$grp_ref->set( "ENTRY", Object::KVC::String->new("GROUP") );
$grp_ref->set( "ID",    Object::KVC::String->new("high-ports") );

$ce11->set( "REMOVE",       Object::KVC::String->new("RULE") );
$ce11->set( "ENTRY",        Object::KVC::String->new("RULE") );
$ce11->set( "ID",           Object::KVC::String->new("outside-in") );
$ce11->set( "ACTION",       Object::KVC::String->new("permit") );
$ce11->set( "PROTOCOL",     Farly::Transport::Protocol->new(6) );
$ce11->set( "SRC_IP",       Farly::IPv4::Network->new("0.0.0.0 0.0.0.0") );
$ce11->set( "SRC_PORT",     $grp_ref );
$ce11->set( "DST_IP",       Farly::IPv4::Address->new("192.168.1.1") );
$ce11->set( "DST_PORT",     Farly::Transport::Port->new("443") );
$ce11->set( "LOG_LEVEL",    Object::KVC::String->new("6") );
$ce11->set( "LOG_INTERVAL", Object::KVC::String->new("600") );
$ce11->set( "STATUS",       Object::KVC::String->new("inactive") );

$container->add($ce11);

my $ce12 = Object::KVC::Hash->new();

$ce12->set( "REMOVE",         Object::KVC::String->new("GROUP") );
$ce12->set( "ID",             Object::KVC::String->new("ms-rpc-locator") );
$ce12->set( "ENTRY",          Object::KVC::String->new("GROUP") );
$ce12->set( "GROUP_PROTOCOL", Object::KVC::String->new("tcp") );
$ce12->set( "OBJECT",         Farly::Transport::Port->new(445) );
$ce12->set( "GROUP_TYPE",     Object::KVC::String->new("service") );
$ce12->set( "OBJECT_TYPE",    Object::KVC::String->new("PORT") );

$container->add($ce12);

my $ce13 = Object::KVC::Hash->new();

$ce13->set( "ENTRY",        Object::KVC::String->new("RULE") );
$ce13->set( "ID",           Object::KVC::String->new("outside-in") );
$ce13->set( "LINE",         Object::KVC::String->new("1") );
$ce13->set( "ACTION",       Object::KVC::String->new("permit") );
$ce13->set( "PROTOCOL",     Farly::Transport::Protocol->new(6) );
$ce13->set( "SRC_IP",       Farly::IPv4::Network->new("0.0.0.0 0.0.0.0") );
$ce13->set( "SRC_PORT",     Farly::Transport::PortGT->new("1024") );
$ce13->set( "DST_IP",       Farly::IPv4::Address->new("192.168.1.1") );
$ce13->set( "DST_PORT",     Farly::Transport::Port->new("443") );
$ce13->set( "LOG_LEVEL",    Object::KVC::String->new("6") );
$ce13->set( "LOG_INTERVAL", Object::KVC::String->new("600") );
$ce13->set( "STATUS",       Object::KVC::String->new("inactive") );

$container->add($ce13);

my $ce14 = Object::KVC::Hash->new();

$ce14->set( "ENTRY",        Object::KVC::String->new("RULE") );
$ce14->set( "ID",           Object::KVC::String->new("outside-in") );
$ce14->set( "LINE",         Object::KVC::String->new("1") );
$ce14->set( "ACTION",       Object::KVC::String->new("permit") );
$ce14->set( "PROTOCOL",     Farly::Transport::Protocol->new(6) );
$ce14->set( "SRC_IP",       Farly::IPv4::Network->new("0.0.0.0 0.0.0.0") );
$ce14->set( "SRC_PORT",     Farly::Transport::PortGT->new("1024") );
$ce14->set( "DST_IP",       Farly::IPv4::Address->new("192.168.1.1") );
$ce14->set( "DST_PORT",     Farly::Transport::PortLT->new("443") );
$ce14->set( "LOG_LEVEL",    Object::KVC::String->new("6") );
$ce14->set( "LOG_INTERVAL", Object::KVC::String->new("600") );
$ce14->set( "STATUS",       Object::KVC::String->new("inactive") );

$container->add($ce14);

my $if_ref_inside = Object::KVC::HashRef->new();
$if_ref_inside->set( "ENTRY", Object::KVC::String->new("INTERFACE") );
$if_ref_inside->set( "ID",    Object::KVC::String->new("inside") );

my $ce15 = Object::KVC::Hash->new();
$ce15->set( "ENTRY",        Object::KVC::String->new("ROUTE") );
$ce15->set( "INTERFACE",    $if_ref_inside );
$ce15->set( "DESTINATION",  Farly::IPv4::Network->new('192.168.0.1 255.255.255.0'));
$ce15->set( "NEXTHOP",      Farly::IPv4::Address->new('192.168.1.1'));
$ce15->set( "COST",         Object::KVC::Integer->new("1") );
$ce15->set( "TRACK",        Object::KVC::Integer->new("20") );

$container->add($ce15);

my $ce16 = Object::KVC::Hash->new();
$ce16->set( "ENTRY",        Object::KVC::String->new("ROUTE") );
$ce16->set( "INTERFACE",    $if_ref_inside );
$ce16->set( "DESTINATION",  Farly::IPv4::Network->new('0.0.0.0 0.0.0.0'));
$ce16->set( "NEXTHOP",      Farly::IPv4::Address->new('192.168.0.1'));
$ce16->set( "COST",         Object::KVC::Integer->new("2") );
$ce15->set( "TUNNELED",     Object::KVC::String->new("tunneled") );

$container->add($ce16);

my $string = '';
my $template = Farly::Template::Cisco->new( 'ASA', 'OUTPUT' => \$string );

foreach my $ce ( $container->iter() ) {
	$template->as_string($ce);
	$string .= "\n";
}

my $expected = q{object-group service ms-rpc-locator tcp
no port-object eq 445
object-group network ms-rpc-server
 group-object test1
object-group service ms-rpc-srv
 service-object 6 source range 1024 65535 destination eq 80
object-group service INFO_ADDRESS
 service-object 1 17
object network test-srv2
 host 10.1.2.3
object service test-srv2
 service 6 source range 1024 65535 destination eq 80
access-list outside-in line 1 permit 6 any object-group high-ports host 192.168.1.1 eq 443 log interval 600 inactive
interface Vlan10
 nameif outside
 security-level 0
 ip address 10.2.19.8 255.255.255.0 standby 10.2.19.9
access-group outside-in in interface outside
no object service test-srv2
no access-list outside-in permit 6 any object-group high-ports host 192.168.1.1 eq 443 log interval 600 inactive
no object-group service ms-rpc-locator tcp
access-list outside-in line 1 permit 6 any gt 1024 host 192.168.1.1 eq 443 log interval 600 inactive
access-list outside-in line 1 permit 6 any gt 1024 host 192.168.1.1 lt 443 log interval 600 inactive
route inside 192.168.0.0 255.255.255.0 192.168.1.1 1 track 20 tunneled
route inside 0.0.0.0 0.0.0.0 192.168.0.1 2
};

ok( $string eq $expected, "template - no formatting" );

$string = '';
$template = Farly::Template::Cisco->new( 'ASA', 'OUTPUT' => \$string );

my $f = {
	'port_formatter'     => Farly::ASA::PortFormatter->new(),
	'protocol_formatter' => Farly::ASA::ProtocolFormatter->new(),
	'icmp_formatter'     => Farly::ASA::ICMPFormatter->new(),
};

$template->use_text(1);
$template->set_formatters($f);

foreach my $ce ( $container->iter() ) {
	$template->as_string($ce);
	$string .= "\n";
}

$expected = q{object-group service ms-rpc-locator tcp
no port-object eq 445
object-group network ms-rpc-server
 group-object test1
object-group service ms-rpc-srv
 service-object tcp source range 1024 65535 destination eq www
object-group service INFO_ADDRESS
 service-object icmp mask-request
object network test-srv2
 host 10.1.2.3
object service test-srv2
 service tcp source range 1024 65535 destination eq www
access-list outside-in line 1 permit tcp any object-group high-ports host 192.168.1.1 eq https log interval 600 inactive
interface Vlan10
 nameif outside
 security-level 0
 ip address 10.2.19.8 255.255.255.0 standby 10.2.19.9
access-group outside-in in interface outside
no object service test-srv2
no access-list outside-in permit tcp any object-group high-ports host 192.168.1.1 eq https log interval 600 inactive
no object-group service ms-rpc-locator tcp
access-list outside-in line 1 permit tcp any gt 1024 host 192.168.1.1 eq https log interval 600 inactive
access-list outside-in line 1 permit tcp any gt 1024 host 192.168.1.1 lt https log interval 600 inactive
route inside 192.168.0.0 255.255.255.0 192.168.1.1 1 track 20 tunneled
route inside 0.0.0.0 0.0.0.0 192.168.0.1 2
};

ok( $string eq $expected, "template - formatted" );
