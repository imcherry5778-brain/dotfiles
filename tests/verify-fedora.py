#!/usr/bin/env python3
"""Verify proposed Fedora sources in temporary destinations, never the real home."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import shutil
import stat
import subprocess
import tempfile
import tomllib

ROOT = Path(__file__).resolve().parents[1]


def run(argv):
    result = subprocess.run([str(x) for x in argv], text=True, capture_output=True, timeout=60)
    if result.returncode:
        raise RuntimeError(f"exit {result.returncode}: " + result.stderr + result.stdout)
    return result.stdout


def snapshot(directory):
    return {
        str(p.relative_to(directory)): ("link:" + os.readlink(p) if p.is_symlink()
                                       else hashlib.sha256(p.read_bytes()).hexdigest())
        for p in directory.rglob("*") if p.is_symlink() or p.is_file()
    }


def verify(chezmoi, mise=None, oh_my_zsh=None, neovim=None, gh_binary=None):
    with tempfile.TemporaryDirectory(prefix="fedora-config-check-") as temporary:
        scratch = Path(temporary)
        source = scratch / "source with spaces"
        destination = scratch / "isolated home with spaces"
        shutil.copytree(ROOT, source, ignore=shutil.ignore_patterns(".git", ".artifacts", ".cache", ".tmp"))
        destination.mkdir()
        run(["git", "-c", "init.templateDir=", "init", "--quiet", "--initial-branch=main", "--", source])
        override = scratch / "override.json"
        base = [chezmoi, "--source", source, "--destination", destination,
                "--config", scratch / "config.toml", "--cache", scratch / "cache",
                "--persistent-state", scratch / "state.boltdb", "--no-tty", "--no-pager",
                "--override-data-file", override]

        def data(enabled, platform="fedora"):
            family = "darwin" if platform == "macos" else "windows" if platform == "windows" else "linux"
            return {"platform": platform, "initialized": True,
                    "chezmoi": {"os": family, "homeDir": str(destination)},
                    "deployment": {"enabled": enabled, "externals": False},
                    "features": {"ai": True, "conda": True, "personal_fedora": True,
                                 "bitwarden_agent": True, "delta": False, "editor_web": True},
                    "machine": {"conda_prefix": str(destination / "miniforge with spaces"),
                                "ssh_agent_socket": str(destination / "agent socket")}}

        for platform in ["fedora", "ubuntu", "arch", "opensuse-tumbleweed", "macos", "windows"]:
            override.write_text(json.dumps(data(False, platform)))
            assert not run(base + ["managed"]).strip(), platform
            if platform not in {"fedora", "ubuntu", "arch", "opensuse-tumbleweed"}:
                override.write_text(json.dumps(data(True, platform)))
                assert not run(base + ["managed"]).strip(), platform
        override.write_text(json.dumps(data(True)))
        targets = run(base + ["managed"])
        assert ".zshrc" in targets and "settings.json" in targets
        assert "hosts.yml" not in targets and "auth.json" not in targets
        assert "README.md" not in targets and "manifest.json" not in targets

        def write(name, value):
            p = destination / name
            p.parent.mkdir(parents=True, exist_ok=True)
            p.write_text(value)

        write("unmanaged-marker", "must survive\n")
        write(".gitconfig", '[user]\n name = fixture-user\n email = fixture@example.invalid\n signingkey = FIXTURE-KEY\n'
              '[commit]\n gpgsign = true\n[credential "https://github.com"]\n helper =\n'
              ' helper = !/old/mise/installs/gh/old/gh auth git-credential\n'
              '[custom]\n preserved = yes\n')
        write(".config/gh/config.yml", '# Keep this comment\neditor:\nbrowser:\npager:\nhttp_unix_socket:\naliases:\n  custom: issue list\nprompt: disabled\n')
        (destination / ".config/gh").chmod(0o751)
        (destination / ".config/gh/config.yml").chmod(0o600)
        (destination / ".local/share").mkdir(parents=True, exist_ok=True)
        (destination / ".local/share").chmod(0o700)
        write(".claude/settings.json", json.dumps({"hooks": {"Stop": [{"command": "fixture-orca-hook"}]},
              "statusLine": {"command": "fixture-status"}, "unknown": {"keep": True}}))
        write(".codex/config.toml", '[hooks.state]\nfixture = "keep"\n[mcp_servers.fixture]\ncommand = "fixture-only"\n'
              '[projects."/fixture/project"]\ntrust_level = "trusted"\n')
        write(".config/opencode/opencode.json", json.dumps({"provider": {"fixture": {"keep": True}}}))

        # These applies are confined to the disposable home above. External downloads are disabled.
        run(base + ["apply"])
        first = snapshot(destination)
        first_modes = {str(p.relative_to(destination)): stat.S_IMODE(p.stat().st_mode)
                       for p in destination.rglob("*") if not p.is_symlink()}
        run(base + ["apply"])
        second = snapshot(destination)
        assert first_modes == {str(p.relative_to(destination)): stat.S_IMODE(p.stat().st_mode)
                               for p in destination.rglob("*") if not p.is_symlink()}, "Repeat apply changed permissions"
        assert second == first, "Repeat apply changed: " + str([k for k in second if first.get(k) != second[k]])
        assert not run(base + ["diff"]).strip(), "Repeated preview has a diff"
        assert (destination / "unmanaged-marker").read_text() == "must survive\n"

        gitconfig = (destination / ".gitconfig").read_text()
        assert "FIXTURE-KEY" in gitconfig and "gpgsign = true" in gitconfig
        assert "fixture@example.invalid" in gitconfig and "preserved = yes" in gitconfig
        assert "/shims/gh" in gitconfig and "/old/mise/" not in gitconfig
        assert gitconfig.count("path = ~/.config/git/config") == 1
        assert run(["git", "config", "--file", destination / ".gitconfig", "--get", "user.email"]).strip() == "fixture@example.invalid"
        helper = run(["git", "config", "--file", destination / ".gitconfig", "--get-all", "credential.https://github.com.helper"])
        assert "isolated home with spaces/.local/share/mise/shims/gh' auth git-credential" in helper
        for relative, mode in [(".local/share", 0o700), (".config/gh", 0o700),
                               (".config/gh/config.yml", 0o600)]:
            assert stat.S_IMODE((destination / relative).stat().st_mode) == mode, relative
        gh = (destination / ".config/gh/config.yml").read_text()
        assert '# Keep this comment' in gh
        assert all(f"{key}:\n" in gh for key in ["editor", "browser", "pager", "http_unix_socket"])
        assert "custom: issue list" in gh and "co: pr checkout" in gh and "prompt: disabled" in gh
        claude = json.loads((destination / ".claude/settings.json").read_text())
        assert claude["unknown"]["keep"] and claude["hooks"]["Stop"][0]["command"] == "fixture-orca-hook"
        assert claude["statusLine"]["command"] == "fixture-status"
        assert claude["theme"] == "dark" and claude["tui"] == "fullscreen"
        codex = tomllib.loads((destination / ".codex/config.toml").read_text())
        assert codex["hooks"]["state"]["fixture"] == "keep"
        assert codex["projects"]["/fixture/project"]["trust_level"] == "trusted"
        assert codex["mcp_servers"]["fixture"]["command"] == "fixture-only"
        assert codex["model"] == "gpt-6.1-sol" and codex["model_reasoning_effort"] == "high"
        opencode = json.loads((destination / ".config/opencode/opencode.json").read_text())
        assert opencode["provider"]["fixture"]["keep"] and opencode["autoupdate"] is False

        # Exact no-op: preserve formatting, comments, ordering and missing final newline.
        for relative, content in [
            (".claude/settings.json", '{ "tui": "fullscreen", "theme": "dark", "hooks": {"keep": true} }'),
            (".codex/config.toml", '# Preserve comment\nservice_tier = "priority"\nmodel_reasoning_effort = "high"\nmodel = "gpt-6.1-sol"'),
            (".config/opencode/opencode.json", '{ "provider": {"keep": true}, "autoupdate": false }'),
        ]:
            write(relative, content)
            assert run(base + ["cat", destination / relative]) == content, relative
            run(base + ["apply", destination / relative])
            assert (destination / relative).read_text() == content, relative

        gh_path = destination / ".config/gh/config.yml"
        gh_cases = [
            ('# exact no-op\neditor:\naliases: {co: "pr checkout", custom: "issue list"}\ngit_protocol: https', False),
            ('# Empty scalars\neditor:\nbrowser:\npager:\nhttp_unix_socket:\ngit_protocol: ssh # transport\naliases:\n  co: issue list # shortcut\n  custom: issue list\nunknown: {nested: null}\n', True),
            ('aliases:\n    custom: issue list\n', True),
            ('aliases: {} # keep header\n', True),
            ('# only a comment\n', True),
            ('', True),
        ]
        for content, changed in gh_cases:
            write(".config/gh/config.yml", content)
            target = run(base + ["cat", gh_path])
            assert (target != content) is changed
            if not changed:
                assert target == content
            else:
                for line in content.splitlines():
                    if line.startswith('#') or line.startswith('unknown:') or 'custom:' in line:
                        assert line in target, line
                for comment in ['# transport', '# shortcut', '# keep header']:
                    if comment in content:
                        assert comment in target, comment
            run(base + ["apply", gh_path])
            assert run(base + ["cat", gh_path]) == target
            assert stat.S_IMODE(gh_path.stat().st_mode) == 0o600
            assert stat.S_IMODE(gh_path.parent.stat().st_mode) == 0o700
            if gh_binary:
                environment = os.environ.copy()
                environment["GH_CONFIG_DIR"] = str(gh_path.parent)
                for key, expected in [("git_protocol", "https"), ("editor", ""), ("browser", ""),
                                      ("pager", ""), ("http_unix_socket", "")]:
                    result = subprocess.run([gh_binary, "config", "get", key], text=True,
                                            capture_output=True, env=environment, timeout=30)
                    assert result.returncode == 0 and result.stdout.rstrip('\n') == expected, (key, result.stdout)
        # Unsupported changed layouts and invalid input must not be overwritten.
        for content in ['aliases: {co: "issue list", custom: "keep"}\ngit_protocol: ssh\n',
                        'aliases: [invalid\n']:
            write(".config/gh/config.yml", content)
            result = subprocess.run([str(x) for x in base + ["apply", gh_path]], text=True, capture_output=True)
            assert result.returncode != 0 and gh_path.read_text() == content
        # A fresh machine must also receive a private directory.
        shutil.rmtree(gh_path.parent)
        fresh_base = base.copy()
        fresh_base[fresh_base.index("--persistent-state") + 1] = scratch / "fresh-gh-state.boltdb"
        run(fresh_base + ["apply", gh_path.parent])
        assert gh_path.is_file() and stat.S_IMODE(gh_path.stat().st_mode) == 0o600
        assert stat.S_IMODE(gh_path.parent.stat().st_mode) == 0o700
        print("gh: blank scalars/comments, actual parser (when supplied), unchanged AI text and private modes: OK")

        configs = ["config.toml", "config.ai.toml", "config.personal-fedora.toml"]
        inventories = [tomllib.loads((destination / ".config/mise" / name).read_text())["tools"] for name in configs]
        assert [len(x) for x in inventories] == [13, 1, 24]
        assert len(set().union(*(set(x) for x in inventories))) == 38, "Duplicate tool ownership"
        selector = tomllib.loads((destination / ".config/mise/miserc.toml").read_text())
        assert selector["env"] == ["ai", "personal-fedora"]
        if mise:
            environment = os.environ.copy()
            environment.pop("MISE_ENV", None)
            for name, value in {
                "MISE_CONFIG_DIR": destination / ".config/mise",
                "MISE_GLOBAL_CONFIG_FILE": destination / ".config/mise/config.toml",
                "MISE_DATA_DIR": scratch / "mise/data", "MISE_CACHE_DIR": scratch / "mise/cache",
                "MISE_STATE_DIR": scratch / "mise/state", "MISE_SYSTEM_CONFIG_DIR": scratch / "mise/system",
                "MISE_TRUSTED_CONFIG_PATHS": destination / ".config/mise",
            }.items():
                environment[name] = str(value)
            result = subprocess.run([mise, "-C", str(destination), "ls", "--current", "--json"],
                                    text=True, capture_output=True, env=environment, timeout=60)
            if result.returncode:
                raise RuntimeError(result.stderr)
            selected = json.loads(result.stdout)
            expected = set().union(*(set(x) for x in inventories))
            assert set(selected) == expected, "mise did not select all three global environment configs"
            print("Installed mise: global selector resolves exactly 38 tools without installing: OK")
        assert len(list((destination / ".config/carapace/specs").glob("*.yaml"))) == 404
        assert len(list((destination / ".local/share/shell-completion/zsh/native").iterdir())) == 26
        assert (destination / ".tmux.conf").is_symlink()
        assert (destination / ".config/nvim/lazy-lock.json").read_bytes() == (source / "home/dot_config/nvim/lazy-lock.json").read_bytes()
        assert not (destination / ".config/nvim/lua/plugins/example.lua").exists()

        zshrc = (destination / ".zshrc").read_text()
        assert "/home/imcherry" not in zshrc
        assert zshrc.index("zsh-path.zsh") < zshrc.index('source "$ZSH/oh-my-zsh.sh"')
        assert zshrc.index("__mamba_setup") < zshrc.index("zsh-init.zsh")
        assert 'eval "$(mise activate' not in zshrc and 'eval "$(zoxide init' not in zshrc
        for shell, paths in [("zsh", [destination / ".zshrc", *(destination / ".config/shell-completion").glob("*.zsh")]),
                             ("bash", [destination / ".bashrc", destination / ".config/carapace/bridge/bash/.bashrc",
                                       *(destination / ".config/shell-completion").glob("*.bash")])]:
            binary = shutil.which(shell)
            if not binary:
                raise RuntimeError(f"Test dependency missing: {shell}")
            for p in paths:
                run([binary, "-n", p])
        compile((destination / ".local/bin/refresh-completions").read_text(), "refresh-completions", "exec")
        if neovim:
            environment = os.environ.copy()
            for name, directory in [("XDG_CONFIG_HOME", "config"), ("XDG_DATA_HOME", "data"),
                                    ("XDG_STATE_HOME", "state"), ("XDG_CACHE_HOME", "cache")]:
                environment[name] = str(scratch / "nvim-check" / directory)
            lua_check = "lua for _, p in ipairs(vim.fn.globpath(" + json.dumps(str(destination / ".config/nvim")) + ", '**/*.lua', 0, 1)) do assert(loadfile(p)) end"
            result = subprocess.run([neovim, "--headless", "-u", "NONE", "-i", "NONE", "-n", "-c", lua_check, "-c", "qa"],
                                    text=True, capture_output=True, env=environment, timeout=30)
            if result.returncode or "Error" in result.stderr:
                raise RuntimeError(result.stderr)
            print("Installed Neovim: Lua syntax compiled without loading configuration/plugins: OK")
        for ai, personal in [(False, False), (True, False), (False, True)]:
            limited = data(True)
            limited["features"].update(ai=ai, personal_fedora=personal, conda=False,
                                       bitwarden_agent=False, editor_web=False)
            override.write_text(json.dumps(limited))
            managed = run(base + ["managed"])
            assert (".claude/settings.json" in managed) is ai
            assert (".config/carapace/specs" in managed) is personal
            rendered = run(base + ["execute-template", "--file", source / "home/dot_config/mise/miserc.toml.tmpl"])
            expected = (["ai"] if ai else []) + (["personal-fedora"] if personal else [])
            assert tomllib.loads(rendered)["env"] == expected
            lua = run(base + ["execute-template", "--file", source / "home/dot_config/nvim/lua/config/lazy.lua.tmpl"])
            assert "extras.lang.python" not in lua and 'import = "plugins"' not in lua
            bashrc = run(base + ["execute-template", "--file", source / "home/.chezmoitemplates/shell/fedora.bashrc.tmpl"])
            assert ("bash-init.bash" in bashrc) is personal
        override.write_text(json.dumps(data(True)))

        # Invalid input cannot silently turn an existing configuration into defaults.
        claude_path = destination / ".claude/settings.json"
        valid_claude = claude_path.read_text()
        claude_path.write_text("{invalid fixture}")
        result = subprocess.run([str(x) for x in base + ["cat", claude_path]], text=True, capture_output=True)
        assert result.returncode != 0 and "invalid" in result.stderr.lower() and claude_path.read_text() == "{invalid fixture}"
        claude_path.write_text(valid_claude)
        if oh_my_zsh:
            # Linux mount namespaces keep HOME unchanged but redirect that path to the test home.
            # The real host filesystem is read-only and the network is unavailable in the child.
            bwrap = shutil.which("bwrap")
            if not bwrap:
                raise RuntimeError("Optional runtime test requires bubblewrap")
            vendor = Path(oh_my_zsh).resolve()
            shutil.copytree(vendor, destination / ".oh-my-zsh", ignore=shutil.ignore_patterns(".git"))
            community = Path.home() / ".local/share/shell-completion/zsh/community"
            for name in json.loads((source / "home/.chezmoidata.json").read_text())["completion"]["community_files"]:
                shutil.copyfile(community / name, destination / ".local/share/shell-completion/zsh/community" / name)
            testbin = destination / "testbin"
            testbin.mkdir()
            mock = testbin / "mock-tool"
            mock.write_text('''#!/usr/bin/python3
import os,sys
from pathlib import Path
name=Path(sys.argv[0]).name
args=sys.argv[1:]
if name=="mise" and args[:2]==["activate","zsh"]:
 print('typeset -g DF_MISE_ACTIVATIONS=$((${DF_MISE_ACTIVATIONS:-0}+1))')
elif name=="mise" and args[:2]==["completion","zsh"]:
 print('#compdef mise\\n_arguments "--help[help]"')
elif name=="mise" and args[:2]==["which","nvim"]:
 print(os.environ['HOME']+'/testbin/nvim')
elif name=="fzf" and args==["--version"]:
 print('0.74.4 (fixture)')
elif name=="fzf" and args==["--zsh"]:
 print('typeset -g DF_FZF_ACTIVATIONS=$((${DF_FZF_ACTIVATIONS:-0}+1))')
elif name=="zoxide" and args[:1]==["init"]:
 print('typeset -g DF_ZOXIDE_ACTIVATIONS=$((${DF_ZOXIDE_ACTIVATIONS:-0}+1))')
''')
            mock.chmod(0o755)
            for name in ["mise", "fzf", "zoxide", "nvim", "kubectl", "aws", "helm"]:
                (testbin / name).symlink_to(mock.name)
            real_home = str(Path.home())
            sandbox = [bwrap, "--unshare-net", "--ro-bind", "/", "/", "--dev", "/dev", "--tmpfs", "/tmp", "--bind", scratch, scratch,
                       "--bind", destination, real_home, "--chdir", scratch,
                       "--setenv", "TMPDIR", str(scratch),
                       "--setenv", "PATH", real_home + "/testbin:/usr/bin:/bin",
                       "--setenv", "XDG_CONFIG_HOME", real_home + "/.config",
                       "--setenv", "XDG_DATA_HOME", real_home + "/.local/share",
                       "--setenv", "XDG_STATE_HOME", real_home + "/.local/state",
                       "--setenv", "XDG_CACHE_HOME", real_home + "/.cache"]
            script = '''
print -r -- "Runtime fixture: mise=${DF_MISE_ACTIVATIONS:-0} fzf=${DF_FZF_ACTIVATIONS:-0} zoxide=${DF_ZOXIDE_ACTIVATIONS:-0}"
(( DF_MISE_ACTIVATIONS == 1 && DF_FZF_ACTIVATIONS == 1 && DF_ZOXIDE_ACTIVATIONS == 1 )) || exit 10
[[ $ZSH_THEME == robbyrussell && $HISTSIZE == 50000 && $SAVEHIST == 50000 ]] || exit 11
[[ $SUDO_EDITOR == "$HOME/testbin/nvim" ]] || exit 12
[[ ${plugins[-1]} == zsh-syntax-highlighting ]] || exit 13
[[ ${(j: :)plugins} == "git mise fzf globalias zoxide kubectl copybuffer aws helm zsh-claudecode-completion zsh-history-substring-search fzf-tab zsh-autosuggestions zsh-syntax-highlighting" ]] || exit 14
[[ ${_comps[wall]} == _sc_carapace ]] || exit 15
(( $+functions[agy] )) || exit 16
source "$HOME/.zshrc"
typeset -A occurrences
for item in $path; do (( occurrences[$item]++ )); done
(( occurrences[$HOME/.local/bin] == 1 )) || exit 17
print 'OMZ runtime, single activation owners, provider registration and PATH deduplication: OK'
'''
            output = run(sandbox + ["/usr/bin/zsh", "-d", "-i", "-c", script])
            print(output.strip())
            (destination / ".oh-my-zsh").rename(destination / "disabled-oh-my-zsh")
            output = run(sandbox + ["/usr/bin/zsh", "-d", "-i", "-c", "[[ $EDITOR == nvim ]] && print 'Missing OMZ: usable shell OK'"])
            print(output.strip())

        # Materialize the external declaration as text only; no external is fetched.
        external_data = data(True)
        external_data["deployment"]["externals"] = True
        override.write_text(json.dumps(external_data))
        external = run(base + ["execute-template", "--file", source / "home/.chezmoiexternal.toml.tmpl"])
        declarations = tomllib.loads(external)
        assert len(declarations) == 57, len(declarations)
        assert all(v.get("exact") is False for v in declarations.values() if v["type"] == "archive")
        assert all("master" not in v["url"] and "latest" not in v["url"] for v in declarations.values())
        print("Fedora draft: isolated repeat apply, preserved Git identity/AI hooks, 38 tool ownerships, shell syntax and disabled-by-default targets: OK")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--chezmoi", required=True)
    parser.add_argument("--mise", help="Optional existing mise executable; config inspection only")
    parser.add_argument("--oh-my-zsh", help="Optional existing OMZ for a read-only Linux namespace runtime test with mock CLIs")
    parser.add_argument("--neovim", help="Optional existing Neovim for syntax-only Lua compilation; plugins are not loaded")
    parser.add_argument("--gh", help="Optional existing GitHub CLI; read back empty values with its actual config parser")
    args = parser.parse_args()
    verify(str(Path(args.chezmoi).resolve()), str(Path(args.mise).resolve()) if args.mise else None, args.oh_my_zsh,
           str(Path(args.neovim).resolve()) if args.neovim else None,
           str(Path(args.gh).resolve()) if args.gh else None)
