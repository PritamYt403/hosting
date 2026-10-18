
<div align="center">

# ⚡ PRITAM HOSTING MANAGEMENT TOOLKIT

### Your VPS. Your Control. One Toolkit.

A Bash-based toolkit designed to simplify hosting management and VPS-related tasks through a clean, interactive terminal menu.

[![GitHub Repository](https://img.shields.io/badge/GitHub-Repository-181717?style=for-the-badge&logo=github)](https://github.com/PritamYt403/hosting)
[![Shell](https://img.shields.io/badge/Shell-Bash-4EAA25?style=for-the-badge&logo=gnubash&logoColor=white)](https://www.gnu.org/software/bash/)
[![Platform](https://img.shields.io/badge/Platform-Linux-FCC624?style=for-the-badge&logo=linux&logoColor=black)](https://www.linux.org/)

**Developed by [PritamYt403](https://github.com/PritamYt403)**

</div>

---

## 📌 About The Project

**PRITAM HOSTING MANAGEMENT TOOLKIT** is a menu-driven Bash project created to make hosting-related scripts easier to access and manage from a Linux terminal.

Instead of remembering multiple script URLs, users can launch the main menu and select the available tool they need.

The project is designed with simplicity, modularity, and future expansion in mind.

## ✨ Features

- 🎨 **Interactive Terminal Menu** — Navigate through a simple command-line interface.
- 🖥️ **Pterodactyl Module** — Access the Pterodactyl installer module when available.
- ⚙️ **VPS Maker Module** — A dedicated section for VPS-related tools.
- 🔗 **Remote Script Execution** — Launch the main menu directly from the repository.
- 🧩 **Modular Structure** — Keep tools organized in separate directories.
- 🚀 **Easy Access** — Start the toolkit with a single command.
- 🛠️ **Expandable Design** — Add more modules as the project develops.

## 🚀 Quick Start

### Method 1 — Run Directly

Requirements:
- A Linux environment with Bash.
- `curl` installed.
- A compatible terminal and required permissions for the selected module.
- Internet access to retrieve repository scripts.

Run:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/PritamYt403/hosting/main/mainmenu/install.sh)
```

> **Important:** Review remote scripts before executing them. Some modules may require root privileges. Only run commands you trust and understand.

### Method 2 — Clone the Repository

Install Git and GitHub CLI if needed, then authenticate the GitHub CLI if your setup requires it.

```bash
gh repo clone PritamYt403/hosting
cd hosting
```

Alternatively, use Git:

```bash
git clone https://github.com/PritamYt403/hosting.git
cd hosting
```

Inspect the files before running the main menu:

```bash
less mainmenu/install.sh
```

To launch it locally:

```bash
bash mainmenu/install.sh
```

## 🧭 Main Menu

The toolkit's menu is intended to provide access to the following sections:

| Option | Module | Purpose |
|:---:|---|---|
| A | Pterodactyl | Open the Pterodactyl module |
| B | VPS Maker | Open the VPS Maker module |
| C | System Tools | Reserved for additional tools, depending on implementation |
| D | Exit | Close the toolkit |

*Available options depend on the current implementation in the repository.*

## 📂 Project Structure

```text
hosting/
├── mainmenu/
│   └── install.sh
├── pterodactyl/
├── vps-maker/
└── README.md
```

The module directories may contain additional scripts and supporting files.

## 🔐 Security & Best Practices

- Review scripts before running them with elevated privileges.
- Never share SSH private keys, passwords, API tokens, or other secrets.
- Use root privileges only when a module genuinely requires them.
- Verify remote script URLs and repository ownership.
- Back up important server data before making system-level changes.
- Run commands only on systems you own or are authorized to administer.

## 🛠️ Troubleshooting

### `curl: command not found`

Install `curl` using your Linux distribution's package manager.

### `gh: command not found`

Install GitHub CLI, or use the standard `git clone` command shown above.

### `Run this tool as root`

The selected module requires elevated privileges. Use an authorized VPS account with the necessary permissions. A restricted online terminal may not provide root access.

### Remote script not found

Verify the file exists in the repository and check that the URL uses the correct branch and path.

### Permission or execution errors

Check the script's requirements, Linux environment, and permissions before retrying.

## 🗺️ Roadmap

Potential improvements for future versions:

- [ ] Additional hosting management modules
- [ ] Improved error handling and diagnostics
- [ ] Consistent terminal themes and animations
- [ ] Module status and dependency checks
- [ ] Expanded documentation

*Roadmap items are plans, not promises of currently available features.*

## 🤝 Contributing

Contributions, suggestions, and bug reports are welcome.

1. Fork the repository.
2. Create a feature branch.
3. Make and test your changes.
4. Submit a pull request describing the changes.

Please keep scripts readable, validate shell syntax, and document any new dependencies.

## 💬 Support

For questions, bugs, or feature requests, visit:

- **Repository:** https://github.com/PritamYt403/hosting
- **Issues:** https://github.com/PritamYt403/hosting/issues

When reporting an issue, include the command used, the relevant error message, and your environment. Never include passwords or access tokens.

## 📄 License

Please check the repository's `LICENSE` file for the applicable license and permissions. If no license file exists, do not assume that public availability grants permission to redistribute or modify the code.

---

<div align="center">

**Built with ⚡ by [PritamYt403](https://github.com/PritamYt403)**

*Simple tools. Cleaner workflows. Better hosting management.*

</div>
