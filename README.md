
<div align="center">

# ⚡ PRITAM VPS MANAGEMENT TOOLKIT

### Professional Server Management System

**A centralized Bash toolkit for managing VPS services and server utilities.**

![Bash](https://img.shields.io/badge/Shell-Bash-121011?style=for-the-badge&logo=gnubash&logoColor=white)
![Linux](https://img.shields.io/badge/Platform-Linux-orange?style=for-the-badge&logo=linux&logoColor=white)
![Ubuntu](https://img.shields.io/badge/OS-Ubuntu-E95420?style=for-the-badge&logo=ubuntu&logoColor=white)
![License](https://img.shields.io/badge/License-Not%20Specified-lightgrey?style=for-the-badge)

**Made with ❤️ by Pritam**

</div>

---

## 📖 About

**PRITAM VPS MANAGEMENT TOOLKIT** is a menu-driven Bash project designed to organize common VPS management tasks in one place.

It provides a central menu for panel management, server utilities, system information, database setup, and additional management modules.

The toolkit is modular, so individual features can be maintained in separate shell scripts.

## ✨ Features

- 🎨 Professional terminal interface with colored menus
- 🖥️ Panel management module
- ⚙️ Wings management module
- 🗑️ Uninstaller menu
- 🔧 Blueprint, themes, and extensions menu
- 🌐 Cloudflare tunnel module
- 📊 System information module
- 🔗 Tailscale setup module
- 🗄️ Database setup module
- 🧩 Modular Bash script architecture
- ⬇️ Downloads modules from the project's GitHub repository

> **Note:** Available features depend on the implementation of each module. A menu entry does not necessarily mean its installation or management function is fully configured.

## 📋 Requirements

Before using the toolkit, make sure your VPS has:

- A supported Linux distribution
- Bash
- `curl`
- An internet connection
- `sudo` or root privileges for system-level operations

Some modules may require additional packages.

## 🚀 Installation & Usage

### 1. Clone the repository

```bash
git clone https://github.com/PritamYt403/pterodactyl.git
```

### 2. Enter the project directory

```bash
cd pterodactyl
```

### 3. Review the scripts

Read the installer and the modules you intend to use before running them.

### 4. Launch the toolkit

```bash
bash install.sh
```

Alternatively, after reviewing the remote script, you can launch the latest version directly:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/PritamYt403/pterodactyl/main/install.sh)
```

**Security recommendation:** Download and inspect scripts before executing them, especially when using root access.

## 🧭 Main Menu

The toolkit's main menu includes:

| Option | Module |
|---|---|
| A | Panel Management |
| B | VPS Maker |
| C | Tools & Utilities |
| D | System Edit |
| E | Exit Toolkit |

### Panel Management

| Option | Module |
|---|---|
| 1 | Panel Installation |
| 2 | Wings Installation |
| 3 | Uninstall Tools |
| 4 | Blueprint / Themes / Extensions |
| 5 | Cloudflare Tunnel |
| 6 | System Information |
| 7 | Tailscale Setup |
| 8 | Database Setup |
| 9 | Back to Main Menu |

*The exact available actions depend on the scripts present in the repository.*

## 📁 Project Structure

```text
pterodactyl/
├── install.sh
├── panel.sh
├── wings.sh
├── uninstall.sh
├── blueprint.sh
├── cloudflare.sh
├── system-info.sh
├── tailscale.sh
├── database.sh
├── vps-maker.sh
├── tools.sh
└── system-edit.sh
```

Some modules may be added or updated as development continues.

## 🔐 Security

- Review scripts before running them.
- Avoid executing untrusted scripts as root.
- Never publish passwords, API tokens, private keys, or other secrets.
- Keep backups before installing, updating, or uninstalling services.
- Restrict database and tunnel access to trusted networks.
- Verify third-party installers and their official sources.
- Do not assume a downloaded script is safe merely because its Bash syntax is valid.

## 🛠️ Troubleshooting

**`curl: command not found`**

```bash
sudo apt-get update
sudo apt-get install -y curl
```

**Permission denied**

```bash
chmod +x install.sh
bash install.sh
```

**Module download failed**

Check your internet connection, repository URL, branch name, and the existence of the requested file.

**Script syntax check**

```bash
bash -n install.sh
```

Replace `install.sh` with the relevant module filename to check another script.

## 🗺️ Roadmap

- [ ] Complete and test every module
- [ ] Improve installation error handling
- [ ] Add dependency checks
- [ ] Improve backup and recovery support
- [ ] Add clear installation and removal confirmations
- [ ] Document supported Linux distributions
- [ ] Add usage examples for each module

## 🤝 Contributing

Contributions, bug reports, and suggestions are welcome.

1. Fork the repository.
2. Create a feature branch.
3. Make your changes.
4. Test your scripts.
5. Submit a pull request.

## ⚠️ Disclaimer

This project is provided for server administration and educational purposes. Use it only on servers you own or are authorized to manage.

The author is not responsible for data loss, service interruptions, or damage resulting from improper use. Always review scripts and maintain backups before making system-level changes.

## 📜 License

No license has been specified in this README. Add an appropriate `LICENSE` file before distributing the project under a particular open-source license.

---

<div align="center">

### ⚡ PRITAM VPS MANAGEMENT TOOLKIT

**Built with Bash. Managed with confidence.**

**Made by Pritam ❤️**

</div>
