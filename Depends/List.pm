package Decision::Depends::List;

require 5.005_62;
use strict;
use warnings;

use Carp;

our $VERSION = '0.01';

use Decision::Depends::Time;
use Decision::Depends::Var;
use Decision::Depends::Sig;

# Preloaded methods go here.

sub new
{
  my $class = shift;
  $class = ref($class) || $class;

  my $self = bless {}, $class;

  $self->{state} = shift;

  $self->{list} = [];

  $self;
}

sub Verbose
{
  $_[0]->{state}->Verbose;
}

sub add
{
  my ( $self, $obj ) = @_;

  push @{$self->{list}}, $obj;
}

sub ndeps
{
  @{shift->{list}};
}

sub depends
{
  my ( $self, $targets ) = @_;

  my %depends;
  local $Carp::CarpLevel = $Carp::CarpLevel + 1;

  for my $target ( @$targets )
  {
    print STDERR "  Target ", $target->file, "\n"
      if $self->Verbose;

    # keep track of changed dependencies
    my %deps = ( time => [],
		 var => [],
		 sig => [] );


    my $time = $target->getTime;

    unless( defined $time )
    {
      print STDERR "    target `", $target->file,
      "' doesn't exist\n" if $self->Verbose;

      $depends{$target->file} = \%deps;
    }
    else
    {
      for my $dep ( @{$self->{list}} )
      {
	my ( $type, $deps ) = $dep->depends( $target->file, $time );
	push @{$deps{$type}}, @$deps;
      }

      my $ndeps = 0;
      map { $ndeps += @{$deps{$_}} } qw( var time sig );

      # return list of dependencies.  if there are none, return
      # the empty hash if force is one
      $depends{$target->file} = \%deps
	if $ndeps or $target->force || $self->{state}->Force;
    }
  }

  \%depends;
}



sub update
{
  my ( $self, $targets ) = @_;

  local $Carp::CarpLevel = $Carp::CarpLevel + 1;

  for my $target ( @$targets )
  {
    print STDERR ("Updating target ", $target->file, "\n" )
      if $self->Verbose;

    $_->update( $target->file ) foreach @{$self->{list}};
  }
}

1;
