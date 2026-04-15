# .simplecov — Coverage configuration for bashcov
#
# bashcov uses SimpleCov under the hood. This file configures output format
# and filtering. Bashcov traces bash scripts via PS4/BASH_XTRACEFD and feeds
# line execution data to SimpleCov for reporting.
#
# References:
#   bashcov — https://github.com/infertux/bashcov
#   simplecov — https://github.com/simplecov-ruby/simplecov
#   simplecov-cobertura — https://github.com/dashingrocket/simplecov-cobertura

require "simplecov-cobertura"

SimpleCov.start do
  # Output both HTML (for local viewing) and Cobertura XML (for CI)
  formatter SimpleCov::Formatter::MultiFormatter.new([
    SimpleCov::Formatter::HTMLFormatter,
    SimpleCov::Formatter::CoberturaFormatter
  ])

  # Only measure coverage for scripts in the scripts/ directory
  add_filter %r{^(?!.*/scripts/)}

  # Group scripts by purpose
  add_group "Elicitation", %w[gather-requirements gather-brief]
  add_group "Pipeline", %w[assemble validate-artifacts progress]
  add_group "Coverage", %w[coverage]

  # Coverage target: 90% minimum
  minimum_coverage 90

  # Merge results across multiple bashcov runs (bats tests + direct invocations)
  use_merging true
end
