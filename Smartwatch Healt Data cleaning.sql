
--- SQL project Data Cleaning, normalization & exploring
---https://www.kaggle.com/datasets/mohammedarfathr/smartwatch-health-data-uncleaned

SELECT [User_ID]
      ,[Heart_Rate_BPM]
      ,[Blood_Oxygen_Level]
      ,[Step_Count]
      ,[Sleep_Duration_hours]
      ,[Activity_Level]
      ,[Stress_Level]
  FROM [dbo].[Smartwatch health]



/*//////////////////////////// Data Cleaning\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\*/

---1.Handling NULL values in the USER_id column b-y deleting rows where User_id IS NULL.

  DELETE FROM [dbo].[Smartwatch health]
  WHERE User_ID IS NULL

---2. Handling with NULL values in [Heart_Rate_BPM] column, by replacing them with mean values.

  UPDATE [dbo].[Smartwatch health]
  SET Heart_rate_BPM = (Select AVG(Heart_rate_BPM)
						FROM [dbo].[Smartwatch health]
						WHERE Heart_rate_BPM IS NOT NULL)
WHERE Heart_rate_BPM IS NULL;

---3. Handling with NULL values in [Blood_oxygen_level] column, by replacing them with mean values.

UPDATE [Smartwatch health]
SET  [Blood_Oxygen_Level] = (SELECT AVG([Blood_Oxygen_Level])
							FROM [Smartwatch health]
							WHERE [Blood_Oxygen_Level] IS NOT NULL)
WHERE [Blood_Oxygen_Level] IS NULL;


---4. Handling with NULL values in [Step_Count] column, by replacing them with mean values.


UPDATE [Smartwatch health]
SET [Step_Count] = (SELECT AVG([Step_Count])
					FROM [Smartwatch health]
					WHERE [Step_Count] IS NOT NULL)

WHERE [Step_Count] iS NULL;



---5.Handling with NULL values in [Sleep_duration_hours] column, by replacing them with mean values.

UPDATE [Smartwatch health]
SET Sleep_duration_hours = (SELECT AVG(Sleep_duration_hours)    
							FROM [Smartwatch health]
							WHERE Sleep_duration_hours IS NOT NULL)

WHERE Sleep_duration_hours IS NULL;


---6. Handling 'nan' value in the [Activity_Level] column, I've decied to delete this rows.

DELETE FROM [Smartwatch health]
WHERE Activity_Level ='nan'


----6.1 Dealing with Inconsistency in [Activity_Level] column like Active/Actve, Highly Active/Highly_Active and Sedentary/Seddentary


UPDATE  [Smartwatch health]
SET Activity_Level = 'Active'
	WHERE Activity_Level IN ('Actve');

	
UPDATE  [Smartwatch health]
SET Activity_Level = 'Highly Active'
	WHERE Activity_Level IN ('Highly_Active');


	UPDATE  [Smartwatch health]
SET Activity_Level = 'Sedentary'
	WHERE Activity_Level IN ('Seddentary');


---7. Handling NULLs in the [Stress_level] column, by filling them with median. 
----7.1 In Update statement we using TOP 1 to be sure that query returns only 1 value.

WITH MedianCTE AS (
			SELECT PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY Stress_Level)  OVER () AS median_value
			FROM [Smartwatch health] 
			WHERE Stress_level IS NOT NULL )

UPDATE [Smartwatch health]
SET Stress_level  =	( SELECT TOP 1 median_value FROM MedianCTE )
WHERE Stress_level IS NULL;


---8. Finishing touches trying to round up all number columns two number after dot(.).

 UPDATE [Smartwatch health]
 SET 
	 [Heart_Rate_BPM] = ROUND([Heart_Rate_BPM],2),
     [Blood_Oxygen_Level] = ROUND([Blood_Oxygen_Level],2),
     [Step_Count] = ROUND([Step_Count],2),
     [Sleep_Duration_hours] = ROUND([Sleep_Duration_hours],2)


SELECT *
FROM [Smartwatch health]

    
					




