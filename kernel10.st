"Mini Smalltalk-80 kernel, part 10: files, directories, the operating system, and date/time arithmetic"

Error subclass: #FileError instanceVariableNames: '' classVariableNames: '' category: 'Kernel-Exceptions'!
Stream subclass: #FileStream instanceVariableNames: 'name handle readOnly binary' classVariableNames: '' category: 'Collections-Streams'!
Object subclass: #Directory instanceVariableNames: 'path' classVariableNames: '' category: 'System-Files'!
Magnitude subclass: #Duration instanceVariableNames: 'seconds' classVariableNames: '' category: 'Kernel-Magnitudes'!
Magnitude subclass: #DateAndTime instanceVariableNames: 'seconds' classVariableNames: '' category: 'Kernel-Magnitudes'!

"---- FileStream: incremental reading and writing through a file handle ----"

!FileStream class methodsFor: 'instance creation'!
fileNamed: aString
	"open for reading and writing, creating the file if it does not exist; the contents are kept"
	| h |
	h := self primOpen: aString mode: 'r+'.
	h isNil ifTrue: [h := self primOpen: aString mode: 'w+'].
	h isNil ifTrue: [^FileError new signal: 'cannot open ', aString].
	^self basicNew setName: aString handle: h readOnly: false!
oldFileNamed: aString
	"open an existing file for reading and writing (read only if the file is not writable)"
	| h |
	h := self primOpen: aString mode: 'r+'.
	h isNil ifFalse: [^self basicNew setName: aString handle: h readOnly: false].
	^self readOnlyFileNamed: aString!
readOnlyFileNamed: aString
	| h |
	h := self primOpen: aString mode: 'r'.
	h isNil ifTrue: [^FileError new signal: 'file not found: ', aString].
	^self basicNew setName: aString handle: h readOnly: true!
newFileNamed: aString
	"create the file, emptying it if it exists"
	| h |
	h := self primOpen: aString mode: 'w+'.
	h isNil ifTrue: [^FileError new signal: 'cannot create ', aString].
	^self basicNew setName: aString handle: h readOnly: false!
forceNewFileNamed: aString
	^self newFileNamed: aString!
appendFileNamed: aString
	"open for writing at the end of the file, creating it if necessary"
	| h |
	h := self primOpen: aString mode: 'a+'.
	h isNil ifTrue: [^FileError new signal: 'cannot open ', aString].
	^(self basicNew setName: aString handle: h readOnly: false) setToEnd; yourself! !

!FileStream class methodsFor: 'scoped use'!
fileNamed: aString do: aBlock
	| f |
	f := self fileNamed: aString.
	^[aBlock value: f] ensure: [f close]!
oldFileNamed: aString do: aBlock
	| f |
	f := self oldFileNamed: aString.
	^[aBlock value: f] ensure: [f close]!
readOnlyFileNamed: aString do: aBlock
	| f |
	f := self readOnlyFileNamed: aString.
	^[aBlock value: f] ensure: [f close]!
newFileNamed: aString do: aBlock
	| f |
	f := self newFileNamed: aString.
	^[aBlock value: f] ensure: [f close]!
appendFileNamed: aString do: aBlock
	| f |
	f := self appendFileNamed: aString.
	^[aBlock value: f] ensure: [f close]!
contentsOf: aString
	"the whole file as a String"
	^self readOnlyFileNamed: aString do: [:f | f contents]! !

!FileStream class methodsFor: 'file system'!
isAFileNamed: aString
	| st |
	st := self primStat: aString.
	^st notNil and: [(st at: 1) not]!
exists: aString
	^(self primStat: aString) notNil!
remove: aString
	^self primDelete: aString!
rename: oldName to: newName
	^self primRename: oldName to: newName!
fileIn: aString
	^Smalltalk fileIn: aString!
sizeOf: aString
	| st |
	st := self primStat: aString.
	^st isNil ifTrue: [nil] ifFalse: [st at: 2]! !

!FileStream class methodsFor: 'primitives'!
primOpen: path mode: mode
	<primitive: 174>
	^nil!
primStat: path
	<primitive: 186>
	^nil!
primDelete: aString
	<primitive: 172>
	^false!
primExists: aString
	<primitive: 173>
	^false!
primRename: old to: new
	<primitive: 187>
	^false!
primRead: aString
	"the whole file as a String, or nil"
	<primitive: 170>
	^nil!
primWrite: contents to: aString append: aBoolean
	<primitive: 171>
	^false!
primRead: h count: n
	<primitive: 175>
	^FileError new signal: 'cannot read the file'!
primWrite: h bytes: aString
	<primitive: 176>
	^FileError new signal: 'cannot write the file'!
primClose: h
	<primitive: 177>
	^false!
primSeek: h to: offset whence: anInteger
	<primitive: 178>
	^nil!
primSize: h
	<primitive: 179>
	^0!
primFlush: h
	<primitive: 181>
	^false!
primTruncate: h to: n
	<primitive: 182>
	^false! !

!FileStream methodsFor: 'private'!
setName: aString handle: anInteger readOnly: aBoolean
	name := aString. handle := anInteger. readOnly := aBoolean. binary := false!
ensureOpen
	handle isNil ifTrue: [^FileError new signal: 'file is closed: ', name]!
ensureWritable
	self ensureOpen.
	readOnly ifTrue: [^FileError new signal: 'file is read only: ', name]!
primRead: count
	^FileStream primRead: handle count: count!
primWrite: aString
	^FileStream primWrite: handle bytes: aString!
primClose
	^FileStream primClose: handle!
primSeek: offset whence: anInteger
	^FileStream primSeek: handle to: offset whence: anInteger!
primSize
	^FileStream primSize: handle!
primFlush
	^FileStream primFlush: handle!
primTruncate: n
	^FileStream primTruncate: handle to: n!
bytesFor: anObject
	"the bytes written for anObject: characters and strings as text, integers as single bytes"
	anObject isCharacter ifTrue: [^anObject value < 256 ifTrue: [String with: anObject] ifFalse: [anObject utf8Encoded]].
	anObject isInteger ifTrue: [^String with: (Character value: anObject)].
	anObject isString ifTrue: [^anObject isWideString ifTrue: [anObject utf8Encoded] ifFalse: [anObject asString]].
	anObject class == ByteArray ifTrue: [^anObject asString].
	^FileError new signal: 'cannot write ', anObject printString, ' to a file'! !

!FileStream methodsFor: 'accessing'!
name
	^name!
fullName
	^(name notEmpty and: [name first = $/]) ifTrue: [name] ifFalse: [Directory default pathName, '/', name]!
size
	self ensureOpen.
	^self primSize!
position
	self ensureOpen.
	^self primSeek: 0 whence: 1!
position: anInteger
	self ensureOpen.
	(self primSeek: anInteger whence: 0) isNil ifTrue: [^self error: 'bad file position ', anInteger printString]!
reset
	self position: 0!
setToEnd
	self ensureOpen.
	self primSeek: 0 whence: 2!
skip: n
	self ensureOpen.
	self primSeek: n whence: 1!
atEnd
	self ensureOpen.
	^self position >= self primSize!
isEmpty
	^self size = 0!
next
	| s |
	self ensureOpen.
	s := self primRead: 1.
	s isEmpty ifTrue: [^nil].
	^binary ifTrue: [s first value] ifFalse: [s first]!
next: n
	"up to n elements: a String, or a ByteArray in binary mode"
	| s |
	self ensureOpen.
	s := self primRead: n.
	^binary ifTrue: [s asByteArray] ifFalse: [s]!
peek
	| s |
	s := self next.
	s isNil ifFalse: [self skip: -1].
	^s!
upToEnd
	| s |
	self ensureOpen.
	s := self primRead: (self primSize - self position max: 0).
	^binary ifTrue: [s asByteArray] ifFalse: [s]!
upTo: anObject
	"read up to (and discard) anObject, answering what came before it"
	| out chunk i key |
	self ensureOpen.
	key := anObject isInteger ifTrue: [Character value: anObject] ifFalse: [anObject].
	out := WriteStream on: String new.
	[chunk := self primRead: 256.
	 chunk isEmpty ifTrue: [^self answerFrom: out].
	 i := chunk indexOf: key.
	 i = 0] whileTrue: [out nextPutAll: chunk].
	out nextPutAll: (chunk copyFrom: 1 to: i - 1).
	self skip: i - chunk size.
	^self answerFrom: out!
answerFrom: aWriteStream
	| s |
	s := aWriteStream contents.
	^binary ifTrue: [s asByteArray] ifFalse: [s]!
nextLine
	"the next line without its terminator (LF, CR or CR LF); nil at the end of the file"
	| line |
	self atEnd ifTrue: [^nil].
	line := self upTo: Character lf.
	(line notEmpty and: [line last == (Character value: 13)]) ifTrue: [line := line copyFrom: 1 to: line size - 1].
	^line!
contents
	"the whole file, leaving the position where it was"
	| here s |
	self ensureOpen.
	here := self position.
	self reset.
	s := self primRead: self primSize.
	self position: here.
	^binary ifTrue: [s asByteArray] ifFalse: [s]!
contentsOfEntireFile
	^self contents!
readStream
	^ReadStream on: self contents!
lines
	| r |
	r := OrderedCollection new.
	self reset.
	[self atEnd] whileFalse: [r add: self nextLine].
	^r! !

!FileStream methodsFor: 'writing'!
nextPut: anObject
	| s |
	self ensureWritable.
	s := self bytesFor: anObject.
	self primWrite: s.
	^anObject!
nextPutAll: aCollection
	self ensureWritable.
	(aCollection isString or: [aCollection class == ByteArray])
		ifTrue: [self primWrite: (self bytesFor: aCollection)]
		ifFalse: [aCollection do: [:e | self nextPut: e]].
	^aCollection!
next: n put: anObject
	n timesRepeat: [self nextPut: anObject].
	^anObject!
truncate
	"discard everything after the current position"
	self ensureWritable.
	self primTruncate: self position!
flush
	self ensureOpen.
	self primFlush! !

!FileStream methodsFor: 'file status'!
close
	"close the file; closing a closed file does nothing"
	handle isNil ifTrue: [^self].
	self primFlush.
	self primClose.
	handle := nil!
closed
	^handle isNil!
isOpen
	^handle notNil!
isReadOnly
	^readOnly!
readOnly
	^readOnly!
isFileStream
	^true!
isDirty
	^false!
binary
	binary := true!
text
	binary := false!
isBinary
	^binary!
exists
	^FileStream exists: name!
delete
	self close.
	^FileStream remove: name!
fileIn
	^Smalltalk fileInString: self contents! !

!FileStream methodsFor: 'printing'!
printOn: aStream
	aStream nextPutAll: 'a FileStream on '; print: name.
	handle isNil ifTrue: [aStream nextPutAll: ' (closed)']! !

!Stream methodsFor: 'testing'!
isFileStream
	^false! !

"---- Directory ----"

!Directory class methodsFor: 'instance creation'!
on: aPathString
	^self basicNew setPath: aPathString!
default
	"the current working directory"
	^self on: self primCwd!
current
	^self default!
root
	^self on: '/'!
home
	^self on: (Smalltalk getenv: 'HOME' ifAbsent: ['/'])! !

!Directory class methodsFor: 'file system'!
exists: aPathString
	| st |
	st := FileStream primStat: aPathString.
	^st notNil and: [st at: 1]!
create: aPathString
	"create the directory and any missing parents"
	^(self on: aPathString) create!
delete: aPathString
	^(self on: aPathString) delete!
setDefault: aPathString
	"make aPathString the current working directory"
	^(self primChdir: aPathString) ifFalse: [FileError new signal: 'cannot change directory to ', aPathString]!
primCwd
	<primitive: 189>
	^'.'!
primChdir: aString
	<primitive: 190>
	^false!
primList: aString
	<primitive: 183>
	^nil!
primMkdir: aString
	<primitive: 184>
	^false!
primRmdir: aString
	<primitive: 185>
	^false! !

!Directory methodsFor: 'private'!
setPath: aString
	path := (aString size > 1 and: [aString last = $/]) ifTrue: [aString copyFrom: 1 to: aString size - 1] ifFalse: [aString]!
statOf: aName
	^FileStream primStat: (self fullNameFor: aName)! !

!Directory methodsFor: 'accessing'!
pathName
	^path!
fullName
	^(path notEmpty and: [path first = $/]) ifTrue: [path] ifFalse: [Directory default pathName, '/', path]!
fullNameFor: aName
	^(aName notEmpty and: [aName first = $/]) ifTrue: [aName] ifFalse: [path = '/' ifTrue: ['/', aName] ifFalse: [path, '/', aName]]!
entries
	"the names of everything in the directory, sorted"
	| list |
	list := Directory primList: path.
	list isNil ifTrue: [^FileError new signal: 'cannot read directory ', path].
	^list asSortedCollection asArray!
fileNames
	^self entries select: [:n | (self isDirectoryNamed: n) not]!
directoryNames
	^self entries select: [:n | self isDirectoryNamed: n]!
entriesDo: aBlock
	self entries do: aBlock!
fileNamed: aName
	^FileStream fileNamed: (self fullNameFor: aName)!
oldFileNamed: aName
	^FileStream oldFileNamed: (self fullNameFor: aName)!
newFileNamed: aName
	^FileStream newFileNamed: (self fullNameFor: aName)!
readOnlyFileNamed: aName
	^FileStream readOnlyFileNamed: (self fullNameFor: aName)!
directoryNamed: aName
	^Directory on: (self fullNameFor: aName)! !

!Directory methodsFor: 'testing'!
exists
	^Directory exists: path!
isDirectoryNamed: aName
	| st |
	st := self statOf: aName.
	^st notNil and: [st at: 1]!
fileExists: aName
	| st |
	st := self statOf: aName.
	^st notNil and: [(st at: 1) not]!
directoryExists: aName
	^self isDirectoryNamed: aName!
sizeOf: aName
	| st |
	st := self statOf: aName.
	^st isNil ifTrue: [nil] ifFalse: [st at: 2]!
modificationTimeOf: aName
	"a DateAndTime, or nil if there is no such file"
	| st |
	st := self statOf: aName.
	^st isNil ifTrue: [nil] ifFalse: [DateAndTime fromSeconds: (st at: 3)]! !

!Directory methodsFor: 'modifying'!
create
	"create the directory, and any missing parents"
	| parent i |
	self exists ifTrue: [^self].
	i := path lastIndexOf: $/.
	i > 1 ifTrue: [parent := Directory on: (path copyFrom: 1 to: i - 1). parent create].
	(Directory primMkdir: path) ifFalse: [^FileError new signal: 'cannot create directory ', path]!
delete
	"remove the (empty) directory"
	(Directory primRmdir: path) ifFalse: [^FileError new signal: 'cannot remove directory ', path]!
deleteFileNamed: aName
	^FileStream remove: (self fullNameFor: aName)!
rename: oldName to: newName
	^FileStream rename: (self fullNameFor: oldName) to: (self fullNameFor: newName)!
deleteAll
	"remove the directory with everything inside it"
	self entries do: [:n |
		(self isDirectoryNamed: n)
			ifTrue: [(self directoryNamed: n) deleteAll]
			ifFalse: [self deleteFileNamed: n]].
	self delete! !

!Directory methodsFor: 'comparing'!
= aDirectory
	^(aDirectory isKindOf: Directory) and: [self fullName = aDirectory fullName]!
hash
	^path hash! !

!Directory methodsFor: 'printing'!
printOn: aStream
	aStream nextPutAll: 'a Directory on '; print: path! !

"---- the operating system ----"

!SystemDictionary methodsFor: 'image'!
snapshot
	"Save the whole system -- classes, methods, all objects reachable from Smalltalk -- to the current image file
	(st.image in the directory you started from, unless you started from another with -i). The changes file is set
	aside, since everything in it is now in the image. Answers true. Processes and windows are not saved."
	^self snapshotAs: self imageName!
snapshotAs: aFileName
	"Save an image to aFileName. The changes file is set aside only if that is the current image file."
	| r |
	r := self primSnapshot: aFileName.
	r == true ifFalse: [^self error: r].
	^true!
primSnapshot: aFileName
	<primitive: 194>
	^'cannot save the image'!
imageName
	"the file that #snapshot writes"
	<primitive: 195>
	^'st.image'! !

!SystemDictionary methodsFor: 'operating system'!
getenv: aName
	"the value of an environment variable, or nil"
	<primitive: 188>
	^nil!
getenv: aName ifAbsent: aBlock
	| v |
	v := self getenv: aName.
	^v isNil ifTrue: [aBlock value] ifFalse: [v]!
os
	<primitive: 191>
	^'unknown'!
platformName
	^self os!
hostName
	<primitive: 193>
	^'localhost'!
currentDirectory
	^Directory default!
homeDirectory
	^Directory home!
microsecondClock
	"microseconds since 1 January 1970 (UTC)"
	<primitive: 192>
	^0!
millisecondClock
	^Time millisecondClock!
timeStamp
	^DateAndTime now printString!
hasClassNamed: aString
	| c |
	c := self at: aString asSymbol ifAbsent: [nil].
	^c notNil and: [c isClass]! !

!Time class methodsFor: 'general inquiries'!
microsecondClock
	^Smalltalk microsecondClock!
secondClock
	^self primSecondsClock! !

"---- Duration ----"

!Duration class methodsFor: 'instance creation'!
seconds: aNumber
	^self basicNew setSeconds: aNumber!
milliSeconds: aNumber
	^self seconds: aNumber / 1000!
minutes: aNumber
	^self seconds: aNumber * 60!
hours: aNumber
	^self seconds: aNumber * 3600!
days: aNumber
	^self seconds: aNumber * 86400!
weeks: aNumber
	^self seconds: aNumber * 604800!
days: d hours: h minutes: m seconds: s
	^self seconds: d * 86400 + (h * 3600) + (m * 60) + s!
zero
	^self seconds: 0! !

!Duration methodsFor: 'private'!
setSeconds: aNumber
	seconds := aNumber! !

!Duration methodsFor: 'accessing'!
totalSeconds
	^seconds!
asSeconds
	^seconds!
asMilliSeconds
	^seconds * 1000!
days
	"days, hours, minutes and seconds are the parts of the absolute value; see #negative"
	^seconds abs // 86400!
hours
	^seconds abs \\ 86400 // 3600!
minutes
	^seconds abs \\ 3600 // 60!
seconds
	^seconds abs \\ 60!
negative
	^seconds < 0!
isZero
	^seconds = 0! !

!Duration methodsFor: 'arithmetic'!
+ aDuration
	^Duration seconds: seconds + aDuration totalSeconds!
- aDuration
	^Duration seconds: seconds - aDuration totalSeconds!
* aNumber
	^Duration seconds: seconds * aNumber!
/ aNumberOrDuration
	^aNumberOrDuration isNumber
		ifTrue: [Duration seconds: seconds / aNumberOrDuration]
		ifFalse: [seconds / aNumberOrDuration totalSeconds]!
negated
	^Duration seconds: seconds negated!
abs
	^Duration seconds: seconds abs! !

!Duration methodsFor: 'comparing'!
< aDuration
	^seconds < aDuration totalSeconds!
= aDuration
	^(aDuration isKindOf: Duration) and: [seconds = aDuration totalSeconds]!
hash
	^seconds hash! !

!Duration methodsFor: 'printing'!
printOn: aStream
	"days:hh:mm:ss, with milliseconds when there are any"
	| s whole fraction |
	s := seconds abs. whole := s truncated. fraction := s - whole.
	seconds < 0 ifTrue: [aStream nextPut: $-].
	aStream print: whole // 86400; nextPut: $:;
		nextPutAll: ((whole \\ 86400 // 3600) printPaddedWith: $0 to: 2); nextPut: $:;
		nextPutAll: ((whole \\ 3600 // 60) printPaddedWith: $0 to: 2); nextPut: $:;
		nextPutAll: ((whole \\ 60) printPaddedWith: $0 to: 2).
	fraction = 0 ifFalse: [aStream nextPut: $.; nextPutAll: ((fraction * 1000) rounded printPaddedWith: $0 to: 3)]! !

!Number methodsFor: 'durations'!
milliSeconds
	^Duration milliSeconds: self!
seconds
	^Duration seconds: self!
minutes
	^Duration minutes: self!
hours
	^Duration hours: self!
days
	^Duration days: self!
weeks
	^Duration weeks: self! !

"---- DateAndTime: seconds since 1 January 1901, local time ----"

!DateAndTime class methodsFor: 'instance creation'!
fromSeconds: aNumber
	^self basicNew setSeconds: aNumber!
now
	^self fromSeconds: Time primSecondsClock!
today
	^self fromSeconds: Time primSecondsClock // 86400 * 86400!
date: aDate time: aTime
	^self fromSeconds: aDate asSeconds + aTime asSeconds!
year: y month: m day: d hour: h minute: min second: s
	^self fromSeconds: (Date newDay: d month: m year: y) asSeconds + (h * 3600) + (min * 60) + s!
year: y month: m day: d
	^self year: y month: m day: d hour: 0 minute: 0 second: 0!
fromUnixTime: aNumber
	"seconds since 1 January 1970 (UTC, ignoring the time zone)"
	^self fromSeconds: aNumber + 2177452800! !

!DateAndTime methodsFor: 'private'!
setSeconds: aNumber
	seconds := aNumber! !

!DateAndTime methodsFor: 'accessing'!
asSeconds
	^seconds!
asUnixTime
	^seconds - 2177452800!
date
	^Date fromDays: seconds // 86400!
time
	^Time fromSeconds: seconds \\ 86400!
asDate
	^self date!
asTime
	^self time!
asDateAndTime
	^self!
year
	^self date year!
month
	^self date month!
monthName
	^self date monthName!
day
	^self date dayOfMonth!
dayOfMonth
	^self date dayOfMonth!
dayOfYear
	^self date dayOfYear!
dayOfWeek
	^self date dayOfWeek!
dayName
	^self date dayName!
hour
	^self time hours!
hour24
	^self time hours!
hour12
	^self time hour12!
minute
	^self time minutes!
second
	^self time seconds!
isLeapYear
	^self date isLeapYear! !

!DateAndTime methodsFor: 'arithmetic'!
+ aDuration
	^DateAndTime fromSeconds: seconds + aDuration totalSeconds!
- aDateOrDuration
	^(aDateOrDuration isKindOf: DateAndTime)
		ifTrue: [Duration seconds: seconds - aDateOrDuration asSeconds]
		ifFalse: [DateAndTime fromSeconds: seconds - aDateOrDuration totalSeconds]! !

!DateAndTime methodsFor: 'comparing'!
< aDateAndTime
	^seconds < aDateAndTime asSeconds!
= aDateAndTime
	^(aDateAndTime isKindOf: DateAndTime) and: [seconds = aDateAndTime asSeconds]!
hash
	^seconds hash! !

!DateAndTime methodsFor: 'printing'!
printOn: aStream
	"ISO 8601: 2026-11-19T09:22:26"
	aStream nextPutAll: self date yyyymmdd; nextPut: $T; nextPutAll: self time print24!
storeOn: aStream
	aStream nextPut: $(; nextPutAll: 'DateAndTime fromSeconds: '; print: seconds; nextPut: $)! !

"---- Date and Time arithmetic ----"

!Date class methodsFor: 'instance creation'!
year: y day: dayOfYear
	^self newDay: dayOfYear year: y!
fromSeconds: secondCount
	"the date that contains secondCount (seconds since 1 January 1901)"
	^self fromDays: secondCount // 86400! !

!Date methodsFor: 'arithmetic'!
+ aDuration
	^self addDays: aDuration totalSeconds // 86400!
- aDateOrDuration
	^(aDateOrDuration isKindOf: Date)
		ifTrue: [Duration days: self asDays - aDateOrDuration asDays]
		ifFalse: [self subtractDays: aDateOrDuration totalSeconds // 86400]!
addMonths: n
	"the same day of the month n months later (clipped to the end of a shorter month)"
	| m y d |
	m := self monthIndex - 1 + n.
	y := year + (m // 12).
	m := m \\ 12 + 1.
	d := self dayOfMonth min: (Date daysInMonth: m forYear: y).
	^Date newDay: d month: m year: y!
addYears: n
	^self addMonths: n * 12!
daysUntil: aDate
	^aDate asDays - self asDays!
daysFrom: aDate
	^self asDays - aDate asDays! !

!Date methodsFor: 'accessing'!
lastDayOfMonth
	^Date newDay: self daysInMonth month: self monthIndex year: year!
monthAbbreviation
	^self monthName copyFrom: 1 to: 3!
dayAbbreviation
	^self dayName copyFrom: 1 to: 3!
weekdayName
	^self dayName!
isLeapYear
	^Date leapYear: year!
isDate
	^true!
asDate
	^self!
asDateAndTime
	^DateAndTime fromSeconds: self asSeconds!
isoString
	^self yyyymmdd! !

!Time methodsFor: 'arithmetic'!
+ aDuration
	^Time fromSeconds: seconds + aDuration totalSeconds!
- aTimeOrDuration
	^(aTimeOrDuration isKindOf: Time)
		ifTrue: [Duration seconds: seconds - aTimeOrDuration asSeconds]
		ifFalse: [Time fromSeconds: seconds - aTimeOrDuration totalSeconds]! !

!Time methodsFor: 'accessing'!
hour
	^self hours!
hour24
	^self hours!
hour12
	| h |
	h := self hours \\ 12.
	^h = 0 ifTrue: [12] ifFalse: [h]!
minute
	^self minutes!
second
	^self seconds!
meridian
	^self hours < 12 ifTrue: ['AM'] ifFalse: ['PM']!
isTime
	^true!
asTime
	^self!
asDateAndTime
	^DateAndTime fromSeconds: Date today asSeconds + seconds! !

!Time class methodsFor: 'instance creation'!
hours: h minutes: m seconds: s
	^self fromSeconds: h * 3600 + (m * 60) + s!
midnight
	^self fromSeconds: 0!
noon
	^self fromSeconds: 43200! !

!Object methodsFor: 'testing'!
isDate
	^false!
isTime
	^false! !
