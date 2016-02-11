use strict;
use warnings;
use inc::Module::Install;

name 'Decision-Depends';

license 'gpl3';

all_from 'lib/Decision/Depends.pm';

requires 'YAML';
requires 'Tie::IxHash';
requires 'Data::Compare';
requires 'Clone';

build_requires 'Test::More';
build_requires 'Test::Deep';

auto_install;

WriteAll;
