Simple-Kickoff: contents/* LICENSE* metadata.*
	zip -FS -r -v Simple-Kickoff.plasmoid contents LICENSE* metadata.*
clean:
	rm *.plasmoid