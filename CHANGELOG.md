# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [Unreleased]

## [0.14.13] - 2026-04-10
### Fixed
- Fixed a `BslashCompletion` API incompatibility with Julia 1.12 ([#604]).

## [0.14.12] - 2026-01-29
### Added
- Added the `JULIA_RCALL_USE_CONDA` environment variable to control whether R is installed via Conda, which is now also used automatically when PkgEval is detected ([#598]).

### Changed
- Dropped support for R versions older than 4.0 ([#600]).

## [0.14.11] - 2026-01-07
### Fixed
- Fixed initialization on Julia 1.13 after a REPL function it relied on was removed ([#591]).

## [0.13.14] - 2026-01-07
No functional changes. This tag re-publishes a commit already released as part of [0.13.15] and later versions; see that entry for the corresponding changes.

## [0.14.10] - 2025-11-12
### Changed
- Changed the internal `SxpPtrInfo` representation to use `UInt64` ([#588]).
- Raised the minimum supported `DataStructures` version to 0.19 ([#575]).

## [0.14.9] - 2025-07-31
### Changed
- Raised the minimum supported `CategoricalArrays` version to 1 ([#574]).

## [0.14.8] - 2025-04-22
### Fixed
- Improved macro hygiene of `@rimport` ([#571]).

## [0.14.7] - 2025-04-17
### Changed
- Moved `AxisArrays` support into a package extension and dropped the `Requires` dependency ([#567]).
- Removed the custom `RException` `showerror` method, so full backtraces are now shown on errors ([#560]).
- Switched to the public `Rf_defineVar` API instead of the internal `SET_SYMVALUE`.

### Fixed
- Fixed `unsafe_vec` on R 4.5.

## [0.14.6] - 2024-09-09
### Added
- Added a deprecated `jtypExtPtrs` alias for backwards compatibility ([#549]).

## [0.14.5] - 2024-09-09
### Fixed
- Fixed an R REPL issue on Julia nightly ([#541]).
- Made indexing into `AbstractArray` safer ([#540]).

## [0.14.4] - 2024-07-18
### Added
- Added support for inline comments in the R REPL mode ([#537]).

## [0.14.3] - 2024-07-18
### Added
- Added conversion support, with possible precision loss, for arbitrary-precision `POSIXct` objects ([#533]).

## [0.14.2] - 2024-07-17
### Changed
- Raised the minimum supported Julia version ([#530]).

### Fixed
- Fixed Unicode-normalization collisions when re-importing R symbols ([#532]).

## [0.14.1] - 2024-01-30
### Added
- Added support for specifying `Rhome`/`libR` via `Preferences.jl` ([#496]).

## [0.14.0] - 2024-01-08
### Added
- Added support for converting Julia tuples to/from R, and improved round-tripping of named tuples ([#515]).

## [0.13.18] - 2023-09-26
### Fixed
- Fixed `complete_line` for the R REPL mode's tab completion on newer Julia ([#502]).

## [0.13.17] - 2023-08-30
### Added
- Added support for installing R 4 via Conda ([#498]).

## [0.13.16] - 2023-08-10
### Fixed
- Fixed conversion from R datetime objects to a character representation ([#495]).

## [0.13.15] - 2023-04-14
### Added
- Added bounds checking when indexing R lists ([#443]).

### Changed
- Updated `Project.toml` ([#463]).

## [0.13.13] - 2022-02-05
### Changed
- Removed use of C function closures for improved Julia compatibility ([#441]).
- Updated `methods.jl` ([#426]).

## [0.13.12] - 2021-07-05
### Changed
- Raised the minimum supported `CategoricalArrays` version to 0.10 ([#413]).

## [0.13.11] - 2021-04-22
### Changed
- Raised the minimum supported `DataFrames` version to 1.0 ([#411]).
- Raised the minimum supported `Missings` version to 1.0 ([#410]).

## [0.13.10] - 2020-11-18
### Changed
- Added support for `DataFrames` 0.22 and `CategoricalArrays` 0.9 ([#399]).

## [0.13.9] - 2020-09-28
### Fixed
- Fixed an incorrect function call ([#395]).

## [0.13.8] - 2020-09-28
### Added
- Added conversion support for data-frame columns that are entirely `missing` ([#387]).

### Fixed
- Fixed R home detection to use the detected `Rhome` ([#382]).
- Fixed and tested the Conda-provided R installation ([#390]).
- Removed a duplicate `sexpclass(::Missing)` method definition ([#392]).

## [0.13.7] - 2020-05-06
### Added
- Added conversion support for `Date`/`DateTime` `SubArray`s ([#337]).

### Changed
- Updated for compatibility with `CategoricalArrays` 0.8 ([#362]).

### Fixed
- Fixed code to use `first`/`last` for better compatibility ([#377]).

## [0.13.6] - 2020-05-03
### Changed
- R is now initialized with the `--no-restore` flag ([#329]).

### Fixed
- Fixed a Unicode-related issue on Windows.
- Fixed an issue affecting 32-bit Windows ([#364]).
- Worked around an `Rf_initialize_R` issue on Windows ([#372]).

## [0.13.5] - 2020-03-07
### Fixed
- Fixed ordering of factor levels when converting `CategoricalArray` ([#338]).
- Improved conversion of `CategoricalArray` (including ordered factors) to R factors ([#332], [#350]).
- Added handling for R installations with distribution-related failures ([#352]).
- R home is now also searched for in `HKEY_CURRENT_USER` on Windows ([#357]).

## [0.13.4] - 2019-08-21
### Changed
- Updated formula copying for `StatsModels` v0.6.0 ([#317]).
- Adapted to the new column-selection syntax in `DataFrames` ([#327]).

## [0.13.3] - 2019-06-22
### Changed
- Added a `Project.toml` file, adopting the standard Julia package manifest format ([#310]).

### Fixed
- Fixed an `AxisArrays` reference to be properly qualified ([#301]).
- Restored an informational message about differing values ([#309]).

## [0.13.2] - 2019-02-24
### Changed
- Errors from R are now returned as a `simpleError` instead of calling `Rf_error` directly ([#296]).

### Fixed
- Fixed error checking to distinguish between Conda-provided R and a user-provided R installation ([#299]).

## [0.13.1] - 2019-02-01
### Added
- Added support for converting R data frames containing matrix columns ([#291]).

### Fixed
- Fixed printing of empty `RObject`s ([#288]).
- Fixed C stack-checking issues on Julia 1.1 ([#293]).
- Fixed an issue with reference handling ([#285]).

## [0.13.0] - 2018-11-09
### Changed
- `AxisArrays` is no longer a hard dependency ([#266]).
- Dropped support for Julia 0.7; Julia 1.0+ is now required ([#279]).
- Sanitized symbols imported from R packages ([#275]).

### Fixed
- Fixed R home detection on Windows.
- Fixed the R REPL mode ([#271]).
- Avoided using the internal `jl_value_ptr` ([#267]).

## [0.12.1] - 2018-08-17
### Fixed
- Fixed `AxisArray` deprecation warnings ([#262]).
- Fixed IJulia integration issues ([#263]).

## [0.12.0] - 2018-08-14
### Changed
- Confirmed and finalized Julia 1.0 support ([#260]).

### Fixed
- Fixed a missing default conversion rule for S4 objects ([#259]).

## [0.11.0] - 2018-08-12
### Added
- Users can now overwrite the default R-class-to-Julia conversion rules ([#251]).

### Changed
- Updated the package for Julia 0.7/1.0 compatibility, removing the `Compat.jl` dependency ([#249], [#250]).
- Removed support for `Nullable`-based code.

### Fixed
- Fixed a bug where an R function could be garbage-collected prematurely.
- Fixed several deprecation-related bugs and `OrderedDict` iteration issues.

## [0.10.6] - 2018-05-16
### Added
- Added `rprint` support for `Ptr{Sxp}`.

### Changed
- Updated formula copying for `StatsModels` v0.2.4 compatibility, raising the minimum required `StatsModels` version ([#242]).

### Fixed
- Fixed unsafe pointer handling for R 3.5 by using `R_ExternalPtrAddr` instead of `unsafe_load`.

## [0.10.5] - 2018-04-21
### Added
- Users can now explicitly specify use of the Conda-provided R.

### Fixed
- Conda R is now only used when `R_HOME` is not already set ([#241]).

## [0.10.4] - 2018-04-01
### Fixed
- Avoided using `@eval` inside `__init__`.

## [0.10.3] - 2018-03-29
### Added
- Added preliminary support for converting R formulas.
- R function calls can now be copied as a Julia `Expr`.

### Fixed
- Fixed `R_NilValue` handling when embedded in RStudio on Linux.
- Fixed constant loading when RCall is embedded in R.
- Fixed a memory-protection issue in error-condition handling.

## [0.10.2] - 2018-03-21
### Added
- Added support for installing R via Conda automatically during `Pkg.build`.
- Added support for custom converters for `LangSxp`.

### Fixed
- Fixed handling of the build dependency file so it's only rewritten when changed.
- Fixed call argument handling to return an `RObject`.

## [0.10.1] - 2018-01-18
### Added
- Added support for empty `AxisArray` axes.
- Added `nrow`/`ncol` support for R data frames.

### Fixed
- Fixed Unicode handling in the render function.
- Fixed an incorrect error being thrown in some cases.
- Fixed reliance on `R_Visible`, which no longer works with recent R.

## [0.10.0] - 2018-01-12
### Added
- Added support for converting `Array{Union{T,Missing}}`; `Union{T,Missing}` is now the default element type for missing data.

### Changed
- Scalar `NA` now converts to Julia `missing`.

### Fixed
- Fixed R home/library detection on Windows.

## [0.9.0] - 2017-11-29
### Changed
- Deprecated `NullableArrays` support in favor of `Missing`-based arrays.
- `NULL` now round-trips with Julia's `Nullable()`.
- Improved error messages when rendering fails.

### Fixed
- Fixed `rcopy(AbstractArray, r)` for creating `AxisArray`s.

## [0.8.1] - 2017-11-13
### Changed
- R lists are now copied to `OrderedDict` by default.
- Improved `tryEval`/`parseVector` and always throw an error on nonzero eval status.

### Fixed
- Fixed several garbage-collection protection bugs.

## [0.8.0] - 2017-11-04
### Changed
- Major refactor of the I/O and error-handling code, now using R's `tryCatch`-based evaluation internally ([#210]).
- Raised the minimum required R version to 3.4.0.

### Fixed
- Fixed parse-error handling and a `PPStack` imbalance bug.

## [0.7.5] - 2017-10-26
### Changed
- R integers are now converted to Julia `Int` by default ([#209]).
- Updated for compatibility with `CategoricalArrays` 0.2.
- Deprecated `IJuliaHooks`.

### Fixed
- Fixed R REPL mode initialization detection ([#201]).
- Fixed `HOME`/`R_USER` environment variables on Windows ([#207]).
- Fixed conversion of integer vectors with missing values to `DataArray{Int}`.

## [0.7.4] - 2017-07-25
### Added
- Added support for converting `RawSxp`.
- Added a fallback `rcopy` method that catches `MethodError`.

### Fixed
- Fixed explicit conversion of `NamedArray` and `AxisArray`.
- Fixed an ambiguity converting `NULL` to `Any`.

## [0.7.3] - 2017-06-14
### Added
- Added getter/setter (`getindex`/`setindex!`) support for S4 objects ([#187]).
- Implemented the `RClass` mechanism for dispatching conversions based on R class ([#192]).
- Documented how to write custom conversions.

### Fixed
- Fixed `rcopy(Array, s)` to dispatch based on the R class of `s`.
- Fixed importing a vector containing an invariant factor ([#188]).
- Re-enabled `LangSxp` conversion.

## [0.7.2] - 2017-04-05
### Fixed
- Fixed spurious output being written after a failed evaluation; rewrote the IO handling code ([#183]).

## [0.7.1] - 2017-04-03
### Changed
- `rprint` can now use the error and warning devices.

### Fixed
- Fixed IJulia initialization issues.
- Improved `@rlibrary` and `@rimport` macros.

## [0.7.0] - 2017-03-24
### Added
- Added conversion of `Date` and `DateTime` (including `Nullable` variants) to and from R.
- Added `sexp` support for `AbstractDataFrame`.
- Added support for `AxisArrays` and `NamedArrays`.
- Added support for both `DataArrays` and `NullableArrays`.

### Changed
- Updated the package for Julia v0.6 compatibility ([#172], [#173]).
- Renamed `CategoricalArrays.ordered` usage to `isordered`.
- Deprecated `rcopy(::String)` and `rcopy(::Symbol)`.
- Deprecated `SxpPtr` in favor of `Ref`.

### Fixed
- Fixed conversion of `NullableArrays` ([#165]).
- Improved `isna` behavior for `DataFrames` integration.

## [0.6.4] - 2016-12-23
### Fixed
- Improved error messages when the R library fails to load.

## [0.6.3] - 2016-12-01
### Fixed
- Fixed `rcopy` to `CategoricalArray` requiring levels to be an array.

## [0.6.2] - 2016-11-21
### Fixed
- Fixed R library detection to use `dlopen_e`.

## [0.6.1] - 2016-11-09
### Fixed
- Fixed R library detection by verifying the library actually loads ([#153]).

## [0.6.0] - 2016-10-14
### Added
- Added support for `NullableArrays` and `CategoricalArrays`, including handling of `Nullable` values ([#145]).

### Changed
- Raised the minimum supported Julia version to 0.5.
- `.Last.value` is now set after evaluating R code.
- Removed the `Compat` dependency.

### Fixed
- Fixed the `$` REPL mode being initialized incorrectly under basic REPLs such as Emacs ([#151]).
- Fixed several memory protection imbalances.
- Fixed rendering of R output.

## [0.5.2] - 2016-09-19
### Fixed
- Fixed rendering of duplicated R expressions.
- Fixed a protection bug in `reval` ([#136]).
- Fixed IJulia display integration by no longer calling `InlineDisplay` directly ([#139]).

## [0.5.1] - 2016-08-03
### Added
- Added bracketed-paste support in the R REPL mode ([#125]).
- Added LaTeX tab-completion in the R REPL mode.
- Added `rcopy(Array{Symbol}, ...)` and `names` support for SEXP pointers.
- Exported more functions from the package.

### Changed
- `LD_LIBRARY_PATH` can now be set for R installations in non-standard locations.

### Fixed
- Fixed `Ctrl-C` unexpectedly exiting the REPL prompt; improved SIGINT handling.
- Fixed error reporting to use R's parse-context information for better messages.
- Fixed several memory-protection bugs (`reval` arguments, etc.).

## [0.5.0] - 2016-06-21
### Added
- Added an interactive R REPL mode within Julia, with tab completion and variable substitution ([#115]).
- Added a `$` prefix to switch between Julia and R REPL modes.

### Changed
- Evaluate the `R"..."` string macro in its own environment ([#110]).
- Updated code for Julia 0.5 compatibility (`Compat`, `is_windows()`, `Symbol`, etc.).

### Fixed
- Fixed print buffer flushing by hooking into R process events.

## [0.4.1] - 2016-04-30
### Changed
- Switched to `WinReg.jl` for querying the Windows registry ([#103]).

### Fixed
- Fixed event processing on Windows by running `R_ProcessEvents` ([#104]).
- Fixed temporary variables not being cleaned up when the result of `@R_str` is garbage collected ([#107]).

## [0.4.0] - 2016-03-21
### Added
- Added the `R"..."` string macro for inlining R code directly in Julia ([#94]).
- Added basic arithmetic/comparison operator support for R objects ([#77]).

### Changed
- Enabled precompilation; raised the minimum Julia version to 0.4 ([#93]).
- `@rlibrary` no longer depends on `@rimport`.
- Improved `@rimport`/package-import functionality, including avoiding a segfault when a namespace isn't found.

### Fixed
- Fixed `@rusing` when an R package contains a function with the same name as the package.
- Fixed several protection/stack-imbalance bugs.

## [0.3.2] - 2016-03-09
### Added
- Added support for converting `Dict` to/from `RObject`.

### Changed
- Removed the need for `BinDeps`; the R version is now checked at installation time.
- Overrode the `show` function for better IJulia display.

### Fixed
- Fixed arguments not being protected from garbage collection.
- Fixed `R_HOME` path detection ([#80], [#81]).

## [0.3.1] - 2015-11-11
### Added
- Exported `NilSxp`.
- Added `newEnvironment` and `findNamespace` helper functions.

### Changed
- Improved the `rprint` function to use `print.default`.

### Fixed
- Fixed a bug affecting void callbacks.
- Improved signal handling.

## [0.3.0] - 2015-10-14
### Added
- Added `RObject` as the main wrapper type, as part of a major internal refactor.
- Added `@rput` and `@rget` macros for transferring variables between Julia and R.
- Added `rprint` supporting arbitrary `IO` and `show` methods for SEXP types ([#54]).
- Added support for R callbacks.

### Changed
- Renamed internal SEXP pointer types (`XXXSxp` to `XXXSxpRec`, `SxpRec` to `Sxp`, `Sxp` to `SxpPtr`) for clarity.
- Added more conversion routines with value-dependent default `rcopy` behavior.

### Fixed
- Fixed UTF-8 encoding issues.
- Fixed the event loop to work with newer `Timer` changes ([#56]).
- Fixed several printing/warning issues by routing through R's IO interface.
- Fixed IJulia integration on Windows, including filename handling ([#65]) and an SVG plotting bug.
- Fixed `HOME` not being defined on Windows ([#68]).

## [0.2.1] - 2015-05-14
### Added
- Added getter and setter support for `LangSxp`.

### Fixed
- Fixed a potential segfault by preserving parse and eval results.
- Fixed handling of `NA` in character vectors.
- Fixed a bug converting `LglSxp` to `DataArray` on Julia 0.4.
- Fixed the Windows build ([#52]).

## [0.2.0] - 2015-04-16
### Added
- Added conversions from `DataArray` and `DataFrame` to R SEXPs.
- Added conversion from Julia `Range` to an R SEXP.
- Added an R event loop for better interactivity.

### Changed
- The R process name can now be customized, enabling a custom `.Rprofile`.
- Improved IJulia functionality and updated graphics documentation.

### Fixed
- Fixed loading of IJulia support to avoid a segfault on some platforms.
- Fixed `Rinstance` to return the correct object.
- An error is now thrown when an `IntSxp` representing a factor is used incorrectly.

## [0.1.2] - 2015-04-13
### Added
- Added IJulia support.
- Added support for SVG graphics devices; arguments to `rcall` are now automatically converted with `sexp`.

### Changed
- Simplified the `rwrap` function.
- Added `BinDeps` as a build dependency.

### Fixed
- Fixed bounds checking when retrieving objects from an R environment.
- Fixed `isNA` for `Float64` and `Complex128`.
- Fixed handling of string arrays containing `NA` values.
- Fixed the SEXP type tag used for real values.

## [0.1.1] - 2015-03-13
### Added
- Added `rcall` for calling R functions directly from Julia.
- Added `@rimport` to import an R library as a Julia module.
- Allowed use of symbols in `lang` calls.

### Fixed
- Resolved a method ambiguity in scalar/array `sexp` conversions.

## [0.1.0] - 2015-02-26
- Reorganized and documented the package, revising the overall code structure.
- Added an IJulia notebook demonstrating usage.
- Switched the internal SEXP representation to use an abstract `SEXPREC` type with subtypes.
- Updated example notebooks to Jupyter (IPython 3.0) format.

## [0.0.3] - 2015-02-05
- Added support for converting `ASCIIString` vectors between Julia and R.
- Added documentation and tests; switched internal implementation from `vec` to `copyvec`.

## [0.0.2] - 2015-02-02
- Fixed an incorrect element count when converting a `Matrix` to an R SEXP.
- Fixed a copy-paste bug affecting `lang4`, `lang5`, and `lang6`.
- Cleaned up SEXP creation code.

## [0.0.1] - 2015-01-14
Initial release.

<!-- Versions -->
[Unreleased]: https://github.com/JuliaInterop/RCall.jl/compare/v0.14.13...HEAD
[0.14.13]: https://github.com/JuliaInterop/RCall.jl/compare/v0.14.12...v0.14.13
[0.14.12]: https://github.com/JuliaInterop/RCall.jl/compare/v0.14.11...v0.14.12
[0.14.11]: https://github.com/JuliaInterop/RCall.jl/compare/v0.13.14...v0.14.11
[0.13.14]: https://github.com/JuliaInterop/RCall.jl/compare/v0.14.10...v0.13.14
[0.14.10]: https://github.com/JuliaInterop/RCall.jl/compare/v0.14.9...v0.14.10
[0.14.9]: https://github.com/JuliaInterop/RCall.jl/compare/v0.14.8...v0.14.9
[0.14.8]: https://github.com/JuliaInterop/RCall.jl/compare/v0.14.7...v0.14.8
[0.14.7]: https://github.com/JuliaInterop/RCall.jl/compare/v0.14.6...v0.14.7
[0.14.6]: https://github.com/JuliaInterop/RCall.jl/compare/v0.14.5...v0.14.6
[0.14.5]: https://github.com/JuliaInterop/RCall.jl/compare/v0.14.4...v0.14.5
[0.14.4]: https://github.com/JuliaInterop/RCall.jl/compare/v0.14.3...v0.14.4
[0.14.3]: https://github.com/JuliaInterop/RCall.jl/compare/v0.14.2...v0.14.3
[0.14.2]: https://github.com/JuliaInterop/RCall.jl/compare/v0.14.1...v0.14.2
[0.14.1]: https://github.com/JuliaInterop/RCall.jl/compare/v0.14.0...v0.14.1
[0.14.0]: https://github.com/JuliaInterop/RCall.jl/compare/v0.13.18...v0.14.0
[0.13.18]: https://github.com/JuliaInterop/RCall.jl/compare/v0.13.17...v0.13.18
[0.13.17]: https://github.com/JuliaInterop/RCall.jl/compare/v0.13.16...v0.13.17
[0.13.16]: https://github.com/JuliaInterop/RCall.jl/compare/v0.13.15...v0.13.16
[0.13.15]: https://github.com/JuliaInterop/RCall.jl/compare/v0.13.13...v0.13.15
[0.13.13]: https://github.com/JuliaInterop/RCall.jl/compare/v0.13.12...v0.13.13
[0.13.12]: https://github.com/JuliaInterop/RCall.jl/compare/v0.13.11...v0.13.12
[0.13.11]: https://github.com/JuliaInterop/RCall.jl/compare/v0.13.10...v0.13.11
[0.13.10]: https://github.com/JuliaInterop/RCall.jl/compare/v0.13.9...v0.13.10
[0.13.9]: https://github.com/JuliaInterop/RCall.jl/compare/v0.13.8...v0.13.9
[0.13.8]: https://github.com/JuliaInterop/RCall.jl/compare/v0.13.7...v0.13.8
[0.13.7]: https://github.com/JuliaInterop/RCall.jl/compare/v0.13.6...v0.13.7
[0.13.6]: https://github.com/JuliaInterop/RCall.jl/compare/v0.13.5...v0.13.6
[0.13.5]: https://github.com/JuliaInterop/RCall.jl/compare/v0.13.4...v0.13.5
[0.13.4]: https://github.com/JuliaInterop/RCall.jl/compare/v0.13.3...v0.13.4
[0.13.3]: https://github.com/JuliaInterop/RCall.jl/compare/v0.13.2...v0.13.3
[0.13.2]: https://github.com/JuliaInterop/RCall.jl/compare/v0.13.1...v0.13.2
[0.13.1]: https://github.com/JuliaInterop/RCall.jl/compare/v0.13.0...v0.13.1
[0.13.0]: https://github.com/JuliaInterop/RCall.jl/compare/v0.12.1...v0.13.0
[0.12.1]: https://github.com/JuliaInterop/RCall.jl/compare/v0.12.0...v0.12.1
[0.12.0]: https://github.com/JuliaInterop/RCall.jl/compare/v0.11.0...v0.12.0
[0.11.0]: https://github.com/JuliaInterop/RCall.jl/compare/v0.10.6...v0.11.0
[0.10.6]: https://github.com/JuliaInterop/RCall.jl/compare/v0.10.5...v0.10.6
[0.10.5]: https://github.com/JuliaInterop/RCall.jl/compare/v0.10.4...v0.10.5
[0.10.4]: https://github.com/JuliaInterop/RCall.jl/compare/v0.10.3...v0.10.4
[0.10.3]: https://github.com/JuliaInterop/RCall.jl/compare/v0.10.2...v0.10.3
[0.10.2]: https://github.com/JuliaInterop/RCall.jl/compare/v0.10.1...v0.10.2
[0.10.1]: https://github.com/JuliaInterop/RCall.jl/compare/v0.10.0...v0.10.1
[0.10.0]: https://github.com/JuliaInterop/RCall.jl/compare/v0.9.0...v0.10.0
[0.9.0]: https://github.com/JuliaInterop/RCall.jl/compare/v0.8.1...v0.9.0
[0.8.1]: https://github.com/JuliaInterop/RCall.jl/compare/v0.8.0...v0.8.1
[0.8.0]: https://github.com/JuliaInterop/RCall.jl/compare/v0.7.5...v0.8.0
[0.7.5]: https://github.com/JuliaInterop/RCall.jl/compare/v0.7.4...v0.7.5
[0.7.4]: https://github.com/JuliaInterop/RCall.jl/compare/v0.7.3...v0.7.4
[0.7.3]: https://github.com/JuliaInterop/RCall.jl/compare/v0.7.2...v0.7.3
[0.7.2]: https://github.com/JuliaInterop/RCall.jl/compare/v0.7.1...v0.7.2
[0.7.1]: https://github.com/JuliaInterop/RCall.jl/compare/v0.7.0...v0.7.1
[0.7.0]: https://github.com/JuliaInterop/RCall.jl/compare/v0.6.4...v0.7.0
[0.6.4]: https://github.com/JuliaInterop/RCall.jl/compare/v0.6.3...v0.6.4
[0.6.3]: https://github.com/JuliaInterop/RCall.jl/compare/v0.6.2...v0.6.3
[0.6.2]: https://github.com/JuliaInterop/RCall.jl/compare/v0.6.1...v0.6.2
[0.6.1]: https://github.com/JuliaInterop/RCall.jl/compare/v0.6.0...v0.6.1
[0.6.0]: https://github.com/JuliaInterop/RCall.jl/compare/v0.5.2...v0.6.0
[0.5.2]: https://github.com/JuliaInterop/RCall.jl/compare/v0.5.1...v0.5.2
[0.5.1]: https://github.com/JuliaInterop/RCall.jl/compare/v0.5.0...v0.5.1
[0.5.0]: https://github.com/JuliaInterop/RCall.jl/compare/v0.4.1...v0.5.0
[0.4.1]: https://github.com/JuliaInterop/RCall.jl/compare/v0.4.0...v0.4.1
[0.4.0]: https://github.com/JuliaInterop/RCall.jl/compare/v0.3.2...v0.4.0
[0.3.2]: https://github.com/JuliaInterop/RCall.jl/compare/v0.3.1...v0.3.2
[0.3.1]: https://github.com/JuliaInterop/RCall.jl/compare/v0.3.0...v0.3.1
[0.3.0]: https://github.com/JuliaInterop/RCall.jl/compare/v0.2.1...v0.3.0
[0.2.1]: https://github.com/JuliaInterop/RCall.jl/compare/v0.2.0...v0.2.1
[0.2.0]: https://github.com/JuliaInterop/RCall.jl/compare/v0.1.2...v0.2.0
[0.1.2]: https://github.com/JuliaInterop/RCall.jl/compare/v0.1.1...v0.1.2
[0.1.1]: https://github.com/JuliaInterop/RCall.jl/compare/v0.1.0...v0.1.1
[0.1.0]: https://github.com/JuliaInterop/RCall.jl/compare/v0.0.3...v0.1.0
[0.0.3]: https://github.com/JuliaInterop/RCall.jl/compare/v0.0.2...v0.0.3
[0.0.2]: https://github.com/JuliaInterop/RCall.jl/compare/v0.0.1...v0.0.2
[0.0.1]: https://github.com/JuliaInterop/RCall.jl/releases/tag/v0.0.1

<!-- Pull requests -->
[#52]: https://github.com/JuliaInterop/RCall.jl/pull/52
[#54]: https://github.com/JuliaInterop/RCall.jl/pull/54
[#56]: https://github.com/JuliaInterop/RCall.jl/pull/56
[#65]: https://github.com/JuliaInterop/RCall.jl/pull/65
[#68]: https://github.com/JuliaInterop/RCall.jl/pull/68
[#77]: https://github.com/JuliaInterop/RCall.jl/pull/77
[#80]: https://github.com/JuliaInterop/RCall.jl/pull/80
[#81]: https://github.com/JuliaInterop/RCall.jl/pull/81
[#93]: https://github.com/JuliaInterop/RCall.jl/pull/93
[#94]: https://github.com/JuliaInterop/RCall.jl/pull/94
[#103]: https://github.com/JuliaInterop/RCall.jl/pull/103
[#104]: https://github.com/JuliaInterop/RCall.jl/pull/104
[#107]: https://github.com/JuliaInterop/RCall.jl/pull/107
[#110]: https://github.com/JuliaInterop/RCall.jl/pull/110
[#115]: https://github.com/JuliaInterop/RCall.jl/pull/115
[#125]: https://github.com/JuliaInterop/RCall.jl/pull/125
[#136]: https://github.com/JuliaInterop/RCall.jl/pull/136
[#139]: https://github.com/JuliaInterop/RCall.jl/pull/139
[#145]: https://github.com/JuliaInterop/RCall.jl/pull/145
[#151]: https://github.com/JuliaInterop/RCall.jl/pull/151
[#153]: https://github.com/JuliaInterop/RCall.jl/pull/153
[#165]: https://github.com/JuliaInterop/RCall.jl/pull/165
[#172]: https://github.com/JuliaInterop/RCall.jl/pull/172
[#173]: https://github.com/JuliaInterop/RCall.jl/pull/173
[#183]: https://github.com/JuliaInterop/RCall.jl/pull/183
[#187]: https://github.com/JuliaInterop/RCall.jl/pull/187
[#188]: https://github.com/JuliaInterop/RCall.jl/pull/188
[#192]: https://github.com/JuliaInterop/RCall.jl/pull/192
[#201]: https://github.com/JuliaInterop/RCall.jl/pull/201
[#207]: https://github.com/JuliaInterop/RCall.jl/pull/207
[#209]: https://github.com/JuliaInterop/RCall.jl/pull/209
[#210]: https://github.com/JuliaInterop/RCall.jl/pull/210
[#241]: https://github.com/JuliaInterop/RCall.jl/pull/241
[#242]: https://github.com/JuliaInterop/RCall.jl/pull/242
[#249]: https://github.com/JuliaInterop/RCall.jl/pull/249
[#250]: https://github.com/JuliaInterop/RCall.jl/pull/250
[#251]: https://github.com/JuliaInterop/RCall.jl/pull/251
[#259]: https://github.com/JuliaInterop/RCall.jl/pull/259
[#260]: https://github.com/JuliaInterop/RCall.jl/pull/260
[#262]: https://github.com/JuliaInterop/RCall.jl/pull/262
[#263]: https://github.com/JuliaInterop/RCall.jl/pull/263
[#266]: https://github.com/JuliaInterop/RCall.jl/pull/266
[#267]: https://github.com/JuliaInterop/RCall.jl/pull/267
[#271]: https://github.com/JuliaInterop/RCall.jl/pull/271
[#275]: https://github.com/JuliaInterop/RCall.jl/pull/275
[#279]: https://github.com/JuliaInterop/RCall.jl/pull/279
[#285]: https://github.com/JuliaInterop/RCall.jl/pull/285
[#288]: https://github.com/JuliaInterop/RCall.jl/pull/288
[#291]: https://github.com/JuliaInterop/RCall.jl/pull/291
[#293]: https://github.com/JuliaInterop/RCall.jl/pull/293
[#296]: https://github.com/JuliaInterop/RCall.jl/pull/296
[#299]: https://github.com/JuliaInterop/RCall.jl/pull/299
[#301]: https://github.com/JuliaInterop/RCall.jl/pull/301
[#309]: https://github.com/JuliaInterop/RCall.jl/pull/309
[#310]: https://github.com/JuliaInterop/RCall.jl/pull/310
[#317]: https://github.com/JuliaInterop/RCall.jl/pull/317
[#327]: https://github.com/JuliaInterop/RCall.jl/pull/327
[#329]: https://github.com/JuliaInterop/RCall.jl/pull/329
[#332]: https://github.com/JuliaInterop/RCall.jl/pull/332
[#337]: https://github.com/JuliaInterop/RCall.jl/pull/337
[#338]: https://github.com/JuliaInterop/RCall.jl/pull/338
[#350]: https://github.com/JuliaInterop/RCall.jl/pull/350
[#352]: https://github.com/JuliaInterop/RCall.jl/pull/352
[#357]: https://github.com/JuliaInterop/RCall.jl/pull/357
[#362]: https://github.com/JuliaInterop/RCall.jl/pull/362
[#364]: https://github.com/JuliaInterop/RCall.jl/pull/364
[#372]: https://github.com/JuliaInterop/RCall.jl/pull/372
[#377]: https://github.com/JuliaInterop/RCall.jl/pull/377
[#382]: https://github.com/JuliaInterop/RCall.jl/pull/382
[#387]: https://github.com/JuliaInterop/RCall.jl/pull/387
[#390]: https://github.com/JuliaInterop/RCall.jl/pull/390
[#392]: https://github.com/JuliaInterop/RCall.jl/pull/392
[#395]: https://github.com/JuliaInterop/RCall.jl/pull/395
[#399]: https://github.com/JuliaInterop/RCall.jl/pull/399
[#410]: https://github.com/JuliaInterop/RCall.jl/pull/410
[#411]: https://github.com/JuliaInterop/RCall.jl/pull/411
[#413]: https://github.com/JuliaInterop/RCall.jl/pull/413
[#426]: https://github.com/JuliaInterop/RCall.jl/pull/426
[#441]: https://github.com/JuliaInterop/RCall.jl/pull/441
[#443]: https://github.com/JuliaInterop/RCall.jl/pull/443
[#463]: https://github.com/JuliaInterop/RCall.jl/pull/463
[#495]: https://github.com/JuliaInterop/RCall.jl/pull/495
[#496]: https://github.com/JuliaInterop/RCall.jl/pull/496
[#498]: https://github.com/JuliaInterop/RCall.jl/pull/498
[#502]: https://github.com/JuliaInterop/RCall.jl/pull/502
[#515]: https://github.com/JuliaInterop/RCall.jl/pull/515
[#530]: https://github.com/JuliaInterop/RCall.jl/pull/530
[#532]: https://github.com/JuliaInterop/RCall.jl/pull/532
[#533]: https://github.com/JuliaInterop/RCall.jl/pull/533
[#537]: https://github.com/JuliaInterop/RCall.jl/pull/537
[#540]: https://github.com/JuliaInterop/RCall.jl/pull/540
[#541]: https://github.com/JuliaInterop/RCall.jl/pull/541
[#549]: https://github.com/JuliaInterop/RCall.jl/pull/549
[#560]: https://github.com/JuliaInterop/RCall.jl/pull/560
[#567]: https://github.com/JuliaInterop/RCall.jl/pull/567
[#571]: https://github.com/JuliaInterop/RCall.jl/pull/571
[#574]: https://github.com/JuliaInterop/RCall.jl/pull/574
[#575]: https://github.com/JuliaInterop/RCall.jl/pull/575
[#588]: https://github.com/JuliaInterop/RCall.jl/pull/588
[#591]: https://github.com/JuliaInterop/RCall.jl/pull/591
[#598]: https://github.com/JuliaInterop/RCall.jl/pull/598
[#600]: https://github.com/JuliaInterop/RCall.jl/pull/600
[#604]: https://github.com/JuliaInterop/RCall.jl/pull/604
