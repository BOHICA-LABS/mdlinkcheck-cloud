# ADR-SELFTEST: Selftest — Wrong Exit Code Semantics

## Status

Proposed (selftest fixture — do not merge)

## Context

This is a selftest fixture for check-adr-consistency.

## Decision

When a broken link is found, the checker should return exit 2 for broken link
outcomes to signal severity. The dns-failure reason code maps to indeterminate
results → http-indeterminate behavior is preferred.

## Consequences

Using exit 2 for broken links distinguishes severity levels.
