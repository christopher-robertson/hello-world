select lm.wh_id + ';' + lm.arecod + ';' + lm.stoloc location_pk,
       lm.stoloc,
       lm.wh_id,
       am.bldg_id,
       lm.arecod,
       case when lm.arecod like '759OVSTK%' then '759 Overstock'
            when lm.arecod = '839OVSTK01' then '839 Overstock'
            when lm.arecod = '3158OSTK01' then '3158 Overstock'
            when lm.arecod = '839EPCK01' then '839 Each Pick'
            when (lm.arecod = '839CPCK01' and lm.aisle_id = '9') then '839 High Density'
            when lm.arecod like '839CPCK%' then '839 Case Pick'
            when (lm.arecod = '3158CPCK01' and lm.aisle_id = '25') then '3158 High Density'
            when lm.arecod like '3158CPCK%' then '3158 Case Pick'
            else lm.arecod
       end Area,
       (select lngdsc
          from wmsmp_prd.dscmst
         where colnam = 'locsts'
           and colval = lm.locsts) LocationStatus,
       lm.lochgt LocationHeight,
       lm.loclen LocationLength,
       lm.locwid LocationWidth,
       lm.maxqvl MaxQuantityValueCubicInches,
       lm.curqvl CurrentQuantityValueCubicInches,
       lm.pndqvl PendingQuantityValueCubicInches
  from wmsmp_prd.locmst lm
  join wmsmp_prd.aremst am
    on am.arecod = lm.arecod
   and am.wh_id = lm.wh_id
 where lm.pck_zone_id in (select pck_zone_id
                            from wmsmp_prd.pck_zone
                           where wh_id not in ('WMD1', 'SANTAANA')
                             and bldg_id != 'B1')