# dotfiles

## How to install

```bash
# deploy dotfiles
cd ~
git clone https://github.com/NaoyaMiyagawa/dotfiles.git
cd ~/dotfiles; make install; cd ~
zsh
```

#### for Linux
The following utilities are required.

```bash
# Redhel
yum install -y \
    git zip unzip tar make python3 zsh file gcc vim-enhanced

# Debian
apt-get update && apt-get install -y \
    git zip unzip tar make python3 zsh file gcc vim
```

```
# (optional) apply Japanese Launguage Pack
yum install -y glibc-langpack-ja
```

#### Error Reference

If you encounter this error while using zsh on amazonlinux, try it again on bash.
```
x x86_64 builds for amazonlinux are not yet available for Starship

> If you would like to see a build for your configuration,
> please create an issue requesting a build for x86_64-amazonlinux:
> https://github.com/starship/starship/issues/new/
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
yum install -y git unzip tar make python3 zsh file gcc vim-enhanced
# (optional) apply Japanese Launguage Pack
yum install -y glibc-langpack-ja

# change shell to zsh
zsh

# deploy dotfiles
cd ~
git clone https://github.com/NaoyaMiyagawa/dotfiles.git
cd ~/dotfiles; make install; cd ~

# reload zsh
source ~/.zshrc
```
