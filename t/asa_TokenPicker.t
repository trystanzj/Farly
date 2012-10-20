use strict;
use warnings;

use Test::Simple tests => 2;

use Log::Log4perl qw(:easy);
Log::Log4perl->easy_init($ERROR);

use Farly;
use Farly::ASA::Builder;
use Farly::ASA::Parser;
use Farly::ASA::Annotator;
use Farly::ASA::TokenPicker;

my $parser    = Farly::ASA::Parser->new();
my $annotator = Farly::ASA::Annotator->new();

my $picker = Farly::ASA::TokenPicker->new();

ok( $picker->isa('Farly::ASA::TokenPicker'), "constructor" );

my $string = "access-list acl-outside line 1 extended permit tcp any range 1024 65535 OG_NETWORK citrix range 1 1024";
my $rule = $parser->parse($string);
$annotator->visit($rule);

$picker->visit($rule);

my $container = $picker->container();

my $DST = Object::KVC::HashRef->new();
$DST->set( "ENTRY", Object::KVC::String->new("GROUP") );
$DST->set( "ID", Object::KVC::String->new("citrix") );

my $expected = Object::KVC::Hash->new();

$expected->set("ID", Object::KVC::String->new("acl-outside") );
$expected->set("DST_IP", $DST );
$expected->set("PROTOCOL", Farly::Transport::Protocol->new("6") );
$expected->set("TYPE", Object::KVC::String->new("extended") );
$expected->set("SRC_PORT", Farly::Transport::PortRange->new("1024 65535") );
$expected->set("DST_PORT", Farly::Transport::PortRange->new("1 1024") );
$expected->set("ACTION", Object::KVC::String->new("permit") );
$expected->set("ENTRY", Object::KVC::String->new("RULE") );
$expected->set("SRC_IP", Farly::IPv4::Network->new("0.0.0.0 0.0.0.0") );
$expected->set("LINE", Object::KVC::Integer->new("1") );

ok( $container->[0]->equals($expected), "equals");