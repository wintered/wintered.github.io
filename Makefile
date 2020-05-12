all:
	jemdoc -c website.conf *.jemdoc 
	chromium index.html
