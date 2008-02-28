use strict;
use warnings;
use inc::Module::Install;

name 'Decision-Depends';

license 'gpl3';

all_from 'lib/Decision/Depends.pm';

requires 'YAML';
requires 'Tie::IxHash';

build_requires 'Test::More';

auto_install;

WriteAll;
