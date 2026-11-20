"Greek: Modern Greek grammar - verbs in every tense and both voices, nouns, articles, adjectives and pronouns, with a lexicon"
| dir |
dir := Smalltalk packagePath: 'Greek'.
#('text.st' 'verbs.st' 'nouns.st' 'lexicon.st' 'tool.st') do: [:f | Smalltalk fileIn: dir, '/', f]!
SystemMenu add: 'greek paradigm...' receiver: GreekTool selector: #open!
