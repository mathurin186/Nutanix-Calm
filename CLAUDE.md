# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

Infrastructure-as-code for **Nutanix Calm** — an application lifecycle management platform. Blueprints define multi-VM applications (services, packages, actions) and Runbooks define one-off automation tasks. All automation is executed by the Calm engine, not run locally.

## Importing / Exporting

Blueprints and Runbooks are JSON files imported and exported through the Nutanix Calm UI or API. There are no local build, lint, or test commands — validation happens inside Calm when you import a blueprint.

To import via CLI (requires `calm` CLI configured against a Prism Central endpoint):
```bash
calm create bp --file Blueprints/<name>.json
calm create runbook --file "Runbooks/<name>.json"
```

## Calm-specific conventions

**Macro syntax** — variable interpolation inside scripts uses `@@{variable}@@` or `@@{service.attribute}@@`. This is resolved by the Calm engine at runtime, not locally.

**Credential references** — secrets are always `@@{CredentialName.secret}@@` and usernames `@@{CredentialName.username}@@`. Credentials are defined in the blueprint's `credential_definition_list` and injected at runtime.

**Script types in blueprints:**
- `"script_type": "sh"` — Bash, runs on the target VM via SSH
- `"script_type": "static"` — Python 2 (Calm built-in), runs on the Calm engine; uses Calm's `urlreq()` and built-in `json` — no imports needed, and `print` uses Python 2 syntax

**Service addressing** — `@@{ServiceName.address}@@` resolves to the first NIC IP of the deployed VM.

## Key blueprint patterns

- **EraServerDeployment** — deploys a Nutanix Era VM from a `.qcow2` image, then runs a multi-step install package: change default password → accept EULA → discover cluster VIP → gather storage container info → register cluster → create network profiles. Uses both `static` (Python 2) and `sh` scripts in sequence.
- **Provision Postgres with ERA** — provisions a Postgres database through Era's REST API after Era is running.
- **cicd-nexus** — deploys a Jenkins + Nexus CI/CD stack with optional Kubernetes/Karbon container deployment.
- **Grafana** — two variants: CentOS and generic; deploys Grafana monitoring.

## Bash scripts in Automated-Builds-Bash

These are standalone scripts intended to be pasted or referenced as task scripts within blueprints. They target RHEL/CentOS 7 unless noted:
- `web-app.sh` — nginx + PHP 5.6 + Laravel; expects `@@{DBService.address}@@` macro for DB connection
- `loadbalancer.sh` — HAProxy round-robin; backend IPs come from `@@{App01Service.address}@@` and `@@{App02Service.address}@@`
- `mysql-install.sh` — MySQL 5.5/5.6/5.7 install; version and password driven by `@@{DBService.MYSQL_VERSION}@@` and `@@{DBService.MYSQL_PASSWORD}@@`
- `jenkins-build.sh` — Jenkins LTS install; outputs initial admin password to stdout
- `install-updates-by-OS.sh` — detects OS family (RHEL/Debian variants) and installs Python packages accordingly

## CI / GitHub Actions

The Claude Code workflow lives in `.workflows/claude.yml` (not `.github/workflows/`). To activate it on GitHub, it must be moved to `.github/workflows/claude.yml`. It triggers on `@claude` mentions in issues and PR comments and requires an `ANTHROPIC_API_KEY` secret set in the repo.
