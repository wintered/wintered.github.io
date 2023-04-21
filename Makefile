SHELL := /bin/bash

last_modified:
	sed -i'' -e "s/last modified:*.*.*/last modified: `date +%d.%m.%Y`/" index.html
	rm -rf *-e

all: last_modified
	tidy -q -indent -m index.html
	codespell index.html 
	tidy -q -indent -m posts/*.html 
	codespell posts/*.html
