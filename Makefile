#!/usr/bin/make -f

# Main Makefile for debian-cd
#
# Copyright 1999 Raphaël Hertzog <hertzog@debian.org>
# See the README file for the license
#
# Significantly modified 2005-2006 Steve McIntyre <93sam@debian.org>
# for multi-arch and mixed bin/src discs
#
# The environment variables must have been set
# before. For this you can source the CONF.sh 
# file in your shell


## DEFAULT VALUES
ifndef VERBOSE_MAKE
Q=@
endif
ifndef SIZELIMIT
SIZELIMIT=2000000000000
endif
ifndef TASK
TASK=$(BASEDIR)/tasks/Debian_$(CODENAME)
endif
ifndef MKISOFS
export MKISOFS=mkisofs
endif
ifndef MKISOFS_OPTS
#For normal users
MKISOFS_OPTS=-r
#For symlink farmers
#MKISOFS_OPTS=-r -F .
endif
ifndef HOOK
HOOK=$(BASEDIR)/tools/$(CODENAME).hook
endif
ifndef DOJIGDO
export DOJIGDO=0
endif

export BUILD_DATE=$(shell date -u +%Y%m%d-%H:%M)
export ARCHES_NOSRC=$(shell echo $(ARCHES) | sed 's/source//')
ifeq ($(ARCHES),source)
	export SOURCEONLY=yes
endif
ifeq ($(shell echo $(ARCHES) | sed 's/.*source.*/1/'),1)
	export INC_SOURCE=yes
endif

## Internal variables  
apt=$(BASEDIR)/tools/apt-selection
list2cds=$(BASEDIR)/tools/list2cds
md5sum=md5sum
jigdo_cleanup=$(BASEDIR)/tools/jigdo_cleanup
grab_md5=$(BASEDIR)/tools/grab_md5
make_image=$(BASEDIR)/tools/make_image
merge_package_lists=$(BASEDIR)/tools/merge_package_lists
update_popcon=$(BASEDIR)/tools/update_popcon

BDIR=$(TDIR)/$(CODENAME)
ADIR=$(APTTMP)
DB_DIR=$(BDIR)/debootstrap

FIRSTDISKS=CD1 

export PATH := $(DB_DIR)/usr/sbin:$(PATH)
export DEBOOTSTRAP_DIR := $(DB_DIR)/usr/lib/debootstrap

LATEST_DB := $(shell ls -1tr $(MIRROR)/pool/main/d/debootstrap/debootstrap*all.deb | tail -1)

## DEBUG STUFF ##

PrintVars:
	@num=1; \
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

default:
	@echo "Please refer to the README file for more information"
	@echo "about the different targets available."

## CHECKS ##

# Basic checks in order to avoid problems
ok:
ifndef TDIR
	@echo TDIR undefined -- set up CONF.sh; false
endif
ifndef BASEDIR
	@echo BASEDIR undefined -- set up CONF.sh; false
endif
ifndef MIRROR
	@echo MIRROR undefined -- set up CONF.sh; false
endif
ifndef ARCHES
	@echo ARCHES undefined -- set up CONF.sh; false
endif
ifndef CODENAME
	@echo CODENAME undefined -- set up CONF.sh; false
endif
ifndef OUT
	@echo OUT undefined -- set up CONF.sh; false
endif
ifdef NONFREE
ifdef EXTRANONFREE
	@echo Never use NONFREE and EXTRANONFREE at the same time; false
endif
endif
	@if [ $(DISKTYPE) = "NETINST" -o $(DISKTYPE) = "BC" ] ; then \
		if [ "$(INC_SOURCE)"x = "yes"x ] ; then \
			echo "Including source is not supported on a netinst/bc CD"; \
			false; \
		fi; \
	fi

## INITIALIZATION ##

# Creation of the directories needed
init: ok $(OUT) $(TDIR) $(BDIR) $(ADIR) $(BDIR)/DATE $(DB_DIR) unstable-map
$(OUT):
	$(Q)mkdir -p $(OUT)
$(TDIR):
	$(Q)mkdir -p $(TDIR)
$(BDIR):
	$(Q)mkdir -p $(BDIR)
$(ADIR):
	$(Q)mkdir -p $(ADIR)
$(BDIR)/DATE:
	$(Q)date '+%Y%m%d' > $(BDIR)/DATE
$(DB_DIR): $(LATEST_DB)
	@rm -rf $(DB_DIR)
	@dpkg -x $(LATEST_DB) $(DB_DIR)
# Make sure unstable/sid points to testing/etch, as there is no build
# rule for unstable/sid.
unstable-map:
	$(Q)if [ ! -d $(BASEDIR)/data/sid ] ; then \
		ln -s etch $(BASEDIR)/data/sid ; \
	fi
	$(Q)if [ ! -d $(BASEDIR)/tools/boot/sid ] ; then \
		ln -s etch $(BASEDIR)/tools/boot/sid ; \
	fi

#################
## CLEAN RULES ##
#################

# Cleans the current arch tree (but not packages selection info)
clean: ok dir-clean
dir-clean:
	$(Q)rm -rf $(BDIR)/CD[1234567890]*
	$(Q)rm -f $(BDIR)/*.filelist*
	$(Q)rm -f  $(BDIR)/packages-stamp $(BDIR)/upgrade-stamp $(BDIR)/md5-check

# Completely cleans the current arch tree
realclean: distclean
distclean: ok clean
	$(Q)echo "Cleaning the build directory"
	$(Q)rm -rf $(ADIR)
	$(Q)rm -rf $(TDIR)

####################
## STATUS and APT ##
####################

# Regenerate the status file with only packages that
# are of priority standard or higher
status: init $(ADIR)/status
$(ADIR)/status:
	@echo "Generating a fake status file for apt-get and apt-cache..."
	$(Q)for ARCH in $(ARCHES); do \
		mkdir -p $(ADIR)/$(CODENAME)-$$ARCH; \
		if [ $$ARCH = "source" -o "$(INSTALLER_CD)" = "1" -o "$(INSTALLER_CD)" = "2" ];then \
			:> $(ADIR)/$(CODENAME)-$$ARCH/status ; \
		else \
			zcat $(MIRROR)/dists/$(CODENAME)/main/binary-$$ARCH/Packages.gz | \
			perl -000 -ne 's/^(Package: .*)$$/$$1\nStatus: install ok installed/m; print if (/^Priority: (required|important|standard)/m or /^Section: base/m);' \
			>> $(ADIR)/$(CODENAME)-$$ARCH/status ; \
		fi; \
	done;
	:> $(ADIR)/status
    # Updating the apt database
	$(Q)for ARCH in $(ARCHES); do \
		export ARCH=$$ARCH; \
		$(apt) update; \
	done
    #
    # Checking the consistency of the standard system
    # If this does fail, then launch make correctstatus
    #
	$(Q)for ARCH in $(ARCHES); do \
		export ARCH=$$ARCH; \
		$(apt) check || $(MAKE) correctstatus; \
	done

# Only useful if the standard system is broken
# It tries to build a better status file with apt-get -f install
correctstatus: status apt-update
    # You may need to launch correctstatus more than one time
    # in order to correct all dependencies
    #
    # Removing packages from the system :
	$(Q)set -e; \
	if [ "$(ARCHES)" != "source" ] ; then \
		for ARCH in $(ARCHES_NOSRC); do \
			export ARCH=$$ARCH; \
			for i in `$(apt) deselected -f install`; do \
				echo $$ARCH:$$i; \
				perl -i -000 -ne "print unless /^Package: \Q$$i\E/m" \
				$(ADIR)/$(CODENAME)-$$ARCH/status; \
			done; \
		done; \
    fi
    #
    # Adding packages to the system :
	$(Q)set -e; \
	if [ "$(ARCHES)" != "source" ] ; then \
		for ARCH in $(ARCHES_NOSRC); do \
			export ARCH=$$ARCH; \
			for i in `$(apt) selected -f install`; do \
				echo $$ARCH:$$i; \
				$(apt) cache dumpavail | perl -000 -ne \
				"s/^(Package: .*)\$$/\$$1\nStatus: install ok installed/m; \
				print if /^Package: \Q$$i\E\s*\$$/m;" \
				>> $(ADIR)/$(CODENAME)-$$ARCH/status; \
			done; \
		done; \
    fi
    #
    # Showing the output of apt-get check :
	$(Q)for ARCH in $(ARCHES_NOSRC); do \
		ARCH=$$ARCH $(apt) check; \
	done

apt-update: status
	$(Q)if [ "$(ARCHES)" != "source" ] ; then \
		for ARCH in $(ARCHES); do \
			echo "Apt-get is updating his files ..."; \
			ARCH=$$ARCH $(apt) update; \
		done; \
    fi

## GENERATING LISTS ##

# Deleting the list only
deletelist: ok
	$(Q)-rm $(BDIR)/rawlist
	$(Q)-rm $(BDIR)/rawlist-exclude
	$(Q)-rm $(BDIR)/list
	$(Q)-rm $(BDIR)/list.exclude

packagelists: ok apt-update genlist

image-trees: ok genlist
    # Use list2cds to do the dependency sorting
	$(Q)for ARCH in $(ARCHES_NOSRC); do \
		ARCH=$$ARCH $(list2cds) $(BDIR)/list $(SIZELIMIT); \
	done
	$(Q)if [ "$(SOURCEONLY)"x = "yes"x ] ; then \
		awk '{printf("source:%s\n",$$0)}' $(BDIR)/list > $(BDIR)/packages; \
	else \
		$(merge_package_lists) $(BDIR) $(ADIR) "$(ARCHES)" $(BDIR)/packages; \
	fi
	$(Q)make_disc_trees.pl $(BASEDIR) $(MIRROR) $(TDIR) $(CODENAME) "$(ARCHES)" $(MKISOFS)

# Generate the complete listing of packages from the task
# Build a nice list without doubles and without spaces
genlist: ok $(BDIR)/list $(BDIR)/list.exclude
$(BDIR)/list: $(BDIR)/rawlist
	@echo "Generating the complete list of packages to be included in $(BDIR)/list..."
	$(Q)perl -ne 'chomp; next if /^\s*$$/; \
	          print "$$_\n" if not $$seen{$$_}; $$seen{$$_}++;' \
		  $(BDIR)/rawlist \
		  > $(BDIR)/list

$(BDIR)/list.exclude: $(BDIR)/rawlist-exclude
	@echo "Generating the complete list of packages to be removed ..."
	$(Q)perl -ne 'chomp; next if /^\s*$$/; \
	          print "$$_\n" if not $$seen{$$_}; $$seen{$$_}++;' \
		  $(BDIR)/rawlist-exclude \
		  > $(BDIR)/list.exclude

# Build the raw list (cpp output) with doubles and spaces
$(BDIR)/rawlist:
# Dirty workaround for saving space, we add some hints to break ties.
# This is just a temporal solution, list2cds should be a little bit less
# silly so that this is not needed. For more info have a look at
# http://lists.debian.org/debian-cd/2004/debian-cd-200404/msg00093.html
	$(Q)if [ "$(SOURCEONLY)"x != "yes"x ] ; then \
		if [ "$(INSTALLER_CD)"x = "1"x ] ; then \
			echo >> $(BDIR)/rawlist; \
	    elif [ "$(INSTALLER_CD)"x = "2"x ] ; then \
			echo -e "mawk\nunifont\npptp-linux" >>$(BDIR)/rawlist; \
	    else \
		    echo -e "mawk\nexim4-daemon-light\nunifont\npptp-linux" >>$(BDIR)/rawlist; \
		fi; \
	fi

	$(Q)if [ "$(SOURCEONLY)"x != "yes"x ] ; then \
		if [ _$(INSTALLER_CD) != _1 ]; then \
			for ARCH in $(ARCHES_NOSRC); do \
				debootstrap --arch $$ARCH --print-debs $(CODENAME) $(TDIR)/debootstrap.tmp file:$(MIRROR) 2>/dev/null \
				| tr ' ' '\n' >>$(BDIR)/rawlist; \
				rm -rf $(TDIR)/debootstrap.tmp; \
			done; \
		fi; \
	fi

	$(Q)for ARCH in $(ARCHES_NOSRC); do \
		ARCHDEFS="$$ARCHDEFS -D ARCH_$(subst -,_,$$ARCH)"; \
		ARCHUNDEFS="$$ARCHUNDEFS -U $$ARCH"; \
	done; \
	if [ "$(SOURCEONLY)"x != "yes"x ] ; then \
		cat $(TASK) | \
		cpp -nostdinc -nostdinc++ -P -undef $$ARCHDEFS \
	   		$$ARCHUNDEFS -U i386 -U linux -U unix \
		    -DFORCENONUSONCD1=0 \
		    -I $(BASEDIR)/tasks -I $(BDIR) - - >> $(BDIR)/rawlist; \
	fi

    # If we're *only* doing source, then we need to build a list of all the
    # available source packages. Deliberately ignore the tasks too.
	$(Q)if [ "$(SOURCEONLY)"x = "yes"x ] ; then \
		awk '/^Package:/ {print $$2}' $(ADIR)/$(CODENAME)-source/apt-state/lists/*Sources | \
			sort -u > $(BDIR)/rawlist; \
	fi
#	ls -al $(BDIR)/rawlist

# Build the raw list (cpp output) with doubles and spaces for excluded packages
$(BDIR)/rawlist-exclude:
	$(Q)if [ -n "$(EXCLUDE)" ]; then \
		for ARCH in $(ARCHES); do \
			ARCHDEFS="$$ARCHDEFS -D ARCH_$(subst -,_,$$ARCH)"; \
			ARCHUNDEFS="$$ARCHUNDEFS -U $$ARCH"; \
		done; \
	 	perl -npe 's/\@ARCH\@/$(ARCH)/g' $(EXCLUDE) | \
			cpp -nostdinc -nostdinc++ -P -undef $$ARCHDEFS \
			$$ARCHUNDEFS -U i386 -U linux -U unix \
			-DFORCENONUSONCD1=0 \
			-I $(BASEDIR)/tasks -I $(BDIR) - - >> $(BDIR)/rawlist-exclude; \
	else \
		echo > $(BDIR)/rawlist-exclude; \
	fi

## BOOT & DOC & INSTALL ##

# Basic checks
$(MIRROR)/doc: need-complete-mirror
$(MIRROR)/tools: need-complete-mirror
need-complete-mirror:
	@# Why the hell is this needed ??
	@if [ ! -d $(MIRROR)/doc -o ! -d $(MIRROR)/tools ]; then \
	    echo "You need a Debian mirror with the doc, tools and"; \
	    echo "indices directories ! "; \
	    exit 1; \
	fi

## IMAGE BUILDING ##

# DOJIGDO actions   (for both binaries and source)
#    0    isofile
#    1    isofile + jigdo, cleanup_jigdo
#    2    jigdo, cleanup_jigdo
#
images: ok $(OUT)
	$(make_image) "$(BDIR)" "$(ARCHES)" "$(OUT)" "$(DOJIGDO)" "$(DEBVERSION)" "$(MIRROR)" "$(MKISOFS)" "$(MKISOFS_OPTS)" "$(JIGDO_OPTS)" "$(jigdo_cleanup)"

check-number-given:
	@test -n "$(CD)" || (echo "Give me a CD=<num> parameter !" && false)

# Generate only one image number $(CD)
image: check-number-given images

# Calculate the md5sums for the images (if available), or get from templates
imagesums:
	$(Q)$(BASEDIR)/tools/imagesums $(OUT)

## MISC TARGETS ##

mirrorcheck: ok
	$(Q)$(grab_md5) $(MIRROR) "$(ARCHES)" $(CODENAME) $(DI_CODENAME) $(BDIR)/md5-check
	$(Q)if [ -e $(BASEDIR)/data/$(CODENAME)/$(ARCH)/extra-sources ]; then \
		echo "Extra dedicated source added; need to grab source MD5 info too"; \
		$(grab_md5) $(MIRROR) source $(CODENAME) $(DI_CODENAME) $(BDIR)/md5-check; \
	fi

update-popcon:
	$(update_popcon) tasks/popularity-contest-$(CODENAME)

# Little trick to simplify things
official_images: ok init packagelists image-trees images

$(CODENAME)_status: ok init
	$(Q)for ARCH in $(ARCHES_NOSRC); do \
		echo "Using the provided status file for $(CODENAME)-$$ARCH ..."; \
		cp $(BASEDIR)/data/$(CODENAME)/status.$$ARCH $(ADIR)/$(CODENAME)-$$ARCH/status 2>/dev/null || $(MAKE) status || $(MAKE) correctstatus ; \
	done
