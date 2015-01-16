BIN = node_modules/.bin

SALES = json/sales.json

SUMMARIES = json/summaries.json

ROLLING = json/rolling.json

JSONTOOL = $(shell $(BIN)/json $(2) --array < $(1))

YEARS = $(shell $(BIN)/json --keys --array < $(SALES))

BOROUGHS = bronx brooklyn queens manhattan statenisland
BOROUGHCSV = $(addsuffix .csv,$(BOROUGHS))

SALESFILES := $(addprefix sales/,$(foreach y,$(YEARS),$(addprefix $(y)/,$(BOROUGHCSV))))

SUMMARYFILES := $(addprefix summaries/,$(BOROUGHCSV))

ROLLINGRAWFILES := $(addprefix rolling/raw/borough/,$(BOROUGHCSV))

comma = ,
space :=
space +=

data: $(SALESFILES) $(SUMMARYFILES)

.PHONY: rolling
rolling: 

# % should be YYYY-MM
rolling/%-city.csv: rolling/raw/city.csv | rolling/raw/borough
	$(eval y = $(shell date -jf '%Y-%m' '$*' +'%y'))
	$(eval m = $(shell date -jf '%Y-%m' '$*' +'%-m'))

	grep $< -e '$(m)/[0-9][0-9]\?/$(y)' > $@

.INTERMEDIATE: rolling/raw/city.csv
rolling/raw/city.csv:
	{ $(foreach borough,$(BOROUGHS),curl "$(call JSONTOOL,$(ROLLING),.$(borough))" | $(BIN)/j -f - ;) } | cat > $@	

sales/%.csv: | sales
	$(eval borough = $(shell echo $* | sed 's|[0-9]\{4\}/||'))
	$(eval year = $(shell echo $* | sed 's|/[a-z]*||'))
	$(eval URL = $(call JSONTOOL,$(SALES),.$(year).$(borough)))
	@echo .$(year).$(borough)
	@echo "$(call JSONTOOL,$(SALES),.$(year).$(borough))"
	@echo "$(call JSONTOOL,$(SALES),.$(year))"
	curl "$(URL)" | $(BIN)/j -f - > $@
	
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
