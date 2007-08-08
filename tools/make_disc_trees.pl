#!/usr/bin/perl -w
#
# make_disc_trees
#
# From the list of packages we have, lay out the CD trees

use strict;
use Digest::MD5;
use File::stat;
use File::Find;

my ($basedir, $mirror, $tdir, $codename, $archlist, $mkisofs, $maxcds, $extranonfree);
my $mkisofs_opts = "";
my $mkisofs_dirs = "";
my (@arches, @arches_nosrc, @overflowlist, @pkgs_added);
my (@exclude_packages, @unexclude_packages, @excluded_package_list);

undef @pkgs_added;
undef @exclude_packages;
undef @unexclude_packages;
undef @excluded_package_list;

$basedir = shift;
$mirror = shift;
$tdir = shift;
$codename = shift;
$archlist = shift;
$mkisofs = shift;

require "$basedir/tools/add_packages";

if (defined($ENV{'MAXCDS'})) {
	$maxcds = $ENV{'MAXCDS'};
} else {
	$maxcds = 0;
}

if (defined($ENV{'EXTRANONFREE'})) {
	$extranonfree = $ENV{'EXTRANONFREE'};
} else {
	$extranonfree = 0;
}
	
my $list = "$tdir/list";
my $list_ex = "$tdir/list.exclude";
my $bdir = "$tdir/$codename";
my $log = "$bdir/make_disc_tree.log";
open(LOG, ">> $log") || die ("Can't open logfile $log for writing: $!\n");

foreach my $arch (split(' ', $archlist)) {
	push(@arches, $arch);
	if (! ($arch eq "source")) {
		push(@arches_nosrc, $arch);
	}
}

my $disknum = 1;
my $max_done = 0;
my $size_check = "";

# Constants used for space calculations
my $MiB = 1048576;
my $MB = 1000000;
my $blocksize = 2048;
my ($maxdiskblocks, $diskdesc);
my $cddir;

my $disktype = $ENV{'DISKTYPE'};
my $size_swap_check;
my $hfs_extra = 0;
my $hfs_mult = 1;

# And count how many packages added since the last size check was done
# - the estimation code is getting very accurate, so let's reduce the
# number of times we fork mkisofs
my $count_since_last_check = 0;
my $size_check_period = 10;

my $pkgs_this_cd = 0;
my $pkgs_done = 0;
my $size = 0;
my $guess_size = 0;
my @overflowpkg;
my $mkisofs_check = "$mkisofs -r -print-size -quiet";
my $debootstrap_script = "";
if (defined ($ENV{'DEBOOTSTRAP_SCRIPT'})) {
	$debootstrap_script = $ENV{'DEBOOTSTRAP_SCRIPT'};
}

chdir $bdir;

# Size calculation is slightly complicated:
#
# 1. At the start, ask mkisofs for a size so far (including all the
#    stuff in the initial tree like docs and boot stuff
#
# 2. After that, add_packages will tell us the sizes of the files it
#    has added. This will not include directories / metadata so is
#    only a rough guess, but it's a _cheap_ guess
#
# 3. Once we get >90% of the max size we've been configured with,
#    start asking mkisofs after each package addition. This will
#    be slow, but we want to be exact at the end

$cddir = "$bdir/CD$disknum";
get_disc_size();
# Space calculation for extra HFS crap
if ($archlist =~ /m68k/ || $archlist =~ /powerpc/) {
    $hfs_mult = 1.2;
    $hfs_extra = int($maxdiskblocks * 8 / $blocksize);
    print LOG "arches require HFS hybrid, multiplying sizes by $hfs_mult and marking $hfs_extra blocks for HFS use\n";
}

print "Starting to lay out packages into $disktype ($diskdesc) images: $maxdiskblocks 2K-blocks maximum per image\n";

open(INLIST, "$bdir/packages") || die "No packages file!\n";
while (defined (my $pkg = <INLIST>)) {
	chomp $pkg;
	$cddir = "$bdir/CD$disknum";
	my $opt;
	if (! -d $cddir) {
		if (($maxcds > 0 ) && ($disknum > $maxcds)) {
			print LOG "Disk $disknum is beyond the configured MAXCDS of $maxcds; exiting now...\n";
			$max_done = 1;
			last;
		}
		print LOG "Starting new disc $disknum at " . `date` . "\n";

		start_disc();

		print "  Placing packages into image $disknum\n";
		if ( -e "$bdir/$disknum.mkisofs_opts" ) {
			open(OPTS, "<$bdir/$disknum.mkisofs_opts");
			while (defined($opt = <OPTS>)) {
				chomp $opt;
				$mkisofs_opts = "$mkisofs_opts $opt";
			}
			close(OPTS);
		} else {
			$mkisofs_opts = "";
		}
		if ( -e "$bdir/$disknum.mkisofs_dirs" ) {
			open(OPTS, "<$bdir/$disknum.mkisofs_dirs");
			while (defined($opt = <OPTS>)) {
				chomp $opt;
				$mkisofs_dirs = "$mkisofs_dirs $opt";
			}
			close(OPTS);
		} else {
			$mkisofs_dirs = "";
		}

		$size_check = "$mkisofs_check $mkisofs_opts $mkisofs_dirs";
		$size=`$size_check $cddir`;
		chomp $size;
		$size += $hfs_extra;
		print LOG "CD $disknum: size is $size before starting to add packages\n";

        $pkgs_this_cd = 0;

        # If we have some unexcludes for this disc and have already
        # previously excluded some packages, check now if the two
        # lists intersect and we should re-include some packages
        if (scalar @unexclude_packages && scalar @excluded_package_list) {
            foreach my $reinclude_pkg (@excluded_package_list) {
                my ($arch, $component, $pkgname) = split /:/, $reinclude_pkg;
                foreach my $entry (@unexclude_packages) {
                    if (($pkgname =~ /^\Q$entry\E$/m)) {
                        print LOG "Re-including $reinclude_pkg due to match on \"\^$entry\$\"\n";
                        $guess_size = int($hfs_mult * add_packages($cddir, $reinclude_pkg));
                        $size += $guess_size;
                        print LOG "CD $disknum: GUESS_TOTAL is $size after adding $reinclude_pkg\n";
                        $pkgs_this_cd++;
                        $pkgs_done++;                        
                    }
                }
            }
        }
		while (scalar @overflowlist) {
		    my $overflowpkg = pop @overflowlist;
		    print LOG "Adding a package that failed on the last disc: $overflowpkg\n";
		    $guess_size = int($hfs_mult * add_packages($cddir, $overflowpkg));
		    $size += $guess_size;
		    print LOG "CD $disknum: GUESS_TOTAL is $size after adding $overflowpkg\n";
		    $pkgs_this_cd++;
		    $pkgs_done++;
		}
    } # end of creating new CD dir

    if (should_exclude_package($pkg)) {
        push(@excluded_package_list, $pkg);
	} elsif (should_start_extra_nonfree($pkg)) {
		print LOG "Starting on extra non-free CDs\n";
		finish_disc($cddir, "");
		# And reset, to start the next disc
		$size = 0;
		$disknum++;
		undef(@pkgs_added);
		# Put this package first on the next disc
		push (@overflowlist, $pkg);
    } else {
        $guess_size = int($hfs_mult * add_packages($cddir, $pkg));
        $size += $guess_size;
		push (@pkgs_added, $pkg);
        print LOG "CD $disknum: GUESS_TOTAL is $size after adding $pkg\n";
        if (($size > $maxdiskblocks) ||
            (($size > $size_swap_check) &&
             ($count_since_last_check > $size_check_period))) {
            $count_since_last_check = 0;
            $size = `$size_check $cddir`;
            chomp $size;
            print LOG "CD $disknum: Real current size is $size blocks after adding $pkg\n";
        }
        if ($size > $maxdiskblocks) {
			while ($size > $maxdiskblocks) {
				$pkg = pop(@pkgs_added);
				print LOG "CD $disknum over-full ($size > $maxdiskblocks). Rollback!\n";
				$guess_size = int($hfs_mult * add_packages("--rollback", $cddir, $pkg));
				$size=`$size_check $cddir`;
				chomp $size;
				print LOG "CD $disknum: Real current size is $size blocks after rolling back $pkg\n";
				# Put this package first on the next disc
				push (@overflowlist, $pkg);
			}
            finish_disc($cddir, "");

            # And reset, to start the next disc
            $size = 0;
            $disknum++;
			undef(@pkgs_added);
        } else {
            $pkgs_this_cd++;
            $pkgs_done++;
            $count_since_last_check++;
        }	
    }
}
close(INLIST);

if ($max_done == 0) {
	finish_disc($cddir, " (not)");
}

print LOG "Finished: $pkgs_done packages placed\n";
print "Finished: $pkgs_done packages placed\n";
system("date >> $log");

close(LOG);

#############################################
#
#  Local helper functions
#
#############################################
sub should_start_extra_nonfree {
    my $pkg = shift;
    my ($arch, $component, $pkgname) = split /:/, $pkg;

	if ( ($component eq "non-free") && $extranonfree) {
		$extranonfree = 0; # Flag that we don't need to start new next time!
		return 1;
	}
	
	return 0;
}

sub should_exclude_package {
    my $pkg = shift;
    my ($arch, $component, $pkgname) = split /:/, $pkg;
    my $should_exclude = 0;

    foreach my $entry (@exclude_packages) {
	    if (($pkgname =~ /^\Q$entry\E$/m)) {
            print LOG "Excluding $pkg due to match on \"\^$entry\$\"\n";
            $should_exclude++;
        }
	}

    if ($should_exclude) {
        # Double-check that we're not being asked to include *and*
        # exclude the package at the same time. If so, complain and
        # bail out
        foreach my $entry (@unexclude_packages) {
            if (($pkgname =~ /^\Q$entry\E$/m)) {
                print LOG "But ALSO asked to unexclude $pkg due to match on \"\^$entry\$\"\n";
                print LOG "Make your mind up! Bailing out...\n";
                die "Incompatible exclude/unexclude entries for $pkg...\n";
            }
        }
        return 1;
    }
    return 0;
}

sub check_base_installable {
	my $arch = shift;
	my $cddir = shift;
	my $ok = 0;
	my (%on_disc, %exclude);
	my $packages_file = "$cddir/dists/$codename/main/binary-$arch/Packages";
	my $p;

	open (PLIST, $packages_file)
		|| die "Can't open Packages file $packages_file : $!\n";
	while (defined($p = <PLIST>)) {
		chomp $p;
		$p =~ m/^Package: (\S+)/ and $on_disc{$1} = $1;
	}
	close PLIST;

	if (defined($ENV{'BASE_EXCLUDE'})) {
		open (ELIST, $ENV{'BASE_EXCLUDE'})
			|| die "Can't open base_exclude file $ENV{'BASE_EXCLUDE'} : $!\n";
		while (defined($p = <ELIST>)) {
			chomp $p;
			$exclude{$p} = $p;
		}
		close ELIST;
	}
		
	open (DLIST, "debootstrap --arch $arch --print-debs $codename $tdir/debootstrap_tmp file:$mirror $debootstrap_script 2>/dev/null | tr ' ' '\n' |")
		 || die "Can't fork debootstrap : $!\n";
	while (defined($p = <DLIST>)) {
		chomp $p;
		if (length $p > 1) {
			if (!defined($on_disc{$p})) {
				if (defined($exclude{$p})) {
					print LOG "Missing debootstrap-required $p but included in $ENV{'BASE_EXCLUDE'}\n";
				} else {
					$ok++;
					print LOG "Missing debootstrap-required $p\n";
				}
			}
		}
	}
	close DLIST;
	system("rm -rf $tdir/debootstrap_tmp");
	return $ok;
}

sub md5_file {
	my $filename = shift;
	my ($md5, $st);

	open(MD5FILE, $filename) or die "Can't open '$filename': $!\n";
	binmode(MD5FILE);
	$md5 = Digest::MD5->new->addfile(*MD5FILE)->hexdigest;
	close(MD5FILE);
	$st = stat($filename) || die "Stat error on '$filename': $!\n";
	return ($md5, $st->size);
}

sub md5_files_for_release {
	my ($md5, $size, $filename);

	$filename = $File::Find::name;

	# Recompress the Packages and Sources files; workaround for bug
	# #402482
	if ($filename =~ m/\/.*\/(Packages|Sources)$/o) {
		system("gzip -9c < $_ >$_.gz");
	}

	if ($filename =~ m/\/.*\/(Packages|Sources|Release)/o) {
		$filename =~ s/^\.\///g;
		($md5, $size) = md5_file($_);
		printf RELEASE " %s %8d %s\n", $md5, $size, $filename;
	}
}	

sub md5_files_for_md5sum {
	my ($md5, $size, $filename);

	$filename = $File::Find::name;
	if (-f $_) {
		($md5, $size) = md5_file($_);
		printf MD5LIST "%s  %s\n", $md5, $filename;
	}
}

sub get_disc_size {
    my $hook;
    my $error = 0;
    my $reserved = 0;

    if (defined($ENV{'RESERVED_BLOCKS_HOOK'})) {
        $hook = $ENV{'RESERVED_BLOCKS_HOOK'};
        print "  Calling reserved_blocks hook: $hook\n";
        $reserved = `$hook $tdir $mirror $disknum $cddir \"$archlist\"`;
		chomp $reserved;
		if ($reserved eq "") {
			$reserved = 0;
		}
        print "  Reserving $reserved blocks on CD $disknum\n";
    }

    # Calculate the maximum number of 2K blocks in the output images
    if ($disktype eq "BC") {
        $maxdiskblocks = int(680 * $MB / $blocksize) - $reserved;
        $diskdesc = "businesscard";
    } elsif ($disktype eq "NETINST") {
        $maxdiskblocks = int(680 * $MB / $blocksize) - $reserved;
        $diskdesc = "netinst";
    } elsif ($disktype =~ /CD$/) {
        $maxdiskblocks = int(680 * $MB / $blocksize) - $reserved;
        $diskdesc = "650MiB CD";
    } elsif ($disktype eq "CD700") {
        $maxdiskblocks = int(737 * $MB / $blocksize) - $reserved;
        $diskdesc = "700MiB CD";
    } elsif ($disktype eq "DVD") {
        $maxdiskblocks = int(4700 * $MB / $blocksize) - $reserved;
        $diskdesc = "4.7GB CD";
    } elsif ($disktype eq "CUSTOM") {
        $maxdiskblocks = $ENV{'CUSTOMSIZE'}  - $reserved || 
            die "Need to specify a custom size for the CUSTOM disktype\n";
        $diskdesc = "User-supplied size";
    }

    $ENV{'MAXDISKBLOCKS'} = $maxdiskblocks;
    $ENV{'DISKDESC'} = $diskdesc;

    # How full should we let the disc get before we stop estimating and
    # start running mkisofs?
    $size_swap_check = $maxdiskblocks - (40 * $MB / $blocksize);
}

sub start_disc {
	my $error = 0;

	$error = system("$basedir/tools/start_new_disc $basedir $mirror $tdir $codename \"$archlist\" $disknum");
	if ($error != 0) {
		die "    Failed to start disc $disknum, error $error\n";
	}

	get_disc_size();

	# Grab all the early stuff, apart from dirs that will change later
	print "  Starting the md5sum.txt file\n";
	chdir $cddir;
	system("find . -type f | grep -v -e ^\./\.disk -e ^\./dists | xargs md5sum >> md5sum.txt");
	chdir $bdir;

	$mkisofs_opts = "";
	$mkisofs_dirs = "";

    undef @exclude_packages;
    undef @unexclude_packages;

    if (defined ($ENV{"EXCLUDE"})) {
        my $excl_file = $ENV{"EXCLUDE"};
        print LOG "Adding excludes from $excl_file\n";
        open (EXCLUDE_FILE, "< $excl_file") || die "Can't open exclude file $excl_file: $!\n";
        while (defined (my $excl_pkg = <EXCLUDE_FILE>)) {
            chomp $excl_pkg;
            push(@exclude_packages, $excl_pkg);
        }
        close (EXCLUDE_FILE);
    }
    if (defined ($ENV{"EXCLUDE$disknum"})) {
        my $excl_file = $ENV{"EXCLUDE$disknum"};
        print LOG "Adding excludes from $excl_file\n";
        open (EXCLUDE_FILE, "< $excl_file") || die "Can't open exclude file $excl_file: $!\n";
        while (defined (my $excl_pkg = <EXCLUDE_FILE>)) {
            chomp $excl_pkg;
            push(@exclude_packages, $excl_pkg);
        }
        close (EXCLUDE_FILE);
    }
    if (defined ($ENV{"UNEXCLUDE$disknum"})) {
        my $excl_file = $ENV{"UNEXCLUDE$disknum"};
        print LOG "Adding unexcludes from $excl_file\n";
        open (EXCLUDE_FILE, "< $excl_file") || die "Can't open unexclude file $excl_file: $!\n";
        while (defined (my $excl_pkg = <EXCLUDE_FILE>)) {
            chomp $excl_pkg;
            push(@unexclude_packages, $excl_pkg);
        }
        close (EXCLUDE_FILE);
    }
}

sub finish_disc {
	my $cddir = shift;
	my $not = shift;
	my $archok = 0;
	my $ok = 0;
	my $bytes = 0;
	my $ctx;
    my $hook;
	my $error = 0;

    if (defined($ENV{'DISC_FINISH_HOOK'})) {
        $hook = $ENV{'DISC_FINISH_HOOK'};
        print "  Calling disc_finish hook: $hook\n";
        $error = system("$hook $tdir $mirror $disknum $cddir \"$archlist\"");
		$error == 0 || die "DISC_FINISH_HOOK failed with error $error\n";
    }

	if (($disknum == 1) && !($archlist eq "source") && !($disktype eq "BC")) {
		foreach my $arch (@arches_nosrc) {
			print "  Checking base is installable for $arch\n";
			$archok = check_base_installable($arch, $cddir);
			if ($archok > 0) {
				print "    $arch is missing $archok files needed for debootstrap, look in $log for the list\n";
			}
			$ok += $archok;
		}
		if ($ok == 0) {
			system("touch $cddir/.disk/base_installable");
			print "  Found all files needed for debootstrap for all binary arches\n";
		} else {
			print "  $ok files missing for debootstrap, not creating base_installable\n";
			if ($disktype eq "BC") {
				print "  This is expected - building a BC\n";
			}
		}
	}

	chdir $cddir;

	print "  Finishing off the Release file\n";
	chdir "dists/$codename";
	open(RELEASE, ">>Release") || die "Failed to open Release file: $!\n";
	print RELEASE "MD5Sum:\n";
	find (\&md5_files_for_release, ".");
	close(RELEASE);
	chdir("../..");

	print "  Finishing off md5sum.txt\n";
	# Just md5 the bits we won't have seen already
	open(MD5LIST, ">>md5sum.txt") || die "Failed to open md5sum.txt file: $!\n";
	find (\&md5_files_for_md5sum, ("./.disk", "./dists"));
	close(MD5LIST);

	# And sort; it should make things faster for people checking
	# the md5sums, as ISO9660 dirs are sorted alphabetically
	system("LANG=C sort -uk2 md5sum.txt | grep -v \./md5sum.txt > md5sum.txt.tmp");
	system("mv -f md5sum.txt.tmp md5sum.txt");
	chdir $bdir;

    if (defined($ENV{'DISC_END_HOOK'})) {
        $hook = $ENV{'DISC_END_HOOK'};
        print "  Calling disc_end hook: $hook\n";
        $error = system("$hook $tdir $mirror $disknum $cddir \"$archlist\"");
		$error == 0 || die "DISC_END_HOOK failed with error $error\n";
    }

	$size = `$size_check $cddir`;
	chomp $size;
	$bytes = $size * $blocksize;
	print LOG "CD $disknum$not filled with $pkgs_this_cd packages, $size blocks, $bytes bytes\n";
	print "  CD $disknum$not filled with $pkgs_this_cd packages, $size blocks, $bytes bytes\n";
	system("date >> $log");
}
