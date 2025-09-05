# -*- coding: utf-8 -*-
"""
Created on Sun May 18 22:06:10 2025

@author: EDER3
"""

import pandas as pd
import os
import numpy as np

# Ruta a la carpeta con los archivos
carpeta_datos = r"C:\Users\EDER3\OneDrive\NACHO\Investigacion China - COLOMBIA\BACI_HS02_V202501"

# Lista de años
años = list(range(2002, 2024))

# Lista para guardar resultados
resultados = []

def calcular_igl(exportaciones, importaciones):
    """
    Calcula el Índice de Grubel-Lloyd (IGL) a nivel de país para un año.

    Parámetros:
    - exportaciones: Lista o array de exportaciones por grupo industrial.
    - importaciones: Lista o array de importaciones por grupo industrial.

    Retorno:
    - Valor del IGL (float).
    """
    exportaciones = np.array(exportaciones)
    importaciones = np.array(importaciones)
    
    # Numerador: suma de los valores absolutos de las diferencias entre exportaciones e importaciones
    numerador = np.sum(np.abs(exportaciones - importaciones))
    
    # Denominador: suma de las exportaciones e importaciones
    denominador = np.sum(exportaciones + importaciones)
    
    # Cálculo del IGL
    igl = 1 - (numerador / denominador) if denominador != 0 else 0
    
    return igl

# Iterar sobre cada año
for anio in años:
    archivo = os.path.join(carpeta_datos, f'BACI_HS02_Y{anio}_V202501.csv')
    print(f"Procesando el año {anio}...")

    # Cargar el archivo del año
    df = pd.read_csv(archivo)

    # Filtrar comercio entre Colombia (170) y China (156)
    df_col_chi2 = df[((df['i'] == 170) & (df['j'] == 842)) | ((df['i'] == 842) & (df['j'] == 170))]

    # Exportaciones de Colombia a China
    exp = df_col_chi2[(df_col_chi2['i'] == 170) & (df_col_chi2['j'] == 842)][['k', 'v']].rename(columns={'v': 'X_k'})

    # Importaciones de Colombia desde China
    imp = df_col_chi2[(df_col_chi2['i'] == 842) & (df_col_chi2['j'] == 170)][['k', 'v']].rename(columns={'v': 'M_k'})

    # Unir exportaciones e importaciones por código arancelario (k)
    df_gl = pd.merge(exp, imp, on='k', how='inner')

    # Calcular el IGL para cada producto
    igl_anual = calcular_igl(df_gl['X_k'], df_gl['M_k'])

    # Guardar el resultado
    resultados.append({
        'Año': anio,
        'IGL': igl_anual
    })

# Crear DataFrame con los resultados
df_resultados2 = pd.DataFrame(resultados)

# Mostrar resultados
print(df_resultados2)