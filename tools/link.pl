#!/usr/bin/perl -w

use strict;

my $symlink_farm = $ENV{'SYMLINK'} || 0;
my $link_verbose = $ENV{'VERBOSE'} || 0;

sub good_link ($$) {
	my ($src, $dest) = @_;

	# Check if the destination directory does exist
	my $ddir = $dest;
	$ddir =~ s#/?[^/]+$##g;
	if ($ddir eq "") 
	{
		$ddir = ".";
	}
	if (! -d $ddir) # Create it if not
	{
		system("mkdir -p $ddir");
	}
	# Link the files
	if ($symlink_farm) {
		print "Symlink: $dest => $src\n" if ($link_verbose >= 3);
		if (not symlink ($src, $dest)) {
			print STDERR "Symlink from $src to $dest failed: $!\n";
		}
	} else {
		print "Harlink: $dest => $src\n" if ($link_verbose >= 3);
		if (not link ($src, $dest)) {
			print STDERR "Link from $src to $dest failed: $!\n";
		}
	}
}

sub real_file ($) {
	my $link = shift;
	my ($dir, $to);
	
	while (-l $link) {
		$dir = $link;
		$dir =~ s#[^/]+/?$##;
		if ($to = readlink($link)) {
			$link = $dir . $to;
		} else {
			print STDERR "Can't readlink $link: $!\n";
		}
	}

	return $link;
}


1;
