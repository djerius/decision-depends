use strict;
use warnings;

use Test::More qw( no_plan );

use Depends;
use Depends::Var;

require 't/common.pl';
require 't/depends.pl';

our $verbose = 0;

our ( $deplist, $targets, $deps );

#---------------------------------------------------

# variable dependency, no var.  this is ok.
eval {
  cleanup();
  touch( 'data/targ1' );
  ( $deplist, $targets, $deps ) = 
    submit( -target => 'data/targ1',
	    -depend => -var => ( -foo => 'data/dep1' ) );
};
print STDERR $@ if $@ && $verbose;
ok ( !$@ && 
     eq_hash( $deps, { 'data/targ1' => {
					var    => [ 'foo' ],
					time   => [],
					sig    => [] }} 
	    ), 'variable dependency, no variable' );

#---------------------------------------------------

# variable dependency, var with same value.
eval {
  cleanup();
  touch( 'data/targ1' );
  ( $deplist, $targets, $deps ) = 
    submit( -target => 'data/targ1',
	    -depend => -var => ( -foo => 'val' ),
	    sub { $Depends::State->setVar( 'data/targ1', foo => 'val' ) }
	    );
};
print STDERR $@ if $@ && $verbose;
ok ( !$@ &&
     eq_hash( $deps, { } ),
     'variable dependency, unchanged value' );

#---------------------------------------------------

# variable dependency, var with different value.
eval {
  cleanup();
  touch( 'data/targ1' );
  ( $deplist, $targets, $deps ) = 
    submit( -target => 'data/targ1',
	    -depend => -var => ( -foo => 'val' ),
	    sub { $Depends::State->setVar( 'data/targ1', foo => 'val2' ) }
	    );
};
print STDERR $@ if $@ && $verbose;
ok ( !$@ &&
     eq_hash( $deps, { 'data/targ1' => {
					var    => [ 'foo' ],
					time   => [],
					sig    => [] } } 
	    ),
     'variable dependency, different value' );

#---------------------------------------------------

cleanup();
