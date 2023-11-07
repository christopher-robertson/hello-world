select lm.wh_id + ';' + lm.arecod + ';' + lm.stoloc location_pk,
       l.wh_id WarehouseID,
       d.prt_client_id ClientID,
       d.inv_attr_str4 BuildingID,
       lm.arecod AreaCode,
       l.stoloc StorageLocation,
       (select min(lngdsc)
          from wmsmp_prd.dscmst
         where colval = pm.prtfit
           and colnam = 'prtfit'
           and locale_id = 'US_ENGLISH') BrandDescription,
       d.prtnum Item,
       left(pd.lngdsc, 50) ItemDescription,
       d.lotnum LotNumber,
       format(d.expire_dte, 'yyyy-MM-dd HH:mm:ss') ExpirationDate,
       d.revlvl METRCID,
       l.lodnum LPN,
       d.dtlnum DetailLPN,
       d.untqty EachQty,
       round(d.untqty / cast(pfc.untqty as float), 2) CaseQty,
       iv.comqty CommittedEaches,
       round((d.untqty / cast(pfc.untqty as float)) *(pfc.len * pfc.wid * pfc.hgt), 2) VolumeCubicInch,
       case when exists(select 'x'
                          from wmsmp_prd.invdtl
                          join wmsmp_prd.invsub
                            on invsub.subnum = invdtl.subnum
                          join wmsmp_prd.invlod
                            on invlod.lodnum = invsub.lodnum
                          join wmsmp_prd.locmst
                            on locmst.wh_id = invlod.wh_id
                           and locmst.stoloc = invlod.stoloc
                         where locmst.pck_zone_id in (select pck_zone_id
                                                        from wmsmp_prd.pck_zone
                                                       where wh_id not in ('WMD1', 'SANTAANA')
                                                         and bldg_id != 'B1')
                           and invlod.wh_id = l.wh_id
                           and invdtl.prt_client_id = d.prt_client_id
                           and invdtl.prtnum = d.prtnum
                         group by locmst.wh_id,
                               invdtl.prt_client_id,
                               invdtl.prtnum
                        having count(distinct locmst.stoloc) > 1) then 1
            else 0
       end SKUConsolidationOpportunity,
       case when exists(select 'x'
                          from wmsmp_prd.invdtl
                          join wmsmp_prd.invsub
                            on invsub.subnum = invdtl.subnum
                          join wmsmp_prd.invlod
                            on invlod.lodnum = invsub.lodnum
                          join wmsmp_prd.locmst
                            on locmst.wh_id = invlod.wh_id
                           and locmst.stoloc = invlod.stoloc
                         where locmst.pck_zone_id in (select pck_zone_id
                                                        from wmsmp_prd.pck_zone
                                                       where wh_id not in ('WMD1', 'SANTAANA')
                                                         and bldg_id != 'B1')
                           and invlod.wh_id = l.wh_id
                           and invdtl.prt_client_id = d.prt_client_id
                           and invdtl.prtnum = d.prtnum
                           and invdtl.lotnum = d.lotnum
                           and
                        case when locmst.arecod like '%PCK%' then 'PICKZONE'
                             when locmst.arecod like '%MCB%' then 'MCBZONE'
                             else 'OVERSTOCKZONE'
                        end =
                        case when lm.arecod like '%PCK%' then 'PICKZONE'
                             when lm.arecod like '%MCB%' then 'MCBZONE'
                             else 'OVERSTOCKZONE'
                        end
                         group by locmst.wh_id,
                               invdtl.prt_client_id,
                               case when locmst.arecod like '%PCK%' then 'PICKZONE'
                                    when locmst.arecod like '%MCB%' then 'MCBZONE'
                                    else 'OVERSTOCKZONE' end,
                                    invdtl.prtnum,
                                    invdtl.lotnum
                             having count(distinct locmst.stoloc) > 1) then 1
                               else 0
            end LotNumberConsolidationOpportunity,
            case when exists(select 'x'
                               from wmsmp_prd.invdtl
                               join wmsmp_prd.invsub
                                 on invsub.subnum = invdtl.subnum
                               join wmsmp_prd.invlod
                                 on invlod.lodnum = invsub.lodnum
                               join wmsmp_prd.locmst
                                 on locmst.wh_id = invlod.wh_id
                                and locmst.stoloc = invlod.stoloc
                              where locmst.pck_zone_id in (select pck_zone_id
                                                             from wmsmp_prd.pck_zone
                                                            where wh_id not in ('WMD1', 'SANTAANA')
                                                              and bldg_id != 'B1')
                                and invlod.wh_id = l.wh_id
                                and invdtl.prt_client_id = d.prt_client_id
                                and invdtl.prtnum = d.prtnum
                                and invdtl.lotnum = d.lotnum
                              group by locmst.wh_id,
                                    invdtl.prt_client_id,
                                    invdtl.prtnum,
                                    invdtl.lotnum
                             having count(distinct locmst.stoloc) > 1) then 1
                 else 0
            end TopOff
       from wmsmp_prd.invdtl d
       join wmsmp_prd.invsub s
         on s.subnum = d.subnum
       join wmsmp_prd.invlod l
         on l.lodnum = s.lodnum
       join wmsmp_prd.invsum iv
         on iv.stoloc = l.stoloc
        and iv.wh_id = l.wh_id
       left outer
       join wmsmp_prd.locmst lm
         on lm.stoloc = l.stoloc
        and lm.wh_id = l.wh_id
       left outer
       join wmsmp_prd.prtdsc pd
         on pd.colval = d.prtnum + '|' + d.prt_client_id + '|' + l.wh_id
        and pd.locale_id = 'US_ENGLISH'
        and pd.colnam = 'prtnum|prt_client_id|wh_id_tmpl'
       left outer
       join wmsmp_prd.prtftp_dtl pfc
         on pfc.prtnum = d.prtnum
        and pfc.prt_client_id = d.prt_client_id
        and pfc.wh_id = l.wh_id
        and pfc.ftpcod = d.ftpcod
        and pfc.cas_flg = 1
       left outer
       join wmsmp_prd.prtmst pm
         on pm.prtnum = pfc.prtnum
        and pm.prt_client_id = pfc.prt_client_id
        and pm.wh_id_tmpl = pfc.wh_id
      where lm.pck_zone_id in (select pck_zone_id
                                 from wmsmp_prd.pck_zone
                                where wh_id not in ('WMD1', 'SANTAANA')
                                  and bldg_id != 'B1')