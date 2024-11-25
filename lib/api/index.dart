/// ignore: file_names
class API {
  static const String login = "/api/login";
  // dash-scope/generate
  static const String generateStory = "/api/dash-scope/generate";
  // dash-scope/refresh
  static const String refreshStory = "/api/dash-scope/refresh";
  // location
  static const String getGeoInfo = '/api/location/geocode';
  // weather
  static const String getWeather = '/api/location/weather';
  // 注册
  static const String register = '/api/users-mingji/register';
  // 获取用户信息
  static const String getUserInfo = '/api/userinfo/';
  // 上传
  static const String uploadImage = '/api/upload/image';
  // 获取兑换码
  static const String getExchangeCode = '/api/users-mingji/exchange-code';
  // 核销兑换码
  static const String redeemCode = '/api/users-mingji/redeem-code';
}
