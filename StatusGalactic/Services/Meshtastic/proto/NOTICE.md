# Vendored Meshtastic protobuf schema

The `.proto` files under this directory are a snapshot of the Meshtastic
project's protocol-buffer schema, taken from:

- https://github.com/meshtastic/protobufs

The upstream project is licensed under GPL-3.0. This repository vendors the
`.proto` schema files (interface descriptions, not implementation) so that we
can regenerate the Swift bindings under `../Generated/` using the
Apache-2.0-licensed `apple/swift-protobuf` toolchain.

**Important:**

- No source code from `meshtastic/Meshtastic-Apple` (GPLv3) was used; the
  Swift bindings under `../Generated/` are produced solely by
  `protoc-gen-swift` from these `.proto` files.
- Only the Apache-2.0 `SwiftProtobuf` runtime is linked into the app.
- The `nanopb.proto` file at the proto root is a vendored copy of the
  upstream nanopb annotation extensions, included because the Meshtastic
  schema imports it. It is BSD-2-Clause / zlib-style licensed.

**Modification from upstream.** Upstream `meshtastic/*.proto` files include
`option swift_prefix = "";` (because the official Meshtastic-Apple app
isolates protobuf types in their own module). We compile generated bindings
into the main app target alongside other code, so we strip that one line per
file when vendoring. This restores the default `Meshtastic_` Swift prefix
(e.g. `Meshtastic_FromRadio`), avoiding identifier collisions with common
type names already used elsewhere in the app (`Config`, `User`, `Channel`,
`Position`, etc.). The wire format is unaffected.

To regenerate the Swift bindings from this directory:

```
cd StatusGalactic/Services/Meshtastic
protoc \
  --proto_path=proto \
  --swift_out=Generated \
  --swift_opt=Visibility=Internal \
  proto/meshtastic/*.proto proto/nanopb.proto
```

`protoc` and `protoc-gen-swift` are installed via `brew install protobuf
swift-protobuf`.
