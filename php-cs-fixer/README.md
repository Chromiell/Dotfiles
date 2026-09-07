# PHP-CS-Fixer Configuration

Configuration for [PHP-CS-Fixer](https://github.com/PHP-CS-Fixer/PHP-CS-Fixer), a tool to automatically fix PHP coding standards according to defined PSR rules and project conventions.

---

## 📦 Required Packages

To install PHP and PHP-CS-Fixer on Debian-based systems use the composer package provided in this repository, or:

```bash
sudo apt update
sudo apt install composer
# And install php-cs-fixer globally via composer:
composer global require friendsofphp/php-cs-fixer
```

---

## 🧩 Dotfiles Module Dependencies

| Module | Dependency Type | Description |
| :--- | :--- | :--- |
| [`composer`](../composer) | Binary Provider | Provides the global `composer.json` defining `friendsofphp/php-cs-fixer`. |
| [`neovim`](../neovim) | Consumer / Editor | Neovim's PHP formatter (`lua/plugins/php-cs-fixer.lua`) directly consumes `~/.config/php-cs-fixer/.php-cs-fixer.php`. |


---

## 📂 Structure

- `.config/php-cs-fixer/.php-cs-fixer.php`: PHP code styling ruleset defining standard formatting rules, risky rule allowances, and excluded paths.

---

## 🚀 Usage with GNU Stow

Symlink this configuration to your home directory:

```bash
cd ~/.dotfiles
stow php-cs-fixer
```
