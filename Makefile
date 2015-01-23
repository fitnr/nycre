BIN = node_modules/.bin

SALES = json/sales.json

SUMMARIES = json/summaries.json

ROLLING = json/rolling.json

HEADER = header.txt

JSONTOOL = $(shell $(BIN)/json $(2) --array < $(1))

YEARS = $(shell $(BIN)/json --keys --array < $(SALES))

BOROUGHS = manhattan bronx brooklyn queens statenisland

BOROUGHCSV = $(addsuffix .csv,$(BOROUGHS))

SALESFILES := $(addprefix sales/,$(addsuffix .csv,$(YEARS)))

SUMMARYFILES := $(addprefix summaries/,$(BOROUGHCSV))

ROLLINGCSVFILES := $(addprefix rolling/raw/borough/,$(BOROUGHCSV))

comma = ,
space :=
space +=

data: $(SALESFILES) $(SUMMARYFILES)

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

.INTERMEDIATE: rolling/raw/borough/%.xls
rolling/raw/borough/%.xls: | rolling/raw/borough
	curl "$(call JSONTOOL,$(ROLLING),.$*)" > $@

sales/%.csv: | sales
	{ $(foreach borough,$(BOROUGHS),curl "$(call JSONTOOL,$(SALES),.$*.$(borough))" | $(BIN)/j -f - | tail -n+4 ;) } > $@
	
summaries/%.csv: | summaries
	curl "$(call JSONTOOL,$(SUMMARIES),.$*)" > summaries/$*.xls
	$(eval sheets = $(subst $(space)Sales$(space),$(comma),$(shell $(BIN)/j -l summaries/$*.xls)))
	bin/sheetstack --groups $(sheets) --group-name year --rm-lines 4 summaries/$*.xls > $@

sales: ; mkdir -p $(addprefix sales/,$(YEARS))

summaries/city: summaries ; mkdir -p summaries/city
summaries: ; mkdir -p summaries

rolling/raw/borough: ; mkdir -p rolling/raw/borough

.PHONY: clean
clean:
	rm -rf rolling summaries sales

.PHONY: install
install:
	npm install
	pip list | grep csvkit || pip install csvkit --user
