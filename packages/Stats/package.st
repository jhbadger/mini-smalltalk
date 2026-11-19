"Stats: tables and statistics - CSV, DataTable, descriptive statistics, hypothesis tests, regression and text plots"
| dir |
Smalltalk loadPackage: 'SUnit'.        "the tests are written in it"
dir := Smalltalk packagePath: 'Stats'.
#('distribution.st' 'statistics.st' 'inference.st' 'csv.st' 'table.st' 'plot.st' 'facade.st' 'tests.st')
	do: [:f | Smalltalk fileIn: dir, '/', f]!
SystemMenu add: 'table browser' receiver: TableBrowser selector: #open!
