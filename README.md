openscad-js
===========

JavaScript reimplementation of OpenSCAD

Dependencies:
- CoffeeScript 1.3.3 - http://coffeescript.org/
- Node.js 0.8.9 - http://nodejs.org/
- Jison - http://zaach.github.com/jison/

Third-Party Libraries
=====================

The following libraries are included in the www/js/3rd-party/ folder:
- csg.js - Evan Wallace, http://evanw.github.com/csg.js/
- prototype.js - http://prototypejs.org/
- THREE.js - http://mrdoob.github.com/three.js/
- ThreeCSG.js - Chandler Prall, https://github.com/chandlerprall/ThreeCSG

Compilation
===========
'make' will compile the jison lexer and all coffeescript files to javascript.
similarly, 'make watch' will monitor coffeescript files for changes and recompile them automagically to enable quick development.

coffescripts are compiled in multiple .js files as well as a single monolitic .js file containing everything.
