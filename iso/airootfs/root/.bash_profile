# Live console login (root is logged in automatically on tty1).
#
# releng's hook first: it runs the script given as `script=` on the kernel
# command line, which unattended test installs use. Otherwise start the
# installer on tty1; quitting it leaves a normal shell.
~/.automated_script.sh
if [[ $(tty) == /dev/tty1 ]] && ! grep -q 'script=' /proc/cmdline; then
  couchbox-install
fi
