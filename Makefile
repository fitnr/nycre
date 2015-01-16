BIN = node_modules/.bin

ROLLING = json/rolling.json

JSONTOOL = $(shell $(BIN)/json $(2) --array < $(1))


BOROUGHS = bronx brooklyn queens manhattan statenisland
BOROUGHCSV = $(addsuffix .csv,$(BOROUGHS))

ROLLINGRAWFILES := $(addprefix rolling/raw/borough/,$(BOROUGHCSV))

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


rolling/raw/borough: ; mkdir -p rolling/raw/borough

.PHONY: install
install:
	npm install
