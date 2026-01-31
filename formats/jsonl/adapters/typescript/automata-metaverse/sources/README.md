Invariant: Authority-Projection
Semantic-Core: JSONL
Adapter: true
Capability: JSONL
Authority: automata-metaverse
Justification: ../ADAPTER-JUSTIFICATION.md
Inputs: (see adapter justification)
Outputs: (see adapter justification)
Trace: no
Halt-On-Violation: yes
# automata-metaverse

Automaton execution engines for self-referential CanvasL/JSONL systems with dimensional progression (0D-7D), Church encoding, and distributed causality tracking.

## Overview

`automata-metaverse` provides a complete suite of automaton execution engines for self-referential computational systems. It integrates with `meta-log-db` for CanvasL/JSONL parsing, ProLog/DataLog queries, and R5RS function execution.

## Installation

```bash
npm install automata-metaverse
```

## Quick Start

```typescript
import { AdvancedSelfReferencingAutomaton } from 'automata-metaverse';
import { MetaLogDb } from 'meta-log-db';
import { AUTOMATON_FILES } from 'automaton-evolutions';

const db = new MetaLogDb();
const automaton = new AdvancedSelfReferencingAutomaton(
  AUTOMATON_FILES.a0Unified,
  db
);

await automaton.init();
await automaton.executeSelfIO();
```

## Features

### Core Execution Engines

- **AdvancedSelfReferencingAutomaton**: Core automaton engine with self-modification capabilities
- **ContinuousAutomatonRunner**: Built-in intelligence automaton with continuous execution
- **OllamaAutomatonRunner**: AI-powered automaton using Ollama for decision-making
- **MemoryOptimizedAutomaton**: Memory-aware automaton with automatic trimming and GC
- **EvolvedAutomaton**: Extended automaton with evolution tracking
- **ScalableAutomaton**: Scalable automaton for large-scale operations
- **LearningAutomaton**: Learning automaton with pattern tracking
- **OptimizedBootstrap**: Optimized bootstrap process for automaton initialization

### Vector Clock Systems

- **VectorClock**: Distributed causality tracking using vector clocks
- **VectorClockAutomaton**: Base class for automata with vector clock state tracking
- **MLVectorClockAutomaton**: ML-enhanced vector clock automaton with semantic conflict resolution
- **Dimension Automata**: Dimensional automata (0D-7D) for topology operations

### Memory Management

- **ObjectPool**: Generic object pool for memory optimization
- **Memory Utilities**: Memory state monitoring, pressure assessment, and GC helpers

### Server Components

- **AutomatonController**: Server-side automaton controller with Socket.IO integration (optional)
- **Automaton Analysis**: Action frequency calculation and performance metrics

## Browser Support

The package includes a browser-compatible build:

```typescript
import { AdvancedSelfReferencingAutomaton } from 'automata-metaverse/browser';
import { CanvasLMetaverseBrowser } from 'meta-log-db/browser';

const browser = new CanvasLMetaverseBrowser();
const automaton = new AdvancedSelfReferencingAutomaton(
  AUTOMATON_FILES.a0Unified,
  browser
);
```

**Note**: Some engines use Node.js modules (`fs`, `path`, `http`) and will not work in the browser. Use `AdvancedSelfReferencingAutomaton` with `meta-log-db/browser` for full browser support.

## Documentation

- **GitHub Pages**: https://bthornemail.github.io/automata-metaverse/
- **API Reference**: https://bthornemail.github.io/automata-metaverse/api/
- **Examples**: https://bthornemail.github.io/automata-metaverse/examples/

## Dependencies

- **`meta-log-db`**: Required for CanvasL/JSONL parsing and R5RS function execution
- **`automaton-evolutions`**: Recommended for canonical automaton CanvasL files (A₀-A₁₁)

## Related Packages

- **[meta-log-db](https://www.npmjs.com/package/meta-log-db)**: Core database and logic programming engine
- **[automaton-evolutions](https://www.npmjs.com/package/automaton-evolutions)**: Canonical automaton CanvasL files (A₀-A₁₁)

## License

MIT
# automata-metaverse
