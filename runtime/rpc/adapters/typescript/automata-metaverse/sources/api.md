Invariant: Authority-Projection
Semantic-Core: RPC
Adapter: true
Capability: RPC
Authority: automata-metaverse
Justification: ../ADAPTER-JUSTIFICATION.md
Inputs: (see adapter justification)
Outputs: (see adapter justification)
Trace: no
Halt-On-Violation: yes
---
layout: default
title: API Reference
permalink: /automata-metaverse/api/
---

# API Reference

Complete TypeScript API reference for `automata-metaverse`.

## Core Execution Engines

### AdvancedSelfReferencingAutomaton

Core automaton engine with self-modification capabilities.

```typescript
import { AdvancedSelfReferencingAutomaton } from 'automata-metaverse';
import { MetaLogDb } from 'meta-log-db';

const db = new MetaLogDb();
const automaton = new AdvancedSelfReferencingAutomaton('./automaton.jsonl', db);

await automaton.init();
await automaton.executeSelfIO();
```

**Methods**:
- `init()`: Initialize and load the automaton file
- `executeSelfIO()`: Execute self-modification operations
- `executeAction(action: string)`: Execute a specific action
- `save()`: Save current state to file

### ContinuousAutomatonRunner

Built-in intelligence automaton with continuous execution.

```typescript
import { ContinuousAutomatonRunner } from 'automata-metaverse';

const runner = new ContinuousAutomatonRunner('./automaton.jsonl', false, 'llama3.2');
await runner.startContinuous(2000, 100); // 2s interval, 100 iterations max
```

### MemoryOptimizedAutomaton

Memory-aware automaton with automatic trimming and GC.

```typescript
import { MemoryOptimizedAutomaton } from 'automata-metaverse';

const automaton = new MemoryOptimizedAutomaton('./automaton.jsonl', {
  maxObjects: 2000,
  gcInterval: 5000,
  enableGC: true
});
```

## Vector Clock Systems

### VectorClock

Distributed causality tracking using vector clocks.

```typescript
import { VectorClock } from 'automata-metaverse';

const clock = new VectorClock('node1');
clock.tick();
clock.update('node2', 5);
const happenedBefore = clock.happenedBefore(otherClock);
```

### VectorClockAutomaton

Base class for automata with vector clock state tracking.

```typescript
import { VectorClockAutomaton } from 'automata-metaverse';

class MyAutomaton extends VectorClockAutomaton {
  // Implement automaton logic
}
```

## Memory Management

### ObjectPool

Generic object pool for memory optimization.

```typescript
import { ObjectPool } from 'automata-metaverse';

const pool = new ObjectPool(
  () => ({ id: '', data: {} }),
  (obj) => { obj.id = ''; obj.data = {}; },
  100 // max size
);

const obj = pool.acquire();
// Use obj...
pool.release(obj);
```

### Memory Utilities

```typescript
import { 
  getMemoryState, 
  assessMemoryPressure, 
  formatMemory 
} from 'automata-metaverse';

const state = getMemoryState();
const pressure = assessMemoryPressure(state);
console.log(formatMemory(state.heapUsed));
```

## Server Components

### AutomatonController

Server-side automaton controller with Socket.IO integration.

```typescript
import { AutomatonController } from 'automata-metaverse/server';
import { Server } from 'socket.io';

const io = new Server();
const controller = new AutomatonController({
  automaton: myAutomaton,
  io
});

controller.start(2000, 100);
```

## Browser Support

### Browser Entry Point

```typescript
import { 
  AdvancedSelfReferencingAutomaton,
  VectorClock,
  ObjectPool
} from 'automata-metaverse/browser';
```

**Note**: Browser build excludes Node.js-specific engines and features.

## Type Exports

```typescript
import type { 
  AutomatonState,
  Transition,
  VerticalTransition,
  CanvasObject
} from 'automata-metaverse';
```
