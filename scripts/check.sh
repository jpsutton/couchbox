#!/usr/bin/env bash
# Static checks for couchbox: no chroot, no root, no network. `make check`
# runs this locally; CI runs it on every pull request (with CHECK_STRICT=1, so
# a missing tool is an error instead of a skip).
#
# Checks the files git tracks, by type:
#   shell scripts  bash -n, shellcheck
#   Python         py_compile
#   JavaScript     node --check (also KWin/Plasma scripts: syntax only)
#   JSON, TOML     parsed
#   XML            xmllint
#   .desktop       desktop-file-validate
#   PKGBUILD       makepkg --printsrcinfo, and source/sha256sums counts match
set -uo pipefail
cd "$(dirname "$0")/.."

strict=${CHECK_STRICT:-0}
failures=0
declare -A missing=()

have() {
  command -v "$1" >/dev/null && return 0
  missing[$1]=1
  return 1
}

# check <label> <command...>: run it, print the output only on failure.
check() {
  local label=$1 out
  shift
  if ! out=$("$@" 2>&1); then
    echo "FAIL $label"
    sed 's/^/    /' <<<"$out"
    failures=$((failures + 1))
  fi
}

shebang() { head -c 64 "$1" | head -n1; }

mapfile -t files < <(git ls-files)
for f in "${files[@]}"; do
  [[ -f $f ]] || continue
  case $f in
    *.js)
      have node && check "$f" node --check "$f"
      continue ;;
    *.json)
      have python3 && check "$f" python3 -m json.tool "$f"
      continue ;;
    *.toml)
      have python3 && check "$f" python3 -c 'import sys, tomllib; tomllib.load(open(sys.argv[1], "rb"))' "$f"
      continue ;;
    *.xml)
      have xmllint && check "$f" xmllint --noout "$f"
      continue ;;
    *.desktop)
      have desktop-file-validate && check "$f" desktop-file-validate "$f"
      continue ;;
    *.py)
      have python3 && check "$f" python3 -c 'import ast, sys; ast.parse(open(sys.argv[1]).read(), sys.argv[1])' "$f"
      continue ;;
    */PKGBUILD | PKGBUILD)
      continue ;;  # below, per package directory
  esac
  case $(shebang "$f") in
    '#!'*python*)
      have python3 && check "$f" python3 -c 'import ast, sys; ast.parse(open(sys.argv[1]).read(), sys.argv[1])' "$f" ;;
    '#!'*sh*)
      check "$f (bash -n)" bash -n "$f"
      have shellcheck && check "$f (shellcheck)" shellcheck -S warning "$f" ;;
  esac
done

for pkgbuild in $(git ls-files '*PKGBUILD'); do
  dir=${pkgbuild%/PKGBUILD}
  check "$pkgbuild (bash -n)" bash -n "$pkgbuild"
  # Array lengths: a source added without its checksum fails only at build time.
  check "$pkgbuild (source/sha256sums)" bash -c '
    source "$1" >/dev/null 2>&1 || exit 0
    [[ ${#sha256sums[@]} -eq 0 || ${#source[@]} -eq ${#sha256sums[@]} ]] ||
      { echo "source has ${#source[@]} entries, sha256sums ${#sha256sums[@]}"; exit 1; }' _ "$pkgbuild"
  if have makepkg; then
    if [[ $EUID -eq 0 ]]; then
      missing["makepkg (as non-root)"]=1
    else
      check "$pkgbuild (makepkg --printsrcinfo)" bash -c 'cd "$1" && makepkg --printsrcinfo >/dev/null' _ "$dir"
    fi
  fi
done

for tool in "${!missing[@]}"; do
  if [[ $strict == 1 ]]; then
    echo "FAIL missing tool: $tool"
    failures=$((failures + 1))
  else
    echo "skip: $tool not available"
  fi
done

if ((failures)); then
  echo "$failures check(s) failed"
  exit 1
fi
echo "all checks passed (${#files[@]} files)"
