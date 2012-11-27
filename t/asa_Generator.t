use strict;
use warnings;
use Storable;
use Test::More tests => 1;
#use Data::Dumper;
use Log::Log4perl qw(:easy);
use Farly;
use Farly::ASA::Generator;

Log::Log4perl->easy_init($ERROR);

my $generator = Farly::ASA::Generator->new();

my $ast = retrieve('expected.ast');

$generator->visit($ast);

#print $generator->container->[0]->dump;

my $dst = Object::KVC::HashRef->new();
$dst->set('ENTRY' => Object::KVC::String->new('GROUP') );
$dst->set('ID' => Object::KVC::String->new('citrix') );

my $expected = Object::KVC::Hash->new();

$expected->set('ACTION',  Object::KVC::String->new('permit'));
$expected->set('DST_IP',  $dst ); 
$expected->set('DST_PORT',  Farly::Transport::PortRange->new('1 1024'));
$expected->set('ENTRY',  Object::KVC::String->new('RULE'));
$expected->set('ID',  Object::KVC::String->new('acl-outside'));
$expected->set('LINE',  Object::KVC::Integer->new(1) );
$expected->set('PROTOCOL',  Farly::Transport::Protocol->new('6'));
$expected->set('SRC_IP',  Farly::IPv4::Network->new('0.0.0.0 0.0.0.0'));
$expected->set('SRC_PORT',  Farly::Transport::PortRange->new('1024 65535'));
$expected->set('TYPE',  Object::KVC::String->new('extended'));

ok( $generator->container->[0]->equals( $expected), 'generator' );