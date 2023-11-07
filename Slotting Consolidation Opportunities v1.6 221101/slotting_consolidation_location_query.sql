select u.wh_id WarehouseID,
       u.bldg_id BuildingID,
       u.prtnum Item,
       u.Brand,
       u.lngdsc ItemDescription,
       u.sup_lotnum SupplierLotNumber,
       sum(u.CaseQty) CaseQty,
       sum(u.VolumeCubicInch) VolumeCubicInch,
       string_agg(u.aisle_id, ';') AisleID,
       string_agg(u.stoloc, ';') StorageLocation
  from (select t.wh_id,
               t.bldg_id,
               t.prtnum,
               (select lngdsc
                  from wmsmp_prd.dscmst
                 where colval = t.prtfit
                   and colnam = 'prtfit'
                   and locale_id = 'US_ENGLISH') Brand,
               t.lngdsc,
               t.sup_lotnum,
               round(sum(t.case_qty), 2) CaseQty,
               round(sum(t.cubic_inch), 2) VolumeCubicInch,
               t.aisle_id,
               t.stoloc
          from (select lm.wh_id,
                       am.bldg_id,
                       d.prtnum,
                       pm.prtfit,
                       pd.lngdsc,
                       d.sup_lotnum,
                       cast(d.untqty as float) / d.untcas case_qty,
                       (pfd.len * pfd.wid * pfd.hgt) *(cast(d.untqty as float) / d.untcas) cubic_inch,
                       lm.aisle_id,
                       lm.stoloc
                  from wmsmp_prd.invlod l
                  join wmsmp_prd.invsub s
                    on s.lodnum = l.lodnum
                  join wmsmp_prd.invdtl d
                    on d.subnum = s.subnum
                  join wmsmp_prd.prtmst pm
                    on d.prtnum = pm.prtnum
                   and l.wh_id = pm.wh_id_tmpl
                   and d.prt_client_id = pm.prt_client_id
                  join wmsmp_prd.prtdsc pd
                    on pd.colnam = 'prtnum|prt_client_id|wh_id_tmpl'
                   and pd.colval = pm.prtnum + '|' + pm.prt_client_id + '|' + pm.wh_id_tmpl
                   and pd.locale_id = 'US_ENGLISH'
                  join wmsmp_prd.locmst lm
                    on l.stoloc = lm.stoloc
                   and l.wh_id = lm.wh_id
                  join wmsmp_prd.aremst am
                    on am.arecod = lm.arecod
                   and am.wh_id = lm.wh_id
                  
                  join wmsmp_prd.prtftp_dtl pfd
                    on pfd.wh_id = l.wh_id
                   and pfd.prt_client_id = d.prt_client_id
                   and pfd.prtnum = d.prtnum
                   and pfd.cas_flg = 1
                 where l.wh_id not in ('WMD1', '----', 'SANTAANA')
                   and d.prt_client_id = 'HDS'
                   and lm.useflg = 1
                   and lm.pckflg = 1
                   and lm.stoflg = 1) t
         group by t.wh_id,
               t.bldg_id,
               t.prtnum,
               t.prtfit,
               t.lngdsc,
               t.sup_lotnum,
               t.aisle_id,
               t.stoloc) u
 group by u.wh_id,
       u.bldg_id,
       u.prtnum,
       u.Brand,
       u.lngdsc,
       u.sup_lotnum