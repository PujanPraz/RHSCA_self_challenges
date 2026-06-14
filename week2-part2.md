# 🐧 RHCSA Hands-On Self Challenge — Week 2 Part 2 Notes

> **Topic:** LVM — Logical Volume Manager
> **Environment:** CentOS 10 (VirtualBox VM)
> **Disk used:** `/dev/sda` (10GB)

---

## 📋 Table of Contents

- [Why LVM Exists](#why-lvm-exists)
- [The 3 Layers of LVM](#the-3-layers-of-lvm)
- [Day 10 — Setting Up LVM From Scratch](#day-10--setting-up-lvm-from-scratch)
- [Day 11 — Extending a Logical Volume (Zero Downtime)](#day-11--extending-a-logical-volume-zero-downtime)
- [Quick Reference Card](#quick-reference-card)
- [Interview Questions](#interview-questions)
  
---

## Why LVM Exists

### The Problem with Normal Partitions

Imagine you set up `/data` with 10GB. Six months later developers fill it up completely. With normal partitions you are stuck:

- Add a new disk
- Create a new partition
- Format it
- Mount it
- Migrate ALL data to the new disk
- Cause downtime

That is painful, risky, and slow.

---

### The LVM Solution

LVM solves this completely. Think of it like two different storage systems:

**Normal partitions = fixed water tanks**

```
Tank A = 10GB    Tank B = 20GB    Tank C = 5GB
  ↑
  Full! Can't add more.
  Other tanks have space but you can't use it.
```

**LVM = swimming pool with flexible dividers**

```
┌─────────────────────────────────────┐
│         POOL (35GB total)           │  ← All disks combined
├──────────────┬──────────────────────┤
│   /data      │     Free space       │  ← Move the divider anytime
│   10GB       │     25GB             │
└──────────────┴──────────────────────┘
```

`/data` is full? Just push the divider. More space instantly. Zero downtime. Zero data loss.

---

## The 3 Layers of LVM

```
Physical Volume (PV)
        ↓        ← pvcreate
Volume Group (VG)
        ↓        ← vgcreate
Logical Volume (LV)
        ↓        ← lvcreate
Format + Mount + fstab
```

| Layer | Command | Real World Analogy |
|-------|---------|-------------------|
| Physical Volume (PV) | `pvcreate` | Water tank you pour into the pool |
| Volume Group (VG) | `vgcreate` | The swimming pool — all water combined |
| Logical Volume (LV) | `lvcreate` | Flexible dividers inside the pool |

### LVM vs Normal Partitions

| Situation | Normal Partition | LVM |
|-----------|-----------------|-----|
| Disk is full | Add disk, migrate data, downtime | Add disk to pool, extend LV, zero downtime |
| Need more space | Complex and risky | One command |
| Multiple disks | Separate, cannot combine | Combined into one pool |
| Resize volume | Not possible | Easy |

---

## Day 10 — Setting Up LVM From Scratch

### 🎯 Scenario
> Set up LVM on `/dev/sda`. Create a volume group called `datavg`. Create a logical volume called `datalv` using 5GB. Format it with XFS and mount it permanently at `/lvm-data`.

---

### Step 1 — Create Physical Volume

Tell LVM: *"I want to use this disk."*

```bash
sudo pvcreate /dev/sda
# Output: Physical volume "/dev/sda" successfully created.
```

> Note: You don't need fdisk first. With LVM you use the whole disk directly. No partitioning needed.

Verify:

```bash
sudo pvs
# PV         VG      Fmt   PSize    PFree
# /dev/sda           lvm2  10.00g   10.00g  ← not in any VG yet
# /dev/sdb3  cs      lvm2  18.00g       0   ← OS disk already in cs VG
```

---

### Step 2 — Create Volume Group

Create the pool and pour `/dev/sda` into it.

```bash
sudo vgcreate datavg /dev/sda
# Output: Volume group "datavg" successfully created
```

Verify:

```bash
sudo vgs
# VG      #PV  #LV   VSize    VFree
# cs        1    2   18.00g       0   ← OS pool, full
# datavg    1    0   10.00g  10.00g   ← our pool, empty and ready
```

Reading the output:

| Column | Meaning |
|--------|---------|
| `#PV` | How many physical disks in this pool |
| `#LV` | How many logical volumes created |
| `VSize` | Total pool size |
| `VFree` | How much space is still free in the pool |

---

### Step 3 — Create Logical Volume

Carve out a section from the pool.

```bash
sudo lvcreate -n datalv -L 5G datavg
# Output: Logical volume "datalv" created.
```

Flags explained:

| Flag | Meaning |
|------|---------|
| `-n datalv` | Name it datalv |
| `-L 5G` | Size = 5GB |
| `datavg` | Take space from this VG |

Verify:

```bash
sudo lvs
# LV      VG      LSize
# datalv  datavg  5.00g   ← 5GB carved out
# root    cs      16.00g  ← OS root LV for comparison
# swap    cs       2.00g  ← OS swap LV for comparison
```

Check lsblk:

```bash
lsblk
# sda
# └─datavg-datalv   5G   lvm   ← logical volume sitting on sda!
```

> The lsblk display shows `datavg-datalv` with a dash. But the real path is `/dev/datavg/datalv` with a forward slash. Always use the real path in commands.

---

### Step 4 — Format, Mount, fstab

Exactly the same as a normal partition. The LV is treated just like a disk partition from here.

```bash
# Format with XFS
sudo mkfs.xfs /dev/datavg/datalv

# Create mount point
sudo mkdir /lvm-data

# Mount temporarily
sudo mount /dev/datavg/datalv /lvm-data

# Verify
df -h
lsblk

# Get UUID for fstab
sudo blkid /dev/datavg/datalv

# Backup fstab ALWAYS
sudo cp /etc/fstab /etc/fstab.backup

# Add to fstab
sudo nano /etc/fstab
# UUID=xxxx /lvm-data xfs defaults 0 0

# Test without rebooting
sudo mount -a
sudo systemctl daemon-reload

# Reboot and verify
sudo reboot
lsblk
df -h
```

### ✅ Final Output After Reboot

```bash
lsblk
# sda
# └─datavg-datalv   5G   lvm   /lvm-data ✅

df -h
# /dev/mapper/datavg-datalv   5.0G   130M   4.9G   3%   /lvm-data ✅
```

---

### 🔮 What's Coming Next — Extending an LV

When `datalv` fills up extend it with zero downtime:

```bash
# Step 1 — Add new disk to the pool
sudo vgextend datavg /dev/sdc

# Step 2 — Extend the logical volume
sudo lvextend -L +10G /dev/datavg/datalv

# Step 3 — Grow the filesystem to use new space
sudo xfs_growfs /lvm-data
```

`/lvm-data` now has 10GB more. Users never notice. Zero downtime.

---

## Quick Reference Card

```bash
# Physical Volume commands
sudo pvcreate /dev/sda          # create PV
sudo pvs                        # list all PVs
sudo pvdisplay                  # detailed PV info

# Volume Group commands
sudo vgcreate datavg /dev/sda   # create VG
sudo vgs                        # list all VGs
sudo vgdisplay                  # detailed VG info
sudo vgextend datavg /dev/sdc   # add new disk to VG

# Logical Volume commands
sudo lvcreate -n datalv -L 5G datavg   # create LV
sudo lvs                               # list all LVs
sudo lvdisplay                         # detailed LV info
sudo lvextend -L +10G /dev/datavg/datalv  # extend LV

# After extending — grow filesystem
sudo xfs_growfs /lvm-data       # for XFS
sudo resize2fs /dev/datavg/datalv  # for EXT4

# Full status check
sudo pvs && sudo vgs && sudo lvs
lsblk
df -h
```

---

## Interview Questions

### Basic Level

**Q: What is LVM and why is it used?**
> LVM stands for Logical Volume Manager. It allows flexible disk management — resize volumes, add disks to a pool, and extend storage without downtime or data migration. Every production Linux server uses LVM.

**Q: What are the 3 layers of LVM?**
> Physical Volume (PV) — the actual disk. Volume Group (VG) — the pool that combines all PVs. Logical Volume (LV) — the flexible partition you format and mount.

**Q: What are the three LVM creation commands in order?**
> `pvcreate` → `vgcreate` → `lvcreate`. Always in this order.

**Q: What are the three LVM status commands?**
> `pvs` for physical volumes, `vgs` for volume groups, `lvs` for logical volumes.

**Q: Why don't you need fdisk before pvcreate?**
> With LVM you use the entire disk directly as a physical volume. No partitioning needed. The logical volume acts as the partition.

---

### Intermediate Level

**Q: What is the difference between a logical volume and a normal partition?**
> A normal partition is fixed to one disk and cannot be resized easily. A logical volume can span multiple disks, be extended without downtime, and resized with a single command.

**Q: What is the real path of a logical volume?**
> `/dev/vgname/lvname` — for example `/dev/datavg/datalv`. The lsblk display shows `datavg-datalv` with a dash but the actual path uses a forward slash.

**Q: What is the difference between vgextend and lvextend?**
> `vgextend` adds a new physical disk to the volume group pool. `lvextend` makes a logical volume bigger using space already available in the pool. When adding a new disk you need both — first extend the pool, then extend the volume.

**Q: After running lvextend, why do you need to run xfs_growfs?**
> `lvextend` makes the logical volume bigger at the block level. But the filesystem on top of it doesn't know about the new space yet. `xfs_growfs` tells the XFS filesystem to expand and use the new space.

---

### Scenario Based

**Q: /data is 95% full on a production server. Users cannot be interrupted. How do you add space?**
> 1. Add a new disk to the server
> 2. `sudo pvcreate /dev/sdc` — make it a PV
> 3. `sudo vgextend datavg /dev/sdc` — add to pool
> 4. `sudo lvextend -L +10G /dev/datavg/datalv` — extend the LV
> 5. `sudo xfs_growfs /data` — grow the filesystem
>
> Zero downtime. Users never notice.

**Q: You ran pvcreate and vgcreate but forgot to run lvcreate. What happens if you try to format the VG directly?**
> You cannot format a volume group directly. You must create a logical volume first. The VG is just a pool — you need an LV carved from it before you can put a filesystem on it.

**Q: A junior sysadmin ran lvextend but users say there is still no new space. What did they forget?**
> They forgot to grow the filesystem. `lvextend` only expands the block device. You must run `xfs_growfs /mountpoint` for XFS or `resize2fs /dev/vg/lv` for EXT4 to make the filesystem aware of the new space.

---


## Day 11 — Extending a Logical Volume (Zero Downtime)
 
### 🎯 Scenario
> `/lvm-data` is filling up. Extend it by 3GB using free space already in the pool. No downtime. Developers should not notice anything.
 
---
 
### 📖 Concepts
 
#### Two Things Need To Grow — Not Just One
 
```
lvextend    ← resizes the CONTAINER (the logical volume itself)
xfs_growfs  ← resizes the CONTENTS (the filesystem inside it)
```
 
Both steps are required. This is the #1 mistake junior sysadmins make — they run `lvextend`, check `df -h`, see no change, and panic thinking it failed.
 
#### Do You Always Need vgextend?
 
Not always! Check `vgs` first:
 
```
VG      VSize    VFree
datavg  10.00g   5.00g   ← 5GB already free in the pool!
```
 
If the pool already has free space, skip `vgextend` and go straight to `lvextend`. Only run `vgextend` when the POOL itself is full and you are adding a brand new disk.
 
```
Pool has free space?
  ├─ Yes → lvextend → xfs_growfs
  └─ No  → vgextend (add new disk) → lvextend → xfs_growfs
```
 
---
 
### 💻 Commands
 
```bash
# Step 1 — Check current status
sudo pvs
sudo vgs
sudo lvs
df -h
 
# Step 2 — Extend the logical volume (+3GB)
sudo lvextend -L +3G /dev/datavg/datalv
# Output: Size of logical volume datavg/datalv changed from 5.00 GiB to 8.00 GiB
 
# Step 3 — Check df -h (still shows OLD size!)
df -h
# /dev/mapper/datavg-datalv   5.0G   130M   4.9G   3%   /lvm-data
# ← filesystem doesn't know about new space yet
 
# Step 4 — Grow the filesystem (note: use MOUNT POINT, not device path)
sudo xfs_growfs /lvm-data
# Output: data blocks changed from 1310720 to 2097152
 
# Step 5 — Verify
df -h
# /dev/mapper/datavg-datalv   8.0G   189M   7.8G   3%   /lvm-data ✅
```
 
### ✅ Verification
 
```bash
sudo vgs
# VG      VSize    VFree
# datavg  10.00g   2.00g   ← was 5GB free, used 3GB, now 2GB free
```
 
Math check: `5.00g - 3G = 2.00g` ✅
 
---
 
### 🧠 The lvextend Flag Syntax
 
| Syntax | Meaning |
|--------|---------|
| `-L +3G` | Add 3GB to current size |
| `-L 8G` | Set absolute size to 8GB (not add) |
| `-l +100%FREE` | Use ALL remaining free space in the pool |
 
> `+` means "add this much". No `+` means "set to exactly this size".
 
---
 
### 🧠 Important — Command Targets Differ!
 
| Command | Points to |
|---------|-----------|
| `lvextend` | Device path → `/dev/datavg/datalv` |
| `xfs_growfs` | Mount point → `/lvm-data` |
 
Easy to mix up. `lvextend` works on the LVM layer (device). `xfs_growfs` works on the filesystem layer (mount point).
 
---
 
### Full LVM Lifecycle Summary
 
| Action | Command |
|--------|---------|
| Create PV | `pvcreate /dev/sda` |
| Create VG | `vgcreate datavg /dev/sda` |
| Create LV | `lvcreate -n datalv -L 5G datavg` |
| Add disk to pool (if pool is full) | `vgextend datavg /dev/sdc` |
| Extend LV | `lvextend -L +3G /dev/datavg/datalv` |
| Grow filesystem | `xfs_growfs /lvm-data` |
| Check everything | `pvs`, `vgs`, `lvs`, `df -h` |
 
---
 
## 🎤 Additional Interview Questions — Extending LVM
 
**Q: After lvextend, df -h still shows the old size. Is something wrong?**
> No, this is expected. `lvextend` resizes the logical volume at the block level, but the filesystem on top still thinks it's the old size. Run `xfs_growfs <mountpoint>` (XFS) or `resize2fs <device>` (EXT4) to make the filesystem aware of the new space.
 
**Q: Do you always need to run vgextend before lvextend?**
> No. Only if the volume group itself has no free space. Check `vgs` first — if `VFree` shows available space, you can extend the LV directly using that space without adding a new disk.
 
**Q: What is the difference between `-L +3G` and `-L 3G` in lvextend?**
> `-L +3G` adds 3GB to the current size. `-L 3G` (no plus sign) sets the absolute size to 3GB total — which could actually shrink the volume if it's currently bigger than 3GB. Always double-check for the `+`.
 
**Q: Why does xfs_growfs take a mount point instead of a device path?**
> XFS tools operate on the mounted filesystem, not the raw block device. You point `xfs_growfs` at where the filesystem is mounted (`/lvm-data`), while `lvextend` points at the LVM device path (`/dev/datavg/datalv`).
 
**Q: Can you shrink an XFS filesystem the same way?**
> No. XFS does NOT support shrinking — only growing. To "shrink" you'd need to back up data, recreate a smaller filesystem, and restore. This is one reason EXT4 is sometimes preferred when shrinking might be needed.
 
---

*Notes by Pujan | RHCSA Hands-On Self Challenge | Week 2 Part 2*
