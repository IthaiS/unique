\
ZIP ?= foodlabel_ai_SUPER_RELEASE_EVERYTHING_*.zip
BRANCH ?= main
REMOTE ?= https://github.com/IthaiS/unique.git

# Defaults for release
TAG ?= v0.5.0
TITLE ?= FoodLabel AI $(TAG)
NOTES ?= $(firstword $(wildcard RELEASE_NOTES.md))

.PHONY: commit infra deploy-dev deploy-prod release

commit:
\tchmod +x commit_super_release.sh || true
\t./commit_super_release.sh --repo-root . --branch $(BRANCH) --remote $(REMOTE)

infra:
\tgh workflow run "Infra Stack (Terraform)" || true

deploy-dev:
\tgh workflow run "Deploy Backend (dev)" || true

deploy-prod:
\tgh workflow run "Deploy Backend (prod)" || true

release:
\tchmod +x scripts/create_release.sh || true
\t@if [ -n "$(NOTES)" ]; then \\
\t  ./scripts/create_release.sh --tag $(TAG) --title "$(TITLE)" --notes "$(NOTES)" --asset $(ZIP); \\
\telse \\
\t  ./scripts/create_release.sh --tag $(TAG) --title "$(TITLE)" --asset $(ZIP); \\
\tfi
