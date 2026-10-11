FROM ubuntu:26.04
# Only clone/network/admin essentials. The installer prepares shell, compiler and app dependencies.
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends git curl ca-certificates sudo passwd && rm -rf /var/lib/apt/lists/*
RUN useradd --create-home --shell /bin/bash dotfiles-test && printf 'dotfiles-test ALL=(ALL) NOPASSWD: ALL\n' > /etc/sudoers.d/dotfiles-test && chmod 0440 /etc/sudoers.d/dotfiles-test
COPY --chown=dotfiles-test:dotfiles-test [".", "/home/dotfiles-test/dotfiles source/"]
ARG FULL_INSTALL=0
ENV DOTFILES_FULL_INSTALL=$FULL_INSTALL
USER dotfiles-test
WORKDIR /home/dotfiles-test
ENV PATH="/home/dotfiles-test/.local/bin:/usr/local/bin:/usr/bin:/bin" LANG="C.UTF-8"
CMD ["sh", "/home/dotfiles-test/dotfiles source/tests/run-install.sh"]
