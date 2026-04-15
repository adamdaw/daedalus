# Recipes use bash features (arrays, [[ ]]); declare explicitly per GNU Make conventions.
# Reference: https://www.gnu.org/software/make/manual/html_node/Choosing-the-Shell.html
SHELL := /bin/bash

# Default target: show help rather than running a build on bare 'make'.
# GNU Make .DEFAULT_GOAL — https://www.gnu.org/software/make/manual/make.html#index-.DEFAULT_005fGOAL
.DEFAULT_GOAL := help

PANDOC_VERSION   := 3.1.13
CROSSREF_VERSION := 0.3.17.1

# Portable in-place sed: BSD sed (macOS) requires an extension argument; GNU sed does not.
UNAME_S := $(shell uname -s)
ifeq ($(UNAME_S),Darwin)
  SED_I := sed -i ''
else
  SED_I := sed -i
endif

# Mermaid diagram theme. Override with: make build MERMAID_THEME=dark
# MERMAID_THEME is read by the mmdc-pandoc wrapper script, which passes --theme to mmdc.
# filters/diagram.lua (pandoc-ext/diagram) invokes the binary at $MERMAID_BIN.
MERMAID_THEME ?= default
export MERMAID_THEME

# Set PROPOSAL=name to build proposals/name/; omit to build the root example.
ifdef PROPOSAL
  PROPOSAL_DIR := proposals/$(PROPOSAL)
else
  PROPOSAL_DIR := .
endif

MARKDOWN := $(sort $(wildcard $(PROPOSAL_DIR)/markdown/*.md))
OUTPUT   := $(PROPOSAL_DIR)/project.pdf
HTML_OUT := $(PROPOSAL_DIR)/project.html
DOCX_OUT := $(PROPOSAL_DIR)/project.docx
CONFIG   := $(PROPOSAL_DIR)/config.yaml
BIB      := $(PROPOSAL_DIR)/project.bib
IMAGES   := $(PROPOSAL_DIR)/images

PANDOC_FLAGS = \
	--metadata-file=$(CONFIG) \
	-F pandoc-crossref \
	--lua-filter filters/diagram.lua \
	--toc \
	-H project.tex \
	$(if $(DRAFT),-H draft.tex,) \
	-V subparagraph \
	--css project.css \
	--bibliography $(BIB) \
	--citeproc \
	--resource-path=$(CURDIR):$(CURDIR)/$(IMAGES)

# Flags for DOCX — excludes LaTeX-specific options (-H, -V subparagraph, --css)
DOCX_FLAGS = \
	--metadata-file=$(CONFIG) \
	-F pandoc-crossref \
	--lua-filter filters/diagram.lua \
	--toc \
	--bibliography $(BIB) \
	--citeproc \
	--resource-path=$(CURDIR):$(CURDIR)/$(IMAGES)

.PHONY: build html docx all clean clean-all check check-pandoc check-filters check-proposal \
        watch lint spellcheck shellcheck wordcount validate validate-all archive init list open open-html \
        new-section status build-all delete help version docker-build docker-run docker-pull-run \
        gather-requirements gather-brief assemble validate-artifacts test-elicitation test-scripts \
        progress ready coverage

build: check check-proposal ## Build PDF (add DRAFT=1 for watermark, MERMAID_THEME=dark for theme)
	pandoc $(MARKDOWN) $(PANDOC_FLAGS) \
		--pdf-engine=xelatex \
		-o $(OUTPUT)

html: check-pandoc check-filters check-proposal ## Build HTML
	pandoc $(MARKDOWN) $(PANDOC_FLAGS) \
		--to=html5 \
		--embed-resources \
		--standalone \
		-o $(HTML_OUT)

docx: check-pandoc check-filters check-proposal ## Build Word document (DOCX)
	pandoc $(MARKDOWN) $(DOCX_FLAGS) \
		--to=docx \
		-o $(DOCX_OUT)

all: build html docx ## Build PDF, HTML, and DOCX

clean: ## Remove generated output for the current target (root or PROPOSAL=)
	rm -f $(OUTPUT) $(HTML_OUT) $(DOCX_OUT)

clean-all: ## Remove generated output for the root example and every proposal
	rm -f project.pdf project.html project.docx
	@for dir in proposals/*/; do \
		[ -d "$$dir" ] || continue; \
		rm -f "$$dir/project.pdf" "$$dir/project.html" "$$dir/project.docx"; \
		echo "Cleaned $$(basename $$dir)"; \
	done

check-filters:
	@command -v mmdc           >/dev/null 2>&1 || { echo "Error: mmdc not found. Run: npm install -g @mermaid-js/mermaid-cli@11.12.0"; exit 1; }
	@test -f filters/diagram.lua                || { echo "Error: filters/diagram.lua not found. Expected at: filters/diagram.lua"; exit 1; }
	@command -v pandoc-crossref >/dev/null 2>&1 || { echo "Error: pandoc-crossref not found. See: https://github.com/lierdakil/pandoc-crossref/releases"; exit 1; }

check: check-pandoc check-filters ## Verify all build dependencies are installed
	@command -v xelatex >/dev/null 2>&1 || { echo "Error: xelatex not found. Install texlive-xetex."; exit 1; }

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
				| head -1 | sed 's/title:[[:space:]]*//' | tr -d '\042\047'); \
			echo "  $$name — $$title"; \
		done; \
	else \
		echo "No proposals found. Run: make init NAME=my-proposal"; \
	fi

status: ## Show build state and word count for all proposals
	@echo "Root example:"
	@words=$$(wc -w markdown/*.md 2>/dev/null | tail -1 | awk '{print $$1}'); \
	if [ -f project.pdf ] && [ -f project.html ] && [ -f project.docx ]; then \
		echo "  [pdf+html+docx]  project.pdf + project.html + project.docx  ($$words words)"; \
	elif [ -f project.pdf ] && [ -f project.html ]; then \
		echo "  [pdf+html]  project.pdf + project.html  ($$words words)"; \
	elif [ -f project.pdf ]; then \
		echo "  [pdf only]  project.pdf  ($$words words)"; \
	else \
		echo "  [not built]  ($$words words)"; \
	fi
	@echo ""
	@if ls proposals/*/config.yaml >/dev/null 2>&1; then \
		echo "Proposals:"; \
		for cfg in proposals/*/config.yaml; do \
			name=$$(basename "$$(dirname "$$cfg")"); \
			title=$$(grep '^title:' "$$cfg" | head -1 \
				| sed 's/title:[[:space:]]*//' | tr -d '\042\047'); \
			pdf="proposals/$$name/project.pdf"; \
			htm="proposals/$$name/project.html"; \
			docx="proposals/$$name/project.docx"; \
			words=$$(wc -w "proposals/$$name/markdown/"*.md 2>/dev/null \
				| tail -1 | awk '{print $$1}'); \
			if [ -f "$$pdf" ] && [ -f "$$htm" ] && [ -f "$$docx" ]; then \
				echo "  [pdf+html+docx]  $$name — $$title  ($$words words)"; \
			elif [ -f "$$pdf" ] && [ -f "$$htm" ]; then \
				echo "  [pdf+html]  $$name — $$title  ($$words words)"; \
			elif [ -f "$$pdf" ]; then \
				echo "  [pdf only]  $$name — $$title  ($$words words)"; \
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

open-html: ## Open the built HTML in the system browser
	@test -f $(HTML_OUT) || { echo "Error: $(HTML_OUT) not found. Run 'make html$(if $(PROPOSAL), PROPOSAL=$(PROPOSAL),)' first."; exit 1; }
	@if command -v xdg-open >/dev/null 2>&1; then \
		xdg-open $(HTML_OUT); \
	elif command -v open >/dev/null 2>&1; then \
		open $(HTML_OUT); \
	else \
		echo "Cannot open HTML: install xdg-utils (Linux) or use macOS."; exit 1; \
	fi

new-section: check-proposal ## Scaffold next numbered section file (requires TITLE="Section Name")
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
		fswatch -o $(PROPOSAL_DIR)/markdown/ $(CONFIG) project.tex project.css $(BIB) \
			| xargs -n1 -I{} $(MAKE) all $(if $(PROPOSAL),PROPOSAL=$(PROPOSAL),); \
	elif command -v inotifywait >/dev/null 2>&1; then \
		echo "Watching for changes (inotifywait)..."; \
		while inotifywait -r -e modify,create,delete \
			$(PROPOSAL_DIR)/markdown/ $(CONFIG) project.tex project.css $(BIB) 2>/dev/null; do \
			$(MAKE) all $(if $(PROPOSAL),PROPOSAL=$(PROPOSAL),); \
		done; \
	else \
		echo "Error: install fswatch (macOS: brew install fswatch) or inotify-tools (Linux: apt install inotify-tools)"; \
		exit 1; \
	fi

lint: ## Run markdownlint on content files
	@command -v markdownlint >/dev/null 2>&1 || { echo "Error: markdownlint not found. Run: npm install -g markdownlint-cli@0.48.0"; exit 1; }
	markdownlint $(MARKDOWN)

spellcheck: ## Run codespell on content files
	@command -v codespell >/dev/null 2>&1 || { echo "Error: codespell not found. Run: pip install --constraint requirements-dev.txt codespell"; exit 1; }
	codespell $(PROPOSAL_DIR)/markdown/

shellcheck: ## Lint shell scripts with ShellCheck (https://www.shellcheck.net)
	@command -v shellcheck >/dev/null 2>&1 || { echo "Error: shellcheck not found. Run: apt-get install shellcheck"; exit 1; }
	shellcheck scripts/*.sh

validate: lint spellcheck shellcheck ## Run lint + spellcheck + shellcheck without building

wordcount: ## Print word count per file and total
	@echo "Word count ($(PROPOSAL_DIR)/markdown/):"
	@wc -w $(MARKDOWN)

build-all: ## Build PDF, HTML, and DOCX for every proposal
	@if ls proposals/*/config.yaml >/dev/null 2>&1; then \
		for cfg in proposals/*/config.yaml; do \
			name=$$(basename "$$(dirname "$$cfg")"); \
			echo "==> Building $$name..."; \
			$(MAKE) all PROPOSAL=$$name || exit 1; \
		done; \
	else \
		echo "No proposals found. Run: make init NAME=my-proposal"; \
	fi

validate-all: ## Run lint + spellcheck for root example and every proposal
	@echo "==> Validating root example..."
	$(MAKE) validate
	@if ls proposals/*/config.yaml >/dev/null 2>&1; then \
		for cfg in proposals/*/config.yaml; do \
			name=$$(basename "$$(dirname "$$cfg")"); \
			echo "==> Validating $$name..."; \
			$(MAKE) validate PROPOSAL=$$name || exit 1; \
		done; \
	else \
		echo "No proposals found."; \
	fi

archive: ## Package source + output into a timestamped zip (requires PROPOSAL=)
	@test -n "$(PROPOSAL)" || { echo "Usage: make archive PROPOSAL=my-proposal"; exit 1; }
	@command -v zip >/dev/null 2>&1 || { echo "Error: zip not found. Run: apt install zip / brew install zip"; exit 1; }
	@test -f $(OUTPUT) || { echo "Error: Run 'make build PROPOSAL=$(PROPOSAL)' first"; exit 1; }
	@TIMESTAMP=$$(date +%Y%m%d-%H%M%S); \
	ARCHIVE="proposals/$(PROPOSAL)-$${TIMESTAMP}.zip"; \
	zip -r "$${ARCHIVE}" \
		$(PROPOSAL_DIR)/markdown/ \
		$(PROPOSAL_DIR)/config.yaml \
		$(PROPOSAL_DIR)/project.bib \
		$(PROPOSAL_DIR)/project.pdf \
		$(if $(wildcard $(HTML_OUT)),$(HTML_OUT),) \
		$(if $(wildcard $(DOCX_OUT)),$(DOCX_OUT),) \
		project.tex \
		project.css; \
	echo "Created: $${ARCHIVE}"

init: ## Scaffold a new proposal (requires NAME=; optional TITLE= AUTHOR= DATE=)
	@test -n "$(NAME)" || { echo "Usage: make init NAME=my-proposal [TITLE='My Title'] [AUTHOR='Name'] [DATE='Month Year']"; exit 1; }
	@echo "$(NAME)" | grep -qE '^[a-zA-Z0-9_-]+$$' || { \
		echo "Error: NAME '$(NAME)' is invalid. Use only letters, numbers, hyphens, and underscores."; \
		exit 1; \
	}
	@test ! -d proposals/$(NAME) || { echo "Error: proposals/$(NAME) already exists"; exit 1; }
	mkdir -p proposals/$(NAME)/markdown proposals/$(NAME)/images
	cp templates/config.yaml proposals/$(NAME)/config.yaml
	@if [ -n "$(TITLE)" ]; then \
		$(SED_I) 's|^title: "Proposal Title"|title: "$(TITLE)"|' proposals/$(NAME)/config.yaml; \
	fi
	@if [ -n "$(AUTHOR)" ]; then \
		$(SED_I) 's|^author: "Author Name"|author: "$(AUTHOR)"|' proposals/$(NAME)/config.yaml; \
	fi
	@if [ -n "$(DATE)" ]; then \
		$(SED_I) 's|^date: "Month Year"|date: "$(DATE)"|' proposals/$(NAME)/config.yaml; \
	else \
		CURRENT_DATE=$$(date +"%B %Y"); \
		$(SED_I) "s|^date: \"Month Year\"|date: \"$$CURRENT_DATE\"|" proposals/$(NAME)/config.yaml; \
	fi
	cp templates/project.bib proposals/$(NAME)/project.bib
	cp -r templates/markdown/. proposals/$(NAME)/markdown/
	cp templates/brief.md proposals/$(NAME)/brief.md
	cp templates/requirements.md proposals/$(NAME)/requirements.md
	@echo ""
	@echo "Scaffolded proposals/$(NAME)/"
	@echo "  Edit:  proposals/$(NAME)/config.yaml"
	@echo "  Write: proposals/$(NAME)/markdown/"
	@echo "  Build: make build PROPOSAL=$(NAME)"
	@echo "  HTML:  make html  PROPOSAL=$(NAME)"
	@echo "  Add sections: make new-section TITLE='...' PROPOSAL=$(NAME)"
	@echo "  Requirements: /req-01 through /req-05 (run from proposals/$(NAME)/)"
	@echo "  Architecture: /gather-01 through /gather-11 (run from proposals/$(NAME)/)"

gather-requirements: ## Elicit requirements interactively → requirements.md (non-AI fallback for /req-* and Prompt 06)
	@if [ -n "$(PROPOSAL)" ]; then \
		bash scripts/gather-requirements.sh proposals/$(PROPOSAL)/requirements.md; \
	else \
		bash scripts/gather-requirements.sh; \
	fi

gather-brief: ## Elicit architecture brief interactively → brief.md (non-AI fallback for /gather-*)
	@if [ -n "$(PROPOSAL)" ]; then \
		cd proposals/$(PROPOSAL) && bash ../../scripts/gather-brief.sh brief.md; \
	else \
		bash scripts/gather-brief.sh; \
	fi

assemble: ## Assemble arc42 markdown from elicitation artifacts (non-AI fallback for Prompt 01)
	bash scripts/assemble.sh $(if $(PROPOSAL),--proposal $(PROPOSAL))

validate-artifacts: ## Validate structure of requirements.md and brief.md
	@if [ -n "$(PROPOSAL)" ]; then \
		bash scripts/validate-artifacts.sh \
			--requirements proposals/$(PROPOSAL)/requirements.md \
			--brief proposals/$(PROPOSAL)/brief.md; \
	else \
		bash scripts/validate-artifacts.sh; \
	fi

progress: ## Show elicitation progress dashboard for requirements.md and brief.md
	@if [ -n "$(PROPOSAL)" ]; then \
		bash scripts/progress.sh \
			--requirements proposals/$(PROPOSAL)/requirements.md \
			--brief proposals/$(PROPOSAL)/brief.md; \
	else \
		bash scripts/progress.sh; \
	fi

ready: ## Validate artifacts are complete and consistent (pre-authoring gate)
	@if [ -n "$(PROPOSAL)" ]; then \
		bash scripts/validate-artifacts.sh --ready \
			--requirements proposals/$(PROPOSAL)/requirements.md \
			--brief proposals/$(PROPOSAL)/brief.md; \
	else \
		bash scripts/validate-artifacts.sh --ready; \
	fi

test-scripts: ## Run bats unit tests for shell scripts (https://github.com/bats-core/bats-core)
	@command -v bats >/dev/null 2>&1 || { echo "Error: bats not found. Run: apt-get install bats"; exit 1; }
	bats test/scripts/*.bats

test-elicitation: ## Run full elicitation pipeline test using fixtures (no AI required)
	@echo "=== Elicitation pipeline test ==="
	@mkdir -p proposals/ci-elicitation-test/markdown
	grep -v '^#' test/fixtures/requirements-answers.txt | \
		bash scripts/gather-requirements.sh proposals/ci-elicitation-test/requirements.md
	cd proposals/ci-elicitation-test && \
		grep -v '^#' ../../test/fixtures/brief-answers.txt | \
		bash ../../scripts/gather-brief.sh brief.md
	bash scripts/validate-artifacts.sh \
		--requirements proposals/ci-elicitation-test/requirements.md \
		--brief proposals/ci-elicitation-test/brief.md
	bash scripts/progress.sh \
		--requirements proposals/ci-elicitation-test/requirements.md \
		--brief proposals/ci-elicitation-test/brief.md
	bash scripts/validate-artifacts.sh --ready \
		--requirements proposals/ci-elicitation-test/requirements.md \
		--brief proposals/ci-elicitation-test/brief.md
	bash scripts/assemble.sh --proposal ci-elicitation-test
	@ls proposals/ci-elicitation-test/markdown/*.md | wc -l | \
		xargs -I{} sh -c 'test {} -ge 12 || { echo "FAIL: expected 12 files, got {}"; exit 1; }'
	@rm -rf proposals/ci-elicitation-test
	@echo "=== Test passed ==="

coverage: ## Run test coverage analysis (requires Ruby + bashcov)
	@command -v bashcov >/dev/null 2>&1 || { echo "Error: bashcov not found. Run: gem install bashcov simplecov-cobertura"; exit 1; }
	@command -v bats >/dev/null 2>&1 || { echo "Error: bats not found. Run: apt-get install bats"; exit 1; }
	bash scripts/coverage.sh

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

delete: ## Delete a proposal and all its contents (requires PROPOSAL=; add CONFIRM=yes to skip prompt)
	@test -n "$(PROPOSAL)" || { echo "Usage: make delete PROPOSAL=my-proposal [CONFIRM=yes]"; exit 1; }
	@test -d $(PROPOSAL_DIR) || { echo "Error: proposal '$(PROPOSAL)' not found."; exit 1; }
	@if [ "$(CONFIRM)" != "yes" ]; then \
		echo "This will permanently delete proposals/$(PROPOSAL)/."; \
		echo "Run with CONFIRM=yes to proceed: make delete PROPOSAL=$(PROPOSAL) CONFIRM=yes"; \
		exit 1; \
	fi
	rm -rf proposals/$(PROPOSAL)/
	@echo "Deleted proposals/$(PROPOSAL)/"

version: ## Print installed versions of all build tools
	@echo "pandoc:          $$(pandoc --version 2>/dev/null | head -1 || echo 'NOT FOUND')"
	@echo "pandoc-crossref: $$(pandoc-crossref --version 2>/dev/null | head -1 || echo 'NOT FOUND')"
	@echo "xelatex:         $$(xelatex --version 2>/dev/null | head -1 || echo 'NOT FOUND')"
	@echo "mmdc (mermaid):  $$(mmdc --version 2>/dev/null | head -1 || echo 'NOT FOUND')"
	@echo "markdownlint:    $$(markdownlint --version 2>/dev/null || echo 'NOT FOUND')"
	@echo "codespell:       $$(codespell --version 2>/dev/null || echo 'NOT FOUND')"
	@echo "node:            $$(node --version 2>/dev/null || echo 'NOT FOUND')"
	@echo "python:          $$(python3 --version 2>/dev/null || echo 'NOT FOUND')"

docker-build: ## Build the Docker image locally
	docker build \
		--build-arg BUILD_DATE=$(shell date -u +%Y-%m-%dT%H:%M:%SZ) \
		--build-arg VCS_REF=$(shell git rev-parse HEAD 2>/dev/null || echo unknown) \
		-t daedalus .

docker-run: docker-build ## Run the build inside the locally-built Docker image (optional: TARGET=all TARGET=validate)
	docker run --rm -v "$(CURDIR):/workspace" \
		$(if $(PROPOSAL),--env PROPOSAL=$(PROPOSAL),) \
		daedalus \
		$(if $(TARGET),make $(TARGET))

docker-pull-run: ## Pull the pre-built image from GHCR and run the build (no local Docker build required)
	docker pull ghcr.io/adamdaw/daedalus:latest
	docker run --rm -v "$(CURDIR):/workspace" \
		$(if $(PROPOSAL),--env PROPOSAL=$(PROPOSAL),) \
		ghcr.io/adamdaw/daedalus:latest \
		$(if $(TARGET),make $(TARGET))
