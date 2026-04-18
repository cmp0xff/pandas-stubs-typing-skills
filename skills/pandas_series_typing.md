# Skill: Advanced Typing for Pandas-like Series

## Description
This skill provides patterns and guidelines for creating or maintaining high-fidelity typing stubs for Series-like objects, based on `pandas-stubs`. It covers complex overloads, generic specialization, and method chaining.

## Patterns

### 1. Constructor Overloading for Type Specialization
When a constructor takes a variety of data types (sequences, dictionaries, scalars), use overloads to specialize the return type.
- **Goal**: Map input `data` type to the generic type parameter of the Series.
- **Example**:
  ```python
  @overload
  def __new__(cls, data: Sequence[int], ...) -> Series[int]: ...
  @overload
  def __new__(cls, data: Sequence[Timestamp], ...) -> Series[Timestamp]: ...
  ```

### 2. Generic Type Aliases with Default Any
Use a `TypeVar` with a bound and a default (PEP 696) to allow both generic and non-generic usage.
- **Pattern**: `S1 = TypeVar("S1", bound=SeriesDType, default=Any)`
- **Benefit**: `Series` (shorthand for `Series[Any]`) works alongside `Series[int]`.

### 3. Specialized Type Aliases
Define central type aliases for common unions to ensure consistency across the codebase.
- `Scalar`: Union of native Python types, NumPy scalars, and custom types like `Timestamp`.
- `SeriesDType`: A broad alias for types that can be stored in a Series.
- `Dtype`: Handles both `ExtensionDtype` and NumPy dtypes.

### 4. Method Chaining with `Self`
Use `Self` (PEP 673) for methods that return a modified copy of the object.
- **Goal**: Ensure subclasses return their own type without re-declaring methods.
- **Example**:
  ```python
  from typing_extensions import Self
  def rename(self, index: IndexLabel = ..., ...) -> Self: ...
  ```

### 5. Interaction Overloads
Handle methods that change the object's dimensionality (e.g., `to_frame`) or interact with other core types (e.g., `Index`).
- `Series.to_frame()` -> `DataFrame`
- `Index.to_series()` -> `Series`

## Best Practices
- **Prioritize Overloads**: If a method's return type depends on an argument's type, always use `@overload`.
- **Use Internal Aliases**: Avoid repeating large `Union` types; use `_typing.pyi` to define them once.
- **Minimal Implementation**: Stubs should only contain signatures, no logic. Use `...` for bodies.
- **Inheritance**: Leverage mixins (e.g., `IndexOpsMixin`) for shared functionality between Series and Index.
