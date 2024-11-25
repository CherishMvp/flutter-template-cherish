//TO DO: add the Apple API key for your app from the RevenueCat dashboard: https://app.revenuecat.com
const appleApiKey = 'appl_PtqavJnfNAcloUOXfiJDbqGOsRp';

//TO DO: add the Google API key for your app from the RevenueCat dashboard: https://app.revenuecat.com
const googleApiKey = 'googl_api_key';

//TO DO: add the Amazon API key for your app from the RevenueCat dashboard: https://app.revenuecat.com
const amazonApiKey = 'amazon_api_key';

const entitlementKey = 'mingji.pro'; //会员通行证字段

// 会员权益对照表
class UploadLimits {
  final int maxImageCount;
  final int maxVideoCount;
  final int maxAudioCount;
  final int maxLivePhotoCount;
  final int maxImageSelectCount;
  final int maxLivePhotoSelectCount;

  const UploadLimits({
    required this.maxImageCount,
    required this.maxVideoCount,
    required this.maxAudioCount,
    required this.maxLivePhotoCount,
    required this.maxImageSelectCount,
    required this.maxLivePhotoSelectCount,
  });
}

const nonMemberLimits = UploadLimits(
  maxImageCount: 3,
  maxVideoCount: 1,
  maxAudioCount: 1,
  maxLivePhotoCount: 2,
  maxImageSelectCount: 2,
  maxLivePhotoSelectCount: 1,
);

const memberLimits = UploadLimits(
  maxImageCount: 30,
  maxVideoCount: 3,
  maxAudioCount: 5,
  maxLivePhotoCount: 5,
  maxImageSelectCount: 10,
  maxLivePhotoSelectCount: 3,
);

/* 
  UploadLimits getUploadLimits(bool isMember) {
  return isMember ? memberLimits : nonMemberLimits;
}

 */