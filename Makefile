MARKDOWN := $(sort $(wildcard markdown/*.md))
OUTPUT   := project.pdf

.PHONY: build clean check watch docker-build docker-run

build: check
	pandoc $(MARKDOWN) \
		--metadata-file=config.yaml \
		-F mermaid-filter \
		--pdf-engine=xelatex \
		-o $(OUTPUT) \
		--toc \
		-H project.tex \
		-V subparagraph \
		--css project.css \
		--bibliography project.bib \
		--citeproc \
		--resource-path=.:images

clean:
	rm -f $(OUTPUT)

check:
	@command -v pandoc         >/dev/null 2>&1 || { echo "Error: pandoc not found";         exit 1; }
	@command -v xelatex        >/dev/null 2>&1 || { echo "Error: xelatex not found";        exit 1; }
	@command -v mermaid-filter >/dev/null 2>&1 || { echo "Error: mermaid-filter not found"; exit 1; }

watch:
	@if command -v fswatch >/dev/null 2>&1; then \
		echo "Watching for changes (fswatch)..."; \
		fswatch -o markdown/ config.yaml project.tex project.bib | xargs -n1 -I{} $(MAKE) build; \
	elif command -v inotifywait >/dev/null 2>&1; then \
		echo "Watching for changes (inotifywait)..."; \
		while inotifywait -r -e modify,create,delete markdown/ config.yaml project.tex project.bib 2>/dev/null; do \
			$(MAKE) build; \
		done; \
	else \
		echo "Error: install fswatch (macOS: brew install fswatch) or inotify-tools (Linux: apt install inotify-tools)"; \
		exit 1; \
	fi

docker-build:
	docker build -t daedalus .

docker-run: docker-build
	docker run --rm -v "$(CURDIR):/workspace" daedalus
