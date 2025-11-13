# parking-manager

parking manager project (Smart Parking Manager) — a sample system for parking reservations, payments, and slot management.

This repository contains:
- backend/ — Node.js + Express server that connects to a MySQL database.
- frontend/ — Flutter application (mobile / desktop / web) that talks to the backend.

This README explains how to install required tools from scratch (Node.js, React tooling, Flutter), set up the database, and run both backend and frontend on Windows (PowerShell). Commands are shown for PowerShell and for common alternative setups (Docker). Adjust usernames/passwords and paths for your environment.

## Table of contents
- Prerequisites
- Install Node.js (Windows)
- Install Flutter (Windows)
- Install MySQL (or run with Docker)
- Project setup — backend
- Project setup — frontend
- Running backend + frontend together
- Emulator / networking notes

## Prerequisites
- A Windows machine with administrative rights (to install tools).
- PowerShell (the examples below use PowerShell syntax).
- Internet access to download SDKs and packages.


## Install Node.js (Windows)
Recommended: install the LTS version from nodejs.org or use nvm-windows if you switch versions frequently.

Option A — Installer (quick):
1. Download the Windows installer (LTS) from https://nodejs.org/ and run it.
2. After installation, open PowerShell and verify:

powershell
node -v
npm -v



## Install Flutter (Windows)
Follow official instructions: https://docs.flutter.dev/get-started/install/windows

Short summary:
1. Download the latest stable Flutter SDK (zip) and extract to a folder, for example C:\src\flutter.
2. Add Flutter to your PATH (PowerShell example — replace the path if different):

powershell
$env:Path += ";C:\src\flutter\bin"
# To persist permanently, add it via System Environment Variables UI or PowerShell/Profile


3. Install Android Studio (for Android emulators) and Android SDK. When installing Android Studio:
	 - Install Android SDK, SDK Platform, and Android SDK Tools via the Android Studio SDK Manager.
	 - Create an AVD (Android Virtual Device) in AVD Manager.
4. Accept Android licenses:

powershell
flutter doctor --android-licenses


5. Verify setup:

powershell
flutter doctor

If flutter doctor reports missing items, follow the suggestions to finish the setup.


## Install MySQL (or run with Docker)
The backend expects a MySQL database named smart_parking_db.

Option A — Install MySQL Server locally (Windows):
1. Download and install MySQL Community Server from https://dev.mysql.com/downloads/mysql/.
2. Remember root password (or create a user for the app).
3. From PowerShell (or MySQL Workbench), create the DB and import schema (see below).

Option B — Use Docker (quick, isolated):

powershell
# run MySQL in docker (example password: my-secret-pw)
docker run --name sp-mysql -e MYSQL_ROOT_PASSWORD=my-secret-pw -e MYSQL_DATABASE=smart_parking_db -p 3306:3306 -d mysql:8


To import the provided SQL schema (when using local MySQL):

powershell
# Run from PowerShell; you'll be prompted for the MySQL password
mysql -u root -p -e "CREATE DATABASE IF NOT EXISTS smart_parking_db;"
mysql -u root -p smart_parking_db < .\backend\smart_parking_db.sql

If using Docker, you can copy/import the SQL into the container or mount a volume at container start.


## 5) Project setup — backend (Node.js)
Path: backend/

What the backend needs:
- Node.js + npm
- MySQL server with database smart_parking_db

Steps (PowerShell):

powershell
cd smart-parking-manager/backend
npm install


Start server (development - auto-restarts on change):

powershell
npm run start
# this runs `nodemon index.js` as defined in package.json


Or run without nodemon:

powershell
node index.js


Default configuration (in code):
- Server port: 3000 (can be overridden with the PORT env var)
- MySQL connection (in backend/index.js) uses:
	- host: localhost
	- user: root
	- password: `` (empty string in the code)
	- database: smart_parking_db

Important: the repository does not include an .env.example file. Create a .env or export environment variables if you want to change DB credentials or port.

Example: run with custom environment variables in PowerShell:

powershell
$env:DB_HOST='localhost'; $env:DB_USER='root'; $env:DB_PASS='my-secret-pw'; $env:DB_NAME='smart_parking_db'; $env:PORT='3000'; npm run start


If you want, you can edit backend/index.js to read these environment variables and use them when creating the MySQL connection.

## Project setup — frontend (Flutter)
Path: smart-parking-manager/frontend/

The Flutter app expects the backend API at http://localhost:3000 in several files (for example lib/screens/home/view_slots_screen.dart and lib/screens/payment/payment_screen.dart).

Steps (PowerShell):

powershell
cd e:/smart-parking-manager-main/smart-parking-manager-main/frontend
flutter pub get
flutter devices   # see available devices/emulators
flutter run -d chrome   # run on web browser
# or
flutter run   # run on the default connected device (emulator or physical)


If you prefer to set the API base URL at runtime (recommended), you can pass a dart-define:

powershell
flutter run --dart-define=API_BASE_URL=http://localhost:3000


Then read it in Dart using:

dart
const apiBaseUrl = String.fromEnvironment('API_BASE_URL', defaultValue: 'http://localhost:3000');


This is useful for switching between emulator/device/production.


## Running backend + frontend concurrently (recommended workflow)
1. Open Terminal A (PowerShell): run the backend

powershell
cd e:/smart-parking-manager-main/smart-parking-manager-main/backend
npm install   # (once)
npm run start


2. Open Terminal B (PowerShell): run the frontend

powershell
cd e:/smart-parking-manager-main/smart-parking-manager-main/frontend
flutter pub get
flutter run


If everything is configured correctly, the Flutter app should make requests to the backend APIs (port 3000) and the backend should reply.


## Emulator / networking notes
- If you run the Flutter app on the Android emulator, localhost inside the emulator refers to the emulator, not your host machine. Use 10.0.2.2:3000 to reach the host's port 3000. The code already shows a commented example at lib/screens/home/view_slots_screen.dart.
- If you run on a physical Android device, use your machine's LAN IP (for example 192.168.1.100:3000) and ensure the backend accepts incoming connections and the Windows firewall allows port 3000.
- For web or desktop targets (Windows, macOS), http://localhost:3000 will normally work.
- Backend includes app.use(cors()) so CORS should not block requests from web targets.


## Common troubleshooting
- Backend won't start: ensure Node.js is installed and npm install finished without errors.
- App can't reach backend: check the backend is running, the port number, firewall, and correct host (use 10.0.2.2 for Android emulator).
- MySQL connection errors: confirm database exists, credentials are correct, and MySQL server is running.