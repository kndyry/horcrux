# Horcrux
    WHAT ========================================================================
        Horcrux takes an input file/archive, encrypts it, hex encodes it and then
        breaks it apart into n equal pieces, or x pieces of <= n bytes.  Horcrux
        can also take a directory of horcrux pieces and concatenate, decode then
        decrypt them to recreate the original file. Horcrux requires GnuPG.

    USAGE =======================================================================
        $ ./horcrux.sh cast -i file -n name -p pass -s n OR -b n[k|m]
        where -i = input file/archive
             -n = a unique name identifying this horcrux
             -p = the password used to encrypt this horcrux
             -s = split the horcrux into n pieces of equal bytes, OR
             -b = split the horcrux into x pieces of max n[k|m] bytes
                  k represents kilobytes, m megabytes; example: -b 1k, -b 20m
                  if no unit is provided bytes are assumed; example: -b 500
        Creates a new horcrux inside a folder (named by -n).  Note that only the
        -s or -b flag need be specified at a time, never both.


        $ ./horcrux.sh restore -i folder/of/pieces -p pass
        where -i = a folder containing horcrux pieces
             -p = the password used to decrypt this horcrux
        Concatenates, decodes and decrypts a horcrux to recreate the original file.

    EXAMPLES ====================================================================
        Split a file, archive.tar, into 5 equal pieces:
        $ ./horcrux.sh cast -i archive.tar -n arch.1.10.15 -p secret -s 5

        Split a file, disk.dmg, into 60mb pieces:
        $ ./horcrux.sh cast -i disk.dmg -n disk.1.10.15 -p secret -b 60m

        Restore an original file from a directory of horcrux pieces:
        $ ./horcrux.sh restore -i ~/disk.1.10.15 -p secret
