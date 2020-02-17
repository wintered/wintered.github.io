all:
	jemdoc -c website.conf *.jemdoc
	firefox *.html &

