our $depfile = 'data/deps';

sub submit
{
  my $poke = pop @_ if 'CODE' eq ref $_[-1];
  my %Attr = %{ shift @_ } if 'HASH' eq ref $_[0];
  my ( @specs ) = @_;

  Depends::init( $depfile, { Verbose => $verbose, Cache => 0, %Attr } )
      unless $Attr{NoInit};

  my @res = Depends::build_spec_list( undef, undef, \@specs );
  my ( $deplist, $targets ) = Depends::traverse_spec_list( @res );

  &$poke( $deplist, $targets )
    if $poke;

  my $deps = Depends::depends( $deplist, $targets);

  ( $deplist, $targets, $deps );
}

sub mkfile
{
  my ( $file, $string ) = @_;
  open FILE, ">$file" or die( "unable to open $file\n" );
  print FILE $string, "\n";
  close FILE;
}


1;
