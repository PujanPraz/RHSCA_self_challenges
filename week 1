# 🐧 RHCSA Hands-On Self Challenge — Week 1 Notes

> **Goal:** Become a Red Hat Certified System Administrator  
> **Environment:** CentOS 10 (Vagrant / VirtualBox)  
> **Schedule:** ~30 minutes/day | 5 months  

---

## 📋 Table of Contents

- [Day 1 — User Management](#day-1--user-management)
- [Day 2 — Shared Folder & Group Permissions](#day-2--shared-folder--group-permissions)
- [Day 3 — Sticky Bit & Folder Protection](#day-3--sticky-bit--folder-protection)
- [Day 4 — Granular Sudo Access](#day-4--granular-sudo-access)
- [Day 5 — Service Management with systemctl](#day-5--service-management-with-systemctl)
- [Day 6 — Investigating a Service Crash](#day-6--investigating-a-service-crash)
- [Day 7 — Auditing with journalctl](#day-7--auditing-with-journalctl)
- [Week 1 Exam](#week-1-exam)
- [Quick Reference Card](#quick-reference-card)

---

## Day 1 — User Management

### 🎯 Scenario
> A new contractor named **sarah** is joining. Create her account, add her to the **developers** group, force her to change her password on first login, and set her account to expire in **30 days**.

---

### 📖 Concepts

#### Why force password change on first login?
When YOU create sarah's account, YOU set her initial password. That means you know her password. That is a security problem. Forcing a change means only sarah knows her own password after first login.

> Think of it like a hotel giving you a temporary key card. The moment you check in, you set your own room PIN. The hotel staff can no longer enter.

#### Why set account expiry?
Contractors leave. Sysadmins forget. If you don't set an expiry date, a contractor's account stays alive even after they leave the company. Setting expiry means the system **automatically locks them out** — even if you forget.

> It's like a visitor badge that automatically deactivates at 5pm. Security doesn't need to chase the visitor and take it back manually.

#### Why use groups?
Instead of setting permissions for every single person one by one, you create a group. Anyone in `developers` automatically gets the right access.

> It's like a keycard system in an office. Instead of programming each door for each person, you give everyone a "developer" level keycard.

---

### 💻 Commands

```bash
# Create the user
sudo useradd sarah

# Create the group
sudo groupadd developers

# Add sarah to developers group
# -a means APPEND (never remove from existing groups)
# -G means secondary Group
sudo usermod -aG developers sarah

# Set a password for sarah
sudo passwd sarah

# Force password change on first login
# -d 0 means "password was last changed on day zero" = must change immediately
sudo chage -d 0 sarah

# Set account expiry 30 days from today
sudo chage -E $(date -d '+30 days' +%Y-%m-%d) sarah

# Set a specific expiry date
sudo chage -E 2026-08-15 sarah

# Remove expiry completely (permanent employee)
sudo chage -E -1 sarah
```

### ✅ Verification

```bash
# Check user exists and group membership
id sarah
# Output: uid=1001(sarah) gid=1001(sarah) groups=1001(sarah),1002(developers)

# Check password and expiry settings
sudo chage -l sarah
# Output should show:
# Last password change  : password must be changed
# Account expires       : Jun 30, 2026

# Check group membership
getent group developers
# Output: developers:x:1002:sarah
```

### 🧠 Golden Rule
> Always verify after you create. Never assume it worked. A sysadmin who doesn't verify is a sysadmin who causes 3am incidents.

---

## Day 2 — Shared Folder & Group Permissions

### 🎯 Scenario
> Create a shared folder at `/projects/dev`. Only members of the **developers** group should be able to read and write inside it. Everyone else should not even be able to look inside it. Files created inside must automatically belong to the **developers** group.

---

### 📖 Concepts

#### Understanding chmod numbers
Every permission has 3 parts — Owner, Group, Others:

```
chmod 770
        ↑↑↑
        |||
        ||└── Others → 0 = no access at all
        |└─── Group  → 7 = read + write + execute
        └──── Owner  → 7 = read + write + execute
```

| Number | Permissions | Meaning |
|--------|-------------|---------|
| 7 | rwx | Read, Write, Execute |
| 6 | rw- | Read, Write |
| 5 | r-x | Read, Execute |
| 4 | r-- | Read only |
| 0 | --- | No access |

#### What is Setgid (the `s` bit)?
By default when sarah creates a file, it belongs to **sarah** personally. Other developers can't access it.

The **setgid bit** tells the folder: *"Any file born inside me automatically inherits my group."*

> Like a rule in a company: "Any document created in this office automatically belongs to the company, not the individual employee."

**Important:** The `s` in `rws` means BOTH execute AND setgid are active at the same time. It does NOT replace execute.

| Symbol | Execute | Setgid |
|--------|---------|--------|
| `x` | ✅ | ❌ |
| `s` | ✅ | ✅ |
| `S` | ❌ | ✅ |

---

### 💻 Commands

```bash
# Create nested folder in one shot
sudo mkdir -p /projects/dev

# Change group owner only (leave user owner as root)
sudo chown :developers /projects/dev

# Full access for owner and group, zero for others
sudo chmod 770 /projects/dev

# Setgid — new files automatically inherit parent folder's group
sudo chmod g+s /projects/dev
```

### ✅ Verification

```bash
# Check folder permissions
ls -ld /projects/dev
# Output: drwxrws---. 2 root developers 4096 /projects/dev
#                ↑
#                s = setgid is active

# Test as sarah
sudo su - sarah
cd /projects/dev
touch testfile.txt
ls -l
# Output: -rw-r--r--. 1 sarah developers 0 testfile.txt
#                           ↑         ↑
#                         sarah    developers ← inherited automatically!
exit
```

---

## Day 3 — Sticky Bit & Folder Protection

### 🎯 Scenario
> Developers can enter `/projects/dev` but sarah should NOT be able to delete john's files, and john should NOT be able to delete sarah's files. Everyone should only delete their OWN files.

---

### 📖 Concepts

#### What is the Sticky Bit?
The sticky bit controls **deletion only**. Nothing else.

> Like a shared office kitchen: Everyone can put their food in the fridge. Everyone can take OUT their own food. But nobody can throw away someone else's food.

**Without sticky bit:**
- Sarah can delete john's files ❌
- John can delete sarah's files ❌

**With sticky bit:**
- Sarah can only delete sarah's files ✅
- John can only delete john's files ✅
- Root can delete anything ✅

#### Capital T vs small t

| Symbol | Execute (others) | Sticky |
|--------|-----------------|--------|
| `t` | ✅ | ✅ |
| `T` | ❌ | ✅ |

Capital `T` means sticky bit is set but others have no execute permission. Our `/projects/dev` shows `T` because others have `---`.

> `/tmp` on every Linux system has sticky bit with small `t` because others have execute permission there.

---

### 💻 Commands

```bash
# Create another developer user
sudo useradd john
sudo usermod -aG developers john

# Add sticky bit to folder
sudo chmod +t /projects/dev

# Check /tmp to see sticky bit in action on a real system
ls -ld /tmp
# Output: drwxrwxrwt. 10 root root 4096 /tmp
#                  ↑
#                  t = sticky bit (others have execute too)
```

### ✅ Verification

```bash
# Check final permissions
ls -ld /projects/dev
# Output: drwxrws--T. 2 root developers 4096 /projects/dev

# Test — switch to john and try to delete sarah's file
sudo su - john
cd /projects/dev
rm sarah_file.txt
# Output: rm: cannot remove 'sarah_file.txt': Operation not permitted ✅
exit
```

### 🧠 Full Permission Breakdown

```
drwxrws--T
│││││││││└── Sticky bit → only delete your own files
││││││└──── Others → no access
│││└──────── Group (developers) → read, write, execute + setgid
└─────────── Owner → read, write, execute
d = directory
```

---

## Day 4 — Granular Sudo Access

### 🎯 Scenario
> John is a junior developer. Give him permission to **only restart nginx**. Not stop. Not start. Not install anything. Just restart nginx.

---

### 📖 Concepts

#### What is Least Privilege?
Never give more access than what is needed. Ever.

If john only needs to restart nginx, he gets ONLY that. This way even if john's account gets hacked, the attacker can only restart nginx. They cannot destroy the system.

#### Why visudo and NOT vim?
If you make a typo in a sudoers file with vim, sudo breaks completely on your system. You get locked out.

`visudo` checks syntax BEFORE saving. If you make a typo it warns you and lets you fix it first.

> `vim` is like signing a contract with a pen — mistake or not, it's done.  
> `visudo` is like having a lawyer read the contract before you sign.

#### Understanding the sudoers rule syntax

```
john    ALL    =    (ALL)    /usr/bin/systemctl restart nginx
  ↑      ↑              ↑              ↑
  │      │              │              └── ONLY this command
  │      │              └── can run as any user
  │      └── on any machine
  └── this user
```

---

### 💻 Commands

```bash
# Always find the full path first
which systemctl
# Output: /usr/bin/systemctl

# Always use visudo with -f flag
sudo visudo -f /etc/sudoers.d/john

# Inside the file write:
john ALL=(ALL) /usr/bin/systemctl restart nginx

# Multiple permissions (comma separated)
john ALL=(ALL) /usr/bin/systemctl restart nginx, /usr/bin/systemctl status nginx

# Multiple lines (easier to read for many commands)
john ALL=(ALL) /usr/bin/systemctl restart nginx
john ALL=(ALL) /usr/bin/systemctl status nginx

# Allow ALL systemctl commands (only if really needed)
john ALL=(ALL) /usr/bin/systemctl
```

### ✅ Verification

```bash
# Switch to john
sudo su - john

# This should WORK
sudo systemctl restart nginx
# Output: (silence = success in Linux) ✅

# This should FAIL
sudo systemctl status nginx
# Output: Sorry, user john is not allowed to execute this ✅

# This should FAIL
sudo dnf install anything
# Output: john is not in the sudoers file ✅

exit
```

### 🧠 Remember
> In Linux **silence is success**. No error message means it worked. This is different from Windows popups saying "Success!"

---

## Day 5 — Service Management with systemctl

### 🎯 Scenario
> The website is down! nginx is not running. Investigate, fix it, and make sure it never goes down after a reboot again.

---

### 📖 Concepts

#### Two completely separate states

| State | Question it answers |
|-------|-------------------|
| Running / Stopped | Is it running RIGHT NOW? |
| Enabled / Disabled | What happens when server REBOOTS? |

These are independent. A service can be:
- Running but disabled → running now, won't start after reboot
- Stopped but enabled → not running now, will start after reboot

#### What is preset?
`preset` is the **manufacturer's default setting**. Red Hat decided whether a service should start automatically on a fresh install.

```
Loaded: loaded (nginx.service; enabled; preset: disabled)
                               ↑                ↑
                     YOU enabled it    Red Hat's factory default was off
```

Your setting always overrides the preset.

#### What does systemctl enable actually do?
It creates a **symlink** in the startup folder:

```
/etc/systemd/system/multi-user.target.wants/nginx.service
                    → /usr/lib/systemd/system/nginx.service
```

When Linux boots it reads this folder and starts everything in it. `systemctl disable` simply deletes that symlink.

---

### 💻 Commands

```bash
# Check service status (ALWAYS first step)
sudo systemctl status nginx

# Start and stop (affects RIGHT NOW only)
sudo systemctl start nginx
sudo systemctl stop nginx
sudo systemctl restart nginx

# Enable and disable (affects REBOOT behavior only)
sudo systemctl enable nginx
sudo systemctl disable nginx

# Do both at once — enable AND start immediately
sudo systemctl enable --now nginx

# Verify the symlink created by enable
ls -l /etc/systemd/system/multi-user.target.wants/nginx.service
```

### ✅ Reading systemctl status output

```
● nginx.service
   Loaded: loaded (/usr/lib/systemd/system/nginx.service; enabled; preset: disabled)
   Active: active (running) since Thu 2026-06-04 02:19:08 UTC

● = green dot → running
○ = white dot → stopped
× = red cross → failed
```

---

## Day 6 — Investigating a Service Crash

### 🎯 Scenario
> nginx crashed with an error. Investigate using logs, find the exact cause, and fix it.

---

### 📖 Concepts

#### How to read a crash
When a service fails, `systemctl status` gives you clues:

```
Active: failed (Result: exit-code)
Process: ExecStartPre=/usr/sbin/nginx -t (code=exited, status=1/FAILURE)
nginx: open() "/etc/nginx/nginx.conf" failed (2: No such file or directory)
```

Read it line by line:
- `failed` → something went wrong on startup
- `nginx -t FAILURE` → config test failed before even starting
- `No such file` → config file is missing

#### Empty config = broken config
A config file must have the correct structure and content. An empty file created with `touch` is just as broken as a missing file.

```bash
# This creates an EMPTY file — nginx will still fail!
sudo touch /etc/nginx/nginx.conf
# Error: no "events" section in configuration
```

#### How to restore missing config files
```bash
# Reinstall the package — restores missing default config files
sudo dnf reinstall nginx -y
# Note: only restores MISSING files, never overwrites existing ones
```

---

### 💻 Investigation Flow

```bash
# Step 1 — Check status
sudo systemctl status nginx

# Step 2 — Read full logs
sudo journalctl -xeu nginx.service

# Step 3 — Test config manually
sudo nginx -t

# Step 4 — Fix the problem
# (restore config, fix syntax error, etc.)

# Step 5 — Start service
sudo systemctl start nginx

# Step 6 — Verify
sudo systemctl status nginx
```

### 🧠 The Sysadmin Investigation Flow

```
Service down?
      ↓
systemctl status → what is the error?
      ↓
Read the error message carefully
      ↓
Fix the specific problem
      ↓
Start the service again
      ↓
Verify it is running
```

---

## Day 7 — Auditing with journalctl

### 🎯 Scenario
> Your manager wants to know who has been using sudo commands on the server and when. Find out using logs.

---

### 📖 Concepts

#### What is journalctl?
Every service, every login, every sudo command, every crash — your server records all of it. `journalctl` is how you read those records.

> Think of it like your server's diary. Nothing is hidden.

#### What is a unit?
Everything systemd manages is called a **unit**. The `-u` flag filters logs by unit name.

```bash
journalctl -u nginx    # -u = unit
```

---

### 💻 Commands

```bash
# All logs since boot
journalctl

# Last N lines
journalctl -n 20
journalctl -n 50

# Live logs in real time (Ctrl+C to exit)
journalctl -f

# Logs for one service only
journalctl -u nginx
journalctl -u nginx -f    # live logs for nginx

# Filter by time
journalctl --since "today"
journalctl --since "1 hour ago"
journalctl --since "2026-06-01" --until "2026-06-07"
journalctl --since "03:00" --until "04:00"

# Filter by program
journalctl _COMM=sudo       # all sudo activity
journalctl _COMM=sshd       # all SSH activity

# Filter by priority (severity)
journalctl -p err           # errors only
journalctl -p warning       # warnings and above

# Since last boot
journalctl -b

# Combine filters
journalctl _COMM=sudo --since "today"
journalctl -u nginx --since "1 hour ago"
```

### ✅ Reading sudo audit logs

```bash
sudo journalctl _COMM=sudo --since "today"

# Output shows:
vagrant : TTY=pts/0 ; PWD=/home/vagrant ; USER=root ; COMMAND=/sbin/useradd sarah
          ↑                               ↑           ↑
        who ran it                    became root   exact command run
```

### 🧠 Real World Use Cases

| Situation | Command |
|-----------|---------|
| Who used sudo today? | `journalctl _COMM=sudo --since "today"` |
| SSH brute force attack? | `journalctl _COMM=sshd --since "today"` |
| Why did server reboot? | `journalctl --since "friday" --until "monday"` |
| nginx crash at 3am? | `journalctl -u nginx --since "02:55" --until "03:05"` |
| Watch deployment live | `journalctl -u nginx -f` |
| Errors only | `journalctl -p err` |

> The server already knows what happened. Your job is just to ask it the right question.

---

## Week 1 Exam

### Results: 6/6 ✅

| Task | Description | Result |
|------|-------------|--------|
| 1 | Create user alex with 45 day expiry and force password change | ✅ PASS |
| 2 | Create devops group, shared folder, correct permissions | ✅ PASS |
| 3 | Setgid + sticky bit on shared folder | ✅ PASS |
| 4 | Give alex sudo access to only check nginx status | ✅ PASS |
| 5 | Start nginx and enable it to survive reboot | ✅ PASS |
| 6 | Show all sudo commands run today | ✅ PASS |

---

## Quick Reference Card

### User Management

```bash
sudo useradd username
sudo passwd username
sudo groupadd groupname
sudo usermod -aG groupname username
sudo chage -d 0 username                          # force password change
sudo chage -E $(date -d '+30 days' +%Y-%m-%d) username   # expiry in 30 days
sudo chage -E 2026-12-31 username                 # specific expiry date
sudo chage -E -1 username                         # remove expiry
sudo chage -l username                            # view all settings
id username                                       # check groups
getent group groupname                            # check group members
getent passwd username                            # check user details
```

### File Permissions

```bash
sudo chmod 770 /folder          # rwxrwx---
sudo chmod 750 /folder          # rwxr-x---
sudo chmod g+s /folder          # add setgid
sudo chmod +t /folder           # add sticky bit
sudo chown user:group /folder   # change owner and group
sudo chown :group /folder       # change group only
ls -ld /folder                  # check folder permissions
ls -l /folder                   # check file permissions
```

### Sudo Access

```bash
which commandname                          # find full path
sudo visudo -f /etc/sudoers.d/username    # edit sudoers file
# Rule syntax:
username ALL=(ALL) /full/path/to/command
```

### Service Management

```bash
sudo systemctl status service
sudo systemctl start service
sudo systemctl stop service
sudo systemctl restart service
sudo systemctl enable service
sudo systemctl disable service
sudo systemctl enable --now service     # enable + start together
```

### Log Investigation

```bash
journalctl -n 50
journalctl -f
journalctl -u servicename
journalctl -p err
journalctl -b
journalctl --since "today"
journalctl --since "1 hour ago"
journalctl _COMM=sudo
journalctl _COMM=sshd
```

---

## 🧠 Key Principles Learned in Week 1

1. **Always verify** — never assume a command worked. Check the output.
2. **Least privilege** — give only the minimum access needed. Nothing more.
3. **Silence is success** — in Linux no output usually means it worked.
4. **Read error messages carefully** — Linux always tells you exactly what went wrong.
5. **Use visudo, never vim** — one syntax error in sudoers locks you out.
6. **Automate cleanup** — use account expiry so you never have to remember to delete contractor accounts.
7. **Test like a user** — after setting permissions, switch to that user and verify it works from their perspective.

---

*Notes by Pujan | RHCSA Hands-On Self Challenge | Week 1*
