"APL: an array language in the family of APL and J - rank-polymorphic arrays, verbs, adverbs and conjunctions, tacit and explicit definitions, boxed data, and a bridge to Smalltalk"
| dir |
dir := Smalltalk packagePath: 'APL'.
#('classes.st' 'array.st' 'words.st' 'verbs.st' 'display.st' 'parser.st' 'prims1.st' 'prims2.st' 'prims3.st' 'prims4.st' 'api.st' 'tool.st' 'tutorial.st')
	do: [:f | Smalltalk fileIn: dir, '/', f]!
SystemMenu add: 'apl workspace' receiver: APLTool selector: #open!
