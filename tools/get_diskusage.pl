#!/usr/bin/perl
#
# Author: Petter Reinholdtsen <pere@hungry.com>
# Date:   2001-11-20
#
# Parse logfile from Debian debian-cd build, and report how much each package
# added to the CD size.

use warnings;
use strict;
use Text::Format; # From debian package libtext-format-perl
use Getopt::Std;

my %opts;
getopts('t', \%opts); 

my $logfile = ($ARGV[0] ||
            "/skolelinux/developer/local0/ftp/tmp/woody-i386/log.list2cds");
my $cdlimit = ($ARGV[1] || 1) + 1;

open(LOG, $logfile) || die "Unable to open $logfile";


my $text = Text::Format->new(leftMargin   =>   16,
			     rightMargin  =>   0,
			     firstIndent  => 0);
my $curcd = 1;
my $pkg;
my @order;
my %cdsize;
my %size;
my %deps;
my $curcdsize;
my $cursize;
while (<LOG>) {
    chomp;
#    $pkg = $1 if (/^\+ Trying to add (.+)\.\.\./);
    if (/  \$cd_size = (\d+), \$size = (\d+)/) {
	$curcdsize = $1;
	$cursize = $2;
    }
    if (/^  Adding (.+) to CD \d+/) {
	my ($pkg, $deplist) = split(/\s+/, $1, 2);
	$cdsize{$pkg} = $curcdsize;
	$size{$pkg} = $cursize;
	push @order, $pkg;
	$deps{$pkg} = $deplist;
    }
    if (/Limit for CD (.+) is/) {
	last  if $cdlimit == $1;
	my $txt = "<=============== start of CD $1";
        $size{$txt} = 0;
        $cdsize{$txt} = 0;
	push @order, $txt;
    }
    # Add delimiter
    if (/Standard system already takes (.\d+)/) {
	my $txt = "<=============== end of standard pkgs";
        $size{$txt} = 0;
        $cdsize{$txt} = $1;
	push @order, $txt;
    }
}
close(LOG);

print "  +size  cdsize pkgname\n";
print "-----------------------\n";

for $pkg (@order) {
    printf "%7d %7d %s\n", $size{$pkg} / 1024, $cdsize{$pkg} / 1024, $pkg;
    print $text->format($deps{$pkg}) if ($opts{'t'} && $deps{$pkg});
}
