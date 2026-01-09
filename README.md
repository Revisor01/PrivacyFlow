<p align="center">
  <img src="app-icon.png" alt="PrivacyFlow" width="128" height="128">
</p>

<h1 align="center">PrivacyFlow</h1>

<p align="center">
  Native iOS-App für <a href="https://umami.is">Umami</a> und <a href="https://plausible.io">Plausible</a> Analytics.
</p>

## Features

- **Multi-Account-Unterstützung**: Verwalte mehrere Analytics-Konten in einer App
- **Echtzeit-Dashboard**: Besucher, Seitenaufrufe, Absprungrate und Sitzungsdauer
- **Detaillierte Analysen**: Top-Seiten, Referrer, Geografie, Geräte und Browser
- **Periodenvergleich**: Woche, Monat oder Jahr vergleichen
- **Home-Screen-Widgets**: Schneller Blick auf die wichtigsten Statistiken
- **Push-Benachrichtigungen**: Tägliche oder wöchentliche Zusammenfassungen
- **Offline-Modus**: Gecachte Daten auch ohne Netzwerk verfügbar
- **Dark Mode**: Vollständige Unterstützung für den Dunkelmodus
- **Lokalisierung**: Deutsch und Englisch

## Unterstützte Anbieter

| Anbieter | API | Funktionen |
|----------|-----|------------|
| **Umami** | REST API | Alle Funktionen inkl. Sessions, Journeys, Share-Links |
| **Plausible** | Stats API v2 | Dashboard, Diagramme, Metriken (keine Einzelsitzungen) |

## Voraussetzungen

- iOS 18.0+
- Eigene Umami- oder Plausible-Instanz (Self-Hosted oder Cloud)

## Installation

### App Store

Demnächst verfügbar.

### Selbst kompilieren

1. Repository klonen
2. `PrivacyFlow.xcodeproj` in Xcode öffnen
3. Auf dem Gerät bauen und ausführen

## Konfiguration

1. App starten
2. Analytics-Konto mit URL und API-Zugangsdaten hinzufügen
3. Websites auswählen und Statistiken anzeigen

## Screenshots

*Screenshots folgen*

## Mitwirken

Beiträge sind willkommen! Pull Requests können gerne eingereicht werden.

## Lizenz

Dieses Projekt steht unter der GNU General Public License v3.0 - siehe [LICENSE](LICENSE) für Details.

## Danksagung

- [Umami Analytics](https://umami.is) - Open-Source, datenschutzfreundliche Web-Analytik
- [Plausible Analytics](https://plausible.io) - Einfache, datenschutzfreundliche Analytik

## Hinweis

Dies ist eine inoffizielle Companion-App. PrivacyFlow ist nicht mit Umami Software, Inc. oder Plausible Insights OU verbunden oder von diesen unterstützt.

## Datenschutzerklarung

**Verantwortlicher**

Simon Luthe
Suderstrasse 18
25779 Hennstedt
Deutschland

E-Mail: mail@simonluthe.de
Telefon: +49 151 21563194
Web: simonluthe.de

**Datenverarbeitung**

PrivacyFlow speichert und verarbeitet folgende Daten ausschliesslich lokal auf deinem Gerat:

- URLs deiner Umami- oder Plausible-Instanzen
- API-Zugangsdaten (Token, Benutzername/Passwort) fur die Authentifizierung
- App-Einstellungen und Praferenzen
- Gecachte Analytics-Daten fur den Offline-Modus

Es werden keine Daten an externe Server ubertragen. Die gesamte Kommunikation erfolgt ausschliesslich zwischen deinem iOS-Gerat und deinen konfigurierten Analytics-Instanzen.

**Keine Tracking- oder Analysedienste**

PrivacyFlow verwendet:

- Keine Analytics oder Tracking-Tools
- Keine Werbung
- Keine Cloud-Dienste
- Keine Drittanbieter-SDKs, die Daten sammeln

**Netzwerkverbindungen**

Die App stellt ausschliesslich Verbindungen zu den von dir konfigurierten Analytics-Instanzen (Umami oder Plausible) her.

**Datenspeicherung**

Alle Daten werden lokal in der iOS-Keychain (fur Zugangsdaten) bzw. in den App-Einstellungen gespeichert. Bei Deinstallation der App werden alle Daten vollstandig entfernt.

**Deine Rechte (DSGVO)**

Da alle Daten ausschliesslich lokal auf deinem Gerat gespeichert werden und keine Ubertragung an den Entwickler oder Dritte erfolgt, hast du die volle Kontrolle uber deine Daten. Du kannst diese jederzeit durch Loschen der App vollstandig entfernen.

Bei Fragen zum Datenschutz kannst du dich jederzeit an die oben genannte Kontaktadresse wenden.

**Anderungen**

Diese Datenschutzerklarung kann bei Bedarf aktualisiert werden. Die aktuelle Version ist stets in diesem Repository verfugbar.

Stand: Dezember 2025
