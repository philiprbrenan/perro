#!/usr/bin/perl -I/home/phil/perl/cpan/DataTableText/lib/
#-------------------------------------------------------------------------------
# Scales the igaes by a factor of three
# Philip R Brenan at appaapps dot com, Appa Apps Ltd Inc., 2023
#-------------------------------------------------------------------------------
use v5.30;
use warnings FATAL => qw(all);
use strict;
use Carp;
use Data::Dump qw(dump);
use Data::Table::Text qw(:all);

my @i = searchDirectoryTreesForMatchingFiles("images");
for my $i(@i)
 {my $o = $i =~ s(images) (images3)gsr;
  say STDERR qx(convert $i -resize 300% $o)
 }
