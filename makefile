.PHONY: all clean

rwildcard=$(foreach d,$(wildcard $(1:=/*)),$(call rwildcard,$d,$2) $(filter $(subst *,%,$2),$d))

MD_FILES=$(call rwildcard,./,*.md)
TMP_FILES=$(patsubst %.md,%.tmp,$(MD_FILES))
OUT_FILES=$(patsubst %.md,%.html,$(MD_FILES))

all: $(OUT_FILES)

%.tmp: %.md
	./pandoc/dyndown.sh $< $@

%.html: %.tmp
	pandoc -f markdown -t html5+smart \
	  --standalone --embed-resources \
	  --css=pandoc/theme.css \
	  --css=pandoc/skylighting-solarized-theme.css \
	  --template=pandoc/template.html5 \
	  --toc \
	  --metadata-file=pandoc/meta.yaml \
	  $< -o $@

clean:
	rm -f $(TMP_FILES) $(OUT_FILES)