# PPL Memory Bug Reproduction

## Overview

This repository contains a minimal OCaml program that reproduces several memory management issues observed when using the Parma Polyhedra Library (PPL) through its OCaml bindings.

The problems manifest as:
- Segmentation faults  
- `Out_of_memory` exceptions

These issues appear when using iterator-based disjunct extraction and copying functions in the PPL OCaml interface.

---

## Affected API functions

The crashes and leaks are consistently reproducible when calling combinations of:

- `ppl_Pointset_Powerset_NNC_Polyhedron_get_disjunct`  
- `ppl_new_NNC_Polyhedron_from_NNC_Polyhedron`  
- `ppl_new_Pointset_Powerset_NNC_Polyhedron_from_Pointset_Powerset_NNC_Polyhedron`  
- `ppl_Pointset_Powerset_NNC_Polyhedron_add_disjunct`  
- Iterator management:
  - `ppl_Pointset_Powerset_NNC_Polyhedron_begin_iterator`
  - `ppl_Pointset_Powerset_NNC_Polyhedron_increment_iterator`
  - `ppl_Pointset_Powerset_NNC_Polyhedron_end_iterator`

---

## Observed results

| Test name           | Description                                           | Result / Failure type |
|----------------------|-------------------------------------------------------|-----------------------|
| `iterator-copy`      | Iterates and copies disjuncts using `new NNC from NNC`| Segfaults or OOM after ~3k iterations |
| `iterator-nocopy`    | Same as above, but uses disjuncts directly            | Appears stable |
| `copy`               | Copies base `NNC_Polyhedron` and powerset structures  | Appears stable |
| `orig-nocopy`        | Reproduction of IMITATOR’s union function             | Survives up to ~18M iterations before crash |
| `orig-copy`          | Same as above with copy                            | Segfaults after ~3k iterations |
| `orig-leak`          | Keeps disjunct references alive for a short while     | Fails after ~130k iterations |

---

## Build
This project uses dune and opam. These can be installed along with all other dependencies including PPL with by executing the script:

```bash
bash scripts/install-dependencies.sh
```

Proceed to run 
```bash
dune build
```
to build the binary. The binary will be in `_build/default/src/main.exe`.

### Rebuilding with modified PPL
The above script will also clone down PPL. You can modify the local PPL folder (to attempt bug-fixes) and then run the script 

```bash
bash scripts/install-ppl.sh
```
to reinstall PPL. Make sure to run 
```bash
dune build
``` 
again for the binary to use the modified version of PPL.

## Running the tests
Do
```bash
./_build/default/src/main.exe
```
to see usage options. 
