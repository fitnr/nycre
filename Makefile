BIN = node_modules/.bin
CSVSORT = csvsort
CSVGREP = csvgrep
MYSQL = mysql --user="$(USER)" $(PASSFLAG)$(PASS)

SALES = json/sales.json

SUMMARIES = json/summaries.json

ROLLING = json/rolling.json

HEADER = header.txt

YEARS := 2003 2004 2005 \
	2006 2007 2008 2009 2010 \
	2011 2012 2013 2014

BOROUGHS = manhattan bronx brooklyn queens statenisland

BOROUGHCSV = $(addsuffix .csv,$(BOROUGHS))

SUMMARYFILES := $(addprefix summaries/,$(BOROUGHCSV))

ROLLINGCSVFILES := $(addprefix rolling/raw/borough/,$(BOROUGHCSV))

DATABASE = nycre

CURLFLAGS = --progress-bar

PASSFLAG = -p
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

all: $(foreach y,$(YEARS),sales/$y-city.csv)

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
	$(BIN)/j --quiet --file $^ | grep -v -e '^,\+$$' -v -e '^$$' > $@

rolling/raw/borough/%.xls: $(ROLLING) | rolling/raw/borough
	$(BIN)/json .$* --array -f $< | \
	xargs curl $(CURLFLAGS) > $@

mysql: $(addprefix mysql-,$(foreach b,$(BOROUGHS),$(foreach y,$(YEARS),$y-$b))) | mysqlcreate

mysql-%: sales/raw/%.csv | mysqlcreate
	$(MYSQL) --local-infile --execute="LOAD DATA LOCAL INFILE '$<' INTO TABLE $(DATABASE).sales \
	FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '\"' LINES TERMINATED BY '\n' IGNORE 1 LINES \
	(borough,@nabe,@category,@dummy_tax_class,block,lot,easement,@dummy_bldg_class,@addr,@apt,zip,resunits,comunits,ttlunits,@land_sf,@gross_sf,yearbuilt,@taxclass,@buildingclass,@price,@date) \
	SET neighborhood=TRIM(@nabe), \
	address=$(CASE_ADDR), \
	apt=$(CASE_APT), \
	gross_sf=REPLACE(@gross_sf, ',', ''), \
	land_sf=REPLACE(@land_sf, ',', ''), \
	taxclass=TRIM(@taxclass), \
	price=REPLACE(REPLACE(@price, '$$', ''), ',', ''), \
	buildingclasscat=SUBSTRING_INDEX(@category, ' ', 1), \
	buildingclass=TRIM(@buildingclass), \
	date=STR_TO_DATE(@date, '%m/%d/%y')"

mysqlcreate: sql/mysql-create-tables.sql building-class.csv
	$(MYSQL) --execute="CREATE DATABASE IF NOT EXISTS $(DATABASE)"
	$(MYSQL) --database='$(DATABASE)' < $<
	$(MYSQL) --local-infile --execute="LOAD DATA LOCAL INFILE '$(lastword $^)' INTO TABLE $(DATABASE).building_class \
  	FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '\"' IGNORE 1 LINES (id,name);"

sales/%-city.csv: $(addprefix sales/raw/%-,$(BOROUGHCSV)) | sales
	{ cat $(HEADER) ; $(foreach file,$^,tail -n+2 $(file) ;) } > $@

# sed: removes whitespace
# awk: removes unnec quotes
# grep: removes blank lines
sales/raw/%.csv: sales/raw/%.xls
	$(BIN)/j --quiet --file $^ | \
	sed -Ee 's/ +("?),/\1,/g' | \
	awk '/([",]{1,3}[A-Z \-]+)$$/ { printf("%s", $$0); next } 1' | \
	grep -v -e '^$$' -v -e '^,\+$$' -v -e 'Rolling Sales File' -v -e '^Building Class Category is based on' \
	-v -e ' All Sales F' -v -e 'Descriptive Data is as of' -v -e 'Coop Sales Files as of' > $@

sales/raw/%.xls: $(SALES) | sales/raw
	BASE=$* ; \
	$(BIN)/json -f $< .$${BASE%%-*}.$${BASE##*-} --array | \
	xargs curl $(CURLFLAGS) > $@

summary: $(SUMMARYFILES)

summaries/%.csv: summaries/%.xls | summaries
	$(BIN)/j --quiet --list-sheets $^ | xargs | \
	sed -e 's/ Sales//g' -e 's/[[:space:]]/,/g' | \
	xargs -I{} $(BIN)/sheetstack --groups {} --group-name year --rm-lines 4 $<| \
	sed -Ee 's/ +("?),/\1,/g' > $@

summaries/%.xls: $(SUMMARIES)
	$(BIN)/json -f $< .$* | \
	xargs curl $(CURLFLAGS) > $@

rolling/raw/borough summaries sales sales/raw: ; mkdir -p $@

clean: ; rm -rf rolling summaries sales

mysqlclean: ; $(MYSQL) --execute "DROP DATABASE IF EXISTS nycre;"

install:
	npm install
	pip list | grep csvkit || pip install csvkit --user
