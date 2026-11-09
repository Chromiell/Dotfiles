# Always-on Deepwork

This Orchestrator is dedicated to deepwork. Treat every session as if the user
had run `/deepwork <task>`.

- At the start of the session — before any research, planning, or delegation —
  load the `deepwork` skill with the `skill` tool and follow it for the whole
  session. Reload it after compaction.
- The user's first message is the deepwork Task. Do not ask whether this is a
  deepwork session, and do not fall back to ordinary single-model behavior.
- If the skill asks for a session-scoped state file, read the current session ID
  from the `OPENCODE_SESSION_ID` environment variable (for example with
  `printenv OPENCODE_SESSION_ID`). For the bundled workflow the router head is
  `.slim/deepwork/$OPENCODE_SESSION_ID.md`.
- Keep the deepwork state file current, use the planned Oracle gates, and finish
  with the skill's completion procedure.
