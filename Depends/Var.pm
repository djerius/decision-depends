package Depends::Var;

require 5.005_62;
use strict;
use warnings;

use Carp;

our $VERSION = '0.01';

our %attr = ( depend => 1,
	      depends => 1,
	      force => 1,
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

  my $var = $self->{attr}{var};

  my $prev_val = $self->{state}->getVar( $target, $var );

  my @deps = ();

  if ( defined $prev_val )
  {
    my $is_not_equal = 
      ( exists $self->{attr}{force} ? 
	$self->{attr}{force} : $self->{state}{Attr}{Force} ) ||
	cmpVar( exists $self->{attr}{case}, $prev_val, $self->{val} );

    if ( $is_not_equal )
    {
      print STDERR 
	"    variable `", $var, "' is now (", $self->{val},
	"), was ($prev_val)\n"
	  if $self->{state}->Verbose;

      push @deps, $var;
    }
    else
    {
      print STDERR "    variable `", $var, "' is unchanged\n"
	if $self->{state}->Verbose;
    }
  }
  else
  {
    print STDERR "    No value on file for variable `", $var, "'\n"
	if $self->{state}->Verbose;
      push @deps, $var;
  }

  var => \@deps;
}

sub cmpVar
{
  my ( $case, $var1, $var2 ) = @_;

  ( $case ? uc($var1) ne uc($var2) : $var1 ne $var2 );
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
