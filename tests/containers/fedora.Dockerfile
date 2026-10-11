FROM registry.fedoraproject.org/fedora:44
RUN dnf install -y git zsh tmux python3 ca-certificates curl tar gzip unzip xz bzip2 util-linux util-linux-script findutils shadow-utils ncurses libstdc++ && dnf clean all
RUN useradd --create-home --shell /bin/zsh dotfiles-test
COPY --chown=dotfiles-test:dotfiles-test [".", "/home/dotfiles-test/dotfiles source/"]
USER dotfiles-test
WORKDIR /home/dotfiles-test
ENV PATH="/home/dotfiles-test/.local/bin:/usr/local/bin:/usr/bin:/bin"
CMD ["python3", "/home/dotfiles-test/dotfiles source/tests/test-install.py"]
