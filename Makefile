#!/usr/bin/make -f

# Main Makefile for YACS
#
# Copyright 1999 Raphaël Hertzog <hertzog@debian.org>
# See the README file for the license

# The environment variables must have been set
# before. For this you can source the CONF.sh 
# file in your shell


## DEFAULT VALUES

ifndef SIZELIMIT
SIZELIMIT=$(shell echo -n $$[ 610 * 1024 * 1024 ])
endif
ifndef TASK
TASK=$(BASEDIR)/tasks/Debian_$(CODENAME)
endif
ifndef BINDISKINFO
BINDISKINFO="Debian GNU/Linux $(CODENAME) (unofficial) binary-$(ARCH) $$num/$$nb $$DATE"
endif
ifndef SRCDISKINFO
SRCDISKINFO="Debian GNU/Linux $(CODENAME) (unofficial) source $$num/$$nb $$DATE"
endif
ifndef BINVOLID
BINVOLID="Debian-$(ARCH) $(CODENAME) Disc $$num"
endif
ifndef SRCVOLID
SRCVOLID="Debian-src $(CODENAME) Disc $$num"
endif
ifndef MKISOFS
MKISOFS=/usr/bin/mkhybrid
endif
ifndef MKISOFS_OPTS
#For normal users
MKISOFS_OPTS=-a -r -T      
#For symlink farmers
#MKISOFS_OPTS=-a -r -F -T  
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
addpackages=$(BASEDIR)/tools/add_packages
adddirs=$(BASEDIR)/tools/add_dirs
scanpackages=$(BASEDIR)/tools/scanpackages
scansources=$(BASEDIR)/tools/scansources
addfiles=$(BASEDIR)/tools/add_files
set_mkisofs_opts=$(BASEDIR)/tools/set_mkisofs_opts

BDIR=$(TDIR)/$(CODENAME)-$(ARCH)
ADIR=$(APTTMP)/$(CODENAME)-$(ARCH)
SDIR=$(TDIR)/$(CODENAME)-src

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
	@mkdir -p $(TDIR)
$(BDIR):
	@mkdir -p $(BDIR)
$(SDIR):
	@mkdir -p $(SDIR)
$(ADIR):
	@mkdir -p $(ADIR)

## CLEANINGS ##

# CLeans the current arch tree (but not packages selection info)
clean: ok bin-clean src-clean
bin-clean:
	@-rm -rf $(BDIR)/[1234567890]
	@-rm -f  $(BDIR)/packages-stamp $(BDIR)/bootable-stamp \
	         $(BDIR)/upgrade-stamp
src-clean:
	@-rm -rf $(SDIR)/[1234567890]
	@-rm -rf $(SDIR)/sources-stamp

# Completely cleans the current arch tree
realclean: distclean
distclean: ok bin-distclean src-distclean
bin-distclean:
	@-rm -rf $(BDIR)
	@-rm -rf $(ADIR)
src-distclean:
	@-rm -rf $(SDIR)


## STATUS and APT ##

# Regenerate the status file with only packages that
# are of priority standard or higher
status: init $(ADIR)/status
$(ADIR)/status:
	@echo "Generating a fake status file for apt-get and apt-cache..."
	@zcat $(MIRROR)/dists/$(CODENAME)/main/binary-$(ARCH)/Packages.gz | \
	perl -000 -ne 's/^(Package: .*)$$/$$1\nStatus: install ok installed/m; \
	               print if (/^Priority: (required|important|standard)/m or \
		       /^Section: base/m);' \
	> $(ADIR)/status
	# Updating the apt database
	@$(apt) update
	#
	# Checking the consistence of the standard system
	# If this does fail, then launch make correctstatus
	#
	@$(apt) check || $(MAKE) correctstatus

# Only useful if the standard system is broken
# It tries to build a better status file with apt-get -f install
correctstatus: status apt-update
	# You may need to launch correctstatus more than one time
	# in order to correct all dependencies
	#
	# Removing packages from the system :
	@for i in `$(apt) deselected -f install`; do \
		echo $$i; \
		perl -i -000 -ne "print unless /^Package: \Q$$i\E/m" \
		$(ADIR)/status; \
	done
	#
	# Adding packages to the system :
	@for i in `$(apt) selected -f install`; do \
	  echo $$i; \
	  $(apt) cache dumpavail | perl -000 -ne \
	      "s/^(Package: .*)\$$/\$$1\nStatus: install ok installed/m; \
	       print if /^Package: \Q$$i\E\s*\$$/m;" \
	       >> $(ADIR)/status; \
	done
	#
	# Showing the output of apt-get check :
	@$(apt) check

apt-update: status
	@echo "Apt-get is updating his files ..."
	@$(apt) update


## GENERATING LISTS ##

# Deleting the list only
deletelist: ok
	@-rm $(BDIR)/rawlist
	@-rm $(BDIR)/list
	
# Generates the list of packages/files to put on each CD
list: bin-list src-list

# Generate the listing of binary packages
bin-list: ok apt-update genlist $(BDIR)/1.packages
$(BDIR)/1.packages:
	@echo "Dispatching the packages on all the CDs ..."
	@$(list2cds) $(BDIR)/list $(SIZELIMIT)
	
# Generate the listing for sources CDs corresponding to the packages included
# in the binary set
src-list: bin-list $(SDIR)/1.sources
$(SDIR)/1.sources:
	@echo "Dispatching the sources on all the CDs ..."
	@$(cds2src) $(SIZELIMIT)
	
# Generate the complete listing of packages from the task
# Build a nice list without doubles and without spaces
genlist: ok $(BDIR)/list
$(BDIR)/list: $(BDIR)/rawlist
	@echo "Generating the complete list of packages to be included ..."
	@perl -ne 'chomp; next if /^\s*$$/; \
	          print "$$_\n" if not $$seen{$$_}; $$seen{$$_}++;' \
		  $(BDIR)/rawlist \
		  > $(BDIR)/list

# Build the raw list (cpp output) with doubles and spaces
$(BDIR)/rawlist:
	@perl -npe 's/\@ARCH\@/$(ARCH)/g' $(TASK) | \
	 cpp -nostdinc -nostdinc++ -P -undef -D ARCH=$(ARCH) -D ARCH_$(ARCH) \
	     -I $(BASEDIR)/tasks - - >> $(BDIR)/rawlist


## DIRECTORIES && PACKAGES && INFOS ##

# Create all the needed directories for installing packages (plus the
# .disk directory)
tree: bin-tree src-tree
bin-tree: ok bin-list $(BDIR)/1/debian
$(BDIR)/1/debian:
	@echo "Adding the required directories to the binary CDs ..."
	@for i in $(BDIR)/*.packages; do \
		dir=$${i%%.packages}; \
		mkdir -p $$dir; \
		$(adddirs) $$dir; \
	done
src-tree: ok src-list $(SDIR)/1/debian
$(SDIR)/1/debian:
	@echo "Adding the required directories to the source CDs ..."
	@for i in $(SDIR)/*.sources; do \
		dir=$${i%%.sources}; \
		mkdir -p $$dir; \
		$(adddirs) $$dir; \
	done

# CD labels / volume ids / disk info
infos: bin-infos src-infos
bin-infos: bin-tree $(BDIR)/1/.disk/info
$(BDIR)/1/.disk/info:
	@echo "Generating the binary CD labels and their volume ids ..."
	@nb=`ls -l $(BDIR)/*.packages | wc -l | tr -d " "`; num=0;\
	 DATE=`date +%Y%m%d`; \
	for i in $(BDIR)/*.packages; do \
		num=$${i%%.packages}; num=$${num##$(BDIR)/}; \
		echo -n $(BINDISKINFO) > $(BDIR)/$$num/.disk/info; \
		echo -n $(BINVOLID) > $(BDIR)/$${num}.volid; \
		$(set_mkisofs_opts) bin $$num > $(BDIR)/$${num}.mkisofs_opts; \
	done
src-infos: src-tree $(SDIR)/1/.disk/info
$(SDIR)/1/.disk/info:
	@echo "Generating the source CD labels and their volume ids ..."
	@nb=`ls -l $(SDIR)/*.sources | wc -l | tr -d " "`; num=0;\
	 DATE=`date +%Y%m%d`; \
	for i in $(SDIR)/*.sources; do \
		num=$${i%%.sources}; num=$${num##$(SDIR)/}; \
		echo -n $(SRCDISKINFO) > $(SDIR)/$$num/.disk/info; \
		echo -n $(SRCVOLID) > $(SDIR)/$${num}.volid; \
		$(set_mkisofs_opts) src $$num > $(SDIR)/$${num}.mkisofs_opts; \
	done

# Adding the deb files to the images
packages: bin-infos bin-list $(BDIR)/packages-stamp
$(BDIR)/packages-stamp:
	@echo "Adding the selected packages to each CD :"
	@for i in $(BDIR)/*.packages; do \
		dir=$${i%%.packages}; \
		n=$${dir##$(BDIR)/}; \
		echo "$$n ... "; \
	  	cat $$i | xargs -n 200 -r $(addpackages) $$dir; \
		if [ -x "$(HOOK)" ]; then \
		   cd $(BDIR) && $(HOOK) $$n before-scanpackages; \
		fi; \
		$(scanpackages) scan $$dir; \
		echo "done."; \
	done
	@#Now install the Packages and Packages.cd files
	@for i in $(BDIR)/*.packages; do \
		dir=$${i%%.packages}; \
		$(scanpackages) install $$dir; \
	done
	@touch $(BDIR)/packages-stamp

sources: src-infos src-list $(SDIR)/sources-stamp
$(SDIR)/sources-stamp:
	@echo "Adding the selected sources to each CD."
	@for i in $(SDIR)/*.sources; do \
		dir=$${i%%.sources}; \
		n=$${dir##$(SDIR)/}; \
		echo -n "$$n ... "; \
		grep -v "non-US/" $$i | xargs $(addfiles) $$dir $(MIRROR); \
		if [ -n "$(NONUS)" ]; then \
			grep "non-US/" $$i | xargs $(addfiles) $$dir $(NONUS); \
		fi; \
		$(scansources) $$dir; \
		echo "done."; \
	done
	@touch $(SDIR)/sources-stamp

## BOOT & DOC & INSTALL ##

# Add everything that is needed to make the CDs bootable
bootable: ok disks installtools $(BDIR)/bootable-stamp
$(BDIR)/bootable-stamp:
	@echo "Making the binary CDs bootable ..."
	@for file in $(BDIR)/*.packages; do \
		dir=$${file%%.packages}; \
		n=$${dir##$(BDIR)/}; \
		if [ -f $(BASEDIR)/tools/boot/$(CODENAME)/boot-$(ARCH) ]; then \
			cd $(BDIR); \
			sh -c $(BASEDIR)/tools/boot/$(CODENAME)/boot-$(ARCH) $$n $$dir; \
		else \
			echo "No script to make CDs bootable for $(ARCH) ..."; \
			exit 1; \
		fi; \
	done
	@touch $(BDIR)/bootable-stamp

# Add the doc files to the CDs and the Release-Notes and the
# Contents-$(ARCH).gz files
doc: ok bin-infos $(BDIR)/1/doc
$(BDIR)/1/doc:
	@echo "Adding the documentation ..."
	@for i in $(BDIR)/*.packages; do \
		dir=$${i%%.packages}; \
		$(addfiles) $$dir $(MIRROR) doc; \
		cp -d $(MIRROR)/README* $$dir/; \
		if [ -e $(MIRROR)/dists/$(CODENAME)/main/Release-Notes ]; then \
		   cp $(MIRROR)/dists/$(CODENAME)/main/Release-Notes $$dir/; \
		fi; \
		cp $(MIRROR)/dists/$(CODENAME)/Contents-$(ARCH).gz \
		   $$dir/dists/$(CODENAME)/; \
		if [ -n "$(NONUS)" ]; then \
		   cp $(NONUS)/dists/$(CODENAME)/non-US/Contents-$(ARCH).gz \
		      $$dir/dists/$(CODENAME)/non-US/; \
		fi; \
		if [ -e $(BASEDIR)/data/$(CODENAME)/README.$(ARCH) ]; then \
		   cp $(BASEDIR)/data/$(CODENAME)/README.$(ARCH) $$dir/; \
		fi; \
		echo "This disc is labelled :" > $$dir/README.1ST; \
		cat $$dir/.disk/info >>$$dir/README.1ST; \
		echo -e "\n\n" >>$$dir/README.1ST; \
		if [ -e $(BASEDIR)/data/$(CODENAME)/README.1ST.$(ARCH) ]; then \
		   cat $(BASEDIR)/data/$(CODENAME)/README.1ST.$(ARCH) \
                    >> $$dir/README.1ST; \
		fi; \
		todos $$dir/README.1ST; \
		if [ -e $(BASEDIR)/data/$(CODENAME)/README.multicd ]; then \
		   cp $(BASEDIR)/data/$(CODENAME)/README.multicd $$dir/; \
		fi; \
	done
	
	

# Add the install stuff on the first CD
installtools: ok doc disks $(BDIR)/1/tools
$(BDIR)/1/tools:
	@echo "Adding install tools and documentation ..."
	@$(addfiles) $(BDIR)/1 $(MIRROR) tools
	@mkdir $(BDIR)/1/install
	@if [ -x "$(BASEDIR)/tools/$(CODENAME)/installtools.sh" ]; then \
		$(BASEDIR)/tools/$(CODENAME)/installtools.sh; \
	 fi

# Add the disks-arch directories where needed
disks: ok bin-infos $(BDIR)/1/dists/$(CODENAME)/main/disks-$(ARCH)
$(BDIR)/1/dists/$(CODENAME)/main/disks-$(ARCH):
	@echo "Adding disks-$(ARCH) stuff ..."
	@mkdir -p \
	    $(BDIR)/1/dists/$(CODENAME)/main/disks-$(ARCH)
	@$(addfiles) \
	  $(BDIR)/1/dists/$(CODENAME)/main/disks-$(ARCH) \
	  $(BOOTDISKS) .
	@#Keep only one copy of the disks stuff
	@cd $(BDIR)/1/dists/$(CODENAME)/main/disks-$(ARCH); \
	if [ "$(SYMLINK)" != "" ]; then exit 0; fi; \
	if [ -L current ]; then \
		CURRENT_LINK=`ls -l current | awk '{print $$11}'`; \
		mv $$CURRENT_LINK .tmp_link; \
		rm -rf [0123456789]*; \
 		mv .tmp_link $$CURRENT_LINK; \
	elif [ -d current ]; then \
		rm -rf [0123456789]*; \
	fi;

upgrade: ok bin-infos $(BDIR)/upgrade-stamp
$(BDIR)/upgrade-stamp:
	@echo "Trying to add upgrade* directories ..."
	@if [ -x "$(BASEDIR)/tools/$(CODENAME)/upgrade.sh" ]; then \
		$(BASEDIR)/tools/$(CODENAME)/upgrade.sh; \
	 fi
	@touch $(BDIR)/upgrade-stamp

## EXTRAS ##

# Launch the extras scripts correctly for customizing the CDs
extras: bin-extras
bin-extras: ok
	@if [ -z "$(DIR)" -o -z "$(CD)" -o -z "$(ROOTSRC)" ]; then \
	  echo "Give me more parameters (DIR, CD and ROOTSRC are required)."; \
	  false; \
	fi
	@echo "Adding dirs '$(DIR)' from '$(ROOTSRC)' to '$(BDIR)/$(CD)'" ...
	@$(addfiles) $(BDIR)/$(CD) $(ROOTSRC) $(DIR)
src-extras:
	@if [ -z "$(DIR)" -o -z "$(CD)" -o -z "$(ROOTSRC)" ]; then \
	  echo "Give me more parameters (DIR, CD and ROOTSRC are required)."; \
	  false; \
	fi
	@echo "Adding dirs '$(DIR)' from '$(ROOTSRC)' to '$(SDIR)/$(CD)'" ...
	@$(addfiles) $(SDIR)/$(CD) $(ROOTSRC) $(DIR)

## IMAGE BUILDING ##

# Get some size info about the build dirs
imagesinfo: bin-imagesinfo
bin-imagesinfo: ok
	@for i in $(BDIR)/*.packages; do \
		echo `du -sb $${i%%.packages}`; \
	done
src-imagesinfo: ok
	@for i in $(SDIR)/*.sources; do \
		echo `du -sb $${i%%.sources}`; \
	done

# Generate a md5sum.txt file listings all files on the CD
md5list: bin-md5list src-md5list
bin-md5list: ok packages $(BDIR)/1/md5sum.txt
$(BDIR)/1/md5sum.txt:
	@echo "Generating md5sum of files from all the binary CDs ..."
	@for file in $(BDIR)/*.packages; do \
		dir=$${file%%.packages}; \
		n=$${dir##$(BDIR)/}; \
		test -x "$(HOOK)" && cd $(BDIR) && $(HOOK) $$n before-mkisofs; \
		cd $$dir; \
		find . -follow -type f | grep -v "\./md5sum" | grep -v \
		"dists/stable" | grep -v "dists/frozen" | \
		grep -v "dists/unstable" | xargs md5sum > md5sum.txt ; \
	done
src-md5list: ok sources $(SDIR)/1/md5sum.txt
$(SDIR)/1/md5sum.txt:
	@echo "Generating md5sum of files from all the source CDs ..."
	@for file in $(SDIR)/*.sources; do \
		dir=$${file%%.sources}; \
		cd $$dir; \
		find . -follow -type f | grep -v "\./md5sum" | grep -v \
		"dists/stable" | grep -v "dists/frozen" | \
		grep -v "dists/unstable" | xargs md5sum > md5sum.txt ; \
	done

# Generates all the images
images: bin-images src-images
bin-images: ok bin-md5list $(OUT)
	@echo "Generating the binary iso images ..."
	@for file in $(BDIR)/*.packages; do \
		dir=$${file%%.packages}; \
		n=$${dir##$(BDIR)/}; \
		cd $$dir/..; \
		opts=`cat $$dir.mkisofs_opts`; \
		volid=`cat $$dir.volid`; \
		rm -f $(OUT)/$(CODENAME)-$(ARCH)-$$n.raw; \
		$(MKISOFS) $(MKISOFS_OPTS) -V "$$volid" \
		  -o $(OUT)/$(CODENAME)-$(ARCH)-$$n.raw $$opts $$n ; \
	done
src-images: ok src-md5list $(OUT)
	@echo "Generating the source iso images ..."
	@for file in $(SDIR)/*.sources; do \
		dir=$${file%%.sources}; \
		n=$${dir##$(SDIR)/}; \
		cd $$dir/..; \
		opts=`cat $$dir.mkisofs_opts`; \
		volid=`cat $$dir.volid`; \
		rm -f $(OUT)/$(CODENAME)-src-$$n.raw; \
		$(MKISOFS) $(MKISOFS_OPTS) -V "$$volid" \
		  -o $(OUT)/$(CODENAME)-src-$$n.raw $$opts $$n ; \
	done

# Generate the *.list files for the Pseudo Image Kit
pi-makelist:
	@for file in $(OUT)/$(CODENAME)-*.raw; do \
		$(BASEDIR)/tools/pi-makelist \
			$$file > $${file%%.raw}.list; \
	done

# Generate only one image number $(CD)
image: bin-image
bin-image: ok bin-md5list $(OUT)
	@echo "Generating the binary iso image n°$(CD) ..."
	@test -n "$(CD)" || (echo "Give me a CD=<num> parameter !" && false)
	@dir=$(BDIR)/$(CD); cd $(BDIR); opts=`cat $$dir.mkisofs_opts`; \
	 volid=`cat $$dir.volid`; rm -f $(OUT)/$(CODENAME)-$(ARCH)-$(CD).raw; \
	  $(MKISOFS) $(MKISOFS_OPTS) -V "$$volid" \
	  -o $(OUT)/$(CODENAME)-$(ARCH)-$(CD).raw $$opts $(CD)
src-image: ok src-md5list $(OUT)
	@echo "Generating the source iso image n°$(CD) ..."
	@test -n "$(CD)" || (echo "Give me a CD=<num> parameter !" && false)
	@dir=$(SDIR)/$(CD); cd $(SDIR); opts=`cat $$dir.mkisofs_opts`; \
	 volid=`cat $$dir.volid`; rm -f $(OUT)/$(CODENAME)-src-$(CD).raw; \
         $(MKISOFS) $(MKISOFS_OPTS) -V "$$volid" \
	  -o $(OUT)/$(CODENAME)-src-$(CD).raw $$opts $(CD)


#Calculate the md5sums for the images
imagesums:
	@cd $(OUT); :> MD5SUMS; for file in *.raw; do \
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
	@$(apt) cache dumpavail | $(mirrorcheck)

# Little trick to simplify things
official_images: bin-official_images src-official_images
bin-official_images: ok bootable upgrade bin-images
src-official_images: ok src-images

$(CODENAME)_status: ok init
	@echo "Using the provided status file for $(CODENAME)-$(ARCH) ..."
	@cp $(BASEDIR)/data/$(CODENAME)/status.$(ARCH) $(ADIR)/status \
	 2>/dev/null || $(MAKE) status || $(MAKE) correctstatus
