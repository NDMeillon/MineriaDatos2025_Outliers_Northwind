SELECT TOP (1000) [OrderID]
      ,[CustomerID]
      ,[EmployeeID]
      ,[OrderDate]
      ,[Freight]
      ,[TotalOrderValue]
      ,[TotalItems]
  FROM [Northwind].[dbo].[OutlierAnalysis_Aggregated]

  ORDER BY
    CustomerID, TotalOrderValue DESC

