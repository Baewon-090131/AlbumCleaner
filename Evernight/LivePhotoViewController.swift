import UIKit
import PhotosUI

// Live Photo 全屏查看器（v2.2.4）
// - 黑底 contain 展示，自动播放一次动态效果
// - 长按持续播放动态，松手停止
// - 点击退出返回整理页
class LivePhotoViewController: UIViewController {

    private let livePhotoView = PHLivePhotoView()

    init(livePhoto: PHLivePhoto) {
        super.init(nibName: nil, bundle: nil)
        livePhotoView.livePhoto = livePhoto
        livePhotoView.contentMode = .scaleAspectFit
        livePhotoView.isUserInteractionEnabled = true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var prefersStatusBarHidden: Bool { true }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black

        livePhotoView.frame = view.bounds
        livePhotoView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(livePhotoView)

        // 单击退出
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        view.addGestureRecognizer(tap)

        // 打开后自动播放一次动态效果（原生相册点开 Live 图的体验）
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { [weak self] in
            self?.livePhotoView.startPlayback(with: .full)
        }
    }

    // 按住播放
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        livePhotoView.startPlayback(with: .full)
    }

    // 松手停止
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        livePhotoView.stopPlayback()
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesCancelled(touches, with: event)
        livePhotoView.stopPlayback()
    }

    @objc private func handleTap() {
        dismiss(animated: true, completion: nil)
    }
}
