# Wallpaper

Roland 的交互式 Wallpaper Engine Web 壁纸工程。网页控制层为独立实现；角色素材使用本机 ComfyUI、Z-Image 与 MiniMax H3 生成。

## 功能

- 28 套可选穿搭，按立姿、坐姿、倚卧分类
- 定格、单次播放、轮播、收藏轮播
- 上一套、下一套、随机、收藏
- 声音、音量、亮度、画面比例、自动换装、自动收起
- 键盘快捷键与 Wallpaper Engine 属性回调
- 设置和收藏持久化到 `localStorage`

## 目录

- `index.html` / `styles.css` / `app.js`：Web 壁纸运行时
- `catalog.js`：28 套穿搭目录
- `assets/images/`：4K 定帧、缩略图与可选开场图
- `assets/media/`：WebM 动画
- `tools/`：本地 ComfyUI 批量生成工具

## 本地预览

在仓库目录启动任意静态服务器，例如 `npx serve .`，然后打开提示的本地地址。Wallpaper Engine 直接导入 `project.json` 即可。

