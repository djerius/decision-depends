use strict;
use warnings;

use Test::More;
plan( tests => 4 );

use Depends;
use Depends::Var;

require 't/common.pl';
require 't/depends.pl';

our $verbose = 1;

our ( %deps );

# try some failures first

#---------------------------------------------------

# the time dependency file does not exist.
eval {
  cleanup();
  touch('data/targ1');
  test_dep( -target => 'data/targ1', -depend => 'NOT_EXIST' );
};
ok( $@ && $@ =~ /non-existant.*NOT_EXIST/, 'non-existant time dependency' );

#---------------------------------------------------

# time dependency, target doesn't exist
eval {
  cleanup();
  touch( 'data/dep1' );
  %deps = test_dep( -target => 'data/targ1', -depend => 'data/dep1' );
};
print STDERR $@ if $@ && $verbose;
ok ( !$@ && 
     eq_hash( \%deps, { 'data/targ1' => { 
					var    => [],
					time   => [],
					sig    => [] } 
		     } 
	    ), 'time dependency, non-existant target' );

#---------------------------------------------------

# time dependency, multiple non-existant targets
eval {
  cleanup();
  touch( 'data/dep1' );
  %deps = test_dep( -target => [ 'data/targ1', 'data/targ2' ],
		    -depend => 'data/dep1' );
};
print STDERR $@ if $@ && $verbose;
ok ( !$@ && 
     eq_hash( \%deps, { 'data/targ1' => { var    => [],
					 time   => [],
					 sig    => [] },
		       'data/targ2' => { var    => [],
					 time   => [],
					 sig    => [] },
		      } ),
     'time dependency, multiple non-existant targets' );

#---------------------------------------------------

# time dependency, target exists
eval {
  cleanup();
  touch( 'data/targ1', 'data/dep1' );
  %deps = test_dep( -target => 'data/targ1', -depend => 'data/dep1' );
};
print STDERR $@ if $@ && $verbose;
ok ( !$@ && 
     eq_hash( \%deps, { 'data/targ1' => {
					var    => [],
					time   => [ 'data/dep1' ],
					sig    => [] } } 
	    ),
     'time dependency, target exists' );

#---------------------------------------------------

cleanup();
