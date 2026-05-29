# TCAExample — The Composable Architecture (TCA) CRUD Sample App in SwiftUI

> A production-style **iOS CRUD app** built with **SwiftUI** and **The Composable
> Architecture (TCA)** by Point-Free — demonstrating unidirectional data flow,
> dependency injection, navigation in state, and clean async/await networking
> against a REST API.

![Swift](https://img.shields.io/badge/Swift-6-orange.svg)
![SwiftUI](https://img.shields.io/badge/SwiftUI-iOS%2026-blue.svg)
![Architecture](https://img.shields.io/badge/Architecture-TCA-green.svg)
![Platform](https://img.shields.io/badge/Platform-iOS%20%7C%20iPad-lightgrey.svg)

If you're looking for a **real-world TCA example**, a **SwiftUI state management
sample**, or a reference for **unidirectional architecture on iOS**, this repo
walks through a complete create / read / update / delete flow end to end.

## Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Why The Composable Architecture?](#why-the-composable-architecture)
- [Requirements](#requirements)
- [Build & Run](#build--run)
- [Architecture](#architecture)
- [API](#api)
- [Learning Aid: TCA Action Tracing](#learning-aid-tca-action-tracing)
- [Keywords & Topics](#keywords--topics)

## Overview

**TCAExample** is a SwiftUI iOS app demonstrating a production-style **CRUD**
application built with [The Composable Architecture (TCA)](https://github.com/pointfreeco/swift-composable-architecture),
backed by the [restful-api.dev](https://restful-api.dev) `/objects` API.

The app signs in with an API key, then lists, creates, edits, renames, and
deletes objects (presented as "Products" in the UI). It is a focused,
copy-pasteable reference for anyone learning **TCA**, **SwiftUI app
architecture**, or **Swift state management** patterns.

## Features

- 🔐 **API-key gate** → **Products list** → **create / view / edit / rename / delete**
- 🔄 Pull-to-refresh with loading / empty / error states
- 🗝️ API key persisted in the **Keychain**; a `401` logs the user out
- 🧩 **Strict TCA**: value-typed state, `@Reducer` features, side effects via
  injected dependencies, child→parent communication through `delegate` actions,
  and **navigation modeled in state**
- ⚡️ Modern **Swift Concurrency** (`async`/`await`) networking layer
- 🧪 Dependency injection with network-free preview values for SwiftUI Previews

## Why The Composable Architecture?

The Composable Architecture (TCA) is a library for building applications with
**unidirectional data flow**, composable and testable features, and explicit
side-effect management. This sample shows how those ideas scale across a
multi-screen iOS app — a practical alternative to ad-hoc **MVVM** when you want
predictable state, ergonomic testing, and clear separation of concerns.

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

> **Note:** You'll need your own [restful-api.dev](https://restful-api.dev) API
> key. Enter it on the login screen — it is stored in the Keychain and is never
> hardcoded in the source.

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

## Learning Aid: TCA Action Tracing

Every feature has a `#if DEBUG`-gated `._printChanges()` that logs each action
and the resulting state diff to the console, so you can watch the **unidirectional
data-flow loop** in action. This adds zero overhead to release builds — a great
way to *learn how TCA actually works* by reading the live action/state stream.

## Keywords & Topics

`#Swift` `#SwiftUI` `#iOS` `#TCA` `#TheComposableArchitecture`
`#ComposableArchitecture` `#PointFree` `#StateManagement`
`#UnidirectionalDataFlow` `#DependencyInjection` `#SwiftConcurrency`
`#AsyncAwait` `#CRUD` `#RESTAPI` `#Keychain` `#MVVM` `#iOSDevelopment`
`#Swift6` `#MobileApp` `#ExampleApp`
