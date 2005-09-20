use strict;
use warnings;

use Test::More;
plan(  tests => 5 );
use YAML qw( DumpFile LoadFile );

our $verbose = 0;
our $create = 0;

use Decision::Depends;

require 't/common.pl';

#---------------------------------------------------

# no targets
eval { submit ();};
ok( $@ && $@ =~ /no targets/i, 'no targets 1' );

#---------------------------------------------------

# valid dependency, but no target
touch( 'data/dep1' );
eval { submit ( -depend => 'data/dep1' );};
print STDERR $@ if $@ && $verbose;
ok( $@ && $@ =~ /no targets/i, 'no targets 2' );

#---------------------------------------------------

# should we require dependencies?
# cleanup();
# eval { submit ( 'data/targ1' );};
# ok( $@ && $@ =~ /no depend/i, 'no dependencies' );

#---------------------------------------------------

cleanup();
touch( 'data/dep1', 'data/dep2' );
my ( $deplist, $targets ) = 
  submit( 
	 -target => [ 'targ1',  'targ2' ],
	 -target => [ -sfile => 'targ3' ],
	 -target => [ '-slink=dep1' => 'targ4' ],
	 -depend => [ 'data/dep1',  'data/dep2' ],
	 -var => [ -case => -foobar => 'value' ],
	 -sig => 'frank',
	);

if ( $create )
{
  delete $deplist->{Attr};
  delete $targets->{Attr};
  delete $Decision::Depends::self->{State}{Attr};
  DumpFile( 'data/traverse', $deplist, $targets, $Decision::Depends::self->{State} );
}

my ( $c_deplist, $c_targets, $c_state ) = LoadFile( 'data/traverse' );

# must rid ourselves of those pesky attributes, as it makes
# debugging things tough
delete $deplist->{Attr};
delete $Decision::Depends::self->{State}{Attr};

ok( eq_hash( $c_deplist, $deplist ), "Dependency list" );
ok( eq_array( $c_targets, $targets ), "Targets" );
ok( eq_hash( $c_state, $Decision::Depends::self->{State} ), "State" );

#---------------------------------------------------

cleanup();

#---------------------------------------------------
sub submit
{
  my ( @specs ) = @_;

  Decision::Depends::Configure( { Verbose => $verbose } );

  my @res = $Decision::Depends::self->_build_spec_list( undef, undef, \@specs );
  my ( $deplist, $targets ) = $Decision::Depends::self->_traverse_spec_list( @res );
}


