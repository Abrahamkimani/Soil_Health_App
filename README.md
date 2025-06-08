# Soil Health App 🌱

An Android-based Soil Property Visualization Tool
Built with Flutter • Powered by Microcontroller-based Spectroscopy & Machine Learning

🧭 Overview
The Soil Health App is a smart agricultural tool designed to empower farmers and agronomists with real-time insights into soil nutrient composition. The app interfaces with a custom microcontroller system that captures soil data (NPK, pH, and EC) using optical spectroscopy and other sensors. It then visualizes the data on a mobile interface and uses AI to guide users on appropriate actions to improve soil health.

📱 Features
📊 Live Data Visualization
View real-time measurements of Nitrogen (N), Phosphorus (P), Potassium (K), pH, and Electrical Conductivity (EC).

🤖 AI-Driven Chat Assistant
Tap on any parameter to ask follow-up questions—get instant agronomic insights and soil treatment tips.

🌐 Multi-Language Support
Toggle between English and Kiswahili for wider accessibility.

🖨️ PDF Report Generation
Export your soil test results and analysis as a neatly formatted PDF file for sharing or record-keeping.

🔗 Sensor Connectivity
Automatically connects to your spectroscopy-based microcontroller via USB, Bluetooth, or local network.

🔒 Offline Mode & Fallback Support
Access cached soil data and receive feedback even when temporarily offline.

🔔 Smart Notifications
Alerts users when any soil parameter exceeds normal thresholds, or when it's time for periodic testing.

🧑‍🌾 Use Case
“A farmer in rural Kenya uses the app to scan soil with a handheld spectrometer. The app shows low phosphorus and suggests composting techniques, translated in Kiswahili.”

📦 Tech Stack
Frontend: Flutter

Backend: Microcontroller (Arduino Nano + ESP8266), Machine Learning model (TinyML)

AI Chat: LLM-based assistant (API-driven)

PDF Export: pdf Flutter package

Languages: English & Kiswahili (with dynamic switching)

Data Input: AS726X Spectrometer, NIR sensor, and traditional NPK probes


🚀 Getting Started
Prerequisites
Flutter SDK

Android Studio or VS Code

Arduino-based Soil Sensor Setup (with ESP8266 or serial interface)

Optional: AI API key for chat functionality

# Run the App
bash
Copy
Edit
git clone https://github.com/Abrahamkimani/Soil_Health_App
cd soil-health-app
flutter pub get
flutter run
