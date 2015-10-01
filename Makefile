BIN = node_modules/.bin
CSVSORT = csvsort
CSVGREP = csvgrep
MYSQL = mysql --user="$(USER)" $(PASSFLAG)$(PASS)
SQLITE = sqlite3

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

SQLITE_CASE_ADDR = CASE \
    WHEN INSTR(ADDRESS, ' UNIT') THEN \
        TRIM(SUBSTR(ADDRESS, 0, INSTR(ADDRESS, ' UNIT'))) \
    WHEN INSTR(ADDRESS, ', UNIT') THEN \
        TRIM(SUBSTR(ADDRESS, 0, INSTR(ADDRESS, ', UNIT'))) \
    WHEN INSTR(ADDRESS, ', APT.') THEN \
        TRIM(SUBSTR(ADDRESS, 0, INSTR(ADDRESS, ', APT.'))) \
    WHEN INSTR(ADDRESS, ', APT') THEN \
        TRIM(SUBSTR(ADDRESS, 0, INSTR(ADDRESS, ', APT'))) \
    WHEN INSTR(ADDRESS, ',APT') THEN \
        TRIM(SUBSTR(ADDRESS, 0, INSTR(ADDRESS, ',APT'))) \
    WHEN INSTR(ADDRESS, '.APT') THEN \
        TRIM(SUBSTR(ADDRESS, 0, INSTR(ADDRESS, '.APT'))) \
    WHEN INSTR(ADDRESS, '. APT.') THEN \
        TRIM(SUBSTR(ADDRESS, 0, INSTR(ADDRESS, '. APT.'))) \
    WHEN INSTR(ADDRESS, ' APT.') THEN \
        TRIM(SUBSTR(ADDRESS, 0, INSTR(ADDRESS, ' APT.'))) \
    WHEN INSTR(ADDRESS , ', \#') THEN \
        TRIM(SUBSTR(ADDRESS, 0, INSTR(ADDRESS, ', \#'))) \
    WHEN INSTR(ADDRESS , ' \#') THEN \
        TRIM(SUBSTR(ADDRESS, 0, INSTR(ADDRESS, ' \#'))) \
    ELSE TRIM(ADDRESS) END

SQLITE_CASE_APT = CASE \
    WHEN INSTR(ADDRESS, ' UNIT') THEN \
        TRIM(SUBSTR(ADDRESS, 5 + INSTR(ADDRESS, ' UNIT'))) \
    WHEN INSTR(ADDRESS, ', UNIT') THEN \
        TRIM(SUBSTR(ADDRESS, 6 + INSTR(ADDRESS, ', UNIT'))) \
    WHEN INSTR(ADDRESS, ',APT') THEN \
        TRIM(SUBSTR(ADDRESS, 4 + INSTR(ADDRESS, ',APT'))) \
    WHEN INSTR(ADDRESS, '.APT') THEN \
        TRIM(SUBSTR(ADDRESS, 4 + INSTR(ADDRESS, '.APT'))) \
    WHEN INSTR(ADDRESS, ', APT.') THEN \
        TRIM(SUBSTR(ADDRESS, 6 + INSTR(ADDRESS, ', APT'))) \
    WHEN INSTR(ADDRESS, ', APT') THEN \
        TRIM(SUBSTR(ADDRESS, 5 + INSTR(ADDRESS, ', APT'))) \
    WHEN INSTR(ADDRESS, '. APT.') THEN \
        TRIM(SUBSTR(ADDRESS, 6 + INSTR(ADDRESS, ' APT.'))) \
    WHEN INSTR(ADDRESS, '. APT') THEN \
        TRIM(SUBSTR(ADDRESS, 5 + INSTR(ADDRESS, ' APT.'))) \
    WHEN INSTR(ADDRESS, ' APT.') THEN \
        TRIM(SUBSTR(ADDRESS, 5 + INSTR(ADDRESS, ' APT.'))) \
    WHEN INSTR(ADDRESS , ', \#') THEN \
        TRIM(SUBSTR(ADDRESS, 3 + INSTR(ADDRESS, ', \#'))) \
    WHEN INSTR(ADDRESS , ' \#') THEN \
        TRIM(SUBSTR(ADDRESS, 2 + INSTR(ADDRESS, ' \#'))) \
    ELSE TRIM(APARTMENTNUMBER) END

SQLITE_SELECT = BOROUGH borough, \
    DATE(SALEDATE) date, \
    $(SQLITE_CASE_ADDR) address, \
    $(SQLITE_CASE_APT) apt, \
    ZIPCODE zip, \
    TRIM(NEIGHBORHOOD) neighborhood, \
    TRIM(SUBSTR(BUILDINGCLASSCATEGORY, 1, INSTR(BUILDINGCLASSCATEGORY, ' ') - 1)) buildingclasscat, \
    TRIM(BUILDINGCLASSATPRESENT) buildingclass, \
    TAXCLASSATTIMEOFSALE taxclass, \
    BLOCK block, \
    LOT lot, \
    RESIDENTIALUNITS resunits, \
    COMMERCIALUNITS comunits, \
    TOTALUNITS ttlunits, \
    REPLACE(LANDSQUAREFEET, ',', '') land_sf, \
    REPLACE(GROSSSQUAREFEET, ',', '') gross_sf, \
    YEARBUILT yearbuilt, \
    REPLACE(REPLACE(SALEPRICE, '$$', ''), ',', '') price, \
    EASEMENT easement

MYSQL_CASE_ADDR = CASE \
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

MYSQL_CASE_APT = CASE \
	WHEN POSITION(' UNIT' IN @addr) \
		THEN TRIM(TRIM(LEADING '.' FROM TRIM(TRIM(LEADING '\#' FROM TRIM(SUBSTRING_INDEX(@addr, ' UNIT', -1)))))) \
	WHEN POSITION(', APT' IN @addr) \
	    THEN TRIM(TRIM(LEADING '.' FROM TRIM(TRIM(LEADING '\#' FROM TRIM(SUBSTRING_INDEX(@addr, ', APT', -1)))))) \
	WHEN POSITION(' APT.' IN @addr) \
	    THEN TRIM(TRIM(LEADING '.' FROM TRIM(TRIM(LEADING '\#' FROM TRIM(SUBSTRING_INDEX(@addr, ' APT.', -1)))))) \
	WHEN @addr REGEXP ', ?\#' \
		THEN TRIM(SUBSTRING_INDEX(@addr, ', ', -1)) \
	ELSE @apt END

.PHONY: all rolling mysql mysql-% sqlite sqlite-% summary clean mysqlclean install select-%

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
	address=$(MYSQL_CASE_ADDR), \
	apt=$(MYSQL_CASE_APT), \
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

sqlite: $(addprefix sqlite-,$(foreach b,$(BOROUGHS),$(foreach y,$(YEARS),$y-$b))) | nycre.db

sqlite-%: sales/raw/%.csv | nycre.db
	$(SQLITE) -separator , $| '.import "$<" sales_tmp'
	$(SQLITE) $| "INSERT INTO sales SELECT $(SQLITE_SELECT) FROM sales_tmp WHERE BOROUGH != 'BOROUGH';"
	$(SQLITE) $| "DELETE FROM sales_tmp"

$(DATABASE).db: sql/sqlite-create-tables.sql building-class.csv
	$(SQLITE) $@ < $<
	$(SQLITE) -separator , $@ '.import "building-class.csv" building_class'

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

# Dummy tasks for testing
select-mysql:
	$(MYSQL) $(DATABASE) --execute "SELECT borough, COUNT(*) FROM sales GROUP BY borough;"
	$(MYSQL) $(DATABASE) --execute "select r.name, s.buildingclass, b.name, s.buildingclasscat, c.name, t.name, s.taxclass, t.name \
		FROM sales s JOIN building_class b ON s.buildingclass = b.id \
		LEFT JOIN borough r ON r.id = s.borough LEFT JOIN tax_class t ON s.taxclass = t.id \
		LEFT JOIN building_class_category c ON c.id=s.buildingclasscat LIMIT 10;"

select-sqlite: $(DATABASE).db
	$(SQLITE) $< "SELECT borough, COUNT(*) FROM sales GROUP BY borough;"
	$(SQLITE) $< "SELECT r.name, s.buildingclass, b.name, s.buildingclasscat, c.name, t.name, s.taxclass, t.name \
		FROM sales s JOIN building_class b ON s.buildingclass = b.id \
		LEFT JOIN borough r ON r.id = s.borough LEFT JOIN tax_class t ON s.taxclass = t.id \
		LEFT JOIN building_class_category c ON c.id=s.buildingclasscat LIMIT 10;"

mysqlclean: ; $(MYSQL) --execute "DROP DATABASE IF EXISTS nycre;"

install:
	npm install
	pip list | grep csvkit || pip install csvkit --user
