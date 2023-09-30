#!/usr/bin/perl -I/home/phil/perl/cpan/DataTableText/lib/
#-------------------------------------------------------------------------------
# Convert click points to  3d 
# Philip R Brenan at appaapps dot com, Appa Apps Ltd Inc., 2023
#-------------------------------------------------------------------------------
use v5.30;
use warnings FATAL => qw(all);
use strict;
use Carp;
use Data::Dump qw(dump);
use Data::Table::Text qw(:all);

my $z = 100;                                                                    # Extrusion 


sub convertFile($)                                                              # Convert a file 
 {my ($in) = @_;                                                                # Input file
  my $out = fpe "coordinates3", fn($in), "obj";                                 # Output file
  my @I = readFile($in); 


  my @v; my @z; 
  for my $i(@I)                                                                 # Extract 2d coordinates
   {if ($i =~ m((\d+), (\d+)))
	 {push @v, [$1, $2,  0];
      push @z, [$1, $2, $z];                                                    # Extrude 
     }  
   }	    

  my @t;
  for my $i(2..@v)                                                              # Create extruded mesh
   {if ($i)
	 {my $al =      $i - 1;
      my $ah = @v + $al;
      my $bl =      $i;
      my $bh = @v + $bl;
      
      push @t, [$al, $ah, $bl];                                                 # Lower triangle
      push @t, [$ah, $bh, $bl];                                                 # Upper triangle
     }  
   }	    

  my @V = (@v, @z);                                                             # All the vertices
  
  my @obj = map {my ($x, $y, $z) = @$_; "v $x $y $z\n"} @V;                     # Vertex definitions
  
  for my $t(@t)                                                                 # Faces
   {my ($a, $b, $c) = @$t;         
    push @obj, "f $a $b $c\n";
   }
   
  owf($out, join '', @obj); 
 }

my @files = searchDirectoryTreesForMatchingFiles("coordinates2"); 
say STDERR "AAAA", dump(\@files);
for my $f(@files)
 {convertFile($f); 
 } 	 
