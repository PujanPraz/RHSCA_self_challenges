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

## Day 10 — LVM (Logical Volume Manager)

### 🎯 Scenario
> Set up LVM on `/dev/sda`. Create a volume group called `datavg`. Inside it create a logical volume called `datalv` using 5GB. Format it with XFS and mount it permanently at `/lvm-data`.

---

### 📖 Concepts

#### Why LVM? The Problem with Normal Partitions

With normal partitions if `/data` fills up you are stuck:
- Add a new disk
- Create a new partition
- Format it
- Mount it
- Migrate all data
- Cause downtime

LVM solves all of this.

#### The Swimming Pool Analogy

```
Normal partitions = fixed water tanks
Each tank is separate. If one fills up you are stuck.

LVM = swimming pool with flexible dividers
Pool runs low? Pour in another tank. Move the dividers. Zero downtime.
```

#### LVM Has 3 Layers

```
Physical Volume (PV)  ← actual disks — /dev/sda, /dev/sdb
        ↓
Volume Group (VG)     ← the pool — combines all PVs into one
        ↓
Logical Volume (LV)   ← flexible partitions you actually use
```

| LVM Term | Real World Analogy |
|----------|-------------------|
| Physical Volume (PV) | Water tank you pour into the pool |
| Volume Group (VG) | The swimming pool — all water combined |
| Logical Volume (LV) | Flexible dividers inside the pool |

#### LVM vs Normal Partitions

| Situation | Normal Partition | LVM |
|-----------|-----------------|-----|
| Disk is full | Add new disk, migrate data, downtime | Add disk to VG, extend LV, zero downtime |
| Need more space | Complex, risky | One command |
| Multiple disks | Separate, cannot combine | Combined into one pool |

#### The LV Path

lsblk shows: `datavg-datalv` (dash notation — display only)

Real path: `/dev/datavg/datalv` (use this in all commands)

---

### 💻 Commands

#### Step 1 — Create Physical Volume

```bash
# Tell LVM to use this disk
sudo pvcreate /dev/sda

# Verify
sudo pvs
# PV         VG      Fmt   PSize    PFree
# /dev/sda           lvm2  10.00g   10.00g  ← not in any VG yet
```

#### Step 2 — Create Volume Group

```bash
# Create the pool called datavg using /dev/sda
sudo vgcreate datavg /dev/sda

# Verify
sudo vgs
# VG      #PV  #LV   VSize    VFree
# datavg    1    0   10.00g   10.00g  ← empty pool ready
```

#### Step 3 — Create Logical Volume

```bash
# Carve out 5GB from datavg and name it datalv
sudo lvcreate -n datalv -L 5G datavg

# Verify
sudo lvs
# LV      VG      LSize
# datalv  datavg  5.00g  ← 5GB carved, 5GB still free in pool
```

#### Step 4 — Format, Mount, fstab

```bash
# Format with XFS — no fdisk needed with LVM!
sudo mkfs.xfs /dev/datavg/datalv

# Create mount point
sudo mkdir /lvm-data

# Mount temporarily
sudo mount /dev/datavg/datalv /lvm-data

# Get UUID
sudo blkid /dev/datavg/datalv

# Backup fstab
sudo cp /etc/fstab /etc/fstab.backup

# Add to fstab
sudo nano /etc/fstab
# UUID=xxxx /lvm-data xfs defaults 0 0

# Test and reload
sudo mount -a
sudo systemctl daemon-reload

# Reboot and verify
sudo reboot
lsblk
df -h
```

### ✅ Verification Commands

```bash
sudo pvs    # show all physical volumes
sudo vgs    # show all volume groups
sudo lvs    # show all logical volumes
lsblk       # show disk layout with mount points
df -h       # show mounted filesystems with usage
```

---

### 🔮 Extending an LV — Coming Next

When datalv fills up extend it with zero downtime:

```bash
# Add new disk to the pool
sudo vgextend datavg /dev/sdc

# Extend the logical volume
sudo lvextend -L +10G /dev/datavg/datalv

# Grow the filesystem to use new space
sudo xfs_growfs /lvm-data
```

Zero downtime. Zero data loss. Users never notice.

---

## 🎤 Interview Questions — LVM

### Basic Level

**Q: What is LVM and why is it used?**
> LVM stands for Logical Volume Manager. It allows flexible disk management — resize volumes, add disks to a pool, and extend storage without downtime or data migration.

**Q: What are the 3 layers of LVM?**
> Physical Volume (PV) — the actual disk. Volume Group (VG) — the pool combining all PVs. Logical Volume (LV) — the flexible partition you format and mount.

**Q: What command creates a physical volume?**
> `sudo pvcreate /dev/sdb`

**Q: What command creates a volume group?**
> `sudo vgcreate myvg /dev/sdb`

**Q: What command creates a logical volume?**
> `sudo lvcreate -n mylv -L 5G myvg` — creates a 5GB LV called mylv inside myvg.

**Q: What are the three LVM status commands?**
> `pvs` for physical volumes, `vgs` for volume groups, `lvs` for logical volumes.

---

### Intermediate Level

**Q: What is the difference between a logical volume and a normal partition?**
> A normal partition is fixed to one disk. A logical volume can span multiple disks, be resized easily, and extended without downtime.

**Q: How do you extend a logical volume when it gets full?**
> Add disk with `vgextend`, extend the LV with `lvextend`, grow the filesystem with `xfs_growfs` for XFS or `resize2fs` for EXT4.

**Q: Why don't you need fdisk before pvcreate?**
> With LVM you can use an entire disk directly as a PV without partitioning. The logical volume acts as the partition.

**Q: What is the real path of a logical volume?**
> `/dev/vgname/lvname` — for example `/dev/datavg/datalv`. The lsblk display shows `datavg-datalv` with a dash but the actual path uses a forward slash.

---

### Scenario Based

**Q: /data is 95% full on a production server. How do you add space without downtime?**
> 1. `pvcreate /dev/sdc` — make new disk a PV
> 2. `vgextend datavg /dev/sdc` — add to pool
> 3. `lvextend -L +10G /dev/datavg/datalv` — extend the LV
> 4. `xfs_growfs /data` — grow the filesystem
> Zero downtime. Users never notice.

**Q: What is the difference between vgextend and lvextend?**
> `vgextend` adds a new disk to the volume group pool. `lvextend` makes a logical volume bigger using space already in the pool. You need both when adding a new disk.

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

---

## 🎤 Interview Questions — Storage & Disks

These are real questions asked in sysadmin and DevOps interviews.

---

### Basic Level

**Q: What are the 3 steps required before you can store files on a new disk?**
> Partition the disk, create a filesystem, and mount it to a directory. Without all three steps the disk is unusable.

**Q: What is the difference between a partition and a filesystem?**
> A partition is just a divided section of a disk — it has no structure yet. A filesystem is the organization layer on top of a partition that allows Linux to store, find, and manage files. A partition without a filesystem is like a room with no floor.

**Q: What command do you use to partition a disk in Linux?**
> `fdisk` for MBR disks. `parted` or `gdisk` for GPT disks.

**Q: What is the default filesystem used on RHEL and CentOS?**
> XFS. Created with `mkfs.xfs /dev/sdb1`.

**Q: What is fstab and why is it important?**
> `/etc/fstab` is the Filesystem Table. Linux reads it on every boot and automatically mounts all listed filesystems. Without an fstab entry, a manually mounted disk disappears after every reboot.

**Q: What is the difference between `mount` and fstab?**
> `mount` is temporary — it mounts a disk right now but the mount disappears after reboot. fstab is permanent — Linux automatically mounts it on every boot.

**Q: What command do you use to verify a disk is mounted?**
> `df -h` shows all mounted filesystems with size and usage. `lsblk` shows disk layout including mount points.

---

### Intermediate Level

**Q: Why should you use UUID instead of /dev/sdb1 in fstab?**
> Device names like `/dev/sdb1` can change if you add or remove disks. What was `sdb` today could become `sdc` after adding another disk. UUID is burned into the filesystem permanently and never changes regardless of disk order.

**Q: How do you find the UUID of a partition?**
> `sudo blkid /dev/sdb1` — this shows the UUID, filesystem type, and partition UUID.

**Q: What command tests fstab entries without rebooting?**
> `sudo mount -a` — this reads fstab and mounts everything listed. If there is an error it tells you immediately instead of failing silently on reboot.

**Q: What happens if you have a wrong entry in fstab?**
> The server may fail to boot or boot into emergency mode. This is why you always backup fstab before editing (`cp /etc/fstab /etc/fstab.backup`) and always test with `mount -a` before rebooting.

**Q: What is the difference between primary and extended partitions?**
> Primary partitions are real usable partitions — you can put a filesystem directly on them. Extended partitions are containers that hold logical partitions inside them. MBR disks allow maximum 4 partitions, so extended partitions allow you to create more by putting logical partitions inside them.

**Q: What does the last column in fstab (0 0) mean?**
> The 5th column is for the `dump` backup tool — almost always 0. The 6th column controls filesystem check order on boot — 0 means never check, 1 means check first (root partition), 2 means check after root.

**Q: How do you safely unmount a disk?**
> `sudo umount /data` — make sure no processes are using the mount point first. If it says device is busy use `lsof /data` to find which process is using it.

---

### Scenario Based

**Q: A developer says "I can see the disk but cannot write files to it." What do you check?**
> 1. Check if it is mounted: `df -h`
> 2. Check permissions on the mount point: `ls -ld /data`
> 3. Check if filesystem is mounted read-only: `mount | grep sdb1`
> 4. Check disk space: `df -h`

**Q: After adding a new disk the server rebooted and the disk is not mounted anymore. What happened and how do you fix it?**
> The disk was mounted temporarily with `mount` but never added to `/etc/fstab`. Fix: get the UUID with `sudo blkid /dev/sdb1`, add the entry to `/etc/fstab`, run `sudo mount -a` to test, then reboot to verify.

**Q: You edited fstab and now the server won't boot. What do you do?**
> Boot into rescue/emergency mode. Mount the root filesystem manually. Edit `/etc/fstab` and fix or remove the bad entry. Reboot normally. This is exactly why you always backup fstab before editing.

**Q: What is the difference between XFS and EXT4? When would you choose one over the other?**
> XFS is faster for large files and parallel workloads. It is the default on RHEL/CentOS. EXT4 is more mature and handles small files well. For RHEL/CentOS production servers always use XFS. For general purpose Linux servers either works.

---

*Notes by Pujan | RHCSA Hands-On Self Challenge | Week 2*
