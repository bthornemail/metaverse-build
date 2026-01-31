# Capability: RPC
# Authority: opencode-obsidian-agent
# Justification: ../JUSTIFICATION.md
# Inputs: RPC requests
# Outputs: RPC responses
# Trace: no
# Opencode Obsidian Agentic Vaults

**Version:** 6.0 | **Status:** MVP Complete

This repository contains the implementation of the **Tetrahedral Shared Brain**, a production-grade environment for decentralized, collaborative coding and AI agents using Opencode and Obsidian.

See `TETRAHEDRAL_BRAIN_PLAN.md` for the full architectural specification.

---

## Architecture Overview

This project uses a `pnpm` workspace (monorepo) to manage several distinct packages:

-   `cli`: A command-line tool (`opencode-vault`) for creating, starting, and managing agent vaults.
-   `runtime`: A background Node.js process that runs on a per-vault basis. It handles file watching, `TetraNode` computation, and hosts a local RPC server for the plugin.
-   `plugin`: The Obsidian plugin that acts as the UI and controller, connecting to the local `runtime` for its vault.
-   `server`: A shared Opencode server wrapper (for future use).
-   `packages/core`: A shared library containing the core logic (`TetraNode`, types, etc.) used by all other packages.

## Setup

1.  **Install Dependencies**: This project uses `pnpm` as its package manager.
    ```bash
    pnpm install
    ```

2.  **Build the Project**: Build all the packages in the workspace.
    ```bash
    pnpm run build
    ```

## Getting Started: Workflow

Here is the standard workflow to create and run a new agent vault:

1.  **Create a Vault**: Use the new CLI to scaffold a new agent vault.
    ```bash
    ./cli/dist/index.js create my-first-agent
    ```
    This will create a new vault at `vaults/agents/my-first-agent`.

2.  **Start the Agent Runtime**: Launch the dedicated background process for your new vault.
    ```bash
    ./cli/dist/index.js start my-first-agent
    ```
    You can view the runtime's logs at `vaults/agents/my-first-agent/.agent.log`.

3.  **Open the Vault in Obsidian**: 
    -   Open Obsidian.
    -   Use the "Open another vault" command.
    -   Select "Open folder as vault" and choose the `vaults/agents/my-first-agent` directory.

4.  **Enable the Plugin**: 
    -   Go to `Settings` > `Community plugins`.
    -   Ensure "Restricted mode" is off.
    -   The `opencode-agent-plugin` should be present (as it was part of the template). Enable it.
    -   The plugin will automatically connect to the local `runtime`.

5.  **Test the System**: 
    -   Create a new folder inside your new vault called `notes`.
    -   Create a new note inside the `notes` folder (e.g., `test-node.md`).
    -   Add content to the note formatted with the four vertices (e.g., `# V1`, `# V2`, etc.).
    -   Save the file. Observe the `runtime` log file (`/.agent.log`) - it will automatically process the file and create a new `TetraNode` JSON representation in the `nodes/` directory.