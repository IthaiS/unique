\
ZIP ?= foodlabel_ai_SUPER_RELEASE_LOCKED_HARDENED_*.zip
BRANCH ?= main
REMOTE ?= https://github.com/IthaiS/unique.git
TAG ?= v0.5.0
TITLE ?= FoodLabel AI $(TAG)
NOTES ?= $(firstword $(wildcard RELEASE_NOTES.md))
.PHONY: commit infra deploy-dev deploy-prod release verify tag
commit: ; chmod +x commit_super_release.sh || true; ./commit_super_release.sh --repo-root . --branch $(BRANCH) --remote $(REMOTE)
infra: ; gh workflow run "Infra Stack (Terraform)" || true
deploy-dev: ; gh workflow run "Deploy Backend (dev)" || true
deploy-prod: ; gh workflow run "Deploy Backend (prod)" || true
release: ; chmod +x scripts/create_release.sh || true; if [ -n "$(NOTES)" ]; then ./scripts/create_release.sh --tag $(TAG) --title "$(TITLE)" --notes "$(NOTES)" --asset $(ZIP); else ./scripts/create_release.sh --tag $(TAG) --title "$(TITLE)" --asset $(ZIP); fi
verify: ; chmod +x scripts/verify_bundle.sh || true; ./scripts/verify_bundle.sh .
tag: ; chmod +x scripts/tag_and_push.sh || true; ./scripts/tag_and_push.sh $(TAG) "Release $(TAG)"
