USE sdmONLINE
go

DROP TABLE IF EXISTS #map;
DROP TABLE IF EXISTS #water
DROP TABLE IF EXISTS #water2
DROP TABLE IF EXISTS #comp
DROP TABLE IF EXISTS #horizon
DROP TABLE IF EXISTS #surface
DROP TABLE IF EXISTS #surface_tex
DROP TABLE IF EXISTS #surface_tex2
DROP TABLE IF EXISTS #surface_tex3
--Define the area
DECLARE @area VARCHAR(20);
--~DeclareChar(@area,20)~
SELECT @area= 'WI001';



------------------------------------------------------------------------------------
--creates the temp table for map unit and legend
CREATE TABLE #map
   ( areaname VARCHAR (135), 
    areasymbol VARCHAR (20),
    musym VARCHAR (20), 
	mukey INT, 
	muname VARCHAR (135))


--Queries the map unit and legend

INSERT INTO #map (areaname, areasymbol, musym, mapunit.mukey, muname)
SELECT areaname, areasymbol, musym, mapunit.mukey, muname
FROM (legend 
INNER JOIN mapunit ON legend.lkey=mapunit.lkey AND areasymbol = @area)  


------------------------------------------------------------------------------------
---Queries the major components 
CREATE TABLE #comp ( mukey INT , compname VARCHAR (60), cokey INT, comppct_r  SMALLINT, landform VARCHAR (60), min_yr_water INT,  subgroup VARCHAR (10), greatgroup VARCHAR (10))

TRUNCATE TABLE #comp
INSERT INTO #comp (mukey, compname, cokey, comppct_r , landform, min_yr_water, subgroup, greatgroup)
SELECT  #map.mukey, compname, cokey, comppct_r ,
(SELECT TOP 1 cogeomordesc.geomfname FROM cogeomordesc WHERE c.cokey = cogeomordesc.cokey AND cogeomordesc.rvindicator='yes' and cogeomordesc.geomftname = 'Landform') as landform, 

(SELECT TOP 1 MIN (soimoistdept_r) FROM component AS c2 
INNER JOIN comonth ON c2.cokey=comonth.cokey 
INNER JOIN cosoilmoist ON cosoilmoist.comonthkey=comonth.comonthkey
AND c2.cokey=c.cokey AND soimoiststat = 'wet'  GROUP BY c2.cokey) AS min_yr_water,

CASE WHEN taxsubgrp LIKE '%natr%' THEN 'natr' WHEN taxsubgrp  LIKE '%gyps%' THEN 'gyps' ELSE 'NA' END AS subgroup, 

CASE WHEN taxgrtgroup LIKE '%verti%' THEN 'verti' 
WHEN taxgrtgroup  LIKE '%natr%' THEN 'natr' 
WHEN taxgrtgroup  LIKE '%calci%' THEN 'calci' 
WHEN taxgrtgroup  LIKE '%gyps%' THEN 'gyps' 
ELSE 'NA' END AS greatgroup
FROM #map
INNER JOIN component AS c ON c.mukey=#map.mukey AND majcompflag = 'Yes';


------------------------------------------------------------------------------------
---Queries the Min water table by component
--creates the temp table for component min water table by month
CREATE TABLE #water
   ( mukey INT , compname VARCHAR (60), month VARCHAR (25), cokey INT , min_water INT)

--Min Soil water table
TRUNCATE TABLE #water
INSERT INTO #water (mukey, compname, month, cokey, min_water)
SELECT  #map.mukey, compname, month, 
c3.cokey, MIN(soimoistdept_r) over(partition by c3.cokey) as min_water 
FROM #map
INNER JOIN component AS c3 ON c3.mukey=#map.mukey AND majcompflag = 'Yes'
INNER JOIN comonth ON c3.cokey=comonth.cokey 
INNER JOIN cosoilmoist ON cosoilmoist.comonthkey=comonth.comonthkey AND soimoiststat = 'wet' ;



------------------------------------------------------------------------------------
--Average Water table for Apr-Sept and Oct-March
--link
CREATE TABLE #water2
   ( mukey INT , compname VARCHAR (60),  avg_h20_apr2sept INT, avg_h20_oct2march INT,  cokey INT)

TRUNCATE TABLE #water2
INSERT INTO #water2 (mukey, compname ,  avg_h20_apr2sept , avg_h20_oct2march ,cokey) 
SELECT DISTINCT mukey, compname,   (SELECT AVG (min_water) FROM #water AS w2 WHERE w2.cokey=#water.cokey AND CASE WHEN month  = 'April' THEN 1
 WHEN month  = 'May'THEN 1
 WHEN month  = 'June' THEN 1
 WHEN month  = 'July' THEN 1
 WHEN month  = 'August' THEN 1
 WHEN month  = 'September' THEN 1 ElSE 2 END = 1) AS avg_h20_apr2sept, 
 (SELECT AVG (min_water) FROM #water AS w3 WHERE w3.cokey=#water.cokey AND CASE WHEN month  = 'October' THEN 1
 WHEN month  = 'November' THEN 1
 WHEN month  = 'December' THEN 1
 WHEN month  = 'February' THEN 1
 WHEN month  = 'March' THEN 1
ElSE 2 END = 1) AS avg_h20_oct2march, cokey
FROM #water


------------------------------------------------------------------------------------
--Queries the all horizons and aggregates to 1 value based on different conditions
-- Add suffix S and flag for spodic
--link
CREATE TABLE #horizon
   ( mukey INT , compname VARCHAR (60), cokey INT,  landform VARCHAR (60), min_yr_water INT, subgroup VARCHAR (10), greatgroup VARCHAR (10), max_ec_profile REAL, max_sar_profile REAL, maxcaco3_0_2cm SMALLINT, maxcaco3_2_13cm SMALLINT, maxcaco3_13_50cm SMALLINT, maxsar_0_2cm SMALLINT ,maxsar_2_13cm SMALLINT, maxsar_13_50cm SMALLINT)

TRUNCATE TABLE #horizon
INSERT INTO #horizon ( mukey, compname, cokey,  landform, min_yr_water, subgroup, greatgroup, max_ec_profile, max_sar_profile, maxcaco3_0_2cm, maxcaco3_2_13cm, maxcaco3_13_50cm, maxsar_0_2cm, maxsar_2_13cm, maxsar_13_50cm) 
SELECT DISTINCT mukey, compname, #comp.cokey, landform, min_yr_water, subgroup, greatgroup, MAX(ec_r) over(partition by #comp.cokey) as max_ec_profile, MAX(sar_r) over(partition by #comp.cokey) as max_sar_profile, 
(Select  MAX(caco3_r) FROM component AS c INNER JOIN chorizon AS ch ON ch.cokey=c.cokey AND  hzdept_r < 2 and ch.cokey= #comp.cokey) as maxcaco3_0_2cm,
(Select  MAX(caco3_r) FROM component AS c INNER JOIN chorizon AS ch ON ch.cokey=c.cokey AND  hzdepb_r >= 2 and hzdept_r <13 and ch.cokey= #comp.cokey) as maxcaco3_2_13cm,
(Select  MAX(caco3_r) FROM component AS c INNER JOIN chorizon AS ch ON ch.cokey=c.cokey AND  hzdepb_r >= 13 and hzdept_r <50 and ch.cokey= #comp.cokey) as maxcaco3_13_50cm, 
(Select  MAX(gypsum_r) FROM component AS c INNER JOIN chorizon AS ch ON ch.cokey=c.cokey AND  hzdept_r < 2 and ch.cokey= #comp.cokey) as maxgypsum_0_2cm,
(Select  MAX(gypsum_r) FROM component AS c INNER JOIN chorizon AS ch ON ch.cokey=c.cokey AND  hzdepb_r >= 2 and hzdept_r <13 and ch.cokey= #comp.cokey) as maxgypsum_2_13cm,
(Select  MAX(gypsum_r) FROM component AS c INNER JOIN chorizon AS ch ON ch.cokey=c.cokey AND  hzdepb_r >= 13 and hzdept_r <50 and ch.cokey= #comp.cokey) as maxgypsum_13_50cm
FROM #comp
INNER JOIN chorizon ON chorizon.cokey=#comp.cokey 


------------------------------------------------------------------------------------
--Queries surface mineral horizon, eliminates duff layer but keeps wet organics -- Surface Mineralogy (separating Organic from Mineral)
--Link
CREATE TABLE #surface(cokey INT, chkey  INT, compname VARCHAR (60), hzname VARCHAR (12), hzdept_r SMALLINT, hzdepb_r SMALLINT, texture VARCHAR (30) , mineral_des VARCHAR (10), om_r REAL ,  surface_mineral VARCHAR(3))

 INSERT INTO #surface(cokey , chkey  , compname, hzname , hzdept_r , hzdepb_r , texture, mineral_des, om_r, surface_mineral )
SELECT 
 #comp.cokey, chorizon.chkey, compname, hzname, hzdept_r, hzdepb_r, texture, 
 CASE WHEN desgnmaster LIKE '%h%' THEN 'H horizon'
 WHEN desgnmaster LIKE '%O%' THEN 'Organic' 
 WHEN  desgnmaster NOT LIKE '%O%' THEN 'Mineral' ELSE 'NA' END AS mineral_des, 
CAST (ISNULL (om_r, 0) AS decimal (5,2))AS om_r,
CASE WHEN ((claytotal_r) IS NOT NULL  AND (om_r) IS NOT NULL AND om_r >= 18*1.724 and claytotal_r >= 60) THEN 'Yes'
WHEN ((claytotal_r) IS NOT NULL  AND (om_r) IS NOT NULL AND (om_r >=(12 +(claytotal_r*0.1))*1.724) AND claytotal_r < 60) THEN 'Yes'
WHEN  (om_r >= 20*1.724 AND  (claytotal_r)  IS NOT NULL AND (om_r) IS NOT NULL) THEN 'Yes' 
ELSE 'No' END AS surface_mineral
FROM #comp  
INNER JOIN(chorizon INNER JOIN chtexturegrp ON chorizon.chkey = chtexturegrp.chkey) ON #comp.cokey = chorizon.cokey
AND (((chorizon.hzdept_r)=(SELECT Min(chorizon.hzdept_r) AS MinOfhzdept_r
FROM chorizon INNER JOIN chtexturegrp ON chorizon.chkey = chtexturegrp.chkey
AND chtexturegrp.texture Not In ('SPM','HPM', 'MPM') 
AND chtexturegrp.rvindicator='Yes' AND #comp.cokey = chorizon.cokey ))AND ((chtexturegrp.rvindicator)='Yes'))
ORDER BY comppct_r DESC, cokey,  hzdept_r, hzdepb_r



------------------------------------------------------------------------------------
---Soil Surface Texture Class by Thickness (not depth)
---Eliminates Duff layer at the end and aggregates texture grouping
CREATE TABLE #surface_tex (cokey INT, chkey  INT, compname VARCHAR (60), hzname VARCHAR (12), hzdept_r SMALLINT, hzdepb_r SMALLINT, texture VARCHAR (30) ,  tex_modifier VARCHAR (254), tex VARCHAR (254), tex_in_lieu VARCHAR (254),  row_num INT, text_grouping VARCHAR (254))

 INSERT INTO #surface_tex (cokey, chkey, compname, hzname, hzdept_r, hzdepb_r, texture, tex_modifier, tex, tex_in_lieu, row_num, text_grouping ) 
-- OUTPUT  INSERTED.cokey, INSERTED.chkey, INSERTED.compname, INSERTED.hzname, INSERTED.hzdept_r, INSERTED.hzdepb_r, INSERTED.texture, INSERTED.tex_modifier, INSERTED.tex, INSERTED.tex_in_lieu, INSERTED.row_num, INSERTED.text_grouping ---For testing to display

 SELECT 
 #comp.cokey, chorizon.chkey, compname, hzname, hzdept_r, hzdepb_r, texture, 

(SELECT TOP 1 [ChoiceName] FROM chtexture AS cht, MetadataDomainMaster dm, MetadataDomainDetail dd, chtexturemod AS chtm WHERE  chtm.chtkey=cht.chtkey AND chtexturegrp.chtgkey=cht.chtgkey and texmod = ChoiceLabel and DomainName = 'texture_modifier' AND 
dm.DomainID=dd.DomainID ORDER BY choicesequence DESC) AS  tex_modifier,

(SELECT TOP 1 [ChoiceName] FROM chtexture AS cht, MetadataDomainMaster dm, MetadataDomainDetail dd WHERE chtexturegrp.chtgkey=cht.chtgkey and texcl = ChoiceLabel and DomainName = 'texture_class' AND 
dm.DomainID=dd.DomainID ORDER BY choicesequence DESC) AS  tex,

(SELECT TOP 1 [ChoiceName] FROM chtexture AS cht, MetadataDomainMaster dm, MetadataDomainDetail dd WHERE chtexturegrp.chtgkey=cht.chtgkey and lieutex = ChoiceLabel and DomainName = 'terms_used_in_lieu_of_texture' AND 
dm.DomainID=dd.DomainID ORDER BY choicesequence DESC) AS  tex_in_lieu,

 row_number() over (PARTITION BY #comp.cokey order by hzdept_r ASC ) as row_num, 
 CASE WHEN stratextsflag = 'Yes' THEN 'stratified'
 WHEN desgnmaster = 'O' THEN 'organic' END AS text_grouping 
FROM #comp 
INNER JOIN(chorizon INNER JOIN chtexturegrp ON chorizon.chkey = chtexturegrp.chkey AND chtexturegrp.rvindicator='Yes') ON #comp.cokey = chorizon.cokey

------------------------------------------------------------------------------------
-- surface tex 2 table
CREATE TABLE #surface_tex2 (cokey INT, chkey  INT, compname VARCHAR (60), hzname VARCHAR (12), hzdept_r SMALLINT, hzdepb_r SMALLINT, texture VARCHAR (30) ,  tex_modifier VARCHAR (254), tex VARCHAR (254), tex_in_lieu VARCHAR (254),  row_num INT, text_grouping VARCHAR (254), texture_grouping VARCHAR (254),  hz_diag_kind VARCHAR (254), texture_grouping_value INT)

 INSERT INTO #surface_tex2 (cokey, chkey, compname, hzname, hzdept_r, hzdepb_r, texture, tex_modifier, tex, tex_in_lieu, row_num, text_grouping, texture_grouping,  hz_diag_kind, texture_grouping_value ) 

SELECT cokey, chkey, compname, hzname, hzdept_r, hzdepb_r, texture, tex_modifier, tex, tex_in_lieu, row_num, text_grouping, 

CASE WHEN text_grouping = 'organic'  THEN 'organic' 
WHEN text_grouping =  'stratified' THEN 'stratified'
WHEN tex_modifier IN ('ASHY', 'HYDR', 'MEDL') THEN 'volcanic modifier'
WHEN tex_modifier IN ('GS', 'HB', 'MS', 'WD') THEN 'organic soil material modifier'
WHEN tex_modifier IN ('HO', 'MK', 'PT') THEN 'highly organic mineral material modifier'
WHEN tex_modifier IN ('COP', 'DIA', 'MR') THEN 'limnic material modifier'
WHEN tex_modifier IN ('ART', 'ARTV', 'ARTVX') THEN 'anthropogenic material modifier'
WHEN tex_modifier = 'CEM' THEN 'cemented material modifier'
WHEN tex_modifier = 'GYP' THEN 'gypsiferous material modifier'
WHEN tex_modifier = 'PF' THEN 'permanently frozen material modifier'
WHEN tex = 'COS' THEN 'coarse textured'
WHEN tex = 'S'  THEN 'coarse textured'
WHEN tex = 'FS' THEN 'coarse textured'
WHEN tex = 'VFS' THEN 'coarse textured'
WHEN tex = 'LCOS' THEN 'coarse textured'
WHEN tex ='LS' THEN 'coarse textured'
WHEN tex = 'LFS' THEN 'coarse textured'
WHEN tex = 'LVFS'THEN 'coarse textured'
WHEN tex = 'COSL' THEN 'moderately coarse textured'
WHEN tex = 'SL' THEN 'moderately coarse textured'
WHEN tex = 'FSL' THEN 'moderately coarse textured'
WHEN tex = 'VFSL' THEN 'medium textured' 
WHEN tex = 'L' THEN 'medium textured' 
WHEN tex = 'SIL' THEN 'medium textured' 
WHEN tex = 'SI'  THEN 'medium textured' 
WHEN tex = 'CL'  THEN 'moderately fine textured'
WHEN tex = 'SCL' THEN 'moderately fine textured'
WHEN tex = 'SICL' THEN 'moderately fine textured'
WHEN tex = 'SC'  THEN  'fine textured' 
WHEN tex = 'SIC' THEN  'fine textured' 
WHEN tex = 'C' THEN  'fine textured' END AS texture_grouping,
CASE WHEN hzname LIKE '%Cr%'  THEN 'paralithic' -- I need to double check horizon suffix
WHEN hzname LIKE '%R%' THEN 'lithic'
WHEN hzname LIKE '%d' THEN 'densic'
WHEN hzname LIKE '%qm%' THEN 'duripan'
WHEN hzname LIKE '%km%' THEN 'petrocalcic'
WHEN hzname LIKE '%ym%' THEN 'petrogypsic'
WHEN hzname LIKE '%x%' THEN 'fragipan' -- may not meet fragipan
WHEN hzname LIKE '%hs%' THEN 'spodic'
WHEN hzname LIKE '%m%' THEN 'petro' END AS hz_diag_kind,
CASE WHEN text_grouping = 'organic'  THEN 1 --'organic' 
WHEN text_grouping =  'stratified' THEN 2--'stratified'
WHEN tex_modifier IN ('ASHY', 'HYDR', 'MEDL') THEN 3-- 'volcanic modifier'
WHEN tex_modifier IN ('GS', 'HB', 'MS', 'WD') THEN 4--'organic soil material modifier'
WHEN tex_modifier IN ('HO', 'MK', 'PT') THEN 5--'highly organic mineral material modifier'
WHEN tex_modifier IN ('COP', 'DIA', 'MR') THEN 6--'limnic material modifier'
WHEN tex_modifier IN ('ART', 'ARTV', 'ARTVX') THEN 7--'anthropogenic material modifier'
WHEN tex_modifier = 'CEM' THEN 8--'cemented material modifier'
WHEN tex_modifier = 'GYP' THEN 9--'gypsiferous material modifier'
WHEN tex_modifier = 'PF' THEN 10--'permanently frozen material modifier'
WHEN tex = 'COS' THEN 11--'coarse textured'
WHEN tex = 'S'  THEN 11--'coarse textured'
WHEN tex = 'FS' THEN 11--'coarse textured'
WHEN tex = 'VFS' THEN 11--'coarse textured'
WHEN tex = 'LCOS' THEN 11--'coarse textured'
WHEN tex ='LS' THEN 11--'coarse textured'
WHEN tex = 'LFS' THEN 11--'coarse textured'
WHEN tex = 'LVFS'THEN 11--'coarse textured'
WHEN tex = 'COSL' THEN 12--'moderately coarse textured'
WHEN tex = 'SL' THEN 12--'moderately coarse textured'
WHEN tex = 'FSL' THEN 12--'moderately coarse textured'
WHEN tex = 'VFSL' THEN 13--'medium textured' 
WHEN tex = 'L' THEN 13--'medium textured' 
WHEN tex = 'SIL' THEN 13--'medium textured' 
WHEN tex = 'SI'  THEN 13--'medium textured' 
WHEN tex = 'CL'  THEN 14--'moderately fine textured'
WHEN tex = 'SCL' THEN 14--'moderately fine textured'
WHEN tex = 'SICL' THEN 14--'moderately fine textured'
WHEN tex = 'SC'  THEN  15-- 'fine textured' 
WHEN tex = 'SIC' THEN 15-- 'fFine textured' 
WHEN tex = 'C' THEN  15--'fine textured' 
ELSE 16 END AS texture_grouping_value


FROM #surface_tex


------------------------------------------------------------------------------------
---Surface Text 
--CREATE TABLE #surface_tex3 (cokey INT, chkey INT, compname VARCHAR (60),  tex_modifier VARCHAR (254), tex_in_lieu VARCHAR (254),   texture_grouping VARCHAR (254), hz_diag_kind VARCHAR (254),  hzname VARCHAR (12), hzdept_r SMALLINT, hzdepb_r SMALLINT,   min_top_depth INT, max_bottom_depth INT, row_num INT)
--INSERT INTO #surface_tex3 (cokey,	chkey,   compname,			   tex_modifier,			   tex_in_lieu,					texture_grouping,				hz_diag_kind,				 hzname,  hzdept_r, hzdepb_r,  min_top_depth ,	   max_bottom_depth ,     row_num  ) 

SELECT 
cokey, chkey,
compname, 
tex_modifier,  
tex_in_lieu, 
texture_grouping, 
hz_diag_kind ,  hzname,  hzdept_r, hzdepb_r, --tex,  

MIN(hzdept_r) over(partition by   cokey, texture_grouping order by hzdept_r ASC) as min_top_depth, 

last_value(hzdepb_r) over(partition by cokey, texture_grouping_value 
  order by hzdept_r ASC
  rows BETWEEN unbounded preceding and unbounded following
  ) as max_bottom_depth,
  ISNULL (LAG(texture_grouping) OVER(PARTITION BY cokey ORDER BY hzdept_r ASC ),texture_grouping)  as prev_texture_grouping,
   ISNULL (LAG(hzdepb_r) OVER(PARTITION BY cokey ORDER BY hzdept_r ASC), hzdept_r) as prev_bottom_depth,

--hzdepb_r,
--(SELECT  COUNT (*)  FROM #surface_tex2 AS s2 WHERE s2.cokey=s1.cokey GROUP BY cokey, texture_grouping, hzdept_r  ) AS test,
--COUNT (*) OVER(PARTITION BY cokey, texture_grouping ORDER BY hzdept_r ASC) AS ct,
ROW_NUMBER() OVER(PARTITION BY cokey, texture_grouping ORDER BY hzdept_r ASC ) AS row_num
--ROW_NUMBER() OVER(PARTITION BY cokey ORDER BY hzdept_r ASC) AS row_num2
FROM #surface_tex2  AS s1
WHERE CASE 
WHEN tex_in_lieu = 'spm' THEN 1
WHEN tex_in_lieu = 'hpm' THEN 1
WHEN tex_in_lieu = 'mpm' THEN 1
WHEN tex_in_lieu IS NULL THEN 2 ELSE 2 END = 2
ORDER BY cokey,  hzdept_r , hzdepb_r,  chkey

--SELECT cokey, texture_grouping, hzdept_r  --, chkey, (SELECT TOP 1 MIN (hzdept_r ) over(partition by cokey order by hzdept_r  ASC)  FROM #surface_tex3 AS s2 WHERE s2.cokey=s1.cokey GROUP BY cokey, texture_grouping, hzdept_r   ORDER BY hzdept_r ASC) AS test, 
--DENSE_RANK() OVER(PARTITION BY cokey, texture_grouping ORDER BY cokey, hzdept_r) AS row_num ,
--MIN(min_top_depth) over(partition by cokey order by min_top_depth ASC)  AS MIN_depth
--FROM #surface_tex3 AS s1 WHERE s2.cokey=s1.cokey 
--GROUP BY cokey, texture_grouping
--ORDER BY cokey, hzdept_r  ASC



------------------------------------------------------------------------------------
---Final Surface
--SELECT DISTINCT cokey, compname,  tex_modifier, tex_in_lieu,   texture_grouping, hzname,  hzdept_r, hzdepb_r,  hz_diag_kind, min_top_depth , max_bottom_depth ,  row_num 
--FROM #surface_tex3 AS s1
--WHERE min_top_depth IN (SELECT MIN(min_top_depth) over(partition by cokey order by min_top_depth ASC)  FROM #surface_tex3 AS s2 WHERE s2.cokey=s1.cokey GROUP BY cokey, texture_grouping ) ---Gets the min rows and eliminates the extra. This step is needed to get the max depth.


--WHERE row_num = 1


------------------------------------------------------------------------------------
---Fragments 
--SELECT cokey , #surface.chkey  , compname, hzname , hzdept_r , hzdepb_r , texture, mineral_des, om_r, surface_mineral, fragvol_r, fragkind, fragsize_r, fragshp, fraground,fraghard,

--FROM #surface
---INNER JOIN chfrags ON chfrags.chkey=#surface.chkey

DROP TABLE IF EXISTS #map;
DROP TABLE IF EXISTS #water;
DROP TABLE IF EXISTS #water2;
DROP TABLE IF EXISTS #comp;
DROP TABLE IF EXISTS #horizon;
DROP TABLE IF EXISTS #surface;
DROP TABLE IF EXISTS #surface_tex;
DROP TABLE IF EXISTS #surface_tex2;
DROP TABLE IF EXISTS #surface_tex3;