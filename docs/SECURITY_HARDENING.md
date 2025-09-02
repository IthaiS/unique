# Security & Hardening Checklist
- Workload Identity Federation for CI (no long-lived keys)
- Least-privilege IAM roles for deploy & runtime SAs
- Guarded YAML conditions use env.* to avoid secret evaluation errors
- Pin action versions
- Use Artifact Registry for container images
- Secret Manager for runtime secrets
- Enable Cloud Audit Logs
