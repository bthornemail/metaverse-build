# Metaverse Build Runtime

This repository is the executable extraction of the metaverse runtime.

It is not a feature repo.
It is a **capability kernel**.

Everything here exists to enforce:

Identity → Authority → Trace → Projection

Adapters and projections are downstream.
Authority is upstream.

---

## Operator Entry Point

👉 See the cockpit:

[[START.canvas]]

The vault snapshot is the human interface.
The runtime is the machine interface.

---

## Core Principles

1. Authority is enforced before emission.
2. HALT produces zero downstream bytes.
3. All adapters are projections.
4. Plans are content-addressed.
5. History is diffable.
6. Navigation is closed-loop (no dead ends).
7. Projection artifacts are disposable.

---


## Kernel Reconstruction Doctrine

See: `docs/kernel-reconstruction.md`

## Build Switchboard

See:

`BUILD-MAP.md`

This file defines:

- authority repo per capability
- semantic language
- invariant language
- adapter languages
- extraction status

It is the canonical capability ledger.

---

## Runtime Architecture

```

Trace
→ Authority Gate (Haskell invariant)
→ POSIX Bus (FIFO/TCP)
→ Adapters
→ Projection
→ Vault export

```

Lattice discovery selects the bus.
Plans are rebindable.
Routing is diffable.
History is indexable.

---

## Invariant

Executable invariant:

```

invariants/authority/AuthorityProjection.hs

```

This module defines the gate:

```

validateAuthority :: Identity -> Trace -> Either Halt ValidTrace

```

If Left → no emission.
Ever.

Adapters cannot bypass this.

---

## POSIX Bus

Mode-aware transport:

- FIFO
- TCP

Selected via:

```

bus.env

```

Derived from lattice connection plan.

No MQTT.
No brokers.
Native pipes and sockets only.

---

## Lattice Runtime

The lattice system provides:

- peer discovery
- basis routing
- live rebind
- plan hashing
- structural diffs

Artifacts:

```

runtime/lattice/

```

Plans are snapshots.
Snapshots are content-addressed.
Diffs are deterministic.

---

## Projection Layer

mind-git projection pipeline:

```

projections/mind-git/

```

Outputs:

- canvases
- reports
- transcripts
- plan history

All ignored by git.
Non-authoritative.

They are views, not truth.

---

## Vault Export

Run:

```

export-vault.sh

```

Produces:

```

dev-vault/metaverse/

```

This is the operator cockpit.

Safe to delete.
Rebuildable at any time.

---

## Safety Contract

If a capability violates its contract:

→ HALT  
→ zero bytes emitted  
→ downstream unchanged  

This is the primary invariant of the system.

---

## Status

Runtime kernel: operational  
Authority gate: enforced  
Plan system: diffable  
Projection pipeline: deterministic  
Vault cockpit: navigable  

System is in stable exploratory state.
