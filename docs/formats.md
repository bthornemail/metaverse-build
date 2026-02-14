# Data Formats

Format definitions for the metaverse kernel.

## Overview

Formats define how data is serialized and interpreted. These are extracted capabilities that need to be rebuilt behind the authority gate.

## CanvasL

Status: **extracted (frozen)**

- Authority: bicf-production
- Semantic Language: Scheme (R5RS)
- Adapter Languages: TypeScript, Scheme (R5RS)
- Sources: `sources/interpreter.scm`

## JSONL

Status: **extracted (frozen)**

- Authority: bicf-production
- Semantic Language: JSON
- Adapter Languages: TypeScript, Scheme (R5RS), JSONL

## Format Contract

- All formats must be parseable
- All formats must be deterministic
- No implicit defaults
- Authority is upstream of format parsing
