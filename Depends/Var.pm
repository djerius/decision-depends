package Depends::Var;

require 5.005_62;
use strict;
use warnings;

use Carp;

our $VERSION = '0.01';

our %attr = ( depend => 1,
	      depends => 1,
	      var => 1,
	      case => 1,
	      no_case => 1,
	    );

sub new
{
  my $class = shift;
  $class = ref($class) || $class;

  my ( $state, $spec ) = @_;

  my $self = { %$spec, state => $state };

  # ensure that no bogus attributes are set
  my @notok = grep { ! exists $attr{$_} } keys %{$self->{attr}};

  croak( __PACKAGE__, '->new: too many variable names(s): ',
	 join(', ', @notok ) ) if @notok > 1;

  croak( __PACKAGE__, 
	 ": must specify a variable name for `$self->{val}'" )
    unless @notok == 1;

  $self->{attr}{var} = $notok[0];

  bless $self, $class;
}

sub depends
{
  my ( $self, $target ) = @_;

  my $prev_val = $self->{state}->getVar( $target, $self->{attr}{var} );

  return
    var => [
	    defined $prev_val &&
	    cmpVar( exists $self->{attr}{case}, $prev_val, $self->{val} )
	    ? () : ( $self->{attr}{var} )
	   ];
}

sub cmpVar
{
  my ( $case, $var1, $var2 ) = @_;

  ( $case ? uc($var1) eq uc($var2) : $var1 eq $var2 );
}

sub update
{
  my ( $self, $target ) = @_;

  $self->{state}->setVar( $target, $self->{attr}{var}, $self->{val} );
}

sub pprint
{
  my $self = shift;

  "$self->{attr}{var} = $self->{val}";
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
