USE sdmONLINE

SELECT DISTINCT  [taxgrtgroup] ,  CASE
                    WHEN taxgrtgroup LIKE '%ert%'
                        THEN 'verti'
                    WHEN taxgrtgroup LIKE '%natr%'
                        THEN 'natr'
                    WHEN taxgrtgroup LIKE '%calci%'
                        THEN 'calci'
                    WHEN taxgrtgroup LIKE '%gyps%'
                        THEN 'gyps'
                    ELSE
                        'NA'
                END                                                                AS greatgroup
				--TOP 10   areasymbol, muname, m.mukey
FROM legend AS l
INNER JOIN mapunit AS m ON m.lkey=l.lkey 
INNER JOIN component AS c ON c.mukey=m.mukey ORDER  BY taxgrtgroup ASC