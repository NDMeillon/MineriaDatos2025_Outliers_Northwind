WITH OrderCalculations AS (
    SELECT
        OD.OrderID,
        O.CustomerID,
        O.EmployeeID,
        O.Freight,
        OD.ProductID,
        OD.UnitPrice AS DetailUnitPrice,
        OD.Quantity,
        OD.Discount,
        -- 1. Calcular el valor de cada línea de detalle
        (OD.UnitPrice * OD.Quantity * (1 - OD.Discount)) AS LineValue
    FROM
        [Northwind].[dbo].[Order Details] AS OD
    INNER JOIN
        [Northwind].[dbo].[Orders] AS O
        ON OD.OrderID = O.OrderID
)
SELECT
    OrderID,
    CustomerID,
    EmployeeID,
    Freight,
    -- 2. Calcular el valor total del pedido (suma de todos los LineValue + Freight)
    SUM(LineValue) AS SubtotalValue,
    (SUM(LineValue) + Freight) AS TotalOrderValue
FROM
    OrderCalculations
GROUP BY
    OrderID, CustomerID, EmployeeID, Freight
ORDER BY
    TotalOrderValue DESC; -- Ordenar para ver inmediatamente los outliers (pedidos más caros)

