use strict;
use warnings;
use Log::Log4perl qw(:easy);
Log::Log4perl->easy_init($ERROR);

use Farly;
use Farly::Opts::Search;
use Test::Simple tests => 6;
use File::Spec; 

my $abs_path = File::Spec->rel2abs( __FILE__ );
our ($volume,$dir,$file) = File::Spec->splitpath( $abs_path );
my $path = $volume.$dir;

my %opts;

my $id = 'outside-in';
my $action = 'permit';
my $protocol = 'tcp';
my $src_ip = '10.1.0.11';
my $dst_ip = '10.1.1.12';
my $src_port = 23547;
my $dst_port = 443;

$opts{'id'} = $id;
$opts{'action'} = $action;
$opts{'p'} = $protocol;
$opts{'s'} = $src_ip;
$opts{'d'} = $dst_ip;
$opts{'sport'} = $src_port;
$opts{'dport'} = $dst_port;

my $search_parser = Farly::Opts::Search->new( \%opts );
 
my $expected = Farly::Object->new();

$expected->set( 'ID', Farly::Value::String->new($id) );
$expected->set( 'ACTION', Farly::Value::String->new($action) );
$expected->set( 'PROTOCOL', Farly::Transport::Protocol->new(6) );
$expected->set( 'SRC_IP', Farly::IPv4::Address->new($src_ip) );
$expected->set( 'DST_IP', Farly::IPv4::Address->new($dst_ip) );
$expected->set( 'SRC_PORT', Farly::Transport::Port->new($src_port) );
$expected->set( 'DST_PORT', Farly::Transport::Port->new($dst_port) );

ok( $search_parser->search()->equals( $expected ), 'ip address' );

my $src_net = '10.1.2.0/24';
my $dst_net = '10.1.3.0/24';

$opts{'s'} = $src_net;
$opts{'d'} = $dst_net;

$search_parser = Farly::Opts::Search->new( \%opts );

$expected->set( 'SRC_IP', Farly::IPv4::Network->new($src_net) );
$expected->set( 'DST_IP', Farly::IPv4::Network->new($dst_net) );

ok( $search_parser->search()->equals( $expected ), 'ip net' );

$opts{'exclude-dst'} = "$path/filter.txt";

my $filter_set = Farly::Object::Set->new();

my $filter1 = Farly::Object->new();
$filter1->set('DST_IP', Farly::IPv4::Network->new('10.1.2.0 255.255.255.0') );
my $filter2 = Farly::Object->new();
$filter2->set('DST_IP', Farly::IPv4::Network->new('10.2.2.0 255.255.255.0') );

$filter_set->add($filter1);
$filter_set->add($filter2);

$search_parser = Farly::Opts::Search->new( \%opts );

ok( $search_parser->filter()->equals( $filter_set ), 'filter dst');


delete $opts{'exclude-dst'};

$opts{'exclude-src'} = "$path/filter.txt";

$filter_set = Farly::Object::Set->new();

my $filter3 = Farly::Object->new();
$filter3->set('SRC_IP', Farly::IPv4::Network->new('10.1.2.0 255.255.255.0') );
my $filter4 = Farly::Object->new();
$filter4->set('SRC_IP', Farly::IPv4::Network->new('10.2.2.0 255.255.255.0') );

$filter_set->add($filter3);
$filter_set->add($filter4);

$search_parser = Farly::Opts::Search->new( \%opts );

ok( $search_parser->filter()->equals( $filter_set ), 'filter src');

$opts{'exclude-src'} = "$path/filter2.txt";

eval {
	$search_parser = Farly::Opts::Search->new( \%opts );
};

ok ( $@ =~ /not a valid file/, 'invalid filter file' );

$opts{'s'} = '';

eval {
	$search_parser = Farly::Opts::Search->new( \%opts );
};

ok ( $@ =~ /Invalid IP/, 'invalid ip' );
