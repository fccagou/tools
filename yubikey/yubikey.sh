#!/usr/bin/bash
# vim: ts=4 sw=4 expandtab
set -euo pipefail

GNUPGHOME="${GNUPGHOME:-"$HOME"/.gnupg}"

# export GNUPGHOME=$(mktemp -d -t gnupg-$(date +%Y-%m-%d)-XXXXXXXXXX)
# chmod 700 "$GNUPGHOME"

printf -- "GNUPGHOME=%s\n" "$GNUPGHOME"

if [ ! -f "$GNUPGHOME"/gpg.conf ]; then
cat > "$GNUPGHOME"/gpg.conf <<EOF_GPG_CONF
personal-cipher-preferences AES256 AES192 AES
personal-digest-preferences SHA512 SHA384 SHA256
personal-compress-preferences ZLIB BZIP2 ZIP Uncompressed
default-preference-list SHA512 SHA384 SHA256 AES256 AES192 AES ZLIB BZIP2 ZIP Uncompressed
cert-digest-algo SHA512
s2k-digest-algo SHA512
s2k-cipher-algo AES256
charset utf-8
no-comments
no-emit-version
no-greeting
keyid-format 0xlong
list-options show-uid-validity
verify-options show-uid-validity
with-fingerprint
require-cross-certification
no-symkey-cache
armor
use-agent
throw-keyids
EOF_GPG_CONF
fi



export IDENTITY="${IDENTITY:-"YUBIKEY DEMO <me@fccagou.fr>"}"
export KEY_TYPE="${KEY_TYPE:-rsa4096}"
export EXPIRATION="${EXPIRATION:-2y}"

# Not safe
export CERTIFY_PASS=$(LC_ALL=C tr -dc 'A-Z1-9' < /dev/urandom | \
  tr -d "1IOS5U" | fold -w 30 | sed "-es/./ /"{1..26..5} | \
  cut -c2- | tr " " "-" | head -1) ; printf "\n$CERTIFY_PASS\n\n"

echo "$CERTIFY_PASS" | gpg --batch --passphrase-fd 0 \
    --quick-generate-key "$IDENTITY" "$KEY_TYPE" cert never

export KEYID=$(gpg -k --with-colons "$IDENTITY" | awk -F: '/^pub:/ { print $5; exit }')
export KEYFP=$(gpg -k --with-colons "$IDENTITY" | awk -F: '/^fpr:/ { print $10; exit }')
printf "\nKey ID: %40s\nKey FP: %40s\n\n" "$KEYID" "$KEYFP"

for SUBKEY in sign encrypt auth ; do \
  echo "$CERTIFY_PASS" | gpg --batch --pinentry-mode=loopback --passphrase-fd 0 \
      --quick-add-key "$KEYFP" "$KEY_TYPE" "$SUBKEY" "$EXPIRATION"
done

gpg -K


# printf -- "# ------------------------------------------------------------------------------\n"
# printf -- "# Public key : %s\n" "$KEYID"
# printf -- "# ------------------------------------------------------------------------------\n"
# gpg --armor --export "$KEYID"
# printf -- "# ------------------------------------------------------------------------------\n"

# backup
#
# echo "$CERTIFY_PASS" | gpg --output $GNUPGHOME/$KEYID-Certify.key \
#     --batch --pinentry-mode=loopback --passphrase-fd 0 \
#     --armor --export-secret-keys "$KEYID"
#
# echo "$CERTIFY_PASS" | gpg --output $GNUPGHOME/$KEYID-Subkeys.key \
#     --batch --pinentry-mode=loopback --passphrase-fd 0 \
#     --armor --export-secret-subkeys "$KEYID"
#
# gpg --output $GNUPGHOME/$KEYID-$(date +%F).asc \
#     --armor --export "$KEYID"





printf -- "# ==================================================================================\n"
printf -- "# YUBIKEY\n"
printf -- "# ==================================================================================\n"

KEYRING="$GNUPGHOME"/pubring.kbx
# OLD_GNUPGHOME="$GNUPGHOME"
# unset GNUPGHOME

gpg --card-status


export ADMIN_PIN=$(LC_ALL=C tr -dc '0-9' < /dev/urandom | fold -w8 | head -1)
export USER_PIN=$(LC_ALL=C tr -dc '0-9' < /dev/urandom | fold -w6 | head -1)
printf "\nAdmin PIN: %12s\nUser PIN: %13s\n\n" "$ADMIN_PIN" "$USER_PIN"

gpg --command-fd=0 --pinentry-mode=loopback --change-pin <<EOF
3
12345678
$ADMIN_PIN
$ADMIN_PIN
q
EOF


gpg --command-fd=0 --pinentry-mode=loopback --change-pin <<EOF
1
123456
$USER_PIN
$USER_PIN
q
EOF


gpg --command-fd=0 --pinentry-mode=loopback --edit-card <<EOF
admin
login
$IDENTITY
$ADMIN_PIN
quit
EOF


gpg --card-status

# Transfert subkeys

gpg --keyring "$KEYRING" --command-fd=0 --pinentry-mode=loopback --edit-key "$KEYID" <<EOF
key 1
keytocard
1
$CERTIFY_PASS
$ADMIN_PIN
save
EOF

gpg --keyring "$KEYRING" --command-fd=0 --pinentry-mode=loopback --edit-key "$KEYID" <<EOF
key 2
keytocard
2
$CERTIFY_PASS
$ADMIN_PIN
save
EOF

gpg --keyring "$KEYRING" --command-fd=0 --pinentry-mode=loopback --edit-key "$KEYID" <<EOF
key 3
keytocard
3
$CERTIFY_PASS
$ADMIN_PIN
save
EOF

gpg -K

echo <<EOF_POST
ykman openpgp access set-retries 5 5 5 -f -a "${ADMIN_PIN}"
ykman openpgp keys set-touch dec on \
    || ykman openpgp keys set-touch enc on
ykman openpgp keys set-touch sig on
ykman openpgp keys set-touch aut on
EOF_POST
