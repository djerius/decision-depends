package Decision::Depends::Target;

require 5.005_62;
use strict;
use warnings;

use Carp;

our $VERSION = '0.01';

our %attr = ( target => 1,
	      targets => 1,
	      sfile => 1,
	      slink => 1,
	    );

sub new
{
  my $class = shift;
  $class = ref($class) || $class;

  my ( $state, $spec ) = @_;

  my $self = { %$spec, state => $state };

  $self->{Pretend} = $self->{state}{Attr}{Pretend};

  # ensure that no bogus attributes are set
  my @notok = grep { ! exists $attr{$_} } keys %{$self->{attr}};
  croak( __PACKAGE__,
      "->new: bad attributes for Target `$self->{val}': ",
	 join( ', ', @notok ) ) if @notok;

  bless $self, $class;
}


sub getTime
{
  my $self = shift;
  my $file = $self->{val};

  my @sb;
  my $time = 
    $self->{state}->getTime( $file )
      || ((@sb = stat( $file )) ? $sb[9] : undef);

  # cache the value
  $self->{state}->setTime( $file, $time )
    if defined $time;

  $time;
}

sub setTime
{
  my $self = shift;
  my @sb;
  my $file = $self->{val};

  my $time = $self->{Pretend} ?
                  time () : ((@sb = stat( $file )) ? $sb[9] : undef);

  croak( __PACKAGE__, 
	 "->setTime: couldn't get time for `$file'. does it exist?" )
    unless defined $time;

  $self->{state}->setTime( $file, $time );
}

sub update
{
  my ( $self ) = @_;

  my $file = $self->{val};
  my $attr = $self->{attr};

  # if it's an sfile or slink, create the file
  if ( exists $attr->{slink} )
  {
    $self->mkSFile;
    $self->{state}->attachSLink( $file, $attr->{slink} );
  }

  elsif ( exists $attr->{sfile} )
  {
    $self->mkSFile;
  }

  $self->setTime;
}

sub mkSFile
{
  my ( $self ) = @_;

  return if $self->{Pretend};

  my $file = $self->{val};

  unlink $file;
  open( FILE, ">$file" )
    or croak( __PACKAGE__, "->mkSFile: unable to create file `$file'" );
  close FILE;
}

sub file
{
  my $self = shift;

  $self->{val};
}

1;
