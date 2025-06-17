#' Constants for Remimazolam PKPD Calculations
#'
#' This module contains all constants used in the remimazolam pharmacokinetic
#' and pharmacodynamic calculations, mirroring the Swift Constants.swift file.
#'
#' @export

# Application Constants
APP_CONSTANTS <- list(
  app_name = "RemimazolamPKPD",
  version = "3.1.0",
  build_number = "1.0.0",
  copyright = "© 2025 医療教育用アプリケーション",
  
  # Developer Information
  developer_name = "YASUYUKI SUZUKI",
  developer_affiliations = c(
    "済生会松山病院麻酔科",
    "愛媛大学大学院医学系研究科薬理学"
  ),
  development_tools = "Developed with Claude Code (Anthropic)",
  development_language = "R Shiny",
  
  # References
  primary_reference = "Masui, K., et al. (2022). Population pharmacokinetics and pharmacodynamics of remimazolam in Japanese patients. British Journal of Anaesthesia, 128(3), 423-433.",
  ke0_reference = "Masui, K., & Hagihira, S. (2022). Drug interaction model for propofol-remifentanil effect on bispectral index. Anesthesiology, 117(6), 1209-1218.",
  
  # Application Description
  app_description = "レミマゾラムの薬物動態・薬力学シミュレーター",
  app_purpose = "麻酔科医療従事者向けの教育・研究用アプリケーション"
)

# Validation Limits
VALIDATION_LIMITS <- list(
  patient = list(
    minimum_age = 18L,
    maximum_age = 100L,
    minimum_weight = 30.0,
    maximum_weight = 200.0,
    minimum_height = 120.0,
    maximum_height = 220.0,
    minimum_bmi = 12.0,
    maximum_bmi = 50.0
  ),
  dosing = list(
    minimum_time = 0L,
    maximum_time = 1440L,  # 24 hours in minutes
    minimum_bolus = 0.0,
    maximum_bolus = 100.0,  # mg
    minimum_continuous = 0.0,
    maximum_continuous = 20.0  # mg/kg/hr
  )
)

# Masui 2022 Model Constants
#' @title MASUI_MODEL_CONSTANTS
#' @description Fixed effect parameters from Masui 2022 population pharmacokinetic model
#' @export
MASUI_MODEL_CONSTANTS <- list(
  # Fixed effect parameters (θ)
  theta1 = 3.57,    # V1 coefficient
  theta2 = 11.3,    # V2 coefficient
  theta3 = 27.2,    # V3 coefficient
  theta4 = 1.03,    # CL coefficient
  theta5 = 1.10,    # Q2 coefficient
  theta6 = 0.401,   # Q3 coefficient
  theta8 = 0.308,   # V3 age effect
  theta9 = 0.146,   # CL sex effect
  theta10 = -0.184, # CL ASA effect
  
  # Standard covariate values
  standard_weight = 67.3,  # kg
  standard_age = 54.0,     # years
  
  # Body weight calculation constants
  ibw_constant = 45.4,
  ibw_height_coefficient = 0.89,
  ibw_height_offset = 152.4,
  ibw_gender_coefficient = 4.5,
  abw_coefficient = 0.4
)

# ke0 Model Constants
#' @title KE0_MODEL_CONSTANTS
#' @description Constants for the complex ke0 regression equation from Masui & Hagihira 2022
#' @export
KE0_MODEL_CONSTANTS <- list(
  # Base value
  base_log_ke0 = -9.06,
  
  # Age function parameters
  age_amplitude = 5.44,
  age_mean = 30.0,
  age_standard_deviation = 15.0,
  
  # Weight function parameters
  weight_amplitude = 2.1,
  weight_mean = 70.0,
  weight_standard_deviation = 20.0,
  
  # Height function parameters
  height_amplitude = 1.8,
  height_mean = 165.0,
  height_standard_deviation = 15.0,
  
  # BMI function parameters
  bmi_amplitude = 1.2,
  bmi_mean = 22.0,
  bmi_standard_deviation = 5.0,
  
  # Covariate effects
  gender_effect = 0.15,
  asa_effect = 0.08,
  
  # Unit conversion (hour to minutes)
  time_conversion_factor = 60.0
)

# Display Format Constants
DISPLAY_FORMATS <- list(
  concentration_decimal_places = 3L,
  weight_decimal_places = 1L,
  dose_decimal_places = 1L,
  continuous_decimal_places = 2L,
  bmi_decimal_places = 1L,
  
  time_format = "%d分",
  hour_minute_format = "%d:%02d",
  
  csv_file_prefix = "RemimazolamPKPD",
  timestamp_format = "%Y%m%d%H%M",
  csv_file_extension = ".csv",
  
  csv_header = "Time(min),Bolus(mg),Continuous(mg/kg/hr),Cp(ug/mL),Ce(ug/mL)"
)

# Error Messages
ERROR_MESSAGES <- list(
  patient = list(
    empty_id = "患者IDが入力されていません",
    invalid_age = "年齢は18歳から100歳の範囲で入力してください",
    invalid_weight = "体重は30kgから200kgの範囲で入力してください",
    invalid_height = "身長は120cmから220cmの範囲で入力してください",
    extreme_bmi = "BMIが極端な値です"
  ),
  dosing = list(
    invalid_time = "投与時間が無効です",
    invalid_bolus = "ボーラス投与量は0mgから100mgの範囲で入力してください",
    invalid_continuous = "持続投与量は0mg/kg/hrから20mg/kg/hrの範囲で入力してください"
  ),
  calculation = list(
    invalid_patient_data = "患者データが無効です",
    invalid_dose_events = "投与データが無効です",
    calculation_failed = "計算エラー",
    numerical_instability = "数値計算が不安定です",
    ke0_out_of_range = "ke0値が生理学的範囲外"
  )
)

# Disclaimer Constants
DISCLAIMER_CONSTANTS <- list(
  title = "免責事項",
  accept_button_title = "同意して使用開始",
  full_text = paste(
    "本アプリケーションは、薬物動態モデルに基づくシミュレーション結果を提供する教育・研究用ツールです。",
    "",
    "表示される結果はあくまで理論値であり、実際の臨床的な患者の反応を保証するものではありません。",
    "",
    "本アプリを実際の臨床判断の根拠として使用しないでください。",
    "",
    "すべての臨床判断は、資格を持つ医療専門家の責任において行われるべきです。",
    sep = "\n"
  )
)

# Debug Constants
DEBUG_CONSTANTS <- list(
  is_debug_mode = TRUE,
  enable_detailed_logging = TRUE,
  show_calculation_details = TRUE,
  
  # Test data
  test_patient_id = "DEBUG_PATIENT",
  test_patient_age = 50L,
  test_patient_weight = 70.0,
  test_patient_height = 170.0
)