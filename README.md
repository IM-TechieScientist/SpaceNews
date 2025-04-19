# Space News

A Flutter application that provides astronomy news, Random Mars rover images (cuz its cool) and NASA Image of the Day.

## Features

- User profile management with interests
- Latest astronomy news from various sources
- Random images from NASA's Perseverance Mars rover
- Local SharedPreferences caching for Nasa's Image of the Day

## Setup

1. Clone the repository
2. Install Flutter dependencies:
   ```bash
   flutter pub get
   ```

3. API Keys Setup:
   - Get a NASA API key from [NASA API Portal](https://api.nasa.gov/)
   - Get a News API key from [News API](https://newsapi.org/)
   - Replace the API keys in the api_keys.dart file:

4. Run the app:
   ```bash
   flutter run
   ```

## Dependencies

- provider: ^6.0.5 (State management)
- http: ^1.1.0 (API calls)
- cupertino_icons: ^1.0.2 (iOS-style icons)
- shared_preferences: ^2.2.2
- url_launcher: ^6.1.14

## Note

The app uses the following APIs:
- NASA Mars Rover Photos API
- News API

## Screenshots
<div style="display: flex; gap: 10px; flex-wrap: wrap;">
  <img src="https://github.com/user-attachments/assets/cd165d96-c163-4f01-8905-266ad37d8104" width="48%" />
  <img src="https://github.com/user-attachments/assets/0fc5afb3-1496-48a7-b634-44153ecc5637" width="48%" />
  <img src="https://github.com/user-attachments/assets/533f77df-3633-4493-bed6-1e37a9917182" width="48%" />
  <img src="https://github.com/user-attachments/assets/5af19af6-d616-446e-b966-7c5b59a47103" width="48%" />
</div>





