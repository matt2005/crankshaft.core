/*
 * Project: Crankshaft
 * This file is part of Crankshaft project.
 * Copyright (C) 2025 OpenCarDev Team
 *
 *  Crankshaft is free software: you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation; either version 3 of the License, or
 *  (at your option) any later version.
 *
 *  Crankshaft is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with Crankshaft. If not, see <http://www.gnu.org/licenses/>.
 */

#include <QCommandLineParser>
#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>

#include "../../core/services/logging/Logger.h"
#include "AndroidAutoFacade.h"
#include "AudioBridge.h"
#include "ConnectionStateMachine.h"
#include "DeviceManager.h"
#include "ErrorHandler.h"
#include "PreferencesFacade.h"
#include "ServiceProvider.h"
#include "TouchEventForwarder.h"

int main(int argc, char* argv[]) {
    // Create application
    QGuiApplication app(argc, argv);
    app.setApplicationName("Crankshaft Slim UI");
    app.setApplicationVersion("1.0.0");
    app.setOrganizationName("OpenCarDev");
    app.setOrganizationDomain("opencardev.org");

    // Parse command-line arguments
    QCommandLineParser parser;
    parser.setApplicationDescription("Lightweight AndroidAuto UI for Crankshaft");
    parser.addHelpOption();
    parser.addVersionOption();

    QCommandLineOption debugOption(QStringList() << "d" << "debug",
                                   "Enable debug logging (same as SLIM_UI_DEBUG=1)");
    parser.addOption(debugOption);

    QCommandLineOption platformOption(QStringList() << "p" << "platform",
                                      "Qt platform plugin (e.g., eglfs, vnc:port=5900, xcb)",
                                      "platform");
    parser.addOption(platformOption);

    parser.process(app);

    // Configure logging
    bool debugMode = parser.isSet(debugOption) || qEnvironmentVariableIsSet("SLIM_UI_DEBUG");

    if (debugMode) {
        Logger::instance().setLevel(Logger::Level::Debug);
        Logger::instance().infoContext("Main", "Debug logging enabled");
    } else {
        Logger::instance().setLevel(Logger::Level::Info);
    }

    Logger::instance().infoContext(
        "Main", "Starting Crankshaft Slim UI",
        {{"version", "1.0.0"}, {"platform", QGuiApplication::platformName()}});

    // Initialize core services
    ServiceProvider& services = ServiceProvider::instance();
    if (!services.initialize()) {
        Logger::instance().errorContext("Main", "Failed to initialize core services");
        return 1;
    }

    // Create facades (Phase 3)
    AndroidAutoFacade androidAutoFacade(&services);
    DeviceManager deviceManager(&services, &androidAutoFacade);
    AudioBridge audioBridge(&services);
    TouchEventForwarder touchForwarder(&androidAutoFacade, &services);
    ConnectionStateMachine connectionStateMachine(&androidAutoFacade);

    // Create facades (Phase 4)
    PreferencesFacade preferencesFacade(&services);

    // Create error handler (Phase 5)
    ErrorHandler errorHandler;

    // Initialize audio system
    if (!audioBridge.initialize()) {
        Logger::instance().warningContext("Main",
                                          "Audio initialization failed, continuing without audio");
        errorHandler.reportError(ErrorHandler::ErrorCode::AudioBackendUnavailable,
                                 "Audio system initialization failed",
                                 ErrorHandler::Severity::Warning);
    }

    // Create QML engine
    QQmlApplicationEngine engine;

    // Expose services and facades to QML
    engine.rootContext()->setContextProperty("_serviceProvider", &services);
    engine.rootContext()->setContextProperty("_androidAutoFacade", &androidAutoFacade);
    engine.rootContext()->setContextProperty("_deviceManager", &deviceManager);
    engine.rootContext()->setContextProperty("_audioBridge", &audioBridge);
    engine.rootContext()->setContextProperty("_touchForwarder", &touchForwarder);
    engine.rootContext()->setContextProperty("_connectionStateMachine", &connectionStateMachine);
    engine.rootContext()->setContextProperty("_preferencesFacade", &preferencesFacade);
    engine.rootContext()->setContextProperty("_errorHandler", &errorHandler);

    // Load main QML
    const QUrl url(QStringLiteral("qrc:/qml/main.qml"));

    QObject::connect(
        &engine, &QQmlApplicationEngine::objectCreated, &app,
        [url](QObject* obj, const QUrl& objUrl) {
            if (!obj && url == objUrl) {
                Logger::instance().errorContext("Main", "Failed to load QML",
                                                {{"url", url.toString()}});
                QCoreApplication::exit(-1);
            }
        },
        Qt::QueuedConnection);

    engine.load(url);

    if (engine.rootObjects().isEmpty()) {
        Logger::instance().errorContext("Main", "No root QML objects created");
        return -1;
    }

    Logger::instance().infoContext("Main", "Application started successfully");

    // Run application event loop
    int exitCode = app.exec();

    // Cleanup
    Logger::instance().infoContext("Main", "Shutting down", {{"exitCode", exitCode}});
    services.shutdown();

    return exitCode;
}