# 🐧 RHCSA Hands-On Self Challenge — Week 2 Notes

> **Topic:** Storage — Disks, Partitions, Filesystems, Mounting  
> **Environment:** CentOS 10 (VirtualBox VM)  
> **Second Disk:** 10GB `/dev/sdb` added via VirtualBox  

---

## 📋 Table of Contents

- [Day 8 — Disk Partitioning with fdisk](#day-8--disk-partitioning-with-fdisk)
- [Day 9 — Filesystem, Mounting & fstab](#day-9--filesystem-mounting--fstab)
- [Quick Reference Card](#quick-reference-card)

---

## The Big Picture — How Storage Works in Linux

Before touching any commands, understand these 3 steps. Every disk setup follows this exact flow:

```
Raw Disk
    ↓
1. Partition    → divide the disk into sections
    ↓
2. Filesystem   → format it so Linux can organize files
    ↓
3. Mount        → attach it to a folder so you can use it
    ↓
4. fstab        → make it survive reboots automatically
```

> Think of a new disk like an empty plot of land.
> You cannot build on raw land.
> You must first divide it, then lay the floor, then open the door.

---

## Day 8 — Disk Partitioning with fdisk

### 🎯 Scenario
> A new 10GB disk `/dev/sdb` was added to the server. Create one partition using the entire disk.

---

### 📖 Concepts

#### What is a Partition?
Dividing a disk into sections. Like building walls inside a warehouse to separate different areas.

```
sdb (10GB whole disk)
├─sdb1 (5GB) ← partition 1
└─sdb2 (5GB) ← partition 2
```

You can have one partition (entire disk) or many. Depends on your needs.

#### What is a Sector?
A disk is divided into tiny equal chunks called sectors. Like marks on a ruler.

```
|----|----|----|----|----|----|
2048                    20971519
start                      end
```

- Sectors 0-2047 are reserved for bootloader and partition table
- Usable space starts at sector **2048** — always accept this default

#### Primary vs Extended Partitions

| Type | Description |
|------|-------------|
| Primary | A real usable partition. Can hold a filesystem directly. Maximum 4 per disk. |
| Extended | A container partition. Cannot hold files directly. Used to create unlimited logical partitions inside. |

> Extended partitions exist because old MBR disks only allow 4 partitions maximum. Use 3 primary + 1 extended container with logical partitions inside.

#### fdisk Safety Net
```
Changes will remain in memory only, until you decide to write them.
```
Nothing is permanent until you press `w`. If you make a mistake press `q` to quit without saving. Start fresh.

---

### 💻 Commands

```bash
# Check current disk layout
lsblk

# Open fdisk for sdb
sudo fdisk /dev/sdb
```

#### Inside fdisk — Key Commands

| Key | Action |
|-----|--------|
| `m` | Show help menu |
| `n` | Create new partition |
| `p` | Print current partition table |
| `d` | Delete a partition |
| `w` | Write changes and exit (permanent!) |
| `q` | Quit without saving |

#### Creating a Partition Step by Step

```
Command (m for help): n          ← new partition
Partition type: p                ← primary (press Enter for default)
Partition number: 1              ← press Enter for default
First sector: 2048               ← press Enter for default
Last sector: 20971519            ← press Enter to use entire disk
                                    OR type +5G for 5GB partition
                                    OR type +500M for 500MB partition

Command (m for help): p          ← verify before saving
Command (m for help): w          ← write and save permanently
```

#### Specifying Partition Size

| What you want | What to type at Last sector |
|---------------|---------------------------|
| Entire disk | Press Enter (default) |
| 5GB partition | `+5G` |
| 500MB partition | `+500M` |
| 2TB partition | `+2T` |

---

### ✅ Verification

```bash
lsblk
# Before:
# sdb    10G    disk
#
# After:
# sdb           10G    disk
# └─sdb1        10G    part    ← partition created!
```

---

## Day 9 — Filesystem, Mounting & fstab

### 🎯 Scenario
> Format `sdb1` with XFS filesystem. Mount it at `/data`. Make it survive every reboot automatically.

---

### 📖 Concepts

#### What is a Filesystem?
After partitioning, the partition exists but Linux cannot organize files on it yet. A filesystem is the structure that allows Linux to store, find, and organize files.

> Like laying a floor in a room. Without a floor you cannot put furniture in it.

#### Common Filesystems on Linux

| Filesystem | Description |
|------------|-------------|
| XFS | Fast, modern. **Default on RHEL/CentOS**. Best for large files. |
| EXT4 | Older but very reliable. Common on Ubuntu. |
| VFAT | Simple. Used for USB drives and Windows compatibility. |
| swap | Special — used as virtual RAM, not for files. |

#### What is Mounting?
Attaching a disk to a folder so Linux can access it.

```
/data    ← the door (mount point)
  ↑
sdb1     ← the room behind the door
```

Everything you put in `/data` physically goes onto `sdb1`.

#### Temporary vs Permanent Mount

| Type | Command | Survives reboot? |
|------|---------|-----------------|
| Temporary | `sudo mount /dev/sdb1 /data` | ❌ No |
| Permanent | Add entry to `/etc/fstab` | ✅ Yes |

#### What is fstab?
`fstab` = **F**ile**s**ystem **Tab**le

A file Linux reads on every boot. It says:
> *"Mount this disk at this location automatically."*

```bash
cat /etc/fstab
# Each line has 6 columns:
UUID=xxx    /data    xfs    defaults    0    0
   ↑          ↑       ↑        ↑        ↑    ↑
Device    Where    Type   Options   Dump  Check
```

| Column | Name | Common values |
|--------|------|---------------|
| 1 | Device | UUID=xxx or /dev/sdb1 |
| 2 | Mount point | /data, /backup, / |
| 3 | Filesystem | xfs, ext4, swap |
| 4 | Options | defaults |
| 5 | Dump | 0 (almost always) |
| 6 | Check | 0=never, 1=root only, 2=others |

#### Why UUID Instead of /dev/sdb1?

Device names can change. If you add another disk, what was `sdb` yesterday could become `sdc` today. But UUID is **burned into the filesystem forever**. It never changes.

> UUID = the permanent identity card of a partition.

#### ⚠️ fstab Warning
One wrong line in fstab = **server won't boot**. Always:
1. Backup before editing: `sudo cp /etc/fstab /etc/fstab.backup`
2. Test before rebooting: `sudo mount -a`

---

### 💻 Commands

```bash
# Step 1 — Create XFS filesystem
sudo mkfs.xfs /dev/sdb1

# Step 2 — Create mount point folder
sudo mkdir /data

# Step 3 — Mount temporarily
sudo mount /dev/sdb1 /data

# Step 4 — Verify it is mounted
df -h
lsblk

# Step 5 — Find UUID
sudo blkid /dev/sdb1
# Output: UUID="c2baf94d-0d7f-4771-8e0a-c1039e45005e" TYPE="xfs"

# Step 6 — Backup fstab (ALWAYS do this first!)
sudo cp /etc/fstab /etc/fstab.backup

# Step 7 — Add entry to fstab
sudo nano /etc/fstab
# Add this line at the bottom:
# UUID=c2baf94d-0d7f-4771-8e0a-c1039e45005e /data xfs defaults 0 0

# Step 8 — Reload and test
sudo systemctl daemon-reload
sudo mount -a

# Step 9 — Reboot and verify
sudo reboot
# After reboot:
lsblk
df -h
```

### ✅ Verification

```bash
df -h
# /dev/sdb1    10G    228M    9.8G    3%    /data ✅

lsblk
# └─sdb1    10G    part    /data ✅
```

---

### 🔧 Useful Extra Commands

```bash
# Check if a partition has a filesystem already
sudo blkid /dev/sdb1

# Unmount a disk
sudo umount /data

# Remove mount point folder
sudo rmdir /data

# Delete partition (inside fdisk)
sudo fdisk /dev/sdb
# d → delete
# w → save

# Reinstall package to restore missing config
sudo dnf reinstall nginx -y
```

---

## Quick Reference Card

### Disk Setup — Full Flow

```bash
# 1. Check disks
lsblk

# 2. Partition
sudo fdisk /dev/sdb
# n → p → 1 → Enter → Enter OR +5G → p → w

# 3. Create filesystem
sudo mkfs.xfs /dev/sdb1        # XFS
sudo mkfs.ext4 /dev/sdb1       # EXT4

# 4. Create mount point
sudo mkdir /data

# 5. Mount temporarily
sudo mount /dev/sdb1 /data

# 6. Verify
df -h
lsblk

# 7. Get UUID
sudo blkid /dev/sdb1

# 8. Backup fstab
sudo cp /etc/fstab /etc/fstab.backup

# 9. Add to fstab
sudo nano /etc/fstab
# UUID=xxxx /data xfs defaults 0 0

# 10. Test and reload
sudo mount -a
sudo systemctl daemon-reload

# 11. Reboot and verify
sudo reboot
df -h
lsblk
```

---

## 🧠 Key Principles Learned in Week 2 (So Far)

1. **3 steps before files** — Partition → Filesystem → Mount. Skip any and the disk is useless.
2. **Always use UUID in fstab** — device names change, UUIDs never do.
3. **Always backup fstab** — one wrong line breaks the boot process.
4. **Always run mount -a** — test fstab before rebooting, not after.
5. **Silence is success** — no output from mount means it worked.
6. **Verify everything** — run `lsblk` and `df -h` after every step.

---

*Notes by Pujan | RHCSA Hands-On Self Challenge | Week 2*
