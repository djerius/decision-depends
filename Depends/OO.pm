package Depends::OO;

require 5.005_62;
use strict;
use warnings;

require Exporter;

our $VERSION = '0.04';

use Carp;
use Depends::State;
use Depends::List;
use Depends::Target;

# regular expression for a floating point number
our $RE_Float = qr/^[+-]?(\d+[.]?\d*|[.]\d+)([dDeE][+-]?\d+)?$/;

sub new
{
  my $class = shift;
  $class = ref($class) || $class;

  my $self = { Attr => { Cache => 0,
			 DumpFiles => 0,
			 Pretend => 0,
			 Verbose => 0,
			 AutoSave => 1,
			 Force => 0,
			 File => undef
		       }
	     };
  bless $self, $class;

  $self->{State} = Depends::State->new();

  $self->configure( @_ );

  $self;
}

sub Verbose
{
  $_[0]->{State}->Verbose;
}

sub Pretend
{
  $_[0]->{State}->Pretend;
}

sub configure
{
  my $self = shift;

  return unless @_;

  my @opts = @_;
  my %attr;
  my ($key, $val);

  while ( @opts )
  {
    my $opt = shift @opts;

    if ( 'HASH' eq ref $opt )
    {
      my @notok = grep { ! exists $self->{Attr}{$_} } keys %$opt;
      croak( __PACKAGE__, '->configure: unknown attribute(s): ',
	     join( ', ', @notok) ) if @notok;
      $attr{$key} = $val while( ($key, $val) = each %$opt );
    }

    elsif ( 'ARRAY' eq ref $opt )
    {
      croak( __PACKAGE__, '->configure: odd number of elements in arrayref' )
	if @$opt %2;

      unshift @opts, @$opt;
    }

    else
    {
      croak( __PACKAGE__, 
	     '->configure: odd number of elements in options list' )
	unless @opts;

      croak( __PACKAGE__, "->configure: unknown attribute: `$opt'" )
	unless exists $self->{Attr}{$opt};

      $attr{$opt} = shift @opts;
    }

  }

  $self->{Attr}{$key} = $val while( ($key, $val) = each %attr );
  $self->{State}->SetAttr( \%attr );
}

sub if_dep
{
  my $self = shift;

  my ( $args, $run ) = @_;

  print STDERR "\nNew dependency\n" if $self->Verbose;

  my @specs = $self->_build_spec_list( undef, undef, $args );

  my ( $deplist, $targets ) = $self->_traverse_spec_list( @specs );

  my $depends = $self->_depends( $deplist, $targets );

  if ( keys %$depends )
  {
    # clean up beforehand in case of Pretend
    undef $@;
    print STDERR "Action required.\n" if $self->Verbose;
    eval { &$run( $depends) } unless $self->Pretend;
    if ( $@ )
    {
      croak $@ unless defined wantarray;
      return 0;
    }
    else
    {
      $self->_update( $deplist, $targets );
    }
  }
  else
  {
    print STDERR "No action required.\n" if $self->Verbose;
  }
  1;
}

sub test_dep
{
  my $self = shift;
  my ( @args ) = @_;

  print STDERR "\nNew dependency\n" if $self->Verbose;

  my @specs = $self->_build_spec_list( undef, undef, \@args );

  my ( $deplist, $targets ) = $self->_traverse_spec_list( @specs );

  my $depends = $self->_depends( $deplist, $targets );

  wantarray ? %$depends : keys %$depends;
}


# spec format is 

# -attr1 => -attr2 => value1, ...
# where value may be of the form 
#  [ -attr3 => -attr4 => value2 ]
#  attr1 and attr2 are attached to value2
# attributes may have values, 
#   '-attr=attr_value'
# by default the value is 1
# to undefine an attribute:
#  -no_attr
# additionally, each value is given an attribute "id" representing its
# position in the list (independent of attributes) and in any sublists. 
# id = [0], [0,0], [0,1,1], etc.

sub _build_spec_list
{
  my $self = shift;
  my ( $attrs, $levels, $specs ) = @_;

  $attrs = [ {} ] unless defined $attrs;
  $levels = [ -1 ] unless defined $levels;

  my @res;

  # process target attributes
  foreach my $spec ( @$specs )
  {
    my $ref = ref $spec;
    # if it's an attribute, process it
    if ( ! $ref && $spec !~ /$RE_Float/ && 
	 $spec =~ /^-(no_)?(\w+)(?:\s*=\s*(.*))?/ )
    {
      if ( defined $1 )
      {
	$attrs->[-1]{$2} = undef;
      }
      else
      {
	$attrs->[-1]{$2} = defined $3 ? $3 : 1;
      }
    }

    # maybe a nested level?
    elsif ( 'ARRAY' eq $ref )
    {
      push @$attrs, {};
      $levels->[-1]++;
      push @$levels, -1;
      push @res, $self->_build_spec_list( $attrs, $levels, $spec );
      pop @$attrs;
      pop @$levels;

      # reset attributes
      $attrs->[-1] = {};
    }

    # a value
    elsif ( 'SCALAR' eq $ref || ! $ref )
    {
      $spec = $$spec if $ref;

      $levels->[-1]++;
      my %attr;
      foreach my $lattr ( @$attrs )
      {
	my ( $key, $val );
	$attr{$key} = $val while ( ($key,$val) = each %$lattr );
      }
      delete @attr{ grep { ! defined $attr{$_} } keys %attr };
      push @res, { id => [ @$levels ], 
		   val => $spec , 
		   attr => \%attr };

      # reset attributes
      $attrs->[-1] = {};
    }

  }

  @res;
}


sub _traverse_spec_list
{
  my $self = shift;
  my @list = @_;

  local $Carp::CarpLevel = $Carp::CarpLevel + 1;

  # two phases; first the targets, then the dependencies.
  # the targets are identified as id 0.X

  my $deplist = Depends::List->new( $self->{State} );

  my @targets;

  eval {

    for my $spec ( @list )
    {
      if ( (grep { exists $spec->{attr}{$_} } qw( target targets sfile slink )) ||
	   (! exists $spec->{attr}{depend} && 0 == $spec->{id}[0] ) )
      {
	push @targets, Depends::Target->new( $self->{State}, $spec );
      }

      else
      {
	my @match = grep { defined $spec->{attr}{$_} } qw( sig var ) ;

	if ( @match > 1 )
	{
	  $Carp::CarpLevel--;
	  croak( __PACKAGE__, 
		 "::traverse_spec_list: too many classes for `$spec->{val}'" )
	}

	my $class = 'Depends::' .
	  ( @match ? ucfirst( $match[0]) : 'Time' );

	$deplist->add( $class->new( $self->{State}, $spec ) );
      }
    }
  };

  croak( $@ ) if $@;

  croak( __PACKAGE__, '::traverse_spec_list: no targets?' )
    unless @targets;

  # should we require dependencies?
  #  croak( __PACKAGE__, '::traverse_spec_list: no dependencies?' )
  #    unless $deplist->ndeps;

  ( $deplist, \@targets );
}

sub _depends
{
  my $self = shift;
  my ( $deplist, $targets ) = @_;

  local $Carp::CarpLevel = $Carp::CarpLevel + 1;
  $deplist->depends( $targets );
}

sub _update
{
  my $self = shift;
  my ( $deplist, $targets ) = @_;

  local $Carp::CarpLevel = $Carp::CarpLevel + 1;

  $deplist->update( $targets );

  $_->update foreach @$targets;
}

1;
