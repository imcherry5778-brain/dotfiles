# Repository working rules

- This is `imcherry5778-brain/dotfiles`; the organization directory is not the Git root.
- Current phase is foundation only. Do not apply user configuration, install or upgrade host tools, alter global Git settings, or change VMs/boot/partitions as part of repository scaffolding.
- Keep deployable source under `home/`. `.chezmoiroot` points there. Repository docs, tests and operational code stay outside it.
- `home/.chezmoiignore` deliberately disables deployment during this phase. Changing that boundary belongs to a reviewed configuration migration.
- Use chezmoi for configuration files and machine differences; use mise for tool versions. Never declare the same install inventory in multiple owners.
- Root `mise.toml` contains repository tasks, not a duplicate of the future global CLI inventory.
- Preserve existing Fedora behavior when migration is later authorized. Do not copy credentials, sessions, generated memory, plugin caches, SSH keys or the complete home into this repository.
- AI settings shared with Orca require selective updates preserving unmanaged keys and hooks. Personal instructions and this repository's `AGENTS.md` have different purposes.
- Compute paths from the actual home or repository root. Do not hardcode `/home/imcherry` into executable code or redirect all applications through global XDG overrides.
- Do not add empty application configs, vendor source copies, redundant bootstrap entry points or parallel task discovery systems.
- Verify native PowerShell and POSIX shell paths. Keep checks isolated from the real home; test paths containing spaces and repeat execution.
- Explain what actually ran versus what is planned. CI rendering does not establish desktop, authentication or all distribution compatibility.
