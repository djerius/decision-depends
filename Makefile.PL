use strict;
use warnings;
use inc::Module::Install;

name 'Decision-Depends';
license 'gpl3';
auto_license( holder => 'Smithsonian Astrophysical Observatory' );
all_from 'lib/Decision/Depends.pm';

resources (
   license    => 'http://www.gnu.org/licenses/gpl-3.0.html',
   repository => 'https://bitbucket.org/djerius/decision-depends',
   bugtracker => 'https://rt.cpan.org/Public/Dist/Display.html?Name=Decision-Depends',
);

author_tests( 'xt' );

cpanfile;

WriteAll;
