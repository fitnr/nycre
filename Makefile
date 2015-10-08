BIN = node_modules/.bin
CSVGREP = csvgrep
MYSQL = mysql --user="$(USER)" $(PASSFLAG)$(PASS)
PSQL = psql --username="$(USER)"
SQLITE = sqlite3

BASE = http://www1.nyc.gov/assets/finance/downloads

include ini/sales.ini
include ini/rolling_summaries.ini

HEADER = header.txt

YEARS := 2003 2004 2005 \
	2006 2007 2008 2009 2010 \
	2011 2012 2013 2014

BOROUGHS = manhattan bronx brooklyn queens statenisland

BOROUGHCSV = $(addsuffix .csv,$(BOROUGHS))

SUMMARYFILES := $(addprefix summaries/,$(BOROUGHCSV))

ROLLINGCSVFILES := $(addprefix rolling/raw/borough/,$(BOROUGHCSV))

DB = mysql
DATABASE = nycre

CURLFLAGS = --progress-bar

PASSFLAG = -p
PASS ?=

SQLITE_CASE_ADDR = CASE \
    WHEN INSTR(address, ' UNIT') THEN \
        TRIM(SUBSTR(address, 0, INSTR(address, ' UNIT'))) \
    WHEN INSTR(address, ', UNIT') THEN \
        TRIM(SUBSTR(address, 0, INSTR(address, ', UNIT'))) \
    WHEN INSTR(address, ', APT.') THEN \
        TRIM(SUBSTR(address, 0, INSTR(address, ', APT.'))) \
    WHEN INSTR(address, ', APT') THEN \
        TRIM(SUBSTR(address, 0, INSTR(address, ', APT'))) \
    WHEN INSTR(address, ',APT') THEN \
        TRIM(SUBSTR(address, 0, INSTR(address, ',APT'))) \
    WHEN INSTR(address, '.APT') THEN \
        TRIM(SUBSTR(address, 0, INSTR(address, '.APT'))) \
    WHEN INSTR(address, '. APT.') THEN \
        TRIM(SUBSTR(address, 0, INSTR(address, '. APT.'))) \
    WHEN INSTR(address, ' APT.') THEN \
        TRIM(SUBSTR(address, 0, INSTR(address, ' APT.'))) \
    WHEN INSTR(address , ', \#') THEN \
        TRIM(SUBSTR(address, 0, INSTR(address, ', \#'))) \
    WHEN INSTR(address , ' \#') THEN \
        TRIM(SUBSTR(address, 0, INSTR(address, ' \#'))) \
    ELSE TRIM(address) END

SQLITE_CASE_APT = CASE \
    WHEN INSTR(address, ' UNIT') THEN \
        TRIM(SUBSTR(address, 5 + INSTR(address, ' UNIT'))) \
    WHEN INSTR(address, ', UNIT') THEN \
        TRIM(SUBSTR(address, 6 + INSTR(address, ', UNIT'))) \
    WHEN INSTR(address, ',APT') THEN \
        TRIM(SUBSTR(address, 4 + INSTR(address, ',APT'))) \
    WHEN INSTR(address, '.APT') THEN \
        TRIM(SUBSTR(address, 4 + INSTR(address, '.APT'))) \
    WHEN INSTR(address, ', APT.') THEN \
        TRIM(SUBSTR(address, 6 + INSTR(address, ', APT'))) \
    WHEN INSTR(address, ', APT') THEN \
        TRIM(SUBSTR(address, 5 + INSTR(address, ', APT'))) \
    WHEN INSTR(address, '. APT.') THEN \
        TRIM(SUBSTR(address, 6 + INSTR(address, ' APT.'))) \
    WHEN INSTR(address, '. APT') THEN \
        TRIM(SUBSTR(address, 5 + INSTR(address, ' APT.'))) \
    WHEN INSTR(address, ' APT.') THEN \
        TRIM(SUBSTR(address, 5 + INSTR(address, ' APT.'))) \
    WHEN INSTR(address , ', \#') THEN \
        TRIM(SUBSTR(address, 3 + INSTR(address, ', \#'))) \
    WHEN INSTR(address , ' \#') THEN \
        TRIM(SUBSTR(address, 2 + INSTR(address, ' \#'))) \
    ELSE TRIM(apartmentnumber) END

# Format a MM/DD/YY date into YYYY-MM-DD
# Only works for years that begin with '20'
SQLITE_FORMAT_DATE = '20' || substr(saledate, -2, 2) \
	|| '-' || substr('00' || trim(trim(saledate, '0123456789'), '/'), -2, 2) \
	|| '-' || substr('00' || substr(saledate, 0, instr(saledate, '/')), -2, 2)

SQLITE_SELECT = (borough * 1000000000 + block * 10000 + lot) BBL, \
	borough, \
    $(SQLITE_FORMAT_DATE) date, \
    $(SQLITE_CASE_ADDR) address, \
    $(SQLITE_CASE_APT) apt, \
    zipcode zip, \
    TRIM(neighborhood) neighborhood, \
    TRIM(SUBSTR(buildingclasscategory, 1, INSTR(buildingclasscategory, ' ') - 1)) buildingclasscat, \
    TRIM(buildingclassatpresent) buildingclass, \
    taxclassattimeofsale taxclass, \
    block, \
    lot, \
    residentialunits resunits, \
    commercialunits comunits, \
    totalunits ttlunits, \
    REPLACE(landsquarefeet, ',', '') land_sf, \
    REPLACE(grosssquarefeet, ',', '') gross_sf, \
    yearbuilt, \
    REPLACE(REPLACE(saleprice, '$$', ''), ',', '') price, \
    easement

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
	WHEN POSITION(', ' IN @addr) \
		THEN TRIM(TRIM(TRAILING '.' FROM TRIM(SUBSTRING_INDEX(@addr, ', ', -1)))) \
	ELSE @apt END

MYSQL_INSERT = (borough, @nabe, @category, @dummy_tax_class, \
	block, lot, easement, @dummy_bldg_class, @addr, @apt, zip, \
	resunits, comunits, ttlunits, @land_sf, @gross_sf, yearbuilt, \
	@taxclass, @buildingclass, @price, @date) \
	SET neighborhood=TRIM(@nabe), \
	bbl=(borough * 1000000000 + block * 10000 + lot), \
	address=$(MYSQL_CASE_ADDR), \
	apt=$(MYSQL_CASE_APT), \
	gross_sf=REPLACE(@gross_sf, ',', ''), \
	land_sf=REPLACE(@land_sf, ',', ''), \
	taxclass=TRIM(@taxclass), \
	price=REPLACE(REPLACE(@price, '$$', ''), ',', ''), \
	buildingclasscat=SUBSTRING_INDEX(@category, ' ', 1), \
	buildingclass=TRIM(@buildingclass), \
	date=STR_TO_DATE(@date, '%m/%d/%y')

# can't directly address an array created by a function,
# workaround by joining with a special character string and splitting

PSQL_CASE_ADDR = CASE WHEN \
	ARRAY_LENGTH( \
		REGEXP_SPLIT_TO_ARRAY( \
			address, \
			', | UNIT[\# ]?|[,.] APT[ \#.,]?| ?\# ?' \
		), 1) > 1 \
	THEN TRIM(SUBSTRING( \
		ARRAY_TO_STRING( \
			REGEXP_SPLIT_TO_ARRAY(address, ', | UNIT[\# ]?|[,.] APT[ \#.,]?| ?\# ?'), \
			'~~~') \
		FROM '/"_+/"~~~%' for '/')) \
	ELSE REGEXP_REPLACE(address, ' +', ' ') \
	END

PSQL_CASE_APT = CASE WHEN LENGTH(apartmentnumber) > 0 \
	THEN apartmentnumber \
	ELSE TRIM(SUBSTRING( \
		ARRAY_TO_STRING( \
			REGEXP_SPLIT_TO_ARRAY(address, ', | UNIT[\# ]?|[,.] APT[ \#.,]?| ?\# ?'), \
			'~~~') \
		FROM '%~~~/"_+/"' FOR '/')) \
	END

PSQL_DATE_CONVERT = to_date(concat_ws('-', \
			lpad(split_part(saledate, '/', 1), 2, '0'), \
			lpad(split_part(saledate, '/', 2), 2, '0'),	\
			split_part(saledate, '/', 3) \
		), 'MM/DD/YY' \
	)

PSQL_SELECT = CAST(borough as BIGINT) * 1000000000 + CAST(block as INTEGER) * 10000 + CAST(lot as INTEGER) bbl, \
	borough, \
    CAST(block AS INTEGER) block, \
    CAST(lot AS INTEGER) lot, \
    $(PSQL_DATE_CONVERT) date, \
    $(PSQL_CASE_ADDR) address, \
    $(PSQL_CASE_APT) apt, \
    zipcode zip, \
    TRIM(neighborhood) neighborhood, \
    TRIM(SUBSTRING(buildingclasscategory, 0, POSITION(' ' IN buildingclasscategory))) buildingclasscat, \
    TRIM(buildingclassatpresent) buildingclass, \
    TRIM(taxclassattimeofsale) taxclass, \
    CAST(TRANSLATE(residentialunits, ', ', '') AS INTEGER) resunits, \
    CAST(TRANSLATE(commercialunits, ', ', '') AS INTEGER) comunits, \
    CAST(TRANSLATE(totalunits, ', ', '') AS INTEGER) ttlunits, \
    CAST(TRANSLATE(landsquarefeet, ', ', '') AS INTEGER) land_sf, \
    CAST(TRANSLATE(grosssquarefeet, ', ', '') AS INTEGER) gross_sf, \
    yearbuilt, \
    CAST(TRANSLATE(REPLACE(saleprice, '.00', ''), '-$$, ', '0') AS BIGINT) price, \
    CAST(REPLACE(REPLACE(easement, 'E', 'T'), ' ', '0') AS BOOL) easement

SALES_FIELDS = bbl, \
    borough, block, lot, \
    date, \
    address, apt, zip, \
    neighborhood, \
    buildingclasscat, buildingclass, \
    taxclass, \
    resunits, comunits, ttlunits, \
    land_sf, gross_sf, \
    yearbuilt, \
    price, \
    easement

SALES_TMP_FIELDS = borough, \
    neighborhood, \
    buildingclasscategory, \
    taxclassatpresent, \
    block, lot, \
    easement, \
    buildingclassatpresent, \
    address, apartmentnumber, zipcode, \
    residentialunits, commercialunits, totalunits, \
    landsquarefeet, grosssquarefeet, \
    yearbuilt, \
    taxclassattimeofsale, buildingclassattimeofsale, \
    saleprice, saledate

.PHONY: all rolling database mysql mysql-% postresql psql-% \
	sqlite sqlite-% summary clean mysqlclean install select-% \
	rolling-mysql-% rolling-sqlite-% rolling-postgresql-%

all: $(foreach y,$(YEARS),sales/$y-city.csv)

# Create rolling files 
# % should be YYYY-MM
rolling/%-city.csv: rolling/raw/city.csv | rolling/raw/borough
	DATE=$* ; YYYY=$${DATE%-*} ; YY=$${YYYY#20} ; MM=$${DATE#*-} ; M=$${MM#0} ; \
	$(CSVGREP) -c SALE_DATE -r "$$M/\d{1,2}/$$YY" $< > $@

rolling: rolling/raw/city.csv

# load YYYY-MM into mysql $(DATABASE)
rolling-mysql-%: rolling/%-city.csv
	$(MYSQL) $(MYSQLFLAGS) --database $(DATABASE) --local-infile \
	--execute "LOAD DATA LOCAL INFILE '$^' INTO TABLE $(DATABASE).sales \
	FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '\"' IGNORE 1 LINES \
	$(MYSQL_INSERT);"

rolling-postgresql-%: rolling/%-city.csv
	tail -n+2 $< | $(PSQL) $(PSQLFLAGS) --dbname $(DATABASE) --command "COPY sales_tmp($(SALES_TMP_FIELDS)) \
	FROM stdin DELIMITER ',' CSV QUOTE '\"';"

	$(PSQL) $(PSQLFLAGS) --dbname $(DATABASE) --command "WITH a AS ( \
	DELETE FROM sales_tmp RETURNING $(PSQL_SELECT)) \
	INSERT INTO sales SELECT $(SALES_FIELDS) FROM a;"

rolling-sqlite-%: rolling/%-city.csv | $(DATABASE).db
	$(SQLITE) $(SQLITEFLAGS) -separator , $| ".import $< sales_tmp"
	$(SQLITE) $(SQLITEFLAGS) $| "INSERT INTO sales SELECT $(SQLITE_SELECT) \
	FROM sales_tmp WHERE STRFTIME('%Y-%m', DATE(saledate)) = '$*';"
	$(SQLITE) $(SQLITEFLAGS) $| "DELETE FROM sales_tmp"

.INTERMEDIATE: rolling/raw/city.csv
rolling/raw/city.csv: $(ROLLINGCSVFILES) | rolling/raw/borough
	{ cat $(HEADER) ; $(foreach csv,$(ROLLINGCSVFILES), tail -n+6 $(csv) ;) } > $@	

.INTERMEDIATE: rolling/raw/borough/%.csv
rolling/raw/borough/%.csv: rolling/raw/borough/%.xls | rolling/raw/borough
	$(BIN)/j --quiet --file $^ | grep -v -e '^,\+$$' -v -e '^$$' > $@

$(foreach b,$(BOROUGHS),rolling/raw/borough/$b.xls): rolling/raw/borough/%.xls: | rolling/raw/borough
	curl $(CURLFLAGS) $(ROLLING-$*) > $@

mysql: $(addprefix mysql-,$(foreach b,$(BOROUGHS),$(foreach y,$(YEARS),$y-$b))) | mysqlcreate

mysql-%: sales/raw/%.csv | mysqlcreate
	$(MYSQL) $(MYSQLFLAGS) --local-infile --execute="LOAD DATA LOCAL INFILE '$<' INTO TABLE $(DATABASE).sales \
	FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '\"' LINES TERMINATED BY '\n' \
	$(MYSQL_INSERT);"

mysqlcreate: sql/mysql-create-tables.sql building-class.csv
	$(MYSQL) $(MYSQLFLAGS) --execute="CREATE DATABASE IF NOT EXISTS $(DATABASE)"
	$(MYSQL) $(MYSQLFLAGS) --database='$(DATABASE)' < $<
	$(MYSQL) $(MYSQLFLAGS) --local-infile --execute="LOAD DATA LOCAL INFILE '$(lastword $^)' INTO TABLE $(DATABASE).building_class \
  	FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '\"' IGNORE 1 LINES (id,name);"

postgresql: $(addprefix psql-,$(foreach b,$(BOROUGHS),$(foreach y,$(YEARS),$y-$b))) | psqlcreate

psql-%: sales/raw/%.csv | psqlcreate
	$(PSQL) $(PSQLFLAGS) --dbname $(DATABASE) \
	--command "COPY sales_tmp($(SALES_TMP_FIELDS)) FROM '$(abspath $<)' DELIMITER ',' CSV QUOTE '\"';"

	$(PSQL) $(PSQLFLAGS) --dbname $(DATABASE) --command "WITH a AS ( \
	DELETE FROM sales_tmp RETURNING $(PSQL_SELECT)) \
	INSERT INTO sales SELECT $(SALES_FIELDS) FROM a;"

psqlcreate: sql/psql-create-tables.sql building-class.csv
	$(PSQL) $(PSQLFLAGS) --command "CREATE DATABASE $(DATABASE)" || echo "$(DATABASE) probably exists"

	$(PSQL) --dbname=$(DATABASE) $(PSQLFLAGS) --single-transaction < $<

	tail -n+2 $(lastword $^) | \
	$(PSQL) --dbname=$(DATABASE) $(PSQLFLAGS) --command="COPY building_class(id, name) \
	FROM stdin DELIMITER ',' CSV QUOTE '\"';" || :

sqlite: $(addprefix sqlite-,$(foreach b,$(BOROUGHS),$(foreach y,$(YEARS),$y-$b))) | $(DATABASE).db

sqlite-%: sales/raw/%.csv | $(DATABASE).db
	$(SQLITE) $(SQLITEFLAGS) -separator , $| '.import "$<" sales_tmp'
	$(SQLITE) $(SQLITEFLAGS) $| "INSERT INTO sales SELECT $(SQLITE_SELECT) FROM sales_tmp WHERE BOROUGH != 'BOROUGH';"
	$(SQLITE) $(SQLITEFLAGS) $| "DELETE FROM sales_tmp"

$(DATABASE).db: sql/sqlite-create-tables.sql building-class.csv
	$(SQLITE) $(SQLITEFLAGS) $@ < $<
	$(SQLITE) $(SQLITEFLAGS) -separator , $@ '.import "building-class.csv" building_class'

summary: $(SUMMARYFILES)

summaries/%.csv: summaries/%.xls
	$(BIN)/j --quiet --list-sheets $^ | xargs | \
	sed -e 's/ Sales//g' -e 's/[[:space:]]/,/g' | \
	xargs -I{} $(BIN)/sheetstack --groups {} --group-name year --rm-lines 4 $<| \
	sed -Ee 's/ +("?),/\1,/g' > $@

summaries/%.xls: summaries
	curl $(CURLFLAGS) $(SUMMARY-$*) > $@

sales/%-city.csv: $(addprefix sales/raw/%-,$(BOROUGHCSV)) | sales
	cat $(HEADER) $^ > $@

sales/raw/%.xls: | sales/raw
	curl $(CURLFLAGS) $(SALES-$*) > $@

.SECONDARY:
# sed: removes whitespace
# awk: removes unnec line breaks in quotes
# grep: removes blank lines
sales/raw/%.csv: sales/raw/%.xls
	$(BIN)/j --quiet --file $^ | \
	sed -Ee 's/ +("?),/\1,/g' | \
	awk '/^("?,?"[A-Z \-]+)$$/ { printf("%s", $$0); next } 1' | \
	grep -v -e '^$$' -v -e '^,\+$$' -v -e 'Rolling Sales File' -v -e '^Building Class Category is based on' \
	-v -e 'ANNUALIZE SALES FOR' -v -e 'BUILDING CLASS AT TIME OF SALE' \
	-v -e ' All Sales F' -v -e 'Descriptive Data is as of' -v -e 'Coop Sales Files as of' > $@

rolling/raw/borough summaries sales sales/raw: ; mkdir -p $@

clean: ; rm -rf rolling summaries sales

# Dummy tasks for testing
select-mysql:
	$(MYSQL) $(MYSQLFLAGS) $(DATABASE) --execute "SELECT borough, COUNT(*) FROM sales GROUP BY borough;"
	$(MYSQL) $(MYSQLFLAGS) $(DATABASE) --execute "select r.name, s.buildingclass, b.name, s.buildingclasscat, c.name, t.name, s.taxclass, t.name \
		FROM sales s JOIN building_class b ON s.buildingclass = b.id \
		LEFT JOIN borough r ON r.id = s.borough LEFT JOIN tax_class t ON s.taxclass = t.id \
		LEFT JOIN building_class_category c ON c.id=s.buildingclasscat LIMIT 10;"
	$(MYSQL) $(MYSQLFLAGS) $(DATABASE) -e "SELECT YEAR(date) year, count(*) FROM sales group BY YEAR(date);"

select-postgresql:
	$(PSQL) $(PSQLFLAGS) --dbname $(DATABASE) -Atc "SELECT borough, COUNT(*) FROM sales GROUP BY borough;"
	$(PSQL) $(PSQLFLAGS) --dbname $(DATABASE) -Atc "SELECT r.name, s.buildingclass, b.name, s.buildingclasscat, c.name, t.name, s.taxclass, t.name \
		FROM sales s JOIN building_class b ON s.buildingclass = b.id \
		LEFT JOIN borough r ON r.id = s.borough LEFT JOIN tax_class t ON s.taxclass = t.id \
		LEFT JOIN building_class_category c ON c.id=s.buildingclasscat LIMIT 10;"
	$(PSQL) $(PSQLFLAGS) --dbname $(DATABASE) -Atc "SELECT date_part('year', date), count(*) FROM sales group BY date_part('year', date)"

select-sqlite: $(DATABASE).db
	$(SQLITE) $(SQLITEFLAGS) $< "SELECT borough, COUNT(*) FROM sales GROUP BY borough;"
	$(SQLITE) $(SQLITEFLAGS) $< "SELECT r.name, s.buildingclass, b.name, s.buildingclasscat, c.name, t.name, s.taxclass, t.name \
		FROM sales s JOIN building_class b ON s.buildingclass = b.id \
		LEFT JOIN borough r ON r.id = s.borough LEFT JOIN tax_class t ON s.taxclass = t.id \
		LEFT JOIN building_class_category c ON c.id=s.buildingclasscat LIMIT 10;"
	$(SQLITE) $(SQLITEFLAGS) $< "SELECT date, count(*) FROM sales group BY STRFTIME(date, '%Y-%m');"

mysqlclean: ; $(MYSQL) --execute "DROP DATABASE IF EXISTS $(DATABASE);"
postgresqlclean: ; $(PSQL) --command "DROP DATABASE $(DATABASE);"

install:
	npm install
	pip list | grep csvkit || pip install csvkit --user
