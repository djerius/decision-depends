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

# the status file does not exist.
eval {
  cleanup();
  touch( 'data/dep1' );
  ( $deplist, $targets, $deps ) =
    submit( -sfile => 'data/targ1',
	    -depend => 'data/dep1',
	    );
};
print STDERR $@ if $@ && $verbose;
ok ( !$@ && 
     eq_hash( $deps, { 'data/targ1' => { 
					var    => [],
					time   => [],
					sig    => [] } 
		     } ),
    'non-existant status file' );

eval {
  Depends::update( $deplist, $targets );
};
print STDERR $@ if $@ && $verbose;
ok ( !$@ && -f 'data/targ1', 
     'sfile update of non-existant sfile' );

#---------------------------------------------------

# the status linked file does not exist.
eval {
  cleanup();
  touch( 'data/dep1' );
  ( $deplist, $targets, $deps ) =
    submit( '-slink=data/targ2' => 'data/targ1',
	    -depend => 'data/dep1',
	    );
};
print STDERR $@ if $@ && $verbose;
ok ( !$@ && 
     eq_hash( $deps, { 'data/targ1' => { 
					var    => [],
					time   => [],
					sig    => [] } 
		     } ),
     'non-existant status file' );

eval {
  Depends::update( $deplist, $targets );
};
print STDERR $@ if $@ && $verbose;
ok ( !$@ && -f 'data/targ1', 
     'slink update of non-existant sfile' );

eval {
  touch( 'data/targ2', 'data/targ3', 'data/targ1' );
  ( $deplist, $targets, $deps ) =
    submit( { NoInit => 1 },
	    -target => 'data/targ3',
	    -depend => 'data/targ2',
	    );
};
print STDERR $@ if $@ && $verbose;
ok ( !$@ && 
     eq_hash( $deps, { 'data/targ3' => {
					var    => [],
					time   => [ 'data/targ1' ],
					sig    => [] } }),
     "check against slink'ed target" );

#---------------------------------------------------

cleanup();


