use strict;
use warnings;

use Test::More qw( no_plan );
use Data::Denter;
use Data::Dumper;

use Depends;
use Depends::Var;

require 't/common.pl';
require 't/depends.pl';

our $verbose = 0;

our ( $deplist, $targets, $deps );

#---------------------------------------------------

eval {
  cleanup();
  touch( 'data/targ1', 'data/dep1', 'data/dep2' );
  mkfile( 'data/sig1', 'contents' );
  my $sig = Depends::Sig::mkSig( 'data/sig1' );

  ( $deplist, $targets, $deps ) =
    submit ( 
      -target => 
	[ 
	  -sfile => 'data/sfile',  
	  '-slink=data/targ1' => 'data/slink',
	  'data/targ1',
	  ],
      -time => [ 'data/dep1',  'data/dep2' ],
      -var => [ -case => -foobar => 'va2lue' ],
      -sig => 'data/sig1',
      );
};
print STDERR $@ if $@ && $verbose;
ok ( !$@ &&
     eq_hash( $deps, {
		      'data/slink' => {
				       'var' => [],
				       'sig' => [],
				       'time' => []
				      },
		      'data/targ1' => {
				       'var' => [
						 'foobar'
						],
				       'sig' => [
						 'data/sig1'
						],
				       'time' => [
						  'data/dep1',
						  'data/dep2'
						 ]
				      },
		      'data/sfile' => {
				       'var' => [],
				       'sig' => [],
				       'time' => []
				      }
		     }) ,

	      'lots of stuff' );

#---------------------------------------------------

cleanup();
