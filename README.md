# Remimazolam PK/PD Simulator

[\![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[\![R](https://img.shields.io/badge/R-4.0%2B-blue.svg)](https://www.r-project.org/)
[\![Shiny](https://img.shields.io/badge/Shiny-1.7%2B-brightgreen.svg)](https://shiny.rstudio.com/)

レミマゾラムの薬物動態・薬力学シミュレーション用のインタラクティブなShinyアプリケーションです。

## 📖 概要

このアプリケーションは、レミマゾラムの個別化薬物動態シミュレーションを行う教育・研究用ツールです。Masui 2022年の母集団薬物動態モデルに基づいて、患者個別の薬物動態パラメータを計算し、血漿中および効果部位濃度の時間推移をシミュレーションします。

## ✨ 主な機能

- **個別化薬物動態パラメータ**: 患者の年齢、体重、身長、性別、ASA分類に基づく個別計算
- **複数計算手法**: V2標準（deSolve）とV3比較（4種類の手法）
- **リアルタイム可視化**: インタラクティブなグラフによる濃度推移表示
- **柔軟な投与設定**: ボーラス投与と持続投与の組み合わせ対応
- **データエクスポート**: CSV形式でのシミュレーション結果出力
- **レスポンシブデザイン**: デスクトップ・タブレット・モバイル対応

## 🚨 重要な使用制限

**⚠️ このソフトウェアは、教育および研究目的での利用のみを想定しています。**

- 本ソフトウェアは医療機器ではありません
- 診断、治療、その他一切の臨床用途・患者ケアに使用してはなりません
- 本ソフトウェアの使用によって生じたいかなる結果についても、作者は一切の責任を負いません

## 🔒 データとプライバシー

このソフトウェアは、利用者が入力したいかなるデータも収集、保存、外部送信することはありません。すべての計算は、利用者のデバイス上で完結します。

## 🛠️ インストールと実行

### 必要な要件

- R 4.0.0以上
- 以下のRパッケージ:
  ```r
  install.packages(c(
    "shiny",
    "shinydashboard", 
    "shinyWidgets",
    "DT",
    "plotly",
    "shinycssloaders",
    "shinyjs",
    "R6",
    "bslib",
    "deSolve"
  ))
  ```

### 実行方法

1. リポジトリをクローン:
   ```bash
   git clone https://github.com/ysuzuki1978/remimazolam-pkpd-simulator.git
   cd remimazolam-pkpd-simulator
   ```

2. Rでアプリケーションを実行:
   ```r
   shiny::runApp()
   ```

3. ブラウザでアプリケーションが自動的に開きます

## 📊 計算手法

### V2 標準計算
- deSolve パッケージによる連続微分方程式解法
- 高精度数値積分（lsoda法）

### V3 比較計算（4手法）
1. **Original**: V2標準と同等のdeSolve手法
2. **Discrete**: 離散時間ステップ法（Euler法）
3. **Exponential**: 指数減衰累積法
4. **Hybrid**: 解析的混合法

## 📚 科学的根拠

本アプリケーションは以下の研究に基づいています：

1. Masui, K., et al. (2022). Population pharmacokinetics and pharmacodynamics of remimazolam in Japanese patients. *British Journal of Anaesthesia*, 128(3), 423-433.
2. Masui, K., & Hagihira, S. (2022). Drug interaction model for propofol-remifentanil effect on bispectral index. *Anesthesiology*, 117(6), 1209-1218.

## 👤 開発者

**YASUYUKI SUZUKI**

📧 suzuki.yasuyuki.hr@ehime-u.ac.jp  
🆔 ORCID: [0000-0002-4871-9685](https://orcid.org/0000-0002-4871-9685)

**所属:**
- 済生会松山病院麻酔科
- 愛媛大学大学院医学系研究科薬理学

**開発環境:** R Shiny, Developed with Claude Code (Anthropic)

## 🤝 貢献

プルリクエストやイシューの報告を歓迎します。貢献をお考えの方は、まずIssueを作成して議論してください。

### 開発のガイドライン

1. コードスタイルは既存のものに合わせてください
2. 新機能には適切なテストを含めてください  
3. コミットメッセージは分かりやすく記述してください
4. 医療安全に関わる変更は特に慎重に検討してください

## 📝 ライセンス

このプロジェクトはMITライセンスの下で公開されています。詳細は[LICENSE](LICENSE)ファイルをご覧ください。

## 🙏 謝辞

- Masui先生らの研究グループによる薬物動態モデルの開発
- R Shinyコミュニティによる優れたツールの提供
- Claude Code (Anthropic)による開発支援

## 📞 お問い合わせ

バグ報告、機能要望、その他のお問い合わせは、GitHubのIssueまたは開発者まで直接ご連絡ください。

---

**免責事項**: このソフトウェアは「現状のまま」提供され、明示または黙示を問わず、いかなる保証もありません。
EOF < /dev/null
