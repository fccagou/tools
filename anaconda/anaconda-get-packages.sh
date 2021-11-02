

curl -k https://docs.anaconda.com/anaconda/packages/py3.7_linux-64/ | \
	grep 'fa-check' -B3 anaconda-list.html | \
	grep '<a ' -A1 | \
	sed -e's/.*>\(.*\)<\/a>.*/@\1/' -e 's/<[^>]*>//g' -e 's/ *//g' | \
	grep -v '^--'  | \
	xargs | \
	tr '@' "\n" | \
	grep -v '^$' | \
	sed 's/ \+/==/'



