FROM archlinux:base
# Fresh disposable OS: full synchronized upgrade, never a partial -Sy install.
RUN pacman -Syu --needed --noconfirm git zsh tmux python ca-certificates curl tar gzip unzip xz bzip2 util-linux shadow ncurses bash-completion wl-clipboard base-devel ghostty libnotify nss libsecret alsa-lib
RUN useradd --create-home --shell /bin/bash dotfiles-test
COPY --chown=dotfiles-test:dotfiles-test [".", "/home/dotfiles-test/dotfiles source/"]
ARG FULL_INSTALL=1
ENV DOTFILES_FULL_INSTALL=$FULL_INSTALL
USER dotfiles-test
WORKDIR /home/dotfiles-test
ENV PATH="/home/dotfiles-test/.local/bin:/usr/local/bin:/usr/bin:/bin" LANG="C.UTF-8"
CMD ["python3", "/home/dotfiles-test/dotfiles source/tests/test-install.py"]
