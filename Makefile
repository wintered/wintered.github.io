all:
	jemdoc -c website.conf *.jemdoc 
	chromium-browser index.html
