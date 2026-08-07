# Changelog

opencode4のバージョン履歴です。

フォーマットは [Keep a Changelog](https://keepachangelog.com/ja/1.0.0/) に準拠し、バージョニングは [Semantic Versioning](https://semver.org/lang/ja/) に従います。

## [1.0.0] - 2026-08-07

### 追加
- 4ペインのOpenCode AIエージェントグリッド機能
- `SUPER + ]` でのグリッド起動
- オーケストレーターによるタスク分配
- ワーカー間のwire log通信
- Todo サイドバー表示
- `SUPER + [` でのバックグラウンド動作
- `SUPER + W` での全終了
- インストーラー (`install.sh`)
- アンインストーラー (`uninstall.sh`)
- 英語・日本語README

### 対応環境
- Hyprland (omarchy)
- tmux
- opencode
- ターミナル: ghostty, kitty, foot, alacritty
- uwsm-app (オプション)
- Ollama / クラウドプロバイダー

---

## リリース方法

### 手動リリース
```bash
git tag -a v1.1.0 -m "v1.1.0: 新機能の説明"
git push origin v1.1.0
```

### 自動リリース
タグをプッシュするとGitHub Actionsが自動でリリースを作成します。

### バージョン番号のルール
- **メジャー** (X.0.0): 破壊的変更
- **マイナー** (0.X.0): 新機能
- **パッチ** (0.0.X): バグ修正
