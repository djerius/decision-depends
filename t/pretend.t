use strict;
use warnings;

use Test::More qw( no_plan );

use Depends;
use Depends::Var;

require 't/common.pl';
require 't/depends.pl';

our $verbose = 0;

our ( $deplist, $targets, $deps );

# try some failures first

#---------------------------------------------------

# time dependency, target doesn't exist
eval {
  cleanup();
  touch( 'data/dep1' );
  ( $deplist, $targets, $deps ) = 
    submit( { Pretend => 1 },
	-target => 'data/targ1',
	 -depend => 'data/dep1' );
};
print STDERR $@ if $@ && $verbose;
ok ( !$@ && 
     eq_hash( $deps, { 'data/targ1' => {
					var    => [],
					time   => [],
					sig    => [] } } 
	    ),
     'time dependency, non-existant target' );

Depends::update($deplist, $targets );
ok( defined $Depends::State->getTime('data/targ1'),
	"update pretend time" );

#---------------------------------------------------

cleanup();
