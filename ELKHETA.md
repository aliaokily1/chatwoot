# Elkheta branch

This branch (`elkheta`) is Chatwoot **v4.18.0 Community Edition** with Elkheta's changes for WhatsApp Cloud API (Coexistence) use by Admins.

- Upstream: https://github.com/chatwoot/chatwoot (MIT; the `enterprise/` directory is removed at build time and not used).
- Image: `ghcr.io/aliaokily1/chatwoot:elkheta-<sha>`, built by `.github/workflows/elkheta-image.yml` on every push to `elkheta`.
- Plan: see `FORK-PLAN.md` in the Elkheta Follow-up project.

Keep changes small and isolated so upstream releases can be merged.

## Updating to a new Chatwoot release

Follow `UPSTREAM-UPDATE-GUIDE.md` in the Elkheta Follow-up project (`chatwoot-tools`). In short: merge the release tag
on an `upstream-update/<tag>` branch, prove every Elkheta change survived with `check-elkheta-changes.mjs`, build and
test that branch, then fast-forward `elkheta`.

| Date | From | To | Notes |
|---|---|---|---|
| 2026-10-01 | v4.16.2 | v4.18.0 | 13 files had conflicts, all resolved keeping both sides |
