CLASS zcl_resonance_test_runner DEFINITION
  PUBLIC FINAL CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES if_oo_adt_classrun.

ENDCLASS.

CLASS zcl_resonance_test_runner IMPLEMENTATION.

  METHOD if_oo_adt_classrun~main.

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

    " 2. Insert test balance row for current year, low remaining days
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
    out->write( |Expected result: CRITICAL (risk score 3).| ).

    " 3. Create a leave request via EML
    MODIFY ENTITIES OF ZI_RESONANCE_REQUEST
      ENTITY Request
        CREATE FIELDS ( EmployeeId LeaveType StartDate EndDate DaysRequested RequestStatus CoverageStatus )
        WITH VALUE #( (
          %cid           = 'REQ1'
          EmployeeId     = 'TEST001'
          LeaveType      = 'ANNL'
          StartDate      = sy-datum
          EndDate        = sy-datum + 5
          DaysRequested  = '5.0'
          RequestStatus  = 'D'
          CoverageStatus = 'N'
        ) )
      MAPPED DATA(mapped)
      FAILED DATA(failed)
      REPORTED DATA(reported).

    IF failed IS NOT INITIAL.
      out->write( |CREATE FAILED.| ).
      LOOP AT reported-request INTO DATA(msg).
        DATA(lv_text) = COND string( WHEN msg-%msg IS BOUND
                                      THEN msg-%msg->if_message~get_text( )
                                      ELSE 'Unknown error' ).
        out->write( lv_text ).
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

    " 4. Read it back using the mapped RequestId
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

  ENDMETHOD.

ENDCLASS.
