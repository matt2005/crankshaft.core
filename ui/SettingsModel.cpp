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

#include "SettingsModel.h"

#include "SettingsRegistry.h"

namespace Crankshaft {

SettingsModel::SettingsModel(SettingsRegistry* registry, QObject* parent)
    : QObject(parent),
      m_registry(registry),
      m_currentTheme("light"),
      m_currentLanguage("en-GB"),
      m_currentLayoutPreference("standard"),
      m_currentPrimaryDisplayId("0"),
      m_currentAaConsent(false) {
  if (m_registry) {
    // Connect to registry signals for reactive updates
    connect(m_registry, &SettingsRegistry::themeChanged, this,
            &SettingsModel::onRegistryThemeChanged);
    connect(m_registry, &SettingsRegistry::languageChanged, this,
            &SettingsModel::onRegistryLanguageChanged);

    // Initialize from registry values
    initializeFromRegistry();
  }
}

SettingsModel::~SettingsModel() = default;

QString SettingsModel::currentTheme() const {
  return m_currentTheme;
}

QString SettingsModel::currentLanguage() const {
  return m_currentLanguage;
}

QString SettingsModel::currentLayoutPreference() const {
  return m_currentLayoutPreference;
}

QString SettingsModel::currentPrimaryDisplayId() const {
  return m_currentPrimaryDisplayId;
}

bool SettingsModel::currentAaConsent() const {
  return m_currentAaConsent;
}

void SettingsModel::setCurrentTheme(const QString& theme) {
  if (m_currentTheme != theme) {
    m_currentTheme = theme;
    if (m_registry) {
      m_registry->setTheme(theme);
    }
    emit currentThemeChanged(theme);
  }
}

void SettingsModel::setCurrentLanguage(const QString& language) {
  if (m_currentLanguage != language) {
    m_currentLanguage = language;
    if (m_registry) {
      m_registry->setLanguage(language);
    }
    emit currentLanguageChanged(language);
  }
}

void SettingsModel::setCurrentLayoutPreference(const QString& preference) {
  if (m_currentLayoutPreference != preference) {
    m_currentLayoutPreference = preference;
    emit currentLayoutPreferenceChanged(preference);
  }
}

void SettingsModel::setCurrentPrimaryDisplayId(const QString& id) {
  if (m_currentPrimaryDisplayId != id) {
    m_currentPrimaryDisplayId = id;
    emit currentPrimaryDisplayIdChanged(id);
  }
}

void SettingsModel::setCurrentAaConsent(bool consent) {
  if (m_currentAaConsent != consent) {
    m_currentAaConsent = consent;
    emit currentAaConsentChanged(consent);
  }
}

void SettingsModel::initializeFromRegistry() {
  if (!m_registry) return;

  m_currentTheme = m_registry->theme();
  m_currentLanguage = m_registry->language();

  emit currentThemeChanged(m_currentTheme);
  emit currentLanguageChanged(m_currentLanguage);
}

void SettingsModel::onRegistryThemeChanged(const QString& theme) {
  if (m_currentTheme != theme) {
    m_currentTheme = theme;
    emit currentThemeChanged(theme);
  }
}

void SettingsModel::onRegistryLanguageChanged(const QString& language) {
  if (m_currentLanguage != language) {
    m_currentLanguage = language;
    emit currentLanguageChanged(language);
  }
}

void SettingsModel::onRegistryLayoutPreferenceChanged(const QString& preference) {
  if (m_currentLayoutPreference != preference) {
    m_currentLayoutPreference = preference;
    emit currentLayoutPreferenceChanged(preference);
  }
}

void SettingsModel::onRegistryPrimaryDisplayIdChanged(const QString& id) {
  if (m_currentPrimaryDisplayId != id) {
    m_currentPrimaryDisplayId = id;
    emit currentPrimaryDisplayIdChanged(id);
  }
}

void SettingsModel::onRegistryAaConsentChanged(bool consent) {
  if (m_currentAaConsent != consent) {
    m_currentAaConsent = consent;
    emit currentAaConsentChanged(consent);
  }
}

}  // namespace Crankshaft
