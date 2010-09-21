#!/usr/bin/env perl6

BEGIN { @*INC.push: './lib' }

use Test;
use HashConfig::File;
use JSON::Tiny;

my $conf = HashConfig::File.make('./t/test.json');

say "Perl: "~$conf.perl;
say "JSON: "~to-json($conf);

$conf<added> = "A new section";
$conf<goodbye> = "Everybody";

$conf.save('test-saved.json');

