# Skill: Advanced Typing Lessons from pandas-stubs PRs

## Description
This skill captures specialized workarounds and advanced patterns identified from historical PRs in the `pandas-stubs` repository, particularly for resolving variance issues and improving literal-based type safety.

## Lessons & Patterns

### 1. Resolving Contravariance in Callables
When using `Callable` in a `Mapping` (e.g., formatters), avoid unions in the key type if it causes variance rejection.
- **Problem**: `Mapping[str | int, Callable[[str | int], Any]]` might reject `dict[str, Callable[[str], Any]]` because the callable argument is contravariant.
- **Solution**: Split the mapping into a union of mappings with narrower key types.
- **Pattern**:
  ```python
  FormattersType: TypeAlias = (
      Mapping[str, Callable[..., Any]]
      | Mapping[int, Callable[..., Any]]
  )
  ```

### 2. Replacing Generic Strings with Literal Kernels
For methods like `agg`, `transform`, and `rolling`, replace `str` with a `Literal` union of valid pandas operation names (kernels).
- **Benefit**: Catch typos like `agg("summm")` at type-check time.
- **Pattern**: 
  ```python
  ReductionKernelType: TypeAlias = Literal["sum", "mean", "min", "max", ...]
  ```

### 3. Explicit Annotations for Dict Inference
Mypy and Pyright often infer `dict[object, object]` for complex dictionaries used in `agg`. Provide explicit annotations using centralized TypeAliases.
- **Pattern**: `agg_dict: dict[str, TransformReductionListType] = {"col": "sum"}`

### 4. Variance Issues with `NDFrame` Methods
Be careful with variance when return types or argument types involve generic parameters of `NDFrame`. Use `@overload` to bypass variance issues in complex methods like `to_latex` or `to_json`.

### 5. Managing Deprecations
Use specialized markers or comments (`# pyright: ignore`) when stubs need to maintain compatibility with multiple pandas versions or when transitioning between internal "NoDefault" markers.

### 6. Overload Order for `Any` and `Unknown`
Overload order is critical when dealing with `Series[Any]` or `Series[Unknown]`.
- **Problem**: When a generic type is used with `Any`, multiple overloads might apply, leading to ambiguous results.
- **Solution**: Carefully order overloads so that more specific types are checked first. Add tests that specifically use `Any` to verify which overload is selected.

### 7. No `# type: ignore` in Tests
Basic rule: Do not put `ignore` in tests unless specifically testing that the stubs should *not* accept something invalid.
- **Benefit**: Ensures that the stubs are robust and that we don't accidentally hide bugs in the type-checking logic.
- **Exceptions**: Only use when testing invalid input or when a confirmed bug in a specific type checker version must be documented.

### 8. Progressive Typing Philosophy
Move from a "Casting" approach to a "Progressive" approach for ambiguous operations.
- **Casting Approach (Old)**: Return `Never` for ambiguous operations (like `Series[Any] + Series[str]`) to force users to cast.
- **Progressive Approach (New)**: Infer the only valid resulting type if the operation is known to work at runtime (e.g., `Series[Any] - Series[Timestamp] -> Series[Timedelta]`).
- **Goal**: Improve user experience while maintaining type safety by providing the most likely correct type.

### 9. Handling Type Checker Discrepancies (`mypy` vs. `pyright`)
`mypy` and `pyright` can have different opinions on how to handle overloads with `Any`.
- **Issue**: `mypy` might return `Any` if multiple overloads are ambiguous due to `Any` being a subtype of everything. `pyright` might return `Unknown` or select the first matching overload differently.
- **Resolution**: Use `assert_type()` in tests to document and verify behavior for both type checkers. If they diverge, consider the "Progressive approach" to find a common ground.

### 10. Managing Major Version Transitions (pandas 3.0/3.1)
When pandas moves towards a major version (like 3.0), the stubs must balance between removing deprecated features and supporting the current stable release.
- **Strategy**: Don't deprecate too early if a feature is still valid in minor versions. For nightly fixes (aiming at 3.1), keep the stubs until the actual release confirms the removal.
- **Cleanup**: Once a major version arrives, clean up objects that produce warnings or have been removed in the `pandas.nightly` builds.

### 11. Exception Hierarchy Changes
Be aware of changes in the exception hierarchy between pandas versions.
- **Example**: `IncompatibleFrequency` changed from subclassing `ValueError` to `TypeError` in pandas 3.0. This affects how users might catch errors and how joins behave (casting to object vs raising).

### 12. Refining Mapping Keys with Generic Hashables
When typing parameters that accept mappings (like `dtype` in `read_*` functions), use specialized hashable type variables to avoid issues with `Any`.
- **Problem**: `Mapping[Hashable, DtypeArg]` is often too broad or causes issues with specialized dictionaries.
- **Solution**: Use `HashableT0`, `HashableT1`, etc., to allow the type checker to track the specific key types more effectively.
- **Pattern**: `Mapping[HashableT0, DtypeArg]` instead of a generic `Mapping`.

### 13. Alternating Argument Patterns (The `set_option` Pattern)
For functions that accept an alternating sequence of arguments (e.g., `key1, val1, key2, val2`), use multiple overloads to provide type safety for common cases.
- **Pattern**:
  ```python
  @overload
  def set_option(pat0: str, val0: object) -> None: ...
  @overload
  def set_option(pat0: str, val0: object, pat1: str, val1: object) -> None: ...
  # Continue up to a reasonable limit (e.g., 5 pairs)
  ```
- **Fallback**: Include a final overload with `*args: Any` to handle cases beyond the explicit overloads.

### 14. Pyrefly Suppression Best Practices
`pyrefly` is used alongside `mypy` and `pyright`, but its suppressions should be handled surgically.
- **Rule**: Avoid `# pyrefly: ignore-errors` at the top of files unless the file has an overwhelming number of false positives (e.g., >20) that cannot be easily fixed.
- **Preference**: Use inline `# pyrefly: ignore[<code>]` for specific lines. Only use file-wide ignores for tests designed to check invalid usage (`TYPE_CHECKING_INVALID_USAGE`).
- **Debugging Tip**: If `pyrefly` fails to find a file or reports strange errors, check for naming conventions (e.g., trailing underscores in filenames like `test_numpy_.py` vs `test_numpy.py`).

### 15. Factoring Internal Type Aliases
To improve readability and remove redundancy in complex stubs, factor out common components of large unions into intermediate aliases.
- **Example**: Creating `ColumnValue` as an intermediate type for `IntoColumn`.
- **Note**: These internal aliases don't necessarily need to be public, but they help maintain the stubs.

### 16. Transition to `NoDefault`
Transition from the internal `NoDefaultDoNotUse` to the newly exposed `pandas.api.typing.NoDefault` where appropriate for 3.0+.
- **Pattern**: Replace `from pandas._libs.lib import NoDefaultDoNotUse` with `from pandas.api.typing import NoDefault`.

### 17. Use of `pandas.api.typing.aliases`
With pandas 3.0+, prefer importing public-facing type aliases from `pandas.api.typing` rather than the internal `pandas._typing` module.
- **Goal**: Align with pandas' goal of providing a stable public typing API.
- **Examples**: `IntervalClosedType`, `ListLike`, `ScalarIndexer`.

### 18. Mandatory `assert_type()` in Tests
Always use `assert_type()` in test files to verify that the stubs are returning the expected types, especially for complex overloads.
- **Rule**: A PR is not complete without tests that explicitly check return types using `assert_type()`.

### 19. Version-Specific Warning Management (`pytest_warns_bounded`)
When managing warnings that vary by pandas version, ensure the bounds are correctly set.
- **Rule**: When moving to a new major version (e.g., 3.0), remove "expired" `pytest_warns_bounded` (where the upper bound is less than the current version).
- **Tip**: Lower bounds for 3.x specific warnings should be at least `3.0`.

### 20. Handling Optional Dependencies in Stubs
Some objects (like `ExcelWriter`) might appear as `Unknown` if optional runtime dependencies (like `xlsxwriter` or `odfpy`) are missing during type checking with strict mode.
- **Resolution**: Advise users to install these optional packages or handle the `Unknown` type if they use strict type checking.

## Best Practices
- **Centralize Aliases**: Move complex unions and literal lists to `_typing.pyi` or specialized `base.pyi` files within modules.
- **Test Variance**: Add tests that specifically use specialized types (e.g., `dict[str, Callable]`) to ensure the stubs don't accidentally reject them due to variance.
- **Literal Dispatch**: Always prefer `Literal` over `str` when the set of valid strings is known and finite.
- **Local CI Validation**: Always run `poetry run poe test_all` (which includes formatting) or `pre-commit run --all-files` locally before pushing. This ensures that the CI doesn't fail on basic linting/formatting issues.
- **Incremental PRs**: Break down large migrations (like pandas 3.0) into smaller, thematic PRs (e.g., "Deprecations Part 1", "Plotting Fixes") for easier review.
- **Avoid Nuclear Changes**: Prefer incremental additions (e.g., adding `| None` to specific method parameters) over broad changes to core aliases like `Scalar`, as the latter can have unpredictable effects across the codebase.
- **Standardize Deprecation naming**: Use `PD_LTE_30` (or similar) consistently in `tests/__init__.py` for version-based test filtering.
