/* Formatted on 2016/06/29 11:29 (Formatter Plus v4.8.8) */
SELECT   ps_corporate_company.ps_corporate_company_desc AS sezionale,
e ti introduco un errore
         a.ps_invoice_external_number AS codice_fattura_sap,
         a.invoice_id AS codice_fattura_archibus,
         a.ps_invoice_vn_number AS numero_fattura_fornitore,
         COALESCE (ps_partner.ps_company_name,
                   ps_partner.name_first || ' ' || ps_partner.name_last
                  ) AS fornitore,
         ps_partner.ps_partner_vn_ex_code AS codice_fornitore_sap,
         a.ps_invoice_dt AS data_fattura,
         a.ps_posting_dt AS data_registrazione,
         a.ps_doc_type_desc AS tipo_documento,
         ps_distr_rule.ps_distr_rule_desc AS regola_distribuzione,
         stragg (DISTINCT ps_cost_su_aggr.table_name) AS oggetto_imputazione,
         stragg (DISTINCT ps_cost_su_aggr.site_id) AS id_sito,
         stragg (DISTINCT ps_cost_su_aggr.bl_id) AS id_fabbricato,
         stragg (DISTINCT ps_cost_su_aggr.ps_part_id) AS id_scala,
         stragg (DISTINCT ps_cost_su_aggr.ui) AS id_ui_rif,
         
         NVL
            (SUM
                (CASE
                    WHEN b.ps_item_category = 0
                    AND b.ps_credit_account_type = 1
                    AND COALESCE (b.ps_cad_cat_type_id,
                                  split_acc.ps_chart_account_drv
                                 ) = 'S'
                       THEN CASE
                              WHEN b.ps_key = '40'
                                 THEN -b.ps_amount
                              WHEN ps_key = '50'
                                 THEN b.ps_amount
                           END
                 END
                ),
             0
            ) AS imponibile_strumentale,
         NVL
            (SUM
                (CASE
                    WHEN b.ps_item_category = 0
                    AND b.ps_credit_account_type = 1
                    AND COALESCE (b.ps_cad_cat_type_id,
                                  split_acc.ps_chart_account_drv
                                 ) = 'A'
                       THEN CASE
                              WHEN b.ps_key = '40'
                                 THEN -b.ps_amount
                              WHEN ps_key = '50'
                                 THEN b.ps_amount
                           END
                 END
                ),
             0
            ) AS imponibile_abitativo,
         NVL
            (SUM
                (CASE
                    WHEN b.ps_item_category = 0
                    AND b.ps_credit_account_type = 1
                    AND COALESCE (b.ps_cad_cat_type_id,
                                  NVL (split_acc.ps_chart_account_drv, 'UI')
                                 ) IN ('UI', 'N')
                       THEN CASE
                              WHEN b.ps_key = '40'
                                 THEN -b.ps_amount
                              WHEN ps_key = '50'
                                 THEN b.ps_amount
                           END
                 END
                ),
             0
            ) AS imponibile_uso_impresa,
         NVL
            (SUM
                (CASE
                    WHEN b.ps_item_category = 3
                    AND COALESCE (b.ps_cad_cat_type_id,
                                  split_acc.ps_chart_account_drv
                                 ) = 'S'
                       THEN CASE
                              WHEN b.ps_key = '40'
                                 THEN -b.ps_amount
                              WHEN ps_key = '50'
                                 THEN b.ps_amount
                           END
                 END
                ),
             0
            ) AS iva_indet_strumentale,
         NVL
            (SUM
                (CASE
                    WHEN b.ps_item_category = 3
                    AND COALESCE (b.ps_cad_cat_type_id,
                                  split_acc.ps_chart_account_drv
                                 ) = 'A'
                       THEN CASE
                              WHEN b.ps_key = '40'
                                 THEN -b.ps_amount
                              WHEN ps_key = '50'
                                 THEN b.ps_amount
                           END
                 END
                ),
             0
            ) AS iva_indet_abitativo,
         NVL
            (SUM
                (CASE
                    WHEN b.ps_item_category = 3
                    AND COALESCE (b.ps_cad_cat_type_id,
                                  NVL (split_acc.ps_chart_account_drv, 'UI')
                                 ) IN ('UI', 'N')
                       THEN CASE
                              WHEN b.ps_key = '40'
                                 THEN -b.ps_amount
                              WHEN ps_key = '50'
                                 THEN b.ps_amount
                           END
                 END
                ),
             0
            ) AS iva_indet_uso_impresa,
         c.cost_tran_id
    FROM ps_invoice a INNER JOIN ps_invoice_item b ON a.invoice_id =
                                                                  b.invoice_id
         INNER JOIN ps_corporate_company
         ON a.ps_partner_role_type_ls_id =
                                  ps_corporate_company.ps_corporate_company_id
         INNER JOIN ps_partner ON a.ps_partner_id = ps_partner.ps_partner_id
         INNER JOIN cost_tran c ON b.cost_tran_id = c.cost_tran_id
         INNER JOIN ps_cost_tran ON ps_cost_tran.cost_tran_id = c.cost_tran_id
         LEFT OUTER JOIN
         (SELECT   ROW_NUMBER () OVER (ORDER BY COUNT (pkey_value) DESC) rn,
                   stragg (DISTINCT table_name) AS table_name,
                   stragg
                      (DISTINCT CASE
                          WHEN table_name = 'Siti' OR table_name = 'Proprieta'
                             THEN pkey_value
                       END
                      ) AS site_id,
                   stragg
                         (DISTINCT CASE
                             WHEN table_name = 'Edifici'
                                THEN pkey_value
                          END
                         ) AS bl_id,
                   stragg
                      (DISTINCT CASE
                          WHEN table_name = 'Scale'
                             THEN pkey_value
                       END
                      ) AS ps_part_id,
                   stragg
                      (DISTINCT CASE
                          WHEN table_name = 'Unita'' Immobiliari'
                             THEN pkey_value
                       END
                      ) AS ui,
                   stragg (su.NAME) AS ui_name, cost_tran_id
              FROM ps_cost_su_aggr LEFT OUTER JOIN su
                   ON ps_cost_su_aggr.table_name = 'Unita'' Immobiliari'
                 AND SUBSTR (pkey_value, 0, INSTR (pkey_value, ';', 1, 1) - 1) =
                                                                      su.su_id
                 AND SUBSTR (pkey_value, INSTR (pkey_value, ';', 1, 1) + 1, 3) =
                                                                      su.fl_id
                 AND SUBSTR (pkey_value, INSTR (pkey_value, ';', 1, 2) + 1) =
                                                                      su.bl_id
          GROUP BY cost_tran_id) ps_cost_su_aggr
         ON c.cost_tran_id = ps_cost_su_aggr.cost_tran_id
         LEFT OUTER JOIN ps_distr_rule
         ON ps_cost_tran.ps_distr_rule_id = ps_distr_rule.ps_distr_rule_id
         LEFT OUTER JOIN
         (SELECT ps_split_acc_sub.ps_chart_of_account_id,
                 ps_split_acc_sub.ps_chart_account_dest,
                 ps_split_acc_sub.ps_chart_account_drv,
                 ps_cost_category.cost_cat_id
            FROM ps_split_acc_sub, ps_cost_category
           WHERE (   ps_cost_category.ps_credit_account =
                                                ps_split_acc_sub.ps_account_id
                  OR ps_cost_category.ps_debit_account =
                                                ps_split_acc_sub.ps_account_id
                 )) split_acc
         ON split_acc.ps_chart_of_account_id = a.ps_partner_role_type_ls_id
       AND split_acc.cost_cat_id = c.cost_cat_id
       AND split_acc.ps_chart_account_dest = b.ps_account
         , ps_cost_category d
   WHERE a.invoice_id = b.invoice_id
     AND b.cost_tran_id = c.cost_tran_id
     AND c.cost_cat_id = d.cost_cat_id
     AND d.cost_cat_desc LIKE '%SPE06%'
     AND d.cost_cat_id NOT IN ('1060003241', '2060003241')
     AND a.ps_invoice_external_number IS NOT NULL
     --AND a.invoice_id = 118390
     AND a.ps_posting_year = 2015
     AND (   (b.ps_item_category = 0 AND b.ps_credit_account_type = 1)
          OR (b.ps_item_category = 3)
         )
     AND a.ps_doc_type_id NOT IN ('PA', 'D3', 'D4')
GROUP BY ps_corporate_company.ps_corporate_company_desc,
         a.ps_invoice_external_number,
         a.invoice_id,
         a.ps_invoice_dt,
         a.ps_posting_dt,
         a.ps_doc_type_desc,
         ps_distr_rule.ps_distr_rule_desc,
         a.ps_invoice_vn_number,
         COALESCE (ps_partner.ps_company_name,
                   ps_partner.name_first || ' ' || ps_partner.name_last
                  ),
         ps_partner.ps_partner_vn_ex_code,
         c.cost_tran_id
ORDER BY a.ps_posting_dt ASC, a.ps_invoice_external_number ASC;

---controlli
/* Formatted on 2016/06/29 10:31 (Formatter Plus v4.8.8) */
SELECT   a.invoice_id,
         SUM (CASE
                 WHEN b.ps_key = '40'
                    THEN -b.ps_amount
                 WHEN ps_key = '50'
                    THEN b.ps_amount
              END
             ) AS amount,
         ps_distr_rule.ps_distr_rule_desc, c.cost_Tran_i
    FROM ps_invoice a,
         ps_invoice_item b,
         cost_tran c,
         ps_cost_category d,
         ps_cost_tran,
         ps_distr_rule
   WHERE a.ps_invoice_external_number IS NOT NULL
     AND a.ps_posting_year = 2015
     AND (   (b.ps_item_category = 0 AND b.ps_credit_account_type = 1)
          OR (b.ps_item_category = 3)
         )
     AND a.ps_doc_type_id NOT IN ('PA', 'D3', 'D4')
     AND a.invoice_id = b.invoice_id
     AND b.cost_tran_id = c.cost_tran_id
     AND a.invoice_id = c.invoice_id
     AND c.cost_cat_id = d.cost_cat_id
     AND d.cost_cat_desc LIKE '%SPE06%'
     AND d.cost_cat_id NOT IN ('1060003241', '2060003241')
     AND c.cost_tran_id = ps_cost_tran.cost_tran_id
     AND ps_cost_tran.ps_distr_rule_id = ps_distr_rule.ps_distr_rule_id
GROUP BY a.invoice_id, ps_distr_rule.ps_distr_rule_desc, c.cost_tran_id