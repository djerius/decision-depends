use strict;
use warnings;

use Test::More tests => 3;

use Decision::Depends;
use Decision::Depends::Var;

require 't/common.pl';
require 't/depends.pl';

our $verbose = 0;

our ( $deplist, $targets, $deps );

#---------------------------------------------------

eval {
  cleanup();
  touch( 'data/targ1', 'data/dep1', 'data/dep2' );
  mkfile( 'data/sig1', 'contents' );
  my $sig = Decision::Depends::Sig::mkSig( 'data/sig1' );

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

# ensure that we're reading in the dependency file correctly
my $cnt = 0;
eval {
  cleanup();

  $Decision::Depends::self->{State}->EraseState;
  Decision::Depends::Configure( { File => 'data/deps' } );

  if_dep { 'data/targ1', -var => ( -foo => 'val' ) }
  action {
    touch( 'data/targ1' );
  };

  $Decision::Depends::self->{State}->EraseState;
  Decision::Depends::Configure( { File => 'data/deps' } );

  if_dep { 'data/targ1', -var => ( -foo => 'val' ) }
  action {
    $cnt++;
  };

};
print STDERR $@ if $@ && $verbose;
ok ( !$@ && $cnt == 0, 'dependency file reread correctly (1)' );

eval {
  $Decision::Depends::self->{State}->EraseState;
  Decision::Depends::Configure( { File => 'data/deps' } );

  if_dep { 'data/targ1', -var => ( -foo => 'val1' ) }
  action {
    $cnt++;
  };
};
ok ( !$@ && $cnt == 1, 'dependency file reread correctly (2)' );


#---------------------------------------------------

cleanup();
