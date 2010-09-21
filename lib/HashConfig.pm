role HashConfig does Hash;

use HashConfig::Parser::JSON;

## The HashConfig Role
#
# Used to power the HashConfig::Magic and HashConfig::File libraries.
#
## NOTE: This role is CANNOT be used standalone.
#  See one of the HashConfig::* libraries for a usable implementation.
#
## The default Parser is HashConfig::Parser::JSON.
#  If you want to override it, pass :parser($object) to the new() method.

has $.parser is rw = HashConfig::Parser::JSON.new();

has $.findFile is rw = sub ($me, $file) { 
  if $file.IO ~~ :f { return $file; }
  else { return; }
};

has $.fatal is rw = True;
has $.debug is rw = False;

method !make-init(:$find, :$fatal, :$parser) {
  my $self = self.new();
  if ($find) {
    $self.findFile = $find;
  }
  if ($fatal) {
    $self.fatal = $fatal;
  }
  if ($parser) {
    $self.parser = $parser;
  }
  return $self;
}

method parseFile($file, :$nofind) {
    say "We're in parseFile" if $.debug;
    my $config;
    if $nofind {
      ## Don't use nofile unless you have ensured the file
      ## exists already. It doesn't do any checks.
      $config = $file;
    }
    else {
      $config = $!findFile(self, $file);
      say "Found file: $config" if $.debug;
    }
    if $config {
        my $definition = slurp($config);
        say "Definition file -- \n"~$definition if $.debug;
        return $.parser.parse($definition);
    }
    else {
        my $msg = "Data file '$file' not found.";
        if ($.fatal) {
          die $msg;
        }
        else {
          warn $msg;
          return {};
        }
    }
}

method !merge-loaded($newdata) {
    say "We're in merge-loaded" if $.debug;
    my $dataobj = $newdata;
    if $newdata !~~ Hash {
        say "New data isn't a Hash, wrapping it" if $.debug;
        say $newdata.WHAT if $.debug;
        say $newdata.perl if $.debug;
        $dataobj = { :DATA($newdata) }; ## Wrap it in a Hash.
    }
    self.merge($dataobj);
}

#vim: ft=perl6
