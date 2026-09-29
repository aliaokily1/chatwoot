# Elkheta branch

This branch (`elkheta`) is Chatwoot **v4.16.2 Community Edition** with Elkheta's changes for WhatsApp Cloud API (Coexistence) use by Admins.

- Upstream: https://github.com/chatwoot/chatwoot (MIT; the `enterprise/` directory is removed at build time and not used).
- Image: `ghcr.io/aliaokily1/chatwoot:elkheta-<sha>`, built by `.github/workflows/elkheta-image.yml` on every push to `elkheta`.
- Plan: see `FORK-PLAN.md` in the Elkheta Follow-up project.

Keep changes small and isolated so upstream releases can be merged.
