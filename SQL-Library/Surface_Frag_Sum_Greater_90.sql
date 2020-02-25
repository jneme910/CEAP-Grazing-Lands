SELECT DISTINCT areaname, areasymbol, muname, mu.mukey, compname, comppct_r, majcompflag,  chorizon.hzname,   chorizon.hzdept_r,  chorizon.hzdepb_r, chorizon.chkey,   s.hzdept_r,  s.hzdepb_r, s.chkey, s.frag_sum 
FROM legend  AS l
INNER JOIN  mapunit AS mu ON mu.lkey = l.lkey  --AND l.areasymbol = 'WI003'
INNER JOIN  component AS c ON c.mukey = mu.mukey  AND majcompflag = 'Yes'
INNER JOIN(chorizon INNER JOIN chtexturegrp ON chorizon.chkey = chtexturegrp.chkey) ON c.cokey = chorizon.cokey
AND (((chorizon.hzdept_r)=(SELECT Min(chorizon.hzdept_r) AS MinOfhzdept_r
FROM chorizon INNER JOIN chtexturegrp ON chorizon.chkey = chtexturegrp.chkey
AND chtexturegrp.texture Not In ('SPM','HPM', 'MPM') AND chtexturegrp.rvindicator='Yes' AND c.cokey = chorizon.cokey ))AND ((chtexturegrp.rvindicator)='Yes'))
INNER JOIN (SELECT  ch.hzdept_r,  ch.hzdepb_r,  ch.chkey, SUM (fragvol_r) AS frag_sum
FROM chorizon AS ch INNER JOIN chfrags AS chf ON chf.chkey=ch.chkey 
GROUP BY ch.chkey, hzdept_r, ch.hzdepb_r
 ) 

--GROUP BY compname, localphase, tfact HAVING COUNT (tfact) > 1)
 AS s ON s.chkey=chorizon.chkey AND s.frag_sum >=  90
ORDER BY areasymbol ASC , areaname,  muname, mu.mukey, s.hzdept_r,  s.hzdepb_r, s.chkey
--AND SUM (fragvol_r) over(partition by ch.chkey ORDER BY ch.chkey  ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)>= 90