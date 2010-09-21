use HashConfig;

class HashConfig::File does HashConfig;

## HashConfig::File is completely different from HashConfig::Magic.
## This class only loads a single file (it must be a file) and stores
## the location of the file. It also offers a save() method, which can
## write the file back, or save a new filename.

has $.filename is rw;

## In this make 'file' is a required parameter.
method make($file, :$find, :$fatal, :$parser) {
  my $self = self!make-init(:$find, :$fatal, :$parser);
  if ($file) {
    $self.load($file);
  }
  return $self;
}

## load is for files only.
method load ($file) {
    say "We're in load" if $.debug;
    my $filename = $!findFile(self, $file);
    $.filename = $filename;
    self!merge-loaded(self.parseFile($filename, :nofind));
}

## save has an optional parameter specifying a new filename.
method save ($file?) {
  my $filename = $.filename;
  if $file {
    $filename = $file;
    $.filename = $file;
  }
  my $fh = open $filename, :w;
  $fh.say: $.parser.encode(self);
  $fh.close;
}

## Based on Hash!push_construct from the Core setting.
method !unshift_construct(%hash, $key, $val) {
  if %hash.exists($key) {
    if %hash{$key} ~~ Array {
      %hash{$key}.unshift($val);
    }
    else {
      %hash{$key} = [ $val, %hash{$key} ];
    }
  }
  else {
    %hash{$key} = $val;
  }
}

## New magic merge method with special rules for merging.
method merge (%data) {
  ## First, delete any existing items.
  for self.keys -> $k {
    self.delete($k);
  }
  ## Nest, load the new keys.
  for %data.kv -> $k, $v {
    self{$k} = $v;
  }
  ## Finally, return ourself.
  return self;
}

