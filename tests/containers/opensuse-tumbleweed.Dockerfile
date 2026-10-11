FROM registry.opensuse.org/opensuse/tumbleweed:latest
RUN zypper --non-interactive install --no-recommends git-core zsh tmux python3 ca-certificates curl tar gzip unzip xz bzip2 util-linux shadow ncurses-utils bash-completion wl-clipboard gcc gcc-c++ make ghostty libnotify4 mozilla-nss libsecret-1-0 libasound2
RUN useradd --create-home --shell /bin/bash dotfiles-test
COPY --chown=dotfiles-test:dotfiles-test [".", "/home/dotfiles-test/dotfiles source/"]
ARG FULL_INSTALL=1
ENV DOTFILES_FULL_INSTALL=$FULL_INSTALL
USER dotfiles-test
WORKDIR /home/dotfiles-test
ENV PATH="/home/dotfiles-test/.local/bin:/usr/local/bin:/usr/bin:/bin" LANG="C.UTF-8"
CMD ["python3", "/home/dotfiles-test/dotfiles source/tests/test-install.py"]
