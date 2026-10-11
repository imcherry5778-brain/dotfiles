"""Small, platform-neutral helpers used by reviewed installers."""
from dataclasses import dataclass
import hashlib
import os
from pathlib import Path
import platform
import shutil
import subprocess
import urllib.request


def run(arguments, *, capture=False, cwd=None, timeout=900, env=None, noninteractive=False):
    """Use argument arrays: paths containing spaces never pass through a shell."""
    result = subprocess.run(
        [str(argument) for argument in arguments], check=True, text=True,
        stdout=subprocess.PIPE if capture else None,
        stdin=subprocess.DEVNULL if noninteractive else None,
        stderr=subprocess.PIPE if noninteractive else None,
        cwd=cwd or Path.home(), timeout=timeout, env=env,
    )
    return result.stdout


@dataclass(frozen=True)
class Host:
    system: str
    architecture: str
    distribution: str = ""

    @classmethod
    def detect(cls):
        system = {"Linux": "linux", "Darwin": "macos", "Windows": "windows"}.get(platform.system())
        architecture = {"x86_64": "x64", "AMD64": "x64", "arm64": "arm64", "aarch64": "arm64"}.get(platform.machine())
        if not system or not architecture:
            raise ValueError("Only Linux, macOS and Windows on x64/arm64 are supported.")
        distribution = ""
        if system == "linux":
            distribution = platform.freedesktop_os_release()["ID"]
        return cls(system, architecture, distribution)


def download_verified(url, destination, sha256):
    """Stream to a private staging file and verify before it can be executed."""
    if not url.startswith("https://") or len(sha256) != 64 or any(character not in "0123456789abcdef" for character in sha256):
        raise ValueError("An HTTPS URL and SHA-256 digest are required.")
    destination = Path(destination)
    digest = hashlib.sha256()
    request = urllib.request.Request(url, headers={"User-Agent": "dotfiles-installer"})
    created = False
    try:
        with urllib.request.urlopen(request, timeout=120) as response:
            with destination.open("xb") as output:
                created = True
                destination.chmod(0o600)
                while chunk := response.read(1024 * 1024):
                    output.write(chunk)
                    digest.update(chunk)
        if digest.hexdigest() != sha256:
            raise ValueError(f"Checksum mismatch: {destination.name}")
    except Exception:
        if created:
            destination.unlink(missing_ok=True)
        raise
    return destination


def administrative_command(arguments):
    """Only system packages need elevation; user configuration never runs as root."""
    if hasattr(os, "geteuid") and os.geteuid() == 0:
        return list(arguments)
    sudo = shutil.which("sudo")
    if not sudo:
        raise ValueError("System package installation needs sudo or the explicit root packages-only stage.")
    return [sudo, *arguments]
