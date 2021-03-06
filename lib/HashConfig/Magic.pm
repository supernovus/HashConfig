use HashConfig;

class HashConfig::Magic does HashConfig;

## The Magic HashConfig, doesn't keep track of files, and has no
## saving support, but is used to merge multiple configuration files
## in special ways. See the 'merge' method for the rules.

method make(:$find, :$fatal, :%data, :$file, :$parser) {
  my $self = self!make-init(:$find, :$fatal, :$parser);
  if (%data) {
    $self.merge(%data);
  }
  if ($file) {
    $self.loadFile($file);
  }
  return $self;
}

method loadFile ($file) {
    say "We're in loadFile" if $.debug;
    self!merge-loaded(self.parseFile($file));
}

multi method load (Str $definition) {
    self!merge-loaded($.parser.parse($definition));
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

## Used by merge to include block level stuf.
method !include(%section is rw, $file) {
  if %section ~~ HashConfig {
    %section.loadFile($file);
  }
  else {
    my %newsection = self.make(:file($file));
    self.merge(%newsection, %section);
  }
  return %section;
}

## New magic merge method with special rules for merging.
method merge (%data, %section=self) {
  ## First we check for block level INCLUDE.
  if %data.exists('INCLUDE') {
    self!include(%section, %data<INCLUDE>);
  }
  ## Now we process normal rules.
  for %data.kv -> $k, $v {
    say "merging $k => "~$v.perl if $.debug;
    if $k ~~ /^'+'/ {
      my $key = $k.subst(/^'+'/, '');
      say "Appending $key" if $.debug;
      if ($v ~~ Array) {
        for @($v) -> $sv {
          %section.push($key => $sv);
        }
      }
      else {
        %section.push($key => $v);
      }
    }
    elsif $k ~~ /^'~'/ {
      my $key = $k.subst(/^'~'/, '');
      say "Inserting $key" if $.debug;
      if ($v ~~ Array) {
        for @($v) -> $sv {
          self!unshift_construct(%section, $key, $sv);
        }
      }
      else {
        self!unshift_construct(%section, $key, $v);
      }
    }
    elsif $k ~~ /^'-'/ {
      my $key = $k.subst(/^'-'/, '');
      say "Removing $key" if $.debug;
      if %section.exists($key) && %section{$key} ~~ Array {
        if $v ~~ /^'-'\d+$/ {
          my $count = $v.subst(/^'-'/, '');
          %section{$key}.splice(+$v, +$count);
        }
        else {
          %section{$key}.splice(0, +$v);
        }
      }
    }
    elsif ($k eq 'INCLUDE') {
      next; ## skip INCLUDE statements.
    }
    elsif ($k eq 'POSTINCLUDE') {
      next; ## skip POSTINCLUDE statements.
    }
    ## A special type of INCLUDE, a way to set a key to the contents of a file.
    elsif ($v ~~ Str && $v ~~ /INCLUDE ':' (.*)/) {
      %section{$k} = self.parseFile($0);
    }
    elsif ($v ~~ Str && $v eq '~~' && %section.exists($k)) {
      %section.delete($k);
    }
    elsif (%section.exists($k) && %section{$k} ~~ Hash && $v ~~ Hash) {
      say "Merging $k as deep hash" if $.debug;
      %section{$k} = self.merge($v, %section{$k});
    }
    else {
      say "Assigning $k directly" if $.debug;
      %section{$k} = $v;
    }
  }
  ## Next we check for block level POSTINCLUDE.
  if %data.exists('POSTINCLUDE') {
    self!include(%section, %data<INCLUDE>);
  }

  ## Finally, we return the section.
  return %section;
}

