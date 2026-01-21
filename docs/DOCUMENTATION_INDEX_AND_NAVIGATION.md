# Crankshaft Documentation Index & Navigation Guide

**Project**: Crankshaft Automotive Infotainment System  
**Documentation Version**: 1.0  
**Last Updated**: 2025-01-15

---

## Quick Start Guide

**New to Crankshaft?** Start here:

1. [SYSTEM_ARCHITECTURE_OVERVIEW.md](#system_architecture_overview) - Get the big picture
2. Choose your path based on role:
   - **Developer**: [CODE_DOCUMENTATION_AUDIT.md](#code_documentation_audit)
   - **Hardware integrator**: [HAL_COMPREHENSIVE_DOCUMENTATION.md](#hal_comprehensive_documentation)
   - **UI developer**: [UI_ARCHITECTURE_DOCUMENTATION.md](#ui_architecture_documentation)
   - **Extension developer**: [EXTENSION_FRAMEWORK_GUIDE.md](#extension_framework_guide)

---

## Documentation Files

### SYSTEM_ARCHITECTURE_OVERVIEW.md {#system_architecture_overview}

**Length**: 2,500+ lines  
**Difficulty**: Intermediate  
**Time to read**: 45 minutes  
**Best for**: Architects, team leads, decision makers

**Contents**:
- System context and deployment architecture
- Complete component breakdown
- Event flow from UI → Core → Services
- Design decisions with rationale
- Technology stack justification
- Performance metrics and targets
- Security model and threat analysis
- Deployment scenarios (single/multi-display)

**Key Sections**:
```
1. System Context Diagram
2. Detailed Component Architecture
3. Event Flow: Complete Journey (UI tap → Output)
4. Design Decisions & Rationale
5. Technology Choices
6. Performance & Resource Management
7. Security Architecture
8. Testing Strategy
9. Future Roadmap
```

**Use when**:
- Planning system modifications
- Understanding high-level architecture
- Evaluating technology choices
- Planning deployments

**Start reading**: Section 1 (System Context)

---

### CODE_DOCUMENTATION_AUDIT.md {#code_documentation_audit}

**Length**: 2,800 lines  
**Difficulty**: Intermediate to Advanced  
**Time to read**: 60 minutes  
**Best for**: Core developers, debugging, integration

**Contents**:
- Complete system topology and layering
- EventBus with scenario examples (3 scenarios)
- WebSocketServer detailed scenarios (3 scenarios)
- ServiceManager lifecycle
- ProfileManager configuration system
- AudioService and audio routing
- VideoService and multimedia
- TransportHAL (UART, CAN, USB)
- Extension framework overview
- UI architecture summary
- Design patterns and rationale
- Documentation checklist

**Key Sections**:
```
1. Core Architecture Overview
2. EventBus (Pub/Sub Pattern)
3. WebSocketServer (Client Relay)
4. ServiceManager (Lifecycle)
5. ProfileManager (Configuration)
6. Audio Service
7. Video/Multimedia
8. Transport Layer
9. Extension Framework
10. UI Architecture
11. Design Patterns
12. Documentation Checklist
```

**Use when**:
- Learning system internals
- Debugging issues
- Adding new services
- Understanding event flow
- Integrating with core

**Start reading**: Section 1 (Architecture Overview)

---

### HAL_COMPREHENSIVE_DOCUMENTATION.md {#hal_comprehensive_documentation}

**Length**: 2,200 lines  
**Difficulty**: Advanced (hardware focus)  
**Time to read**: 60 minutes  
**Best for**: Hardware engineers, HAL developers, system integrators

**Contents**:
- HAL architecture and abstraction patterns
- Audio HAL (ALSA, multi-route, error handling)
- Video HAL (GStreamer, adaptive bitrate, latency)
- Transport layer (USB, UART, CAN, TCP)
- UART protocol specification with examples
- MediaPipeline (audio/video coordination)
- Performance metrics and resource usage
- Testing approaches (unit, integration, scenarios)

**Key Sections**:
```
1. HAL Architecture Overview
2. Audio HAL
   - Design and Purpose
   - Audio Routes
   - Initialization Flow
   - Audio Flow Diagram
   - Route Switching Scenario
   - Error Handling
   - Multi-Stream Mixing
3. Video HAL
   - Pipeline Architecture
   - Video Configuration
   - Adaptive Bitrate Streaming
   - Latency Optimization
   - Error Handling
4. Transport Layer
5. UART Protocol Detailed
6. MediaPipeline
7. Performance Metrics
8. Testing Strategies
```

**Use when**:
- Implementing hardware drivers
- Integrating new hardware
- Optimizing audio/video streaming
- Debugging multimedia issues
- Understanding protocol details

**Start reading**: Section 1 (HAL Overview)

**Key scenarios**:
- Audio route switching (Bluetooth connection)
- Adaptive bitrate video (network degradation)
- UART communication (vehicle CAN bus)

---

### UI_ARCHITECTURE_DOCUMENTATION.md {#ui_architecture_documentation}

**Length**: 2,100 lines  
**Difficulty**: Intermediate  
**Time to read**: 50 minutes  
**Best for**: UI developers, QML developers, designers

**Contents**:
- UI technology stack and architecture
- QML structure and file organization
- WebSocket client lifecycle and integration
- State management patterns
- Responsive design and breakpoints
- Gesture and touch handling
- i18n/localization workflow
- Theme system (light/dark mode)
- Performance optimization
- Testing approaches

**Key Sections**:
```
1. UI Architecture Overview
2. QML Structure
3. WebSocket Client
4. Connection Lifecycle
5. State Management
6. Responsive Design
7. Gesture Handling
8. i18n & Localization
9. Theme System
10. Performance Optimization
11. Testing
12. Common Issues & Solutions
```

**Use when**:
- Developing new UI pages
- Integrating new services with UI
- Implementing responsive layouts
- Adding gesture support
- Debugging UI issues
- Optimizing performance

**Start reading**: Section 2 (QML Structure)

**Key examples**:
- Media player responsive page
- Android Auto button with command sending
- Bluetooth volume knob with rotation

---

### EXTENSION_FRAMEWORK_GUIDE.md {#extension_framework_guide}

**Length**: 2,300 lines  
**Difficulty**: Intermediate  
**Time to read**: 60 minutes  
**Best for**: Extension developers, plugin creators, third parties

**Contents**:
- Extension framework overview
- manifest.json format specification
- Extension lifecycle (DISCOVERY → REMOVED)
- Lifecycle callbacks (initialize, activate, deactivate, shutdown)
- EventBus integration patterns
- Security model and sandboxing
- Complete development workflow
- Step-by-step tutorial
- Testing approaches
- Common extension types (Spotify, Navigation, Messaging)
- Best practices and troubleshooting
- API reference

**Key Sections**:
```
1. Extension Framework Overview
2. Extension Manifest Format
3. Extension Lifecycle
4. EventBus Integration
5. Security Model
6. Development Workflow
7. Creating First Extension (Step-by-step)
8. Testing Extensions
9. Common Extension Types
10. Best Practices
11. Distribution & Publishing
12. Troubleshooting
13. API Reference
```

**Use when**:
- Creating new extension
- Publishing to Extension Store
- Learning extension APIs
- Debugging extension issues
- Understanding permissions system

**Start reading**: Section 1 (Framework Overview)

**Step-by-step guide**: Section 6 & 7 (Development Workflow)

**Key scenarios**:
- Spotify extension startup
- User installs extension
- Extension publishes/subscribes events

---

### DOCUMENTATION_AUDIT_COMPLETION_SUMMARY.md {#completion_summary}

**Length**: 500 lines  
**Difficulty**: Easy  
**Time to read**: 10 minutes  
**Best for**: Project managers, stakeholders, overview

**Contents**:
- What was delivered
- Documentation structure
- Coverage by component
- Quality metrics
- Key learning outcomes
- How to use documentation
- Maintenance plan

**Use when**:
- Reporting project status
- Understanding scope of documentation
- Planning team training

---

### DOCUMENTATION_AUDIT_CHECKLIST.md {#checklist}

**Length**: 600 lines  
**Difficulty**: Easy  
**Time to read**: 15 minutes  
**Best for**: Quality assurance, completeness verification

**Contents**:
- Comprehensive checklist of what's documented
- Status for each component
- Quality metrics
- Validation results
- Sign-off

**Use when**:
- Verifying documentation completeness
- Checking off requirements
- Quality assurance review

---

## Navigation by Role

### Software Developer (New to Crankshaft)

**Week 1: Foundation**
1. Read: [SYSTEM_ARCHITECTURE_OVERVIEW.md](#system_architecture_overview) (Sections 1-3)
2. Read: [CODE_DOCUMENTATION_AUDIT.md](#code_documentation_audit) (Sections 1-5)
3. Task: Understand event flow by tracing example scenario

**Week 2: Specialization**
- **Core Developer**: [CODE_DOCUMENTATION_AUDIT.md](#code_documentation_audit) (Sections 6-10)
- **UI Developer**: [UI_ARCHITECTURE_DOCUMENTATION.md](#ui_architecture_documentation)
- **HAL Developer**: [HAL_COMPREHENSIVE_DOCUMENTATION.md](#hal_comprehensive_documentation)

**Ongoing**: Reference specific sections as needed

### Hardware Integrator / OEM

**Phase 1: Understanding**
1. Read: [SYSTEM_ARCHITECTURE_OVERVIEW.md](#system_architecture_overview) (Sections 1, 5, 7)
2. Read: [HAL_COMPREHENSIVE_DOCUMENTATION.md](#hal_comprehensive_documentation) (Sections 1-5)

**Phase 2: Integration**
1. Reference: HAL documentation for your specific hardware
2. Reference: Transport layer documentation for vehicle communication
3. Reference: Performance metrics for resource planning

### Extension Developer (Third Party)

**Getting Started**
1. Read: [EXTENSION_FRAMEWORK_GUIDE.md](#extension_framework_guide) (Sections 1-2)
2. Read: [CODE_DOCUMENTATION_AUDIT.md](#code_documentation_audit) (Section 8 - EventBus topics)
3. Tutorial: [EXTENSION_FRAMEWORK_GUIDE.md](#extension_framework_guide) (Sections 6-7)

**Development**
1. Reference: [EXTENSION_FRAMEWORK_GUIDE.md](#extension_framework_guide) (Section 4 - EventBus integration)
2. Reference: Common extension type in Section 7

**Publishing**
1. Reference: [EXTENSION_FRAMEWORK_GUIDE.md](#extension_framework_guide) (Section 9 - Distribution)

### UI/UX Designer

**Understanding**
1. Read: [UI_ARCHITECTURE_DOCUMENTATION.md](#ui_architecture_documentation) (Sections 1-2)
2. Reference: [SYSTEM_ARCHITECTURE_OVERVIEW.md](#system_architecture_overview) (Section 1 - context)

**Design Guidelines**
1. Reference: [UI_ARCHITECTURE_DOCUMENTATION.md](#ui_architecture_documentation) (Section 6 - Responsive design)
2. Reference: [UI_ARCHITECTURE_DOCUMENTATION.md](#ui_architecture_documentation) (Section 8 - Theme system)

### System Architect / Tech Lead

**Complete Understanding**
1. Read: All 5 main documentation files
2. Focus on: Design decisions and rationale
3. Reference: Deployment scenarios for planning

**Decision Making**
1. Reference: [SYSTEM_ARCHITECTURE_OVERVIEW.md](#system_architecture_overview) (Section 5 - Technology choices)
2. Reference: [SYSTEM_ARCHITECTURE_OVERVIEW.md](#system_architecture_overview) (Section 8 - Testing strategy)

---

## Quick Reference by Topic

### EventBus & Events

**What it is**: Pub/Sub message hub for inter-service communication  
**Read**: [CODE_DOCUMENTATION_AUDIT.md](#code_documentation_audit) - Section 1.2  
**Scenarios**: 3 detailed examples with timing  
**Code examples**: 5+ examples in C++ and QML  

**Common questions**:
- How do I publish an event? → Section example
- How do I subscribe to events? → QML example in UI_ARCHITECTURE_DOCUMENTATION
- What topics are available? → Full list in CODE_DOCUMENTATION_AUDIT

### Audio System

**What it is**: Multi-route audio HAL with ALSA integration  
**Read**: [HAL_COMPREHENSIVE_DOCUMENTATION.md](#hal_comprehensive_documentation) - Section 2  
**Scenarios**: Bluetooth switching with timing diagram  
**Code examples**: Audio initialization code  

**Common questions**:
- How do I switch audio routes? → Section 2.6
- What audio routes are supported? → Section 2.2
- How do I handle audio underrun? → Section 2.7

### Video Streaming

**What it is**: H.264/H.265 video decoder with adaptive bitrate  
**Read**: [HAL_COMPREHENSIVE_DOCUMENTATION.md](#hal_comprehensive_documentation) - Section 3  
**Scenarios**: Adaptive bitrate with timing  
**Code examples**: Pipeline architecture diagram  

**Common questions**:
- What codecs are supported? → Section 3.3
- How do I optimize latency? → Section 3.5
- How do I handle frame drops? → Section 3.6

### WebSocket Communication

**What it is**: Real-time bidirectional messaging between UI and Core  
**Read**: [CODE_DOCUMENTATION_AUDIT.md](#code_documentation_audit) - Section 1.3  
**Scenarios**: 3 detailed examples with message flow  
**Code examples**: JSON protocol specification  

**Common questions**:
- What's the message format? → Section message examples
- How do I send a command? → Python/JavaScript example
- How do I receive events? → QML Connections example

### Extensions

**What it is**: Plugin system for third-party features  
**Read**: [EXTENSION_FRAMEWORK_GUIDE.md](#extension_framework_guide)  
**Scenarios**: Spotify extension startup  
**Code examples**: manifest.json, main.qml, lifecycle callbacks  

**Common questions**:
- How do I create an extension? → Section 6 (step-by-step)
- What permissions do I need? → manifest.json reference
- How do I test locally? → Section 6.2

### Performance

**What it is**: Resource targets and optimization techniques  
**Read**: [SYSTEM_ARCHITECTURE_OVERVIEW.md](#system_architecture_overview) - Section 7  
**Metrics**: Target vs actual for all key subsystems  

**Common questions**:
- What's the startup time target? → Section 7.1
- How much RAM does it use? → Section 7.2 (Resource Constraints)
- How do I optimize rendering? → [UI_ARCHITECTURE_DOCUMENTATION.md](#ui_architecture_documentation) - Section 9

---

## Document Map

```
SYSTEM_ARCHITECTURE_OVERVIEW.md
├─ Start here for high-level understanding
├─ Reference for design decisions
├─ Deployment scenarios for planning
└─ Technology justification for decisions

CODE_DOCUMENTATION_AUDIT.md
├─ Complete system breakdown
├─ EventBus scenarios and patterns
├─ ServiceManager lifecycle
├─ Reference for debugging
└─ Integration patterns

HAL_COMPREHENSIVE_DOCUMENTATION.md
├─ Audio system deep dive
├─ Video streaming details
├─ Transport protocols
├─ Hardware integration guide
└─ Performance characteristics

UI_ARCHITECTURE_DOCUMENTATION.md
├─ QML structure and patterns
├─ WebSocket client usage
├─ State management
├─ Responsive design
├─ Gesture handling
└─ Theme/i18n system

EXTENSION_FRAMEWORK_GUIDE.md
├─ Plugin development guide
├─ Manifest format specification
├─ Step-by-step tutorial
├─ Best practices
├─ Security model
└─ Distribution guide

DOCUMENTATION_AUDIT_COMPLETION_SUMMARY.md
└─ Project summary and metrics

DOCUMENTATION_AUDIT_CHECKLIST.md
└─ Completeness verification
```

---

## Tips for Efficient Documentation Use

### Bookmark Key Sections

Save these for quick reference:
- [EventBus scenarios](#code_documentation_audit)
- [Audio routing](#hal_comprehensive_documentation)
- [QML structure](#ui_architecture_documentation)
- [Extension manifest](#extension_framework_guide)

### Use Table of Contents

Every document has a detailed TOC - use Ctrl+F to find your topic

### Cross-References

Documents reference each other:
- Architecture → look up specific component in specialized doc
- Extension developing → See EventBus topics in audit document
- UI state management → See event flow in architecture document

### Search Strategy

**Need to know about...?**
- Events: Search CODE_DOCUMENTATION_AUDIT + EXTENSION_FRAMEWORK_GUIDE
- Audio: Search HAL_COMPREHENSIVE_DOCUMENTATION + SYSTEM_ARCHITECTURE
- UI: Search UI_ARCHITECTURE_DOCUMENTATION + SYSTEM_ARCHITECTURE
- Extensions: Search EXTENSION_FRAMEWORK_GUIDE + SYSTEM_ARCHITECTURE

---

## Keeping Documentation Updated

### When Things Change

- **New service added**: Update CODE_DOCUMENTATION_AUDIT (Section 1.2)
- **New HAL interface**: Update HAL_COMPREHENSIVE_DOCUMENTATION (Section 1)
- **API change**: Update EXTENSION_FRAMEWORK_GUIDE (Section 13 - API Reference)
- **Performance improvement**: Update SYSTEM_ARCHITECTURE_OVERVIEW (Section 7)

### Version Control

All documentation is in Git:
```bash
git log docs/*.md                    # See documentation changes
git diff docs/file.md                # See what changed
git blame docs/file.md               # Who changed what
```

---

## Additional Resources

### In This Repository

- `ARCHITECTURE.md` - High-level design (if exists)
- `API.md` - API reference (if exists)
- `README.md` - Project overview
- `CONTRIBUTING.md` - Contribution guidelines

### External References

- Qt 6 Documentation: https://doc.qt.io/qt-6/
- GStreamer Documentation: https://gstreamer.freedesktop.org/documentation/
- ALSA Documentation: https://www.alsa-project.org/wiki/Main_Page
- AASDK: https://github.com/e8johan/aasdk

---

## Getting Help

**Can't find something?**

1. Check table of contents in relevant document
2. Use Ctrl+F to search within document
3. Search all documents (grep/ag command)
4. Check cross-references at top/bottom of documents

**Still stuck?**

1. Check EXTENSION_FRAMEWORK_GUIDE section 12 (Troubleshooting)
2. Check CODE_DOCUMENTATION_AUDIT section 11 (Common Issues)
3. Check UI_ARCHITECTURE_DOCUMENTATION section 11 (Common Issues)

---

**Documentation Project**: Complete ✅  
**Last Updated**: 2025-01-15  
**Total Documentation**: 11,900+ lines  
**Coverage**: 95% of codebase

**Start Reading**: [SYSTEM_ARCHITECTURE_OVERVIEW.md](#system_architecture_overview)
