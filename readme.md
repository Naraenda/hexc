# Hexpattern Compiler for Hex Casting in Lua

Partial implementation of the `.hexpattern` format used in the [`vscode-hex-casting`](https://github.com/object-Object/vscode-hex-casting) to build hexes from the [Hex Casting](https://github.com/FallingColors/HexMod) Minecraft mod. This is written in Lua for [CC: Tweaked](https://github.com/cc-tweaked/CC-Tweaked) to make in-game hex making easier.

Currently the following features are implemented:

- A `.hexpattern` compiler: `hexc.lua`.
- A literal number path finder `hexnum.lua`.
  - A* path searching using a monotonic heuristic.
- Symbol name parsing and translating to angle-notation.
- Handles numbers (*Numerical Reflection*) and masking (*Bookkeeper's Gambit*).
  - Very large numbers >50000 and very small numbers <0.2 are still slow and may time out on slow computers.
  - Decimal numbers are not exact.

The following features are missing to have full support for `.hexpattern`:

- There is no support for `#define <name> (<dir> <angles>) = <type> -> <type>`.
- There is no support for `#include "<filepath>"`.
