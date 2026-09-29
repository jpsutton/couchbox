.PHONY: repo iso check clean

repo:
	scripts/build-repo.sh

iso: repo
	sudo scripts/build-iso.sh

# Static checks that need no chroot or root.
check:
	bash -n scripts/*.sh iso/airootfs/usr/local/bin/couchbox-install
	command -v shellcheck >/dev/null && shellcheck scripts/*.sh iso/airootfs/usr/local/bin/couchbox-install || true
	command -v desktop-file-validate >/dev/null && desktop-file-validate packages/*/*.desktop || true
	cd packages/couchbox-base && makepkg --printsrcinfo >/dev/null

clean:
	sudo rm -rf work out
