pandoc markdown/*.md -o project.md
pandoc project.md -F mermaid-filter --pdf-engine=xelatex -o project.pdf --toc -H project.tex -V subparagraph --css project.css --bibliography project.bib --citeproc 