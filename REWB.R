library(plm)
library(dplyr)
library(readxl)

# Cargar la base
datos <- read_excel("C:/Users/EDER3/OneDrive/NACHO/Investigacion China - COLOMBIA/Modelo/Datos modelo.xlsx")

# 1. Asegurar que todas las variables relevantes sean numéricas
datos <- datos %>%
  mutate(across(
    c("AbsPC", "avg_price", "contig", "Dcrisis", "dist", "Grado_apertura", "IEDPIB", "LDEP", "gdp_o", "gdp_d", "DIF_KL", "IGL_total"), 
    as.numeric
  ))

# 2. Filtrar observaciones y calcular promedios en un solo paso
# Se asigna a 'pdata' el resultado de las transformaciones
pdata <- datos %>%
  filter(!is.na(IGL_total)) %>%
  group_by(socio) %>%
  mutate(
    mean_AbsPC = mean(AbsPC, na.rm = TRUE),
    mean_avg_price = mean(avg_price, na.rm = TRUE),
    mean_contig = mean(contig, na.rm = TRUE),
    mean_Dcrisis = mean(Dcrisis, na.rm = TRUE),
    mean_dist = mean(dist, na.rm = TRUE),
    mean_Grado_apertura = mean(Grado_apertura, na.rm = TRUE),
    mean_IEDPIB = mean(IEDPIB, na.rm = TRUE),
    mean_LDEP = mean(LDEP, na.rm = TRUE),
    mean_gdp_o = mean(gdp_o, na.rm = TRUE),
    mean_gdp_d = mean(gdp_d, na.rm = TRUE),
    mean_DIF_KL = mean(DIF_KL, na.rm = TRUE)
  ) %>%
  ungroup()

# ================================
# Convertir a estructura de panel
# ================================
pdata <- pdata.frame(pdata, index = c("socio", "año"))

# ================================
# Estimar modelo REWB (Mundlak)
# ================================
modelo_rewb <- plm(
  IGL_total ~ AbsPC + avg_price + Dcrisis + Grado_apertura + IEDPIB + LDEP + gdp_o + gdp_d + DIF_KL + # Within-country variables
    mean_AbsPC + mean_avg_price + mean_Dcrisis + mean_Grado_apertura + mean_IEDPIB + mean_LDEP + mean_gdp_o + mean_gdp_d + mean_DIF_KL + # Between-country variables
    contig + dist,
  data = pdata,
  model = "random",
  effect = "individual"
)

# ===============================
# Mostrar resultados
# ================================
summary(modelo_rewb)
