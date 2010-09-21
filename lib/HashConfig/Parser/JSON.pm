## A HashConfig Parser for JSON data.

class HashConfig::Parser::JSON;

use JSON::Tiny;

method parse(Str $string) {
    my $data = from-json($string);
    if ! defined $data {
        warn "error parsing JSON, null document returned.";
    }
    return $data;
}

method encode($data) {
  return to-json($data);
}

