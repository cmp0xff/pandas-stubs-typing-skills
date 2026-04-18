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

## Best Practices
- **Centralize Aliases**: Move complex unions and literal lists to `_typing.pyi` or specialized `base.pyi` files within modules.
- **Test Variance**: Add tests that specifically use specialized types (e.g., `dict[str, Callable]`) to ensure the stubs don't accidentally reject them due to variance.
- **Literal Dispatch**: Always prefer `Literal` over `str` when the set of valid strings is known and finite.
