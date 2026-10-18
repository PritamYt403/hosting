
<div align="center">

# ⚡ PRITAM HOSTING

### 🚀 Hosting & VPS Management Toolkit

**A modular, menu-driven Bash toolkit for server and hosting management.**

[![Bash](https://img.shields.io/badge/Shell-Bash-121011?style=for-the-badge&logo=gnubash&logoColor=white)](https://www.gnu.org/software/bash/)
[![Platform](https://img.shields.io/badge/Platform-Linux-orange?style=for-the-badge&logo=linux&logoColor=white)](https://www.linux.org/)
[![Ubuntu](https://img.shields.io/badge/OS-Ubuntu-E95420?style=for-the-badge&logo=ubuntu&logoColor=white)](https://ubuntu.com/)
[![GitHub](https://img.shields.io/badge/Hosted_on-GitHub-181717?style=for-the-badge&logo=github&logoColor=white)](https://github.com/PritamYt403/hosting)

**Developed with ❤️ by Pritam**

[Features](#-features) · [Installation](#-installation) · [Menu](#-main-menu) · [Requirements](#-requirements) · [Support](#-support)

</div>

---

## 📖 About the Project

**PRITAM HOSTING MANAGEMENT TOOLKIT** is a Bash-based project designed to bring hosting utilities and server-management scripts together in one convenient terminal interface.

The toolkit uses a modular structure, allowing individual scripts to be maintained and updated separately. Its interactive menu provides access to Pterodactyl management, VPS Maker, and additional tools as they become available.

Our goal is to make server administration more organized, accessible, and convenient.

> **Project status:** Under active development. Features may be incomplete or require additional configuration.

## ✨ Features

- 🎨 **Neon Terminal UI** — Colorful menus and terminal animations.
- 🖥️ **Pterodactyl Management** — Access the Pterodactyl management installer.
- ⚙️ **VPS Maker** — A separate module for VPS-related utilities.
- 🔧 **Modular Architecture** — Keep individual tools in separate scripts.
- 🌐 **Remote Script Loading** — Retrieve modules from this GitHub repository.
- 🛠️ **System Edit** — Reserved for upcoming system-management features.
- ✅ **Bash Syntax Validation** — Check downloaded scripts before execution.
- 📦 **Centralized Toolkit** — Access available modules from one main menu.

*Features depend on the implementation and compatibility of each module.*

## 📋 Requirements

Before running the toolkit, make sure you have:

| Requirement | Description |
|---|---|
| Operating system | A supported Linux distribution |
| Bash | Bash shell |
| cURL | For downloading remote scripts |
| Internet | Required for remote modules |
| Permissions | Root or sudo access for system-level installations |

Some modules may have additional dependencies.

## 🚀 Installation

### Option 1 — Run directly

Review the script on GitHub before executing it, especially if you intend to use root privileges.

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/PritamYt403/hosting/main/mainmenu/install.sh)
```

### Option 2 — Clone the repository

```bash
git clone https://github.com/PritamYt403/hosting.git
cd hosting
```

Run the main menu:

```bash
bash mainmenu/install.sh
```

### Option 3 — Check Bash syntax

To check the downloaded main menu script without running it:

```bash
bash -n <(curl -fsSL https://raw.githubusercontent.com/PritamYt403/hosting/main/mainmenu/install.sh)
```

No output usually means the script passed Bash syntax validation. This does not guarantee that every module will run successfully.

## 🧭 Main Menu

The main toolkit currently uses the following menu:

| Option | Module | Status |
|:---:|---|---|
| A | Pterodactyl Management | In development |
| B | VPS Maker | In development |
| C | System Edit | Coming soon |
| D | Exit Toolkit | Available |

Actual functionality depends on the scripts available in the repository.

## 📁 Project Structure

```text
hosting/
├── mainmenu/
│   ├── install.sh
│   └── vps-maker.sh
├── pterodactyl/
│   └── install.sh
├── vps-maker/
├── README.md
└── LICENSE (optional)
```

This is a simplified overview. The exact files and folders may change as the project develops.

## 🔐 Security Guidelines

Please follow these precautions when using the toolkit:

- **Review scripts first.** Understand what a script does before executing it.
- **Use root privileges carefully.** Installation scripts may modify system files, services, and firewall rules.
- **Protect credentials.** Never commit passwords, API tokens, SSH private keys, or other secrets.
- **Back up your server.** Keep backups before installing, updating, or removing hosting software.
- **Verify remote URLs.** Confirm that scripts come from the intended repository and branch.
- **Check compatibility.** Confirm that the operating system and software versions are supported.

Bash syntax validation checks for parsing errors only; it does not prove that a script is safe.

## 🛠️ Troubleshooting

<details>
<summary><strong>cURL is not installed</strong></summary>

On Debian or Ubuntu:

```bash
sudo apt-get update
sudo apt-get install -y curl
```

</details>

<details>
<summary><strong>The installer says to run as root</strong></summary>

Use a VPS account with authorized root access. If your account has sudo privileges, you can open a root shell with:

```bash
sudo -i
```

Some online terminals do not provide root access and cannot run system-level installers.

</details>

<details>
<summary><strong>Module download failed</strong></summary>

Check your internet connection, repository name, branch, and file path. Confirm that the requested file exists in the `main` branch.

</details>

<details>
<summary><strong>Bash syntax error</strong></summary>

Check the relevant script using:

```bash
bash -n mainmenu/install.sh
```

Make sure all `if`, `case`, loops, functions, and quotation marks are correctly closed.

</details>

## 🗺️ Roadmap

- [ ] Complete and test Pterodactyl management features.
- [ ] Develop and document VPS Maker.
- [ ] Implement System Edit utilities.
- [ ] Improve dependency and compatibility checks.
- [ ] Improve error handling and installation logs.
- [ ] Add module-specific documentation.
- [ ] Add release notes and version information.

## 🤝 Contributing

Suggestions, bug reports, and improvements are welcome.

1. Fork the repository.
2. Create a feature branch.
3. Make your changes.
4. Test the affected scripts.
5. Submit a pull request.

Please avoid committing credentials or other sensitive information.

## 💬 Support

For questions, bugs, or feature suggestions, open an issue in the repository:

**[PritamYt403/hosting — GitHub Repository](https://github.com/PritamYt403/hosting/issues)**

## ⚖️ Disclaimer

This project is provided for educational purposes and authorized server administration.

The toolkit may contain experimental or incomplete features. Always inspect scripts before execution, especially when using root privileges. Use the software responsibly and maintain backups of important data.

## 📜 License

No license has been specified unless a `LICENSE` file exists in the repository. Until a license is added, do not assume that others have permission to redistribute or modify the project.

---

<div align="center">

### ⚡ PRITAM HOSTING MANAGEMENT TOOLKIT

**Built with Bash · Designed for Server Management**

Made with ❤️ by **Pritam**

</div>
