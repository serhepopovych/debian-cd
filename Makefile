#!/usr/bin/make -f

# Main Makefile for YACS
#
# Copyright 1999 Raphaël Hertzog <hertzog@debian.org>
# See the README file for the license

# The environment variables must have been set
# before. For this you can source the CONF.sh 
# file in your shell


## DEFAULT VALUES
ifndef VERBOSE_MAKE
Q=@
endif
ifndef SIZELIMIT
SIZELIMIT=$(shell echo -n $$[ 610 * 1024 * 1024 ])
endif
ifndef TASK
TASK=$(BASEDIR)/tasks/Debian_$(CODENAME)
endif
ifndef CAPCODENAME
CAPCODENAME:=$(shell perl -e "print ucfirst("$(CODENAME)")")
endif
ifndef BINDISKINFO
BINDISKINFO="Debian GNU/Linux $(DEBVERSION) \"$(CAPCODENAME)\" - $(OFFICIAL) $(ARCH) Binary-$$num ($$DATE)"
endif
ifndef SRCDISKINFO
SRCDISKINFO="Debian GNU/Linux $(DEBVERSION) \"$(CAPCODENAME)\" - $(OFFICIAL) Source-$$num ($$DATE)"
endif
# ND=No-Date versions for README
ifndef BINDISKINFOND
BINDISKINFOND="Debian GNU/Linux $(DEBVERSION) \"$(CAPCODENAME)\" - $(OFFICIAL) $(ARCH) Binary-$$num"
endif
ifndef SRCDISKINFOND
SRCDISKINFOND="Debian GNU/Linux $(DEBVERSION) \"$(CAPCODENAME)\" - $(OFFICIAL) Source-$$num"
endif
ifndef BINVOLID
ifeq ($(ARCH),powerpc)
BINVOLID="Debian $(DEBVERSION) ppc Bin-$$num"
else
BINVOLID="Debian $(DEBVERSION) $(ARCH) Bin-$$num"
endif
endif
ifndef SRCVOLID
SRCVOLID="Debian $(DEBVERSION) Src-$$num"
endif
ifndef MKISOFS
MKISOFS=/usr/bin/mkhybrid
endif
ifndef MKISOFS_OPTS
#For normal users
MKISOFS_OPTS=-a -r -T      
#For symlink farmers
#MKISOFS_OPTS=-a -r -F . -T  
endif
ifndef HOOK
HOOK=$(BASEDIR)/tools/$(CODENAME).hook
endif
ifndef BOOTDISKS
BOOTDISKS=$(MIRROR)/dists/$(CODENAME)/main/disks-$(ARCH)
endif

## Internal variables  
apt=$(BASEDIR)/tools/apt-selection
list2cds=$(BASEDIR)/tools/list2cds
cds2src=$(BASEDIR)/tools/cds2src
master2tasks=$(BASEDIR)/tools/master2tasks
mirrorcheck=$(BASEDIR)/tools/mirror_check
add_packages=$(BASEDIR)/tools/add_packages
add_dirs=$(BASEDIR)/tools/add_dirs
add_bin_doc=$(BASEDIR)/tools/add-bin-doc
scanpackages=$(BASEDIR)/tools/scanpackages
scansources=$(BASEDIR)/tools/scansources
add_files=$(BASEDIR)/tools/add_files
set_mkisofs_opts=$(BASEDIR)/tools/set_mkisofs_opts
strip_nonus_bin=$(BASEDIR)/tools/strip-nonUS-bin
add_secured=$(BASEDIR)/tools/add_secured

BDIR=$(TDIR)/$(CODENAME)-$(ARCH)
ADIR=$(APTTMP)/$(CODENAME)-$(ARCH)
SDIR=$(TDIR)/$(CODENAME)-src

FIRSTDISKS=CD1 
ifdef FORCENONUSONCD1
FIRSTDISKS=CD1 CD1_NONUS
forcenonusoncd1=1
else
forcenonusoncd1=0
endif

## DEBUG STUFF ##

PrintVars:
	@num=1; \
	DATE=`date +%Y%m%d` ; \
	echo BINDISKINFO: ; \
        echo $(BINDISKINFO) ; \
	echo SRCDISKINFO: ; \
        echo $(SRCDISKINFO) ; \
	echo BINDISKINFOND: ; \
        echo $(BINDISKINFOND) ; \
	echo SRCDISKINFOND: ; \
        echo $(SRCDISKINFOND) ; \
	echo BINVOLID: ; \
        echo $(BINVOLID) ; \
	echo SRCVOLID: ; \
        echo $(SRCVOLID) ; \

## CHECKS ##

# Basic checks in order to avoid problems
ok=true
ifndef TDIR
ok=false
endif
ifndef BASEDIR
ok=false
endif
ifndef MIRROR
ok=false
endif
ifndef ARCH
ok=false
endif
ifndef CODENAME
ok=false
endif
ifndef OUT
ok=false
endif
# Never use NONFREE and EXTRANONFREE at the same time
ifdef NONFREE
ifdef EXTRANONFREE
ok=false
endif
endif
# If we have FORCENONUSONCD1 set, we must also have NONUS set
ifdef FORCENONUSONCD1
ifndef NONUS
ok=false
endif
endif

default:
	@echo "Please refer to the README file for more information"
	@echo "about the different targets available."

ok:
	@$(ok) || (echo \
	 "ERROR: Bad configuration. Please edit CONF.sh and source it ..." \
	 && false)

## INITIALIZATION ##

# Creation of the directories needed
init: ok $(TDIR) $(BDIR) $(SDIR) $(ADIR)
$(TDIR):
	$(Q)mkdir -p $(TDIR)
$(BDIR):
	$(Q)mkdir -p $(BDIR)
$(SDIR):
	$(Q)mkdir -p $(SDIR)
$(ADIR):
	$(Q)mkdir -p $(ADIR)

## CLEANINGS ##

# CLeans the current arch tree (but not packages selection info)
clean: ok bin-clean src-clean
bin-clean:
	$(Q)-rm -rf $(BDIR)/CD[1234567890]
	$(Q)-rm -rf $(BDIR)/*_NONUS
	$(Q)-rm -f  $(BDIR)/packages-stamp $(BDIR)/bootable-stamp \
	         $(BDIR)/upgrade-stamp
src-clean:
	$(Q)-rm -rf $(SDIR)/CD[1234567890]
	$(Q)-rm -rf $(SDIR)/*_NONUS
	$(Q)-rm -rf $(SDIR)/sources-stamp

# Completely cleans the current arch tree
realclean: distclean
distclean: ok bin-distclean src-distclean
bin-distclean:
	$(Q)-rm -rf $(BDIR)
	$(Q)-rm -rf $(ADIR)
src-distclean:
	$(Q)-rm -rf $(SDIR)


## STATUS and APT ##

# Regenerate the status file with only packages that
# are of priority standard or higher
status: init $(ADIR)/status
$(ADIR)/status:
	@echo "Generating a fake status file for apt-get and apt-cache..."
	$(Q)zcat $(MIRROR)/dists/$(CODENAME)/main/binary-$(ARCH)/Packages.gz | \
	perl -000 -ne 's/^(Package: .*)$$/$$1\nStatus: install ok installed/m; \
	               print if (/^Priority: (required|important|standard)/m or \
		       /^Section: base/m);' \
	> $(ADIR)/status
	# Updating the apt database
	$(Q)$(apt) update
	#
	# Checking the consistence of the standard system
	# If this does fail, then launch make correctstatus
	#
	$(Q)$(apt) check || $(MAKE) correctstatus

# Only useful if the standard system is broken
# It tries to build a better status file with apt-get -f install
correctstatus: status apt-update
	# You may need to launch correctstatus more than one time
	# in order to correct all dependencies
	#
	# Removing packages from the system :
	$(Q)set -e; \
	for i in `$(apt) deselected -f install`; do \
		echo $$i; \
		perl -i -000 -ne "print unless /^Package: \Q$$i\E/m" \
		$(ADIR)/status; \
	done
	#
	# Adding packages to the system :
	$(Q)set -e; \
	for i in `$(apt) selected -f install`; do \
	  echo $$i; \
	  $(apt) cache dumpavail | perl -000 -ne \
	      "s/^(Package: .*)\$$/\$$1\nStatus: install ok installed/m; \
	       print if /^Package: \Q$$i\E\s*\$$/m;" \
	       >> $(ADIR)/status; \
	done
	#
	# Showing the output of apt-get check :
	$(Q)$(apt) check

apt-update: status
	@echo "Apt-get is updating his files ..."
	$(Q)$(apt) update


## GENERATING LISTS ##

# Deleting the list only
deletelist: ok
	$(Q)-rm $(BDIR)/rawlist
	$(Q)-rm $(BDIR)/list

# Generates the list of packages/files to put on each CD
list: bin-list src-list

# Generate the listing of binary packages
bin-list: ok apt-update genlist $(BDIR)/1.packages
$(BDIR)/1.packages:
	@echo "Dispatching the packages on all the CDs ..."
	$(Q)$(list2cds) $(BDIR)/list $(SIZELIMIT)
ifdef FORCENONUSONCD1
	$(Q)set -e; \
	 for file in $(BDIR)/*.packages; do \
	    newfile=$${file%%.packages}_NONUS.packages; \
	    cp $$file $$newfile; \
	    $(strip_nonus_bin) $$file $$file.tmp; \
	    if (cmp -s $$file $$file.tmp) ; then \
	        rm -f $$file.tmp $$newfile ; \
	    else \
	        echo Splitting non-US packages: $$file and $$newfile ; \
	        mv -f $$file.tmp $$file; \
	    fi ;\
	done
endif

# Generate the listing for sources CDs corresponding to the packages included
# in the binary set
src-list: bin-list $(SDIR)/1.sources
$(SDIR)/1.sources:
	@echo "Dispatching the sources on all the CDs ..."
	$(Q)$(cds2src) $(SIZELIMIT)
ifdef FORCENONUSONCD1
	$(Q)set -e; \
	 for file in $(SDIR)/*.sources; do \
	    newfile=$${file%%.sources}_NONUS.sources; \
	    cp $$file $$newfile; \
	    grep -v non-US $$file >$$file.tmp; \
	    if (cmp -s $$file $$file.tmp) ; then \
	        rm -f $$file.tmp $$newfile ; \
	    else \
	        echo Splitting non-US sources: $$file and $$newfile ; \
	        mv -f $$file.tmp $$file; \
	    fi ;\
	done
endif

# Generate the complete listing of packages from the task
# Build a nice list without doubles and without spaces
genlist: ok $(BDIR)/list
$(BDIR)/list: $(BDIR)/rawlist
	@echo "Generating the complete list of packages to be included ..."
	$(Q)perl -ne 'chomp; next if /^\s*$$/; \
	          print "$$_\n" if not $$seen{$$_}; $$seen{$$_}++;' \
		  $(BDIR)/rawlist \
		  > $(BDIR)/list

# Build the raw list (cpp output) with doubles and spaces
$(BDIR)/rawlist:
ifdef FORCENONUSONCD1
	$(Q)$(apt) cache dumpavail | \
		grep-dctrl -FSection -n -sPackage -e '^non-US' - | \
		sort | uniq > $(BDIR)/Debian_$(CODENAME)_nonUS
endif
	$(Q)perl -npe 's/\@ARCH\@/$(ARCH)/g' $(TASK) | \
	 cpp -nostdinc -nostdinc++ -P -undef -D ARCH=$(ARCH) -D ARCH_$(ARCH) \
	     -DFORCENONUSONCD1=$(forcenonusoncd1) \
	     -I $(BASEDIR)/tasks -I $(BDIR) - - >> $(BDIR)/rawlist

## DIRECTORIES && PACKAGES && INFOS ##

# Create all the needed directories for installing packages (plus the
# .disk directory)
tree: bin-tree src-tree
bin-tree: ok bin-list $(BDIR)/CD1/debian
$(BDIR)/CD1/debian:
	@echo "Adding the required directories to the binary CDs ..."
	$(Q)set -e; \
	 for i in $(BDIR)/*.packages; do \
		dir=$${i%%.packages}; \
		dir=$${dir##$(BDIR)/}; \
		dir=$(BDIR)/CD$$dir; \
		mkdir -p $$dir; \
		$(add_dirs) $$dir; \
	done

src-tree: ok src-list $(SDIR)/CD1/debian
$(SDIR)/CD1/debian:
	@echo "Adding the required directories to the source CDs ..."
	$(Q)set -e; \
	 for i in $(SDIR)/*.sources; do \
		dir=$${i%%.sources}; \
		dir=$${dir##$(SDIR)/}; \
		dir=$(SDIR)/CD$$dir; \
		mkdir -p $$dir; \
		$(add_dirs) $$dir; \
	done

# CD labels / volume ids / disk info
infos: bin-infos src-infos
bin-infos: bin-tree $(BDIR)/CD1/.disk/info
$(BDIR)/CD1/.disk/info:
	@echo "Generating the binary CD labels and their volume ids ..."
	$(Q)set -e; \
	 nb=`ls -l $(BDIR)/?.packages | wc -l | tr -d " "`; num=0;\
	 DATE=`date +%Y%m%d`; \
	for i in $(BDIR)/*.packages; do \
		num=$${i%%.packages}; num=$${num##$(BDIR)/}; \
		dir=$(BDIR)/CD$$num; \
		echo -n $(BINDISKINFO) | sed 's/_NONUS//g' > $$dir/.disk/info; \
		echo '#define DISKNAME ' $(BINDISKINFOND) | sed 's/_NONUS//g' \
					> $$dir/README.diskdefines; \
		echo '#define TYPE  binary' \
					>> $$dir/README.diskdefines; \
		echo '#define TYPEbinary  1' \
					>> $$dir/README.diskdefines; \
		echo '#define ARCH ' $(ARCH) \
					>> $$dir/README.diskdefines; \
		echo '#define ARCH'$(ARCH) ' 1' \
					>> $$dir/README.diskdefines; \
		echo '#define DISKNUM ' $$num | sed 's/_NONUS//g' \
					>> $$dir/README.diskdefines; \
		echo '#define DISKNUM'$$num ' 1' | sed 's/_NONUS//g' \
					>> $$dir/README.diskdefines; \
		echo '#define TOTALNUM ' $$nb \
					>> $$dir/README.diskdefines; \
		echo '#define TOTALNUM'$$nb ' 1' \
					>> $$dir/README.diskdefines; \
		echo -n $(BINVOLID) > $(BDIR)/$${num}.volid; \
		$(set_mkisofs_opts) bin $$num > $(BDIR)/$${num}.mkisofs_opts; \
	done
src-infos: src-tree $(SDIR)/CD1/.disk/info
$(SDIR)/CD1/.disk/info:
	@echo "Generating the source CD labels and their volume ids ..."
	$(Q)set -e; \
	 nb=`ls -l $(SDIR)/?.sources | wc -l | tr -d " "`; num=0;\
	 DATE=`date +%Y%m%d`; \
	for i in $(SDIR)/*.sources; do \
		num=$${i%%.sources}; num=$${num##$(SDIR)/}; \
		dir=$(SDIR)/CD$$num; \
		echo -n $(SRCDISKINFO) | sed 's/_NONUS//g' > $$dir/.disk/info; \
		echo '#define DISKNAME ' $(SRCDISKINFOND) | sed 's/_NONUS//g' \
					> $$dir/README.diskdefines; \
		echo '#define TYPE  source' \
					>> $$dir/README.diskdefines; \
		echo '#define TYPEsource  1' \
					>> $$dir/README.diskdefines; \
		echo '#define ARCH ' $(ARCH) \
					>> $$dir/README.diskdefines; \
		echo '#define ARCH'$(ARCH) ' 1' \
					>> $$dir/README.diskdefines; \
		echo '#define DISKNUM ' $$num | sed 's/_NONUS//g' \
					>> $$dir/README.diskdefines; \
		echo '#define DISKNUM'$$num ' 1' | sed 's/_NONUS//g' \
					>> $$dir/README.diskdefines; \
		echo '#define TOTALNUM ' $$nb \
					>> $$dir/README.diskdefines; \
		echo '#define TOTALNUM'$$nb ' 1' \
					>> $$dir/README.diskdefines; \
		echo -n $(SRCVOLID) > $(SDIR)/$${num}.volid; \
		$(set_mkisofs_opts) src $$num > $(SDIR)/$${num}.mkisofs_opts; \
	done

# Adding the deb files to the images
packages: bin-infos bin-list $(BDIR)/packages-stamp
$(BDIR)/packages-stamp:
	@echo "Adding the selected packages to each CD :"
	$(Q)set -e; \
	 for i in $(BDIR)/*.packages; do \
		dir=$${i%%.packages}; \
		n=$${dir##$(BDIR)/}; \
		dir=$(BDIR)/CD$$n; \
		echo "$$n ... "; \
	  	cat $$i | xargs -n 200 -r $(add_packages) $$dir; \
		if [ -x "$(HOOK)" ]; then \
		   cd $(BDIR) && $(HOOK) $$n before-scanpackages; \
		fi; \
		$(scanpackages) scan $$dir; \
		echo "done."; \
	done
	@#Now install the Packages and Packages.cd files
	$(Q)set -e; \
	 for i in $(BDIR)/*.packages; do \
		dir=$${i%%.packages}; \
		dir=$${dir##$(BDIR)/}; \
		dir=$(BDIR)/CD$$dir; \
		$(scanpackages) install $$dir; \
	done
	$(Q)touch $(BDIR)/packages-stamp

sources: src-infos src-list $(SDIR)/sources-stamp
$(SDIR)/sources-stamp:
	@echo "Adding the selected sources to each CD."
	$(Q)set -e; \
	 for i in $(SDIR)/*.sources; do \
		dir=$${i%%.sources}; \
		n=$${dir##$(SDIR)/}; \
		dir=$(SDIR)/CD$$n; \
		echo -n "$$n ... "; \
		echo -n "main ... "; \
		grep -vE "(non-US/|/local/)" $$i > $$i.main || true ; \
		if [ -s $$i.main ] ; then \
			cat $$i.main | xargs $(add_files) $$dir $(MIRROR); \
		fi ; \
		if [ -n "$(LOCAL)" ]; then \
			echo -n "local ... "; \
			grep "/local/" $$i > $$i.local || true ; \
			if [ -s $$i.local ] ; then \
				if [ -n "$(LOCALDEBS)" ] ; then \
					cat $$i.local | xargs $(add_files) \
						$$dir $(LOCALDEBS); \
			    else \
					cat $$i.local | xargs $(add_files) \
						$$dir $(MIRROR); \
				fi; \
		    fi; \
		fi; \
		if [ -n "$(NONUS)" ]; then \
			echo -n "non-US ... "; \
			grep "non-US/" $$i > $$i.nonus || true ; \
			if [ -s $$i.nonus ] ; then \
				cat $$i.nonus | xargs $(add_files) $$dir $(NONUS); \
			fi; \
		fi; \
		$(scansources) $$dir; \
		echo "done."; \
	done
	$(Q)touch $(SDIR)/sources-stamp

## BOOT & DOC & INSTALL ##

# Add everything that is needed to make the CDs bootable
bootable: ok disks installtools $(BDIR)/bootable-stamp
$(BDIR)/bootable-stamp:
	@echo "Making the binary CDs bootable ..."
	$(Q)set -e; \
	 for file in $(BDIR)/*.packages; do \
		dir=$${file%%.packages}; \
		n=$${dir##$(BDIR)/}; \
		dir=$(BDIR)/CD$$n; \
		if [ -f $(BASEDIR)/tools/boot/$(CODENAME)/boot-$(ARCH) ]; then \
			cd $(BDIR); \
			echo "Running tools/boot/$(CODENAME)/boot-$(ARCH) $$n $$dir" ; \
			$(BASEDIR)/tools/boot/$(CODENAME)/boot-$(ARCH) $$n $$dir; \
		else \
			echo "No script to make CDs bootable for $(ARCH) ..."; \
			exit 1; \
		fi; \
	done
	$(Q)touch $(BDIR)/bootable-stamp

# Add the doc files to the CDs and the Release-Notes and the
# Contents-$(ARCH).gz files
bin-doc: ok bin-infos $(BDIR)/CD1/doc
$(BDIR)/CD1/doc:
	@echo "Adding the documentation (bin) ..."
	$(Q)set -e; \
	 for DISK in $(FIRSTDISKS) ; do \
		$(add_files) $(BDIR)/$$DISK $(MIRROR) doc; \
	done
	@for DISK in $(FIRSTDISKS) ; do \
		mkdir $(BDIR)/$$DISK/doc/FAQ/html ; \
		cd $(BDIR)/$$DISK/doc/FAQ/html ; \
		tar xzvf ../debian-faq.html.tar.gz ; \
		rm -f ../debian-faq.html.tar.gz ; \
	done
	$(Q)$(add_bin_doc) # Common stuff for all disks

src-doc: ok src-infos $(SDIR)/CD1/README.html
$(SDIR)/CD1/README.html:
	@echo "Adding the documentation (src) ..."
	$(Q)set -e; \
	 for i in $(SDIR)/*.sources; do \
		dir=$${i%%.sources}; \
		dir=$${dir##$(SDIR)/}; \
		dir=$(SDIR)/CD$$dir; \
		cp -d $(MIRROR)/README* $$dir/; \
		rm -f $$dir/README $$dir/README.1ST \
			$$dir/README.CD-manufacture $$dir/README.multicd \
			$$dir/README.pgp ; \
		cpp -traditional -undef -P -C -Wall -nostdinc -I $$dir/ \
		    -D OUTPUTtext $(BASEDIR)/data/$(CODENAME)/README.html.in \
			| sed -e 's/%%.//g' > $$dir/README.html ; \
		lynx -dump -force_html $$dir/README.html | todos \
			> $$dir/README.txt ; \
		cpp -traditional -undef -P -C -Wall -nostdinc -I $$dir/ \
		    -D OUTPUThtml $(BASEDIR)/data/$(CODENAME)/README.html.in \
			| sed -e 's/%%.//g' > $$dir/README.html ; \
		rm -f $$dir/README.diskdefines ; \
		mkdir -p $$dir/pics ; \
		cp $(BASEDIR)/data/pics/*.* $$dir/pics/ ; \
	done

# Add the install stuff on the first CD
installtools: ok bin-doc disks $(BDIR)/CD1/tools
$(BDIR)/CD1/tools:
	@echo "Adding install tools and documentation ..."
	$(Q)set -e; \
	 for DISK in $(FIRSTDISKS) ; do \
		$(add_files) $(BDIR)/$$DISK $(MIRROR) tools ; \
		mkdir $(BDIR)/$$DISK/install ; \
		if [ -x "$(BASEDIR)/tools/$(CODENAME)/installtools.sh" ]; then \
			$(BASEDIR)/tools/$(CODENAME)/installtools.sh $(BDIR)/$$DISK ; \
		fi ; \
	done

# Add the disks-arch directories where needed
disks: ok bin-infos $(BDIR)/CD1/dists/$(CODENAME)/main/disks-$(ARCH)
$(BDIR)/CD1/dists/$(CODENAME)/main/disks-$(ARCH):
	@echo "Adding disks-$(ARCH) stuff ..."
	$(Q)set -e; \
	 for DISK in $(FIRSTDISKS) ; do \
		mkdir -p $(BDIR)/$$DISK/dists/$(CODENAME)/main/disks-$(ARCH) ; \
		$(add_files) \
	  	$(BDIR)/$$DISK/dists/$(CODENAME)/main/disks-$(ARCH) \
	  	$(BOOTDISKS) . ; \
		cd $(BDIR)/$$DISK/dists/$(CODENAME)/main/disks-$(ARCH); \
		if [ "$(SYMLINK)" != "" ]; then exit 0; fi; \
		if [ -L current ]; then \
			CURRENT_LINK=`ls -l current | awk '{print $$11}'`; \
			mv $$CURRENT_LINK .tmp_link; \
			rm -rf [0123456789]*; \
			mv .tmp_link $$CURRENT_LINK; \
		elif [ -d current ]; then \
			rm -rf [0123456789]*; \
		fi; \
	done

upgrade: ok bin-infos $(BDIR)/upgrade-stamp
$(BDIR)/upgrade-stamp:
	@echo "Trying to add upgrade* directories ..."
	$(Q)if [ -x "$(BASEDIR)/tools/$(CODENAME)/upgrade.sh" ]; then \
		$(BASEDIR)/tools/$(CODENAME)/upgrade.sh; \
	 fi
	$(Q)if [ -x "$(BASEDIR)/tools/$(CODENAME)/upgrade-$(ARCH).sh" ]; then \
		$(BASEDIR)/tools/$(CODENAME)/upgrade-$(ARCH).sh; \
	 fi
	$(Q)touch $(BDIR)/upgrade-stamp

## EXTRAS ##

# Launch the extras scripts correctly for customizing the CDs
extras: bin-extras
bin-extras: ok
	$(Q)if [ -z "$(DIR)" -o -z "$(CD)" -o -z "$(ROOTSRC)" ]; then \
	  echo "Give me more parameters (DIR, CD and ROOTSRC are required)."; \
	  false; \
	fi
	@echo "Adding dirs '$(DIR)' from '$(ROOTSRC)' to '$(BDIR)/CD$(CD)'" ...
	$(Q)$(add_files) $(BDIR)/CD$(CD) $(ROOTSRC) $(DIR)
src-extras:
	$(Q)if [ -z "$(DIR)" -o -z "$(CD)" -o -z "$(ROOTSRC)" ]; then \
	  echo "Give me more parameters (DIR, CD and ROOTSRC are required)."; \
	  false; \
	fi
	@echo "Adding dirs '$(DIR)' from '$(ROOTSRC)' to '$(SDIR)/CD$(CD)'" ...
	$(Q)$(add_files) $(SDIR)/CD$(CD) $(ROOTSRC) $(DIR)

## IMAGE BUILDING ##

# Get some size info about the build dirs
imagesinfo: bin-imagesinfo
bin-imagesinfo: ok
	$(Q)for i in $(BDIR)/*.packages; do \
		echo `du -sb $${i%%.packages}`; \
	done
src-imagesinfo: ok
	$(Q)for i in $(SDIR)/*.sources; do \
		echo `du -sb $${i%%.sources}`; \
	done

# Generate a md5sum.txt file listings all files on the CD
md5list: bin-md5list src-md5list
bin-md5list: ok packages bin-secured $(BDIR)/CD1/md5sum.txt
$(BDIR)/CD1/md5sum.txt:
	@echo "Generating md5sum of files from all the binary CDs ..."
	$(Q)set -e; \
	 for file in $(BDIR)/*.packages; do \
		dir=$${file%%.packages}; \
		n=$${dir##$(BDIR)/}; \
		dir=$(BDIR)/CD$$n; \
		test -x "$(HOOK)" && cd $(BDIR) && $(HOOK) $$n before-mkisofs; \
		cd $$dir; \
		find . -follow -type f | grep -v "\./md5sum" | grep -v \
		"dists/stable" | grep -v "dists/frozen" | \
		grep -v "dists/unstable" | xargs md5sum > md5sum.txt ; \
	done
src-md5list: ok sources src-secured $(SDIR)/CD1/md5sum.txt
$(SDIR)/CD1/md5sum.txt:
	@echo "Generating md5sum of files from all the source CDs ..."
	$(Q)set -e; \
	 for file in $(SDIR)/*.sources; do \
		dir=$${file%%.sources}; \
		dir=$${dir##$(SDIR)/}; \
		dir=$(SDIR)/CD$$dir; \
		cd $$dir; \
		find . -follow -type f | grep -v "\./md5sum" | grep -v \
		"dists/stable" | grep -v "dists/frozen" | \
		grep -v "dists/unstable" | xargs md5sum > md5sum.txt ; \
	done

# Generate $CODENAME-secured tree with Packages and Release(.gpg) files
# from the official tree
# Complete the Release file from the normal tree
secured: bin-secured src-secured
bin-secured: $(BDIR)/CD1/dists/$(CODENAME)-secured
$(BDIR)/CD1/dists/$(CODENAME)-secured:
	@echo "Generating $(CODENAME)-secured on all the binary CDs ..."
	$(Q)set -e; \
	 for file in $(BDIR)/*.packages; do \
		dir=$${file%%.packages}; \
		n=$${dir##$(BDIR)/}; \
		dir=$(BDIR)/CD$$n; \
		cd $$dir; \
		$(add_secured); \
	done
	
src-secured: $(SDIR)/CD1/dists/$(CODENAME)-secured
$(SDIR)/CD1/dists/$(CODENAME)-secured:
	@echo "Generating $(CODENAME)-secured on all the source CDs ..."
	$(Q)set -e; \
	 for file in $(SDIR)/*.sources; do \
		dir=$${file%%.sources}; \
		dir=$${dir##$(SDIR)/}; \
		dir=$(SDIR)/CD$$dir; \
		cd $$dir; \
		$(add_secured); \
	done


# Generates all the images
images: bin-images src-images
bin-images: ok bin-md5list $(OUT)
	@echo "Generating the binary iso images ..."
	$(Q)set -e; \
	 for file in $(BDIR)/*.packages; do \
		dir=$${file%%.packages}; \
		n=$${dir##$(BDIR)/}; \
		dir=$(BDIR)/CD$$n; \
		cd $$dir/..; \
		opts=`cat $(BDIR)/$$n.mkisofs_opts`; \
		volid=`cat $(BDIR)/$$n.volid`; \
		rm -f $(OUT)/$(CODENAME)-$(ARCH)-$$n.raw; \
		$(MKISOFS) $(MKISOFS_OPTS) -V "$$volid" \
		  -o $(OUT)/$(CODENAME)-$(ARCH)-$$n.raw $$opts CD$$n ; \
		if [ -f $(BASEDIR)/tools/boot/$(CODENAME)/post-boot-$(ARCH) ]; then \
			$(BASEDIR)/tools/boot/$(CODENAME)/post-boot-$(ARCH) $$n $$dir \
			 $(OUT)/$(CODENAME)-$(ARCH)-$$n.raw; \
		fi \
	done
src-images: ok src-md5list $(OUT)
	@echo "Generating the source iso images ..."
	$(Q)set -e; \
	 for file in $(SDIR)/*.sources; do \
		dir=$${file%%.sources}; \
		n=$${dir##$(SDIR)/}; \
		dir=$(SDIR)/CD$$n; \
		cd $$dir/..; \
		opts=`cat $(SDIR)/$$n.mkisofs_opts`; \
		volid=`cat $(SDIR)/$$n.volid`; \
		rm -f $(OUT)/$(CODENAME)-src-$$n.raw; \
		$(MKISOFS) $(MKISOFS_OPTS) -V "$$volid" \
		  -o $(OUT)/$(CODENAME)-src-$$n.raw $$opts CD$$n ; \
	done

# Generate the *.list files for the Pseudo Image Kit
pi-makelist:
	$(Q)set -e; \
	 cd $(OUT); for file in `find * -name \*.raw`; do \
		$(BASEDIR)/tools/pi-makelist \
			$$file > $${file%%.raw}.list; \
	done

# Generate only one image number $(CD)
image: bin-image
bin-image: ok bin-md5list $(OUT)
	@echo "Generating the binary iso image n°$(CD) ..."
	@test -n "$(CD)" || (echo "Give me a CD=<num> parameter !" && false)
	set -e; cd $(BDIR); opts=`cat $(CD).mkisofs_opts`; \
	 volid=`cat $(CD).volid`; rm -f $(OUT)/$(CODENAME)-$(ARCH)-$(CD).raw; \
	 $(MKISOFS) $(MKISOFS_OPTS) -V "$$volid" \
	  -o $(OUT)/$(CODENAME)-$(ARCH)-$(CD).raw $$opts CD$(CD); \
	 if [ -f $(BASEDIR)/tools/boot/$(CODENAME)/post-boot-$(ARCH) ]; then \
		$(BASEDIR)/tools/boot/$(CODENAME)/post-boot-$(ARCH) $$n $$dir \
		 $(OUT)/$(CODENAME)-$(ARCH)-$$n.raw; \
	 fi
src-image: ok src-md5list $(OUT)
	@echo "Generating the source iso image n°$(CD) ..."
	@test -n "$(CD)" || (echo "Give me a CD=<num> parameter !" && false)
	set -e; cd $(SDIR); opts=`cat $(CD).mkisofs_opts`; \
	 volid=`cat $(CD).volid`; rm -f $(OUT)/$(CODENAME)-src-$(CD).raw; \
         $(MKISOFS) $(MKISOFS_OPTS) -V "$$volid" \
	  -o $(OUT)/$(CODENAME)-src-$(CD).raw $$opts CD$(CD)


#Calculate the md5sums for the images
imagesums:
	$(Q)cd $(OUT); :> MD5SUMS; for file in `find * -name \*.raw`; do \
	      md5sum $$file >>MD5SUMS; \
	 done

## MISC TARGETS ##

tasks: ok $(BASEDIR)/data/$(CODENAME)/master
	$(master2tasks)

readme:
	sensible-pager $(BASEDIR)/README

conf:
	sensible-editor $(BASEDIR)/CONF.sh

mirrorcheck: ok apt-update
	$(Q)$(apt) cache dumpavail | $(mirrorcheck)

# Little trick to simplify things
official_images: bin-official_images src-official_images
bin-official_images: ok bootable upgrade bin-images
src-official_images: ok src-doc src-images

$(CODENAME)_status: ok init
	@echo "Using the provided status file for $(CODENAME)-$(ARCH) ..."
	$(Q)cp $(BASEDIR)/data/$(CODENAME)/status.$(ARCH) $(ADIR)/status \
	 2>/dev/null || $(MAKE) status || $(MAKE) correctstatus
