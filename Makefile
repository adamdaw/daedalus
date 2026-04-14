PANDOC_VERSION   := 3.1.13
CROSSREF_VERSION := 0.3.17.1

# Mermaid diagram theme. Override with: make build MERMAID_THEME=dark
MERMAID_THEME ?= default
export MERMAID_FILTER_THEME = $(MERMAID_THEME)

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
	-F pandoc-crossref \
	-F mermaid-filter \
	--toc \
	-H project.tex \
	$(if $(DRAFT),-H draft.tex,) \
	-V subparagraph \
	--css project.css \
	--bibliography $(BIB) \
	--citeproc \
	--resource-path=.:$(IMAGES)

.PHONY: build html all clean clean-all check check-pandoc check-proposal watch \
        lint spellcheck wordcount validate archive init list open \
        new-section status build-all help docker-build docker-run

build: check check-proposal ## Build PDF (add DRAFT=1 for watermark, MERMAID_THEME=dark for theme)
	pandoc $(MARKDOWN) $(PANDOC_FLAGS) \
		--pdf-engine=xelatex \
		-o $(OUTPUT)

html: check-pandoc check-proposal ## Build HTML
	pandoc $(MARKDOWN) $(PANDOC_FLAGS) \
		--to=html5 \
		--embed-resources \
		--standalone \
		-o $(HTML_OUT)

all: build html ## Build both PDF and HTML

clean: ## Remove generated output for the current target (root or PROPOSAL=)
	rm -f $(OUTPUT) $(HTML_OUT)

clean-all: ## Remove generated output for the root example and every proposal
	rm -f project.pdf project.html
	@for dir in proposals/*/; do \
		[ -d "$$dir" ] || continue; \
		rm -f "$$dir/project.pdf" "$$dir/project.html"; \
		echo "Cleaned $$(basename $$dir)"; \
	done

check: check-pandoc ## Verify all build dependencies are installed
	@command -v xelatex         >/dev/null 2>&1 || { echo "Error: xelatex not found. Install texlive-xetex."; exit 1; }
	@command -v mermaid-filter  >/dev/null 2>&1 || { echo "Error: mermaid-filter not found. Run: npm install -g mermaid-filter"; exit 1; }
	@command -v pandoc-crossref >/dev/null 2>&1 || { echo "Error: pandoc-crossref not found. See: https://github.com/lierdakil/pandoc-crossref/releases"; exit 1; }

check-pandoc:
	@command -v pandoc >/dev/null 2>&1 || { echo "Error: pandoc not found. See https://pandoc.org/installing.html"; exit 1; }
	@pandoc --version | head -1 | grep -qF "$(PANDOC_VERSION)" || \
		echo "Warning: expected pandoc $(PANDOC_VERSION), got $$(pandoc --version | head -1)"

check-proposal:
ifdef PROPOSAL
	@test -d $(PROPOSAL_DIR) || { \
		echo "Error: proposal '$(PROPOSAL)' not found."; \
		echo "  Run 'make list' to see available proposals."; \
		echo "  Run 'make init NAME=$(PROPOSAL)' to create it."; \
		exit 1; \
	}
endif

list: ## List all proposals with their titles
	@if ls proposals/*/config.yaml >/dev/null 2>&1; then \
		echo "Proposals:"; \
		for cfg in proposals/*/config.yaml; do \
			name=$$(basename "$$(dirname "$$cfg")"); \
			title=$$(grep '^title:' "$$cfg" 2>/dev/null \
				| head -1 | sed 's/title:[[:space:]]*//' | tr -d '"'"'"'); \
			echo "  $$name — $$title"; \
		done; \
	else \
		echo "No proposals found. Run: make init NAME=my-proposal"; \
	fi

status: ## Show build state and word count for all proposals
	@echo "Root example:"
	@if [ -f project.pdf ]; then \
		words=$$(wc -w markdown/*.md 2>/dev/null | tail -1 | awk '{print $$1}'); \
		echo "  [built]     project.pdf  ($$words words)"; \
	else \
		echo "  [not built]"; \
	fi
	@echo ""
	@if ls proposals/*/config.yaml >/dev/null 2>&1; then \
		echo "Proposals:"; \
		for cfg in proposals/*/config.yaml; do \
			name=$$(basename "$$(dirname "$$cfg")"); \
			title=$$(grep '^title:' "$$cfg" | head -1 \
				| sed 's/title:[[:space:]]*//' | tr -d '"'"'"'); \
			pdf="proposals/$$name/project.pdf"; \
			words=$$(wc -w "proposals/$$name/markdown/"*.md 2>/dev/null \
				| tail -1 | awk '{print $$1}'); \
			if [ -f "$$pdf" ]; then \
				echo "  [built]     $$name — $$title  ($$words words)"; \
			else \
				echo "  [not built] $$name — $$title  ($$words words)"; \
			fi; \
		done; \
	else \
		echo "No proposals. Run: make init NAME=my-proposal"; \
	fi

open: ## Open the built PDF in the system viewer
	@test -f $(OUTPUT) || { echo "Error: $(OUTPUT) not found. Run 'make build$(if $(PROPOSAL), PROPOSAL=$(PROPOSAL),)' first."; exit 1; }
	@if command -v xdg-open >/dev/null 2>&1; then \
		xdg-open $(OUTPUT); \
	elif command -v open >/dev/null 2>&1; then \
		open $(OUTPUT); \
	else \
		echo "Cannot open PDF: install xdg-utils (Linux) or use macOS."; exit 1; \
	fi

new-section: ## Scaffold next numbered section file (requires TITLE="Section Name")
	@test -n "$(TITLE)" || { echo "Usage: make new-section TITLE='Section Name' [PROPOSAL=my-proposal]"; exit 1; }
	@LAST=$$(ls $(PROPOSAL_DIR)/markdown/*.md 2>/dev/null \
		| sed 's|.*/\([0-9][0-9]*\)_.*|\1|' \
		| grep -v '^99$$' | sort -n | tail -1); \
	NEXT=$$(printf "%02d" $$(( $${LAST:-0} + 1 ))); \
	SLUG=$$(echo "$(TITLE)" | tr ' ' '_' | tr -cd 'A-Za-z0-9_-'); \
	FILE="$(PROPOSAL_DIR)/markdown/$${NEXT}_$${SLUG}.md"; \
	printf "# $(TITLE)\n" > "$$FILE"; \
	echo "Created: $$FILE"

watch: ## Rebuild on file changes (requires fswatch or inotify-tools)
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

lint: ## Run markdownlint on content files
	@command -v markdownlint >/dev/null 2>&1 || { echo "Error: markdownlint not found. Run: npm install -g markdownlint-cli"; exit 1; }
	markdownlint $(MARKDOWN)

spellcheck: ## Run codespell on content files
	@command -v codespell >/dev/null 2>&1 || { echo "Error: codespell not found. Run: pip install codespell"; exit 1; }
	codespell $(PROPOSAL_DIR)/markdown/

validate: lint spellcheck ## Run lint + spellcheck without building

wordcount: ## Print word count per file and total
	@echo "Word count ($(PROPOSAL_DIR)/markdown/):"
	@wc -w $(MARKDOWN)

build-all: ## Build PDF for every proposal
	@if ls proposals/*/config.yaml >/dev/null 2>&1; then \
		for cfg in proposals/*/config.yaml; do \
			name=$$(basename "$$(dirname "$$cfg")"); \
			echo "==> Building $$name..."; \
			$(MAKE) build PROPOSAL=$$name || exit 1; \
		done; \
	else \
		echo "No proposals found. Run: make init NAME=my-proposal"; \
	fi

archive: ## Package source + output into a timestamped zip (requires PROPOSAL=)
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

init: ## Scaffold a new proposal (requires NAME=; optional TITLE= AUTHOR=)
	@test -n "$(NAME)" || { echo "Usage: make init NAME=my-proposal [TITLE='My Title'] [AUTHOR='Name']"; exit 1; }
	@test ! -d proposals/$(NAME) || { echo "Error: proposals/$(NAME) already exists"; exit 1; }
	mkdir -p proposals/$(NAME)/markdown proposals/$(NAME)/images
	cp templates/config.yaml proposals/$(NAME)/config.yaml
	@if [ -n "$(TITLE)" ]; then \
		sed -i 's|^title: "Proposal Title"|title: "$(TITLE)"|' proposals/$(NAME)/config.yaml; \
	fi
	@if [ -n "$(AUTHOR)" ]; then \
		sed -i 's|^author: "Author Name"|author: "$(AUTHOR)"|' proposals/$(NAME)/config.yaml; \
	fi
	cp templates/project.bib proposals/$(NAME)/project.bib
	cp -r templates/markdown/. proposals/$(NAME)/markdown/
	@echo ""
	@echo "Scaffolded proposals/$(NAME)/"
	@echo "  Edit:  proposals/$(NAME)/config.yaml"
	@echo "  Write: proposals/$(NAME)/markdown/"
	@echo "  Build: make build PROPOSAL=$(NAME)"
	@echo "  HTML:  make html  PROPOSAL=$(NAME)"
	@echo "  Add sections: make new-section TITLE='...' PROPOSAL=$(NAME)"

help: ## Show available targets
	@echo "Usage: make [target] [PROPOSAL=name] [options]"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) \
		| awk 'BEGIN {FS = ":.*?## "}; {printf "  %-18s %s\n", $$1, $$2}'
	@echo ""
	@echo "Options:"
	@echo "  PROPOSAL=name    Target a specific proposal in proposals/name/"
	@echo "  DRAFT=1          Add DRAFT watermark to PDF"
	@echo "  MERMAID_THEME=x  Mermaid theme: default, dark, forest, neutral"

docker-build: ## Build the Docker image
	docker build -t daedalus .

docker-run: docker-build ## Run the build inside Docker
	docker run --rm -v "$(CURDIR):/workspace" $(if $(PROPOSAL),--env PROPOSAL=$(PROPOSAL),) daedalus
