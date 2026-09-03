CLASS zcl_resonance_seed_data DEFINITION
  PUBLIC FINAL CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES if_oo_adt_classrun.

ENDCLASS.

CLASS zcl_resonance_seed_data IMPLEMENTATION.

  METHOD if_oo_adt_classrun~main.

    DATA(lv_year) = sy-datum(4).

    " Clear any previous seed data (TESTxxx range only - safe)
    DELETE FROM zrlv_emp WHERE employee_id LIKE 'TEST%'.
    DELETE FROM zrlv_bal WHERE employee_id LIKE 'TEST%'.

    " Varied employees: mix of departments, workloads, skill groups
    INSERT zrlv_emp FROM TABLE @( VALUE #(
      ( client = sy-mandt employee_id = 'TEST001' employee_name = 'Alice Dlamini'   department = 'IT'      manager_id = 'MGR001' team_skill_group = 'ABAP'    workload_pct = '90.00' hire_date = '20200101' )
      ( client = sy-mandt employee_id = 'TEST002' employee_name = 'Bongani Nkosi'   department = 'IT'      manager_id = 'MGR001' team_skill_group = 'ABAP'    workload_pct = '35.00' hire_date = '20210101' )
      ( client = sy-mandt employee_id = 'TEST003' employee_name = 'Thabo Molefe'    department = 'Finance' manager_id = 'MGR002' team_skill_group = 'FICO'    workload_pct = '55.00' hire_date = '20190101' )
      ( client = sy-mandt employee_id = 'TEST004' employee_name = 'Sarah Mokoena'   department = 'Finance' manager_id = 'MGR002' team_skill_group = 'FICO'    workload_pct = '72.00' hire_date = '20220101' )
      ( client = sy-mandt employee_id = 'TEST005' employee_name = 'David van Wyk'   department = 'HR'      manager_id = 'MGR003' team_skill_group = 'HCM'     workload_pct = '45.00' hire_date = '20180101' )
      ( client = sy-mandt employee_id = 'TEST006' employee_name = 'Naledi Khumalo'  department = 'HR'      manager_id = 'MGR003' team_skill_group = 'HCM'     workload_pct = '83.00' hire_date = '20230101' )
      ( client = sy-mandt employee_id = 'TEST007' employee_name = 'James Botha'     department = 'Sales'   manager_id = 'MGR004' team_skill_group = 'SD'      workload_pct = '95.00' hire_date = '20170101' )
      ( client = sy-mandt employee_id = 'TEST008' employee_name = 'Zanele Dube'     department = 'Sales'   manager_id = 'MGR004' team_skill_group = 'SD'      workload_pct = '60.00' hire_date = '20200601' )
    ) ).

    " Balances - deliberately varied so risk tiers spread across all 3
    INSERT zrlv_bal FROM TABLE @( VALUE #(
      ( client = sy-mandt employee_id = 'TEST001' leave_type = 'ANNL' leave_year = lv_year entitled_days = '20.0' taken_days = '17.0' remaining_days = '3.0'  )
      ( client = sy-mandt employee_id = 'TEST002' leave_type = 'ANNL' leave_year = lv_year entitled_days = '20.0' taken_days = '5.0'  remaining_days = '15.0' )
      ( client = sy-mandt employee_id = 'TEST003' leave_type = 'ANNL' leave_year = lv_year entitled_days = '20.0' taken_days = '8.0'  remaining_days = '12.0' )
      ( client = sy-mandt employee_id = 'TEST004' leave_type = 'ANNL' leave_year = lv_year entitled_days = '20.0' taken_days = '12.0' remaining_days = '8.0'  )
      ( client = sy-mandt employee_id = 'TEST005' leave_type = 'ANNL' leave_year = lv_year entitled_days = '20.0' taken_days = '6.0'  remaining_days = '14.0' )
      ( client = sy-mandt employee_id = 'TEST006' leave_type = 'ANNL' leave_year = lv_year entitled_days = '20.0' taken_days = '18.0' remaining_days = '2.0'  )
      ( client = sy-mandt employee_id = 'TEST007' leave_type = 'ANNL' leave_year = lv_year entitled_days = '20.0' taken_days = '19.0' remaining_days = '1.0'  )
      ( client = sy-mandt employee_id = 'TEST008' leave_type = 'ANNL' leave_year = lv_year entitled_days = '20.0' taken_days = '10.0' remaining_days = '10.0' )
    ) ).

    out->write( |Seeded 8 employees across IT, Finance, HR, Sales.| ).
    out->write( |Expected spread: 3 CRITICAL, 1 ELEVATED, 4 STABLE.| ).

  ENDMETHOD.

ENDCLASS.
