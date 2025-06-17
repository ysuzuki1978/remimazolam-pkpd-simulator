# Git 初心者向け完全マニュアル v2.0
## Remimazolam PK/PD Simulator 開発・更新ガイド

---

## 📚 目次
1. [Gitとは何か？](#gitとは何か)
2. [基本概念の理解](#基本概念の理解)
3. [初回セットアップ](#初回セットアップ)
4. [メールアドレスの使い分け設定](#メールアドレスの使い分け設定)
5. [日常的な開発フロー](#日常的な開発フロー)
6. [アップデート・機能追加の手順](#アップデート機能追加の手順)
7. [トラブルシューティング](#トラブルシューティング)
8. [実践例](#実践例)

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

### 1. Gitの基本設定（初回のみ）

```bash
# 自分の名前を設定（全プロジェクト共通）
git config --global user.name "YASUYUKI SUZUKI"

# デフォルトのメールアドレス設定（大学アドレス推奨）
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

## 📧 メールアドレスの使い分け設定

### なぜ使い分けが必要？

1. **プライバシー保護**: 私用のGmailアドレスを公開リポジトリで隠す
2. **プロフェッショナルな印象**: 学術・医療分野では大学アドレスが信頼性高い
3. **組織要件**: 大学や病院のポリシーに準拠

### GitHubでの複数メールアドレス登録

1. **GitHub → Settings → Emails**
2. **Add email address** で両方のアドレスを追加：
   - `ysuzuki1978@gmail.com`（Private用）
   - `suzuki.yasuyuki.hr@ehime-u.ac.jp`（Academic用）
3. **両方とも認証を完了**
4. **Keep my email addresses private** ✅ をチェック

### プロジェクトタイプ別設定

#### パターン1: グローバル設定 + プロジェクト個別設定

```bash
# グローバル設定（デフォルト）- 大学アドレス
git config --global user.email "suzuki.yasuyuki.hr@ehime-u.ac.jp"

# 特定プロジェクトで私用アドレスを使用
cd /path/to/private-project
git config user.email "ysuzuki1978@gmail.com"
```

#### パターン2: ディレクトリ別自動設定（上級者向け）

**~/.gitconfig** ファイルを編集：

```ini
[user]
    name = YASUYUKI SUZUKI
    email = suzuki.yasuyuki.hr@ehime-u.ac.jp

# 私用プロジェクト用ディレクトリ
[includeIf "gitdir:~/personal-projects/"]
    path = ~/.gitconfig-personal

[includeIf "gitdir:~/private/"]
    path = ~/.gitconfig-personal

[includeIf "gitdir:~/hobby/"]
    path = ~/.gitconfig-personal
```

**~/.gitconfig-personal** ファイルを作成：

```ini
[user]
    email = ysuzuki1978@gmail.com
```

### プロジェクトタイプ別の推奨設定

| プロジェクトタイプ | 推奨メールアドレス | 理由 |
|-------------------|-------------------|------|
| **医療・学術研究** | `suzuki.yasuyuki.hr@ehime-u.ac.jp` | 信頼性、組織要件 |
| **教育用ソフトウェア** | `suzuki.yasuyuki.hr@ehime-u.ac.jp` | プロフェッショナル |
| **オープンソース貢献** | `suzuki.yasuyuki.hr@ehime-u.ac.jp` | 学術的背景アピール |
| **個人的な実験** | `ysuzuki1978@gmail.com` | プライバシー保護 |
| **趣味のプロジェクト** | `ysuzuki1978@gmail.com` | 個人アカウント |

### 設定確認コマンド

```bash
# 現在のプロジェクトの設定確認
git config user.email

# グローバル設定確認
git config --global user.email

# プロジェクトのすべての設定確認
git config --list

# 最新コミットの作者情報確認
git log --oneline -1 --pretty=format:"%h %s (%an <%ae>)"
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

# 現在のメール設定確認
git config user.email
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
# 1. 現在の状況・設定確認
git status
git config user.email

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
# 1. 現在の状況・設定確認
git status
git config user.email

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

### パターン4: プロジェクトタイプ変更

```bash
# 学術プロジェクト → 私用プロジェクトに変更する場合

# 1. メールアドレス設定変更
git config user.email "ysuzuki1978@gmail.com"

# 2. 設定確認
git config user.email

# 3. 変更をコミット
git add .
git commit -m "プロジェクト設定: 私用アカウントに変更"

# 4. アップロード
git push origin main
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

#### 3. 間違ったメールアドレスでコミットした

**問題**: 私用プロジェクトで大学アドレスを使ってしまった

**解決方法:**
```bash
# 直前のコミットのメールアドレス修正
git config user.email "ysuzuki1978@gmail.com"
git commit --amend --reset-author --no-edit

# 複数のコミットを修正する場合（上級者向け）
git rebase -i HEAD~3 --exec "git commit --amend --reset-author --no-edit"
```

#### 4. 間違ったコミットをした

**直前のコミットを修正:**
```bash
# コミットメッセージを修正
git commit --amend -m "正しいメッセージ"

# ファイルを追加して再コミット
git add 忘れたファイル
git commit --amend --no-edit
```

#### 5. ファイルを間違って追加した

**ステージングから除外:**
```bash
git reset HEAD ファイル名
```

**コミットを取り消し（ファイルは残る）:**
```bash
git reset --soft HEAD~1
```

#### 6. メールアドレス設定がわからなくなった

**現在の設定確認:**
```bash
# プロジェクト固有の設定
git config user.email

# グローバル設定
git config --global user.email

# すべての設定
git config --list | grep user
```

---

## 💡 実践例

### 例1: 医療アプリのバグ修正（大学アドレス使用）

```bash
# 1. 設定確認
cd ~/medical-projects/remimazolam-simulator
git config user.email
# 出力: suzuki.yasuyuki.hr@ehime-u.ac.jp

# 2. 問題発見: 時間入力でエラーが発生

# 3. ファイルを修正
# modules/patient_input_module.R を編集

# 4. 修正内容を確認
git diff modules/patient_input_module.R

# 5. 変更をステージング
git add modules/patient_input_module.R

# 6. コミット
git commit -m "バグ修正: 時間入力検証の正規表現を修正

- 1桁の時間（例：8:30）が拒否される問題を解決
- 正規表現パターンを ^([0-9]|[0-1][0-9]|2[0-3]):([0-5][0-9])$ に変更
- 医療現場での使用頻度の高い時間形式に対応"

# 7. アップロード
git push origin main
```

### 例2: 個人的な実験プロジェクト（私用アドレス使用）

```bash
# 1. 新しい私用プロジェクト開始
mkdir ~/personal-projects/data-analysis-tool
cd ~/personal-projects/data-analysis-tool

# 2. Gitリポジトリ初期化
git init

# 3. 私用メールアドレス設定
git config user.email "ysuzuki1978@gmail.com"

# 4. 設定確認
git config user.email
# 出力: ysuzuki1978@gmail.com

# 5. 初期ファイル作成
echo "# Personal Data Analysis Tool" > README.md

# 6. 初回コミット
git add README.md
git commit -m "初期コミット: 個人用データ解析ツールプロジェクト開始"

# 7. GitHubリポジトリと連携（私用アカウント）
git remote add origin https://TOKEN@github.com/ysuzuki1978/personal-data-tool.git
git push -u origin main
```

### 例3: プロジェクトの性質変更

```bash
# 学術研究 → 個人的な実験に変更する場合

# 1. 現在の設定確認
git config user.email
# 出力: suzuki.yasuyuki.hr@ehime-u.ac.jp

# 2. 私用アドレスに変更
git config user.email "ysuzuki1978@gmail.com"

# 3. プロジェクト情報更新
echo "注意: このプロジェクトは個人的な実験用です" >> README.md

# 4. 変更をコミット
git add README.md
git commit -m "プロジェクト変更: 個人実験用に移行

- プロジェクトの性質を学術研究から個人実験に変更
- 対応するメールアドレスを私用アドレスに変更"

# 5. アップロード
git push origin main
```

### 例4: 新しい計算手法の追加（大学アドレス使用）

```bash
# 1. 医療用プロジェクトでの作業開始
cd ~/medical-projects/remimazolam-simulator

# 2. 設定確認
git config user.email
# 出力: suzuki.yasuyuki.hr@ehime-u.ac.jp

# 3. 新機能開発開始

# 4. 新しい計算エンジンファイルを作成
# R/pk_calculation_engine_v4.R

# 5. 段階的にコミット
git add R/pk_calculation_engine_v4.R
git commit -m "新機能: V4計算エンジンの基本実装

- Masui 2023年の最新モデルに基づく実装
- より高精度な薬物動態予測アルゴリズム"

# 6. データモデルを更新
git add R/data_models.R
git commit -m "新機能: V4結果用データモデル追加

- SimulationResultV4クラスの実装
- 拡張された結果フォーマット対応"

# 7. UIを更新
git add modules/simulation_module.R
git commit -m "新機能: V4計算エンジン選択UIを追加

- ドロップダウンメニューに新オプション追加
- 計算手法の詳細説明を表示"

# 8. メインアプリを更新
git add app.R
git commit -m "新機能: V4計算エンジンをメインアプリに統合

- V4エンジンの完全統合
- 後方互換性の維持"

# 9. README更新
git add README.md
git commit -m "ドキュメント: V4計算手法の説明を追加

- 新しい計算手法の科学的根拠を記載
- 使用方法とパフォーマンス比較を追加"

# 10. バージョン更新
git add R/constants.R
git commit -m "Version bump to 3.3.0

- V4計算エンジン追加に伴うメジャーアップデート"

# 11. すべてをアップロード
git push origin main

# 12. バージョンタグを作成
git tag -a v3.3.0 -m "Version 3.3.0 - V4計算エンジン追加

- Masui 2023年モデル実装
- 高精度薬物動態予測
- 学術研究用途での使用推奨"

git push origin v3.3.0
```

---

## 📝 良いコミットメッセージの書き方

### 基本ルール

1. **1行目**: 50文字以内の要約
2. **2行目**: 空行
3. **3行目以降**: 詳細説明（必要に応じて）

### メッセージの種類

| 種類 | 使用例 | 適用場面 |
|------|--------|----------|
| **新機能** | `新機能: V3計算エンジンの追加` | 機能追加 |
| **バグ修正** | `バグ修正: 時間入力検証エラーを解決` | 問題修正 |
| **改善** | `改善: UIの応答性を向上` | 既存機能強化 |
| **ドキュメント** | `ドキュメント: README更新` | 文書修正 |
| **設定** | `設定: メールアドレス変更` | 設定変更 |
| **リファクタリング** | `リファクタリング: コード構造の整理` | 構造改善 |
| **テスト** | `テスト: 新しいテストケース追加` | テスト関連 |

### プロジェクトタイプ別のメッセージ例

#### 医療・学術プロジェクト
```bash
# 学術的な内容を意識
git commit -m "バグ修正: 薬物動態計算の精度向上

- deSolve積分アルゴリズムの誤差修正
- 臨床使用時の安全性マージン確保
- Masui 2022年論文の基準に準拠"
```

#### 個人プロジェクト
```bash
# カジュアルでも情報は正確に
git commit -m "新機能: データ可視化チャート追加

- plotlyを使用したインタラクティブグラフ
- 個人分析用途での使いやすさ向上"
```

### 良い例と悪い例

#### ✅ 良い例
```bash
git commit -m "バグ修正: CSV出力時のファイル名エラーを解決

- 患者IDに特殊文字が含まれる場合の処理を改善
- ファイル名の正規化処理を追加
- Windows環境での互換性確保"
```

#### ❌ 悪い例
```bash
git commit -m "fix"
git commit -m "いろいろ修正"
git commit -m "とりあえずコミット"
```

---

## 🔄 定期的なメンテナンス

### 月1回程度

```bash
# 1. リポジトリの状況確認
git log --oneline -10

# 2. メール設定確認
git config user.email

# 3. 不要なブランチがあれば削除
git branch -d 古いブランチ名

# 4. GitHubのサイズ確認
# https://github.com/ysuzuki1978/remimazolam-pkpd-simulator でリポジトリサイズを確認
```

### バックアップ

```bash
# 重要な節目でタグを作成
git tag -a backup-YYYYMMDD -m "定期バックアップ - 月次保存"
git push origin backup-YYYYMMDD
```

### メールアドレス設定の定期確認

```bash
# すべてのプロジェクトのメール設定を確認するスクリプト
cd ~/projects
find . -name ".git" -type d | while read repo; do
    cd "$(dirname "$repo")"
    echo "$(pwd): $(git config user.email)"
    cd - > /dev/null
done
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

# 5. メールアドレス設定（プロジェクトタイプに応じて）
git config user.email "suzuki.yasuyuki.hr@ehime-u.ac.jp"
```

### 設定ファイルのバックアップ

```bash
# Gitの設定をバックアップ
cp ~/.gitconfig ~/.gitconfig.backup.$(date +%Y%m%d)
cp ~/.gitconfig-personal ~/.gitconfig-personal.backup.$(date +%Y%m%d) 2>/dev/null || true
```

---

## 📞 サポート

### 困ったときは

1. **エラーメッセージをコピー**
2. **以下のコマンドで状況確認**:
   ```bash
   git status
   git config user.email
   git log --oneline -5
   ```
3. **設定確認**:
   ```bash
   git config --list | grep user
   ```
4. **Claude Codeに相談**するか、GitHub Issuesで質問

### メールアドレス関連のよくある質問

**Q: 私用アドレスが公開されてしまった場合は？**

A: GitHubの設定で以下を確認：
- Settings → Emails → Keep my email addresses private ✅
- 必要に応じて過去のコミットを修正

**Q: プロジェクトの途中でメールアドレスを変更したい場合は？**

A: 
```bash
git config user.email "新しいアドレス"
git commit --amend --reset-author --no-edit  # 直前のコミットを修正
```

**Q: 複数のGitHubアカウントを使い分けたい場合は？**

A: SSH鍵を使用した高度な設定が必要。別途設定が必要です。

### 有用なリンク

- [Git公式ドキュメント](https://git-scm.com/doc)
- [GitHub ヘルプ](https://docs.github.com/ja)
- [Gitチートシート](https://education.github.com/git-cheat-sheet-education.pdf)
- [GitHubのメール設定ガイド](https://docs.github.com/en/account-and-profile/setting-up-and-managing-your-personal-account-on-github/managing-email-preferences/setting-your-commit-email-address)

---

## 📋 クイックリファレンス

### よく使うコマンド

```bash
# 基本操作
git status                    # 状況確認
git add ファイル名             # ステージング
git commit -m "メッセージ"     # コミット
git push origin main          # アップロード

# 設定確認
git config user.email         # 現在のメール設定
git config --global user.email # グローバル設定

# メール設定変更
git config user.email "新しいアドレス"           # プロジェクト個別
git config --global user.email "新しいアドレス"  # グローバル

# 履歴確認
git log --oneline -5          # 直近5コミット
git log --pretty=format:"%h %s (%an <%ae>)" -5  # 作者情報付き
```

### プロジェクトタイプ別設定チェックリスト

#### 医療・学術プロジェクト
- [ ] `git config user.email "suzuki.yasuyuki.hr@ehime-u.ac.jp"`
- [ ] 詳細なコミットメッセージ
- [ ] 科学的根拠の記載
- [ ] バージョンタグの適切な作成

#### 個人プロジェクト
- [ ] `git config user.email "ysuzuki1978@gmail.com"`
- [ ] プライバシー設定の確認
- [ ] 必要に応じたREADMEの編集

---

**🎉 このマニュアルで、メールアドレスを適切に使い分けながら、安心してGitを使った開発ができるようになります！**