# dotfiles

## How to install

```bash
# deploy dotfiles
cd ~
git clone https://github.com/NaoyaMiyagawa/dotfiles.git
cd ~/dotfiles; make install; cd -
```

## How to see the list of dotfiles

```bash
cd ~/dotfiles
make list
```

## How to test the result of applied dotfiles

```bash
# run plain amazonlinux2 docker container
docker run -it --rm amazonlinux:2 /bin/bash

----

# install necessary utilities to run installer of dotfiles
yum install -y git unzip tar make python3 zsh file
# (optional) apply Japanese Launguage Pack
yum install -y glibc-langpack-ja

# deploy dotfiles
cd ~
git clone https://github.com/NaoyaMiyagawa/dotfiles.git
cd ~/dotfiles; make install; cd -

# reload zsh
source ~/.zshrc
```
