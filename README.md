# IngredientCareApp
Ingredient Care App - This iOS app enables users to scan and analyze food product ingredient lists against a pre-defined JSON list of over 2K categorized list of "Safe", "Use With Caution" and "Potentially Harmful" common food product ingredients. 

Ingredient Care App
Overview
Ingredient Care is an iOS application that helps users identify potentially harmful ingredients in food products. By leveraging camera-based text recognition technology, the app allows users to scan ingredient lists on food packaging and instantly receive safety assessments based on a comprehensive database of safe, conditionally allowed, and potentially harmful ingredients.
Features

Real-time Ingredient Scanning: Capture food product labels with your device camera
Optical Character Recognition (OCR): Automatically extract text from images using Vision framework
Ingredient Analysis: Compare identified ingredients against a database of known safe and harmful substances
Safety Classification: Ingredients are categorized as:

✅ Safe
⚠️ Use with caution
❌ Potentially harmful
❓ Unknown


Scan History: Save and review previous scans with date, image, and analysis
Multi-Camera Support: Switch between available device cameras for optimal scanning
Accessible UI: Clean, intuitive interface with clear visual indicators

Screenshots
<div style="display: flex; justify-content: space-between;">
  <img src="/api/placeholder/180/320" alt="Home Screen" />
  <img src="/api/placeholder/180/320" alt="Camera Screen" />
  <img src="/api/placeholder/180/320" alt="Results Screen" />
</div>
Technical Details
Requirements

iOS 16.0+
Swift 5.9+
Xcode 15.0+

Frameworks Used

SwiftUI
AVFoundation
Vision
Photos

Architecture
The app follows a clean architecture with separation of concerns:

Model: Data structures and business logic (IngredientModel)
View: User interface components (ContentView, CameraView, ResultsView)
ViewModel: Data processing and state management
Managers: Hardware and service coordination (CameraCaptureManager)
Storage: Persistence of scan data (ScanResultStore)

Installation

Clone the repository:

bashgit clone https://github.com/yourusername/IngredientCareApp.git

Open the project in Xcode:

bashcd IngredientCareApp
open IngredientCareApp.xcodeproj

Select your development team in the Signing & Capabilities tab
Build and run the application on your device/simulator

Usage

Launch the app and grant camera permissions when prompted
Tap "Scan Ingredients" to open the camera view
Hold your device steady and frame the ingredient list in view
Tap the capture button to scan and analyze the text
Review the analyzed ingredients with their safety classifications
Save the scan or scan again as needed
Access your scan history via the "Saved Scans" button

Database Information
The app uses a comprehensive ingredient database divided into three categories:

Safe Ingredients: Common ingredients with no known health concerns
Conditionally Allowed: Ingredients that may cause issues for some people or in certain quantities
Harmful Ingredients: Substances with documented health risks

The database is stored in JSON format and can be updated with new ingredients as needed.
Contributing
Contributions to improve Ingredient Care are welcome:

Fork the repository
Create a feature branch (git checkout -b feature/your-feature)
Commit your changes (git commit -m 'Add some feature')
Push to the branch (git push origin feature/your-feature)
Open a Pull Request

Please ensure your code follows the project's style guidelines and includes appropriate tests.
Future Enhancements

Customizable ingredient concerns (allergies, dietary restrictions)
Barcode scanning for product identification
Expanded ingredient database
Offline recognition capability
Sharing functionality for scan results
Nutrition information analysis
Product alternatives suggestions

License
This project is licensed under the MIT License - see the LICENSE file for details.
Acknowledgements

Vision Framework - For text recognition capabilities
Food safety organizations and research for ingredient safety classifications
