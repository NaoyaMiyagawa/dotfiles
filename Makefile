DOTPATH    := $(realpath $(dir $(lastword $(MAKEFILE_LIST))))
CANDIDATES := $(wildcard .??*)
# Repo-only entries: linking them into ~ would, e.g., point ~/.vscode (VS Code's extensions dir) at this repo.
EXCLUSIONS := .DS_Store .git .gitignore .gitattributes .ai .vscode
DOTFILES   := $(filter-out $(EXCLUSIONS), $(CANDIDATES))
PLISTS     := $(notdir $(wildcard $(DOTPATH)/.config/cmux/*.plist))

.DEFAULT_GOAL := help

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

t3themes: ## Symlink T3 Code's themes folder to .config/t3code/themes (run after T3 Code's first launch)
	@rmdir $(HOME)/.t3/userdata/themes 2>/dev/null || true
	@ln -sfnv $(DOTPATH)/.config/t3code/themes $(HOME)/.t3/userdata/themes

clean: ## Remove the dotfile symlinks from the home directory (keeps this repo)
	@echo 'Remove dot files in your home directory...'
	@-$(foreach val, $(DOTFILES), rm -v $(HOME)/$(val);)

help: ## Self-documented Makefile
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) \
		| sort \
		| awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'
