use strict;
use warnings;
use Test::More tests => 1;
use Log::Log4perl qw(:easy);
use Farly;
use Farly::ASA::Parser;
use Farly::ASA::Annotator;
use Farly::ASA::Rewriter;
 
Log::Log4perl->easy_init($ERROR);

my $abs_path = File::Spec->rel2abs( __FILE__ );
our ($volume,$dir,$file) = File::Spec->splitpath( $abs_path );
my $path = $volume.$dir;

my $parser = Farly::ASA::Parser->new();
my $annotator = Farly::ASA::Annotator->new();
my $rewriter = Farly::ASA::Rewriter->new();

my $string = q{access-list acl-outside line 1 extended permit tcp any range 1024 65535 OG_NETWORK citrix range 1 1024};

my $parse_tree = $parser->parse($string);

$annotator->visit($parse_tree);

my $ast = $rewriter->rewrite($parse_tree);

my $expected = bless( {
                 'ID' => bless( {
                                  '__VALUE__' => bless( do{\(my $o = 'acl-outside')}, 'Object::KVC::String' ),
                                  'LINE' => bless( {
                                                     '__VALUE__' => bless( do{\(my $o = '1')}, 'Object::KVC::Integer' ),
                                                     'TYPE' => bless( {
                                                                        '__VALUE__' => bless( do{\(my $o = 'extended')}, 'Object::KVC::String' ),
                                                                        'ACTION' => bless( {
                                                                                             '__VALUE__' => bless( do{\(my $o = 'permit')}, 'Object::KVC::String' ),
                                                                                             'PROTOCOL' => bless( {
                                                                                                                    '__VALUE__' => bless( do{\(my $o = '6')}, 'Farly::Transport::Protocol' ),
                                                                                                                    'SRC_IP' => bless( {
                                                                                                                                         '__VALUE__' => bless( {
                                                                                                                                                                 'NETWORK' => Farly::IPv4::Address->new("0.0.0.0"),
                                                                                                                                                                 'MASK' => Farly::IPv4::Address->new("0.0.0.0")
                                                                                                                                                               }, 'Farly::IPv4::Network' ),
                                                                                                                                         'SRC_PORT' => bless( {
                                                                                                                                                                '__VALUE__' => bless( {
                                                                                                                                                                                        'LOW' => bless( do{\(my $o = '1024')}, 'Farly::Transport::Port' ),
                                                                                                                                                                                        'HIGH' => bless( do{\(my $o = '65535')}, 'Farly::Transport::Port' )
                                                                                                                                                                                      }, 'Farly::Transport::PortRange' ),
                                                                                                                                                                'DST_IP' => bless( {
                                                                                                                                                                                     'DST_PORT' => bless( {
                                                                                                                                                                                                            '__VALUE__' => bless( {
                                                                                                                                                                                                                                    'LOW' => bless( do{\(my $o = '1')}, 'Farly::Transport::Port' ),
                                                                                                                                                                                                                                    'HIGH' => bless( do{\(my $o = '1024')}, 'Farly::Transport::Port' )
                                                                                                                                                                                                                                  }, 'Farly::Transport::PortRange' )
                                                                                                                                                                                                          }, 'DST_PORT' ),
                                                                                                                                                                                     '__VALUE__' => bless( {
                                                                                                                                                                                                             'ID' => bless( do{\(my $o = 'citrix')}, 'Object::KVC::String' ),
                                                                                                                                                                                                             'ENTRY' => bless( do{\(my $o = 'GROUP')}, 'Object::KVC::String' )
                                                                                                                                                                                                           }, 'Object::KVC::HashRef' )
                                                                                                                                                                                   }, 'DST_IP' )
                                                                                                                                                              }, 'SRC_PORT' )
                                                                                                                                       }, 'SRC_IP' )
                                                                                                                  }, 'PROTOCOL' )
                                                                                           }, 'ACTION' )
                                                                      }, 'TYPE' )
                                                   }, 'LINE' )
                                }, 'ID' )
               }, 'RULE' );

is_deeply($ast, $expected, "abstract syntax tree");

