# Debug ke0 calculation
source("R/constants.R")
source("R/data_models.R")
source("R/pk_calculation_engine.R")

# Problem patient
patient2 <- Patient$new("TEST_2", 70L, 80.0, 180.0, SexType$MALE, AsapsType$CLASS3_4)

cat("Debugging ke0 calculation for patient 2:\n")
cat(sprintf("Age: %d\n", patient2$age))
cat(sprintf("Weight: %.1f kg\n", patient2$weight))
cat(sprintf("Height: %.1f cm\n", patient2$height))
cat(sprintf("Sex: %d\n", patient2$sex))
cat(sprintf("ASA: %d\n", patient2$asa_ps))
cat(sprintf("BMI: %.1f\n", patient2$get_bmi()))

# Manual ke0 calculation
age <- as.numeric(patient2$age)
tbw <- patient2$weight
height <- patient2$height
sex <- as.numeric(patient2$sex)
asa <- as.numeric(patient2$asa_ps)
bmi <- patient2$get_bmi()

cat("\nCalculation steps:\n")
cat(sprintf("Age: %.1f\n", age))
cat(sprintf("TBW: %.1f\n", tbw))
cat(sprintf("Height: %.1f\n", height))
cat(sprintf("Sex: %.1f\n", sex))
cat(sprintf("ASA: %.1f\n", asa))
cat(sprintf("BMI: %.1f\n", bmi))

# Age function
f_age <- KE0_MODEL_CONSTANTS$age_amplitude * 
         exp(-0.5 * ((age - KE0_MODEL_CONSTANTS$age_mean) / KE0_MODEL_CONSTANTS$age_standard_deviation)^2)

# Weight function
f_tbw <- KE0_MODEL_CONSTANTS$weight_amplitude * 
         exp(-0.5 * ((tbw - KE0_MODEL_CONSTANTS$weight_mean) / KE0_MODEL_CONSTANTS$weight_standard_deviation)^2)

# Height function
f_height <- KE0_MODEL_CONSTANTS$height_amplitude * 
            exp(-0.5 * ((height - KE0_MODEL_CONSTANTS$height_mean) / KE0_MODEL_CONSTANTS$height_standard_deviation)^2)

# BMI function
f_bmi <- KE0_MODEL_CONSTANTS$bmi_amplitude * 
         exp(-0.5 * ((bmi - KE0_MODEL_CONSTANTS$bmi_mean) / KE0_MODEL_CONSTANTS$bmi_standard_deviation)^2)

cat("\nFunction values:\n")
cat(sprintf("f_age: %.6f\n", f_age))
cat(sprintf("f_tbw: %.6f\n", f_tbw))
cat(sprintf("f_height: %.6f\n", f_height))
cat(sprintf("f_bmi: %.6f\n", f_bmi))

# ke0 calculation
ke0_log <- KE0_MODEL_CONSTANTS$base_log_ke0 + 
           f_age + 
           f_tbw + 
           f_height + 
           f_bmi + 
           KE0_MODEL_CONSTANTS$gender_effect * sex + 
           KE0_MODEL_CONSTANTS$asa_effect * asa

cat(sprintf("\nke0_log components:\n"))
cat(sprintf("Base: %.6f\n", KE0_MODEL_CONSTANTS$base_log_ke0))
cat(sprintf("Age effect: %.6f\n", f_age))
cat(sprintf("Weight effect: %.6f\n", f_tbw))
cat(sprintf("Height effect: %.6f\n", f_height))
cat(sprintf("BMI effect: %.6f\n", f_bmi))
cat(sprintf("Sex effect: %.6f\n", KE0_MODEL_CONSTANTS$gender_effect * sex))
cat(sprintf("ASA effect: %.6f\n", KE0_MODEL_CONSTANTS$asa_effect * asa))
cat(sprintf("Total ke0_log: %.6f\n", ke0_log))

ke0 <- exp(ke0_log) / KE0_MODEL_CONSTANTS$time_conversion_factor

cat(sprintf("\nFinal ke0: %.8f 1/min\n", ke0))

# Check if this is reasonable
if (ke0 < 0.0001) {
  cat("WARNING: ke0 is extremely small!\n")
  cat("This suggests an issue with the calculation or constants.\n")
}