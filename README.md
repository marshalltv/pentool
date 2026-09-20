# 🔥 pentool

Penetration Testing Toolkit for Kali Linux

## Features
- **Nmap Scans** — Quick / Full / Aggressive + Vuln scripts
- **DDoS Stress Test** — MAX POWER (hping3 SYN flood + multi-threaded HTTP flood)
- **Hidden Files & Directories Scanner** — dirsearch/gobuster/dirb
- **Subdomain Enumerator** — assetfinder/amass
- **Admin Panel Finder** — 70+ common admin paths with login detection

## Installation
```bash
git clone https://github.com/SENIN-ADIN/pentool.git
cd pentool
sudo cp pentool.sh /usr/local/bin/pentool
sudo chmod +x /usr/local/bin/pentool
sudo apt install nmap dirsearch hping3 -y
