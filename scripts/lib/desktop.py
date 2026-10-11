"""Native desktop packages, separate from mise-owned CLI versions."""
import json
import platform
import subprocess
from pathlib import Path
import shutil
import tempfile
import xml.etree.ElementTree as ET

from lib.runtime import Host, administrative_command, download_verified, run
from lib.appimage import install_orca_appimage, orca_directory

ROOT = Path(__file__).resolve().parents[1]


def package_present(host, name):
    if host.distribution == "ubuntu":
        try:
            return run(["dpkg-query", "-W", "-f=${db:Status-Status}", name], capture=True).strip() == "installed"
        except subprocess.CalledProcessError:
            return False
    if host.distribution in {"arch", "opensuse-tumbleweed"}:
        if name == "orca-ide":
            return all(path.is_file() for path in [orca_directory() / "resources/bin/orca-ide",
                                                  Path.home() / ".local/bin/orca-ide",
                                                  Path.home() / ".local/share/applications/orca-ide.desktop"])
        if host.distribution == "arch":
            return subprocess.run(["pacman", "-Q", name], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL).returncode == 0
    if host.distribution in {"fedora", "opensuse-tumbleweed"}:
        return subprocess.run(["rpm", "-q", name], stdout=subprocess.DEVNULL).returncode == 0
    if host.system == "macos":
        application = "Ghostty.app" if name == "ghostty" else "Orca.app"
        return any((directory / application).exists() for directory in [Path("/Applications"), Path.home() / "Applications"])
    if host.system == "windows":
        return bool(shutil.which("orca") or (Path.home() / "AppData/Local/Programs/Orca/Orca.exe").exists())
    raise ValueError(f"Native desktop packages are not reviewed for {host.distribution}.")


def desktop_plan(host):
    """A pure plan is useful on every OS, including CI without a desktop."""
    if host.distribution == "ubuntu":
        return {"ghostty": "Ubuntu 26.04 official APT package", "orca": "checksum-pinned official .deb"}
    if host.distribution == "arch":
        return {"ghostty": "Arch extra official package; existing sync database", "orca": "checksum-pinned official AppImage, unpacked with bundled CLI"}
    if host.distribution == "opensuse-tumbleweed":
        return {"ghostty": "openSUSE official OSS package; existing repository metadata", "orca": "checksum-pinned official AppImage, unpacked with bundled CLI"}
    if host.distribution == "fedora":
        return {"ghostty": "officially documented scottames/ghostty COPR", "orca": "checksum-pinned official .rpm"}
    if host.system == "macos":
        return {"ghostty": "Homebrew ghostty cask", "orca": "Homebrew stablyai/orca/orca cask"}
    if host.system == "windows":
        return {"ghostty": "unsupported: native Windows build is unavailable", "orca": "checksum-pinned official Windows installer"}
    raise ValueError(f"Desktop packages are not reviewed for {host.distribution}.")


def install_opensuse_packages(packages):
    """Require a pure-addition solver plan; keep installed packages and vendors."""
    command = ["zypper", "--non-interactive", "--no-refresh", "--xmlout", "install",
               "--no-recommends", "--no-force-resolution", "--no-allow-vendor-change",
               "--no-allow-downgrade"]
    plan = run(administrative_command([*command, "--dry-run", *packages]), capture=True)
    document = ET.fromstring(plan)
    summary = document.find("install-summary")
    if summary is not None:
        for action in summary:
            if action.tag.startswith("to-") and action.tag != "to-install" and list(action):
                raise ValueError(f"openSUSE package plan changes installed packages: {action.tag}; review separately.")
    run(administrative_command([*command, *packages]))


def install_ghostty(host):
    if host.system == "windows":
        print("Ghostty: no native Windows distribution; no substitute is installed.", flush=True)
        return
    if package_present(host, "ghostty"):
        print("Ghostty: existing installation preserved.", flush=True)
        return
    if host.distribution == "ubuntu":
        release = platform.freedesktop_os_release()
        if release.get("VERSION_ID") != "26.04":
            raise ValueError("Official Ubuntu Ghostty package reviewed for 26.04 only.")
        run(administrative_command(["apt-get", "install", "--yes", "--no-remove", "ghostty"]))
    elif host.distribution == "arch":
        # Never refresh sync databases alone: Arch does not support partial upgrades.
        run(administrative_command(["pacman", "-S", "--needed", "--noconfirm", "ghostty"]))
    elif host.distribution == "opensuse-tumbleweed":
        install_opensuse_packages(["ghostty"])
    elif host.distribution == "fedora":
        run(administrative_command(["dnf", "copr", "enable", "--assumeyes", "scottames/ghostty"]))
        run(administrative_command(["dnf", "install", "--assumeyes", "ghostty"]))
    elif host.system == "macos":
        run(["brew", "install", "--cask", "ghostty"])
    else:
        raise ValueError(f"Ghostty installer missing for {host.distribution}.")


def install_orca(host):
    if package_present(host, "orca-ide") or (host.system == "linux" and shutil.which("orca-ide")):
        print("Orca: existing installation preserved.", flush=True)
        return
    if host.system == "macos":
        run(["brew", "install", "--cask", "stablyai/orca/orca"])
        return
    release = json.loads((ROOT / "desktop-release.json").read_text())
    # Arch and openSUSE share the publisher AppImage; checksum metadata has one owner.
    asset_platform = "linux-appimage" if host.distribution in {"arch", "opensuse-tumbleweed"} else host.distribution or host.system
    key = f"{asset_platform}-{host.architecture}"
    asset = release["orca"]["assets"].get(key)
    if not asset:
        raise ValueError(f"No reviewed Orca asset for {key}.")
    if host.distribution in {"arch", "opensuse-tumbleweed"}:
        install_orca_appimage(asset, release["orca"]["version"])
        return
    with tempfile.TemporaryDirectory(prefix="dotfiles-orca-") as temporary:
        package = Path(temporary) / asset["name"]
        download_verified(asset["url"], package, asset["sha256"])
        if host.distribution == "ubuntu":
            # APT's sandbox user must be able to read this non-secret verified package.
            Path(temporary).chmod(0o755)
            package.chmod(0o644)
            run(administrative_command(["apt-get", "install", "--yes", "--no-remove", package]))
        elif host.distribution == "fedora":
            run(administrative_command(["dnf", "install", "--assumeyes", package]))
        elif host.system == "windows":
            # Keep the publisher's installer UI; do not invent undocumented silent flags.
            run([package])
        else:
            raise ValueError(f"Orca installer missing for {key}.")
    if not package_present(host, "orca-ide"):
        raise ValueError("Orca installer finished without a detectable installation.")


def install_desktop(host=None):
    host = host or Host.detect()
    print(json.dumps(desktop_plan(host), ensure_ascii=False), flush=True)
    install_ghostty(host)
    install_orca(host)
