#!/usr/bin/perl -I/home/phil/perl/cpan/DataTableText/lib/
#-------------------------------------------------------------------------------
# Triangulate the two faces of each slice
# Philip R Brenan at appaapps dot com, Appa Apps Ltd Inc., 2023
#-------------------------------------------------------------------------------
use v5.30;
use warnings FATAL => qw(all);
use strict;
use Carp;
use Data::Dump qw(dump);
use Data::Table::Text qw(:all);
use Math::Vectors2;

my $offset = 100;                                                               # Offset the drawing by this much 
my $thick  = 100;                                                               # Thickness of the slices
my $BackBoneHeight    =  370;                                                   # Back bone size 
my $BackBoneMouth     =  347;                                                   # Back bone mouth 
my $BackBoneBackHead  =   54;                                                   # Back bone back of head
my $BackHeight        =   75;
my $BackBoneLegToLeg  = 1374;                                                   # Leg to leg
my $CrossSectionUp    =   83;
my $CrossSectionSide  =  251;
my $CrossSectionDown  =  203;
my $LowerBodyBackTop  =  264;
my $LowerBodyFoot     =  106;
my $EarWidth          =  225;

makeDieConfess;

sub toSvg($;$)                                                                  # Convert an obj file to svg by projecting the mesh onto the xy plane
 {my ($file, $debug) = @_;                                                      # File name, debug 
  my $in   = fpe "coordinates2", $file, q(txt);                                 # Input file name
  my @lines = readFile $in;
  
  my @points2;                                                                  # The 2d points as originally read in before any transformations
  my @points; my %points;                                                       # The vertices in the slice.  mapping from a point in 3d to its vertex number
  my @triangles;                                                                # The triangles in the lower layer

  my sub addPoint($$$)                                                          # Returns the vertex number of a point
   {my ($x, $y, $z) = @_;                                                       # x, y, z coordinates of point
    my $p = $points{$x}{$y}{$z};
    return $p if defined $p;
    push @points, [$x, $y, $z];
    return $points{$x}{$y}{$z} = @points;
   }
   
  my sub measure($$)                                                            # Measure the distance between two points
   {my ($A, $B) = @_;                                                           # Point indices of points to measue  betweenParameters
	my $a = &Math::Vectors2::new($points2[$A]->@*);
    my $b = &Math::Vectors2::new($points2[$B]->@*); 
    sprintf "%4d", int(($a-$b)->l + 0.5);
   }
   
  my sub measureY($$)                                                           # Measure the Y distance between two points
   {my ($A, $B) = @_;                                                           # Point indices of points to measue  betweenParameters
	my $a = &Math::Vectors2::new(0, $points2[$A][1]);
    my $b = &Math::Vectors2::new(0, $points2[$B][1]); 
    sprintf "%4d", int(($a-$b)->l + 0.5);
   }
   
  my sub scale($)                                                               # Scale a set of points
   {my ($s) = @_;                                                               # Scale factor
    for my $p(@points2)
     {my ($x, $y) = @$p;
      $p = [$x * $s, $y * $s];
     }
   }
   
  my sub swapYZ()                                                               # Swap y and z coordinates
   {for my $p(@points)
     {my ($x, $y, $z) = @$p;
      $p = [$x, $z, $y];
     }
   }

  my sub tri($$$$@)                                                             # Draw triangles
   {my ($cx, $cy, $s, $f, @z) = @_;                                             # Center x, Center y to draw from, start point in array, end point in array, trailing pairs  
    $cx += $offset;
    $cy += $offset;

    my @s;
     
    foreach my $i($s..$f-1)                                                     # Triangles in initial series
     {my $ax = $points[$i+0][0] + $offset;
      my $ay = $points[$i+0][1] + $offset;
      my $bx = $points[$i+1][0] + $offset;
      my $by = $points[$i+1][1] + $offset;
      push @s, qq(<polygon points="$ax,$ay $bx,$by $cx,$cy" fill="none" stroke="red\"/>);

      my $c = addPoint($cx, $cy, 0);
      my $a = addPoint($ax, $ay, 0);
      my $b = addPoint($bx, $by, 0);
      my $C = addPoint($cx, $cy, $thick);
      my $A = addPoint($ax, $ay, $thick);
      my $B = addPoint($bx, $by, $thick);
      push @triangles, [$c, $b, $a],  [$A, $B, $C], [$a, $b, $A], [$b, $B, $A]; # Triangulate the slice
     }                
    
    while(@z >= 2)                                                              # Trailing pairs to be drawn individualy
     {my $s = shift @z; my $f = shift @z;
	  my $ax = $points[$s][0] + $offset;
      my $ay = $points[$s][1] + $offset;
      my $bx = $points[$f][0] + $offset;
      my $by = $points[$f][1] + $offset;
      push @s, qq(<polygon points="$ax,$ay $bx,$by $cx,$cy" fill="none" stroke="red\"/>);

      my $c = addPoint($cx, $cy, 0);
      my $a = addPoint($ax, $ay, 0);
      my $b = addPoint($bx, $by, 0);
      my $C = addPoint($cx, $cy, $thick);
      my $A = addPoint($ax, $ay, $thick);
      my $B = addPoint($bx, $by, $thick);
      push @triangles, [$c, $b, $a],  [$A, $B, $C], [$a, $b, $A], [$b, $B, $A]; # Triangulate the slice
	 }
    @s
   }
  
  if ($file =~ m(\AcrossSection\Z))                                             # Clean up some drawings 
   {shift @lines for 0..4;
    pop @lines;
   }

  for my $l(@lines)                                                             # Load vertices
   {if ($l =~ m((\d+),\s+(\d+)))
     {push @points2, [$1, $2];
     }
    else 
     {confess "Unexpected line: $l";
     }                          
   }

  my sub horizontal($$)                                                         # Rotate figure to make it horizontal 
   {my ($O, $P) = @_;                                                           # Index of point acting as origin, index of sample point we wish to make horizontal
	my $o = &Math::Vectors2::new($points2[$O]->@*);                             # Origin of rotation
	my $p = &Math::Vectors2::new($points2[$P]->@*);                             # Sample point we want to rotate 
	my $c =  Math::Vectors2::new($p->x, $o->y);                                 # We want the sample point to rotate onto a line through the origin and this point
	my $S = -($c - $o)->  sine($p - $o);
	my $C =  ($c - $o)->cosine($p - $o);
    for my $p(@points2)
     {my $a = &Math::Vectors2::new(@$p);
	  my $A = $a->rotate($o, $S, $C);	 
      $p = [$A->x, $A->y];
     } 
   } 

  my sub vertical($$)                                                           # Rotate figure to make it vertical
   {my ($O, $P) = @_;                                                           # Index of point acting as origin, index of sample point we wish to make horizontal
	my $o = &Math::Vectors2::new($points2[$O]->@*);                             # Origin of rotation
	my $p = &Math::Vectors2::new($points2[$P]->@*);                             # Sample point we want to rotate 
	my $c =  Math::Vectors2::new($o->x, $p->y);                                 # We want the sample point to rotate onto a line through the origin and this point
	my $S = -($c - $o)->  sine($p - $o);
	my $C =  ($c - $o)->cosine($p - $o);
    for my $p(@points2)
     {my $a = &Math::Vectors2::new(@$p);
	  my $A = $a->rotate($o, $S, $C);	 
      $p = [$A->x, $A->y];
     } 
   } 

  horizontal( 2,  3) if $file =~ m(\Aback\Z);           
  horizontal( 2,  3) if $file =~ m(\Aback2\Z);                                  # Rotate figures to make horizontal 
  vertical  (79, 80) if $file =~ m(\AbackBone\Z);       
  horizontal(52, 53) if $file =~ m(\AcrossSection\Z);   
  horizontal(32, 33) if $file =~ m(\Afoot1\Z);          
  horizontal( 2,  3) if $file =~ m(\Afoot2\Z);         
  horizontal( 2,  3) if $file =~ m(\Afoot3\Z);          
  horizontal( 3,  4) if $file =~ m(\Afoot4\Z);          
  horizontal( 4,  5) if $file =~ m(\AlowerBody\Z);

  scale($BackBoneLegToLeg / measure ( 2,  3)) if $file =~ m(\Aback\Z);          # Scale figures
  scale($BackBoneLegToLeg / measure ( 2,  3)) if $file =~ m(\Aback2\Z);   
  scale($BackBoneHeight   / measure (22, 23)) if $file =~ m(\AcrossSection\Z);   
  scale($LowerBodyFoot    / measure (32, 33)) if $file =~ m(\Afoot1\Z);          
  scale($BackBoneMouth    / measure ( 2,  3)) if $file =~ m(\Afoot2\Z);         
  scale($EarWidth         / measure ( 0,  1)) if $file =~ m(\Afoot3\Z);          
  scale($BackBoneBackHead / measure ( 2,  3)) if $file =~ m(\Afoot4\Z);          
  scale($BackBoneLegToLeg / measure ( 4,  5)) if $file =~ m(\AlowerBody\Z);          
  
  my $min_x; my $max_x;                                                         # Maximum and minimum extents
  my $min_y; my $max_y;                                                           
  
  for my $p(@points2)
   {my ($x, $y) = @$p;
    $min_x = $x if !defined($min_x) || $x < $min_x;
    $min_y = $y if !defined($min_y) || $y < $min_y;
    $max_x = $x if !defined($max_x) || $x > $max_x;
    $max_y = $y if !defined($max_y) || $y > $max_y;
   }

  my sub flipX()                                                                # Flip along the X axis
   {for my $p(@points2)
     {my ($x, $y) = @$p;
      $p = [$min_x + $max_x - $x, $y];
     }
   }

  my sub flipY()                                                                # Flip along the Y axis
   {for my $p(@points2)
     {my ($x, $y) = @$p;
      $p = [$x, $min_y + $max_y - $y];
     }
   }

  flipX() if $file =~ m(\Aback2\Z);       
  flipX() if $file =~ m(\AbackBone\Z);       
  flipX() if $file =~ m(\Afoot4\Z);       

   flipY() if $file =~ m(\Aback\Z);                                              # Prepare for FreeCad
   flipY() if $file =~ m(\Aback2\Z);                       
   flipY() if $file =~ m(\AbackBone\Z);       
   flipY() if $file =~ m(\AcrossSection\Z);   
  #flipY() if $file =~ m(\Afoot1\Z);          
  #flipY() if $file =~ m(\Afoot2\Z);         
  #flipY() if $file =~ m(\Afoot3\Z);          
  #flipY() if $file =~ m(\Afoot4\Z);          
   flipY() if $file =~ m(\AlowerBody\Z);
  
  for my $p(@points2)                                                           # Relocate to edge of quadrant and construct 3d lower layer 
   {my ($x, $y) = @$p;
    addPoint($x - $min_x, $y - $min_y, 0);
   }
  
  my $svg_width  = $max_x - $min_x + 2 * $offset;                               # Create SVG representation of slice 
  my $svg_height = $max_y - $min_y + 2 * $offset;
  
  push my @s, <<"END";
<svg width="$svg_width" height="$svg_height" xmlns="http://www.w3.org/2000/svg">
END
  
  push @s, q(<polygon points=");                                                # Draw the closed loop  
  foreach my $p(@points)
   {my ($x, $y) = @$p;
    $x += $offset;
    $y += $offset;
    push @s, "$x,$y ";
   }
  push @s, qq(" fill="none" stroke="black\"/>);
  
  my $n = 0;                                                                    # Label vertex with position in array
  foreach my $p(@points)                                                        # Mark vertices with corners and numbers
   {my ($x, $y) = @$p;
    $x += $offset;
    $y += $offset;
    #push @s, qq(<rect x="$x" y="$y" width="4" height="4" fill="black"/>\n);
    push @s, qq(<text x="$x" y="$y" font-size="20" dy="-2" text-anchor="middle" fill="red">$n</text>);
    $n++;
  }
  
  if ($file =~ m(\Aback\Z))
   {push @s, tri($points[0][0], $points[0][1],  27,  41, 27, 1);
    
    my $c = &Math::Vectors2::new($points[26]->@*);
    my $a = &Math::Vectors2::new($points[ 2]->@*);
    my $b = &Math::Vectors2::new($points[ 3]->@*);
    my $C = $a + ($b - $a) / 3;
    push @s, tri($C->x, $C->y,  11, 27, 4, 11);
    push @s, tri($C->x, $C->y,   1,  4, 27, 1);
    push @s, tri($points[5][0], $points[5][1],  6, 11, 11, 4);
   
    say STDERR "my \$BackHeight        = ",  measure( 4, 12), ";";
   }   
  
  
  if ($file =~ m(\Aback2\Z))
   {push @s, tri($points[0][0], $points[0][1],  28, 38, 1, 28);

    my $c = &Math::Vectors2::new($points[22]->@*);
    my $a = &Math::Vectors2::new($points[ 2]->@*);
    my $b = &Math::Vectors2::new($points[ 3]->@*);
    my $C = $a + ($b - $a) / 2;
    push @s, tri($C->x, $C->y,  15, 28, 28, 1);
    push @s, tri($C->x, $C->y,   1, 4,   4, 15);
    push @s, tri($points[5][0], $points[5][1],  6, 15, 15, 4);
    swapYZ();
   }
  
  if ($file =~ m(\AbackBone\Z))
   {my $a = &Math::Vectors2::new($points[20]->@*);
    my $b = &Math::Vectors2::new($points[99]->@*);
    my $c = ($a + $b) / 2;
    push @s, tri($c->x, $c->y,  8, 23);
    push @s, tri($c->x, $c->y, 81, 107, 23,  81, 107, 8);
	   
#	push @s, tri($points[ 20][0], $points[ 20][1] + 2*$offset,  8,  23);
#    push @s, tri($points[ 20][0], $points[ 20][1] + 2*$offset, 81, 107, 23,  81, 107, 8);

    push @s, tri($points[108][0], $points[108][1],            109, 118,  8, 107, 118, 8);
   
    if (1)                                                                      # Tail
     {my $x = ($points[4][0] +  $points[126][0]) / 2;
      my $y = ($points[4][1] +  $points[126][1]) / 2;
      push @s, tri($x, $y, 0, 8, 8, 118);
      push @s, tri($x, $y, 118, 133, 133, 0);
     }
   
    if (1)                                                                      # Right side of body
     {my $x = ($points[27][0] +  $points[59][0]) / 2;
      my $y = ($points[27][1] +  $points[59][1]) / 2;
      push @s, tri($x, $y, 23, 31, 81, 23);
      push @s, tri($x, $y, 48, 81);
      push @s, tri($x, $y, 33, 42, 31, 48);
  
      my ($X, $Y) = @{$points[38]};                                             # Top of head
      $x = ($x + $X) / 2;
      $y = ($y + $Y) / 2;
      push @s, tri($x, $y, 31, 48);
     }
   
    say STDERR "my \$BackBoneHeight    = ",  measure(10, 108), ";";
    say STDERR "my \$BackBoneMouth     = ",  measure(49, 50) , ";";
    say STDERR "my \$BackBoneBackHead  = ",  measure(29, 30) , ";";
    say STDERR "my \$BackBoneLegToLeg  = ",  measure(82, 106) , ";";
   }
  
  if ($file =~ m(\AcrossSection\Z))  
   {push @s, tri($points[ 10][0], $points[ 10][1],    0,   9, 120, 121, 11, 120, 121, 0);
    push @s, tri($points[ 23][0], $points[ 23][1],   11,  22, 119, 120, 120, 11);
    push @s, tri($points[ 23][0], $points[ 23][1],  111, 119);
    push @s, tri($points[ 23][0], $points[ 23][1],   73, 103, 102, 111, 24, 73);
  
    push @s, tri($points[103][0], $points[103][1],   104, 119);
  
    push @s, tri($points[ 24][0], $points[ 24][1],    25,  39, 39, 51);
    push @s, tri($points[ 24][0], $points[ 24][1],    51,  62, 62, 73);
    
    push @s, tri($points[ 39][0], $points[ 39][1],    40,  51);
    push @s, tri($points[ 73][0], $points[ 73][1],    62,  71);
   
    say STDERR "my \$CrossSectionUp    = ",  measure(38, 37), ";";
    say STDERR "my \$CrossSectionSide  = ",  measure(50, 51), ";";
    say STDERR "my \$CrossSectionDown  = ",  measure(74, 75), ";";
   }
  
  if ($file =~ m(\Afoot1\Z))                                                     
   {push @s, tri($points[ 31][0], $points[ 31][1],   31, 31, 30, 35); 
    push @s, tri($points[ 32][0], $points[ 32][1],   24, 33); 
    push @s, tri($points[ 33][0], $points[ 33][1],    8, 24, 34, 8,  24, 32);
    push @s, tri($points[ 34][0], $points[ 34][1],    3,  13, 13, 34, 35, 3);   ####
    push @s, tri($points[ 35][0], $points[ 35][1],    0, 3, 30, 36, 36, 0); 
   # push @s, tri($points[ 34][0], $points[ 34][1],   35, 36, 36, 0);    
    
    
   # push @s, tri($points[ 30][0], $points[ 30][1],   31, 31, 31, 36);           # Covers unwanted cut  
   # push @s, tri($points[ 31][0], $points[ 31][1],   30, 30, 35, 36); 
    swapYZ();
   }
																				# Actually the mouth
  if ($file =~ m(\Afoot2\Z))
   {push @s, tri($points[  1][0], $points[  1][1],    8, 30, 2, 8, 30, 0);
    push @s, tri($points[  2][0], $points[  2][1],    3, 8);
    swapYZ();
   }
  
  if ($file =~ m(\Afoot3\Z))
   {push @s, tri($points[  1][0], $points[  1][1],   16, 37, 2, 16, 37, 0);
    push @s, tri($points[  2][0], $points[  2][1],    2, 16);
    #swapYZ();
   }
  
  if ($file =~ m(\Afoot4\Z))
   {push @s, tri($points[  2][0], $points[  2][1],   18, 22, 22, 0, 0, 1);
    push @s, tri($points[  3][0], $points[  3][1],    4, 18, 18, 2);
    swapYZ();
    say STDERR "my \$EarWidth          = ",  measure( 4, 5), ";";
   }
  
  if ($file =~ m(\AlowerBody\Z))
   {push @s, tri($points[  2][0], $points[  2][1],   83, 96,  96,  1,   3, 83);
    push @s, tri($points[  3][0], $points[  3][1],   52, 74,  74, 83,   4,  5,  5, 52);
    push @s, tri($points[ 74][0], $points[ 74][1],   75, 83);
  
    push @s, tri($points[  5][0], $points[  5][1],   51, 52);
    push @s, tri($points[  6][0], $points[  6][1],   39, 51, 51, 5, 7, 39);
    push @s, tri($points[  7][0], $points[  7][1],    8, 13, 13, 39);
  
    push @s, tri($points[ 16][0], $points[ 16][1],   35, 39, 39, 13, 13, 14, 14, 15, 17, 35);
    push @s, tri($points[ 17][0], $points[ 17][1],   18, 27, 27, 35);
  
    push @s, tri($points[ 27][0], $points[ 27][1],   28, 35);
    say STDERR "my \$LowerBodyBackTop  = ",  measure( 6, 44), ";";
    say STDERR "my \$LowerBodyFoot     = ",  measure(28, 29), ";";
   }
  
  push @s, qq(<rect x="0" y="0" width="100" height="100" stroke="green" fill='none'/>\n);
  push @s, "</svg>\n";                                                          # SVG footer
  owf(fpe(q(svg/xy), $file, q(svg)), join "\n", @s);                            # Write SVG file
   
  if (1)                                                                        # Write object file
   {my @o; 
    for my $p(@points)
     {push @o, "v $$p[0] $$p[1] $$p[2]";
     }
    for my $t(@triangles)
     {push @o, "f $$t[0] $$t[1] $$t[2]";
     }
  
    owf(fpe(q(obj), $file, q(obj)), join "\n", @o);                           
   }
 }

toSvg(q(back2));
toSvg(q(backBone));
toSvg(q(back));
toSvg(q(crossSection));
toSvg(q(foot1));
toSvg(q(foot2), 1);
toSvg(q(foot3));
toSvg(q(foot4));
toSvg(q(lowerBody)); 
