package Depends::Sig;

require 5.005_62;
use strict;
use warnings;

use Carp;
use Digest::MD5;

our $VERSION = '0.01';

our %attr = ( depend => 1,
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

  croak( __PACKAGE__, 
	 "->depends: non-existant signature file `$self->{val}'" )
    unless -f $self->{val};

  my $prev_val = $self->{state}->getSig( $target, $self->{val} );


  return 
    sig => 
      [
       (defined $prev_val && cmpSig( $prev_val, mkSig( $self->{val} ) ))
       ? () : $self->{val}
      ];
}

sub cmpSig
{
  $_[0] eq $_[1];
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
