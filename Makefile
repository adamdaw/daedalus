PANDOC_VERSION := 3.1.12

# Set PROPOSAL=name to build proposals/name/; omit to build the root example.
ifdef PROPOSAL
  PROPOSAL_DIR := proposals/$(PROPOSAL)
else
  PROPOSAL_DIR := .
endif

MARKDOWN := $(sort $(wildcard $(PROPOSAL_DIR)/markdown/*.md))
OUTPUT   := $(PROPOSAL_DIR)/project.pdf
HTML_OUT := $(PROPOSAL_DIR)/project.html
CONFIG   := $(PROPOSAL_DIR)/config.yaml
BIB      := $(PROPOSAL_DIR)/project.bib
IMAGES   := $(PROPOSAL_DIR)/images

PANDOC_FLAGS = \
	--metadata-file=$(CONFIG) \
	-F mermaid-filter \
	--toc \
	-H project.tex \
	$(if $(DRAFT),-H draft.tex,) \
	-V subparagraph \
	--css project.css \
	--bibliography $(BIB) \
	--citeproc \
	--resource-path=.:$(IMAGES)

.PHONY: build html all clean check watch lint spellcheck wordcount archive init \
        docker-build docker-run

build: check
	pandoc $(MARKDOWN) $(PANDOC_FLAGS) \
		--pdf-engine=xelatex \
		-o $(OUTPUT)

html: check-pandoc
	pandoc $(MARKDOWN) $(PANDOC_FLAGS) \
		--to=html5 \
		--embed-resources \
		--standalone \
		-o $(HTML_OUT)

all: build html

clean:
	rm -f $(OUTPUT) $(HTML_OUT)

check: check-pandoc
	@command -v xelatex        >/dev/null 2>&1 || { echo "Error: xelatex not found. Install texlive-xetex."; exit 1; }
	@command -v mermaid-filter >/dev/null 2>&1 || { echo "Error: mermaid-filter not found. Run: npm install -g mermaid-filter"; exit 1; }

check-pandoc:
	@command -v pandoc >/dev/null 2>&1 || { echo "Error: pandoc not found. See https://pandoc.org/installing.html"; exit 1; }
	@pandoc --version | head -1 | grep -qF "$(PANDOC_VERSION)" || \
		echo "Warning: expected pandoc $(PANDOC_VERSION), got $$(pandoc --version | head -1)"

watch:
	@if command -v fswatch >/dev/null 2>&1; then \
		echo "Watching for changes (fswatch)..."; \
		fswatch -o $(PROPOSAL_DIR)/markdown/ $(CONFIG) project.tex $(BIB) \
			| xargs -n1 -I{} $(MAKE) build $(if $(PROPOSAL),PROPOSAL=$(PROPOSAL),); \
	elif command -v inotifywait >/dev/null 2>&1; then \
		echo "Watching for changes (inotifywait)..."; \
		while inotifywait -r -e modify,create,delete \
			$(PROPOSAL_DIR)/markdown/ $(CONFIG) project.tex $(BIB) 2>/dev/null; do \
			$(MAKE) build $(if $(PROPOSAL),PROPOSAL=$(PROPOSAL),); \
		done; \
	else \
		echo "Error: install fswatch (macOS: brew install fswatch) or inotify-tools (Linux: apt install inotify-tools)"; \
		exit 1; \
	fi

lint:
	@command -v markdownlint >/dev/null 2>&1 || { echo "Error: markdownlint not found. Run: npm install -g markdownlint-cli"; exit 1; }
	markdownlint $(MARKDOWN)

spellcheck:
	@command -v codespell >/dev/null 2>&1 || { echo "Error: codespell not found. Run: pip install codespell"; exit 1; }
	codespell $(PROPOSAL_DIR)/markdown/

wordcount:
	@echo "Word count ($(PROPOSAL_DIR)/markdown/):"
	@wc -w $(MARKDOWN)

archive:
	@test -n "$(PROPOSAL)" || { echo "Usage: make archive PROPOSAL=my-proposal"; exit 1; }
	@test -f $(OUTPUT) || { echo "Error: Run 'make build PROPOSAL=$(PROPOSAL)' first"; exit 1; }
	@TIMESTAMP=$$(date +%Y%m%d-%H%M%S); \
	ARCHIVE="proposals/$(PROPOSAL)-$${TIMESTAMP}.zip"; \
	zip -r "$${ARCHIVE}" \
		$(PROPOSAL_DIR)/markdown/ \
		$(PROPOSAL_DIR)/config.yaml \
		$(PROPOSAL_DIR)/project.bib \
		$(PROPOSAL_DIR)/project.pdf \
		$(if $(wildcard $(HTML_OUT)),$(HTML_OUT),) \
		project.tex \
		project.css; \
	echo "Created: $${ARCHIVE}"

init:
	@test -n "$(NAME)" || { echo "Usage: make init NAME=my-proposal"; exit 1; }
	@test ! -d proposals/$(NAME) || { echo "Error: proposals/$(NAME) already exists"; exit 1; }
	mkdir -p proposals/$(NAME)/markdown proposals/$(NAME)/images
	cp templates/config.yaml proposals/$(NAME)/config.yaml
	cp templates/project.bib proposals/$(NAME)/project.bib
	cp -r templates/markdown/. proposals/$(NAME)/markdown/
	@echo ""
	@echo "Scaffolded proposals/$(NAME)/"
	@echo "  Edit: proposals/$(NAME)/config.yaml"
	@echo "  Write: proposals/$(NAME)/markdown/"
	@echo "  Build: make build PROPOSAL=$(NAME)"
	@echo "  HTML:  make html  PROPOSAL=$(NAME)"

docker-build:
	docker build -t daedalus .

docker-run: docker-build
	docker run --rm -v "$(CURDIR):/workspace" $(if $(PROPOSAL),--env PROPOSAL=$(PROPOSAL),) daedalus
