.PHONY: repo iso check clean

repo:
	scripts/build-repo.sh

iso: repo
	sudo scripts/build-iso.sh

# Static checks that need no chroot or root (also run by CI on every PR).
check:
	scripts/check.sh

clean:
	sudo rm -rf work out
