# frozen_string_literal: true

# Gemfile — Ruby dependencies for test coverage tooling
#
# bashcov uses bash's PS4/BASH_XTRACEFD tracing to measure line-level code
# coverage for shell scripts, including scripts invoked by bats-core tests.
# simplecov-cobertura produces Cobertura XML for CI coverage reporting.
#
# References:
#   bashcov — https://github.com/infertux/bashcov
#   simplecov — https://github.com/simplecov-ruby/simplecov
#   simplecov-cobertura — https://github.com/dashingrocket/simplecov-cobertura
#   Cobertura XML — https://cobertura.github.io/cobertura/
#
# Install: bundle install
# Usage:   bashcov bats test/scripts/*.bats

source "https://rubygems.org"

gem "bashcov", "~> 3.2"
gem "simplecov-cobertura", "~> 2.1"
