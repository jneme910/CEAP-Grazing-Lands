SET STATISTICS IO ON

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
DROP TABLE IF EXISTS #surface_tex4
DROP TABLE IF EXISTS #surface_final
DROP TABLE IF EXISTS #fragment
DROP TABLE IF EXISTS #fragment2
DROP TABLE IF EXISTS #diag
DROP TABLE IF EXISTS #diag3
DROP TABLE IF EXISTS #d
DROP TABLE IF EXISTS #r
DROP TABLE IF EXISTS #rest_pivot_table
DROP TABLE IF EXISTS #rest
DROP TABLE IF EXISTS #frag_pivot_table
DROP TABLE IF EXISTS #ffmonth_pivot_table
DROP TABLE IF EXISTS #flood_month
DROP TABLE IF EXISTS #pfmonth_pivot_table
DROP TABLE IF EXISTS #pond_month
DROP TABLE IF EXISTS #frag
DROP TABLE IF EXISTS #surface_final2
DROP TABLE IF EXISTS #surface_final3
DROP TABLE IF EXISTS #spd
DROP TABLE IF EXISTS #acpf
DROP TABLE IF EXISTS #aws
DROP TABLE IF EXISTS #aws150

--Define the area
DECLARE @area VARCHAR(20);
DECLARE @area_type INT;
DECLARE @domc INT;

DECLARE @major INT;
DECLARE @operator VARCHAR(5);
-- Soil Data Access

/*
~DeclareChar(@area,20)~  -- Used for Soil Data Access
-~DeclareINT(@area_type)~ 
~DeclareINT(@domc)~ 
~DeclareINT(@major)~ 
~DeclareChar(@operator,20)~ 
*/
-- End soil data access
SELECT
    @area = 'NE001'; --Enter State Abbreviation or Soil Survey Area i.e. WI or  WI025,  US 
SELECT
    @domc = 0; -- Enter 0 for dominant component, enter 1 for all components
SELECT
    @major = 0; -- Enter 0 for major component, enter 1 for all components


------------------------------------------------------------------------------------
SELECT
    @area_type = LEN(@area); --determines number of characters of area 2-State, 5- Soil Survey Area
--creates the temp table for map unit and legend
CREATE TABLE #map
    (
        areaname         VARCHAR(255),
        areasymbol       VARCHAR(20),
        musym            VARCHAR(20),
        mukey            INT,
        muname           VARCHAR(250),
        datestamp        VARCHAR(32),
        major_mu_pct_sum SMALLINT,
        mlra_sym         VARCHAR(250)
    )


--Queries the map unit and legend
--Link Main
INSERT INTO #map
    (
        areaname,
        areasymbol,
        musym,
        mapunit.mukey,
        muname,
        datestamp,
        major_mu_pct_sum,
        mlra_sym
    )
            SELECT
                legend.areaname,
                legend.areasymbol,
                musym,
                mapunit.mukey,
                muname,
                CONCAT([SC].[areasymbol], ' ', FORMAT([SC].[saverest], 'dd-MM-yy')) AS datestamp,
                (
                    SELECT
                        SUM(CCO.comppct_r)
                    FROM
                        mapunit       AS MM2
                        INNER JOIN
                            component AS CCO
                                ON CCO.mukey = MM2.mukey
                                   AND mapunit.mukey = MM2.mukey
                                   AND (CASE
                                            WHEN 1 = @major
                                                THEN 0
                                            WHEN majcompflag = 'Yes'
                                                THEN 0
                                            ELSE
                                                1
                                        END = 0
                                       )
                --AND majcompflag = 'Yes'

                )                                                                   AS major_mu_pct_sum,
                (
                    SELECT DISTINCT
                        SUBSTRING(
                            (
                                SELECT ('; ' + lao.areasymbol)
                                FROM
                                       mapunit     AS m
                                    INNER JOIN
                                        muaoverlap AS mua
                                            ON mua.mukey = m.mukey
                                    INNER JOIN
                                        laoverlap  AS lao
                                            ON mua.lareaovkey = lao.lareaovkey
                                               AND lao.areatypename = 'mlra'
                                               AND mapunit.mukey = m.mukey
                                ORDER BY
                                       lao.areasymbol ASC
                                FOR XML PATH('')
                            ), 3, 1000
                                 )
                )                                                                   as mlra_sym
            FROM
                (legend
                INNER JOIN
                    mapunit
                        ON legend.lkey = mapunit.lkey
                          --AND areasymbol <> 'US'
                           
						   AND (CASE
                                    WHEN @area_type = 2
                                        THEN LEFT(areasymbol, 2)
                                    ELSE
                                        areasymbol
                                END = @area) 
							
                               )
                INNER JOIN
                    sacatalog SC
                        ON legend.areasymbol = SC.areasymbol


------------------------------------------------------------------------------------
---Queries the major components 
--- Link 
CREATE TABLE #comp
    (
        mukey               INT,
        compname            VARCHAR(60),
		compkind           VARCHAR(254),
        cokey               INT,
        comppct_r           SMALLINT,
        landform            VARCHAR(60),
        min_yr_water        INT,
        subgroup            VARCHAR(10),
        greatgroup          VARCHAR(10),
        wei                 VARCHAR(254),
        weg                 VARCHAR(254),
        h_spodic_flag       SMALLINT,
        h_lithic_flag       SMALLINT,
        h_parlithic_flag    SMALLINT,
        h_densic_flag       SMALLINT,
        h_duripan_flag      SMALLINT,
        h_petrocalic_flag   SMALLINT,
        h_petrogypsic_flag  SMALLINT,
        h_petro_flag        SMALLINT,
        h_salt_flag         SMALLINT,
        slope_r             REAL,
        hydgrp              VARCHAR(254),
        esd_id              VARCHAR(30),
        esd_name            VARCHAR(254),
        sum_fragcov_low     REAL,
        sum_fragcov_rv      REAL,
        sum_fragcov_high    REAL,
        major_mu_pct_sum    SMALLINT,
        adj_comp_pct        REAL,
        restrictiodepth     SMALLINT,
		PD_Fragi		SMALLINT,
        taxmoistcl          VARCHAR(20),
        taxmoistscl         VARCHAR(20),
        taxtempregime       VARCHAR(100),
        taxtempcl           VARCHAR(100),
        dom_comp_flag       VARCHAR(5),
        majcompflag         VARCHAR(5),
        soil_moisture_class VARCHAR(254),
        flood_freq          VARCHAR(254),
        flood_dur           VARCHAR(254),
        pond_freq           VARCHAR(254),
        pond_dur            VARCHAR(254) /*,
        flooding_june       VARCHAR(254),
        flooding_july       VARCHAR(254),
        flooding_august     VARCHAR(254),
        ponding_june        VARCHAR(254),
        ponding_july        VARCHAR(254),
        ponding_august      VARCHAR(254) */
    )

--TRUNCATE TABLE #comp
INSERT INTO #comp
    (
        mukey,
        compname,
		compkind,
        cokey,
        comppct_r,
        landform,
        min_yr_water,
        subgroup,
        greatgroup,
        wei,
        weg,
        h_spodic_flag,
        h_lithic_flag,
        h_parlithic_flag,
        h_densic_flag,
        h_duripan_flag,
        h_petrocalic_flag,
        h_petrogypsic_flag,
        h_petro_flag,
        h_salt_flag,
        slope_r,
        hydgrp,
        esd_id,
        esd_name,
        sum_fragcov_low,
        sum_fragcov_rv,
        sum_fragcov_high,
        major_mu_pct_sum,
        adj_comp_pct,
        restrictiodepth,
		PD_Fragi,
        taxmoistcl,
        taxmoistscl,
        taxtempregime,
        taxtempcl,
        dom_comp_flag,
        majcompflag,
        soil_moisture_class,
        flood_freq,
        flood_dur,
        pond_freq,
        pond_dur /*,
        flooding_june,
        flooding_july,
        flooding_august,
        ponding_june,
        ponding_july,
        ponding_august */
    )
            SELECT
                map.mukey,
                compname,
				compkind,
                c.cokey,
                comppct_r,
                (
                    SELECT TOP 1
                        cogeomordesc.geomfname
                    FROM
                        cogeomordesc
                    WHERE
                        c.cokey = cogeomordesc.cokey
                        AND cogeomordesc.rvindicator = 'yes'
                        and cogeomordesc.geomftname = 'Landform'
                )                                                                  as landform,
                (
                    SELECT TOP 1
                        MIN(soimoistdept_r)
                    FROM
                        component AS c2
                        INNER JOIN
                            comonth
                                ON c2.cokey = comonth.cokey
                        INNER JOIN
                            cosoilmoist
                                ON cosoilmoist.comonthkey = comonth.comonthkey
                                   AND c2.cokey = c.cokey
                                   AND soimoiststat = 'wet'
                    GROUP BY
                        c2.cokey
                )                                                                  AS min_yr_water,
                CASE
                    WHEN taxsubgrp LIKE '%natr%'
                        THEN 'natr'
                    WHEN taxsubgrp LIKE '%gyps%'
                        THEN 'gyps'
                    WHEN taxsubgrp LIKE '%verti%'
                        THEN 'verti'
                    ELSE
                        'NA'
                END                                                                AS subgroup,
                CASE
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
                END                                                                AS greatgroup,
                wei,
                weg,
                (
                    SELECT TOP 1
                        MIN(hzdept_r)
                    FROM
                        chorizon          AS ch2
                        INNER JOIN
                            chdesgnsuffix AS chs
                                ON chs.chkey = ch2.chkey
                                   AND ch2.cokey = c.cokey
                                   AND desgnsuffix = 's'
                                   AND desgnsuffix IS NOT NULL
                )                                                                  AS h_spodic_flag,
                (
                    SELECT TOP 1
                        MIN(hzdept_r)
                    FROM
                        chorizon AS ch2
                    WHERE
                        ch2.cokey = c.cokey
                        AND desgnmaster = 'R'
                )                                                                  AS h_lithic_flag,
                (
                    SELECT TOP 1
                        MIN(hzdept_r)
                    FROM
                        chorizon AS ch2
                    WHERE
                        ch2.cokey = c.cokey
                        AND hzname LIKE '%Cr%'
                )                                                                  AS h_parlithic_flag,
                (
                    SELECT TOP 1
                        MIN(hzdept_r)
                    FROM
                        chorizon AS ch2
                    WHERE
                        ch2.cokey = c.cokey
                        AND hzname LIKE '%d%'
                        AND hzname NOT LIKE '%and%'
                )                                                                  AS h_densic_flag,
                (
                    SELECT TOP 1
                        MIN(hzdept_r)
                    FROM
                        chorizon AS ch2
                    WHERE
                        ch2.cokey = c.cokey
                        AND hzname LIKE '%qm%'
                )                                                                  AS h_duripan_flag,
                (
                    SELECT TOP 1
                        MIN(hzdept_r)
                    FROM
                        chorizon AS ch2
                    WHERE
                        ch2.cokey = c.cokey
                        AND hzname LIKE '%km%'
                )                                                                  AS h_petrocalic_flag,
                (
                    SELECT TOP 1
                        MIN(hzdept_r)
                    FROM
                        chorizon AS ch2
                    WHERE
                        ch2.cokey = c.cokey
                        AND hzname LIKE '%ym%'
                )                                                                  AS h_petrogypsic_flag,
                (
                    SELECT TOP 1
                        MIN(hzdept_r)
                    FROM
                        chorizon AS ch2
                    WHERE
                        ch2.cokey = c.cokey
                        AND hzname LIKE '%m%'
                )                                                                  AS h_petro_flag,
                (
                    SELECT TOP 1
                        MIN(hzdept_r)
                    FROM
                        chorizon AS ch2
                    WHERE
                        ch2.cokey = c.cokey
                        AND hzname LIKE '%z%'
                )                                                                  AS h_salt_flag,
                slope_r,
                hydgrp,
                (
                    SELECT TOP 1
                        ecoclassid
                    FROM
                        component AS ce1
                        INNER JOIN
                            coecoclass
                                on ce1.cokey = coecoclass.cokey
                                   and coecoclass.ecoclassref like 'Ecological Site Description Database'
                                   AND ce1.cokey = c.cokey
                )                                                                  AS esd_id,
                (
                    SELECT TOP 1
                        ecoclassname
                    FROM
                        component AS ce1
                        INNER JOIN
                            coecoclass
                                on ce1.cokey = coecoclass.cokey
                                   and coecoclass.ecoclassref like 'Ecological Site Description Database'
                                   AND ce1.cokey = c.cokey
                )                                                                  AS esd_name,
                (
                    SELECT
                        ROUND(SUM(sfragcov_l), 2)
                    FROM
                        component       AS c2
                        INNER JOIN
                            cosurffrags AS cosf
                                ON cosf.cokey = c2.cokey
                                   AND c2.cokey = c.cokey
                    GROUP BY
                        c2.cokey
                )                                                                  AS sum_fragcov_low,
                (
                    SELECT
                        ROUND(SUM(sfragcov_r), 2)
                    FROM
                        component       AS c2
                        INNER JOIN
                            cosurffrags AS cosf
                                ON cosf.cokey = c2.cokey
                                   AND c2.cokey = c.cokey
                    GROUP BY
                        c2.cokey
                )                                                                  AS sum_fragcov_rv,
                (
                    SELECT
                        ROUND(SUM(sfragcov_h), 2)
                    FROM
                        component       AS c2
                        INNER JOIN
                            cosurffrags AS cosf
                                ON cosf.cokey = c2.cokey
                                   AND c2.cokey = c.cokey
                    GROUP BY
                        c2.cokey
                )                                                                  AS sum_fragcov_high,
                major_mu_pct_sum,
                LEFT(ROUND((1.0 * comppct_r / NULLIF(major_mu_pct_sum, 0)), 2), 4) AS adj_comp_pct,
                (
                    SELECT
                        CASE
                            WHEN MIN(resdept_r) IS NULL
                                THEN 200
                            ELSE
                                CAST(MIN(resdept_r) AS INT)
                        END
                    FROM
                        component
                        LEFT OUTER JOIN
                            corestrictions
                                ON component.cokey = corestrictions.cokey
                    WHERE
                        component.cokey = c.cokey
                        AND reskind IS NOT NULL
                )                                                                  AS restrictiodepth,
				     (
                    SELECT
                        CASE
                            WHEN MIN(resdept_r) IS NULL
                                THEN 200


                            ELSE
                                CAST(MIN(resdept_r) AS INT)
                        END
                    FROM
                        component
                        LEFT OUTER JOIN
                            corestrictions
                                ON component.cokey = corestrictions.cokey
                    WHERE
                        component.cokey = c.cokey
                        AND reskind IS NOT NULL AND reskind != 'Fragipan'
                )                                                                  AS PD_Fragi,
                (
                    SELECT TOP 1
                        taxmoistcl
                    FROM
                        component AS t
                        INNER JOIN
                            cotaxmoistcl
                                ON t.cokey = cotaxmoistcl.cokey
                                   AND t.cokey = c.cokey
                )                                                                  AS taxmoistcl,
                taxmoistscl,
                taxtempregime,
                taxtempcl,
                CASE
                    WHEN c.cokey =
                        (
                            SELECT TOP 1
                                c1.cokey
                            FROM
                                component   AS c1
                                INNER JOIN
                                    mapunit AS mu1
                                        ON c1.mukey = mu1.mukey
                                           AND c1.mukey = map.mukey
                            ORDER BY
                                c1.comppct_r DESC,
                                CASE
                                    WHEN LEFT(muname, 3) = LEFT(compname, 3)
                                        THEN 1
                                    ELSE
                                        2
                                END ASC,
                                c1.cokey
                        )
                        THEN 'Yes'
                    ELSE
                        'No'
                END                                                                AS dom_comp_flag,
                majcompflag,
                (
                    SELECT TOP 1
                        taxmoistcl
                    FROM
                        component AS t
                        INNER JOIN
                            cotaxmoistcl
                                ON t.cokey = cotaxmoistcl.cokey
                                   AND t.cokey = c.cokey
                )                                                                  AS soil_moisture_class,
                (
                    select top 1
                        flodfreqcl
                    FROM
                        comonth,
                        MetadataDomainMaster dm,
                        MetadataDomainDetail dd
                    WHERE
                        comonth.cokey = c.cokey
                        and flodfreqcl = ChoiceLabel
                        and DomainName = 'flooding_frequency_class'
                        and dm.DomainID = dd.DomainID
                    order by
                        choicesequence DESC
                )                                                                  as flood_freq,
                (
                    select top 1
                        floddurcl
                    FROM
                        comonth,
                        MetadataDomainMaster dm,
                        MetadataDomainDetail dd
                    WHERE
                        comonth.cokey = c.cokey
                        and floddurcl = ChoiceLabel
                        and DomainName = 'flooding_duration_class'
                        and dm.DomainID = dd.DomainID
                    order by
                        choicesequence DESC
                )                                                                  as flood_dur,
                (
                    SELECT TOP 1
                        pondfreqcl
                    FROM
                        comonth,
                        MetadataDomainMaster dm,
                        MetadataDomainDetail dd
                    WHERE
                        comonth.cokey = c.cokey
                        and pondfreqcl = ChoiceLabel
                        and DomainName = 'ponding_frequency_class'
                        and dm.DomainID = dd.DomainID
                    ORDER BY
                        choicesequence DESC
                )                                                                  as pond_freq,
                (
                    select top 1
                        ponddurcl
                    FROM
                        comonth,
                        MetadataDomainMaster dm,
                        MetadataDomainDetail dd
                    WHERE
                        comonth.cokey = c.cokey
                        and ponddurcl = ChoiceLabel
                        and DomainName = 'ponding_duration_class'
                        and dm.DomainID = dd.DomainID
                    order by
                        choicesequence DESC
                )                                                                  as pond_dur  /* ,
              (
                    select top 1
                        flodfreqcl
                    FROM
                        comonth
                    WHERE
                        comonth.cokey = c.cokey
                        and month = 'June'
                )                                                                  as flooding_June,
                (
                    select top 1
                        flodfreqcl
                    FROM
                        comonth
                    WHERE
                        comonth.cokey = c.cokey
                        and month = 'July'
                )                                                                  as flooding_July,
                (
                    select top 1
                        flodfreqcl
                    FROM
                        comonth
                    WHERE
                        comonth.cokey = c.cokey
                        and month = 'August'
                )                                                                  as flooding_August,

                --
                (
                    select top 1
                        pondfreqcl
                    FROM
                        comonth
                    WHERE
                        comonth.cokey = c.cokey
                        and month = 'June'
                )                                                                  as ponding_June,
                (
                    select top 1
                        pondfreqcl
                    FROM
                        comonth
                    WHERE
                        comonth.cokey = c.cokey
                        and month = 'July'
                )                                                                  as ponding_July,
                (
                    select top 1
                        pondfreqcl
                    FROM
                        comonth
                    WHERE
                        comonth.cokey = c.cokey
                        and month = 'August'
                )                                                                  as ponding_August */
            FROM
                #map          AS map
                INNER JOIN
                    component AS c
                        ON c.mukey = map.mukey
                           AND (CASE
                                    WHEN 1 = @major
                                        THEN 0
                                    WHEN majcompflag = 'Yes'
                                        THEN 0
                                    ELSE
                                        1
                                END = 0
                               )

------------------------------------------------------------------------------------
---Queries the Min water table by component
--creates the temp table for component min water table by month
CREATE TABLE #water
    (
        mukey     INT,
        compname  VARCHAR(60),
        month     VARCHAR(25),
        cokey     INT,
        min_water INT
    )

--Min Soil water table
TRUNCATE TABLE #water
INSERT INTO #water
    (
        mukey,
        compname,
        month,
        cokey,
        min_water
    )
            SELECT
                #map.mukey,
                compname,
                month,
                c3.cokey,
                MIN(soimoistdept_r) over (partition by
                                              c3.cokey
                                         ) as min_water
            FROM
                #map
                INNER JOIN
                    component  AS c3
                        ON c3.mukey = #map.mukey
                           AND majcompflag = 'Yes'
                INNER JOIN
                    comonth
                        ON c3.cokey = comonth.cokey
                INNER JOIN
                    cosoilmoist
                        ON cosoilmoist.comonthkey = comonth.comonthkey
                           AND soimoiststat = 'wet';

------------------------------------------------------------------------------------
--Average Water table for Apr-Sept and Oct-March
--link
CREATE TABLE #water2
    (
        mukey             INT,
        compname          VARCHAR(60),
        avg_h20_apr2sept  INT,
        avg_h20_oct2march INT,
        avg_h20_nov2feb   INT,
        avg_h20_march2oct INT,
        cokey             INT
    )

---TRUNCATE TABLE #water2
INSERT INTO #water2
    (
        mukey,
        compname,
        avg_h20_apr2sept,
        avg_h20_oct2march,
        avg_h20_nov2feb,
        avg_h20_march2oct,
        cokey
    )
            SELECT DISTINCT
                mukey,
                compname,
                (
                    SELECT
                        AVG(min_water)
                    FROM
                        #water AS w2
                    WHERE
                        w2.cokey = #water.cokey
                        AND CASE
                                WHEN month = 'April'
                                    THEN 1
                                WHEN month = 'May'
                                    THEN 1
                                WHEN month = 'June'
                                    THEN 1
                                WHEN month = 'July'
                                    THEN 1
                                WHEN month = 'August'
                                    THEN 1
                                WHEN month = 'September'
                                    THEN 1
                                ElSE
                                    2
                            END = 1
                )       AS avg_h20_apr2sept,
                (
                    SELECT
                        AVG(min_water)
                    FROM
                        #water AS w3
                    WHERE
                        w3.cokey = #water.cokey
                        AND CASE
                                WHEN month = 'October'
                                    THEN 1
                                WHEN month = 'November'
                                    THEN 1
                                WHEN month = 'December'
                                    THEN 1
                                WHEN month = 'January'
                                    THEN 1
                                WHEN month = 'February'
                                    THEN 1
                                WHEN month = 'March'
                                    THEN 1
                                ElSE
                                    2
                            END = 1
                )       AS avg_h20_oct2march,
                (
                    SELECT
                        AVG(min_water)
                    FROM
                        #water AS w3
                    WHERE
                        w3.cokey = #water.cokey
                        AND CASE
                                WHEN month = 'November'
                                    THEN 1
                                WHEN month = 'December'
                                    THEN 1
                                WHEN month = 'February'
                                    THEN 1
                                ElSE
                                    2
                            END = 1
                )       AS avg_h20_nov2feb,
                (
                    SELECT
                        AVG(min_water)
                    FROM
                        #water AS w3
                    WHERE
                        w3.cokey = #water.cokey
                        AND CASE
                                WHEN month = 'March'
                                    THEN 1
                                WHEN month = 'April'
                                    THEN 1
                                WHEN month = 'May'
                                    THEN 1
                                WHEN month = 'June'
                                    THEN 1
                                WHEN month = 'July'
                                    THEN 1
                                WHEN month = 'August'
                                    THEN 1
                                WHEN month = 'September'
                                    THEN 1
                                WHEN month = 'October'
                                    THEN 1
                                ElSE
                                    2
                            END = 1
                )       AS avg_h20_march2oct,
                cokey
            FROM
                #water


------------------------------------------------------------------------------------
--Queries the all horizons and aggregates to 1 value based on different conditions
-- Add suffix S and flag for spodic, aggregated to component
--link
CREATE TABLE #horizon
    (
        mukey                INT,
        compname             VARCHAR(60),
        cokey                INT,
        landform             VARCHAR(60),
        min_yr_water         INT,
        subgroup             VARCHAR(10),
        greatgroup           VARCHAR(10), --max_ec_profile REAL, max_sar_profile REAL, 
        maxec_0_2cm          REAL,
        maxec_2_13cm         REAL,
        maxec_13_50cm        REAL,
        maxsar_0_2cm         REAL,
        maxsar_2_13cm        REAL,
        maxsar_13_50cm       REAL,
        maxcaco3_0_2cm       SMALLINT,
        maxcaco3_2_13cm      SMALLINT,
        maxcaco3_13_50cm     SMALLINT,
        maxgypsum_0_2cm      SMALLINT,
        maxgypsum_2_13cm     SMALLINT,
        maxgypsum_13_50cm    SMALLINT,
        maxph1to1h2o_0_15cm  REAL,
        minph1to1h2o_0_15cm  REAL,
        maxph01mcacl2_0_15cm REAL,
        minph01mcacl2_0_15cm REAL,
        maxcec7_0_15cm       REAL,
        mincec7_0_15cm       REAL,
        maxecec_0_15cm       REAL,
        minecec_0_15cm       REAL,
		minksat0_20cm       REAL, -- New Added 12/13/2003
		maxksat0_20cm		REAL, -- New Added 12/13/2003
		minksat20_50cm		REAL, -- New Added 12/13/2003
		maxksat20_50cm		REAL,-- New Added 12/13/2003
		minksat50_100cm		REAL,-- New Added 12/13/2003
		maxksat50_100cm		REAL,-- New Added 12/13/2003
        hzdept_r             SMALLINT,
        hzdepb_r             SMALLINT,
        awc_r                REAL,
        chkey                INT,
        hzname               VARCHAR(12)
    )

--TRUNCATE TABLE #horizon
INSERT INTO #horizon
    (
        mukey,
        compname,
        cokey,
        landform,
        min_yr_water,
        subgroup,
        greatgroup, --max_ec_profile, max_sar_profile,
        maxec_0_2cm,
        maxec_2_13cm,
        maxec_13_50cm,
        maxsar_0_2cm,
        maxsar_2_13cm,
        maxsar_13_50cm,
        maxcaco3_0_2cm,
        maxcaco3_2_13cm,
        maxcaco3_13_50cm,
        maxgypsum_0_2cm,
        maxgypsum_2_13cm,
        maxgypsum_13_50cm,
        maxph1to1h2o_0_15cm,
        minph1to1h2o_0_15cm,
        maxph01mcacl2_0_15cm,
        minph01mcacl2_0_15cm,
        maxcec7_0_15cm,
        mincec7_0_15cm,
        maxecec_0_15cm,
        minecec_0_15cm,
		minksat0_20cm  ,    
		maxksat0_20cm	,	
		minksat20_50cm,		
		maxksat20_50cm,		
		minksat50_100cm	,	 
		maxksat50_100cm		,
        hzdept_r,
        hzdepb_r,
        awc_r,
        chkey,
        hzname
    )
            SELECT DISTINCT
                mukey,
                compname,
                #comp.cokey,
                landform,
                min_yr_water,
                subgroup,
                greatgroup,                          --MAX(ec_r) over(partition by #comp.cokey) as max_ec_profile, MAX(sar_r) over(partition by #comp.cokey) as max_sar_profile, 

                (
                    Select
                        MAX(ec_r)
                    FROM
                        component    AS c
                        INNER JOIN
                            chorizon AS ch
                                ON ch.cokey = c.cokey
                                   AND hzdept_r < 2
                                   and ch.cokey = #comp.cokey
                )           as maxec_0_2cm,
                (
                    Select
                        MAX(ec_r)
                    FROM
                        component    AS c
                        INNER JOIN
                            chorizon AS ch
                                ON ch.cokey = c.cokey
                                   AND hzdepb_r >= 2
                                   and hzdept_r < 13
                                   and ch.cokey = #comp.cokey
                )           as maxec_2_13cm,
                (
                    Select
                        MAX(ec_r)
                    FROM
                        component    AS c
                        INNER JOIN
                            chorizon AS ch
                                ON ch.cokey = c.cokey
                                   AND hzdepb_r >= 13
                                   and hzdept_r < 50
                                   and ch.cokey = #comp.cokey
                )           as maxec_13_50cm,
                (
                    Select
                        MAX(sar_r)
                    FROM
                        component    AS c
                        INNER JOIN
                            chorizon AS ch
                                ON ch.cokey = c.cokey
                                   AND hzdept_r < 2
                                   and ch.cokey = #comp.cokey
                )           as maxsar_0_2cm,
                (
                    Select
                        MAX(sar_r)
                    FROM
                        component    AS c
                        INNER JOIN
                            chorizon AS ch
                                ON ch.cokey = c.cokey
                                   AND hzdepb_r >= 2
                                   and hzdept_r < 13
                                   and ch.cokey = #comp.cokey
                )           as maxsar_2_13cm,
                (
                    Select
                        MAX(sar_r)
                    FROM
                        component    AS c
                        INNER JOIN
                            chorizon AS ch
                                ON ch.cokey = c.cokey
                                   AND hzdepb_r >= 13
                                   and hzdept_r < 50
                                   and ch.cokey = #comp.cokey
                )           as maxsar_13_50cm,
                (
                    Select
                        MAX(caco3_r)
                    FROM
                        component    AS c
                        INNER JOIN
                            chorizon AS ch
                                ON ch.cokey = c.cokey
                                   AND hzdept_r < 2
                                   and ch.cokey = #comp.cokey
                )           as maxcaco3_0_2cm,
                (
                    Select
                        MAX(caco3_r)
                    FROM
                        component    AS c
                        INNER JOIN
                            chorizon AS ch
                                ON ch.cokey = c.cokey
                                   AND hzdepb_r >= 2
                                   and hzdept_r < 13
                                   and ch.cokey = #comp.cokey
                )           as maxcaco3_2_13cm,
                (
                    Select
                        MAX(caco3_r)
                    FROM
                        component    AS c
                        INNER JOIN
                            chorizon AS ch
                                ON ch.cokey = c.cokey
                                   AND hzdepb_r >= 13
                                   and hzdept_r < 50
                                   and ch.cokey = #comp.cokey
                )           as maxcaco3_13_50cm,
                (
                    Select
                        MAX(gypsum_r)
                    FROM
                        component    AS c
                        INNER JOIN
                            chorizon AS ch
                                ON ch.cokey = c.cokey
                                   AND hzdept_r < 2
                                   and ch.cokey = #comp.cokey
                )           as maxgypsum_0_2cm,
                (
                    Select
                        MAX(gypsum_r)
                    FROM
                        component    AS c
                        INNER JOIN
                            chorizon AS ch
                                ON ch.cokey = c.cokey
                                   AND hzdepb_r >= 2
                                   and hzdept_r < 13
                                   and ch.cokey = #comp.cokey
                )           as maxgypsum_2_13cm,
                (
                    Select
                        MAX(gypsum_r)
                    FROM
                        component    AS c
                        INNER JOIN
                            chorizon AS ch
                                ON ch.cokey = c.cokey
                                   AND hzdepb_r >= 13
                                   and hzdept_r < 50
                                   and ch.cokey = #comp.cokey
                )           as maxgypsum_13_50cm,
                (
                    Select
                        MAX(ph1to1h2o_r)
                    FROM
                        component    AS c
                        INNER JOIN
                            chorizon AS ch
                                ON ch.cokey = c.cokey
                                   AND hzdept_r < 15
                                   and ch.cokey = #comp.cokey
                )           as maxph1to1h2o_0_15cm,  -- New 9/8/2021
                (
                    Select
                        MIN(ph1to1h2o_r)
                    FROM
                        component    AS c
                        INNER JOIN
                            chorizon AS ch
                                ON ch.cokey = c.cokey
                                   AND hzdept_r < 15
                                   and ch.cokey = #comp.cokey
                )           as minph1to1h2o_0_15cm,  -- New 9/8/2021

                (
                    Select
                        MAX(ph01mcacl2_r)
                    FROM
                        component    AS c
                        INNER JOIN
                            chorizon AS ch
                                ON ch.cokey = c.cokey
                                   AND hzdept_r < 15
                                   and ch.cokey = #comp.cokey
                )           as maxph01mcacl2_0_15cm, -- New 9/8/2021
                (
                    Select
                        MIN(ph01mcacl2_r)
                    FROM
                        component    AS c
                        INNER JOIN
                            chorizon AS ch
                                ON ch.cokey = c.cokey
                                   AND hzdept_r < 15
                                   and ch.cokey = #comp.cokey
                )           as minph01mcacl2_0_15cm, -- New 9/8/2021

                (
                    Select
                        MAX(cec7_r)
                    FROM
                        component    AS c
                        INNER JOIN
                            chorizon AS ch
                                ON ch.cokey = c.cokey
                                   AND hzdept_r < 15
                                   and ch.cokey = #comp.cokey
                )           as maxcec7_0_15cm,       -- New 9/8/2021
                (
                    Select
                        MIN(cec7_r)
                    FROM
                        component    AS c
                        INNER JOIN
                            chorizon AS ch
                                ON ch.cokey = c.cokey
                                   AND hzdept_r < 15
                                   and ch.cokey = #comp.cokey
                )           as mincec7_0_15cm,       -- New 9/8/2021

                (
                    Select
                        MAX(ecec_r)
                    FROM
                        component    AS c
                        INNER JOIN
                            chorizon AS ch
                                ON ch.cokey = c.cokey
                                   AND hzdept_r < 15
                                   and ch.cokey = #comp.cokey
                )           as maxecec_0_15cm,       -- New 9/8/2021
                (
                    Select
                        MIN(ecec_r)
                    FROM
                        component    AS c
                        INNER JOIN
                            chorizon AS ch
                                ON ch.cokey = c.cokey
                                   AND hzdept_r < 15
                                   and ch.cokey = #comp.cokey
                )           as minecec_0_15cm,       -- New 9/8/2021

				     (
                    Select
                        MIN(ch.ksat_r)
                    FROM
                        component    AS c
                        INNER JOIN
                            chorizon AS ch
                                ON ch.cokey = c.cokey
                                   AND hzdepb_r >= 0
                                   and hzdept_r < 20
                                   and ch.cokey = #comp.cokey
                )           as minksat0_20cm ,

					     (
                    Select
                        MAX(ch.ksat_r)
                    FROM
                        component    AS c
                        INNER JOIN
                            chorizon AS ch
                                ON ch.cokey = c.cokey
                                   AND hzdepb_r >= 0
                                   and hzdept_r < 20
                                   and ch.cokey = #comp.cokey
                )     as maxksat0_20cm,

				     (
                    Select
                        MIN(ch.ksat_r)
                    FROM
                        component    AS c
                        INNER JOIN
                            chorizon AS ch
                                ON ch.cokey = c.cokey
                                   AND hzdepb_r >= 20
                                   and hzdept_r < 50
                                   and ch.cokey = #comp.cokey
                )           as minksat20_50cm ,

					     (
                    Select
                        MAX(ch.ksat_r)
                    FROM
                        component    AS c
                        INNER JOIN
                            chorizon AS ch
                                ON ch.cokey = c.cokey
                                   AND hzdepb_r >= 20
                                   and hzdept_r < 50
                                   and ch.cokey = #comp.cokey
                )     as maxksat20_50cm,

								     (
                    Select
                        MIN(ch.ksat_r)
                    FROM
                        component    AS c
                        INNER JOIN
                            chorizon AS ch
                                ON ch.cokey = c.cokey
                                   AND hzdepb_r >= 50
                                   and hzdept_r < 100
                                   and ch.cokey = #comp.cokey
                )           as minksat50_100cm ,

					     (
                    Select
                        MAX(ch.ksat_r)
                    FROM
                        component    AS c
                        INNER JOIN
                            chorizon AS ch
                                ON ch.cokey = c.cokey
                                   AND hzdepb_r >= 50
                                   and hzdept_r < 100
                                   and ch.cokey = #comp.cokey
                )     as maxksat50_100cm,
                hzdept_r,
                hzdepb_r,
                awc_r,
                chkey,
                hzname
            FROM
                #comp
                INNER JOIN
                    chorizon
                        ON chorizon.cokey = #comp.cokey

--Start AWS
CREATE TABLE #acpf
    (
        mukey     INT,
        cokey     INT,
        hzname    VARCHAR(12),
        hzdept_r  SMALLINT,
        hzdepb_r  SMALLINT,
        thickness SMALLINT,
        awc_r     REAL,
        chkey     INT
    )
INSERT INTO #acpf
    (
        mukey,
        cokey,
        hzname,
        hzdept_r,
        hzdepb_r,
        thickness,
        awc_r,
        chkey
    )
            SELECT
                mukey,
                cokey,
                hzname,
                --restrictiodepth, 
                hzdept_r,
                hzdepb_r,
                CASE
                    WHEN (hzdepb_r - hzdept_r) IS NULL
                        THEN 0
                    ELSE
                        CAST((hzdepb_r - hzdept_r) AS INT)
                END     AS thickness,
                CASE
                    when awc_r IS NULL
                        THEN 0
                    ELSE
                        awc_r
                END     AS awc_r,
                chkey
            FROM
                #horizon
            WHERE
                CASE
                    WHEN hzdept_r IS NULL
                        THEN 2
                    WHEN awc_r IS NULL
                        THEN 2
                    WHEN awc_r = 0
                        THEN 2
                    ELSE
                        1
                END = 1

--- depth ranges for AWS ----
CREATE TABLE #aws
    (
        InRangeBot        SMALLINT,
        InRangeTop        SMALLINT,
        InRangeBot_0_20   SMALLINT,
        InRangeTop_0_20   SMALLINT,
        InRangeBot_20_50  SMALLINT,
        InRangeTop_20_50  SMALLINT,
        InRangeBot_50_100 SMALLINT,
        InRangeTop_50_100 SMALLINT,
        awc_r             REAL,
        cokey             INT,
        mukey             INT
    )
INSERT INTO #aws
    (
        InRangeBot,
        InRangeTop,
        InRangeBot_0_20,
        InRangeTop_0_20,
        InRangeBot_20_50,
        InRangeTop_20_50,
        InRangeBot_50_100,
        InRangeTop_50_100,
        awc_r,
        cokey,
        mukey
    )
            SELECT
                CASE
                    WHEN hzdepb_r <= 150
                        THEN hzdepb_r
                    WHEN hzdepb_r > 150
                         and hzdept_r < 150
                        THEN 150
                    ELSE
                        0
                END AS InRangeBot,
                CASE
                    WHEN hzdept_r < 150
                        then hzdept_r
                    ELSE
                        0
                END AS InRangeTop,
                CASE
                    WHEN hzdepb_r <= 20
                        THEN hzdepb_r
                    WHEN hzdepb_r > 20
                         and hzdept_r < 20
                        THEN 20
                    ELSE
                        0
                END AS InRangeBot_0_20,
                CASE
                    WHEN hzdept_r < 20
                        then hzdept_r
                    ELSE
                        0
                END AS InRangeTop_0_20,
                CASE
                    WHEN hzdepb_r <= 50
                        THEN hzdepb_r
                    WHEN hzdepb_r > 50
                         and hzdept_r < 50
                        THEN 50
                    ELSE
                        20
                END AS InRangeBot_20_50,
                CASE
                    WHEN hzdept_r < 50
                        then hzdept_r
                    ELSE
                        20
                END AS InRangeTop_20_50,
                CASE
                    WHEN hzdepb_r <= 100
                        THEN hzdepb_r
                    WHEN hzdepb_r > 100
                         and hzdept_r < 100
                        THEN 100
                    ELSE
                        50
                END AS InRangeBot_50_100,
                CASE
                    WHEN hzdept_r < 100
                        then hzdept_r
                    ELSE
                        50
                END AS InRangeTop_50_100,
                awc_r,
                cokey,
                mukey
            FROM
                #acpf
            ORDER BY
                cokey

CREATE TABLE #aws150
    (
        mukey        INT,
        cokey        INT,
        aws150cm     REAL,
        aws_0_20cm   REAL,
        aws_20_50cm  REAL,
        aws_50_100cm REAL
    )
INSERT INTO #aws150
    (
        mukey,
        cokey,
        aws150cm,
        aws_0_20cm,
        aws_20_50cm,
        aws_50_100cm
    )
            SELECT
                mukey,
                cokey,
                ROUND(SUM((InRangeBot - InRangeTop) * awc_r), 3)               AS aws150cm,
                ROUND(SUM((InRangeBot_0_20 - InRangeTop_0_20) * awc_r), 3)     AS aws_0_20cm,
                ROUND(SUM((InRangeBot_20_50 - InRangeTop_20_50) * awc_r), 3)   AS aws_20_50cm,
                ROUND(SUM((InRangeBot_50_100 - InRangeTop_50_100) * awc_r), 3) AS aws_50_100cm
            FROM
                #aws
            GROUP BY
                mukey,
                cokey


------------------------------------------------------------------------------------
--Queries surface mineral horizon, eliminates duff layer but keeps wet organics -- Surface Mineralogy (separating Organic from Mineral)
--Link
CREATE TABLE #surface
    (
        cokey           INT,
        chkey           INT,
        compname        VARCHAR(60),
        hzname          VARCHAR(12),
        hzdept_r        SMALLINT,
        hzdepb_r        SMALLINT,
        texture         VARCHAR(30),
        mineral_des     VARCHAR(10),
        om_r            REAL,
        surface_mineral VARCHAR(3),
        awc_r           REAL,
        kwfact          VARCHAR(254),
        kffact          VARCHAR(254)
    )

INSERT INTO #surface
    (
        cokey,
        chkey,
        compname,
        hzname,
        hzdept_r,
        hzdepb_r,
        texture,
        mineral_des,
        om_r,
        surface_mineral,
        awc_r,
        kwfact,
        kffact
    )
            SELECT
                #comp.cokey,
                chorizon.chkey,
                compname,
                hzname,
                hzdept_r,
                hzdepb_r,
                texture,
                CASE
                    WHEN desgnmaster LIKE '%h%'
                        THEN 'H horizon'
                    WHEN desgnmaster LIKE '%O%'
                        THEN 'Organic'
                    WHEN desgnmaster NOT LIKE '%O%'
                        THEN 'Mineral'
                    ELSE
                        'NA'
                END                                    AS mineral_des,
                CAST(ISNULL(om_r, 0) AS decimal(5, 2)) AS om_r,
                CASE
                    WHEN
                        (
                            (claytotal_r) IS NOT NULL
                            AND (om_r) IS NOT NULL
                            AND om_r >= 18 * 1.724
                            and claytotal_r >= 60
                        )
                        THEN 'Yes'
                    WHEN
                        (
                            (claytotal_r) IS NOT NULL
                            AND (om_r) IS NOT NULL
                            AND (om_r >= (12 + (claytotal_r * 0.1)) * 1.724)
                            AND claytotal_r < 60
                        )
                        THEN 'Yes'
                    WHEN
                        (
                            om_r >= 20 * 1.724
                            AND (claytotal_r) IS NOT NULL
                            AND (om_r) IS NOT NULL
                        )
                        THEN 'Yes'
                    ELSE
                        'No'
                END                                    AS surface_mineral,
                awc_r,
                kwfact,
                kffact
            FROM
                #comp
                INNER JOIN
                    (chorizon
                INNER JOIN
                    chtexturegrp
                        ON chorizon.chkey = chtexturegrp.chkey)
                        ON #comp.cokey = chorizon.cokey
                           AND (
                                   ((chorizon.hzdept_r) =
                                       (
                                           SELECT
                                               Min(chorizon.hzdept_r) AS MinOfhzdept_r
                                           FROM
                                               chorizon
                                               INNER JOIN
                                                   chtexturegrp
                                                       ON chorizon.chkey = chtexturegrp.chkey
                                                          AND chtexturegrp.texture Not In (
                                                                                              'SPM', 'HPM', 'MPM'
                                                                                          )
                                                          AND chtexturegrp.rvindicator = 'Yes'
                                                          AND #comp.cokey = chorizon.cokey
                                       )
                                   )
                                   AND ((chtexturegrp.rvindicator) = 'Yes')
                               )
            ORDER BY
                comppct_r DESC,
                cokey,
                hzdept_r,
                hzdepb_r



------------------------------------------------------------------------------------
---Soil Surface Texture Class by Thickness (not depth)
---Eliminates Duff layer at the end and aggregates texture grouping
CREATE TABLE #surface_tex
    (
        cokey         INT,
        chkey         INT,
        compname      VARCHAR(60),
        hzname        VARCHAR(12),
        hzdept_r      SMALLINT,
        hzdepb_r      SMALLINT,
        texture       VARCHAR(30),
        tex_modifier  VARCHAR(254),
        tex           VARCHAR(254),
        tex_in_lieu   VARCHAR(254),
        row_num       INT,
        text_grouping VARCHAR(254)
    )

INSERT INTO #surface_tex
    (
        cokey,
        chkey,
        compname,
        hzname,
        hzdept_r,
        hzdepb_r,
        texture,
        tex_modifier,
        tex,
        tex_in_lieu,
        row_num,
        text_grouping
    )
            -- OUTPUT  INSERTED.cokey, INSERTED.chkey, INSERTED.compname, INSERTED.hzname, INSERTED.hzdept_r, INSERTED.hzdepb_r, INSERTED.texture, INSERTED.tex_modifier, INSERTED.tex, INSERTED.tex_in_lieu, INSERTED.row_num, INSERTED.text_grouping ---For testing to display

            SELECT
                #comp.cokey,
                chorizon.chkey,
                compname,
                hzname,
                hzdept_r,
                hzdepb_r,
                texture,
                (
                    SELECT TOP 1
                        [ChoiceName]
                    FROM
                        chtexture AS cht,
                        MetadataDomainMaster dm,
                        MetadataDomainDetail dd,
                        chtexturemod AS chtm
                    WHERE
                        chtm.chtkey = cht.chtkey
                        AND chtexturegrp.chtgkey = cht.chtgkey
                        and texmod = ChoiceLabel
                        and DomainName = 'texture_modifier'
                        AND dm.DomainID = dd.DomainID
                    ORDER BY
                        choicesequence DESC
                )                   AS tex_modifier,
                (
                    SELECT TOP 1
                        [ChoiceName]
                    FROM
                        chtexture AS cht,
                        MetadataDomainMaster dm,
                        MetadataDomainDetail dd
                    WHERE
                        chtexturegrp.chtgkey = cht.chtgkey
                        and texcl = ChoiceLabel
                        and DomainName = 'texture_class'
                        AND dm.DomainID = dd.DomainID
                    ORDER BY
                        choicesequence DESC
                )                   AS tex,
                (
                    SELECT TOP 1
                        [ChoiceName]
                    FROM
                        chtexture AS cht,
                        MetadataDomainMaster dm,
                        MetadataDomainDetail dd
                    WHERE
                        chtexturegrp.chtgkey = cht.chtgkey
                        and lieutex = ChoiceLabel
                        and DomainName = 'terms_used_in_lieu_of_texture'
                        AND dm.DomainID = dd.DomainID
                    ORDER BY
                        choicesequence DESC
                )                   AS tex_in_lieu,
                row_number() over (PARTITION BY
                                       #comp.cokey
                                   order by
                                       hzdept_r ASC
                                  ) as row_num,
                CASE
                    WHEN stratextsflag = 'Yes'
                        THEN 'stratified'
                    WHEN desgnmaster = 'O'
                        THEN 'organic'
                END                 AS text_grouping
            FROM
                #comp
                INNER JOIN
                    (chorizon
                INNER JOIN
                    chtexturegrp
                        ON chorizon.chkey = chtexturegrp.chkey
                           AND chtexturegrp.rvindicator = 'Yes')
                        ON #comp.cokey = chorizon.cokey

------------------------------------------------------------------------------------
-- surface tex 2 table
CREATE TABLE #surface_tex2
    (
        cokey            INT,
        chkey            INT,
        compname         VARCHAR(60),
        hzname           VARCHAR(12),
        hzdept_r         SMALLINT,
        hzdepb_r         SMALLINT,
        texture          VARCHAR(30),
        tex_modifier     VARCHAR(254),
        tex              VARCHAR(254),
        tex_in_lieu      VARCHAR(254),
        row_num          INT,
        text_grouping    VARCHAR(254),
        texture_grouping VARCHAR(254)
    )

INSERT INTO #surface_tex2
    (
        cokey,
        chkey,
        compname,
        hzname,
        hzdept_r,
        hzdepb_r,
        texture,
        tex_modifier,
        tex,
        tex_in_lieu,
        row_num,
        text_grouping,
        texture_grouping
    )
            SELECT
                cokey,
                chkey,
                compname,
                hzname,
                hzdept_r,
                hzdepb_r,
                texture,
                tex_modifier,
                tex,
                tex_in_lieu,
                row_num,
                text_grouping,
                CASE
                    WHEN text_grouping = 'organic'
                        THEN 'organic'
                    WHEN text_grouping = 'stratified'
                        THEN 'stratified'
                    WHEN tex_modifier IN (
                                             'ASHY', 'HYDR', 'MEDL'
                                         )
                        THEN 'volcanic modifier'
                    WHEN tex_modifier IN (
                                             'GS', 'HB', 'MS', 'WD'
                                         )
                        THEN 'organic soil material modifier'
                    WHEN tex_modifier IN (
                                             'HO', 'MK', 'PT'
                                         )
                        THEN 'highly organic mineral material modifier'
                    WHEN tex_modifier IN (
                                             'COP', 'DIA', 'MR'
                                         )
                        THEN 'limnic material modifier'
                    WHEN tex_modifier IN (
                                             'ART', 'ARTV', 'ARTVX'
                                         )
                        THEN 'anthropogenic material modifier'
                    WHEN tex_modifier = 'CEM'
                        THEN 'cemented material modifier'
                    WHEN tex_modifier = 'GYP'
                        THEN 'gypsiferous material modifier'
                    WHEN tex_modifier = 'PF'
                        THEN 'permanently frozen material modifier'
                    WHEN tex = 'COS'
                        THEN 'coarse textured'
                    WHEN tex = 'S'
                        THEN 'coarse textured'
                    WHEN tex = 'FS'
                        THEN 'coarse textured'
                    WHEN tex = 'VFS'
                        THEN 'coarse textured'
                    WHEN tex = 'LCOS'
                        THEN 'coarse textured'
                    WHEN tex = 'LS'
                        THEN 'coarse textured'
                    WHEN tex = 'LFS'
                        THEN 'coarse textured'
                    WHEN tex = 'LVFS'
                        THEN 'coarse textured'
                    WHEN tex = 'COSL'
                        THEN 'moderately coarse textured'
                    WHEN tex = 'SL'
                        THEN 'moderately coarse textured'
                    WHEN tex = 'FSL'
                        THEN 'moderately coarse textured'
                    WHEN tex = 'VFSL'
                        THEN 'medium textured'
                    WHEN tex = 'L'
                        THEN 'medium textured'
                    WHEN tex = 'SIL'
                        THEN 'medium textured'
                    WHEN tex = 'SI'
                        THEN 'medium textured'
                    WHEN tex = 'CL'
                        THEN 'moderately fine textured'
                    WHEN tex = 'SCL'
                        THEN 'moderately fine textured'
                    WHEN tex = 'SICL'
                        THEN 'moderately fine textured'
                    WHEN tex = 'SC'
                        THEN 'fine textured'
                    WHEN tex = 'SIC'
                        THEN 'fine textured'
                    WHEN tex = 'C'
                        THEN 'fine textured'
                END AS texture_grouping
            FROM
                #surface_tex


------------------------------------------------------------------------------------
---Surface Text 
CREATE TABLE #surface_tex3
    (
        cokey                 INT,
        chkey                 INT,
        compname              VARCHAR(60),
        tex_modifier          VARCHAR(254),
        tex_in_lieu           VARCHAR(254),
        texture_grouping      VARCHAR(254),
        hzname                VARCHAR(12),
        hzdept_r              SMALLINT,
        hzdepb_r              SMALLINT,
        min_top_depth         SMALLINT,
        prev_texture_grouping VARCHAR(254),
        prev_bottom_depth     SMALLINT,
        row_num               INT
    )
INSERT INTO #surface_tex3
    (
        cokey,
        chkey,
        compname,
        tex_modifier,
        tex_in_lieu,
        texture_grouping,
        hzname,
        hzdept_r,
        hzdepb_r,
        min_top_depth,
        prev_texture_grouping,
        prev_bottom_depth,
        row_num
    )
            SELECT
                cokey,
                chkey,
                compname,
                tex_modifier,
                tex_in_lieu,
                texture_grouping,
                hzname,
                hzdept_r,
                hzdepb_r, --tex,  
                MIN(hzdept_r) over (partition by
                                        cokey,
                                        texture_grouping
                                    order by
                                        hzdept_r ASC
                                    ROWS UNBOUNDED PRECEDING
                                   ) as min_top_depth,
                          --last_value(hzdepb_r) over(partition by cokey, texture_grouping_value hz_diag_kind
                          -- order by hzdept_r ASC
                          -- rows BETWEEN unbounded preceding and unbounded following
                          --) as max_bottom_depth,
                ISNULL(   LAG(texture_grouping) OVER (PARTITION BY
                                                          cokey
                                                      ORDER BY
                                                          hzdept_r ASC
                                                     ), texture_grouping
                      )              as prev_texture_grouping,
                ISNULL(   LAG(hzdepb_r) OVER (PARTITION BY
                                                  cokey
                                              ORDER BY
                                                  hzdept_r ASC
                                             ), hzdept_r
                      )              as prev_bottom_depth,
                ROW_NUMBER() OVER (PARTITION BY
                                       cokey,
                                       texture_grouping
                                   ORDER BY
                                       hzdept_r ASC
                                  )  AS row_num
            FROM
                #surface_tex2 AS s1
            WHERE
                CASE
                    WHEN tex_in_lieu = 'spm'
                        THEN 1
                    WHEN tex_in_lieu = 'hpm'
                        THEN 1
                    WHEN tex_in_lieu = 'mpm'
                        THEN 1
                    WHEN tex_in_lieu IS NULL
                        THEN 2
                    ELSE
                        2
                END = 2
            ORDER BY
                cokey,
                hzdept_r,
                hzdepb_r,
                chkey;


---with — recursive common table expression - CTE (common table expression)
WITH #surface_tex4
AS (
       SELECT
           cokey,
           chkey,
           compname,
           tex_modifier,
           tex_in_lieu,
           texture_grouping,
           hzname,
           hzdept_r,
           hzdepb_r,
           min_top_depth,
           prev_texture_grouping,
           prev_bottom_depth,
           row_num
       From
           #surface_tex3
       WHERE
           prev_bottom_depth = hzdept_r
           AND prev_texture_grouping = texture_grouping
   )

--SELECT *
-- FROM #surface_tex3
---Final Surface Texture grouping
--link
SELECT DISTINCT
    cokey,
    compname,
    SUBSTRING(
        (
            SELECT (', ' + tex_modifier)
            FROM
                   #surface_tex4 AS st2
            WHERE
                   st1.cokey = st2.cokey
            GROUP BY
                   cokey,
                   tex_modifier
            ORDER BY
                   st1.cokey,
                   st2.cokey
            FOR XML PATH('')
        ), 3, 1000
             )           as tex_modifier,
    tex_in_lieu,
    texture_grouping,
    min_top_depth,
    MAX(hzdepb_r) over (partition by
                            cokey,
                            texture_grouping
                       ) as max_bottom_depth --, ROW_NUMBER() OVER(PARTITION BY cokey ORDER BY min_top_depth ASC ) AS row_num 
INTO
    #surface_final
FROM
    #surface_tex4 AS st1
GROUP BY
    cokey,
    compname,
    tex_modifier,
    tex_in_lieu,
    texture_grouping,
    min_top_depth,
    hzdepb_r
ORDER BY
    cokey,
    min_top_depth ASC

SELECT
    cokey,
    compname,
    tex_modifier,
    tex_in_lieu,
    texture_grouping,
    min_top_depth,
    max_bottom_depth,
    ROW_NUMBER() OVER (PARTITION BY
                           cokey
                       ORDER BY
                           min_top_depth ASC
                      ) AS row_num
INTO
    #surface_final2
FROM
    #surface_final
ORDER BY
    cokey,
    min_top_depth ASC

SELECT
    cokey,
    compname,
    tex_modifier,
    tex_in_lieu,
    texture_grouping,
    min_top_depth,
    max_bottom_depth,
    row_num
INTO
    #surface_final3
FROM
    #surface_final2
WHERE
    row_num = 1


---Diagnostic Horizon Kind
--Link
CREATE TABLE #diag
    (
        cokey                INT,
        compname             VARCHAR(60),
        [Argillic horizon]   SMALLINT,
        [Albic horizon]      SMALLINT,
        [Cambic horizon]     SMALLINT,
        [Densic contact]     SMALLINT,
        [Duripan]            SMALLINT,
        [Fragipan]           SMALLINT,
        [Lithic contact]     SMALLINT,
        [Oxic horizon]       SMALLINT,
        [Paralithic contact] SMALLINT,
        [Petro]              SMALLINT,
        [Spodic horizon]     SMALLINT,
        [Salic horizon]      SMALLINT
    )
INSERT INTO #diag
    (
        cokey,
        compname,
        [Argillic horizon],
        [Albic horizon],
        [Cambic horizon],
        [Densic contact],
        [Duripan],
        [Fragipan],
        [Lithic contact],
        [Oxic horizon],
        [Paralithic contact],
        [Petro],
        [Spodic horizon],
        [Salic horizon]
    )
            SELECT
                *
            FROM
                (
                    SELECT
                        #comp.cokey,
                        compname,
                        featdept_r,
                        featkind
                    FROM
                        #comp
                        INNER JOIN
                            codiagfeatures AS dia
                                ON dia.cokey = #comp.cokey
                ) #d
            PIVOT
                (
                    MIN(featdept_r)
                    FOR featkind IN (
                        [Argillic horizon], [Albic horizon], --Albic materials --Interfingering of albic materials
                        [Cambic horizon], [Densic contact],  --Densic materials
                        [Duripan], [Fragipan], [Lithic contact], [Oxic horizon],
                        [Paralithic contact],                --Paralithic materials
                        [Petro],                             --[Petrocalcic horizon --Petroferric contact --Petrogypsic horizon
                        [Spodic horizon], [Salic horizon]
                                    )
                ) AS #diag_pivot_table;
-------------------------
  CREATE TABLE #flood_month
    (
        cokey                INT,
        compname             VARCHAR(60),
        flooding_January	 VARCHAR(60),
		flooding_February	 VARCHAR(60),
		flooding_March       VARCHAR(60),
		flooding_April       VARCHAR(60),
		flooding_May         VARCHAR(60),
		flooding_June	     VARCHAR(60),
		flooding_July		 VARCHAR(60),
		flooding_August		 VARCHAR(60),
		flooding_September   VARCHAR(60),
		flooding_October     VARCHAR(60),
		flooding_November    VARCHAR(60),
		flooding_December    VARCHAR(60)
    )
INSERT INTO #flood_month
    (
        cokey,
        compname,
        flooding_January,
		flooding_February,
		flooding_March,
		flooding_April,
		flooding_May,
		flooding_June,
		flooding_July,
		flooding_August	,
		flooding_September,
		flooding_October,
		flooding_November,
		flooding_December
    )         
		   
		   
  
		   
		   SELECT
                cokey, compname,      
                        January AS flooding_January,
						February AS flooding_February,
						March AS flooding_March,
						April AS flooding_April,
						May AS flooding_May,
						June AS flooding_June ,
						July AS flooding_July ,
						August AS flooding_August,
						September AS flooding_September,
						October AS flooding_October,
						November AS flooding_November ,
						December AS flooding_December
            FROM
                (
                    SELECT
                        #comp.cokey,
                        compname,
                        flodfreqcl,
                        month
                    FROM
                        #comp
                        INNER JOIN
                            comonth AS m
                                ON m.cokey = #comp.cokey
                ) #fm
            PIVOT
                (
                    MIN(flodfreqcl)
                    FOR month IN (
                        January,
						February,
						March,
						April,
						May,
						June,
						July,
						August,
						September,
						October,
						November,
						December)
                                    
                ) AS #ffmonth_pivot_table;

---------------------------------------

 CREATE TABLE #pond_month
    (
        cokey                		INT,
        compname             		VARCHAR(60),
        ponding_January	 		VARCHAR(60),
		ponding_February	VARCHAR(60),
		ponding_March       	VARCHAR(60),
		ponding_April       	VARCHAR(60),
		ponding_May         	VARCHAR(60),
		ponding_June	     	VARCHAR(60),
		ponding_July		VARCHAR(60),
		ponding_August		VARCHAR(60),
		ponding_September   	VARCHAR(60),
		ponding_October     	VARCHAR(60),
		ponding_November    	VARCHAR(60),
		ponding_December    	VARCHAR(60)
    )
INSERT INTO #pond_month
    (
        cokey,
        compname,
        ponding_January,
		ponding_February,
		ponding_March,
		ponding_April,
		ponding_May,
		ponding_June,
		ponding_July,
		ponding_August	,
		ponding_September,
		ponding_October,
		ponding_November,
		ponding_December
    )         
		   
		   
  
		   
		   SELECT
                cokey, compname,      
                        January AS ponding_January,
						February AS ponding_February,
						March AS ponding_March,
						April AS ponding_April,
						May AS ponding_May,
						June AS ponding_June ,
						July AS ponding_July ,
						August AS ponding_August,
						September AS ponding_September,
						October AS ponding_October,
						November AS ponding_November ,
						December AS ponding_December
            FROM
                (
                    SELECT
                        #comp.cokey,
                        compname,
                        flodfreqcl,
                        month
                    FROM
                        #comp
                        INNER JOIN
                            comonth AS m
                                ON m.cokey = #comp.cokey
                ) #fm
            PIVOT
                (
                    MIN(flodfreqcl)
                    FOR month IN (
                        January,
						February,
						March,
						April,
						May,
						June,
						July,
						August,
						September,
						October,
						November,
						December)
                                    
                ) AS #pfmonth_pivot_table;
CREATE TABLE #diag3
    (
        cokey    INT,
        compname VARCHAR(60),
        Diag1    VARCHAR(254),
        Diag2    VARCHAR(254),
        Diag3    VARCHAR(254)
    )
INSERT INTO #diag3
    (
        cokey,
        compname,
        Diag1,
        Diag2,
        Diag3
    )

            --Grabs the top 3 diagnostics where the top depth is less than or equal to 50
            Select
                *
            From
                (
                    Select
                        #comp.cokey,
                        compname,
                        featkind,
                        Col = concat(   'Diag', Row_Number() over (Partition By
                                                                       #comp.cokey
                                                                   Order By
                                                                       [featdept_r] ASC
                                                                  )
                                    )
                    FROM
                        #comp
                        INNER JOIN
                            codiagfeatures AS dia
                                ON dia.cokey = #comp.cokey
                                   AND [featdept_r] <= 50
                ) diag
            Pivot
                (
                    MIN(featkind)
                    for Col in (
                        Diag1, Diag2, Diag3
                               )
                ) p


---Restrictions
--Link
CREATE TABLE #rest
    (
        cokey                INT,
        compname             VARCHAR(60),
        [Densic bedrock]     SMALLINT,
        [Lithic bedrock]     SMALLINT,
        [Paralithic bedrock] SMALLINT,
        [Cemented horizon]   SMALLINT,
        [Duripan]            SMALLINT,
        [Fragipan]           SMALLINT,
        [Manufactured layer] SMALLINT,
        [Petrocalcic]        SMALLINT,
        [Petroferric]        SMALLINT,
        [Petrogypsic]        SMALLINT
    )
INSERT INTO #rest
    (
        cokey,
        compname,
        [Densic bedrock],
        [Lithic bedrock],
        [Paralithic bedrock],
        [Cemented horizon],
        [Duripan],
        [Fragipan],
        [Manufactured layer],
        [Petrocalcic],
        [Petroferric],
        [Petrogypsic]
    )
            SELECT
                *
            FROM
                (
                    SELECT
                        #comp.cokey,
                        compname,
                        resdept_r,
                        reskind
                    FROM
                        #comp
                        INNER JOIN
                            corestrictions AS res
                                ON res.cokey = #comp.cokey
                ) #r
            PIVOT
                (
                    MIN(resdept_r)
                    FOR reskind IN (
                        [Densic bedrock], [Lithic bedrock], [Paralithic bedrock], [Cemented horizon], [Duripan],
                        [Fragipan], [Manufactured layer], [Petrocalcic], [Petroferric], [Petrogypsic]
                                   )
                ) AS #rest_pivot_table;


--Fragments 1
CREATE TABLE #fragment
    (
        cokey          INT,
        chkey          INT,
        compname       VARCHAR(60),
        fragvol_r      SMALLINT,
        fragsize_r     SMALLINT,
        fragment_class VARCHAR(254)
    )
INSERT INTO #fragment
    (
        cokey,
        chkey,
        compname,
        fragvol_r,
        fragsize_r,
        fragment_class
    )
            SELECT
                c3.cokey,
                ch.chkey,
                c3.compname,          --hzname , hzdept_r , hzdepb_r , 
                fragvol_r,
                                      --fragsize_l,  
                fragsize_r,           --,fragsize_h, fragkind, fragshp, fraground, fraghard,
                CASE
                    WHEN
                        (
                            fragshp = 'Flat'
                            AND fragsize_r
                        BETWEEN 2 AND 380
                        )
                        THEN 'channers and flagstones'
                    -- WHEN  (fragshp = 'Flat'	AND  fragsize_r BETWEEN   2	AND 150)	THEN 'channers' 
                    -- WHEN  (fragshp = 'Flat'	AND  fragsize_r BETWEEN   150 AND 380)	THEN 'flagstones' 
                    -- WHEN  (fragshp = 'Flat'	AND  fragsize_r BETWEEN   380 AND 600)	THEN 'stones' 
                    -- WHEN  (fragshp = 'Flat'	AND   fragsize_r >= 600)				THEN 'boulders'

                    WHEN
                        (
                            fragshp = 'Nonflat'
                            AND fragsize_r
                        BETWEEN 75 AND 250
                        )
                        THEN 'cobbles'
                    WHEN
                        (
                            fragshp = 'Nonflat'
                            AND fragsize_r >= 250
                        )
                        THEN 'stones and boulders'
                    -- WHEN  (fragshp = 'Nonflat' AND  fragsize_r BETWEEN   250 AND 600)	THEN 'stones' 
                    -- WHEN  (fragshp = 'Nonflat' AND  fragsize_r >=  600)				THEN 'boulders' 
                    WHEN
                        (
                            fragshp = 'Nonflat'
                            AND fragsize_r
                        BETWEEN 2 AND 75
                        )
                        THEN 'gravel'
                    WHEN (fragsize_r
                         BETWEEN 75 AND 250
                         )
                        THEN 'cobbles'
                    WHEN (fragsize_r >= 250)
                        THEN 'stones and boulders'
                    -- WHEN							 (fragsize_r BETWEEN  250	AND 600)	THEN 'stones' 
                    -- WHEN							  (fragsize_r >=  600)					THEN 'boulders' 
                    WHEN (fragsize_r
                         BETWEEN 2 AND 75
                         )
                        THEN 'gravel'
                    WHEN fraghard = 'Noncemented'
                        THEN 'para'
                    ELSE
                        'unspecified'
                END AS fragment_class --, --max_frag_volumne
            FROM
                #comp AS c3
                INNER JOIN
                    (chorizon AS ch
                INNER JOIN
                    chfrags   AS chf
                        ON chf.chkey = ch.chkey
                           AND hzdept_r < 50)
                        ON c3.cokey = ch.cokey
                           AND ch.chkey IN (
                                               SELECT TOP 1
                                                   ch2.chkey
                                               FROM
                                                   chorizon    AS ch2
                                                   INNER JOIN
                                                       chfrags AS chf2
                                                           ON chf2.chkey = ch2.chkey
                                                              AND c3.cokey = ch2.cokey
                                                              AND hzdept_r < 50
                                               ORDER BY
                                                   SUM(fragvol_r) OVER (PARTITION BY
                                                                            ch2.chkey
                                                                       ) DESC,
                                                   ch2.hzdepb_r ASC,
                                                   ch2.chkey
                                           )

CREATE TABLE #fragment2
    (
        cokey            INT,
        chkey            INT,
        compname         VARCHAR(60),
        total_frag_class SMALLINT,
        fragment_class   VARCHAR(254)
    )
INSERT INTO #fragment2
    (
        cokey,
        chkey,
        compname,
        total_frag_class,
        fragment_class
    )
            SELECT DISTINCT
                cokey,
                chkey,
                compname, --fragvol_r,  fragsize_r,  
                SUM(fragvol_r) OVER (PARTITION BY
                                         chkey,
                                         fragment_class
                                    ) as total_frag_class,
                fragment_class
            FROM
                #fragment
            GROUP BY
                cokey,
                chkey,
                compname,
                fragment_class,
                fragvol_r


-- FInal Fragments 
--Link
CREATE TABLE #frag
    (
        cokey                     INT,
        compname                  VARCHAR(60),
        [gravel]                  SMALLINT,
        [cobbles]                 SMALLINT,
        [stones and boulders]     SMALLINT,
        [para]                    SMALLINT,
        [channers and flagstones] SMALLINT,
        total_frags               SMALLINT
    )
INSERT INTO #frag
    (
        cokey,
        compname,
        [gravel],
        [cobbles],
        [stones and boulders],
        [para],
        [channers and flagstones],
        total_frags
    )
            SELECT
                cokey,
                compname,
                [gravel],
                [cobbles],
                [stones and boulders],
                [para],
                [channers and flagstones],
                total_frags = ISNULL([gravel], 0) + ISNULL([cobbles], 0) + ISNULL([stones and boulders], 0)
                              + ISNULL([para], 0) + ISNULL([channers and flagstones], 0)
            FROM
                (
                    SELECT
                        cokey,
                        compname,
                        total_frag_class,
                        fragment_class
                    FROM
                        #fragment2
                ) #f
            PIVOT
                (
                    MAX(total_frag_class)
                    FOR fragment_class IN (
                        [gravel], [cobbles], [stones and boulders], [para], [channers and flagstones]
                                          )
                ) AS #frag_pivot_table;



---Min Soil Profile Depth (Finds min depth from all the fields
CREATE TABLE #spd
    (
        cokey                 INT,
        minsoil_profile_depth SMALLINT
    )
INSERT INTO #spd
    (
        cokey,
        minsoil_profile_depth
    )
            SELECT
                #comp.cokey,
                (
                    SELECT
                        MIN(min_depth)
                    FROM
                        (
                            VALUES
                                (
                                    h_lithic_flag
                                ),
                                (
                                    h_parlithic_flag
                                ),
                                (
                                    h_parlithic_flag
                                ),
                                (
                                    h_duripan_flag
                                ),
                                (
                                    h_petrocalic_flag
                                ),
                                (
                                    h_petrogypsic_flag
                                ),
                                (
                                    h_petro_flag
                                ),
                                (
                                    [Densic bedrock]
                                ),
                                (
                                    [Lithic bedrock]
                                ),
                                (
                                    [Paralithic bedrock]
                                ),
                                (
                                    [Cemented horizon]
                                ),
                                (
                                    [Duripan]
                                ),
                                (
                                    [Fragipan]
                                ),
                                (
                                    [Manufactured layer]
                                ),
                                (
                                    [Petrocalcic]
                                ),
                                (
                                    [Petroferric]
                                ),
                                (
                                    [Petrogypsic]
                                )
                        ) AS d (min_depth)
                ) AS minsoil_profile_depth
            FROM
                #comp
                LEFT OUTER JOIN
                    #rest
                        ON #comp.cokey = #rest.cokey;



------------------------------------------------------------------------------------
--Final

SELECT DISTINCT
    #map.areaname,
    #map.areasymbol,
    #map.musym,
    #map.mukey,
    #map.muname,
    mlra_sym,                                                      --#map
    #comp.compname,
    #comp.cokey,
    #comp.comppct_r,
    #comp.landform,
    #comp.min_yr_water,
    #comp.subgroup,
    #comp.greatgroup,
    #comp.wei,
    #comp.weg,
    #comp.h_spodic_flag,
    #comp.h_lithic_flag,
    #comp.h_parlithic_flag,
    #comp.h_densic_flag,
    #comp.h_duripan_flag,
    #comp.h_petrocalic_flag,
    #comp.h_petrogypsic_flag,
    #comp.h_petro_flag,
    h_salt_flag,
    #comp.slope_r,
    #comp.hydgrp,
    #comp.taxmoistcl,
    #comp.taxmoistscl,
    soil_moisture_class,
    flood_freq,
    flood_dur,
	 	flooding_January,
		flooding_February,
		flooding_March,
		flooding_April,
		flooding_May,
		flooding_June,
		flooding_July,
		flooding_August	,
		flooding_September,
		flooding_October,
		flooding_November,
		flooding_December,

    pond_freq,
    pond_dur,
		ponding_January,
		ponding_February,
		ponding_March,
		ponding_April,
		ponding_May,
		ponding_June,
		ponding_July,
		ponding_August	,
		ponding_September,
		ponding_October,
		ponding_November,
		ponding_December,

    #comp.taxtempregime,
    #comp.taxtempcl,
    esd_id,
    esd_name,
    CASE
        WHEN sum_fragcov_low > 100
            THEN 100
        WHEN sum_fragcov_low > sum_fragcov_rv
            THEN sum_fragcov_rv
        ELSE
            sum_fragcov_low
    END                                     AS sum_fragcov_low2,
    CASE
        WHEN sum_fragcov_rv > 100
            THEN 100
        WHEN sum_fragcov_rv > sum_fragcov_high
            THEN sum_fragcov_high
        ELSE
            sum_fragcov_rv
    END                                     AS sum_fragcov_rv2,
    CASE
        WHEN sum_fragcov_high > 100
            THEN 100
        WHEN sum_fragcov_rv > sum_fragcov_high
            THEN sum_fragcov_rv
        ELSE
            sum_fragcov_high
    END                                     AS sum_fragcov_high2,
    #comp.major_mu_pct_sum,
    #comp.adj_comp_pct,
                                                                   --#comp 
    #water2.avg_h20_apr2sept,
    #water2.avg_h20_oct2march,
    avg_h20_nov2feb,
    avg_h20_march2oct,                                             -- #water2
                                                                   --#horizon.subgroup, #horizon.greatgroup, 
                                                                   --#horizon.max_ec_profile, #horizon.max_sar_profile,
    #horizon.maxec_0_2cm,
    #horizon.maxec_2_13cm,
    #horizon.maxec_13_50cm,
    #horizon.maxsar_0_2cm,
    #horizon.maxsar_2_13cm,
    #horizon.maxsar_13_50cm,
    #horizon.maxcaco3_0_2cm,
    #horizon.maxcaco3_2_13cm,
    #horizon.maxcaco3_13_50cm,
    #horizon.maxgypsum_0_2cm,
    #horizon.maxgypsum_2_13cm,
    #horizon.maxgypsum_13_50cm,
                                                                   --#horizon.maxcaco3_0_2cm, #horizon.maxcaco3_2_13cm, #horizon.maxcaco3_13_50cm, #horizon.maxsar_0_2cm, #horizon.maxsar_2_13cm, #horizon.maxsar_13_50cm, --#horizon.h_spodic_flag, --awc_r, kwfact, kffact, --#horizon
    maxph1to1h2o_0_15cm,
    minph1to1h2o_0_15cm,
    maxph01mcacl2_0_15cm,
    minph01mcacl2_0_15cm,
    maxcec7_0_15cm,
    mincec7_0_15cm,
    maxecec_0_15cm,
    minecec_0_15cm,
    #surface.hzname,
    #surface.hzdept_r,
    #surface.hzdepb_r,
    #surface.texture                        AS surf_texture,
    #surface.mineral_des,
    #surface.om_r                           AS surf_om_r,
    #surface.surface_mineral,
    #surface.awc_r,
    #surface.kwfact,
    #surface.kffact,                                               --#surface
    #surface_final3.tex_modifier            surf_tex_modifier,
    #surface_final3.tex_in_lieu,
    #surface_final3.texture_grouping        AS surf_texture_grouping,
    #surface_final3.min_top_depth,
    #surface_final3.max_bottom_depth,                              --#surface_final
    #diag.[Argillic horizon]                AS argillic_horizon_dia,
    #diag.[Albic horizon]                   AS albic_horizon_dia,
    #diag.[Cambic horizon]                  AS cambic_horizon_dia,
    #diag.[Densic contact]                  AS densic_contact_dia,
    #diag.[Duripan]                         AS duripan_dia,
    #diag.[Fragipan]                        AS fragipan_dia,
    #diag.[Lithic contact]                  AS lithic_contact_dia,
    #diag.[Oxic horizon]                    AS oxic_horizon_dia,
    #diag.[Paralithic contact]              AS paralithic_contact_dia,
    #diag.[Petro],
    #diag.[Spodic horizon]                  AS spodic_horizon_dia,
    #diag.[Salic horizon]                   AS Salic_horizon_diag, --#diag
    Diag1,
    Diag2,
    Diag3,                                                         -- Diag3 TOp 3 diagnostics

    #rest.[Densic bedrock]                  AS densic_bedrock_rest,
    #rest.[Lithic bedrock]                  AS lithic_bedrock_rest,
    #rest.[Paralithic bedrock]              AS paralithic_bedrock_rest,
    #rest.[Cemented horizon]                AS cemented_horizon_rest,
    #rest.[Duripan]                         AS duripan_rest,
    #rest.[Fragipan]                        AS fragipan_rest,
    #rest.[Manufactured layer]              AS manufactured_layer_rest,
    #rest.[Petrocalcic]                     AS petrocalcic_rest,
    #rest.[Petroferric]                     AS petroferric_rest,
    #rest.[Petrogypsic]                     AS petrogypsic_rest,   --#rest
    #frag.[gravel]                          AS thoriz_gravel,
    #frag.[cobbles]                         AS thoriz_cobbles,
    #frag.[stones and boulders]             AS thoriz_stones_and_boulders,
    #frag.[para]                            AS thoriz_para,
    #frag.[channers and flagstones]         AS thoriz_channers_and_flagstones,
    #frag.total_frags                       AS thoriz_total_frags, --#frag
    #aws150.aws150cm,
    #aws150.aws_0_20cm,
    #aws150.aws_20_50cm,
    #aws150.aws_50_100cm,
		minksat0_20cm  ,    
		maxksat0_20cm	,	
		minksat20_50cm,		
		maxksat20_50cm,		
		minksat50_100cm	,	 
		maxksat50_100cm		,
   CASE WHEN compkind = 'Miscellaneous area' THEN NULL WHEN #spd.minsoil_profile_depth IS NULL THEN 200 
   WHEN #spd.minsoil_profile_depth > 200 THEN 200 ELSE #spd.minsoil_profile_depth END AS PD_Fragi, --Switched the names around

	CASE WHEN compkind = 'Miscellaneous area' THEN NULL WHEN PD_Fragi IS NULL THEN 200 
	WHEN PD_Fragi > 200 THEN 200 ELSE 
	PD_Fragi END AS profile_depth  ,  --Switched the names around
    #comp.dom_comp_flag,
    #comp.majcompflag,
    #map.datestamp
FROM
    #map
    INNER JOIN
        #comp
            ON #comp.mukey = #map.mukey
    LEFT OUTER JOIN
        #water2
            ON #water2.cokey = #comp.cokey
    LEFT OUTER JOIN
        #horizon
            ON #horizon.cokey = #comp.cokey
    LEFT OUTER JOIN
        #surface
            ON #surface.cokey = #comp.cokey
    LEFT OUTER JOIN
        #surface_final3
            ON #surface_final3.cokey = #comp.cokey
    LEFT OUTER JOIN
        #diag
            ON #diag.cokey = #comp.cokey
    LEFT OUTER JOIN
        #diag3
            ON #diag3.cokey = #comp.cokey
    LEFT OUTER JOIN
        #rest
            ON #rest.cokey = #comp.cokey
    LEFT OUTER JOIN
        #frag
            ON #frag.cokey = #comp.cokey
    LEFT OUTER JOIN
        #spd
            ON #spd.cokey = #comp.cokey
    LEFT OUTER JOIN
        #aws150
            ON #aws150.cokey = #comp.cokey
    LEFT OUTER JOIN
        #flood_month
            ON #flood_month.cokey = #comp.cokey
    LEFT OUTER JOIN
        #pond_month
            ON #pond_month.cokey = #comp.cokey

WHERE --( dom_comp_flag = 'Yes' OR 1 = @domc) 
    (CASE
         WHEN 1 = @domc
             THEN 0
         WHEN dom_comp_flag = 'Yes'
             THEN 0
         ELSE
             1
     END = 0
    )
GROUP BY
    #map.areaname,
    #map.areasymbol,
    #map.musym,
    #map.mukey,
    #map.muname,
    mlra_sym,                         --#map
    #comp.compname,
    #comp.cokey,
    #comp.comppct_r,
    #comp.landform,
    #comp.min_yr_water,
    #comp.subgroup,
    #comp.greatgroup,
    #comp.wei,
    #comp.weg,
    #comp.h_spodic_flag,
    #comp.h_spodic_flag,
    #comp.h_lithic_flag,
    #comp.h_parlithic_flag,
    #comp.h_densic_flag,
    #comp.h_duripan_flag,
    #comp.h_petrocalic_flag,
    #comp.h_petrogypsic_flag,
    h_petro_flag,
    h_salt_flag,
    #comp.slope_r,
    #comp.hydgrp,
    #comp.taxmoistcl,
    #comp.taxmoistscl,
	#comp.compkind,
    soil_moisture_class,
    flood_freq,
    flood_dur,
    pond_freq,
    pond_dur,
	    		flooding_January,
		flooding_February,
		flooding_March,
		flooding_April,
		flooding_May,
		flooding_June,
		flooding_July,
		flooding_August	,
		flooding_September,
		flooding_October,
		flooding_November,
		flooding_December,
		ponding_January,
		ponding_February,
		ponding_March,
		ponding_April,
		ponding_May,
		ponding_June,
		ponding_July,
		ponding_August	,
		ponding_September,
		ponding_October,
		ponding_November,
		ponding_December,
    #comp.taxtempregime,
    #comp.taxtempcl,
    #comp.dom_comp_flag,
    #comp.esd_id,
    #comp.esd_name,
    sum_fragcov_low,
    sum_fragcov_rv,
    sum_fragcov_high,
    #comp.major_mu_pct_sum,
    #comp.adj_comp_pct,               --#comp 
    #water2.avg_h20_apr2sept,
    #water2.avg_h20_oct2march,
    avg_h20_nov2feb,
    avg_h20_march2oct,                -- #water2
    Diag1,
    Diag2,
    Diag3,
    #horizon.maxec_0_2cm,
    #horizon.maxec_2_13cm,
    #horizon.maxec_13_50cm,
    #horizon.maxsar_0_2cm,
    #horizon.maxsar_2_13cm,
    #horizon.maxsar_13_50cm,
    #horizon.maxcaco3_0_2cm,
    #horizon.maxcaco3_2_13cm,
    #horizon.maxcaco3_13_50cm,
    #horizon.maxgypsum_0_2cm,
    #horizon.maxgypsum_2_13cm,
    #horizon.maxgypsum_13_50cm,
    maxph1to1h2o_0_15cm,
    minph1to1h2o_0_15cm,
    maxph01mcacl2_0_15cm,
    minph01mcacl2_0_15cm,
    maxcec7_0_15cm,
    mincec7_0_15cm,
    maxecec_0_15cm,
    minecec_0_15cm,
                                      --#horizon
    #surface.hzname,
    #surface.hzdept_r,
    #surface.hzdepb_r,
    #surface.texture,
    #surface.mineral_des,
    #surface.om_r,
    #surface.surface_mineral,
    #surface.awc_r,
    #surface.kwfact,
    #surface.kffact,                  --#surface
    #surface_final3.tex_modifier,
    #surface_final3.tex_in_lieu,
    #surface_final3.texture_grouping,
    #surface_final3.min_top_depth,
    #surface_final3.max_bottom_depth, --#surface_final
    #diag.[Argillic horizon],
    #diag.[Albic horizon],
    #diag.[Cambic horizon],
    #diag.[Densic contact],
    #diag.[Duripan],
    #diag.[Fragipan],
    #diag.[Lithic contact],
    #diag.[Oxic horizon],
    #diag.[Paralithic contact],
    #diag.[Petro],
    #diag.[Spodic horizon],
    #diag.[Salic horizon],            --#diag
    #rest.[Densic bedrock],
    #rest.[Lithic bedrock],
    #rest.[Paralithic bedrock],
    #rest.[Cemented horizon],
    #rest.[Duripan],
    #rest.[Fragipan],
    #rest.[Manufactured layer],
    #rest.[Petrocalcic],
    #rest.[Petroferric],
    #rest.[Petrogypsic],              --#rest
    #frag.[gravel],
    #frag.[cobbles],
    #frag.[stones and boulders],
    #frag.[para],
    #frag.[channers and flagstones],
    #frag.total_frags,                --#frag
    #spd.minsoil_profile_depth,       --#spd
    #aws150.aws150cm,
    #aws150.aws_0_20cm,
    #aws150.aws_20_50cm,
    #aws150.aws_50_100cm,
    #comp.majcompflag,
	PD_Fragi,
		minksat0_20cm  ,    
		maxksat0_20cm	,	
		minksat20_50cm,		
		maxksat20_50cm,		
		minksat50_100cm	,	 
		maxksat50_100cm		,
    #map.datestamp
ORDER BY
    areasymbol ASC,
    musym ASC,
    mukey,
    comppct_r DESC,
    cokey

DROP TABLE IF EXISTS #map;
DROP TABLE IF EXISTS #water
DROP TABLE IF EXISTS #water2
DROP TABLE IF EXISTS #comp
DROP TABLE IF EXISTS #horizon
DROP TABLE IF EXISTS #surface
DROP TABLE IF EXISTS #surface_tex
DROP TABLE IF EXISTS #surface_tex2
DROP TABLE IF EXISTS #surface_tex3
DROP TABLE IF EXISTS #surface_tex4
DROP TABLE IF EXISTS #surface_final
DROP TABLE IF EXISTS #fragment
DROP TABLE IF EXISTS #fragment2
DROP TABLE IF EXISTS #diag
DROP TABLE IF EXISTS #diag3
DROP TABLE IF EXISTS #d
DROP TABLE IF EXISTS #r
DROP TABLE IF EXISTS #rest_pivot_table
DROP TABLE IF EXISTS #rest
DROP TABLE IF EXISTS #frag_pivot_table
DROP TABLE IF EXISTS #frag
DROP TABLE IF EXISTS #surface_final2
DROP TABLE IF EXISTS #surface_final3
DROP TABLE IF EXISTS #spd
DROP TABLE IF EXISTS #acpf
DROP TABLE IF EXISTS #aws
DROP TABLE IF EXISTS #aws150