package Decision::Depends::Sig;

require 5.005_62;
use strict;
use warnings;

use Carp;
use Digest::MD5;

our $VERSION = '0.01';

our %attr = ( depend => 1,
	      depends => 1,
	      force => 1,
	      sig => 1 );

sub new
{
  my $class = shift;
  $class = ref($class) || $class;

  my ( $state, $spec ) = @_;

  my $self = { %$spec, state => $state };

  # ensure that no bogus attributes are set
  my @notok = grep { ! exists $attr{$_} } keys %{$self->{attr}};
  croak( __PACKAGE__, 
      "->new: bad attributes for Signature dependency `$self->{val}': ",
	 join( ', ', @notok ) ) if @notok;

  bless $self, $class;
}

sub depends
{
  my ( $self, $target, $time ) = @_;

  my $state = $self->{state};

  croak( __PACKAGE__, 
	 "->depends: non-existant signature file `$self->{val}'" )
    unless -f $self->{val};

  my @deps = ();

  my $prev_val = $state->getSig( $target, $self->{val} );

  if ( defined $prev_val )
  {
    my $is_not_equal = 
      ( exists $self->{attr}{force} ?  
	$self->{attr}{force} : $state->Force ) ||
	cmpSig( $prev_val, mkSig( $self->{val} ) );

    if ( $is_not_equal )
    {
      print STDOUT "    signature file `", $self->{val}, "' has changed\n"
	if $state->Verbose;
      push @deps, $self->{val};
    }
    else
    {
      print STDOUT "    signature file `", $self->{val}, "' is unchanged\n"
	if $state->Verbose;
    }

  }
  else
  {
    print STDOUT "    No signature on file for `", $self->{val}, "'\n"
	if $state->Verbose;
      push @deps, $self->{val};
  }

  sig => \@deps;

}

sub cmpSig
{
  $_[0] ne $_[1];
}

sub mkSig
{
  my ( $file ) = @_;

  open( SIG, $file )
    or croak( __PACKAGE__, "->mkSig: non-existant signature file `$file'" );

  Digest::MD5->new->addfile(\*SIG)->hexdigest;
}

sub update
{
  my ( $self, $target ) = @_;

  $self->{state}->setSig( $target, $self->{val}, mkSig( $self->{val} ) );
}

sub pprint
{
  my $self = shift;

  $self->{val};
}

1;
