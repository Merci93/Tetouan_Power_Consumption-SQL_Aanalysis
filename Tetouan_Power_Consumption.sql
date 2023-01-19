--1
--Total consumption per zone
SELECT SUM(power_consumption_zone_1) AS zone_1_total,
       SUM(power_consumption_zone_2) AS zone_2_total,
       SUM(power_consumption_zone_3) AS zone_3_total
FROM power_consumption_zones;


--2
--Average consumption per zone rounded to 2 decimal places
SELECT ROUND(AVG(power_consumption_zone_1), 2) AS zone_1_avg,
       ROUND(AVG(power_consumption_zone_2), 2) AS zone_2_avg,
       ROUND(AVG(power_consumption_zone_3), 2) AS zone_3_avg
FROM power_consumption_zones;


--3
--Monthly average consumption per zone
SELECT md.month,
       ROUND(AVG(pcz.power_consumption_zone_1), 2) AS zone_1,
       ROUND(AVG(pcz.power_consumption_zone_2), 2) AS zone_1,
       ROUND(AVG(pcz.power_consumption_zone_3), 2) AS zone_1
FROM power_consumption_zones AS pcz
LEFT JOIN month_day AS md
ON md.date = pcz.date
GROUP BY DATEPART(month, pcz.date), md.month
ORDER BY DATEPART(month, pcz.date); 


--4
--Difference in average monthly power consumption and temperature to the overall average per zone
SELECT md.month AS month,
       ROUND(AVG(pcz.power_consumption_zone_1) - (SELECT AVG(power_consumption_zone_1) FROM power_consumption_zones), 2) AS zone_1_differences,
       ROUND(AVG(pcz.power_consumption_zone_2) - (SELECT AVG(power_consumption_zone_2) FROM power_consumption_zones), 2) AS zone_2_differences,
       ROUND(AVG(pcz.power_consumption_zone_3) - (SELECT AVG(power_consumption_zone_3) FROM power_consumption_zones), 2) AS zone_3_differences,
       ROUND(AVG(dp.temperature) - (SELECT AVG(temperature) FROM daily_parameters), 2) AS temperature
FROM power_consumption_zones AS pcz
LEFT JOIN month_day AS md
ON pcz.date = md.date
LEFT JOIN daily_parameters AS dp
ON md.date = dp.date
GROUP BY DATEPART(month, pcz.date), md.month
ORDER BY DATEPART(month, pcz.date);


--5
--Monthly moving average
WITH monthly_power_consumed (month_numeric, month, zone_1, zone_2, zone_3) AS
	(
		SELECT DATEPART(month, pcz.date) AS month_numeric,
		       md.month,
		       ROUND(SUM(pcz.power_consumption_zone_1), 2) AS zone_1,
		       ROUND(SUM(pcz.power_consumption_zone_2), 2) AS zone_2,
		       ROUND(SUM(pcz.power_consumption_zone_3), 2) AS zone_3
		FROM power_consumption_zones AS pcz
		LEFT JOIN month_day AS md
		ON md.date = pcz.date
		GROUP BY DATEPART(month, pcz.date), md.month
	)

SELECT month,
       ROUND(AVG(zone_1) OVER (ORDER BY month_numeric ROWS BETWEEN 2 PRECEDING AND CURRENT ROW), 2) AS zone_1_MA,
       ROUND(AVG(zone_1) OVER (ORDER BY month_numeric ROWS BETWEEN 2 PRECEDING AND CURRENT ROW), 2) AS zone_1_MA,
       ROUND(AVG(zone_1) OVER (ORDER BY month_numeric ROWS BETWEEN 2 PRECEDING AND CURRENT ROW), 2) AS zone_1_MA
FROM monthly_power_consumed;


--6
--Monthly power consumption per zone
SELECT md.month,
       ROUND(SUM(pcz.power_consumption_zone_1), 2) AS zone_1,
       ROUND(SUM(pcz.power_consumption_zone_2), 2) AS zone_2,
       ROUND(SUM(pcz.power_consumption_zone_3), 2) AS zone_3
FROM power_consumption_zones AS pcz
LEFT JOIN month_day AS md
ON pcz.date = md.date
GROUP BY DATEPART(month, pcz.date), md.month
ORDER BY DATEPART(month, pcz.date);


--7
--Monthly power consumption as a percentage of total power consumption per zone
WITH total_power (zone_1_total, zone_2_total, zone_3_total) AS
	(
		SELECT ROUND(SUM(power_consumption_zone_1), 2) AS zone_1_total,
		       ROUND(SUM(power_consumption_zone_2), 2) AS zone_2_total,
		       ROUND(SUM(power_consumption_zone_3), 2) AS zone_3_total
		FROM power_consumption_zones
	)

SELECT md.month AS month,
       ROUND(100.0 * SUM(pcz.power_consumption_zone_1) / (SELECT zone_1_total FROM total_power), 2) AS zone_1,
       ROUND(100.0 * SUM(pcz.power_consumption_zone_2) / (SELECT zone_2_total FROM total_power), 2) AS zone_2,
       ROUND(100.0 * SUM(pcz.power_consumption_zone_3) / (SELECT zone_3_total FROM total_power), 2) AS zone_3
FROM power_consumption_zones AS pcz
LEFT JOIN month_day AS md
ON pcz.date = md.date
GROUP BY DATEPART(month, pcz.date), md.month
ORDER BY DATEPART(month, pcz.date);


--8
--Monthly change in power consumption and temperature
WITH summary_data (month_numeric, month, zone_1, zone_2, zone_3, temperature_change) AS
	(
		SELECT DATEPART(month, pcz.date) AS month_numeric,
		       md.month,
		       ROUND(SUM(pcz.power_consumption_zone_1), 2) AS zone_1,
		       ROUND(SUM(pcz.power_consumption_zone_2), 2) AS zone_2,
		       ROUND(SUM(pcz.power_consumption_zone_3), 2) AS zone_3,
		       ROUND(SUM(dp.temperature), 2) AS temperature_change
		FROM power_consumption_zones AS pcz
		LEFT JOIN month_day AS md
		ON md.date = pcz.date
		LEFT JOIN daily_parameters AS dp
		ON md.date = dp.date
		GROUP BY DATEPART(month, pcz.date), md.month
	)

SELECT month,
       zone_1 - LAG(zone_1) OVER (ORDER BY month_numeric ASC) AS zone_1_change,
       zone_2 - LAG(zone_2) OVER (ORDER BY month_numeric ASC) AS zone_2_change,
       zone_3 - LAG(zone_1) OVER (ORDER BY month_numeric ASC) AS zone_3_change,
       temperature_change - LAG(temperature_change) OVER (ORDER BY month_numeric) AS temperature_change
FROM summary_data
ORDER BY month_numeric;


--9
--Average monthly temperature and windspeed
SELECT md.month,
       ROUND(AVG(dp.temperature), 2) AS temperature_avg,
       ROUND(AVG(dp.wind_speed), 2) AS wind_speed_avg
FROM daily_parameters AS dp
LEFT JOIN month_day AS md
ON md.date = dp.date
GROUP BY DATEPART(month, md.date), md.month
ORDER BY DATEPART(month, md.date);


