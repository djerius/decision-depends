package Depends::State;

require 5.005_62;
use strict;
use warnings;

use YAML qw();
use IO::File;
use Carp;

our $VERSION = '0.01';

sub new
{
  my $class = shift;
  $class = ref($class) || $class;

  my $self = {
	      Attr => { Cache => 0,
			DumpFiles => 0,
			Pretend => 0,
			Verbose => 0,
			AutoSave => 1,
			Force => 0,
			File => undef
		      },
	      SLink => {},
	      Files => {},
	      Sig   => {},
	      Var   => {},
	     };

  bless $self, $class;

  my $attr = pop @_ if 'HASH' eq ref $_[-1];

  my ( $file ) = @_;

  $self->SetAttr( $attr );
  $self->LoadState( );

  $self;
}

sub DESTROY
{
  $_[0]->SaveState if $_[0]->{Attr}{AutoSave};
}

sub SetAttr
{
  my ( $self, $attr ) = @_;

  return unless defined $attr;

  croak( __PACKAGE__, '->SetAttr: attribute not a hash ref')
	 unless 'HASH' eq ref $attr;

    my @notok = grep { ! exists $self->{Attr}{$_} } keys %$attr;
  croak( __PACKAGE__, '->SetAttr: unknown attribute(s): ',
	 join( ', ', @notok) ) if @notok;

  my ($key, $val);
  $self->{Attr}{$key} = $val while( ($key, $val) = each %$attr );
  $self->{Attr}{Cache} = 1 if $self->{Attr}{Pretend};

  $self->LoadState() if exists $attr->{File};
}

sub LoadState
{
  my ( $self ) = @_;

  my $file = $self->{Attr}{File};

  my $state = YAML::LoadFile($file)
      if defined $file && -f $file;

  $self->{SLink} = {};
  $self->{Sig} = $state->{Sig};
  $self->{Var} = $state->{Var};
  $self->{Files} = $state->{Files};
}

sub SaveState
{
  my $self = shift;

  return if $self->{Attr}{Pretend} || !defined $self->{Attr}{File};

  YAML::StoreFile( $self->{Attr}{File},
		   { 
		    Sig => $self->{Sig}, 
		    Var => $self->{Var}, 
		    Files => 
		      ( $self->{Attr}{DumpFiles} ? $self->{Files} : {} ) 
		   } )
    or croak( __PACKAGE__, 
	      "->SaveState: error writing state to $self->{Attr}{File}" );
}

sub EraseState
{
  my $self = shift;

  $self->{$_} = {} foreach qw( SLink Files Sig Var );

}

sub DumpAll
{
  my $self = shift;

  print STDERR YAML::Store($self);
}

sub Verbose
{
  $_[0]->{Attr}{Verbose};
}

sub Pretend
{
  $_[0]->{Attr}{Pretend};
}

######################################################################
#  Status Files,


sub attachSLink
{
  my ( $self, $file, $slink ) = @_;

  $self->{SLink}{$slink} = []
    unless exists  $self->{SLink}{$slink};

  push @{$self->{SLink}{$slink}}, $file;
}

sub getSLinks
{
  my ( $self, $file ) = @_;

  return exists $self->{SLink}{$file} ? $self->{SLink}{$file} : [$file];
}


######################################################################
# File/Time routines

sub getTime
{
  my ( $self, $file ) = @_;

  exists $self->{Files}{$file} ?  $self->{Files}{$file}{time} : undef;
}

sub setTime
{
  my ( $self, $file, $time ) = @_;

  return unless $self->{Attr}{Cache};

  $self->{Files}{$file}{time} = $time;
}


######################################################################
# Signature routines

sub getSig
{
  my ( $self, $target, $file ) = @_;

  ( exists $self->{Sig}{$target} && exists $self->{Sig}{$target}{$file} )
     ? $self->{Sig}{$target}{$file} : undef;
}

sub setSig
{
  my ( $self, $target, $file, $sig ) = @_;

  $self->{Sig}{$target}{$file} = $sig;
  $self->SaveState;
}


######################################################################
# Variable routines

sub getVar
{
  my ( $self, $target, $var ) = @_;

  # return undef if we have no record of this variable
  exists $self->{Var}{$target} && $self->{Var}{$target}{$var} ? $self->{Var}{$target}{$var} : undef;
}


sub setVar
{
  my ( $self, $target, $var, $val ) = @_;

  $self->{Var}{$target}{$var} = $val;
  $self->SaveState;
}

1;
__END__
# Below is stub documentation for your module. You better edit it!

=head1 NAME

Depends - Perl extension for blah blah blah

=head1 SYNOPSIS

  use Depends::State;


=head1 DESCRIPTION


=head2 EXPORT

None by default.


=head1 AUTHOR

A. U. Thor, a.u.thor@a.galaxy.far.far.away

=head1 SEE ALSO

perl(1).

=cut
