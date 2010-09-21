#!/usr/bin/env perl6

use HashConfig::Magic;
use JSON::Tiny;

my $conf = HashConfig::Magic.make(:file('./t/test.json'));

say "Perl: "~$conf.perl;
say "JSON: "~to-json($conf);

