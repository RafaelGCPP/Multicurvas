
# Dispatch Table Optimization — Proposal

Status: draft

Context
-------
- Recent changes introduced a unary token (`TOKEN_NEG`) and refactored the evaluator loop. Measured benchmarks show an increase in interpreted overhead (historical ~8.9x → current ~9.5x after micro-optimizations).
- We explored a `switch`-based refactor and shrinking `Token` layout (to `uint8_t`) which yielded measurable improvements.

Goal
----
Document a non-intrusive, future optimization: replace the hot evaluation `switch`/chain-of-ifs with a dispatch-by-function-pointer table indexed by `token.type`.

Rationale
---------
- Reduce branch mispredictions in the evaluator hot loop.
- Provide per-token small handlers (push number, apply add, call sin, etc.) that operate on an explicit stack buffer.
- Keep source readable/educational: handlers are small, explicit functions. Advanced contributors can implement more aggressive low-level optimizations in a separate fork or branch.

High level design
-----------------
- A table `TokenHandler handlers[256]` is populated at init.
- `TokenHandler` signature (example):

```c
typedef EvalError (*TokenHandler)(double *stack, int *stack_top,
                                  const Token *token,
                                  const TokenBuffer *rpn,
                                  double var_value);
```

- Each handler manipulates `stack` and `stack_top` directly and returns an `EvalError`.
- The evaluator loop becomes: load token, lookup handler, call handler. Handlers for simple ops are short and branch-free.

Example handlers (sketch)
-------------------------

```c
static EvalError handle_number(double *stack, int *stack_top, const Token *token, const TokenBuffer *rpn, double var_value) {
    if (*stack_top >= MAX_EVAL_STACK_SIZE - 1) return EVAL_STACK_ERROR;
    stack[++(*stack_top)] = rpn->values[token->value_index];
    return EVAL_OK;
}

static EvalError handle_plus(double *stack, int *stack_top, const Token *token, const TokenBuffer *rpn, double var_value) {
    if (*stack_top < 1) return EVAL_STACK_ERROR;
    double b = stack[(*stack_top)--];
    double a = stack[(*stack_top)--];
    stack[++(*stack_top)] = a + b;
    return EVAL_OK;
}
```

Integration notes
-----------------
- Initialize `handlers` at program startup (or lazily) and register handlers for number, variables, constants, binary operators, unary `neg`, and functions.
- Keep `handlers` initialization readable and linked in `DOCUMENTATION.md` as an optional optimization.
- This approach introduces one indirect call per token; on modern CPUs a dense, hot table often produces stable predictions and lowers misprediction cost compared to many `if` checks.

Tradeoffs & Considerations
-------------------------
- Pros:
  - Lower branch misprediction in hot loop
  - Encapsulated handlers, clear specialization points
  - Easy to extend with new tokens
- Cons:
  - One more level of indirection (function pointer call) — may or may not be cheaper depending on CPU and code layout
  - Slightly more code to maintain (many small handlers)
  - Educational clarity vs. micro-optimized code: keep in a separate branch if heavy tuning is applied

Links
-----
- Main documentation: [DOCUMENTATION.md](DOCUMENTATION.md)
- Related benchmark artifacts: `build/benchmark` and `build/benchmark.test` in the repo.

Next steps (if we decide to implement)
-------------------------------------
1. Prototype handlers for the common hot tokens: `NUMBER`, `VARIABLE_*`, `CONST_*`, `+ - * / ^`, `NEG`, and `SIN/COS/EXP`.
2. Benchmark and compare against `switch`-based evaluator on target machine(s).
3. If faster, provide the dispatch variant behind a compile-time flag (e.g., `#define USE_DISPATCH`) and keep `switch` version for readability.

Notes
-----
- As requested, this stays as a documented possibility (educational). Your sibling can fork and implement the dispatch table in a performance-focused fork and submit a PR when ready.
