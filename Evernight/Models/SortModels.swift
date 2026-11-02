import SwiftUI

/// 整理页一次「分拣」动作。手势与按钮都归到这里，动效只认它。
enum SortMove: Equatable {
    case delete, next, undo, favorite, album
}

/// 交给卡片区播放的一次操作。`token` 让同一种动作也能被 `.onChange` 认出来；
/// 撤回时额外带上「被撤那张」与「它当初往哪飞」，倒放才有方向。
struct DeckCommand: Equatable {
    let token: Int
    let move: SortMove
    var incoming: PhotoItem?
    var reverseOf: SortMove?

    /// 只比 token：`incoming` 里的 `PHAsset` 没法比较，而 token 已经唯一标识一次操作。
    static func == (lhs: Self, rhs: Self) -> Bool { lhs.token == rhs.token }
}

/// 撤回栈里的一条记录：上一步做了什么 + 涉及的照片 + 操作前的游标。
enum UndoRecord {
    /// 删除：按创建日期把照片插回原月份原位，游标回到删除前
    case deletion(photo: PhotoItem, index: Int)
    /// 下一张：游标退回上一张
    case advance(photo: PhotoItem, index: Int)
    /// 收藏：取消系统收藏，游标不动
    case favorite(photo: PhotoItem)
    /// 存入相簿：从目标相簿移除，游标退回上一张
    case albumAdd(photo: PhotoItem, album: AlbumItem, index: Int)

    /// 撤回时从原方向飞回来的那张；撤收藏没有位移。
    var restorePhoto: PhotoItem? {
        switch self {
        case .deletion(let photo, _): return photo
        case .advance(let photo, _): return photo
        case .albumAdd(let photo, _, _): return photo
        case .favorite: return nil
        }
    }

    /// 当初那次动作，决定倒放时从哪个方向飞回。
    var origin: SortMove {
        switch self {
        case .deletion: return .delete
        case .advance: return .next
        case .favorite: return .favorite
        case .albumAdd: return .album
        }
    }
}

/// 底部操作岛的四个按钮。
enum SortAction: String, CaseIterable, Identifiable {
    case undo, delete, next, album

    var id: String { rawValue }

    var title: String {
        switch self {
        case .undo: "撤回"
        case .delete: "删除"
        case .next: "下一张"
        case .album: "相簿"
        }
    }

    var symbol: String {
        switch self {
        case .undo: "arrow.uturn.backward"
        case .delete: "trash"
        case .next: "forward.end"
        case .album: "photo.stack"
        }
    }

    var color: Color {
        switch self {
        case .undo: Theme.warning
        case .delete: Theme.danger
        case .next: Theme.info
        case .album: Theme.accent
        }
    }
}

/// 整理页顶部的媒体类型筛选（对应参考视频的「照片 ▾」胶囊）。
enum MediaFilter: String, CaseIterable, Identifiable {
    case all = "全部"
    case photo = "照片"
    case video = "视频"
    case live = "实况"

    var id: String { rawValue }

    var symbol: String {
        switch self {
        case .all: "square.grid.2x2"
        case .photo: "photo"
        case .video: "video"
        case .live: "livephoto"
        }
    }

    func matches(_ item: PhotoItem) -> Bool {
        switch self {
        case .all: return true
        case .photo: return !item.isVideo && !item.isLivePhoto
        case .video: return item.isVideo
        case .live: return item.isLivePhoto
        }
    }
}
