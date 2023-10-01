cd PATH_2/mediawiki/maintenance

php74 dumpBackup.php \
  --full \
  --include-files \
  --uploads \
  --output=gzip:/root/backup/mediawiki-full.xml.gz
# --quiet


