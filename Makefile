BIN = node_modules/.bin

SALES = json/sales.json

SUMMARIES = json/summaries.json

ROLLING = json/rolling.json

HEADER = header.txt

JSONTOOL = $(shell $(BIN)/json $(2) --array < $(1))

YEARS = $(shell $(BIN)/json --keys --array < $(SALES))

BOROUGHS = manhattan bronx brooklyn queens statenisland

BOROUGHCSV = $(addsuffix .csv,$(BOROUGHS))

MYSQLPHONY := $(addprefix mysql-,$(YEARS))
SUMMARYFILES := $(addprefix summaries/,$(BOROUGHCSV))

ROLLINGCSVFILES := $(addprefix rolling/raw/borough/,$(BOROUGHCSV))

comma = ,
space :=
space +=

DATABASE = nycre

PASS ?= ''

.PHONY: all
all: $(addsuffix -city.csv,$(addprefix sales/,$(YEARS)))

# Create rolling files 
# % should be YYYY-MM
rolling/%-city.csv: rolling/raw/city.csv | rolling/raw/borough
	$(eval y = $(shell date -jf '%Y-%m' '$*' +'%y'))
	$(eval m = $(shell date -jf '%Y-%m' '$*' +'%-m'))
	{ cat $(HEADER) ; grep $< -e '$(m)/[0-9][0-9]\?/$(y)' ; } > $@

.INTERMEDIATE: rolling/raw/city.csv
rolling/raw/city.csv: $(ROLLINGCSVFILES) | rolling/raw/borough
	{ cat $(HEADER) ; $(foreach csv,$(ROLLINGCSVFILES), tail -n+6 $(csv) ;) } > $@	

.INTERMEDIATE: rolling/raw/borough/%.csv
rolling/raw/borough/%.csv: rolling/raw/borough/%.xls | rolling/raw/borough
	$(BIN)/j -f $^ | grep -v -e '^,\+$$' -v -e '^$$' > $@

rolling/raw/borough/%.xls: | rolling/raw/borough
	curl "$(call JSONTOOL,$(ROLLING),.$*)" > $@

.PHONY: mysql
mysql: $(MYSQLPHONY) | mysqlcreate

.PHONY: mysql-%
mysql-%: sales/%-city.csv | mysqlcreate
	mysql --user="$(USER)" -p$(PASS) --database="$(DATABASE)" --execute="LOAD DATA LOCAL INFILE '$^' INTO TABLE sales FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '\"' LINES TERMINATED BY '\n' IGNORE 1 LINES (borough,neighborhood,@category,taxclass,block,lot,easement,bldgclass,address,apt,zipcode,res_units,com_units,ttl_units,@land_sf,@gross_sf,yearbuilt,taxclass,@dummy,@price,@date) SET gross_sf=REPLACE(@gross_sf, ',', ''), land_sf=REPLACE(@land_sf, ',', ''), price=REPLACE(REPLACE(@price, '$$', ''), ',', ''), bldgcatid=SUBSTRING_INDEX(@category, ' ', 1), date=STR_TO_DATE(@date, '%m/%d/%y')"

mysqlcreate: create-tables.sql
	mysql -user="$(USER)" -p$(PASS) --execute="CREATE DATABASE IF NOT EXISTS $(DATABASE)"
	mysql -user="$(USER)" -p$(PASS) --database=$(DATABASE) < $^

sales/%-city.csv: $(addprefix sales/%/,$(BOROUGHCSV)) | sales
	{ cat $(HEADER) ; $(foreach file,$^,tail -n+6 $(file) ;) } > $@

sales/%.csv: sales/%.xls | sales
	$(BIN)/j -f $^ | sed -Ee 's/ +("?),/\1,/g' | awk '/([",]{1,3}[A-Z \-]+)$$/ { printf("%s", $$0); next } 1' | grep -v -e '^$$' -v -e '^,\+$$' > $@

sales/%.xls: | sales
	$(eval borough = $(shell echo $* | sed 's|[0-9]\{4\}/||'))
	$(eval year = $(shell echo $* | sed 's|/[a-z]*||'))

	curl "$(call JSONTOOL,$(SALES),.$(year).$(borough))" > $@

sales: ; mkdir -p $(addprefix sales/,$(YEARS))

.PHONY: summary
summary: $(SUMMARYFILES)

summaries/%.csv: summaries/%.xls | summaries
	$(eval sheets = $(subst Sales,,$(subst $(space)Sales$(space),$(comma),$(shell $(BIN)/j -l $^))))
	$(BIN)/sheetstack --groups $(sheets) --group-name year --rm-lines 4 summaries/$*.xls | sed -Ee 's/ +("?),/\1,/g' > $@

summaries/%.xls:
	curl "$(call JSONTOOL,$(SUMMARIES),.$*)" > $@

summaries/city: summaries ; mkdir -p summaries/city
summaries: ; mkdir -p summaries

rolling/raw/borough: ; mkdir -p rolling/raw/borough

.PHONY: clean
clean:
	rm -rf rolling summaries sales

.PHONE: mysqlclean
mysqlclean:
	mysql --user="$(USER)" -p$(PASS) --execute "DROP DATABASE IF EXISTS nycre;"

.PHONY: install
install:
	npm install
	pip list | grep csvkit || pip install csvkit --user
