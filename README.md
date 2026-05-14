# Avalon Nine

> A perhaps foolish attempt at a new kind of operating system.

Avalon Nine (A-9) is a hobby microkernel and operating system targeting RISC-V, written in Rust, built on a set of first
principles that depart significantly from the Unix tradition.

---

## Philosophy

A-9 tries to prove out several ideas:

- Workloads are the security boundary, not a user role or a file, not even the process.
- Workloads are isolated by default.
- Local privilege escalation should be architecturally meaningless. There is no hierarchy of privileges to escalate through.
- Authentication is a cryptographic proof, not merely a secret. Passwords suck and server oriented workloads don't really need them.

### Traditional multi-user based permission models holds computing back

`uid`/`gid`/`rwx` was designed for a world of shared terminals and local users. It describes almost no real workload 
in 2026. The actual threats — lateral movement, privilege escalation, confused deputy attacks — are not addressed by 
file permission bits. A-9 does not attempt to improve this model, it just discards it and starts over.

### The workload is the security boundary

In Unix, the user is the security boundary. In A-9, the workload, or 'session' is. A workload is instantiated with a signed capability 
set that defines exactly what it can touch. Nothing bleeds between workloads by default. There is no ambient authority.

### Privilege escalation should be architecturally meaningless

Local privilege escalation presupposes there is a higher privilege level reachable from a lower one. A-9's design goal 
is a system where that concept does not apply, not because LPE is mathematically prevented (seL4's approach), but 
because there is no local privilege hierarchy to escalate through.

When a workload needs elevated capability, it does not escalate, it just ends its session (lets call it `gary`)
, a new session (`gina`) starts with a different signed context. State is persisted by `gary` and read by `gina`,
but `gina` can opt in to writing back such that `gary` sees state changes, or not.

### Single user mode or bust

A-9 is designed to have as few "local" human users as practical without sacrificing the ability to directly maintain the
server. The traditional multi-user model is replaced by a single console user, and a session model: a session arrives, 
is granted a capability set, does its work, and ends. 

This challenges the idea that you need a separate "workstation" operating system and a "server" operating system in the 
opposite direction that modern Linux does. Servers should not be multi-role, instead they should encourage single use,
much like a container enforces this via process isolation. In some ways containers are the proof that Linux and its
multi-user architecture is an anti-pattern.

### No passwords, ever

Passwords are phishable, reusable, and require the server to store (or memorize) a representation of a secret. They're
also the focus of hackers who steal and hoard them over time in the hopes that people would re-use them. A-9's 
philosophy here is that passwords are a root cause that should be minimized if not entirely eliminated from the
operating system altogether.

To accomodate this the following installation and user experience is part of the design goals for this project:
1. Sysadmin uses a different system to generate a keypair offline, on hardware you trust. If you do not have that, A-9 will produce this keypair for you but drop the private key at installation time. The adminstrator will need to keep that for recovery purposes. In the ideal case, A-9 never sees the private key.
2. Only the public key is used during installation to become the root of trust.
3. Signing operations happen on the users FIDO2 compatible device
4. The OS validates signatures against the public key it was installed with

In practice most system administrators would use Yubikey to both generate the key pair, and bring this to the installation 
process, register its public key with A-9 and from that point any authentication operations require physical possession of 
the key.

This means there can never be any shared trust anchor across machines, making lateral movement much harder should A-9
machines be networked.

### Microkernel — security over performance

The kernel does as little as possible:

- Physical memory management
- Scheduling
- IPC
- Capability enforcement
- Exception and interrupt dispatch

Everything else — storage, display, input, networking, filesystem — is a userspace driver. A buggy driver crashes a 
process. It does not crash the kernel. It does not compromise other workloads.

I realize this comes at a performance cost, but high performance is explicitly not a design goal.

### Q&A

### 'Does everything run as root then?'

Not at all, there is no real concept of root. Yes there is an administrative user (lets call them `adm`) who is authorized
to allow a web service the ability to access parts of the file system, but the web service runs under a context dedicated
entirely to it, and it alone.

### 'Right so can I remotely interact via a shell to maintain A-9?'

Hypothetically, yes, that's just an SSH session that has been configured with specific capabilities, including network
access via port 22. If the administrator chooses to configure that session with every capability it would be as powerful
as a root user session over SSH.

### 'But how does a team of people maintain A-9 then?'

A-9 doesn't preclude multiple people from remotely accessing it, however, only a single person may physically access the
system at a given time. Multiple console TTYs for the `adm` user are possible, but two users physically logging into A-9
is intended to be impossible.

### 'Why the name Avalon Nine? It sounds like a bad sci-fi?'

Thanks, partly intentional! The first name 'Avalon' is actually inspired by the isle of Avalon from Arthurian
legend, as synthesised in Malory's _Le Morte d'Arthur_. The 'Nine' is a tip of the hat to the makers of Plan-9 for thinking
outside the box. Other influences on my design decisions are, [QubesOS](https://en.wikipedia.org/wiki/Qubes_OS) (Joanna Rutkowska), for treating isolation as a first class citizen, and 
[TempleOS](https://en.wikipedia.org/wiki/TempleOS) (Terry Davis) for having the audacity to build a whole world from nothing.

---

## Influences

- **Plan 9** — everything is a file server, private namespaces per process, composition over monoliths
- **seL4** — capability-based security, minimal trusted computing base
- **QubesOS** — isolation as a primary primitive, not an afterthought
- **TempleOS** — the audacity of building your own world from scratch


---

## Target

- **Architecture:** RISC-V (riscv64gc)
- **Primary dev target:** QEMU virt machine
- **Hardware target:** StarFive VisionFive 2 (JH7110 SoC)
- **Boot stack:** OpenSBI (M-mode) → U-Boot (S-mode) → kernel
- **Language:** Rust (no_std, no_main, freestanding)

---

## v0.1 Goals

A proof of concept:

1. Kernel boots in QEMU and on VisionFive 2 hardware, prints to serial via SBI
2. A fixed storage region (not a filesystem) holds a single Ed25519 public key written at install time
3. Boot requires presence of that key to proceed — password string placeholder, YubiKey deferred to v0.2
4. A minimal shell (esh) accepts keyboard input via serial and recognises two commands: shutdown and keygen
5. keygen generates a keypair, outputs the private key to stdout once and never stores it, writes the public key to the fixed storage region
6. No passwords ever stored — the placeholder is a temporary compile-time gate, not a credential

What this defers explicitly to later versions:

- Real YubiKey/FIDO2 authentication (needs USB stack)
- `afs` filesystem (needs a proper storage driver)
- Networking of any kind
- Capability model enforcement
- Multiple sessions

---

## Longer Term Roadmap

- [ ] Kernel boots in QEMU, prints to serial via SBI
- [ ] DTB parsing — discover memory map and UART from hardware
- [ ] Trap and interrupt handling
- [ ] Physical memory allocator
- [ ] Virtual memory (sv39 page tables)
- [ ] IPC primitives
- [ ] Userspace and capability model foundations
- [ ] Authentication subsystem (password placeholder → YubiKey)
- [ ] Output recovery phrase to stdout
- [ ] afs - filesystem implementation for persistence (borrow heavily ZFS)
- [ ] esh - Excalibur Shell
- [ ] ans - network stack
---

## Building

```bash
cargo build -Zjson-target-spec -Zbuild-std=core
```

QEMU setup and hardware flashing instructions to follow once the kernel has something worth booting.

---

*"Avalon, access granted not assumed."*