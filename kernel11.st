"Mini Smalltalk-80 kernel, part 11: optional packages and the System menu.
A package is an optional system kept in the packages/ folder next to the kernel sources: a file Name.st, or a folder Name
containing package.st (which may file in other files from its folder). It is loaded on request, not part of the kernel image:

	Smalltalk availablePackages            #('Prolog')
	Smalltalk loadPackage: 'Prolog'        loads it (once), and records the load in the changes file
	Smalltalk isPackageLoaded: 'Prolog'
	Smalltalk packageDescription: 'Prolog' the first comment of its file
	Smalltalk packagePath: 'Prolog'        its folder, for the data files it ships

Saving an image afterwards keeps the package in the image."

Object subclass: #SystemMenu instanceVariableNames: '' classVariableNames: 'Items' category: 'System-Support'!

!SystemMenu class methodsFor: 'items'!
items
	^Items ifNil: [Items := OrderedCollection new]!
labels
	^(self items collect: [:i | i at: 1]) asArray!
add: aLabel receiver: anObject selector: aSymbol
	"add (or replace) an item at the end of the System menu; choosing it sends aSymbol to anObject"
	self remove: aLabel.
	self items add: (Array with: aLabel with: anObject with: aSymbol).
	self primChanged!
remove: aLabel
	| mine |
	mine := self items select: [:i | (i at: 1) = aLabel].
	mine do: [:i | self items remove: i].
	mine isEmpty ifFalse: [self primChanged]!
run: index
	| i |
	i := self items at: index.
	^(i at: 2) perform: (i at: 3)!
primChanged
	<primitive: 200>
	^self! !

!SystemDictionary methodsFor: 'packages'!
kernelDirectory
	"where the kernel sources, tutorial.st and the packages folder are"
	<primitive: 196>
	^'.'!
packageDirectory
	^self kernelDirectory, '/packages'!
availablePackages
	"the names of the optional systems: files Name.st and folders Name that hold a package.st"
	| names dir |
	names := Set new.
	dir := Directory on: self packageDirectory.
	dir exists ifFalse: [^Array new].
	dir entries do: [:e |
		((e size > 3 and: [(e copyFrom: e size - 2 to: e size) = '.st']) and: [dir fileExists: e])
			ifTrue: [names add: (e copyFrom: 1 to: e size - 3)].
		((dir directoryExists: e) and: [(Directory on: (dir fullNameFor: e)) fileExists: 'package.st'])
			ifTrue: [names add: e]].
	^names asSortedCollection asArray!
availablePackagesString
	^', ' join: self availablePackages!
packageFileFor: aName
	"the file to file in for a package, or nil"
	| dir folder |
	dir := Directory on: self packageDirectory.
	folder := Directory on: (dir fullNameFor: aName).
	(folder exists and: [folder fileExists: 'package.st']) ifTrue: [^folder fullNameFor: 'package.st'].
	(dir fileExists: aName, '.st') ifTrue: [^dir fullNameFor: aName, '.st'].
	^nil!
packagePath: aName
	"the folder of a package (the packages folder itself for a single-file package)"
	| folder |
	folder := Directory on: (self packageDirectory, '/', aName).
	^folder exists ifTrue: [folder pathName] ifFalse: [self packageDirectory]!
packageDescription: aName
	"the first comment in the package's file"
	| file text start stop |
	file := self packageFileFor: aName.
	file isNil ifTrue: [^nil].
	text := FileStream contentsOf: file.
	start := text indexOf: $".
	start = 0 ifTrue: [^''].
	stop := text indexOf: $" startingAt: start + 1.
	stop = 0 ifTrue: [^''].
	^text copyFrom: start + 1 to: stop - 1!
loadedPackages
	^self at: #LoadedPackages ifAbsentPut: [OrderedCollection new]!
isPackageLoaded: aName
	^self loadedPackages includes: aName asString!
loadPackage: aName
	"File in the package (once). The load is recorded in the changes file, so that the next session loads it again
	-- unless an image saved in the meantime already contains it."
	| name file r |
	name := aName asString.
	(self isPackageLoaded: name) ifTrue: [^true].
	file := self packageFileFor: name.
	file isNil ifTrue: [^self error: 'no package named ', name, ' (available: ', self availablePackagesString, ')'].
	r := self primLoadFile: file.
	r == true ifFalse: [^self error: 'package ', name, ' failed to load: ', r].
	self loadedPackages add: name.
	self primLogChange: 'Smalltalk loadPackage: ', name printString, '!!'.
	^true!
primLoadFile: aPath
	"file in without recording the code in the changes file: true, or a message"
	<primitive: 197>
	^'cannot read the file'!
primLogChange: aString
	<primitive: 198>
	^self! !

!SystemDictionary methodsFor: 'tools'!
openTool: aClassName title: aTitle contents: aString
	"open a workspace window whose do it / print it send  aClassName evaluate: text  (the class answers a String)"
	<primitive: 201>
	^self error: 'cannot open the window'! !

!Object methodsFor: 'evaluating'!
compileSafely: aString
	"compile aString as a do-it for the receiver without running it: Array(true, CompiledMethod) or Array(false, error message)"
	<primitive: 199>
	^Array with: false with: 'compilation failed'!
evaluateSafely: aString
	"compile and run aString with the receiver as self: Array(true, value), or Array(false, compile error message).
	The code runs in the caller's own run loop, so exceptions it signals can be caught by the caller's handlers."
	| r |
	r := self compileSafely: aString.
	^(r at: 1)
		ifTrue: [Array with: true with: ((r at: 2) valueWithReceiver: self arguments: Array new)]
		ifFalse: [r]! !

!CompiledMethod methodsFor: 'evaluating'!
valueWithReceiver: anObject arguments: anArray
	"run the method with anObject as self (the method must not be installed anywhere)"
	<primitive: 202>
	^self error: 'cannot run the method with these arguments'! !

!Compiler class methodsFor: 'evaluating'!
evaluate: aString onError: aBlock
	"evaluate Smalltalk source; a syntax error evaluates aBlock (with the message) instead of aborting"
	| r |
	r := nil evaluateSafely: aString.
	^(r at: 1)
		ifTrue: [r at: 2]
		ifFalse: [aBlock numArgs = 0 ifTrue: [aBlock value] ifFalse: [aBlock value: (r at: 2)]]! !
