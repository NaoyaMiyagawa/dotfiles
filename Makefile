DOTPATH    := $(realpath $(dir $(lastword $(MAKEFILE_LIST))))
CANDIDATES := $(wildcard .??*)
EXCLUSIONS := .DS_Store .git .gitmodules .travis.yml .gitignore
DOTFILES   := $(filter-out $(EXCLUSIONS), $(CANDIDATES))
PLISTS     := $(notdir $(wildcard $(DOTPATH)/.config/cmux/*.plist))

.DEFAULT_GOAL := help

all:

list: ## Show dot files in this repo
	@$(foreach val, $(DOTFILES), /bin/ls -dF $(val);)

install: ## Create symlink to home directory
	@echo '==> Start to deploy dotfiles to home directory.'
	@echo ''
	@$(foreach val, $(DOTFILES), ln -sfnv $(abspath $(val)) $(HOME)/$(val);)

brew: ## Install CLI tools from the Brewfile
	@echo '==> Installing CLI tools via brew bundle.'
	brew bundle --file=$(DOTPATH)/Brewfile

launchagents: ## Symlink launchd plists into ~/Library/LaunchAgents and load them
	@$(foreach val, $(PLISTS), ln -sfnv $(DOTPATH)/.config/cmux/$(val) $(HOME)/Library/LaunchAgents/$(val);)
	@$(foreach val, $(PLISTS), launchctl bootstrap gui/$$(id -u) $(HOME)/Library/LaunchAgents/$(val) 2>/dev/null || true;)

clean: ## Remove the dotfile symlinks from the home directory (keeps this repo)
	@echo 'Remove dot files in your home directory...'
	@-$(foreach val, $(DOTFILES), rm -v $(HOME)/$(val);)

help: ## Self-documented Makefile
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) \
		| sort \
		| awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'
