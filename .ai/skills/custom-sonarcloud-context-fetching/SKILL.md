---
name: custom-sonarcloud-context-fetching
description: Fetch SonarCloud / SonarQube context from a sonarcloud.io URL (or a project / issue / hotspot / rule key) using the installed `sonar` CLI. Use when the user shares a SonarCloud link or asks for project quality-gate status, issues, security hotspots, measures, or rule details. Read-only and on-demand — no MCP server required.
---

# Custom SonarCloud Context Fetching

Fetch info from SonarCloud using the `sonar` CLI directly. This replaces the old
`mcp/sonarqube` MCP server (which spawned a ~500 MB+ Docker container per session).
The CLI runs on demand and exits, so it costs zero idle memory.

## Scope

Run this only when SonarCloud context is actually needed — typically when the user
shares a `sonarcloud.io` URL or asks about a project's issues, quality gate, hotspots,
measures, or a rule. Do not run it if the user already pasted the relevant details.

This skill is **read-only**. Do not run `sonar analyze`, `sonar remediate`, or any
`sonar api post|put|patch|delete` unless the user explicitly asks.

## Setup

1. Verify the CLI is authenticated:
   ```bash
   sonar auth status
   ```
   It should report `[✓ Connected]`, the server (e.g. `https://sonarcloud.io`) and the
   organization (the `Org` line — note it; some API endpoints need it).
2. If it is not connected, stop and ask the user to run `sonar auth login`. Do not guess.

## Parse the URL

SonarCloud links are `https://sonarcloud.io/<page>?<params>`. Extract the relevant
query params (they are URL-encoded — decode `%2F` etc.):

| Page | Meaning | Params to extract |
|------|---------|-------------------|
| `/project/overview`, `/summary/overall`, `/summary/new_code` | Project dashboard | `id` = **projectKey**, optional `branch` |
| `/project/issues` | Issues list / single issue | `id`, `open` or `issues` = **issueKey**, optional `branch`, `pullRequest`, filters (`types`, `severities`, `resolved`, `rules`) |
| `/project/security_hotspots` | Security hotspots | `id`, `hotspots` = **hotspotKey** |
| `/code`, `/component_measures` | File / measures view | `id`, `selected` or `metric` |
| `/organizations/<ORG>/rules`, `.../coding_rules` | Rule details | `ORG` from path, `open`/`rule_key` = **ruleKey** |
| `/organizations/<ORG>/projects` | Org project list | `ORG` from path |

Notes:
- `projectKey` (the `id` param) is usually `<Org>_<Repo>` — e.g. `Accredifysg_Nexus`.
- Derive `<ORG>` from the URL path, the projectKey prefix, or the `Org` line of `sonar auth status`.
- If the URL has no `id`/`open` and you cannot determine the key, ask the user rather than guessing.

## Workflow

1. Parse the URL → determine page type and keys (above).
2. Run the matching command (next section). Prefer `--format json` / `sonar api get`
   when you need to parse; use `--format table` when just showing the user a list.
3. Report back: state the parsed projectKey / issueKey so the user can confirm the match,
   then summarize (severity, rule, file:line, message, status, quality-gate result).
4. For a flagged issue, fetch the rule explanation (`/api/rules/show`) when the user needs
   the "why" or how to fix.

## Commands

Issues (high-level CLI — supports filters):
```bash
# All open issues for a project (json for parsing, table for display)
sonar list issues -p <projectKey> --format json
sonar list issues -p <projectKey> --statuses OPEN --severities CRITICAL,BLOCKER --format table
sonar list issues -p <projectKey> --branch <branch>
sonar list issues -p <projectKey> --pull-request <prNumber>
```

Single issue / arbitrary data (universal authenticated API — the escape hatch):
```bash
# A specific issue from ?open=<key> or ?issues=<key>
sonar api get "/api/issues/search?issues=<issueKey>&componentKeys=<projectKey>&additionalFields=_all"

# Quality gate status (project overview pages)
sonar api get "/api/qualitygates/project_status?projectKey=<projectKey>"          # add &branch= or &pullRequest=

# Measures (component_measures pages)
sonar api get "/api/measures/component?component=<projectKey>&metricKeys=bugs,vulnerabilities,code_smells,security_hotspots,coverage,duplicated_lines_density,ncloc"

# Security hotspots
sonar api get "/api/hotspots/search?projectKey=<projectKey>"
sonar api get "/api/hotspots/show?hotspot=<hotspotKey>"

# Rule details / explanation
sonar api get "/api/rules/show?key=<ruleKey>&organization=<org>"

# Component / file
sonar api get "/api/components/show?component=<componentKey>"
```

Projects:
```bash
sonar list projects -q <query>      # find a project key by name/key
sonar list projects --page-size 50
```

## Behavior

1. Always confirm the parsed keys back to the user (URL → projectKey / issueKey) so a mismatch is caught.
2. Prefer `sonar list issues` for issue queries; fall back to `sonar api get "/api/issues/search?..."` for a single issue key, since `list issues` filters by project/severity/status, not by issue key.
3. Mirror URL filters in the command — if the URL has `branch=` or `pullRequest=`, pass `--branch` / `--pull-request` (or `&branch=` / `&pullRequest=` for `sonar api`).
4. When summarizing an issue, include: rule, severity/impact, `component:line`, message, status, and (if asked) the rule explanation from `/api/rules/show`.
5. Stay read-only. If the user wants to scan code or remediate, point them to `sonar analyze` / `sonar remediate` and let them decide.
