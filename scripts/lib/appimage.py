"""Install a verified Orca AppImage as a user-owned, version-matched application."""
import os
from pathlib import Path
import shutil
import tempfile

from lib.runtime import download_verified, run


def orca_directory():
    return Path.home() / ".local/share/orca/appimage"


def desktop_quote(path):
    # Desktop Entry Exec quoting differs from shell quoting; % escapes field codes.
    value = str(path).replace("%", "%%")
    for character in ["\\", '"', "`", "$"]:
        value = value.replace(character, "\\" + character)
    return '"' + value + '"'


def install_orca_appimage(asset, version):
    if hasattr(os, "geteuid") and os.geteuid() == 0:
        raise ValueError("Orca AppImage must be installed as the actual desktop user, not root.")
    directory = orca_directory()
    cli = Path.home() / ".local/bin/orca-ide"
    launcher = Path.home() / ".local/share/applications/orca-ide.desktop"
    # Never repair an unknown/partial installation by overwriting it.
    for path in [directory, cli, launcher]:
        if path.exists() or path.is_symlink():
            raise ValueError(f"Existing Orca path requires review: {path}")
    directory.parent.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory(prefix=".orca-install-", dir=directory.parent) as temporary:
        stage = Path(temporary)
        package = stage / asset["name"]
        download_verified(asset["url"], package, asset["sha256"])
        package.chmod(0o755)
        # Publisher runtime extraction needs no FUSE mount or custom Electron wrapper.
        run([package, "--appimage-extract"], cwd=stage, capture=True)
        application = stage / "squashfs-root"
        required = ["AppRun", "orca-ide", "resources/bin/orca-ide",
                    "resources/app.asar.unpacked/out/cli/index.js",
                    "usr/share/icons/hicolor/256x256/apps/orca-ide.png"]
        if not all((application / name).is_file() for name in required):
            raise ValueError("Official AppImage has an unexpected layout; no launcher installed.")
        if f"X-AppImage-Version={version}" not in (application / "orca-ide.desktop").read_text():
            raise ValueError("Official AppImage desktop version does not match the reviewed release.")
        application.rename(directory)
    cli.parent.mkdir(parents=True, exist_ok=True)
    cli.symlink_to(directory / "resources/bin/orca-ide")
    launcher.parent.mkdir(parents=True, exist_ok=True)
    launcher.write_text(
        "[Desktop Entry]\nName=Orca\nType=Application\nTerminal=false\n"
        f"Exec={desktop_quote(directory / 'AppRun')} %U\n"
        f"Icon={directory / 'usr/share/icons/hicolor/256x256/apps/orca-ide.png'}\n"
        "StartupWMClass=orca\nCategories=Development;IDE;\n"
        "MimeType=text/markdown;x-scheme-handler/orca;\n"
        f"X-AppImage-Version={version}\n"
    )
    launcher.chmod(0o644)
    if shutil.which("update-desktop-database"):
        run(["update-desktop-database", launcher.parent])
    print(f"Orca {version}: verified AppImage unpacked; official CLI and desktop launcher installed.", flush=True)
