
# Make all...
all: coffee-files libs/openscad.js libs/lexer.js www

# Compile all coffee scripts
coffee-files:
	coffee --bare --compile --output ./libs ./coffee/*

libs:
        mkdir libs

libs/openscad.js: libs
	coffee --bare --compile --join libs/openscad.js ./coffee

libs/lexer.js: libs
	jison -o libs/lexer.js lexer/lexer.jison

www/js/openscad.js: libs/openscad.js
	cp libs/openscad.js www/js/

www/js/lexer.js: libs/lexer.js
	cp libs/lexer.js www/js/

www: www/js/openscad.js www/js/lexer.js

# Watch the coffee dir and compile scripts as they change
watch:
	coffee --watch --bare --compile --output ./libs ./coffee

watch-www:
	coffee --watch --bare --compile --join ./www/js/openscad.js ./coffee

# Clean all targets
clean:
	rm -f `ls ./coffee/*.coffee | sed -e 's/\.\/coffee\/\(.*\)\.coffee/\.\/libs\/\1.js/'`
	rm -f libs/openscad.js libs/lexer.js
	rm -f www/js/openscad.js www/js/lexer.js
