select t.wh_id WarehouseID,
       t.bldg_id BuildingID,
       t.prtnum Item,
       (select lngdsc
          from wmsmp_prd.dscmst
         where colval = t.prtfit
           and colnam = 'prtfit'
           and locale_id = 'US_ENGLISH') Brand,
       t.lngdsc ItemDescription,
       t.sup_lotnum SupplierLotNumber,
       round(sum(t.case_qty), 2) CaseQty,
       round(sum(t.cubic_inch), 2) VolumeCubicInch,
       string_agg(t.aisle_id, ';') AisleID,
       string_agg(t.stoloc, ';') StorageLocation
  from (select lm.wh_id,
               am.bldg_id,
               lm.aisle_id,
               lm.stoloc,
               d.prtnum,
               pm.prtfit,
               pd.lngdsc,
               d.sup_lotnum,
               cast(d.untqty as float) / d.untcas case_qty,
               (pfd.len * pfd.wid * pfd.hgt) *(cast(d.untqty as float) / d.untcas) cubic_inch
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
           and lm.stoflg = 1
           and lm.stoloc not like '%MCB%'
           and ((lm.wh_id = 'GOLETA' and lm.aisle_id != '9') or (lm.wh_id = 'SANTAROSA' and lm.aisle_id != '25'))) t
 group by t.wh_id,
       t.bldg_id,
       t.prtnum,
       t.prtfit,
       t.lngdsc,
       t.sup_lotnum
having sum(t.cubic_inch) < 1500