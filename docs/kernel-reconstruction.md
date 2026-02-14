# Kernel Reconstruction Doctrine

## Purpose

This system is being rebuilt from the kernel outward.

We are not integrating legacy projects as foundations.
We are harvesting them as research artifacts and rebuilding from invariants.

This is an intentional architectural stance.

---

## The Stance

We are not discarding prior work.
We are re-deriving the metaverse from a clean authority kernel.

Old projects become:

- reference implementations
- feature mines
- design libraries
- test vectors

But not the spine.

The spine is:

Authority kernel (Haskell invariant)
→ POSIX bus (FIFO/TCP transport)
→ World IR compiler
→ Projection portals

Everything else plugs in downstream.

---

## Why Rebuild Instead of Integrate

Legacy systems were built without:

- invariant-first authority gate
- lattice plan runtime
- deterministic projection discipline
- cockpit-grade introspection

Direct integration would import:

- authority leaks
- implicit state
- non-replayable behavior
- UI-driven truth
- inconsistent identity semantics

That would corrupt the kernel.

So we preserve the mathematics and discard accidental structure.

---

## Integration Philosophy

Not:

> integrate projects

But:

> extract capabilities

Each legacy project becomes:

capability candidate
→ rewritten as adapter
→ bound behind authority
→ compiled into world IR

Nothing gets privileged access.

All flows are:

Intent → Authority → Trace → Compile → Projection

---

## Rebuild Strategy

We are not starting from zero.
We are doing kernel-first reconstruction with archaeological reuse.

Current Status (Phase 3):

- Authority kernel: operational (invariants/authority/)
- World IR: defined (world-ir/SCHEMA.md)
- Runtime components: operational (runtime/)
- Test infrastructure: operational (golden/, scripts/)
- Pipeline execution: operational (pipelines/)

Phases:

1. **Capability Harvesting** ✅ COMPLETE
   - Document what is reusable
   - Identify violations of kernel rules
   - No code copy

2. **World IR Definition** ✅ COMPLETE
   - Canonical intermediate representation defined
   - Schema: world-ir/SCHEMA.md
   - Everything compiles to IR

3. **Adapter Reimplementation** 🔄 IN PROGRESS
   - Reimplement semantics, not code
   - Wrap behind invariant
   - Emit trace
   - Compile to IR

4. **Projection Layer** 🔄 IN PROGRESS
   - mind-git pipeline operational
   - Vault export available
   - Canvas rendering defined

---

## What Not To Do

- import engines wholesale
- merge repos for convenience
- copy runtimes as-is
- reuse UI state logic
- trust old authority assumptions
- let portals write truth

---

## What To Do

- ✅ harvest ideas
- ✅ formalize IR (world-ir/SCHEMA.md)
- ✅ enforce invariant first (AuthorityGate)
- 🔄 rebuild adapters cleanly
- ✅ treat portals as projections
- ✅ keep old projects as reference docs

---

## The Mental Shift

We are not building a game engine.

We are building a world operating system.

Engines are plugins.
Truth is kernel.
