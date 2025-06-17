# Git 初心者向け完全マニュアル
## Remimazolam PK/PD Simulator 開発・更新ガイド

---

## 📚 目次
1. [Gitとは何か？](#gitとは何か)
2. [基本概念の理解](#基本概念の理解)
3. [初回セットアップ](#初回セットアップ)
4. [日常的な開発フロー](#日常的な開発フロー)
5. [アップデート・機能追加の手順](#アップデート機能追加の手順)
6. [トラブルシューティング](#トラブルシューティング)
7. [実践例](#実践例)

---

## 🤔 Gitとは何か？

**Git**は、プログラムのソースコードの変更履歴を管理するシステムです。

### なぜGitが必要なのか？

1. **バックアップ**: ファイルの変更履歴をすべて保存
2. **協力**: 複数人で同じプロジェクトを開発
3. **公開**: 作成したソフトウェアを世界中に公開
4. **復元**: 間違いがあっても過去の状態に戻せる

### GitHubとの違い

- **Git**: コンピュータ上のツール（ローカル）
- **GitHub**: インターネット上のサービス（リモート）

---

## 🧠 基本概念の理解

### 重要な用語

| 用語 | 説明 | 例 |
|------|------|-----|
| **Repository（リポジトリ）** | プロジェクトフォルダ全体 | remimazolam-pkpd-simulator |
| **Commit（コミット）** | 変更の保存ポイント | 「バグ修正」「新機能追加」 |
| **Push（プッシュ）** | ローカル → GitHubへアップロード | 自分のPC → インターネット |
| **Pull（プル）** | GitHub → ローカルへダウンロード | インターネット → 自分のPC |
| **Branch（ブランチ）** | 開発の枝分かれ | main（本体）、feature（新機能） |

### ファイルの状態

```
[作業中] → [ステージング] → [コミット] → [GitHub]
   ↓           ↓           ↓         ↓
ファイル編集 → git add → git commit → git push
```

---

## ⚙️ 初回セットアップ

### 1. Gitの設定（初回のみ）

```bash
# 自分の名前とメールアドレスを設定
git config --global user.name "YASUYUKI SUZUKI"
git config --global user.email "suzuki.yasuyuki.hr@ehime-u.ac.jp"

# 設定確認
git config --global --list
```

### 2. GitHub Personal Access Token の作成

1. **GitHubにログイン** → **Settings** → **Developer settings**
2. **Personal access tokens** → **Tokens (classic)**
3. **Generate new token (classic)** をクリック
4. **Note**: 「Remimazolam Development」などの説明を入力
5. **Expiration**: 90 days または No expiration
6. **Select scopes**: ✅ **repo** をチェック
7. **Generate token** をクリック
8. **生成されたトークンをコピー**（⚠️ 一度しか表示されません）

### 3. プロジェクトの初期設定（今回は完了済み）

```bash
# プロジェクトフォルダに移動
cd /Users/ysuzuki/Dropbox/claude_work/remimazolam_shiny_v3.1

# Gitリポジトリとして初期化
git init

# GitHubとの接続設定
git remote add origin https://YOUR_TOKEN@github.com/ysuzuki1978/remimazolam-pkpd-simulator.git
```

---

## 🔄 日常的な開発フロー

### 基本的な流れ

```
1. ファイルを編集
2. 変更をステージング（git add）
3. 変更をコミット（git commit）
4. GitHubにアップロード（git push）
```

### 具体的なコマンド

#### 1. 現在の状況を確認

```bash
# 何が変更されたかを確認
git status

# どこが変更されたかを詳しく確認
git diff
```

#### 2. 変更をステージングに追加

```bash
# 特定のファイルを追加
git add app.R

# 複数ファイルを追加
git add app.R README.md

# すべての変更を追加（注意して使用）
git add .
```

#### 3. 変更をコミット（保存）

```bash
# コミットメッセージと一緒に保存
git commit -m "バグ修正: 時間入力の検証エラーを解決"

# より詳細なメッセージの場合
git commit -m "新機能: V3.2計算エンジンの追加

- 新しい薬物動態計算手法を実装
- UIに選択オプションを追加
- テストケースを更新"
```

#### 4. GitHubにアップロード

```bash
# メインブランチにプッシュ
git push origin main
```

---

## 🚀 アップデート・機能追加の手順

### パターン1: 小さな修正・バグ修正

```bash
# 1. 現在の状況確認
git status

# 2. ファイルを編集（Rコードの修正など）

# 3. 変更を確認
git diff

# 4. 変更をステージング
git add 修正したファイル名

# 5. コミット
git commit -m "バグ修正: 具体的な修正内容"

# 6. アップロード
git push origin main
```

### パターン2: 新機能の追加

```bash
# 1. 現在の状況確認
git status

# 2. 新機能を開発（複数ファイルの変更）

# 3. 段階的にコミット
git add R/new_feature.R
git commit -m "新機能: 基本機能の実装"

git add modules/new_module.R
git commit -m "新機能: UIモジュールの追加"

git add app.R
git commit -m "新機能: メインアプリに統合"

# 4. すべてをアップロード
git push origin main
```

### パターン3: バージョンアップ

```bash
# 1. バージョン番号を更新
# R/constants.R の version = "3.2.0" に変更

# 2. 変更をコミット
git add R/constants.R
git commit -m "Version bump to 3.2.0"

# 3. タグを作成（バージョン管理）
git tag -a v3.2.0 -m "Version 3.2.0 - 新機能追加"

# 4. アップロード（タグも含める）
git push origin main
git push origin v3.2.0
```

---

## 🔧 トラブルシューティング

### よくある問題と解決方法

#### 1. プッシュが拒否される

**エラー:**
```
! [rejected] main -> main (fetch first)
```

**解決方法:**
```bash
# GitHubの最新版を取得してマージ
git pull origin main

# 競合がある場合は手動で解決後
git add 競合ファイル名
git commit -m "競合解決"

# 再度プッシュ
git push origin main
```

#### 2. 認証エラー

**エラー:**
```
Permission denied
```

**解決方法:**
```bash
# Personal Access Tokenを再設定
git remote set-url origin https://YOUR_NEW_TOKEN@github.com/ysuzuki1978/remimazolam-pkpd-simulator.git
```

#### 3. 間違ったコミットをした

**直前のコミットを修正:**
```bash
# コミットメッセージを修正
git commit --amend -m "正しいメッセージ"

# ファイルを追加して再コミット
git add 忘れたファイル
git commit --amend --no-edit
```

#### 4. ファイルを間違って追加した

**ステージングから除外:**
```bash
git reset HEAD ファイル名
```

**コミットを取り消し（ファイルは残る）:**
```bash
git reset --soft HEAD~1
```

---

## 💡 実践例

### 例1: アプリケーションのバグ修正

```bash
# 1. 問題発見: 時間入力でエラーが発生

# 2. ファイルを修正
# modules/patient_input_module.R を編集

# 3. 修正内容を確認
git diff modules/patient_input_module.R

# 4. 変更をステージング
git add modules/patient_input_module.R

# 5. コミット
git commit -m "バグ修正: 時間入力検証の正規表現を修正

- 1桁の時間（例：8:30）が拒否される問題を解決
- 正規表現パターンを ^([0-9]|[0-1][0-9]|2[0-3]):([0-5][0-9])$ に変更"

# 6. アップロード
git push origin main
```

### 例2: 新しい計算手法の追加

```bash
# 1. 新機能開発開始

# 2. 新しい計算エンジンファイルを作成
# R/pk_calculation_engine_v4.R

# 3. 段階的にコミット
git add R/pk_calculation_engine_v4.R
git commit -m "新機能: V4計算エンジンの基本実装"

# 4. データモデルを更新
git add R/data_models.R
git commit -m "新機能: V4結果用データモデル追加"

# 5. UIを更新
git add modules/simulation_module.R
git commit -m "新機能: V4計算エンジン選択UIを追加"

# 6. メインアプリを更新
git add app.R
git commit -m "新機能: V4計算エンジンをメインアプリに統合"

# 7. README更新
git add README.md
git commit -m "ドキュメント: V4計算手法の説明を追加"

# 8. バージョン更新
git add R/constants.R
git commit -m "Version bump to 3.3.0"

# 9. すべてをアップロード
git push origin main

# 10. バージョンタグを作成
git tag -a v3.3.0 -m "Version 3.3.0 - V4計算エンジン追加"
git push origin v3.3.0
```

---

## 📝 良いコミットメッセージの書き方

### 基本ルール

1. **1行目**: 50文字以内の要約
2. **2行目**: 空行
3. **3行目以降**: 詳細説明

### メッセージの種類

| 種類 | 使用例 |
|------|--------|
| **新機能** | `新機能: V3計算エンジンの追加` |
| **バグ修正** | `バグ修正: 時間入力検証エラーを解決` |
| **改善** | `改善: UIの応答性を向上` |
| **ドキュメント** | `ドキュメント: README更新` |
| **リファクタリング** | `リファクタリング: コード構造の整理` |
| **テスト** | `テスト: 新しいテストケース追加` |

### 良い例

```bash
git commit -m "バグ修正: CSV出力時のファイル名エラーを解決

- 患者IDに特殊文字が含まれる場合の処理を改善
- ファイル名の正規化処理を追加
- テストケースを更新"
```

---

## 🔄 定期的なメンテナンス

### 月1回程度

```bash
# 1. リポジトリの状況確認
git log --oneline -10

# 2. 不要なブランチがあれば削除
git branch -d 古いブランチ名

# 3. GitHubのサイズ確認
# https://github.com/ysuzuki1978/remimazolam-pkpd-simulator でリポジトリサイズを確認
```

### バックアップ

```bash
# 重要な節目でタグを作成
git tag -a backup-YYYYMMDD -m "定期バックアップ"
git push origin backup-YYYYMMDD
```

---

## 🆘 緊急時の対応

### プロジェクトを完全に復元

```bash
# 1. 新しいフォルダを作成
mkdir remimazolam_restore
cd remimazolam_restore

# 2. GitHubから最新版をダウンロード
git clone https://github.com/ysuzuki1978/remimazolam-pkpd-simulator.git

# 3. フォルダに移動
cd remimazolam-pkpd-simulator

# 4. Personal Access Tokenを設定
git remote set-url origin https://YOUR_TOKEN@github.com/ysuzuki1978/remimazolam-pkpd-simulator.git
```

---

## 📞 サポート

### 困ったときは

1. **エラーメッセージをコピー**
2. **以下のコマンドで状況確認**:
   ```bash
   git status
   git log --oneline -5
   ```
3. **Claude Codeに相談**するか、GitHub Issuesで質問

### 有用なリンク

- [Git公式ドキュメント](https://git-scm.com/doc)
- [GitHub ヘルプ](https://docs.github.com/ja)
- [Gitチートシート](https://education.github.com/git-cheat-sheet-education.pdf)

---

**🎉 このマニュアルで、安心してGitを使った開発ができるようになります！**