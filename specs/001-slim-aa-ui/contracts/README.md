# Internal Service Contracts

**Feature**: Slim AndroidAuto UI  
**Created**: 2026-01-10

## Overview

This directory contains the internal API contracts for the Slim AndroidAuto UI application. These define the interfaces between C++ backend services and QML frontend components.

## Contract Files

- [settings_manager_contract.md](settings_manager_contract.md) - Settings persistence and management
- [aa_connection_manager_contract.md](aa_connection_manager_contract.md) - AndroidAuto connection lifecycle
- [audio_handler_contract.md](audio_handler_contract.md) - Audio routing and processing
- [video_frame_provider_contract.md](video_frame_provider_contract.md) - Video frame delivery

## Contract Format

Each contract specifies:
- **Service Name**: Identifier for the service
- **Purpose**: What the service does
- **Exposed Properties**: QML-accessible properties (Q_PROPERTY)
- **Exposed Methods**: QML-callable methods (Q_INVOKABLE)
- **Signals**: Events emitted to QML
- **Data Types**: Custom types used in the interface
