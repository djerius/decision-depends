use strict;
use warnings;

use Test::More;
plan( tests => 6);

use Decision::Depends;
use Decision::Depends::Var;

require 't/common.pl';
require 't/depends.pl';

our $verbose = 0;

our ( $deplist, $targets, $deps );

#---------------------------------------------------

# non-existant signature file
eval {
  cleanup();
  touch( 'data/targ1' );
  ( $deplist, $targets, $deps ) =
    submit ( -target => 'data/targ1',
	     -sig    => 'data/sig1'
	     );
};
print STDERR $@ if $@ && $verbose;
ok( $@ && $@ =~ /non-existant signature/,
	 'non-existant signature file' );

#---------------------------------------------------

# no signature on file
eval {
  cleanup();
  mkfile( 'data/sig1', 'contents' );
  touch( 'data/targ1', 'data/sig1' );
  ( $deplist, $targets, $deps ) =
    submit ( -target => 'data/targ1',
	     -sig    => 'data/sig1'
	     );
};
print STDERR $@ if $@ && $verbose;
ok ( !$@ && 
     eq_hash( $deps, { 'data/targ1' => {
					var    => [],
					time   => [],
					sig    => [ 'data/sig1' ] }
		     } ),
     'no signature on file' );

#---------------------------------------------------

# same signature on file
eval {
  cleanup();
  mkfile( 'data/sig1', 'contents' );
  touch( 'data/targ1', 'data/sig1' );
  my $sig = Decision::Depends::Sig::mkSig( 'data/sig1' );

  ( $deplist, $targets, $deps ) =
    submit ( -target => 'data/targ1',
	     -sig    => 'data/sig1',
	     sub { $Decision::Depends::self->{State}->setSig( 'data/targ1', 'data/sig1',
					    $sig ) }
	     );

};
print STDERR $@ if $@ && $verbose;
ok ( !$@ && 
     eq_hash( $deps, { } ),
     'same signature on file' );

#---------------------------------------------------

# different signature on file
eval {
  cleanup();
  mkfile( 'data/sig1', 'contents' );
  touch( 'data/targ1', 'data/sig1' );
  my $sig = Decision::Depends::Sig::mkSig( 'data/sig1' );

  mkfile( 'data/sig1', 'contents2' );

  ( $deplist, $targets, $deps ) =
    submit ( -target => 'data/targ1',
	     -sig    => 'data/sig1',
	     sub { $Decision::Depends::self->{State}->setSig( 'data/targ1', 'data/sig1', 
					    $sig ) }
	     );

};
print STDERR $@ if $@ && $verbose;
ok ( !$@ && 
     eq_hash( $deps, { 'data/targ1' => { target => [],
					 var    => [],
					 time   => [],
					 sig    => [ 'data/sig1' ] }
		     } 
	    ),
     'different signature on file' );

#---------------------------------------------------

# force dependency
eval {
  cleanup();
  mkfile( 'data/sig1', 'contents' );
  touch( 'data/targ1', 'data/sig1' );
  my $sig = Decision::Depends::Sig::mkSig( 'data/sig1' );

  ( $deplist, $targets, $deps ) =
    submit ( -target => 'data/targ1',
	     -force => -sig    => 'data/sig1',
	     sub { $Decision::Depends::self->{State}->setSig( 'data/targ1', 'data/sig1',
					    $sig ) }
	     );

};
print STDERR $@ if $@ && $verbose;
ok ( !$@ && 
     eq_hash( $deps, { 'data/targ1' => { target => [],
					 var    => [],
					 time   => [],
					 sig    => [ 'data/sig1' ] }
		     } 
	    ),
     'local force signature dependency' );

#---------------------------------------------------

# force dependency
eval {
  cleanup();
  mkfile( 'data/sig1', 'contents' );
  touch( 'data/targ1', 'data/sig1' );
  my $sig = Decision::Depends::Sig::mkSig( 'data/sig1' );

  ( $deplist, $targets, $deps ) =
    submit ( { Force => 1 },
             -target => 'data/targ1',
	     -sig    => 'data/sig1',
	     sub { $Decision::Depends::self->{State}->setSig( 'data/targ1', 'data/sig1',
					    $sig ) }
	     );

};
print STDERR $@ if $@ && $verbose;
ok ( !$@ && 
     eq_hash( $deps, { 'data/targ1' => { target => [],
					 var    => [],
					 time   => [],
					 sig    => [ 'data/sig1' ] }
		     } 
	    ),
     'global force signature dependency' );

#---------------------------------------------------

cleanup();

