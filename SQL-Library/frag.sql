SELECT c.cokey , ch.chkey  , compname, hzname , hzdept_r , hzdepb_r , --texture, 
--mineral_des, om_r, surface_mineral, 
fragvol_r, fragkind, fragsize_r, fragshp, fraground,fraghard,
 CASE 
	  WHEN  fragshp = 'Flat'	AND  (fragsize_l >= 2		AND  fragsize_h <= 150)	THEN 'channers' 
      WHEN  fragshp = 'Flat'	AND  (fragsize_l >= 150		AND  fragsize_h <= 380)	THEN 'flagstones' 
      WHEN  fragshp = 'Flat'	AND  (fragsize_l >= 380		AND  fragsize_h <= 600)	THEN 'stones' 
      WHEN  fragshp = 'Flat'	AND   fragsize_l >= 600								THEN 'boulders'
--	  WHEN  fragshp = 'Nonflat' AND  (fragsize_l >= 2		AND  fragsize_h <= 5)	THEN 'fine gravel' 
--    WHEN  fragshp = 'Nonflat' AND  (fragsize_l >= 5		AND  fragsize_h <= 20)  THEN 'medium gravel' 
--    WHEN  fragshp = 'Nonflat' AND  (fragsize_l >= 20		AND  fragsize_h <= 75)  THEN 'coarse gravel' 
      WHEN  fragshp = 'Nonflat' AND  (fragsize_l >= 75		AND  fragsize_h <= 250)  THEN 'cobbles' 
      WHEN  fragshp = 'Nonflat' AND  (fragsize_l >= 250		AND  fragsize_h <= 600)	THEN 'stones' 
      WHEN  fragshp = 'Nonflat' AND  (fragsize_l >= 600)							THEN 'boulders' 
      WHEN  fragshp = 'Nonflat' AND  (fragsize_l =  2		AND  fragsize_h  = 75)	THEN 'gravel' 
      WHEN  fragshp = 'Nonflat' AND  (fragsize_l >= 2		AND  fragsize_h <= 20)  THEN 'fine  AND  medium gravel' 
      WHEN  fragshp = 'Nonflat' AND  (fragsize_l >= 5		AND  fragsize_h <= 75)  THEN 'medium  AND  coarse gravel' 
	  
	  WHEN							  (fragsize_l >= 75		AND  fragsize_h <= 250)  THEN 'cobbles' 
      WHEN							  (fragsize_l >= 250	AND  fragsize_h <= 600)	THEN 'stones' 
      WHEN							  (fragsize_l >= 600)							THEN 'boulders' 
      WHEN							  (fragsize_l =  2		AND  fragsize_h  = 75)	THEN 'gravel' 
--    WHEN							  (fragsize_l >= 2		AND  fragsize_h <= 20)  THEN 'fine  AND  medium gravel' 
--    WHEN							  (fragsize_l >= 5		AND  fragsize_h <= 75)  THEN 'medium  AND  coarse gravel' 

	  ELSE '(shape or size unspecified)' END AS fun_with_frags,


CASE 
	  WHEN  (fragshp = 'Flat'	AND  fragsize_r BETWEEN   2	AND 150)	THEN 'channers' 
      WHEN  (fragshp = 'Flat'	AND  fragsize_r BETWEEN   150 AND 380)	THEN 'flagstones' 
      WHEN  (fragshp = 'Flat'	AND  fragsize_r BETWEEN   380 AND 600)	THEN 'stones' 
      WHEN  (fragshp = 'Flat'	AND   fragsize_r >= 600)								THEN 'boulders'
--	  WHEN  fragshp = 'Nonflat' AND  fragsize_r BETWEEN   2		AND 5)	THEN 'fine gravel' 
--    WHEN  fragshp = 'Nonflat' AND  fragsize_r BETWEEN   5		AND 20)  THEN 'medium gravel' 
--    WHEN  fragshp = 'Nonflat' AND  fragsize_r BETWEEN   20		AND 75)  THEN 'coarse gravel' 
      WHEN  (fragshp = 'Nonflat' AND  fragsize_r BETWEEN   75 AND 250)  THEN 'cobbles' 
      WHEN  (fragshp = 'Nonflat' AND  fragsize_r BETWEEN   250 AND 600)	THEN 'stones' 
      WHEN  (fragshp = 'Nonflat' AND  fragsize_r >=  600)							THEN 'boulders' 
      WHEN  (fragshp = 'Nonflat' AND  fragsize_r BETWEEN   2	 AND 75)	THEN 'gravel' 
--      WHEN  fragshp = 'Nonflat' AND  fragsize_r BETWEEN   2	AND 20)  THEN 'fine and medium gravel' 
--      WHEN  fragshp = 'Nonflat' AND  fragsize_r BETWEEN   5	AND 75)  THEN 'medium and coarse gravel' 
	  
	  WHEN							 (fragsize_r BETWEEN 75	AND 250)  THEN 'cobbles' 
      WHEN							 (fragsize_r BETWEEN  250	AND 600)	THEN 'stones' 
      WHEN							  (fragsize_r >=  600)							THEN 'boulders' 
      WHEN							  (fragsize_r BETWEEN  2 AND 75)	THEN 'gravel' 
--    WHEN							  (fragsize_r  2		AND 20)  THEN 'fine and medium gravel' 
--    WHEN							  (fragsize_r  5		AND 75)  THEN 'medium and coarse gravel' 

	  ELSE '(shape or size unspecified)' END AS fun_with_frags_part_duo


FROM legend AS l
INNER JOIN mapunit AS m ON m.lkey=l.lkey AND areasymbol = 'WI001'
INNER JOIN component AS c ON c.mukey=m.mukey AND majcompflag = 'Yes'
INNER JOIN chorizon AS ch ON ch.cokey=c.cokey
INNER JOIN chfrags AS chf ON chf.chkey=ch.chkey