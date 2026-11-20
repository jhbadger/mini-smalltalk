# ORF sizes in *Hyphomonas neptunium*

This notebook measures the annotated ORFs (the CDS features recorded in the GenBank file) of the complete genome of
*Hyphomonas neptunium* ATCC 15444 (`hyphomonas.gb`, a GenBank file of about 3.7 Mb)
and reports their average, minimum and maximum size. Run it from the top with ctrl-R

## 1. Load the packages

`Bio` reads sequence files and finds ORFs; `Stats` adds statistics such as `mean` to
ordinary collections. Loading a package that is already loaded does nothing, so this
cell is safe to run repeatedly.

```smalltalk
Smalltalk loadPackage: 'Bio'.
Smalltalk loadPackage: 'Stats'.
(Smalltalk isPackageLoaded: 'Bio') & (Smalltalk isPackageLoaded: 'Stats')
```
```result
true
```
## 2. Read the genome

`Bio read:` picks the format from the file name and answers a `SequenceCollection` of
records. A bacterial genome is a single record; we keep the first one.

```smalltalk
path := 'hyphomonas.gb'.
(FileStream exists: path)
	ifTrue: [Transcript show: path, ' already exists'; cr]
	ifFalse: [
		Bio download: 'CP000158.1' format: #genbank to: path.
		Transcript show: 'CP000158.1 downloaded'
	].
genome := (Bio read: path) first
```
```result
SeqRecord(CP000158, 3705021 bp, 7121 features)
```

## 3. Get the annotated ORFs

The GenBank file already lists the genome's protein-coding genes as `CDS` features, so there is no need to
search for ORFs ourselves. `cdsFeatures` answers them all, on both strands.

```smalltalk
cds := genome cdsFeatures.
cds size
```
```result
3505
```

## 4. ORF sizes

Each feature knows its location, and `size` is its length in bases (the stop codon is included, and the
parts of a joined location are added up). We collect the sizes into an `Array`, which the `Stats` package can
summarize.

```smalltalk
sizes := (cds collect: [:f | f size]) asArray.
sizes size
```
```result
3505
```

## 5. Average, minimum and maximum

`mean` comes from `Stats`; `min` and `max` are the ordinary collection methods.

```smalltalk
'CDS features: ', sizes size printString, String cr,
'average size: ', (sizes mean printShowingDecimalPlaces: 1), String cr,
'minimum size: ', sizes min printString, String cr,
'maximum size: ', sizes max printString
```
```result
'CDS features: 3505
average size: 957.0
minimum size: 93
maximum size: 6258'
```

## 6. A fuller picture (optional)

The average hides the shape of the distribution, which is usually skewed with a long tail of big ORFs. The
five-number summary (min, Q1, median, Q3, max) and standard deviation show that.

```smalltalk
sizes fiveNumberSummary printString, ' sd: ', (sizes standardDeviation printShowingDecimalPlaces: 1)
```
```result
'#(93 513 825 1221 6258) sd: 625.1'
```
