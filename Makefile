BIN = node_modules/.bin
CSVSORT = csvsort
CSVGREP = csvgrep
MYSQL := mysql --user="$(USER)" -p$(PASS)

SALES = json/sales.json

SUMMARIES = json/summaries.json

ROLLING = json/rolling.json

HEADER = header.txt

YEARS = $(shell $(BIN)/json --keys --array < $(SALES))

BOROUGHS = manhattan bronx brooklyn queens statenisland

BOROUGHCSV = $(addsuffix .csv,$(BOROUGHS))

SUMMARYFILES := $(addprefix summaries/,$(BOROUGHCSV))

ROLLINGCSVFILES := $(addprefix rolling/raw/borough/,$(BOROUGHCSV))

DATABASE = nycre

PASS ?=

CASE_ADDR = CASE \
	WHEN POSITION(' UNIT' IN @addr) \
	    THEN TRIM(TRIM(TRAILING '.' FROM TRIM(TRAILING ',' FROM TRIM(SUBSTRING_INDEX(@addr, ' UNIT', 1))))) \
	WHEN POSITION(', APT' IN @addr) \
	    THEN TRIM(TRIM(TRAILING '.' FROM TRIM(SUBSTRING_INDEX(@addr, ', APT', 1)))) \
	WHEN POSITION(' APT.' IN @addr) \
	    THEN TRIM(TRIM(TRAILING '.' FROM TRIM(SUBSTRING_INDEX(@addr, ' APT.', 1)))) \
	WHEN @addr REGEXP ', ?\#' \
	    THEN TRIM(TRIM(TRAILING '.' FROM TRIM(TRAILING ',' FROM TRIM(SUBSTRING_INDEX(@addr, '\#', 1))))) \
	WHEN POSITION(', ' IN @addr) \
	    THEN TRIM(TRIM(TRAILING '.' FROM TRIM(SUBSTRING_INDEX(@addr, ', ', 1)))) \
	ELSE TRIM(@addr) END

CASE_APT = CASE \
	WHEN POSITION(' UNIT' IN @addr) \
		THEN TRIM(TRIM(LEADING '.' FROM TRIM(TRIM(LEADING '\#' FROM TRIM(SUBSTRING_INDEX(@addr, ' UNIT', -1)))))) \
	WHEN POSITION(', APT' IN @addr) \
	    THEN TRIM(TRIM(LEADING '.' FROM TRIM(TRIM(LEADING '\#' FROM TRIM(SUBSTRING_INDEX(@addr, ', APT', -1)))))) \
	WHEN POSITION(' APT.' IN @addr) \
	    THEN TRIM(TRIM(LEADING '.' FROM TRIM(TRIM(LEADING '\#' FROM TRIM(SUBSTRING_INDEX(@addr, ' APT.', -1)))))) \
	WHEN @addr REGEXP ', ?\#' \
		THEN TRIM(SUBSTRING_INDEX(@addr, ', ', -1)) \
	ELSE @apt END

.PHONY: all rolling mysql mysql-% summary clean mysqlclean install

all: $(addsuffix -city.csv,$(addprefix sales/,$(YEARS)))

# Create rolling files 
# % should be YYYY-MM
rolling/%-city.csv: rolling/raw/city.csv | rolling/raw/borough
	DATE=$* ; YYYY=$${DATE%-*} ; YY=$${YYYY#20} ; MM=$${DATE#*-} ; M=$${MM#0} ; \
	$(CSVGREP) -c 'SALE DATE' -r "$$M/\d{1,2}/$$YY" $< | \
	$(CSVSORT) -c 'SALE DATE',BOROUGH,NEIGHBORHOOD > $@

rolling: rolling/raw/city.csv

.INTERMEDIATE: rolling/raw/city.csv
rolling/raw/city.csv: $(ROLLINGCSVFILES) | rolling/raw/borough
	{ cat $(HEADER) ; $(foreach csv,$(ROLLINGCSVFILES), tail -n+6 $(csv) ;) } > $@	

.INTERMEDIATE: rolling/raw/borough/%.csv
rolling/raw/borough/%.csv: rolling/raw/borough/%.xls | rolling/raw/borough
	$(BIN)/j -f $^ | grep -v -e '^,\+$$' -v -e '^$$' > $@

rolling/raw/borough/%.xls: $(ROLLING) | rolling/raw/borough
	$(BIN)/json .$* --array -f $< | \
	xargs curl > $@

mysql: $(addprefix mysql-,$(YEARS)) | mysqlcreate

mysql-%: sales/%-city.csv | mysqlcreate
	$(MYSQL) --execute="LOAD DATA LOCAL INFILE '$<' INTO TABLE $(DATABASE).sales \
	FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '\"' LINES TERMINATED BY '\n' IGNORE 1 LINES \
	(borough,@nabe,@category,@dummy_tax_class,block,lot,easement,@dummy_bldg_class,@addr,@apt,zip,resunits,comunits,ttlunits,@land_sf,@gross_sf,yearbuilt,taxclass,@buildingclass,@price,@date) \
	SET neighborhood=TRIM(@nabe), \
	address=$(CASE_ADDR), \
	apt=$(CASE_APT), \
	gross_sf=REPLACE(@gross_sf, ',', ''), \
	land_sf=REPLACE(@land_sf, ',', ''), \
	price=REPLACE(REPLACE(@price, '$$', ''), ',', ''), \
	buildingclasscat=SUBSTRING_INDEX(@category, ' ', 1), \
	buildingclass=TRIM(@buildingclass), \
	date=STR_TO_DATE(@date, '%Y-%m-%d')"

mysqlcreate: create-tables.sql
	$(MYSQL) --execute="CREATE DATABASE IF NOT EXISTS $(DATABASE)"
	$(MYSQL) --database='$(DATABASE)' < $^

sales/%-city.csv: $(addprefix sales/%/,$(BOROUGHCSV)) | sales
	{ cat $(HEADER) ; $(foreach file,$^,tail -n+6 $(file) ;) } | \
	$(CSVSORT) -c 'SALE DATE',BOROUGH,NEIGHBORHOOD > $@

# sed: removes whitespace
# awk: removes unnec quotes
# grep: removes blank lines
sales/%.csv: sales/%.xls
	$(BIN)/j -f $^ | \
	sed -Ee 's/ +("?),/\1,/g' | \
	awk '/([",]{1,3}[A-Z \-]+)$$/ { printf("%s", $$0); next } 1' | \
	grep -v -e '^$$' -v -e '^,\+$$' > $@

sales/%.xls: $(SALES)
	@mkdir -p $(@D)
	BASE=$* ; \
	$(BIN)/json -f $< .$${BASE%%-*}.$${BASE##*-} --array | \
	xargs curl > $@

summary: $(SUMMARYFILES)

summaries/%.csv: summaries/%.xls | summaries
	$(BIN)/j -l $^ | xargs | \
	sed -e 's/ Sales//g' -e 's/[[:space:]]/,/g' | \
	xargs -I{} $(BIN)/sheetstack --groups {} --group-name year --rm-lines 4 $<| \
	sed -Ee 's/ +("?),/\1,/g' > $@

summaries/%.xls: $(SUMMARIES)
	$(BIN)/json -f $< .$* | \
	xargs curl > $@

rolling/raw/borough summaries: ; mkdir -p $@

clean: ; rm -rf rolling summaries sales

mysqlclean: ; $(MYSQL) --execute "DROP DATABASE IF EXISTS nycre;"

install:
	npm install
	pip list | grep csvkit || pip install csvkit --user
