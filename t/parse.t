use strict;
use warnings;

use Test::More tests => 1;

use Depends;
use Data::Denter;

our $create = 0;

my @specs = ( 
	     -target => [ -unalias => 'targ1',  -no_target => 'targ2' ],
	     -depend => -md5 => [ 'dep1',  '-slurp=' => 'dep2' ],
	     '-slurp=33' => 'frank',
	     -wave => -33,
	     -snooker => \-39
	 );

my @res = Depends::build_spec_list( undef, undef, \@specs );

if ( $create )
{
  open( DATA, ">data/parse" ) or die( "unable to create data/parse\n" );
  print DATA Indent(\@res);
  close( DATA );
}

my $c_res;

{
  local $/ = undef;
  open( DATA, "data/parse" ) 
    or die( "unable to open data/parse\n" );
  ( $c_res ) = Undent( <DATA> );
  close( DATA );
}

ok( eq_array( \@res, $c_res ), 'token parse' );
