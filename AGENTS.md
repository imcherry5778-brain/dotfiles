# Repository working rules

- This is `imcherry5778-brain/dotfiles`; the organization directory is not the Git root. The repository is public: never commit credentials, private backups or per-machine deployment records.
- Personal Fedora, Ubuntu, Arch, openSUSE Tumbleweed, Windows 11 and Mac ARM64 machines use enabled chezmoi automation from their own checkout. Installing on or reapplying to any of them requires authorization for that task; review a fresh diff and make a targeted private backup first. Preserve existing profiles, tool versions, native providers, authentication, native security policy and QGA/SELinux/SSD guards. Do not upgrade unrelated tools or change VM definitions/boot/partitions. FreeBSD is excluded.
- Keep deployable source under `home/`. `.chezmoiroot` points there. Repository docs, tests and operational code stay outside it.
- `home/.chezmoiignore` disables deployment by default. Tests may opt into targets only in an isolated destination or a disposable GitHub-hosted runner.
- Use chezmoi for configuration files and machine differences; use mise for tool versions. Never declare the same install inventory in multiple owners.
- Root `mise.toml` contains read-only repository tasks with auto-install disabled. Pinned Unix installer Python belongs to `scripts/unix/mise.toml`; it never becomes a Windows/global CLI requirement.
- Windows uses native PowerShell 7, WinGet for the four bootstrap products and the Windows-only GCC parser compiler, mise for common CLI/runtimes and Aider/OpenCode, and checksum-reviewed official installers for the other AI CLI and Orca. Do not require WSL. Keep Windows provider declarations separate from Linux mise ownership.
- `home/dot_config/mise/config.ai.toml` owns the OpenCode 2.x pin for every platform. Keep its `[tool_alias]`: the short name otherwise resolves to npm. Fedora's ai-cli/sys-update may move the pin together with this source.
- Preserve existing Fedora behavior during configuration changes. Do not copy credentials, sessions, generated memory, plugin caches, SSH keys or the complete home into this repository.
- AI settings shared with Orca require selective updates preserving unmanaged keys and hooks. Personal instructions and this repository's `AGENTS.md` have different purposes.
- Compute paths from the actual home or repository root. Do not hardcode `/home/imcherry` into executable code or redirect all applications through global XDG overrides.
- Do not add empty application configs, full vendor checkouts, redundant bootstrap entry points or parallel task discovery systems. The three selected completion files with modified compdef headers retain upstream copyright notices and documented provenance.
- Verify native PowerShell and POSIX shell paths. Keep checks isolated from the real home; test paths containing spaces and repeat execution.
- Explain what actually ran versus what is planned. CI rendering does not establish desktop, authentication or all distribution compatibility.
