use strict;
use warnings;

use Test::More;
plan( tests => 13 );

use Depends;
use Depends::Var;

require 't/common.pl';
require 't/depends.pl';

our $verbose = 0;
our $error = 0;

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
	    sub { $Depends::self->{State}->setVar( 'data/targ1', foo => 'val' ) }
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
	    sub { $Depends::self->{State}->setVar( 'data/targ1', foo => 'val2' ) }
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

# variable dependency, var with same value.
eval {
  cleanup();
  touch( 'data/targ1' );
  ( $deplist, $targets, $deps ) = 
    submit( -target => 'data/targ1',
	    -force => -depend => -var => ( -foo => 'val' ),
	    sub { $Depends::self->{State}->setVar( 'data/targ1', foo => 'val' ) }
	    );
};
print STDERR $@ if $@ && $verbose;
ok ( !$@ &&
     eq_hash( $deps, { 'data/targ1' => {
					var    => [ 'foo' ],
					time   => [],
					sig    => [] } } 
	    ),
     'local force variable dependency' );

#---------------------------------------------------

# variable dependency, var with same value.
eval {
  cleanup();
  touch( 'data/targ1' );
  ( $deplist, $targets, $deps ) = 
    submit( { Force => 1 },
            -target => 'data/targ1',
	    -depend => -var => ( -foo => 'val' ),
	    sub { $Depends::self->{State}->setVar( 'data/targ1', foo => 'val' ) }
	    );
};
print STDERR $@ if $@ && $verbose;
ok ( !$@ &&
     eq_hash( $deps, { 'data/targ1' => {
					var    => [ 'foo' ],
					time   => [],
					sig    => [] } } 
	    ),
     'global force variable dependency' );

#---------------------------------------------------

# variable dependency, guess numeric variable

eval {
  cleanup();
  Depends::Configure( { Verbose => $verbose, File => 'data/deps' } );

  my $val = '0.1470';

  $error = 1;
  if_dep { -slink => 'data/targ1', -var => -val => $val }
  action {
    $error = 0;
  };
};
print STDERR $@ if $@ && $verbose;
ok ( ! $error && !$@,  'setup guessed numerical variable deps' );

eval {
  my $val = 0.147;
  if_dep { -slink => 'data/targ1', -var => -val => $val }
  action {
    die( "shouldn't get here!\n" );
  };
};
print STDERR $@ if $@ && $verbose;
ok ( !$@,  'guessed numerical values' );


#---------------------------------------------------

# variable dependency, force numeric variable

eval {
  cleanup();
  Depends::Configure( { Verbose => $verbose, File => 'data/deps1' } );

  my $val = '0.1470';

  $error = 1;
  if_dep { -slink => 'data/targ1', -var => -numcmp => -val => $val }
  action {
    $error = 0;
  };
};
print STDERR $@ if $@ && $verbose;
ok ( ! $error && !$@,  'setup forced numerical variable deps' );

eval {
  my $val = 0.147;
  if_dep { -slink => 'data/targ1', -var => -numcmp => -val => $val }
  action {
    die( "shouldn't get here!\n" );
  };
};
print STDERR $@ if $@ && $verbose;
ok ( !$@,  'forced numerical values' );

eval {
  my $val = 0.147;
  $error = 1;
  if_dep { -slink => 'data/targ1', -var => -strcmp => -val => $val }
  action {
    $error = 0;
  };
};
print STDERR $@ if $@ && $verbose;
ok ( !$@,  'forced string compare of num values' );

#---------------------------------------------------

# variable dependency, force string compare

eval {
  cleanup();
  Depends::Configure( { Verbose => $verbose, File => 'data/deps1' } );

  my $val = 'snake';

  $error = 1;
  if_dep { -slink => 'data/targ1', -var => -val => $val }
  action {
    $error = 0;
  };
};
print STDERR $@ if $@ && $verbose;
ok ( ! $error && !$@,  'setup forced string variable deps' );

eval {
  my $val = 'snake';
  if_dep { -slink => 'data/targ1', -var => -strcmp => -val => $val }
  action {
    die( "shouldn't get here!\n" );
  };
};
print STDERR $@ if $@ && $verbose;
ok ( !$@,  'forced numerical values' );

eval {
  my $val = 0.147;
  $error = 1;
  if_dep { -slink => 'data/targ1', -var => -strcmp => -val => $val }
  action {
    $error = 0;
  };
};
print STDERR $@ if $@ && $verbose;
ok ( !$error && !$@,  'forced string compare of num values' );

#---------------------------------------------------

cleanup();
