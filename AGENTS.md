# Repository working rules

- This is `imcherry5778-brain/dotfiles`; the organization directory is not the Git root.
- Current phase includes the user-authorized personal Fedora migration and disposable GitHub-hosted installation testing. Review a fresh diff, preserve existing behavior, make targeted private backups, install the selected missing CLI versions, apply the personal profile and verify it. Do not upgrade unrelated tools or change VMs/boot/partitions. Other OS real deployment remains a separate instruction.
- Keep deployable source under `home/`. `.chezmoiroot` points there. Repository docs, tests and operational code stay outside it.
- `home/.chezmoiignore` disables deployment by default. Tests may opt into Fedora targets in an isolated destination or the disposable Fedora CI container user. Additional real deployments require user authorization; the personal Fedora migration is now authorized and complete.
- Use chezmoi for configuration files and machine differences; use mise for tool versions. Never declare the same install inventory in multiple owners.
- Root `mise.toml` contains repository tasks, not a duplicate of the future global CLI inventory.
- Preserve existing Fedora behavior during migration and future configuration changes. Do not copy credentials, sessions, generated memory, plugin caches, SSH keys or the complete home into this repository.
- AI settings shared with Orca require selective updates preserving unmanaged keys and hooks. Personal instructions and this repository's `AGENTS.md` have different purposes.
- Compute paths from the actual home or repository root. Do not hardcode `/home/imcherry` into executable code or redirect all applications through global XDG overrides.
- Do not add empty application configs, full vendor checkouts, redundant bootstrap entry points or parallel task discovery systems. The three selected completion files with modified compdef headers retain upstream copyright notices and documented provenance.
- Verify native PowerShell and POSIX shell paths. Keep checks isolated from the real home; test paths containing spaces and repeat execution.
- Explain what actually ran versus what is planned. CI rendering does not establish desktop, authentication or all distribution compatibility.
