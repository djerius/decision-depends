package Depends;

require 5.005_62;
use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Depends ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
if_dep
action
);

our $VERSION = '0.03';

use Carp;
use Depends::State;
use Depends::List;
use Depends::Target;

# regular expression for a floating point number
our $RE_Float = qr/^[+-]?(\d+[.]?\d*|[.]\d+)([dDeE][+-]?\d+)?$/;

# this keeps track of all saveable state, as well as stuff when
# we're just Pretending

our $State = Depends::State->new( );

sub if_dep(&@)
{
  my ( $deps, $run ) = @_;

  croak( __PACKAGE__, 
	 '::if_dep: ', __PACKAGE__, "::init must be called first\n" )
	unless defined $State;

  print STDERR "\nNew dependency\n" if $State->Verbose;

  my @args = &$deps;

  my @specs = build_spec_list( undef, undef, \@args );

  my ( $deplist, $targets ) = traverse_spec_list( @specs );

  my $depends = depends( $deplist, $targets );

  if ( keys %$depends )
  {
    # clean up beforehand in case of Pretend
    undef $@;
    print STDERR "Action required.\n" if $State->Verbose;
    eval { &$run( $depends) } unless $State->Pretend;
    if ( $@ )
    {
      croak $@ unless defined wantarray;
      return 0;
    }
    else
    {
      update( $deplist, $targets );
    }
  }
  else
  {
    print STDERR "No action required.\n" if $State->Verbose;
  }
  1;
}

sub action(&) { $_[0] }

sub init
{
  my ( $state_file, $attr ) = @_;

  $State->LoadState( $state_file );
  $State->SetAttr( $attr );
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

sub build_spec_list
{
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
      push @res, build_spec_list( $attrs, $levels, $spec );
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


sub traverse_spec_list
{
  my @list = @_;

  local $Carp::CarpLevel = $Carp::CarpLevel + 1;

  # two phases; first the targets, then the dependencies.
  # the targets are identified as id 0.X

  my $deplist = Depends::List->new( $State,
				  { Verbose => $State->Verbose } );

  my @targets;

  eval {

    for my $spec ( @list )
    {
      if ( (grep { exists $spec->{attr}{$_} } qw( target targets sfile slink )) ||
	   (! exists $spec->{attr}{depend} && 0 == $spec->{id}[0] ) )
      {
	push @targets, Depends::Target->new( $State, $spec );
      }

      elsif ( my @match = grep { defined $spec->{attr}{$_} } qw( sig var ) )
      {
	if ( @match > 1 )
	{
	  $Carp::CarpLevel--;
	  croak( __PACKAGE__, 
		 "::traverse_spec_list: too many classes for `$spec->{val}'" )
	}

	$deplist->create( $match[0], $spec );
      }
      else
      {
	$deplist->create( Time => $spec );
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

sub depends
{
  my ( $deplist, $targets ) = @_;

  local $Carp::CarpLevel = $Carp::CarpLevel + 1;
  $deplist->depends( $targets );
}

sub update
{
  my ( $deplist, $targets ) = @_;

  local $Carp::CarpLevel = $Carp::CarpLevel + 1;

  $deplist->update( $targets );

  $_->update foreach @$targets;
}

1;

__END__
# Below is stub documentation for your module. You better edit it!

=head1 NAME

Depends - Track dependencies

=head1 SYNOPSIS

  use Depends;

  Depends::init( $depfile );
  if_dep { @targ_dep_list } 
     action { action };

=head1 DESCRIPTION

B<Depends> is a module which simplifies tracking of file dependencies
based on file time stamps and file contents.  Think of it as a
procedural version of B<make>.

B<Depends> is useful when there are several steps in a process, each
of which depends upon the last.  If the process is interrupted, or if
it is to be redone with changes to parameters in later steps, and if
intermediate results can be kept, then B<Depends> can insure that only
the minimal number of steps be redone.

Each step must result in a tangible product (a file).  For complicated
steps with many products the step's successful completion may be
indicated by creating an empty file whose existance indicates
completion.  This file (a C<status> file in B<Depends> terminology)
can be automatically created if requested.

B<Depends> determines if the product for a given step is older than
any files required to produce it.  It can also check whether the
contents of a file have changed since the product was last created.
This is useful in the case where a configuration file must be created
anew each time, but results in action only if changed since the
product was last created. Finally, it can determine if a variable's
value has changed since the product was last created.

=head2 Dependency history

B<Depends> must keep some dependency information between runs (for
signature and variable dependencies). It stores this in a file,
which must be named by the application.  The application indicates
the file by calling the B<Depends::init> subroutine.

This file is updated after completion of successful actions and
when the program is exited.

=head2 Dry Runs and Changing other behavior

B<Depends> can be put into a state where it checks dependencies
and pretends to update targets in order to check what actions might
need to be taken.  This is done by passing the C<Pretend> attribute
to B<Depends::init>.  In this mode no actions are actually performed,
but are assumed to have successfully created their products.

B<Depends> will output to STDERR its musings if the C<Verbose>
attribute is passed to B<Depends::init>.



=head2 Targets and Dependencies List

Each step must construct a single Perl list of products, also called
targets (as in B<make>), and dependencies.  The list has a simple
syntax - it is a sequence of values, each of which may have one or
more attributes.  Attributes precede values and apply only to the next
value (unless values are grouped), and always begin with a C<->
character.  Multiple attributes may be applied to a single value.

	-target => $file, -depend => -sig => $dep

(Note the use of the perl C<< => >> operator to avoid quoting of
attributes.)  Values which begin with the C<-> character (which may be
confused with attributes) may be passed by reference.  B<Depend>
recognizes negative numbers, so those need not be handled specially.

	-target => \'-strange_file', -target => -33.99e24

Values may be grouped by placing them in anonymous arrays:

	-target => [ $file1, $file2 ]

Attributes are applied to all elements of the group; additional attributes
may modify individual group members:

	-target => [ -sfile => $file1, $file2 ]

Groups may be nested.

To negate an attribute, introduce the same attribute with a prefix of
C<-no_>:

	-target => -sfile => [ $file1, -no_sfile => $file2 ]

Attributes may have values, although they are in general boolean values.
The syntax is '-attr=value'.  Note that because of the C<=> character,
Perl's automatic quoting rules when using the C<< => >> operator are
insufficient to ensure appropriate quoting.  For example

	'-slink=foo' => $target

assigns the C<-slink> attribute to C<$target> and gives the attribute
the value C<foo>.  If no value is specified, a default value of C<1>
is assigned.  Most attributes are boolean, so no value need be assigned
them.

=head2 Targets

Targets are identified either by having the C<-target> or C<-targets>
attributes, or by being the first value (or group) in the
target-dependency list and not having the C<-depend> attribute.  For
example, the following are equivalent

	( -target => $targ1, -target => $targ2, ... )
	( -target => [ $targ1, $targ2 ], ... )
	( [ $targ1, $targ2 ], ... )

There must be at least one target. Target values may have the
following attributes:

=over 8

=item B<-target>

This indicates the value is a target.

=item B<-sfile>

This indicates that the target is a status file.  It will be automatically
created upon successful completion of the step.

=item B<-slink=<linkfile>>

This indicates that the target is a status file which is linked to an
imaginary file C<linkfile>.  Any step which explicitly depends upon
C<linkfile> will instead depend upon the target file instead.
Multiple links to C<linkfile> may be created. Links are checked in
order of appearance, and are useful only as time dependencies.  For
example, rather than depending upon the target of the previous step, a
step might depend upon the C<linkfile>.  It's then possible to
introduce new intermediate steps which link their status files to
C<linkfile> without having to rewrite the current step.  For example

	( -target => '-slink=step1' => 'step1a', ... )
	( -target => '-slink=step1' => 'step1b', ... )

	( -target => $result, -depend => 'step1' )

In this case, the final step will depend upon F<step1a> and F<step1b>.
One could later add a F<step1c> and not have to change the dependencies
for the final step.

The target status file will be automatically created upon successful
completion of the step.

=back


=head2 Dependencies

Dependencies are identified either as I<not> being the first value (or
group) in the list and not having the C<-target> attribute, or by
having the attributes C<-depend> or C<-depends>.  There need not be
any dependencies.

There are three types of dependencies: I<time>, I<signature>, and
I<variable>.  The default type is I<time>.  The defining attributes
are:

=over 8

=item C<-time>

Time dependencies are the default if no attribute is not specified.  A
time dependency results in a comparison of the timestamps of the
target and dependency files.  If the target is older than the
dependency file, the step must be redone.

=item C<-sig>

Signature dependencies check the current contents of the dependency
file against the contents the last time the target was created.  If
the contents have changed, the step must be redone.  An MD5 checksum
signature is computed for signature dependency files; these are what
is stored and compared.

A new signature is recorded upon successful completion of the step.

=item C<-var>

Variable dependencies check the value of a variable against its value
the last time the target was created. If the contents have changed,
the step must be redone.  The new value is recorded upon successful
completion of the step.

Variable specification is a bit strange; the name of the variable
is provided as if it were another attribute:

	-var => -var_name => $var_value

Variables cannot have the same name as any of the reserved names for
attributes.

=back

=head2 Action specification

B<Depends> exports the function B<if_dep>, which is used by the
application to specify the targets and dependencies and the action to
be taken if the dependencies have not been met.  It has the form

  if_dep { targdep }
     action { actions };

where I<targdep> is Perl code which results in a target and dependency
list and I<actions> is Perl code to generate the target.
Note the final semi-colon.

The target dependency list code is generally very simple:

  if_dep { -target => 'foo.out', -depend => 'foo.in' }
     action { ... }

The action routine is passed (via C<@_>) a reference to a hash with
the names of targets whose dependencies were not met as the keys.  The
values are hash references, with the following keys:

=over 8

=item time

A reference to an array of the dependency files which were newer than
the target.

=item var

A reference to an array of the variables whose values had changed.

=item sig

A reference to an array of the files whose content signatures had changed.

=back

If these lists are empty, the target file does not exist.  For example,

  if_dep { -target => 'foo.out', -depend => 'foo.in' }
    action {
      my ( $deps ) = @_;
      ...
    };

If F<foo.out> did not exist

  $deps = { 'foo.out' => { time => [], 
			   var => [],
 			   sig => [] } };

If F<foo.out> did exist, but was older than F<foo.in>,

  %deps = { 'foo.out' => { time => [ 'foo.in' ],
 		           var => [],
                           sig => [] } };

Unless the target is a status file (with attributes C<-sfile> or
C<-slink>), the action routine B<must> create the target file.  It B<must>
indicate the success or failure of the action by calling B<die()> if there
is an error:

  if_dep { -target => 'foo.out', -depend => 'foo.in' }
    action {
      my ( $deps ) = @_;

      frobnagle( 'foo.out' )
	or die( "error frobnagling!\n" );
    };

B<if_dep> will catch the B<die()>. There are two manners in which
the error will be passed on by B<if_dep>.  If B<if_dep> is called
in a void context (i.e., its return value is being ignored), it
will B<croak()> (See L<Carp>).  If called in a scalar context,
it will return C<true> upon success and C<false> upon error.  In either
case the C<$@> variable will contain the text passed to the original
B<die()> call.

The following two examples have the same result:

  eval{ if_dep { ... } action { ... } };
  die( $@ ) if $@;

  if_dep { ... } action { ... } or die $@;


=head1 Subroutines

=over 8

=item Depends::init

  Depends::init( $depfile, \%attr )

This routine sets the file to which B<Depends> writes its dependency
information, as well as various attributes to control B<Depends>
behavior.  

A dependency file is not required if there are no signature or
variable dependencies.  In that case, if no attributes need be set,
this routine need not be called at all.  However, if attributes must
be set and no dependency file is required, pass in the undefined value
for the file name.

  Depends::init( undef, \%attr );

The attributes are passed via a hash, with the following recognized
keys:

=over 8

=item Pretend

If set to a non-zero value, B<Depends> will simulate the actions
to track what might happen.

=item Verbose

If set to a non-zero value, B<Depends> will be somewhat verbose.

=back

For example,

  Depends::init( $depfile, { Pretend => 1, Verbose => 1 } );


=back


=head1 EXPORT

The following routines are exported into the caller's namespace
B<if_dep>, B<action>.

=head1 NOTES

This module was heavily influenced by the ideas in the B<cons> software
construction tool.

The C<{targdep}> and C<{actions}> clauses to B<if_dep> are actually
anonymous subroutines.  Any subroutine reference will do in their
stead

  if_dep \&targdep 
    action \&actions;


=head1 LICENSE

This software is released under the GNU General Public License.  You
may find a copy at 

   http://www.fsf.org/copyleft/gpl.html

=head1 AUTHOR

Diab Jerius (djerius@cfa.harvard.edu)

=cut
