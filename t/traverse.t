use strict;
use warnings;

use Test::More qw( no_plan);
use Data::Denter;

our $verbose = 0;
our $create = 1;

use Depends;

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

cleanup();

if ( $create )
{
  delete $deplist->{Attr};
  delete $targets->{Attr};
  delete $Depends::State->{Attr};
  open( DATA, ">data/traverse" ) or die( "unable to create data/traverse\n" );
  print DATA Indent($deplist, $targets, $Depends::State);
  close( DATA );
}

my ( $c_deplist, $c_targets, $c_state );
{
  local $/ = undef;
  open( DATA, "data/traverse" ) 
    or die( "unable to open data/traverse\n" );
  ( $c_deplist, $c_targets, $c_state ) = Undent( <DATA> );
  close( DATA );

}

# must rid ourselves of those pesky attributes, as it makes
# debugging things tough
delete $deplist->{Attr};
delete $targets->{Attr};
delete $Depends::State->{Attr};

ok( eq_hash( $c_deplist, $deplist ), "Dependency list" );
ok( eq_array( $c_targets, $targets ), "Targets" );
ok( eq_hash( $c_state, $Depends::State ), "State" );

#---------------------------------------------------

cleanup();

#---------------------------------------------------
sub submit
{
  my ( @specs ) = @_;

  Depends::init( undef, { Verbose => $verbose } );

  my @res = Depends::build_spec_list( undef, undef, \@specs );
  my ( $deplist, $targets ) = Depends::traverse_spec_list( @res );
}


