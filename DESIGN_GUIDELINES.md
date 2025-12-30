# MyEmby 设计规范

## 🎨 页面背景色规范

### ⚪️ 白色背景主题

**规定日期**: 2025-12-30
**状态**: ✅ 生效中

#### 基本原则

> **所有新建页面的背景色默认使用白色**

#### 颜色定义

```swift
// 主背景色
Color.white              // 纯白背景

// 次要背景色（卡片、分组等）
Color.gray.opacity(0.2)  // 浅灰背景（白色主题）
```

#### 文字颜色规范

```swift
// 主要文字
.foregroundColor(.black)        // 黑色（明确）
.foregroundColor(.primary)      // 主色（自动适配）

// 次要文字
.foregroundColor(.secondary)    // 次色（自动适配）

// 特殊文字
.foregroundColor(.gray)         // 灰色（占位符等）
```

#### 按钮样式

```swift
// 返回按钮
Circle()
    .fill(Color.white.opacity(0.9))
    .shadow(radius: 2)

// 图标颜色
.foregroundColor(.black)  // 深色图标
```

#### 已更新页面清单

| 页面 | 背景色 | 状态 | 更新日期 |
|------|--------|------|---------|
| MediaDetailView | 白色 | ✅ | 2025-12-30 |
| HomeView | 黑色 | ⚠️ 待更新 | - |
| LoginView | 待定 | ⚠️ 待确认 | - |

## 📋 组件色彩规范

### 卡片和容器

```swift
// 卡片背景
Color.white  // 白色卡片

// 占位符背景
Color.gray.opacity(0.2)  // 浅灰
```

### 交互元素

```swift
// 按钮背景
Color.blue              // 主按钮蓝色
Color.gray.opacity(0.2) // 次按钮浅灰

// 图标颜色
Color.primary           // 主要图标（深色）
Color.secondary         // 次要图标（灰色）
Color.red               // 收藏状态
Color.blue              // 播放状态
```

### 渐变和覆盖层

```swift
// 模糊背景覆盖层
LinearGradient(
    colors: [
        Color.black.opacity(0),       // 透明
        Color.black.opacity(0.3),     // 半透明
        Color.black.opacity(0.8)      // 深色
    ]
)
```

## 🎯 创建新页面时的检查清单

- [ ] 背景色使用 `Color.white`
- [ ] 主要文字使用 `.foregroundColor(.primary)` 或 `.black`
- [ ] 次要文字使用 `.foregroundColor(.secondary)`
- [ ] 按钮和卡片使用浅灰背景 `Color.gray.opacity(0.2)`
- [ ] 返回按钮使用白色圆形背景 + 阴影
- [ ] 占位符使用 `Color.gray.opacity(0.2)`

## 📝 示例代码

### 标准页面模板

```swift
struct NewView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // 内容区域
                contentSection
            }
            .background(Color.white)  // 白色背景
        }
        .ignoresSafeArea()
    }

    private var contentSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("标题")
                .font(.headline)
                .foregroundColor(.black)  // 主要文字

            Text("描述内容")
                .font(.body)
                .foregroundColor(.secondary)  // 次要文字
        }
        .padding()
    }
}
```

### 返回按钮标准

```swift
private var backButton: some View {
    Button(action: {
        NavigationManager.shared.goBack()
    }) {
        ZStack {
            Circle()
                .fill(Color.white.opacity(0.9))
                .shadow(radius: 2)
                .frame(width: 44, height: 44)

            Image(systemName: "chevron.left")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.black)
        }
        .padding(.leading, 16)
        .padding(.top, 8)
    }
}
```

## 🔄 更新记录

| 日期 | 更新内容 | 操作人 |
|------|---------|--------|
| 2025-12-30 | 创建设计规范文档，规定白色为默认页面背景色 | Claude |
| 2025-12-30 | 更新 MediaDetailView 为白色背景主题 | Claude |

---

**注意**: 以后所有新建页面必须遵循此设计规范！⚠️
