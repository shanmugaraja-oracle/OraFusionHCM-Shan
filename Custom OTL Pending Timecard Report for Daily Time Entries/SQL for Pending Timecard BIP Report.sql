SELECT
	 x.manager_id key_value
	,x.manager_name manager_name
	,x.person_name person_name
	,x.creation_date creation_date
	,x.hours_type hours_type
	,SUM(hours) hours
	,x.mgr_email email_address

FROM
(
(SELECT DISTINCT
	 papf.person_number
	,ppnf.display_name person_name
	,lm.manager_name manager_name
	,lm.person_number manager_number
	,lm.manager_id manager_id
	,TO_CHAR(htre.start_time, 'MM/DD/YYYY') creation_date
	,aatf.name hours_type
	,htre.measure hours

	,(SELECT email_address
	 FROM per_email_addresses
	 WHERE person_id = lm.manager_id
	 AND email_type = 'W1'
	) mgr_email

FROM
	 per_all_people_f papf
	,per_person_names_f ppnf
	,per_all_assignments_f paaf
	,hwm_ext_timecard_detail_v htre
	,anc_per_abs_entries apae
	,anc_absence_types_f_tl aatf

	,(SELECT
		 papf1.person_number
		,pasf.person_id
		,pasf.manager_type
		,pasf.manager_id
		,ppnf1.display_name manager_name
		,paaf1.assignment_number
		,past1.user_status

	FROM
		 per_assignment_supervisors_f pasf
		,per_person_names_f ppnf1
		,per_all_assignments_f paaf1
		,per_all_people_f papf1
		,per_assignment_status_types_tl past1

	WHERE 1=1
		AND ppnf1.person_id = pasf.manager_id
		AND ppnf1.name_type = 'GLOBAL'
		AND paaf1.person_id = pasf.manager_id
		AND paaf1.effective_latest_change = 'Y'
		AND paaf1.primary_assignment_flag = 'Y'
		AND paaf1.assignment_type in ( 'E', 'C', 'P', 'N' )
		AND pasf.manager_type = 'LINE_MANAGER'
		AND ppnf1.person_id = papf1.person_id
		AND paaf1.assignment_status_type_id = past1.assignment_status_type_id
		AND Trunc(sysdate) BETWEEN Trunc(paaf1.effective_start_date) AND Trunc(paaf1.effective_end_date)
		AND Trunc(sysdate) BETWEEN Trunc(ppnf1.effective_start_date) AND Trunc(ppnf1.effective_end_date)
		AND Trunc(sysdate) BETWEEN Trunc(papf1.effective_start_date) AND Trunc(papf1.effective_end_date)
		AND Trunc(sysdate) BETWEEN Trunc(pasf.effective_start_date) AND Trunc(pasf.effective_end_date)
	) lm

WHERE
	1=1
	AND papf.person_id = paaf.person_id
	AND papf.person_id = ppnf.person_id
	AND ppnf.name_type = 'GLOBAL'
	AND paaf.assignment_status_type = 'ACTIVE'
	AND paaf.primary_assignment_flag = 'Y'
	AND papf.person_id = htre.resource_id
	AND htre.subresource_id = paaf.assignment_id
	AND htre.grp_type_name = 'Absences Entry'
	AND htre.layer_code = 'ABSENCES'
	AND Nvl(htre.delete_flag, 'N') <> 'Y'
	AND htre.latest_version = 'Y'
	AND apae.person_id = htre.resource_id
	AND apae.approval_status_cd NOT IN ('DENIED', 'APPROVED')
	AND apae.absence_type_id = aatf.absence_type_id
	AND lm.person_id = paaf.person_id
	AND TO_DATE(TO_CHAR(htre.start_time, 'MM/DD/YYYY'), 'MM/DD/YYYY') BETWEEN 
		TO_DATE(TO_CHAR(apae.start_date, 'MM/DD/YYYY'), 'MM/DD/YYYY') AND TO_DATE(TO_CHAR(apae.end_date, 'MM/DD/YYYY'), 'MM/DD/YYYY')
	AND Trunc(sysdate) BETWEEN papf.effective_start_date AND papf.effective_end_date
	AND Trunc(sysdate) BETWEEN paaf.effective_start_date AND paaf.effective_end_date
	AND Trunc(sysdate) BETWEEN ppnf.effective_start_date AND ppnf.effective_end_date
	AND (EXISTS (SELECT 1
		FROM FUSION.PER_PERSON_SECURED_LIST_V pas
		WHERE pas.person_id = lm.manager_id
		AND lm.manager_id = HRC_SESSION_UTIL.GET_USER_PERSONID)
		OR EXISTS (SELECT 1
FROM per_user_roles pur,
     per_users pu,
     per_roles_dn_tl prdt
WHERE pu.user_id = pur.user_id
AND prdt.role_id = pur.role_id
AND prdt.language = USERENV('lang')
and pu.person_id = HRC_SESSION_UTIL.GET_USER_PERSONID
and prdt.role_name IN ('Payroll Manager')))
)

UNION

(SELECT
	 papf.person_number
	,ppnf.display_name person_name
	,lm.manager_name manager_name
	,lm.person_number manager_number
	,lm.manager_id manager_id
	,TO_CHAR(htrc.change_date, 'MM/DD/YYYY') creation_date
	,hnvt.alt_name_value hours_type
	,hcra.measure_new hours
	
	,(SELECT email_address
	 FROM per_email_addresses
	 WHERE person_id = lm.manager_id
	 AND email_type = 'W1'
	) mgr_email
	
FROM
	 per_all_people_f papf
	,per_person_names_f ppnf
	,per_all_assignments_f paaf
	,hwm_te_alt_name_vals_b htnv
	,hwm_te_alt_name_vals_tl hnvt
	,hxt_change_req_aprv_dtl hcra
	,hwm_tm_rec_change_reqs htrc
	
	,(SELECT
		 papf1.person_number
		,pasf.person_id
		,pasf.manager_type
		,pasf.manager_id
		,ppnf1.display_name manager_name
		,paaf1.assignment_number
		,past1.user_status

	FROM
		 per_assignment_supervisors_f pasf
		,per_person_names_f ppnf1
		,per_all_assignments_f paaf1
		,per_all_people_f papf1
		,per_assignment_status_types_tl past1

	WHERE 1=1
		AND ppnf1.person_id = pasf.manager_id
		AND ppnf1.name_type = 'GLOBAL'
		AND paaf1.person_id = pasf.manager_id
		AND paaf1.effective_latest_change = 'Y'
		AND paaf1.primary_assignment_flag = 'Y'
		AND paaf1.assignment_status_type = 'ACTIVE'
		AND paaf1.assignment_type in ( 'E', 'C', 'P', 'N' )
		AND pasf.manager_type = 'LINE_MANAGER'
		AND ppnf1.person_id = papf1.person_id
		AND paaf1.assignment_status_type_id = past1.assignment_status_type_id
		AND Trunc(sysdate) BETWEEN Trunc(paaf1.effective_start_date) AND Trunc(paaf1.effective_end_date)
		AND Trunc(sysdate) BETWEEN Trunc(ppnf1.effective_start_date) AND Trunc(ppnf1.effective_end_date)
		AND Trunc(sysdate) BETWEEN Trunc(papf1.effective_start_date) AND Trunc(papf1.effective_end_date)
		AND Trunc(sysdate) BETWEEN Trunc(pasf.effective_start_date) AND Trunc(pasf.effective_end_date)
	) lm
	
WHERE
	1=1
	AND papf.person_id = ppnf.person_id
	AND ppnf.name_type = 'GLOBAL'
	AND htrc.resource_id = papf.person_id
	AND paaf.assignment_status_type = 'ACTIVE'
	AND paaf.primary_assignment_flag = 'Y'
	AND hcra.attribute_number9_new = paaf.assignment_id
	AND htrc.resource_id = paaf.person_id
	AND htrc.tm_rec_change_req_id = hcra.tm_rec_change_req_id
	AND htrc.status = '0'
	AND htnv.te_alt_name_val_id = hnvt.te_alt_name_val_id
	AND ((htnv.attribute20 IS NULL
	AND htnv.attribute25 IS NULL
	AND htnv.attribute15 = hcra.attribute_char5_new
	AND SUBSTR(htnv.attribute10, 17) = hcra.attribute_char12_new)
	OR 	(htnv.attribute10 IS NULL
	AND htnv.attribute20 IS NULL
	AND htnv.attribute15 = hcra.attribute_char5_new
	AND htnv.attribute25 = hcra.attribute_number16_new)
	OR 	(htnv.attribute15 IS NULL
	AND htnv.attribute20 IS NULL
	AND htnv.attribute25 IS NULL
	AND SUBSTR(htnv.attribute10, 17) = hcra.attribute_char12_new))
	AND lm.person_id = paaf.person_id
	AND NOT EXISTS(SELECT 1 FROM hwm_tm_rec_grp_sum
					WHERE 1=1
						AND resource_id = htrc.resource_id
						AND Trunc(htrc.change_date) BETWEEN Trunc(start_time) AND Trunc(stop_time)
						AND htrc.tm_rec_grp_id IS NULL)
	AND Trunc(sysdate) BETWEEN papf.effective_start_date AND papf.effective_end_date
	AND Trunc(sysdate) BETWEEN paaf.effective_start_date AND paaf.effective_end_date
	AND Trunc(sysdate) BETWEEN ppnf.effective_start_date AND ppnf.effective_end_date
	AND (EXISTS (SELECT 1
		FROM FUSION.PER_PERSON_SECURED_LIST_V pas
		WHERE pas.person_id = lm.manager_id
		AND lm.manager_id = HRC_SESSION_UTIL.GET_USER_PERSONID)
		OR EXISTS (SELECT 1
FROM per_user_roles pur,
     per_users pu,
     per_roles_dn_tl prdt
WHERE pu.user_id = pur.user_id
AND prdt.role_id = pur.role_id
AND prdt.language = USERENV('lang')
and pu.person_id = HRC_SESSION_UTIL.GET_USER_PERSONID
and prdt.role_name IN ('Payroll Manager')))
)
) x

GROUP BY
	 x.manager_id
	,x.manager_name
	,x.person_name
	,x.creation_date
	,x.hours_type
	,x.mgr_email

ORDER BY
	 x.person_name
	,x.creation_date
	,x.hours_type