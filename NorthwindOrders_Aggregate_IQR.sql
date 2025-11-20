USE Northwind;
GO

/**************************************************************
*** VISUALIZACIÓN IQR: BOX PLOT DEL VALOR TOTAL DEL PEDIDO
**************************************************************/

EXEC sp_execute_external_script
    @language = N'Python',
    @script = N'
import pandas as pd
import matplotlib.pyplot as plt
import numpy as np

data = InputData.copy()
order_values = data["TotalOrderValue"]

plt.figure(figsize=(10, 6))

# El Box Plot de Matplotlib identifica los outliers automáticamente
# como puntos individuales que caen fuera de 1.5 * IQR de los cuartiles.
plt.boxplot(order_values, vert=False, patch_artist=True,
            medianprops=dict(color="red"),
            boxprops=dict(facecolor="lightblue"))

# Calcular los cuartiles y umbrales para el título/etiquetas
Q1 = np.percentile(order_values, 25)
Q3 = np.percentile(order_values, 75)
IQR = Q3 - Q1
UpperBound = Q3 + 1.5 * IQR
LowerBound = Q1 - 1.5 * IQR

plt.title("Diagrama de Caja (Box Plot) del Valor Total del Pedido")
plt.xlabel(f"Valor Total del Pedido ($) | IQR: {IQR:.2f}")
plt.yticks([1], ["TotalOrderValue"])

# Agregar texto de los umbrales (opcional, para claridad)
plt.text(order_values.max() * 0.9, 1.25,
         f"Umbral Alto (Outlier): {UpperBound:.2f}",
         fontsize=9, color="darkgreen", horizontalalignment="right")

plt.text(order_values.min(), 0.75,
         f"Umbral Bajo (Outlier): {LowerBound:.2f}",
         fontsize=9, color="darkred", horizontalalignment="left")

plot_path = r"C:\temp\IQR_Box_Plot_TotalOrderValue.png"
plt.savefig(plot_path)

OutputData = pd.DataFrame([f"Box Plot exportado a {plot_path}"], columns=["Mensaje"])
',
    @input_data_1 = N'
        SELECT
            CAST(TotalOrderValue AS FLOAT) AS TotalOrderValue
        FROM
            [Northwind].[dbo].[OutlierAnalysis_Aggregated]
        ',
    @input_data_1_name = N'InputData'
WITH RESULT SETS
(
    (
        Mensaje NVARCHAR(MAX)
    )
);