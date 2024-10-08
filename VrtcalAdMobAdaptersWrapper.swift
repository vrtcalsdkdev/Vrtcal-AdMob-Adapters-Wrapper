import Vrtcal_Adapters_Wrapper_Parent
import GoogleMobileAds

extension GADAdapterInitializationState: CustomStringConvertible {
    public var description: String {
        switch self {
            case .notReady:
                return "notReady"
            case .ready:
                return "ready"
            default:
                return "Unknown"
        }
    }
}

// Must be NSObject for GADBannerViewDelegate
class VrtcalAdMobAdaptersWrapper: NSObject, AdapterWrapperProtocol {
    
    var appLogger: Logger
    var sdkEventsLogger: Logger
    var sdk = SDK.adMob
    var delegate: AdapterWrapperDelegate
    
    var gadInterstitialAd: GADInterstitialAd?
    
    required init(
        appLogger: Logger,
        sdkEventsLogger: Logger,
        delegate: AdapterWrapperDelegate
    ) {
        self.appLogger = appLogger
        self.sdkEventsLogger = sdkEventsLogger
        self.delegate = delegate
    }
    
    func initializeSdk() {
        self.appLogger.log()
        
        
        GADMobileAds.sharedInstance().requestConfiguration.testDeviceIdentifiers = [
            "bc8b2db6f176d262669c7768ea6ea2e5", // Scott iPhone 11
            "bd799f83fd95f07a2719d1bb226c76ca", // Scott iPhone XR
            "54829330cdb5c96af35c5e9477a3ee6c", // Dennis Vrtcal iPad
            "67cb2ecd3963bd12c15b0362eddffe24", // Dennis iPhone 13 Mini
            "4577c0cb42fe35e076890115cbe624e3"  // Dennis iPhone 12
        ]

        GADMobileAds.sharedInstance().start { gadInitializationStatus in
            
            
            let adapterStatusesByClassName = gadInitializationStatus.adapterStatusesByClassName.map { adapter in
                let strName = adapter.key
                let gadAdapterStatus = adapter.value
                let status = gadAdapterStatus.state
                
                if status == .ready {
                    return "\(strName): ✅"
                } else {
                    let reason = gadAdapterStatus
                        .description
                        .substring(fromLast:";")?
                        .replacingOccurrences(of: ">", with: "") ?? ""
                    return "\(strName): ❌, \(reason)"
                }
            }
            .sorted()
            .joined(separator: "\n")
            
            self.sdkEventsLogger.log("GADMobileAds init complete. adapterStatusesByClassName: \n\(adapterStatusesByClassName)")
        }
    }
    
    func handle(adTechConfig: AdTechConfig) {
        
        switch adTechConfig.placementType {
            case .banner:
                appLogger.log("Google Mobile Ads Banner - VRTGADMediationBannerAd")
                var gadSize = GADAdSize()
                gadSize.size = CGSize(width:320,height:50)
                let gadBannerView = GADBannerView(adSize: gadSize)
                gadBannerView.adUnitID = adTechConfig.adUnitId
                gadBannerView.rootViewController = delegate.viewController
                gadBannerView.delegate = self
                delegate.adapterWrapperDidProvide(banner: gadBannerView)
                gadBannerView.load(GADRequest())

            case .interstitial:
                appLogger.log("Google Mobile Ads Interstitial - VRTGADCustomEventInterstitial")
                
                let gadRequest = GADRequest()
                GADInterstitialAd.load(
                    withAdUnitID: adTechConfig.adUnitId,
                    request: gadRequest
                ) { gadInterstitialAd, error in

                    //Failure
                    guard let unwrappedGadInterstitialAd = gadInterstitialAd else {
                        self.sdkEventsLogger.log("GADInterstitialAd failed to load. Error: \(String(describing: error))")
                        return
                    }
                    
                    //Success
                    unwrappedGadInterstitialAd.fullScreenContentDelegate = self
                    self.gadInterstitialAd = unwrappedGadInterstitialAd
                    self.sdkEventsLogger.log("GADInterstitialAd loaded")
                }
                
            case .rewardedVideo:
                fatalError("rewardedVideo not supported for Google Mobile Ads")
                
            case .showDebugView:
                appLogger.log("GMA doesn't have a debug view")
        }
    }
    
    func showInterstitial() -> Bool {
        appLogger.log()
        //Google Mobile Ads
        if let gadInterstitialAd {
            gadInterstitialAd.present(fromRootViewController: delegate.viewController)
            return true
        }
        
        return false
    }
    
    func destroyInterstitial() {
        gadInterstitialAd = nil
    }
}

extension VrtcalAdMobAdaptersWrapper: GADBannerViewDelegate {
    
    //MARK: - GADBannerViewDelegate
    func bannerViewDidReceiveAd(_ bannerView: GADBannerView) {
        sdkEventsLogger.log("AdMob bannerViewDidReceiveAd")
    }
    
    func bannerView(_ bannerView: GADBannerView, didFailToReceiveAdWithError error: Error) {
        appLogger.log("error: \(error)")
        sdkEventsLogger.log("AdMob bannerViewDidFailToReceiveAdWithError")
    }
    
    func bannerViewWillPresentScreen(_ bannerView: GADBannerView) {
        sdkEventsLogger.log("AdMob bannerViewWillPresentScreen")
    }
    
    func bannerViewWillDismissScreen(_ bannerView: GADBannerView) {
        sdkEventsLogger.log("AdMob bannerViewWillDismissScreen")
    }
    
    func bannerViewDidDismissScreen(_ bannerView: GADBannerView) {
        sdkEventsLogger.log("AdMob bannerViewDidDismissScreen")
    }
    
    func bannerViewDidRecordImpression(_ bannerView: GADBannerView) {
        sdkEventsLogger.log("AdMob bannerViewDidRecordImpression")
    }
    
    func bannerViewDidRecordClick(_ bannerView: GADBannerView) {
        sdkEventsLogger.log("AdMob bannerViewDidRecordClick")
    }
}
    
extension VrtcalAdMobAdaptersWrapper : GADFullScreenContentDelegate {
    
    //MARK: - GADInterstitialDelegate
    func adDidRecordImpression(_ ad: GADFullScreenPresentingAd) {
        sdkEventsLogger.log("AdMob adDidRecordImpression")
    }

    func ad(_ ad: GADFullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        sdkEventsLogger.log("AdMob ad didFailToPresentFullScreenContentWithError")
    }

    func adWillPresentFullScreenContent(_ ad: GADFullScreenPresentingAd) {
        sdkEventsLogger.log("AdMob adWillPresentFullScreenContent")
    }

    func adWillDismissFullScreenContent(_ ad: GADFullScreenPresentingAd) {
        sdkEventsLogger.log("AdMob adWillDismissFullScreenContent")
    }

    func adDidDismissFullScreenContent(_ ad: GADFullScreenPresentingAd) {
        sdkEventsLogger.log("AdMob adDidDismissFullScreenContent")
    }
}



extension String {
    func substring(fromLast: String) -> String? {
        guard let substring = self.components(separatedBy: fromLast).last else {
            return nil
        }
        
        return String(substring)
    }
}
