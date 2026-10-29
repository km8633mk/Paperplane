# Papierflieger

Ein kleiner 2D-Godot-Prototyp für die Projektarbeit **Creative Game & XR Experience**.

## Spielidee

Ein Papierflieger muss einen Parcours überqueren, Hindernissen ausweichen und Windböen nutzen, um Höhe zu gewinnen. Die Faltform lässt sich jederzeit wechseln:

- **Gleiter:** langsamer, sinkt langsamer und bekommt mehr Auftrieb in Windböen.
- **Düsenflieger:** schneller und schmaler, passt besser durch enge Stellen.

Der Parcours wird **jede Runde zufällig neu gebaut** und hat drei Abschnitte (Einflug, Über den Dächern, Sturmfront), die immer schwerer werden: mehr enge Tore, mehr Hindernisse, mehr Abwinde. Er besteht aus fairen Bausteinen (Böe + Tor, einzelnes Tor, Doppeltor, Hindernis): Nach einem Aufwind liegt das Tor hoch, nach einem Abwind tief, und die Höhe aufeinanderfolgender Tore springt nie zu weit. Zu Beginn jeder Runde nennt das Spiel eine zufällige **Mission**, z. B. „Sammle 4 Briefmarken, 2 Münzen und 3 Federn“ (2 bis 4 pro Sorte), und den Brief zum Briefkasten bringen. Die Sammelobjekte werden jede Runde neu verteilt: frei in der Luft oder in den Lücken der Tore, nie in Wänden oder an Hindernissen. Von jeder Sorte liegen 2 mehr im Level als verlangt. Wer ohne die geforderte Anzahl am Briefkasten ankommt, hat die Mission nicht erfüllt. Enge Tore verlangen die schmale Düsenform. Aufwinde heben den Gleiter stark an und geben einen kurzen Geschwindigkeitsschub; Abwinde (violett) drücken ihn nach unten. Vögel, Ballons und Drachen bewegen sich auf und ab.

Der Spieler hat **3 Leben** (Herzen oben rechts). Nach einem Absturz geht es nach einer Sekunde hinter dem letzten geschafften Tor weiter (Checkpoint); beim dritten Absturz ist Game Over. Der Boden ist nicht tödlich, der Flieger prallt ab. Kurz vor engen (rötlichen) Toren lenkt eine leichte Zielhilfe den Düsenflieger zur Öffnung.

Bei erfüllter Mission gibt es einen Stern pro übrigem Leben. Die Bestzeit wird gespeichert.

## Starten

**Im Editor:**

1. Godot 4.7 öffnen.
2. Im Projektmanager **Importieren** wählen und diese `project.godot` auswählen.
3. Das Projekt starten (F5 oder ▶). Tipp: Im eingebetteten Game-Tab über das ⋮-Menü „Stretch“ wählen, sonst ist das Bild auf hochauflösenden Bildschirmen sehr klein.

**Direkt aus dem Terminal (macOS):**

```
/Applications/Godot.app/Contents/MacOS/Godot --path <Pfad zu diesem Ordner>
```

Als eigenes Fenster skaliert sich das Spiel automatisch passend zum Bildschirm.

## Steuerung

- **W**, **Pfeil hoch** oder **Leertaste antippen:** starten bzw. einen Auftriebsstoß geben
- **Shift** oder **X:** Faltform wechseln
- **Pfeil runter** oder **S** halten: aktiv sinken
- **Pfeil links** oder **A** halten: bremsen (halbe Geschwindigkeit, beschleunigt nach dem Loslassen wieder)
- **R:** jederzeit ganz von vorn beginnen (nach dem Ziel auch Leertaste)
- Gamepad: A = Auftrieb, B/X = Faltform, linke Schultertaste = bremsen, Steuerkreuz runter = sinken, Start = Neustart

## Aufbau

```
autoload/Settings.gd      Spieltempo und Fenstergröße (Autoload)
main/Main.tscn + .gd      Spielablauf (Mission, Leben, Respawn, Ziel, Game Over), verbindet alles über Signale
main/HUD.tscn + .gd       Anzeigen: Status, Missionsfortschritt, Herzen, Zeit, Meldungen, Banner
main/Records.gd           Bestzeit speichern/laden
player/Player.tscn + .gd  Papierflieger: Steuerung, Faltformen, Physik, Kamera, Absturz
course/Course.tscn + .gd  Das Level; sammelt die Signale aller Level-Objekte
course/CourseGenerator.gd baut jede Runde einen neuen zufälligen Parcours aus Bausteinen
course/Gate               Tor aus zwei Wänden; enge Tore lassen nur den Düsenflieger durch
course/Wall.gd            gekachelte Wand (wird vom Tor erzeugt)
course/Gust               Auf- oder Abwind
course/Hazard             Vogel, Ballon, Drachen, Kamin (optional auf und ab)
course/Pickup             Sammelobjekt: Briefmarke, Münze oder Feder
course/PickupSpawner.gd   würfelt die Mission und verteilt die Sammelobjekte zufällig
course/Mailbox            Ziel
course/SectionTrigger     kündigt einen neuen Abschnitt an
audio/Sfx.gd              im Code erzeugte Soundeffekte
```

Tore, Böen und Hindernisse sind eigene Szenen mit Einstellungen im Inspector (z. B. `narrow`, `gap_height`, `strength`, `bob_amplitude`). `CourseGenerator` setzt sie jede Runde zufällig zusammen; Abschnittsmarken und Briefkasten stehen fest in `course/Course.tscn`. Dank `@tool` lassen sich die Bausteine auch einzeln im Editor ansehen und testen.

Level-Objekte kennen den Spielablauf nicht. Sie rufen nur Methoden des Fliegers auf (`hit`, `enter_wind`, `exit_wind`, `steer_towards`) oder senden Signale, die `Course` bündelt und `Main` verarbeitet.

Wichtige Stellschrauben: `GAME_SPEED` in `autoload/Settings.gd`, `NARROW_GAP` und `AIM_ASSIST` in `course/Gate.gd`, Flugwerte oben in `player/Player.gd`, `MAX_LIVES` in `main/Main.gd`, Missionsgröße und Verteilung im Node `PickupSpawner` in `course/Course.tscn`.

## Assets

Alle Spielgrafiken sind Pixel-PNGs in `sprites/` (Flieger, Hintergrund, Hindernisse, Wind, Briefmarke, Münze, Feder, Herzen und Briefkasten). Münze, Feder und Herzen wurden als 16×16-Pixelraster gezeichnet und doppelt skaliert als PNG gespeichert, in der Farbpalette der übrigen Sprites. Die Soundeffekte werden zur Laufzeit im Code synthetisiert (`audio/Sfx.gd`). Es werden keine externen Assets oder Bibliotheken außer der Godot Engine verwendet.
