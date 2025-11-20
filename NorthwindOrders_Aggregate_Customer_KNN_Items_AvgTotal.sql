USE Northwind;
GO

EXEC sp_execute_external_script
    @language = N'Python',
    @script = N'
import pandas as pd
import numpy as np
from sklearn.preprocessing import StandardScaler
from sklearn.neighbors import NearestNeighbors
import matplotlib.pyplot as plt

data = InputData.copy()
# Usamos CustomerID como índice, ya que es la unidad de análisis
data.set_index("CustomerID", inplace=True)

# Seleccionar y escalar las características
# Usamos el promedio del valor y el promedio de los artículos por cliente
features = data[["AvgTotalOrderValue", "AvgTotalItems"]]
scaler = StandardScaler()
X_scaled = scaler.fit_transform(features)

# Aplicar K-Nearest Neighbors (KNN)
k_neighbors = 5
nn = NearestNeighbors(n_neighbors=k_neighbors)
nn.fit(X_scaled)

# Calcular el score de anomalía (distancia al 5to vecino más cercano)
distances, indices = nn.kneighbors(X_scaled, n_neighbors=k_neighbors + 1)
anomaly_score = distances[:, k_neighbors]
data["AnomalyScore"] = anomaly_score

# Definir Outliers (Top 5% de los scores más altos)
outlier_threshold = np.percentile(anomaly_score, 95)
data["IsOutlier"] = (data["AnomalyScore"] >= outlier_threshold).astype(int)

# Generar y Guardar el Gráfico de Clientes (2D)
plot_path = r"C:\temp\KNN_Outliers_Customer_Avg.png"
plt.figure(figsize=(10, 6))

colors = ["blue", "red"] # Azul para normal, Rojo para outlier
c_map = [colors[i] for i in data["IsOutlier"]]

plt.scatter(data["AvgTotalOrderValue"],
            data["AvgTotalItems"],
            c=c_map,
            s=50,
            marker="o",
            alpha=0.7)

plt.title("Detección de Outliers KNN por Cliente (Promedio de Pedido)")
plt.xlabel("Valor Promedio del Pedido ($)")
plt.ylabel("Promedio de Artículos por Pedido")
plt.grid(True, linestyle="--", alpha=0.6)
plt.savefig(plot_path)

# Devolver el DataFrame con el CustomerID y el score, filtrando solo los outliers
OutputData = data[data["IsOutlier"] == 1].reset_index()
OutputData = OutputData[["CustomerID", "AvgTotalOrderValue", "AvgTotalItems", "AnomalyScore"]].sort_values(by="AnomalyScore", ascending=False)
',
    @input_data_1 = N'
        -- Agregamos la tabla por CustomerID para obtener los valores promedio
        SELECT
            CustomerID,
            CAST(AVG(TotalOrderValue) AS FLOAT) AS AvgTotalOrderValue,
            CAST(AVG(TotalItems) AS FLOAT) AS AvgTotalItems
        FROM
            [Northwind].[dbo].[OutlierAnalysis_Aggregated]
        GROUP BY
            CustomerID
        ',
    @input_data_1_name = N'InputData'
WITH RESULT SETS
(
    (
        CustomerID NCHAR(5), -- CustomerID es NCHAR(5) en Northwind
        AvgTotalOrderValue FLOAT,
        AvgTotalItems FLOAT,
        AnomalyScore FLOAT
    )
);