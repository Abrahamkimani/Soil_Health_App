import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';

// This is the place where the code starts or the entry point
void main() {
  runApp(const MyApp());
}

// This sets up the app's theme and title
//statelesswidgets(Its UI does not change ones its build)
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(
    BuildContext context,
  ) // This where I start building the look of the app (What
  // will be showned on the screen)
  {
    return MaterialApp(
      title: 'Soil Sensor Dashboard', // The name of the app
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      home: const SensorDashboard(), //first screen that sows when the app opens
    );
  }
} // This last place of the return is to return the main app layout as Material Design

//This part we have a class now with statefulwidget which means this screen can change while app is running
//The const (super.key) needed for flutter to keep track of widgets
class SensorDashboard
    extends
        StatefulWidget // connects to the state logic where data and updates are handled
        {
  const SensorDashboard({super.key});

  @override
  State<SensorDashboard> createState() => _SensorDashboardState();
}

class _SensorDashboardState extends State<SensorDashboard> {
  double? electricalConductivity;
  double? phosphorus;
  double? potassium;
  double? pH;
  String selectedParameter = '';
  bool isLoading = false;
  String _errorMessage = '';
  bool _isServerAvailable = false;
  bool _isFirstLoad = true;
  bool _isSwahili = false; // Add language state

  final TextEditingController _chatController =
      TextEditingController(); // controls the chatbot inputs
  final List<ChatMessage> _messages = []; //stores the list of chatbot messages

  // Different multiple URLs in order of preference
  final List<String> serverUrls = [
    "http://192.168.137.1:5000/chat", // Laptop's hotspot IP address where server is running
    "http://192.168.137.246:5000/chat", // Phone's IP address
    "http://192.168.1.170:5000/chat", // Laptop's main WiFi IP address
    "http://192.168.1.130:5000/chat", // Alternative laptop IP
    "http://127.0.0.1:5000/chat", // Local testing
    "http://localhost:5000/chat", // Local testing
    "http://10.0.2.2:5000/chat", // Android emulator
  ];

  String get localServerUrl => serverUrls[0]; // Start with the hotspot URL

  final Random _random =
      Random(); //used to generate mock data and chat responses

  // Add Google Sheets URL
  final String googleSheetsUrl =
      "https://script.google.com/macros/s/AKfycbzST1YtS947TUOrRXmQm2rNxL-1mg0eWl2r2PTYSD6aU6by_jWBYHFuUWBBPKUI2IPz/exec";

  // Add translation maps
  final Map<String, Map<String, String>> translations = {
    'Electrical Conductivity': {'en': 'Electrical Conductivity', 'sw': 'Uendeshaji wa Umeme'},
    'Phosphorus': {'en': 'Phosphorus', 'sw': 'Fosforasi'},
    'Potassium': {'en': 'Potassium', 'sw': 'Potasiamu'},
    'Soil pH': {'en': 'Soil pH', 'sw': 'Asidi ya Udongo'},
    'No data': {'en': 'No data', 'sw': 'Hakuna data'},
    'Tap for details': {'en': 'Tap for details', 'sw': 'Gusa kwa maelezo'},
    'Soil Health Monitor': {
      'en': 'Soil Health Monitor',
      'sw': 'Kifaa cha Kufuatilia Afya ya Udongo',
    },
    'Read Sensor': {'en': 'Read Sensor', 'sw': 'Soma Sensor'},
    'Refresh Now': {'en': 'Refresh Now', 'sw': 'Sasisha Sasa'},
    'Download Report': {'en': 'Download Report', 'sw': 'Pakua Ripoti'},
  };

  String translate(String key) {
    return translations[key]?[_isSwahili ? 'sw' : 'en'] ?? key;
  }

  // Add weather related variables
  final TextEditingController _locationController = TextEditingController();
  Map<String, dynamic>? _weatherData;
  bool _isLoadingWeather = false;
  String _weatherError = '';

  // Add weather translations
  final Map<String, Map<String, String>> weatherTranslations = {
    'Enter Location': {'en': 'Enter Location', 'sw': 'Weka Mahali'},
    'Get Weather': {'en': 'Get Weather', 'sw': 'Pata Hali ya Hewa'},
    'Temperature': {'en': 'Temperature', 'sw': 'Joto'},
    'Humidity': {'en': 'Humidity', 'sw': 'Unyevu'},
    'Wind Speed': {'en': 'Wind Speed', 'sw': 'Kasi ya Upepo'},
    'Weather': {'en': 'Weather', 'sw': 'Hali ya Hewa'},
  };

  // Add forecast data variable
  Map<String, dynamic>? _forecastData;

  @override
  void initState() {
    super.initState();
    _refreshSensorData(); //generates mock sensor data
    _checkServerAvailability(); //check if serve is online
  }

  void _showInitialMessage() {
    if (mounted) {
      Future.microtask(() {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Sensor data refreshed!')),
          );
        }
      });
    }
  }

  Future<void> _checkServerAvailability() async {
    print('\n=== Checking Server Availability ===');
    for (String url in serverUrls) {
      try {
        print('Attempting to connect to server at: $url');
        final response = await http
            .get(Uri.parse(url))
            .timeout(const Duration(seconds: 5));
        print('Server response status: ${response.statusCode}');
        print('Server response headers: ${response.headers}');
        print('Server response body: ${response.body}');

        if (response.statusCode == 200) {
          try {
            final responseBody = response.body.trim();
            print('Parsed response body: $responseBody');
            
            // Try to parse as JSON
            final jsonResponse = json.decode(responseBody);
            print('Parsed JSON response: $jsonResponse');
            
            if (jsonResponse['status'] == 'ok') {
              setState(() {
                _isServerAvailable = true;
                _errorMessage = '';
              });
              print('✅ Successfully connected to server at: $url');
              return;
            }
          } catch (e) {
            print('Error parsing response: $e');
          }
        }
      } catch (e) {
        print('❌ Server check error for $url: $e');
        if (e is SocketException) {
          print('Socket error details: ${e.message}');
          print('Address: ${e.address}');
          print('Port: ${e.port}');
        }
      }
    }

    setState(() {
      _isServerAvailable = false;
      _errorMessage = 'Could not connect to server. Using mock responses.';
    });
    print('❌ All server URLs failed. Using mock responses.');
  }

  // Add internet permission check
  Future<bool> _checkInternetConnection() async {
    try {
      final result = await http.get(Uri.parse('https://www.google.com'));
      return result.statusCode == 200;
    } catch (e) {
      print('Internet connection check failed: $e');
      return false;
    }
  }

  Future<void> _fetchSensorData() async {
    int retryCount = 0;
    const maxRetries = 3;
    const timeoutDuration = Duration(seconds: 15); // Increased timeout

    while (retryCount < maxRetries) {
      try {
        print('Fetching data from Google Sheets... (Attempt ${retryCount + 1}/$maxRetries)');
        print('Google Sheets URL: $googleSheetsUrl');
        
        // Try to resolve the host first
        try {
          final result = await InternetAddress.lookup('script.google.com')
              .timeout(const Duration(seconds: 5));
          print('DNS lookup successful: ${result.first.address}');
        } catch (e) {
          print('DNS lookup failed: $e');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Network connection issue. Retrying...'),
                backgroundColor: Colors.orange,
                duration: Duration(seconds: 2),
              ),
            );
          }
          retryCount++;
          if (retryCount < maxRetries) {
            await Future.delayed(const Duration(seconds: 2)); // Wait before retry
            continue;
          }
          _useMockData();
          return;
        }
        
        // Add timeout to the request
        final response = await http.get(Uri.parse(googleSheetsUrl))
            .timeout(timeoutDuration);
        
        print('Google Sheets response status: ${response.statusCode}');
        print('Response headers: ${response.headers}');
        
        if (response.statusCode == 200) {
          print('Successfully received data from Google Sheets');
          final List<dynamic> data = json.decode(response.body);
          print('Number of rows in data: ${data.length}');
          
          if (data.isNotEmpty) {
            // Process the data as before
            DateTime? latestDateTime;
            Map<String, dynamic>? latestReading;
            
            for (var i = data.length - 1; i >= 0; i--) {
              final reading = data[i];
              final dateStr = reading['date']?.toString();
              final timeStr = reading['time']?.toString();
              
              if (dateStr != null && timeStr != null) {
                try {
                  final dateTime = DateTime.parse('$dateStr $timeStr');
                  if (latestDateTime == null || dateTime.isAfter(latestDateTime)) {
                    latestDateTime = dateTime;
                    latestReading = reading;
                    print('Found latest reading at: $dateTime');
                  }
                } catch (e) {
                  print('Error parsing date/time: $e');
                }
              }
            }
            
            if (latestReading != null) {
              print('Processing latest reading: $latestReading');
              setState(() {
                electricalConductivity = double.tryParse(latestReading?['EC']?.toString() ?? '0');
                phosphorus = double.tryParse(latestReading?['Phosphorus']?.toString() ?? '0');
                potassium = double.tryParse(latestReading?['Potassium']?.toString() ?? '0');
                pH = double.tryParse(latestReading?['pH']?.toString() ?? '0');
                
                print('Updated sensor values:');
                print('EC: $electricalConductivity');
                print('Phosphorus: $phosphorus');
                print('Potassium: $potassium');
                print('pH: $pH');
                
                // Get location from the latest reading
                final latitude = latestReading?['latitude']?.toString();
                final longitude = latestReading?['longitude']?.toString();
                
                if (latitude != null && longitude != null) {
                  _getWeatherFromCoordinates(latitude, longitude);
                }
              });
              return;
            }
          }
        } else {
          print('Error response from Google Sheets: ${response.statusCode}');
          print('Response body: ${response.body}');
        }
        
        // If we get here, either the response wasn't 200 or we couldn't process the data
        retryCount++;
        if (retryCount < maxRetries) {
          print('Retrying... (${retryCount + 1}/$maxRetries)');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Retrying connection... (${retryCount + 1}/$maxRetries)'),
                backgroundColor: Colors.orange,
                duration: const Duration(seconds: 2),
              ),
            );
          }
          await Future.delayed(const Duration(seconds: 2)); // Wait before retry
          continue;
        }
        
        print('Using mock data after all retries failed');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not fetch data from Google Sheets. Using mock data.'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 5),
            ),
          );
        }
        _useMockData();
        return;
        
      } catch (e) {
        print('Error fetching sensor data: $e');
        print('Error details: ${e.toString()}');
        
        retryCount++;
        if (retryCount < maxRetries) {
          print('Retrying after error... (${retryCount + 1}/$maxRetries)');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Connection error. Retrying... (${retryCount + 1}/$maxRetries)'),
                backgroundColor: Colors.orange,
                duration: const Duration(seconds: 2),
              ),
            );
          }
          await Future.delayed(const Duration(seconds: 2)); // Wait before retry
          continue;
        }
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error after all retries: ${e.toString()}'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 5),
            ),
          );
        }
        _useMockData();
        return;
      }
    }
  }

  Future<void> _getWeatherFromCoordinates(String latitude, String longitude) async {
    print('\nGetting weather from coordinates:');
    print('Latitude: $latitude');
    print('Longitude: $longitude');
    
    int retryCount = 0;
    const maxRetries = 3;
    const timeoutDuration = Duration(seconds: 15);

    setState(() {
      _isLoadingWeather = true;
      _weatherError = '';
    });

    while (retryCount < maxRetries) {
      try {
        final apiKey = '39ad63e587f94429a3e110940252505';
        final currentUrl = 'https://api.weatherapi.com/v1/current.json?key=$apiKey&q=$latitude,$longitude&aqi=no';
        final forecastUrl = 'https://api.weatherapi.com/v1/forecast.json?key=$apiKey&q=$latitude,$longitude&days=1&aqi=no';

        print('Weather API URLs (Attempt ${retryCount + 1}/$maxRetries):');
        print('Current: $currentUrl');
        print('Forecast: $forecastUrl');

        // Try to resolve the host first
        try {
          final result = await InternetAddress.lookup('api.weatherapi.com')
              .timeout(const Duration(seconds: 5));
          print('DNS lookup successful: ${result.first.address}');
        } catch (e) {
          print('DNS lookup failed: $e');
          retryCount++;
          if (retryCount < maxRetries) {
            print('Retrying weather API connection... (${retryCount + 1}/$maxRetries)');
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Weather API connection issue. Retrying... (${retryCount + 1}/$maxRetries)'),
                  backgroundColor: Colors.orange,
                  duration: const Duration(seconds: 2),
                ),
              );
            }
            await Future.delayed(const Duration(seconds: 2));
            continue;
          }
          throw Exception('Could not resolve weather API hostname');
        }

        // Fetch both current weather and forecast with timeout
        final currentResponse = await http.get(Uri.parse(currentUrl))
            .timeout(timeoutDuration);
        final forecastResponse = await http.get(Uri.parse(forecastUrl))
            .timeout(timeoutDuration);

        print('Current Weather response status: ${currentResponse.statusCode}');
        print('Forecast response status: ${forecastResponse.statusCode}');

        if (currentResponse.statusCode == 200 && forecastResponse.statusCode == 200) {
          final currentData = json.decode(currentResponse.body);
          final forecastData = json.decode(forecastResponse.body);
          
          setState(() {
            _weatherData = currentData;
            _forecastData = forecastData;
            _isLoadingWeather = false;
            // Update location controller with the location name
            final locationName = currentData['location']?['name'];
            print('Location name from weather API: $locationName');
            _locationController.text = locationName ?? 'Current Location';
          });
          return;
        } else {
          final errorData = json.decode(currentResponse.body);
          print('Weather API error response: $errorData');
          retryCount++;
          if (retryCount < maxRetries) {
            print('Retrying weather API request... (${retryCount + 1}/$maxRetries)');
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Weather API error. Retrying... (${retryCount + 1}/$maxRetries)'),
                  backgroundColor: Colors.orange,
                  duration: const Duration(seconds: 2),
                ),
              );
            }
            await Future.delayed(const Duration(seconds: 2));
            continue;
          }
          throw Exception('Failed to get weather data: ${errorData['error']?['message'] ?? 'Unknown error'}');
        }
      } catch (e) {
        print('Weather API error: $e');
        print('Error details: ${e.toString()}');
        
        retryCount++;
        if (retryCount < maxRetries) {
          print('Retrying after weather API error... (${retryCount + 1}/$maxRetries)');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Weather API error. Retrying... (${retryCount + 1}/$maxRetries)'),
                backgroundColor: Colors.orange,
                duration: const Duration(seconds: 2),
              ),
            );
          }
          await Future.delayed(const Duration(seconds: 2));
          continue;
        }
        
        setState(() {
          _weatherError = 'Error: Could not fetch weather data after $maxRetries attempts';
          _isLoadingWeather = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Weather API error: ${e.toString()}'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 5),
            ),
          );
        }
        return;
      }
    }
  }

  // Update the existing _getWeather function to use coordinates if available
  Future<void> _getWeather() async {
    if (_locationController.text.isEmpty) {
      // If no location is entered, try to get weather from the latest sensor reading
      final latestReading = await _getLatestReading();
      if (latestReading != null) {
        final latitude = latestReading['latitude']?.toString();
        final longitude = latestReading['longitude']?.toString();
        if (latitude != null && longitude != null) {
          await _getWeatherFromCoordinates(latitude, longitude);
          return;
        }
      }
      return;
    }

    // If location is entered manually, use that instead
    await _getWeatherFromLocation(_locationController.text);
  }

  Future<Map<String, dynamic>?> _getLatestReading() async {
    try {
      final response = await http.get(Uri.parse(googleSheetsUrl));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        if (data.isNotEmpty) {
          // Find the most recent reading
          for (var i = data.length - 1; i >= 0; i--) {
            final reading = data[i];
            final dateStr = reading['date']?.toString();
            final timeStr = reading['time']?.toString();
            
            if (dateStr != null && timeStr != null) {
              try {
                DateTime.parse('$dateStr $timeStr');
                return reading;
              } catch (e) {
                print('Error parsing date/time: $e');
              }
            }
          }
        }
      }
    } catch (e) {
      print('Error getting latest reading: $e');
    }
    return null;
  }

  Future<void> _getWeatherFromLocation(String location) async {
    setState(() {
      _isLoadingWeather = true;
      _weatherError = '';
    });

    try {
      final apiKey = '39ad63e587f94429a3e110940252505';
      final currentUrl = 'https://api.weatherapi.com/v1/current.json?key=$apiKey&q=$location&aqi=no';
      final forecastUrl = 'https://api.weatherapi.com/v1/forecast.json?key=$apiKey&q=$location&days=1&aqi=no';

      print('Fetching current weather data from: $currentUrl');
      print('Fetching forecast data from: $forecastUrl');

      // Fetch both current weather and forecast
      final currentResponse = await http.get(Uri.parse(currentUrl));
      final forecastResponse = await http.get(Uri.parse(forecastUrl));

      print('Current Weather response status code: ${currentResponse.statusCode}');
      print('Forecast response status code: ${forecastResponse.statusCode}');

      if (currentResponse.statusCode == 200 && forecastResponse.statusCode == 200) {
        final currentData = json.decode(currentResponse.body);
        final forecastData = json.decode(forecastResponse.body);

        setState(() {
          _weatherData = currentData;
          _forecastData = forecastData; // Set forecast data
          _isLoadingWeather = false;
        });
      } else {
        // Handle errors from either response
        String errorMessage = 'Failed to get weather data';
        if (currentResponse.statusCode != 200) {
           final errorData = json.decode(currentResponse.body);
           errorMessage = 'Error (current): ${errorData['error']?['message'] ?? 'Unknown error'}';
        } else if (forecastResponse.statusCode != 200) {
           final errorData = json.decode(forecastResponse.body);
           errorMessage = 'Error (forecast): ${errorData['error']?['message'] ?? 'Unknown error'}';
        }

        setState(() {
          _weatherError = 'Error: $errorMessage';
          _isLoadingWeather = false;
        });
      }
    } catch (e) {
      print('Weather API error: $e');
      setState(() {
        _weatherError = 'Error: $e';
        _isLoadingWeather = false;
      });
    }
  }

  void _useMockData() {
    setState(() {
      // Generate more realistic mock data
      electricalConductivity = 250 + _random.nextDouble() * 150; // Typical EC range: 250-400 µS/cm
      phosphorus = 10 + _random.nextDouble() * 20; // Typical P range: 10-30 mg/kg
      potassium = 150 + _random.nextDouble() * 100; // Typical K range: 150-250 mg/kg
      pH = 6.0 + _random.nextDouble() * 1.5; // Typical pH range: 6.0-7.5
    });
  }

  Future<void> _refreshSensorData() async {
    // First try to fetch real data
    await _fetchSensorData();
    
    if (_isFirstLoad) {
      _isFirstLoad = false;
      _showInitialMessage();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sensor data refreshed!')),
      );
    }
  }

  void _openChatForParameter(String parameter, double? value) {
    setState(() {
      selectedParameter = parameter;
      _messages.clear();
      _messages.add(
        ChatMessage(
          text:
              "Ask me anything about $parameter levels in soil. Current reading: ${_formatValue(parameter, value)}",
          isUser: false,
        ),
      );
      _errorMessage = '';
    });

    _showChatBottomSheet();
  }

  String _formatValue(String parameter, double? value) {
    if (value == null) return "No data";
    if (parameter == "Electrical Conductivity") {
      return "${value.toStringAsFixed(1)} µS/cm";
    } else if (parameter == "Soil pH") {
      return value.toStringAsFixed(2);
    } else {
      return "${value.toStringAsFixed(1)} mg/kg";
    }
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    print('Starting to send message: $text');

    setState(() {
      _messages.add(ChatMessage(text: text, isUser: true));
      _chatController.clear();
      isLoading = true;
      _errorMessage = '';
    });

    int retryCount = 0;
    const maxRetries = 3;
    const timeoutDuration = Duration(seconds: 15);

    while (retryCount < maxRetries) {
      try {
        // Recheck server availability before sending
        print('Checking server availability... (Attempt ${retryCount + 1}/$maxRetries)');
        await _checkServerAvailability();

        if (!_isServerAvailable) {
          print('Server not available, using mock response');
          _sendMockResponse(text);
          return;
        }

        String contextInfo = "The current $selectedParameter reading is: ";
        if (selectedParameter == "Electrical Conductivity") {
          contextInfo += "${electricalConductivity?.toStringAsFixed(1)} µS/cm. This indicates the soil's ability to conduct electricity.";
        } else if (selectedParameter == "Phosphorus") {
          contextInfo += "${phosphorus?.toStringAsFixed(1)} mg/kg. Phosphorus is important for root development.";
        } else if (selectedParameter == "Potassium") {
          contextInfo += "${potassium?.toStringAsFixed(1)} mg/kg. Potassium aids plant health.";
        } else if (selectedParameter == "Soil pH") {
          contextInfo += "${pH?.toStringAsFixed(2)}. pH affects nutrient uptake.";
        }

        print('Sending request to server with context: $contextInfo');
        final requestBody = jsonEncode({
          'context': contextInfo,
          'question': text,
          'temperature': 0.7,
          'max_length': 200,
        });

        print('Request body: $requestBody');

        // Try each URL until one works
        for (String url in serverUrls) {
          try {
            print('Trying to send request to: $url');
            print('Request headers: {"Content-Type": "application/json", "Accept": "application/json"}');
            
            final response = await http
                .post(
                  Uri.parse(url),
                  headers: {
                    'Content-Type': 'application/json',
                    'Accept': 'application/json',
                  },
                  body: requestBody,
                )
                .timeout(timeoutDuration);

            print('Server response status: ${response.statusCode}');
            print('Response headers: ${response.headers}');
            print('Raw response body: ${response.body}');

            if (response.statusCode == 200) {
              try {
                final data = jsonDecode(response.body);
                print('Parsed response data: $data');
                
                // Check if the response has the expected format
                if (data is Map<String, dynamic> && data.containsKey('response')) {
                  final aiResponse = data['response'];
                  print('Extracted AI response: $aiResponse');

                  setState(() {
                    _messages.add(ChatMessage(text: aiResponse, isUser: false));
                    isLoading = false;
                  });
                  return;
                } else {
                  print('Unexpected response format: $data');
                  throw Exception('Unexpected response format from server');
                }
              } catch (e) {
                print('Error parsing response: $e');
                print('Error details: ${e.toString()}');
                retryCount++;
                if (retryCount < maxRetries) {
                  print('Retrying after parse error... (${retryCount + 1}/$maxRetries)');
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error parsing response. Retrying... (${retryCount + 1}/$maxRetries)'),
                        backgroundColor: Colors.orange,
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  }
                  await Future.delayed(const Duration(seconds: 2));
                  continue;
                }
              }
            } else {
              print('Error response from server: ${response.statusCode}');
              print('Error response body: ${response.body}');
            }
          } catch (e) {
            print('Error with $url: $e');
            if (e is SocketException) {
              print('Socket error details: ${e.message}');
              print('Address: ${e.address}');
              print('Port: ${e.port}');
            }
          }
        }

        // If we get here, all URLs failed
        retryCount++;
        if (retryCount < maxRetries) {
          print('All URLs failed. Retrying... (${retryCount + 1}/$maxRetries)');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Connection error. Retrying... (${retryCount + 1}/$maxRetries)'),
                backgroundColor: Colors.orange,
                duration: const Duration(seconds: 2),
              ),
            );
          }
          await Future.delayed(const Duration(seconds: 2));
          continue;
        }

        print('All server URLs failed after $maxRetries attempts, using mock response');
        _sendMockResponse(text);
        return;

      } catch (e) {
        print('Error sending message: $e');
        print('Error details: ${e.toString()}');
        
        retryCount++;
        if (retryCount < maxRetries) {
          print('Retrying after error... (${retryCount + 1}/$maxRetries)');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error. Retrying... (${retryCount + 1}/$maxRetries)'),
                backgroundColor: Colors.orange,
                duration: const Duration(seconds: 2),
              ),
            );
          }
          await Future.delayed(const Duration(seconds: 2));
          continue;
        }

        setState(() {
          _errorMessage = 'Error: Could not connect to server after $maxRetries attempts';
          _isServerAvailable = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${e.toString()}'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 5),
            ),
          );
        }
        _sendMockResponse(text);
        return;
      }
    }
  }

  void _sendMockResponse(String text) {
    setState(() {
      String mockResponse = "This is a mock response about $selectedParameter. ";
      if (selectedParameter == "Electrical Conductivity") {
        mockResponse += "Your current EC level is ${electricalConductivity?.toStringAsFixed(1)} µS/cm. This indicates the soil's ability to conduct electricity.";
      } else if (selectedParameter == "Phosphorus") {
        mockResponse += "Your current phosphorus level is ${phosphorus?.toStringAsFixed(1)} mg/kg. This is suitable for most plants.";
      } else if (selectedParameter == "Potassium") {
        mockResponse += "Your current potassium level is ${potassium?.toStringAsFixed(1)} mg/kg. Consider adding more for flowering plants.";
      } else if (selectedParameter == "Soil pH") {
        mockResponse += "Your current pH is ${pH?.toStringAsFixed(2)}. This is slightly acidic.";
      }

      _messages.add(ChatMessage(text: mockResponse, isUser: false));
      isLoading = false;
    });
  }

  void _showChatBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            top: 10,
            left: 10,
            right: 10,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      "$selectedParameter Information",
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              if (_errorMessage.isNotEmpty)
                Container(
                  color: Colors.red.shade100,
                  padding: const EdgeInsets.all(8),
                  child: Text(
                    _errorMessage,
                    style: TextStyle(color: Colors.red.shade900, fontSize: 12),
                  ),
                ),
              if (!_isServerAvailable)
                Container(
                  color: Colors.orange.shade100,
                  padding: const EdgeInsets.all(8),
                  child: const Text(
                    "Server is not available. Using mock responses.",
                    style: TextStyle(color: Colors.orange, fontSize: 12),
                  ),
                ),
              const Divider(),
              Expanded(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    return MessageBubble(message: _messages[index]);
                  },
                ),
              ),
              const Divider(),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _chatController,
                      decoration: InputDecoration(
                        hintText: "Ask about $selectedParameter...",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      onSubmitted: (text) => _sendMessage(text),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FloatingActionButton(
                    onPressed: () => _sendMessage(_chatController.text),
                    mini: true,
                    child: isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : const Icon(Icons.send),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _chatController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _generateAndDownloadPDF() async {
    try {
      // Request storage permission first
      if (Platform.isAndroid) {
        final status = await Permission.storage.request();
        if (!status.isGranted) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Storage permission is required to save PDF'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }
      }

      final pdf = pw.Document();

      pdf.addPage(
        pw.Page(
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Header(
                  level: 0,
                  child: pw.Text(
                    'Soil Health Report',
                    style: pw.TextStyle(fontSize: 24),
                  ),
                ),
                pw.SizedBox(height: 20),
                pw.Text('Generated on: ${DateTime.now().toString()}'),
                pw.SizedBox(height: 20),
                pw.Table(
                  border: pw.TableBorder.all(),
                  children: [
                    pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8.0),
                          child: pw.Text(
                            'Parameter',
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8.0),
                          child: pw.Text(
                            'Value',
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8.0),
                          child: pw.Text('Electrical Conductivity'),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8.0),
                          child: pw.Text(
                            '${electricalConductivity?.toStringAsFixed(1)} µS/cm',
                          ),
                        ),
                      ],
                    ),
                    pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8.0),
                          child: pw.Text('Phosphorus'),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8.0),
                          child: pw.Text(
                            '${phosphorus?.toStringAsFixed(1)} mg/kg',
                          ),
                        ),
                      ],
                    ),
                    pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8.0),
                          child: pw.Text('Potassium'),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8.0),
                          child: pw.Text(
                            '${potassium?.toStringAsFixed(1)} mg/kg',
                          ),
                        ),
                      ],
                    ),
                    pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8.0),
                          child: pw.Text('Soil pH'),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8.0),
                          child: pw.Text(
                            '${pH?.toStringAsFixed(2)}',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      );

      // Get the external storage directory
      Directory? directory;
      try {
        if (Platform.isAndroid) {
          directory = await getExternalStorageDirectory();
        } else {
          directory = await getApplicationDocumentsDirectory();
        }
      } catch (e) {
        print('Error getting directory: $e');
        directory = await getApplicationDocumentsDirectory();
      }

      if (directory == null) {
        throw Exception('Could not access storage directory');
      }

      final String fileName = 'soil_report_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final String filePath = path.join(directory.path, fileName);
      final file = File(filePath);
      await file.writeAsBytes(await pdf.save());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('PDF report saved to ${directory.path}'),
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'OK',
              onPressed: () {},
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error generating PDF: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildWeatherInfo(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.green.shade700),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.green.shade700),
        ),
        Text(
          value,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildWeatherSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            translate('Weather'),
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.green.shade700,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _locationController,
                  decoration: InputDecoration(
                    hintText: translate('Enter Location'),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _isLoadingWeather ? null : _getWeather,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                child: _isLoadingWeather
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : Text(
                        translate('Get Weather'),
                        style: const TextStyle(color: Colors.white),
                      ),
              ),
            ],
          ),
          if (_weatherError.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                _weatherError,
                style: const TextStyle(color: Colors.red),
              ),
            ),
          if (_weatherData != null) ...[
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildWeatherInfo(
                  translate('Temperature'),
                  '${_weatherData!['current']['temp_c'].toStringAsFixed(1)}°C',
                  Icons.thermostat,
                ),
                _buildWeatherInfo(
                  translate('Humidity'),
                  '${_weatherData!['current']['humidity']}%',
                  Icons.water_drop,
                ),
                _buildWeatherInfo(
                  translate('Wind Speed'),
                  '${_weatherData!['current']['wind_kph']} km/h',
                  Icons.air,
                ),
              ],
            ),
            if (_forecastData != null) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              Text(
                '24-Hour Forecast',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade700,
                ),
              ),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (var hour in _forecastData!['forecast']['forecastday'][0]['hour'])
                      Container(
                        margin: const EdgeInsets.only(right: 12),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.1),
                              spreadRadius: 1,
                              blurRadius: 2,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Text(
                              DateTime.parse(hour['time']).hour.toString().padLeft(2, '0') + ':00',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Image.network(
                              'https:${hour['condition']['icon']}',
                              width: 30,
                              height: 30,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${hour['temp_c'].toStringAsFixed(1)}°C',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '${hour['humidity']}%',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  void _refreshAllData() async {
    // First trigger the sensor reading
    await _fetchSensorData();

    // Then refresh the weather if location is set
    if (_locationController.text.isNotEmpty) {
      _getWeather();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(translate('Soil Health Monitor')),
        backgroundColor: Theme.of(context).colorScheme.primary,
        actions: [
          IconButton(
            icon: Icon(_isSwahili ? Icons.language : Icons.translate),
            onPressed: () {
              setState(() {
                _isSwahili = !_isSwahili;
              });
            },
            tooltip:
                _isSwahili ? 'Switch to English' : 'Badilisha kwa Kiswahili',
            color: Colors.white,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshAllData,
            tooltip: translate('Refresh Now'),
            color: Colors.white,
          ),
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: _generateAndDownloadPDF,
            tooltip: translate('Download Report'),
            color: Colors.white,
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 120.0),
            child: Column(
              children: [
                if (!_isServerAvailable)
                  Container(
                    color: Colors.orange.shade100,
                    padding: const EdgeInsets.all(8),
                    margin: const EdgeInsets.only(bottom: 16),
                    child: const Row(
                      children: [
                        Icon(Icons.warning, color: Colors.orange),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            "Server is not available. Using mock data.",
                            style: TextStyle(color: Colors.orange),
                          ),
                        ),
                      ],
                    ),
                  ),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  childAspectRatio: 1.2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  children: [
                    SensorCard(
                      label: "Electrical Conductivity",
                      value: electricalConductivity,
                      onTap: () => _openChatForParameter("Electrical Conductivity", electricalConductivity),
                      isSwahili: _isSwahili,
                    ),
                    SensorCard(
                      label: "Phosphorus",
                      value: phosphorus,
                      onTap: () => _openChatForParameter("Phosphorus", phosphorus),
                      isSwahili: _isSwahili,
                    ),
                    SensorCard(
                      label: "Potassium",
                      value: potassium,
                      onTap: () => _openChatForParameter("Potassium", potassium),
                      isSwahili: _isSwahili,
                    ),
                    SensorCard(
                      label: "Soil pH",
                      value: pH,
                      onTap: () => _openChatForParameter("Soil pH", pH),
                      isSwahili: _isSwahili,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildWeatherSection(),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _refreshAllData,
        icon: const Icon(Icons.sensors),
        label: Text(translate('Read Sensor')),
        backgroundColor: Colors.green,
      ),
    );
  }
}

class SensorCard extends StatelessWidget {
  final String label;
  final double? value;
  final VoidCallback onTap;
  final bool isSwahili;

  const SensorCard({
    super.key,
    required this.label,
    required this.value,
    required this.onTap,
    this.isSwahili = false,
  });

  String translate(String key) {
    final translations = {
      'Electrical Conductivity': {'en': 'Electrical Conductivity', 'sw': 'Uendeshaji wa Umeme'},
      'Phosphorus': {'en': 'Phosphorus', 'sw': 'Fosforasi'},
      'Potassium': {'en': 'Potassium', 'sw': 'Potasiamu'},
      'Soil pH': {'en': 'Soil pH', 'sw': 'Asidi ya Udongo'},
      'No data': {'en': 'No data', 'sw': 'Hakuna data'},
      'Tap for details': {'en': 'Tap for details', 'sw': 'Gusa kwa maelezo'},
    };
    return translations[key]?[isSwahili ? 'sw' : 'en'] ?? key;
  }

  @override
  Widget build(BuildContext context) {
    String displayValue =
        value == null
            ? translate('No data')
            : label == "Soil pH"
            ? value!.toStringAsFixed(2)
            : label == "Electrical Conductivity"
                ? "${value!.toStringAsFixed(1)} µS/cm"
                : "${value!.toStringAsFixed(1)} mg/kg";

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Card(
        elevation: 4,
        color: Colors.green.shade50,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                translate(label),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(displayValue, style: const TextStyle(fontSize: 16)),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.chat_bubble_outline,
                    size: 16,
                    color: Colors.green,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    translate('Tap for details'),
                    style: const TextStyle(fontSize: 12, color: Colors.green),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ChatMessage {
  final String text;
  final bool isUser;

  ChatMessage({required this.text, required this.isUser});
}

class MessageBubble extends StatelessWidget {
  final ChatMessage message;

  const MessageBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          color: message.isUser ? Colors.green : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          message.text,
          style: TextStyle(color: message.isUser ? Colors.white : Colors.black),
        ),
      ),
    );
  }
}
