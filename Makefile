.PHONY: repo iso netiso check clean

repo:
	scripts/build-repo.sh

iso: repo
	sudo scripts/build-iso.sh

# Netinstall ISO: downloads the target at install time, so no package build.
netiso:
	sudo scripts/build-iso.sh net

# Static checks that need no chroot or root (also run by CI on every PR).
check:
	scripts/check.sh

clean:
	sudo rm -rf work out
