install:
	cp src/timetrack.sh /usr/local/bin/track
	cp src/bash_completion.sh /etc/bash_completion.d/track

uninstall:
	rm /usr/local/bin/track
	rm /etc/bash_completion.d/track
