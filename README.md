## Panel Auto Patch + Release

This repository automates:

1. Fetching upstream `https://github.com/pterodactyl/panel`
2. Applying local patch files from `patches/*.patch`
3. Building production frontend assets
4. Packaging a release-ready panel source archive
5. Publishing a GitHub release tagged as `vX.Y.Z-YYYYMMDD`

`X.Y.Z` is parsed from the latest top entry in upstream `CHANGELOG.md`.

## Install

For installation, follow the official guide:

`https://pterodactyl.io/panel/1.0/getting_started.html`

Important:

1. Use your own/custom release link and repository link wherever the guide references official download sources.
2. Do not point installs to upstream binaries/source if you want your patched build deployed.

## Update

For updates, follow all instructions in the official update guide:

`https://pterodactyl.io/panel/1.0/updating.html`

Important:

1. Follow every step on that page in order.
2. Replace upstream download/reference links with your custom release link when pulling new panel code.
3. Keep your local `.env` and persistent data, and follow the guide’s maintenance, dependency, migration, and cache steps exactly.

## Workflow

Workflow file: `.github/workflows/weekly-patch-release.yml`

Triggers:

1. Weekly schedule (Monday 03:00 UTC)
2. Manual run (`workflow_dispatch`)

Manual inputs:

1. `upstream_ref` (optional): branch/tag/SHA to build from
2. `date_override` (optional): force date in `YYYYMMDD`

## Patches

Put patch files into `patches/` with `.patch` extension.

They are applied in filename order using `git apply`.

## Output

Each run creates:

1. `dist/panel_vX.Y.Z-YYYYMMDD.tar.gz`
2. `dist/SHA256SUMS`

Then a GitHub release is created (or updated) with tag format:

`vX.Y.Z-YYYYMMDD`
