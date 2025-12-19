# Function Refactor Ledger

This document tracks every function found in both source repositories
(`dotbuntu` and `gitconfig`) during the refactor process.

No function may be implemented, modified, or removed unless it appears
in this ledger with an explicit decision.

---

## Legend

| Status | Meaning |
|------|--------|
| 🟢 MERGED | Unified implementation from multiple sources |
| 🔵 KEPT | Preserved as-is (no equivalent found) |
| 🟡 REWRITTEN | Logic preserved, implementation improved |
| 🟠 RENAMED | Same logic, renamed for clarity |
| 🔴 DELETED | Redundant or obsolete |
| ⚫ IGNORED | Intentionally excluded (with justification) |
| 🟣 DEFERRED | Decision postponed |

---

## Repositories

- **Repo A**: gitconfig
- **Repo B**: dotbuntu

---

## Global Notes

- All functions start as 🟣 **DEFERRED**
- Decisions must include a short rationale
- This ledger is updated incrementally
- This document is reviewed in every PR

---

---

## Helper: <module_name>

> Example: logger, colors, ui, validation, utils, prompts

| Function Name | Repository | Status | Final Name | Notes |
|--------------|------------|--------|------------|-------|
|              |            | 🟣 DEFERRED |            |       |
|              |            | 🟣 DEFERRED |            |       |
|              |            | 🟣 DEFERRED |            |       |

---

## Scripts: core/<script_name>

| Function Name | Repository | Status | Final Name | Notes |
|--------------|------------|--------|------------|-------|
|              |            | 🟣 DEFERRED |            |       |

---

## Scripts: extras/<script_name>

| Function Name | Repository | Status | Final Name | Notes |
|--------------|------------|--------|------------|-------|
|              |            | 🟣 DEFERRED |            |       |

---

## Scripts: setup/<script_name>

| Function Name | Repository | Status | Final Name | Notes |
|--------------|------------|--------|------------|-------|
|              |            | 🟣 DEFERRED |            |       |

---

## Scripts: verify/<script_name>

| Function Name | Repository | Status | Final Name | Notes |
|--------------|------------|--------|------------|-------|
|              |            | 🟣 DEFERRED |            |       |

---

## Deferred Decisions Log

| Function Name | Repository | Reason for Deferral | Follow-up Required |
|--------------|------------|---------------------|-------------------|
|              |            |                     |                   |

---

## Completed Summary

| Status | Count |
|------|------|
| 🟢 MERGED | 0 |
| 🔵 KEPT | 0 |
| 🟡 REWRITTEN | 0 |
| 🟠 RENAMED | 0 |
| 🔴 DELETED | 0 |
| ⚫ IGNORED | 0 |
| 🟣 DEFERRED | 0 |

---

## Final Notes

- All functions from both repositories must appear in this document
- No undocumented function may exist in the final codebase

