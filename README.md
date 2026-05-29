# TCAExample

A SwiftUI iOS app demonstrating a production-style CRUD app built with
[The Composable Architecture (TCA)](https://github.com/pointfreeco/swift-composable-architecture),
backed by the [restful-api.dev](https://restful-api.dev) `/objects` API.

The app signs in with an API key, then lists, creates, edits, renames, and
deletes objects (presented as "Products" in the UI).

## Features

- **API-key gate** → **Products list** → **create / view / edit / rename / delete**
- Pull-to-refresh, loading/empty/error states
- API key persisted in the Keychain; a `401` logs the user out
- Strict TCA: value-typed state, `@Reducer` features, side effects via injected
  dependencies, child→parent communication through `delegate` actions, and
  navigation modeled in state

## Requirements

- **Xcode 26.5** (Swift 6 toolchain, Swift 5 language mode)
- **iOS 26.5** deployment target (iPhone + iPad)
- Dependency: `swift-composable-architecture` via Swift Package Manager (resolves
  automatically on first build in Xcode)

## Build & Run

There is no `.xcworkspace` — open the project and use the `TCAExample` scheme
(⌘R). From the command line:

```bash
xcodebuild build -project TCAExample.xcodeproj -scheme TCAExample \
  -destination 'platform=iOS Simulator,name=iPhone 16'
```

> If you see `No such module 'ComposableArchitecture'`, the SPM package just
> needs resolving — open in Xcode (resolves on build) or run
> `xcodebuild -resolvePackageDependencies`.

## Architecture

Each feature is a `@Reducer` with `@ObservableState`. Parents compose children
via `Scope` (always present) or `@Presents` + `ifLet` (presented), and children
report outcomes upward through `delegate` actions.

```
App/        AppFeature + AppView      — root: API-key session, composition
Features/
  Login/    API-key entry + validation
  Home/     authenticated TabView shell (Products + Account)
  Products/ CRUD: list, detail, and a create/edit form
  Account/  masked key + logout
Clients/    AuthClient (validate key), ProductsClient (CRUD),
            APIKeyStore (Keychain), RestfulAPI (URL building + x-api-key)
Models/     Product, ProductInput, JSONValue, DataField, APIError
Components/ ErrorStateView, TimestampText
Support/    Keychain
```

### Session ownership

`AppFeature` is the single owner of the API-key session. It composes
`LoginFeature` (always present) and an optional `HomeFeature` (present only when
a valid key exists). On launch it restores and validates the stored key; a `401`
clears it and returns to login. `AccountFeature`'s logout `delegate` falls
through `HomeFeature` to `AppFeature`, which clears the key.

### Products CRUD

- `ProductsFeature` loads the list and presents `ProductDetailFeature` (push) and
  `ProductFormFeature` (sheet, create).
- `ProductFormFeature` is shared by **create (POST)** and **edit (PUT)**.
- `ProductDetailFeature` hosts **edit (PUT)**, **rename (PATCH)**, and
  **delete (DELETE)**, reporting results back up via `delegate`.

### Dependencies

Clients are hand-written structs of closures, each with a `liveValue` (real
network / Keychain) and a network-free `previewValue` for SwiftUI previews and
tests.

## API

All calls hit `https://api.restful-api.dev`, scoped to a private collection
(`/collections/products/objects`) with an `x-api-key` header. Using the private
collection (instead of the public `/objects`) means created objects persist and
appear in the list. There is no real auth/token concept — "auth" is validating
the API key with a real request and storing it in the Keychain.

## Learning aid: TCA action tracing

Every feature has a `#if DEBUG`-gated `._printChanges()` that logs each action
and the resulting state diff to the console, so you can watch the unidirectional
data-flow loop in action. This adds zero overhead to release builds.
