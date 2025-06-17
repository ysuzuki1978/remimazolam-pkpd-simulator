# Remimazolam PK/PD Simulator Shiny Application

レミマゾラムの薬物動態・薬力学シミュレーション用のモダンなShinyアプリケーションです。Masui 2022年の母集団薬物動態モデルに基づいて、個別化された薬物動態パラメータを用いた高精度シミュレーションを提供します。

## 📋 目次

- [特徴](#特徴)
- [必要環境](#必要環境)
- [インストール](#インストール)
- [使用方法](#使用方法)
- [アプリケーション構造](#アプリケーション構造)
- [カスタマイズ](#カスタマイズ)
- [トラブルシューティング](#トラブルシューティング)
- [開発者向け情報](#開発者向け情報)

## ✨ 特徴

### 🎯 核心機能
- **個別化薬物動態計算**: 患者特性に基づくパラメータ調整
- **高精度数値積分**: 4次Runge-Kutta法による正確なシミュレーション
- **リアルタイム可視化**: インタラクティブな濃度推移グラフ
- **データエクスポート**: CSV形式での結果出力

### 🎨 ユーザーインターフェース
- **レスポンシブデザイン**: モバイル・タブレット対応
- **モダンUI**: Bootstrap 5 + bslibテーマ
- **直感的操作**: ドラッグ&ドロップ、ライブバリデーション
- **多言語対応**: 日本語インターフェース

### 🔧 技術的特徴
- **モジュラー設計**: 再利用可能なShinyモジュール
- **エラーハンドリング**: 堅牢なバリデーションシステム
- **パフォーマンス最適化**: 効率的なリアクティブプログラミング
- **デバッグモード**: 開発・検証用の詳細ログ

## 📦 必要環境

### R環境
- **R**: バージョン 4.0.0 以上
- **RStudio**: 推奨（最新版）

### 必須パッケージ
```r
# 核心パッケージ
R6, deSolve

# Shinyパッケージ
shiny (>= 1.7.0), shinydashboard, shinyWidgets, DT, 
plotly, shinycssloaders, shinyjs, bslib (>= 0.4.0), htmltools
```

## 🚀 インストール

### 1. リポジトリのクローン/ダウンロード
```bash
git clone [repository-url]
cd remimazolam_shiny
```

### 2. 依存関係のインストール
```r
# Rコンソールで実行
source("install_shiny_dependencies.R")
```

### 3. アプリケーションの起動
```r
# 方法1: RStudioから
# app.Rファイルを開いて「Run App」ボタンをクリック

# 方法2: Rコンソールから
shiny::runApp("app.R")

# 方法3: 外部からアクセス可能な起動
shiny::runApp("app.R", host = "0.0.0.0", port = 3838)
```

## 📖 使用方法

### 基本的な使用の流れ

1. **免責事項の確認**
   - アプリ起動時に表示される免責事項を確認
   - 「同意して使用開始」をクリック

2. **患者情報の入力**
   - 患者ID（必須）
   - 年齢（18-100歳）
   - 体重（30-200kg）
   - 身長（120-220cm）
   - 性別（男性/女性）
   - ASA分類（I-II / III-IV）

3. **投与スケジュールの設定**
   - プリセット投与法の選択、または
   - カスタム投与スケジュールの作成
   - ボーラス投与量（0-100mg）
   - 持続投与量（0-20mg/kg/hr）

4. **シミュレーションの実行**
   - 「シミュレーション実行」ボタンをクリック
   - 進行状況の確認
   - 結果の確認

5. **結果の確認・エクスポート**
   - 濃度推移グラフの表示
   - データテーブルの確認
   - CSV形式でのエクスポート

### プリセット投与法

#### 標準導入
- 0分: ボーラス 6mg + 持続 1.0mg/kg/hr
- 5分: 持続 0.5mg/kg/hr

#### 緩徐導入
- 0分: ボーラス 3mg + 持続 0.5mg/kg/hr
- 10分: 持続 0.3mg/kg/hr

#### 維持のみ
- 0分: 持続 0.2mg/kg/hr

## 🏗️ アプリケーション構造

```
remimazolam_shiny/
├── app.R                          # メインアプリケーション
├── modules/                       # Shinyモジュール
│   ├── patient_input_module.R     # 患者情報入力
│   ├── dosing_module.R           # 投与スケジュール管理
│   ├── simulation_module.R       # シミュレーション制御
│   ├── results_module.R          # 結果表示
│   └── disclaimer_module.R       # 免責事項
├── R/                            # 核心計算エンジン
│   ├── constants.R              # 定数定義
│   ├── data_models.R            # データモデル
│   └── pk_calculation_engine.R  # PK計算エンジン
├── install_shiny_dependencies.R  # 依存関係インストール
└── README_SHINY.md              # このファイル
```

### モジュール構成

#### Patient Input Module
- リアルタイムバリデーション
- BMI自動計算
- 患者データサマリー表示

#### Dosing Module
- プリセット投与法
- 動的テーブル編集
- 投与スケジュール可視化

#### Simulation Module
- 進行状況表示
- エラーハンドリング
- デバッグモード

#### Results Module
- インタラクティブプロット
- データテーブル表示
- エクスポート機能

## 🎛️ カスタマイズ

### テーマの変更
```r
# app.R内のbs_theme設定を編集
theme = bs_theme(
  version = 5,
  bootswatch = "flatly",  # "cerulean", "cosmo", "darkly"等に変更可能
  primary = "#2c3e50"
)
```

### デバッグモードの有効化
```r
# R/constants.R内で設定
DEBUG_CONSTANTS <- list(
  is_debug_mode = TRUE,
  enable_detailed_logging = TRUE,
  show_calculation_details = TRUE
)
```

### 新しい投与プリセットの追加
```r
# modules/dosing_module.R内のpresetRegimens listに追加
your_custom_regimen = data.frame(
  time_min = c(0, 5, 10),
  bolus_mg = c(5, 0, 0),
  continuous_mg_kg_hr = c(0, 0.8, 0.4),
  stringsAsFactors = FALSE
)
```

## 🔧 トラブルシューティング

### よくある問題と解決方法

#### 1. パッケージインストールエラー
```r
# パッケージを個別にインストール
install.packages(c("shiny", "DT", "plotly", "bslib"), dependencies = TRUE)

# Bioconductorパッケージがエラーになる場合
if (!requireNamespace("BiocManager", quietly = TRUE))
    install.packages("BiocManager")
```

#### 2. アプリが起動しない
```r
# デバッグモードで確認
options(shiny.error = browser)
shiny::runApp("app.R")
```

#### 3. プロットが表示されない
- ブラウザのJavaScriptが有効か確認
- plotlyパッケージが正しくインストールされているか確認
- ブラウザキャッシュをクリア

#### 4. データエクスポートができない
- ファイル書き込み権限を確認
- ブラウザのダウンロード設定を確認

### エラーログの確認
```r
# Rコンソールでエラーメッセージを確認
options(shiny.error = function() { 
  cat("Error occurred at:", as.character(Sys.time()), "\n")
  traceback()
})
```

## 👨‍💻 開発者向け情報

### 開発環境のセットアップ
```r
# 開発用パッケージのインストール
install.packages(c("devtools", "roxygen2", "testthat"))

# パッケージ構造の確認
devtools::check()
```

### テスト実行
```r
# 単体テストの実行
testthat::test_dir("tests/")

# PK計算エンジンのテスト
source("tests/testthat/test_pk_calculation_engine.R")
```

### コード品質チェック
```r
# コードスタイルチェック
lintr::lint_dir(".")

# パフォーマンス分析
profvis::profvis({
  # シミュレーション実行
})
```

### 新機能の追加

1. **新しいモジュールの作成**
   ```r
   # modules/your_module.R
   yourModuleUI <- function(id) { ... }
   yourModuleServer <- function(id, ...) { ... }
   ```

2. **app.Rでモジュールを統合**
   ```r
   source("modules/your_module.R")
   # UIとサーバーロジックに統合
   ```

3. **テストの追加**
   ```r
   # tests/testthat/test_your_module.R
   test_that("your module works", { ... })
   ```

## 📚 参考文献

1. Masui, K., et al. (2022). Population pharmacokinetics and pharmacodynamics of remimazolam in Japanese patients. *British Journal of Anaesthesia*, 128(3), 423-433.

2. Masui, K., & Hagihira, S. (2022). Drug interaction model for propofol-remifentanil effect on bispectral index. *Anesthesiology*, 117(6), 1209-1218.

## 📞 サポート

- **バグレポート**: GitHubのIssuesページ
- **機能要望**: GitHubのDiscussions
- **技術的質問**: 開発者にお問い合わせください

## 📄 ライセンス

GPL-3ライセンスの下で配布されています。詳細は`LICENSE`ファイルを参照してください。

---

**免責事項**: このアプリケーションは教育・研究目的のシミュレーションツールです。実際の臨床判断には使用しないでください。すべての臨床判断は、資格を持つ医療専門家の責任において行われるべきです。