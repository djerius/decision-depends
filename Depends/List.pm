package Depends::List;

require 5.005_62;
use strict;
use warnings;

use Carp;

our $VERSION = '0.01';

use Depends::Time;
use Depends::Var;
use Depends::Sig;

# Preloaded methods go here.

sub new
{
  my $class = shift;
  $class = ref($class) || $class;

  my $self = bless {}, $class;

  $self->{state} = shift;
  $self->{Attr} = shift || { Verbose => 0 };

  $self->{list} = [];

  $self;
}

sub Verbose
{
  $_[0]->{Attr}{Verbose};
}

sub create
{
  my $self = shift;
  my $type = shift;

  $type = lc $type;

 ( my $class = __PACKAGE__) =~ s/\w+$/\u$type/;


  local $Carp::CarpLevel = $Carp::CarpLevel + 1;
  push @{$self->{list}}, $class->new( $self->{state}, @_ );

  print STDERR "Creating $class (", $self->{list}[-1]->pprint, ")\n"
    if $self->Verbose && $self->Verbose > 4;
}

sub ndeps
{
  @{shift->{list}};
}

sub depends
{
  my ( $self, $targets ) = @_;

  my $state = $self->{state};

  my %depends;
  local $Carp::CarpLevel = $Carp::CarpLevel + 1;

  for my $target ( @$targets )
  {
    print STDERR "  Target ", $target->file, "\n"
      if $state->Verbose;

    # keep track of changed dependencies
    my %deps = ( time => [],
		 var => [],
		 sig => [] );


    my $time = $target->getTime;

    unless( defined $time )
    {
      print STDERR $target->file, " doesn't exist\n" if $self->Verbose;

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

      $depends{$target->file} = \%deps if $ndeps;
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
__END__
# Below is stub documentation for your module. You better edit it!

=head1 NAME

Depends::Time - Perl extension for blah blah blah

=head1 SYNOPSIS

  use Depends::Time;
  blah blah blah

=head1 DESCRIPTION

Stub documentation for Depends::Time, created by h2xs. It looks like the
author of the extension was negligent enough to leave the stub
unedited.

Blah blah blah.

=head2 EXPORT

None by default.


=head1 AUTHOR

A. U. Thor, a.u.thor@a.galaxy.far.far.away

=head1 SEE ALSO

perl(1).

=cut
