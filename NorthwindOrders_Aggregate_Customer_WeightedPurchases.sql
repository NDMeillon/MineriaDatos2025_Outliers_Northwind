USE Northwind;
GO

EXEC sp_execute_external_script
    @language = N'Python',
    @script = N'
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt

# Cargar los datos y definir el CustomerID como índice
data = InputData.copy()
data.set_index("CustomerID", inplace=True)

# Definir los umbrales de Outlier (basado en IQR de la métrica ponderada)
weighted_metric = data["WeightedPurchaseMetric"]
Q1 = np.percentile(weighted_metric, 25)
Q3 = np.percentile(weighted_metric, 75)
IQR = Q3 - Q1
upper_bound = Q3 + 1.5 * IQR

# Clasificar outliers
data["IsOutlier"] = (weighted_metric > upper_bound).astype(int)

# Generar y Guardar el Gráfico de Dispersión (Scatter Plot)
plot_path = r"C:\temp\Customer_Weighted_Purchases.png"
plt.figure(figsize=(10, 8))

# Mapear colores y tamaños
colors = ["blue", "red"] # Azul para Normal, Rojo para Outlier
c_map = [colors[i] for i in data["IsOutlier"]]
sizes = [150 if i == 1 else 50 for i in data["IsOutlier"]] # Los outliers son más grandes

plt.scatter(data["TotalPurchases"],
            data["AveragePurchase"],
            c=c_map,
            s=sizes,
            marker="o",
            alpha=0.7)

plt.title("Análisis Ponderado por Cliente: Total vs. Promedio de Compra")
plt.xlabel("Valor Total de Compras (SUM)")
plt.ylabel("Valor Promedio de Compra (AVG)")
plt.grid(True, linestyle="--", alpha=0.6)

# Agregar una línea para el umbral de outlier en el eje Y (opcional)
# plt.axhline(data[data["IsOutlier"] == 1]["AveragePurchase"].max(), color="red", linestyle=":", linewidth=1)

plt.savefig(plot_path)


# 4. Devolver los Outliers (Clientes cuyo WeightedPurchaseMetric es anómalo)
OutputData = data[data["IsOutlier"] == 1].reset_index()
OutputData = OutputData[["CustomerID", "TotalPurchases", "AveragePurchase", "WeightedPurchaseMetric"]].sort_values(by="WeightedPurchaseMetric", ascending=False)
',
    @input_data_1 = N'
        -- Consulta SQL que alimenta el script de Python con la métrica requerida
        SELECT
            CustomerID,
            CAST(SUM(TotalOrderValue) AS FLOAT) AS TotalPurchases,
            CAST(AVG(TotalOrderValue) AS FLOAT) AS AveragePurchase,
            -- Métrica Ponderada = SUM(TotalOrderValue) + AVG(TotalOrderValue)
            (CAST(SUM(TotalOrderValue) AS FLOAT) + CAST(AVG(TotalOrderValue) AS FLOAT)) AS WeightedPurchaseMetric
        FROM
            [Northwind].[dbo].[OutlierAnalysis_Aggregated]
        GROUP BY
            CustomerID
        ',
    @input_data_1_name = N'InputData'
WITH RESULT SETS
(
    (
        CustomerID NCHAR(5),
        TotalPurchases FLOAT,
        AveragePurchase FLOAT,
        WeightedPurchaseMetric FLOAT
    )
);

SELECT
    CustomerID,
    COUNT(OrderID) AS Numero_de_Ordenes,
    SUM(TotalOrderValue) AS Total_de_Ingresos,
    AVG(TotalOrderValue) AS Promedio_por_Pedido,
    -- NULL si solo hay una orden, sino la desviación estándar
    STDEV(TotalOrderValue) AS Desviacion_Estandar_Pedidos 
FROM
    [Northwind].[dbo].[OutlierAnalysis_Aggregated]
GROUP BY
    CustomerID
ORDER BY
    Total_de_Ingresos DESC; -- Ordenado por ingresos totales para identificar a los clientes más valiosos