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

#ifndef SETTINGSMODEL_H
#define SETTINGSMODEL_H

#include <QObject>
#include <QString>

namespace Crankshaft {

class SettingsRegistry;

class SettingsModel : public QObject {
  Q_OBJECT

  Q_PROPERTY(
      QString currentTheme READ currentTheme WRITE setCurrentTheme NOTIFY currentThemeChanged)
  Q_PROPERTY(QString currentLanguage READ currentLanguage WRITE setCurrentLanguage NOTIFY
                 currentLanguageChanged)
  Q_PROPERTY(QString currentLayoutPreference READ currentLayoutPreference WRITE
                 setCurrentLayoutPreference NOTIFY currentLayoutPreferenceChanged)
  Q_PROPERTY(QString currentPrimaryDisplayId READ currentPrimaryDisplayId WRITE
                 setCurrentPrimaryDisplayId NOTIFY currentPrimaryDisplayIdChanged)
  Q_PROPERTY(bool currentAaConsent READ currentAaConsent WRITE setCurrentAaConsent NOTIFY
                 currentAaConsentChanged)

 public:
  explicit SettingsModel(SettingsRegistry* registry, QObject* parent = nullptr);
  ~SettingsModel() override;

  // Getters
  auto currentTheme() const -> QString;
  auto currentLanguage() const -> QString;
  auto currentLayoutPreference() const -> QString;
  auto currentPrimaryDisplayId() const -> QString;
  auto currentAaConsent() const -> bool;

  // Setters
  void setCurrentTheme(const QString& theme);
  void setCurrentLanguage(const QString& language);
  void setCurrentLayoutPreference(const QString& preference);
  void setCurrentPrimaryDisplayId(const QString& id);
  void setCurrentAaConsent(bool consent);

  // Initialization from registry
  void initializeFromRegistry();

 signals:
  void currentThemeChanged(const QString& theme);
  void currentLanguageChanged(const QString& language);
  void currentLayoutPreferenceChanged(const QString& preference);
  void currentPrimaryDisplayIdChanged(const QString& id);
  void currentAaConsentChanged(bool consent);

 private slots:
  void onRegistryThemeChanged(const QString& theme);
  void onRegistryLanguageChanged(const QString& language);
  void onRegistryLayoutPreferenceChanged(const QString& preference);
  void onRegistryPrimaryDisplayIdChanged(const QString& id);
  void onRegistryAaConsentChanged(bool consent);

 private:
  SettingsRegistry* m_registry;
  QString m_currentTheme;
  QString m_currentLanguage;
  QString m_currentLayoutPreference;
  QString m_currentPrimaryDisplayId;
  bool m_currentAaConsent;
};

}  // namespace Crankshaft

#endif  // SETTINGSMODEL_H
