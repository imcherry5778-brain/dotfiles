FROM ubuntu:26.04
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends git zsh tmux python3 ca-certificates curl tar gzip unzip xz-utils bzip2 util-linux passwd ncurses-bin libstdc++6 bash-completion wl-clipboard build-essential && rm -rf /var/lib/apt/lists/*
RUN useradd --create-home --shell /bin/bash dotfiles-test
COPY --chown=dotfiles-test:dotfiles-test [".", "/home/dotfiles-test/dotfiles source/"]
USER dotfiles-test
WORKDIR /home/dotfiles-test
ENV PATH="/home/dotfiles-test/.local/bin:/usr/local/bin:/usr/bin:/bin" LANG="C.UTF-8"
CMD ["python3", "/home/dotfiles-test/dotfiles source/tests/test-install.py"]
