#!/bin/bash
# Copyright (c) 2015 Ryan Kennedy <ry@nkennedy.net>
#
# WHAT ========================================================================
#   Horcrux takes an input file/archive, encrypts it, hex encodes it and then
#   breaks it apart into n equal pieces, or x pieces of <= n bytes.  Horcrux
#   can also take a directory of horcrux pieces and concatenate, decode then
#   decrypt them to recreate the original file.
#
# USAGE =======================================================================
#   $ ./horcrux split -i file -n name -p pass -s n OR -b n[k|m]
#   where -i = input file/archive
#         -n = a unique name identifying this horcrux
#         -p = the password used to encrypt this horcrux
#         -s = split the horcrux into n pieces of equal bytes, OR
#         -b = split the horcrux into x pieces of max n[k|m] bytes
#              k represents kilobytes, m megabytes; example: -b 1k, -b 20m
#              if no unit is provided bytes are assumed; example: -b 500
#   Creates a new horcrux inside a folder (named by -n).  Note that only the -s
#   or -b flag need be specified at a time, never both.
#
#
#   $ ./horcrux join -i folder/of/pieces -p pass
#   where -i = a folder containing horcrux pieces
#         -p = the password used to decrypt this horcrux
#   Concatenates, decodes and decrypts a horcrux to recreate the original file.
#
# Created: 10-Sep-2015
# Updated: 01-Jul-2020

set -o errtrace
set -o pipefail

gpg=$(command -v gpg || command -v gpg2)

fail () {
  tput setaf 1 ; echo "Finite Incantatum: ${1}"
  tput sgr0    ; exit 1
}

success () {
  tput setaf 2 ; echo "Success: ${1}"
  tput sgr0    ; exit 0
}

do_split () {
  echo "${input}" | cat - ${input} > cleartext.tmp
  do_encrypt cleartext.tmp ciphertext.tmp ${pass}
  xxd -p ciphertext.tmp > cipherhex.tmp

  rm cleartext.tmp ciphertext.tmp ; mv cipherhex.tmp ${name}

  if [[ ! -z ${pieces} && -z ${bytes} ]] ; then
    split -l $(($(wc -l < ${name}) / ${pieces} + 1)) ${name} ${name}.
  elif [[ ! -z ${bytes} && -z ${pieces} ]] ; then
    split -b ${bytes} ${name} ${name}.
  else
    rm ${name} ; fail "Invalid number of arguments"
  fi

  rm ${name} ; check_dir ${name}
  for piece in ${name}.* ; do
    mv ${piece} ${name}/$(basename ${piece}).hcrx
  done

  success "New horcrux created in $(pwd)/${name}/"
}

do_join () {
  cat ${input}/*.hcrx | xxd -r -p > ciphertext.tmp
  do_decrypt ciphertext.tmp ${pass} > cleartext.tmp
  ofilename=$(head -n 1 cleartext.tmp)
  tail -n +2 cleartext.tmp > ${input}/${ofilename}

  rm ciphertext.tmp cleartext.tmp

  success "Horcrux rejoined as ${input}/${ofilename}"
}

do_encrypt () {
  ${gpg} \
    --symmetric --armor --batch \
    --cipher-algo AES256 --passphrase-fd 3 \
    --output "${2}" "${1}" 3< <(echo "${3}")
}

do_decrypt () {
  ${gpg} \
    --decrypt --armor --batch \
    --passphrase-fd 3 "${1}" 3< <(echo "${2}") 2>/dev/null
}

check_dir () {
  if [[ ! -e ${1} || ! -d ${1} ]] ; then
    mkdir ${1}
  fi
}

check_gpg () {
  if [[ -z ${gpg} && ! -x ${gpg} ]] ; then
    fail "GnuPG potion is not available"
  fi
}

check_gpg

if [[ ${1} == 'split' ]] ; then
  shift
  args=$(getopt i:n:p:s:b: $*)
  set -- $args
  for i ; do
    case "$i" in
      -i ) input="${2}"
           shift ; shift ;;
      -n ) name="${2}"
           shift ; shift ;;
      -p ) pass="${2}"
           shift ; shift ;;
      -s ) pieces="${2}"
           shift ; shift ;;
      -b ) bytes="${2}"
           shift ; shift ;;
      -- ) shift ; break ;;
    esac
  done
  if [[ -f ${input} && ! -z ${name} && ! -z ${pass} ]] ; then
    if [[ ! -z ${pieces} || ! -z ${bytes} ]] ; then
      do_split ${input} ${name} ${pass} ${pieces} ${bytes}
    else
      fail "Invalid number of arguments: check -s or -b"
    fi
  else
    fail "Invalid or missing arguments"
  fi
elif [[ ${1} == 'join' ]] ; then
  shift
  args=$(getopt i:p: $*)
  set -- $args
  for i ; do
    case "$i" in
      -i ) input="${2}"
           shift ; shift ;;
      -p ) pass="${2}"
           shift ; shift ;;
      -- ) shift ; break ;;
    esac
  done
  if [[ -d ${input} && ! -z ${pass} ]] ; then
    do_join ${input} ${pass}
  else
    fail "Invalid number of arguments"
  fi
else
  fail "Unknown incantation: ${1}"
fi
