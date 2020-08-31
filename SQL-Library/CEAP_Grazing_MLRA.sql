DECLARE @area VARCHAR(20);
DECLARE @area_type INT ;

--~DeclareChar(@area,20)~  -- Used for Soil Data Access
--~DeclareINT(@area_type)~ 

--SELECT @area= 'HI'; --Enter State Abbreviation or Soil Survey Area i.e. WI or WI025

------------------------------------------------------------------------------------
SELECT @area_type = LEN (@area); --determines number of characters of area 2-State, 5- Soil Survey Area


SELECT 

areasymbol, muname, mukey, compname, cokey, comppct_r, (SELECT DISTINCT SUBSTRING(  (  SELECT ( '; ' + lao.areasymbol)
FROM mapunit AS m
INNER JOIN muaoverlap AS mua ON mua.mukey=m.mukey 
INNER JOIN laoverlap AS lao ON mua.lareaovkey = lao.lareaovkey AND lao.areatypename='mlra'   AND s.mukey=m.mukey
ORDER BY lao.areasymbol ASC 
FOR XML PATH('') ), 3, 1000) )as [mlra_sym], 
taxtempcl, taxmoistscl, taxtempregime , 
(SELECT TOP 1 taxmoistcl  FROM component AS t INNER JOIN cotaxmoistcl ON t.cokey=cotaxmoistcl.cokey AND t.cokey=s.cokey) AS soil_moisture_class

FROM (SELECT   areasymbol, muname,musym,  mapunit.mukey, compname, c.cokey, comppct_r, taxtempcl, taxmoistscl, taxtempregime
FROM legend 
       INNER JOIN mapunit ON mapunit.lkey=legend.lkey and areasymbol <> 'US' 
	   
              INNER JOIN component AS c ON c.mukey=mapunit.mukey
			  AND majcompflag = 'Yes' 
			 
			  ) AS s 

ORDER BY areasymbol ASC, muname ASC, mukey, compname,  comppct_r DESC, cokey
