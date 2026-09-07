# Composer Configuration

Global configuration and environment files for [Composer](https://getcomposer.org/), the dependency manager for PHP.

---

## 📦 Required Packages

To install Composer on Debian-based systems:

```bash
sudo apt update
sudo apt install composer
```

---

## 🧩 Dotfiles Module Dependencies

| Module | Dependency Type | Description |
| :--- | :--- | :--- |
| [`php-cs-fixer`](../php-cs-fixer) | Global Package | `composer.json` installs `friendsofphp/php-cs-fixer` globally, providing the formatter binary for `php-cs-fixer` and `neovim`. |


---

## 📂 Structure

- `.config/composer/composer.json`: Global Composer configuration defining global PHP packages, repository settings, and configuration flags.
- `.config/composer/.htaccess`: Access control configuration.

---

## 🚀 Usage with GNU Stow

Symlink this configuration to your home directory:

```bash
cd ~/.dotfiles
stow composer
```
