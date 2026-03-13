SELECT DISTINCT
	  key_value KEY
	,'PENDING_TIMECARD_TEMPLATE' TEMPLATE
	,'en-US' LOCALE
	,'HTML' OUTPUT_FORMAT
	,'EMAIL' DEL_CHANNEL
	,email_address PARAMETER1
	,'bipublisher-report@oracle.com' PARAMETER3
	,'Unapproved Timecard and Absence Report as of ' || TO_CHAR(SYSDATE, 'MM/DD/YYYY') PARAMETER4
	,'false' PARAMETER6

FROM 

(SELECT DISTINCT
	 pasf.manager_id key_value
	,ppnf.display_name manager_name
	,(SELECT email_address
	 FROM per_email_addresses
   	 WHERE person_id = pasf.manager_id
	 AND email_type = 'W1'
	) email_address
	
FROM
	 per_assignment_supervisors_f pasf
	,per_all_people_f papf
	,per_all_assignments_f paaf
    ,per_person_names_f ppnf

WHERE 1=1
	AND pasf.manager_id = papf.person_id
	AND papf.person_id = paaf.person_id
	AND papf.person_id = ppnf.person_id
	AND paaf.assignment_status_type = 'ACTIVE'
	AND pasf.manager_type = 'LINE_MANAGER'
	AND ppnf.name_type = 'GLOBAL'
	AND Trunc(sysdate) BETWEEN Trunc(papf.effective_start_date) AND Trunc(papf.effective_end_date)
    AND Trunc(sysdate) BETWEEN Trunc(pasf.effective_start_date) AND Trunc(pasf.effective_end_date)
	AND Trunc(sysdate) BETWEEN Trunc(paaf.effective_start_date) AND Trunc(paaf.effective_end_date)
)