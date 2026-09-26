import UIKit
import WebKit
import Photos

class ViewController: UIViewController, WKNavigationDelegate, WKUIDelegate, WKScriptMessageHandler, WKURLSchemeHandler {

    var webView: WKWebView!
    private let photoManager = PhotoLibraryManager.shared
    private var hasInjectedData = false

    override func loadView() {
        let config = WKWebViewConfiguration()

        // 注册自定义URLScheme：photo 加载缩略图，video 加载视频/Live 数据流（v2.5 自动播放）
        config.setURLSchemeHandler(self, forURLScheme: "photo")
        config.setURLSchemeHandler(self, forURLScheme: "video")

        // 移除 javaScriptEnabled（iOS 14+ deprecated，默认开启；内容脚本由 allowsContentJavaScript 控制）
        config.preferences.javaScriptCanOpenWindowsAutomatically = true
        if #available(iOS 14.0, *) {
            config.defaultWebpagePreferences.allowsContentJavaScript = true
        }

        // JS桥接
        let userContentController = WKUserContentController()
        userContentController.add(self, name: "photoApp")
        config.userContentController = userContentController

        webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = self
        webView.uiDelegate = self
        webView.scrollView.contentInsetAdjustmentBehavior = .never
        webView.scrollView.bounces = false
        webView.isOpaque = false
        webView.backgroundColor = UIColor(red: 0.95, green: 0.95, blue: 0.97, alpha: 1.0)

        view = webView
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(red: 0.95, green: 0.95, blue: 0.97, alpha: 1.0)

        // 请求照片库权限（无论授权与否都加载网页，JS 层处理无权限状态）
        photoManager.requestAuthorization { [weak self] _ in
            DispatchQueue.main.async {
                self?.loadWebPage()
            }
        }
    }

    private func loadWebPage() {
        guard let url = Bundle.main.url(forResource: "index", withExtension: "html", subdirectory: "WebContent") else {
            print("SLIDEBOX_ERROR: index.html not found in bundle. WebContent missing!")
            return
        }
        let accessURL = url.deletingLastPathComponent()
        webView.loadFileURL(url, allowingReadAccessTo: accessURL)
    }

    // MARK: - 数据注入

    private func injectPhotoData() {
        let assets = photoManager.fetchAllAssets()
        let months = photoManager.groupAssetsByMonth(assets)
        let albums = photoManager.fetchAlbums()

        // v2.3：预缓存最新一批缩略图，进入月份翻页更跟手
        photoManager.prefetchThumbnails(assets)

        // 序列化为JSON
        guard let monthsData = try? JSONSerialization.data(withJSONObject: months, options: []),
              let monthsJSON = String(data: monthsData, encoding: .utf8),
              let albumsData = try? JSONSerialization.data(withJSONObject: albums, options: []),
              let albumsJSON = String(data: albumsData, encoding: .utf8) else {
            return
        }

        let js = """
        if (window.NativeBridge) {
            window.NativeBridge.receiveData({
                months: \(monthsJSON),
                albums: \(albumsJSON)
            });
        }
        """
        webView.evaluateJavaScript(js, completionHandler: nil)
    }

    // MARK: - WKNavigationDelegate

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        // 延迟注入，确保JS桥接已就绪
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            self?.injectPhotoData()
        }
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        print("WebView navigation failed: \(error.localizedDescription)")
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        print("WebView provisional navigation failed: \(error.localizedDescription)")
    }

    // MARK: - WKScriptMessageHandler

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard message.name == "photoApp",
              let body = message.body as? [String: Any],
              let action = body["action"] as? String else { return }

        switch action {
        case "getData":
            injectPhotoData()

        case "deleteAssets":
            if let identifiers = body["identifiers"] as? [String] {
                photoManager.deleteAssets(identifiers) { [weak self] success, _ in
                    self?.callbackToJS("onDeleteComplete", success: success)
                }
            }

        case "setFavorite":
            if let identifier = body["identifier"] as? String,
               let favorite = body["favorite"] as? Bool {
                photoManager.setFavorite(identifier, favorite: favorite) { [weak self] success in
                    self?.callbackToJS("onFavoriteComplete", success: success)
                }
            }

        case "addToAlbum":
            if let assetId = body["assetIdentifier"] as? String,
               let albumId = body["albumIdentifier"] as? String {
                photoManager.addToAlbum(assetId, albumIdentifier: albumId) { [weak self] success in
                    self?.callbackToJS("onAddToAlbumComplete", success: success)
                }
            }

        case "playMedia":
            // 播放视频或 Live Photo（原生全屏，v2.2.4）
            if let identifier = body["identifier"] as? String {
                photoManager.playMedia(identifier)
            }

        case "jsError":
            if let message = body["message"] as? String {
                print("SLIDEBOX_JS: \(message)")
            }

        default:
            break
        }
    }

    private func callbackToJS(_ callback: String, success: Bool) {
        let js = "if (window.NativeBridge) { window.NativeBridge.\(callback)(\(success)); }"
        DispatchQueue.main.async {
            self.webView.evaluateJavaScript(js, completionHandler: nil)
        }
    }

    // MARK: - WKURLSchemeHandler (加载真实照片缩略图)

    // 记录已取消的加载任务，防止回调时重复完成
    private var cancelledTasks: Set<ObjectIdentifier> = []

    // v2.3.2：PNG 数据二级缓存（UIImage 之上再缓存编码后的 PNG Data，
    // 避免每次 photo:// 请求都重复 PNG 编码，删除/切换照片时响应快、不闪黑）
    // totalCostLimit 50MB，NSCache 会自动按内存压力驱逐
    private let pngDataCache: NSCache<NSString, NSData> = {
        let cache = NSCache<NSString, NSData>()
        cache.totalCostLimit = 50 * 1024 * 1024
        return cache
    }()

    func webView(_ webView: WKWebView, start urlSchemeTask: WKURLSchemeTask) {
        let taskID = ObjectIdentifier(urlSchemeTask)
        guard !cancelledTasks.contains(taskID) else { return }

        guard let url = urlSchemeTask.request.url else {
            urlSchemeTask.didFailWithError(NSError(domain: "Scheme", code: -1, userInfo: nil))
            return
        }

        // 完整 identifier 提取（localIdentifier 形如 "UUID/L0/001" 含斜杠，
        // 必须用 absoluteString 保留全量，host 会截断）
        let identifier = url.absoluteString
            .replacingOccurrences(of: "photo://", with: "")
            .replacingOccurrences(of: "video://", with: "")
            .removingPercentEncoding ?? ""

        if url.scheme == "photo" {
            handlePhotoScheme(urlSchemeTask, url: url, identifier: identifier, taskID: taskID)
        } else if url.scheme == "video" {
            handleVideoScheme(urlSchemeTask, url: url, identifier: identifier, taskID: taskID)
        } else {
            urlSchemeTask.didFailWithError(NSError(domain: "Scheme", code: -1, userInfo: nil))
        }
    }

    private func handlePhotoScheme(_ urlSchemeTask: WKURLSchemeTask, url: URL, identifier: String, taskID: ObjectIdentifier) {
        guard let asset = photoManager.asset(for: identifier) else {
            // 返回占位图
            if let placeholderData = UIImage(systemName: "photo")?.pngData() {
                let response = URLResponse(url: url, mimeType: "image/png", expectedContentLength: placeholderData.count, textEncodingName: nil)
                urlSchemeTask.didReceive(response)
                urlSchemeTask.didReceive(placeholderData)
                urlSchemeTask.didFinish()
            } else {
                urlSchemeTask.didFailWithError(NSError(domain: "PhotoScheme", code: -2, userInfo: nil))
            }
            return
        }

        // 请求缩略图：v2.3 使用公共比例尺寸方法（源头保留照片比例，不裁切成方形）
        let targetSize = photoManager.targetSizeForAsset(asset)

        photoManager.requestThumbnail(for: asset, size: targetSize) { [weak self] image in
            // requestThumbnail 保证 completion 在主线程回调
            // （cache hit 同步；cache miss 内部已 DispatchQueue.main.async）
            guard let self = self else { return }
            // 任务已被取消时不再回调
            guard !self.cancelledTasks.contains(taskID) else {
                self.cancelledTasks.remove(taskID)
                return
            }
            guard let image = image else {
                urlSchemeTask.didFailWithError(NSError(domain: "PhotoScheme", code: -3, userInfo: nil))
                return
            }
            // PNG 数据二级缓存：命中直接使用，避免重复 PNG 编码（删除后下一张秒显、不闪黑）
            let cacheKey = "\(identifier)|\(Int(targetSize.width))x\(Int(targetSize.height))" as NSString
            let pngData: Data
            if let cached = self.pngDataCache.object(forKey: cacheKey) {
                pngData = cached as Data
            } else if let encoded = image.pngData() {
                self.pngDataCache.setObject(encoded as NSData, forKey: cacheKey, cost: encoded.count)
                pngData = encoded
            } else {
                urlSchemeTask.didFailWithError(NSError(domain: "PhotoScheme", code: -3, userInfo: nil))
                return
            }
            let response = URLResponse(url: url, mimeType: "image/png", expectedContentLength: pngData.count, textEncodingName: nil)
            urlSchemeTask.didReceive(response)
            urlSchemeTask.didReceive(pngData)
            urlSchemeTask.didFinish()
        }
    }

    // v2.5：video:// 数据流（视频 / Live 自动播放）
    private func handleVideoScheme(_ urlSchemeTask: WKURLSchemeTask, url: URL, identifier: String, taskID: ObjectIdentifier) {
        photoManager.requestVideoData(for: identifier) { [weak self] data, mime in
            guard let self = self else { return }
            guard !self.cancelledTasks.contains(taskID) else {
                self.cancelledTasks.remove(taskID)
                return
            }
            guard let data = data, let mime = mime, !data.isEmpty else {
                urlSchemeTask.didFailWithError(NSError(domain: "VideoScheme", code: -3, userInfo: nil))
                return
            }
            let response = URLResponse(url: url, mimeType: mime, expectedContentLength: data.count, textEncodingName: nil)
            urlSchemeTask.didReceive(response)
            urlSchemeTask.didReceive(data)
            urlSchemeTask.didFinish()
        }
    }

    func webView(_ webView: WKWebView, stop urlSchemeTask: WKURLSchemeTask) {
        // 标记任务为已取消，回调到达时跳过
        cancelledTasks.insert(ObjectIdentifier(urlSchemeTask))
    }

    // MARK: - 状态栏

    override var prefersStatusBarHidden: Bool {
        return false
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        if #available(iOS 13.0, *) {
            return .darkContent
        }
        return .default
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        webView.frame = view.bounds
    }
}
