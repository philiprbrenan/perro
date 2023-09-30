#!/usr/bin/perl -I/home/phil/perl/cpan/DataTableText/lib/
#-------------------------------------------------------------------------------
# Zip
# Philip R Brenan at appaapps dot com, Appa Apps Ltd Inc., 2023
#-------------------------------------------------------------------------------
use v5.30;
use warnings FATAL => qw(all);
use strict;
use Carp;
use Data::Dump qw(dump);
use Data::Table::Text qw(:all);
use GitHub::Crud qw(:all);
use feature qw(say current_sub);

my $Z = q(perro.zip);

unlink $Z;
say STDERR qx(zip $Z coordinates2/* coordinates3/* images/* images3/* obj/* svg/* svg/*/* coodinates2.pl coordinates3.pl createSlices.pl dog*.* scale.pl README.html); 

my $home = q(/home/phil/people/Maria/projects/perro2/);                         # Local files
my $user = q(philiprbrenan);                                                    # User
my $repo = q(perro);                                                            # Repo
my $wf   = q(.github/workflows/main.yml);                                       # Work flow on Ubuntu

expandWellKnownWordsInMarkDownFile                                              # Documentation
  fpe($home, qw(README md2)), fpe $home, qw(README md);

push my @files, searchDirectoryTreesForMatchingFiles($home);                    # Files

for my $s(@files)                                                               # Upload each selected file
 {next if $s =~ m((png|zip|FCStd)\Z); 	                                        # Skip these files
  my $p = readFile($s);                                                         # Load file
  my $t = swapFilePrefix $s, $home;
  next if $s =~ m(/backups/);                                                   # Ignore this folder
  my $w = writeFileUsingSavedToken($user, $repo, $t, $p);
  lll "$w $s $t";
 }

my $d = dateTimeStamp;

my $y = <<'END';
# Test $d

name: Test

on:
  push

jobs:
  test:
    runs-on: ubuntu-latest

    steps:
    - uses: actions/checkout@v2
      with:
        ref: 'main'

    - name: Array
      run: |
        perl createSlices.pl
END

lll "Ubuntu work flow for $repo ", writeFileUsingSavedToken($user, $repo, $wf, $y);
