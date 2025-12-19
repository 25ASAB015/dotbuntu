# NIX Package Configuration for dotbuntu
# This file defines all system packages to be installed via the NIX package manager.
# 
# Usage:
#   nix-env -iA myPackages -f packages.nix
#
# To add/remove packages, edit the 'myPackages' list below and run sync-packages.sh

{ pkgs ? import <nixpkgs> {} }:

{
  # Main package collection
  myPackages = pkgs.buildEnv {
    name = "dotbuntu-packages";
    paths = with pkgs; [
      #======================================================================
      # CORE DEPENDENCIES (always installed)
      # Original: zsh tree bat highlight ruby-coderay npm
      #======================================================================
      zsh
      tree
      bat
      highlight
      
      # ruby-coderay → Ruby gem, install via: nix-shell -p ruby rubygems, then gem install coderay
      # OR use ruby with bundler in NIX
      ruby
      
      # npm → Use nodejs which includes npm
      nodejs
      
      #======================================================================
      # DEFAULT EXTRA DEPENDENCIES (optional, install with --extras)
      # Original: neovim tmux htop ripgrep fd fzf git-delta
      #======================================================================
      neovim
      tmux
      htop
      ripgrep
      fd
      fzf
      delta  # was: git-delta
      
      #======================================================================
      # AUR EQUIVALENTS (previously installed from AUR)
      # Original: zsh-theme-powerlevel10k-git zsh-autosuggestions zsh-syntax-highlighting
      #======================================================================
      zsh-powerlevel10k  # was: zsh-theme-powerlevel10k-git
      zsh-autosuggestions
      zsh-syntax-highlighting
      
      # dotbare - check if available in nixpkgs, otherwise manual install
      # NOTE: dotbare may not be in stable nixpkgs, consider:
      #   1. Using nixpkgs-unstable channel
      #   2. Manual git clone installation
      #   3. Creating custom derivation
      
      #======================================================================
      # CHAOTIC-AUR EQUIVALENTS (previously from Chaotic-AUR)
      # Original: brave-bin visual-studio-code-bin
      #======================================================================
      brave  # was: brave-bin
      vscode  # was: visual-studio-code-bin
      
      #======================================================================
      # NPM PACKAGES (previously installed globally via npm)
      # Original: @fission-ai/openspec diff-so-fancy
      #======================================================================
      # diff-so-fancy available in nixpkgs
      diff-so-fancy
      
      # @fission-ai/openspec - install via nodejs/npm after NIX setup
      # OR create a node2nix derivation (advanced)
      
      #======================================================================
      # DEVELOPMENT TOOLS (common additions)
      #======================================================================
      git
      curl
      wget
      jq
      gnupg
      openssh
      
      #======================================================================
      # LANGUAGE SERVERS & DEV EXTRAS
      #======================================================================
      # Add as needed, examples:
      # lua-language-server
      # rust-analyzer
      # pyright
    ];
  };
}
