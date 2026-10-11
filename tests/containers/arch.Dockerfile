FROM archlinux:base
# Only clone/network/admin essentials. The installer prepares shell, compiler and app dependencies.
RUN pacman -Syu --needed --noconfirm git curl ca-certificates sudo shadow
RUN useradd --create-home --shell /bin/bash dotfiles-test && printf 'dotfiles-test ALL=(ALL) NOPASSWD: ALL\n' > /etc/sudoers.d/dotfiles-test && chmod 0440 /etc/sudoers.d/dotfiles-test
COPY --chown=dotfiles-test:dotfiles-test [".", "/home/dotfiles-test/dotfiles source/"]
ARG FULL_INSTALL=0
ENV DOTFILES_FULL_INSTALL=$FULL_INSTALL
USER dotfiles-test
WORKDIR /home/dotfiles-test
ENV PATH="/home/dotfiles-test/.local/bin:/usr/local/bin:/usr/bin:/bin" LANG="C.UTF-8"
CMD ["sh", "/home/dotfiles-test/dotfiles source/tests/run-install.sh"]
