// lib/common.dart

const String environment =
    String.fromEnvironment('ENVIRONMENT', defaultValue: 'development');
const String baseUrl = String.fromEnvironment('BASE_URL',
    defaultValue: 'https://ai-miniprogram.fancyzh.top');
const String winDevBaseUrl = 'http://192.168.2.9:6066';
const String macDevBaseUrl = 'http://192.168.0.157:6066';
