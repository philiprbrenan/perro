#!/usr/bin/perl -I/home/phil/perl/cpan/DataTableText/lib/
#-------------------------------------------------------------------------------
# Get the coordinates of a shape in an image
# Philip R Brenan at appaapps dot com, Appa Apps Ltd Inc., 2023
#-------------------------------------------------------------------------------
use v5.30;
use warnings FATAL => qw(all);
use strict;
use Carp;
use Data::Dump qw(dump);
use Data::Table::Text qw(:all);
use Tk;
use Tk::PNG;

my $in         = qq(back2);                                                      # Image to process             
my $file       = fpe q(images3), $in, q(png);                                   # Image to process             
my $click_file = fpe "coordinates2", $in, "txt";                                # Coordinates

my $mw = MainWindow->new;
$mw->title("Image Clicker");

my $canvas = $mw->Canvas(-width => 3500, -height => 2000)->pack;
my $image  = $mw->Photo (-file  => $file);
$canvas->createImage(0, 0, -image => $image, -anchor => 'nw');

my $cross_length = 10;

$canvas->bind('all', '<ButtonPress>', [sub {
    my ($event, $x, $y) = (@_);    

    open(my $fh, '>>', $click_file) or die "Cannot open $click_file: $!";
    print $fh fn($file), " ($x, $y)\n";
    close($fh);

    # Draw a cross at the clicked point
    $canvas->createLine(
        $x - $cross_length, $y,
        $x + $cross_length, $y,
        -fill => 'red',
    );
    $canvas->createLine(
        $x, $y - $cross_length,
        $x, $y + $cross_length,
        -fill => 'red',
    );
}, Ev("%x"), Ev("%y")]);

MainLoop;
