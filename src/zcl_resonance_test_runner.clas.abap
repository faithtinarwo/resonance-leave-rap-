CLASS zcl_resonance_test_runner DEFINITION
  PUBLIC FINAL CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES if_oo_adt_classrun.

ENDCLASS.

CLASS zcl_resonance_test_runner IMPLEMENTATION.

  METHOD if_oo_adt_classrun~main.

    " 0. Clean up any stale bad-key rows from earlier failed test runs
    DELETE FROM zrlv_req WHERE employee_id = 'TEST001'.
    DELETE FROM zrlv_alloc WHERE covering_employee_id = 'TEST002'.

    " 1. Insert test employee (high workload)
    DELETE FROM zrlv_emp WHERE employee_id = 'TEST001'.
    INSERT zrlv_emp FROM @( VALUE #(
      client           = sy-mandt
      employee_id      = 'TEST001'
      employee_name    = 'Test Employee'
      department       = 'IT'
      manager_id       = 'MGR001'
      team_skill_group = 'ABAP'
      workload_pct     = '85.00'
      hire_date        = '20200101'
    ) ).

    " Insert a second employee in the same skill group, low workload -
    " this is our expected coverage backup candidate
    DELETE FROM zrlv_emp WHERE employee_id = 'TEST002'.
    INSERT zrlv_emp FROM @( VALUE #(
      client           = sy-mandt
      employee_id      = 'TEST002'
      employee_name    = 'Backup Employee'
      department       = 'IT'
      manager_id       = 'MGR001'
      team_skill_group = 'ABAP'
      workload_pct     = '40.00'
      hire_date        = '20210101'
    ) ).

    " 2. Insert test balance row for current year
    DATA(lv_year) = sy-datum(4).
    DELETE FROM zrlv_bal WHERE employee_id = 'TEST001' AND leave_type = 'ANNL'.
    INSERT zrlv_bal FROM @( VALUE #(
      client         = sy-mandt
      employee_id    = 'TEST001'
      leave_type     = 'ANNL'
      leave_year     = lv_year
      entitled_days  = '20.0'
      taken_days     = '17.0'
      remaining_days = '3.0'
    ) ).

    out->write( |Test master data inserted. Workload=85%, Remaining balance=3 days.| ).
    out->write( |Expected: CRITICAL (score 3), coverage should route to TEST002.| ).

    " 3. Create a leave request via EML
    MODIFY ENTITIES OF ZI_RESONANCE_REQUEST
      ENTITY Request
        CREATE FIELDS ( EmployeeId LeaveType StartDate EndDate DaysRequested RequestStatus CoverageStatus )
        WITH VALUE #( (
          %cid           = cl_system_uuid=>create_uuid_x16_static( )
          EmployeeId     = 'TEST001'
          LeaveType      = 'ANNL'
          StartDate      = sy-datum
          EndDate        = sy-datum + 5
          DaysRequested  = '2.0'
          RequestStatus  = 'D'
          CoverageStatus = 'N'
        ) )
      MAPPED DATA(mapped)
      FAILED DATA(failed)
      REPORTED DATA(reported).

    IF failed IS NOT INITIAL.
      out->write( |CREATE FAILED. Details below:| ).
      LOOP AT reported-request INTO DATA(create_msg).
        IF create_msg-%msg IS BOUND.
          out->write( create_msg-%msg->if_message~get_text( ) ).
        ENDIF.
      ENDLOOP.
      RETURN.
    ENDIF.

    COMMIT ENTITIES
      RESPONSE OF ZI_RESONANCE_REQUEST
      FAILED DATA(commit_failed)
      REPORTED DATA(commit_reported).

    IF commit_failed IS NOT INITIAL.
      out->write( |COMMIT FAILED.| ).
      RETURN.
    ENDIF.

    out->write( |Request created successfully.| ).

    READ TABLE mapped-request INTO DATA(ls_mapped) INDEX 1.

    READ ENTITIES OF ZI_RESONANCE_REQUEST
      ENTITY Request
        ALL FIELDS
        WITH VALUE #( ( RequestId = ls_mapped-RequestId ) )
      RESULT DATA(result)
      FAILED DATA(read_failed).

    LOOP AT result INTO DATA(ls_result).
      out->write( |RequestId: { ls_result-RequestId }| ).
      out->write( |BurnoutRiskScore: { ls_result-BurnoutRiskScore } (1=STABLE, 2=ELEVATED, 3=CRITICAL)| ).
    ENDLOOP.

    " 4. Now call the submit action
    MODIFY ENTITIES OF ZI_RESONANCE_REQUEST
      ENTITY Request
        EXECUTE submit
        FROM VALUE #( ( RequestId = ls_mapped-RequestId ) )
      RESULT DATA(submit_result)
      FAILED DATA(submit_failed)
      REPORTED DATA(submit_reported).

    IF submit_failed IS NOT INITIAL.
      out->write( |SUBMIT FAILED.| ).
    ELSE.
      COMMIT ENTITIES
        RESPONSE OF ZI_RESONANCE_REQUEST
        FAILED DATA(submit_commit_failed)
        REPORTED DATA(submit_commit_reported).

      out->write( |Submit action completed.| ).

      LOOP AT submit_result INTO DATA(sr).
        out->write( |Final RequestStatus: { sr-%param-RequestStatus } (should be S)| ).
        out->write( |Final CoverageStatus: { sr-%param-CoverageStatus } (F=Found, U=Unresolved)| ).
      ENDLOOP.
    ENDIF.

  ENDMETHOD.

ENDCLASS.
