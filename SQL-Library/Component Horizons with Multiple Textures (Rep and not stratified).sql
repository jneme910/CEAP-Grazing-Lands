SELECT DISTINCT areasymbol, areaname, musym,  muname, m.mukey, compname, comppct_r

FROM legend AS l
INNER JOIN mapunit AS m ON m.lkey=l.lkey AND areasymbol <> 'US'
INNER JOIN component ON component.mukey=m.mukey AND majcompflag = 'Yes'
INNER JOIN chorizon ON chorizon.cokey=component.cokey
INNER JOIN chtexturegrp ON chorizon.chkey = chtexturegrp.chkey AND chtexturegrp.rvindicator='Yes'
INNER JOIN chtexture ON chtexture.chtgkey=chtexturegrp.chtgkey AND stratextsflag != 'Yes' AND rvindicator =  'Yes' 
WHERE chtexturegrp.chtgkey IN
(SELECT chtgkey FROM chtexture
GROUP BY chtgkey
HAVING COUNT(*) > 1)  
ORDER BY areasymbol ASC,  musym ASC, m.mukey, comppct_r ASC
