TYPES: BEGIN OF ty_balance_update,
         employee_id TYPE zrlv_bal-employee_id,
         leave_type  TYPE zrlv_bal-leave_type,
         leave_year  TYPE zrlv_bal-leave_year,
         days        TYPE zrlv_bal-taken_days,
       END OF ty_balance_update.

CLASS lsc_saver DEFINITION INHERITING FROM cl_abap_behavior_saver.
  PUBLIC SECTION.
    CLASS-DATA gt_balance_updates TYPE STANDARD TABLE OF ty_balance_update WITH EMPTY KEY.

    CLASS-METHODS queue_balance_update
      IMPORTING iv_employee_id TYPE zrlv_bal-employee_id
                iv_leave_type  TYPE zrlv_bal-leave_type
                iv_leave_year  TYPE zrlv_bal-leave_year
                iv_days        TYPE zrlv_bal-taken_days.

  PROTECTED SECTION.
    METHODS save_modified REDEFINITION.
ENDCLASS.

CLASS lsc_saver IMPLEMENTATION.

  METHOD queue_balance_update.
    APPEND VALUE #( employee_id = iv_employee_id
                     leave_type  = iv_leave_type
                     leave_year  = iv_leave_year
                     days        = iv_days ) TO gt_balance_updates.
  ENDMETHOD.

  METHOD save_modified.
    LOOP AT gt_balance_updates INTO DATA(ls_upd).
      UPDATE zrlv_bal
        SET taken_days     = taken_days + @ls_upd-days,
            remaining_days = remaining_days - @ls_upd-days
        WHERE employee_id = @ls_upd-employee_id
          AND leave_type  = @ls_upd-leave_type
          AND leave_year  = @ls_upd-leave_year.
    ENDLOOP.
    CLEAR gt_balance_updates.
  ENDMETHOD.

ENDCLASS.

CLASS lhc_Request DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.
    METHODS setBurnoutRisk FOR DETERMINE ON SAVE
      IMPORTING keys FOR Request~setBurnoutRisk.

    METHODS validateDates FOR VALIDATE ON SAVE
      IMPORTING keys FOR Request~validateDates.

    METHODS submit FOR MODIFY
      IMPORTING keys FOR ACTION Request~submit RESULT result.

    METHODS get_instance_authorizations FOR INSTANCE AUTHORIZATION
      IMPORTING keys REQUEST requested_authorizations FOR Request RESULT result.
ENDCLASS.

CLASS lhc_Request IMPLEMENTATION.

    METHOD get_instance_authorizations.

    READ ENTITIES OF ZI_RESONANCE_REQUEST IN LOCAL MODE
      ENTITY Request
        FIELDS ( RequestStatus )
        WITH CORRESPONDING #( keys )
      RESULT DATA(requests).

    LOOP AT keys INTO DATA(ls_key).

      DATA lv_status TYPE zrlv_req-request_status.
      CLEAR lv_status.

      READ TABLE requests INTO DATA(ls_req)
        WITH KEY %tky-RequestId = ls_key-%tky-RequestId.
      IF sy-subrc = 0.
        lv_status = ls_req-RequestStatus.
      ENDIF.

      DATA lv_auth TYPE if_abap_behv=>t_char01.
      IF lv_status = 'D'.
        lv_auth = if_abap_behv=>auth-allowed.
      ELSE.
        lv_auth = if_abap_behv=>auth-unauthorized.
      ENDIF.

      APPEND VALUE #( %tky           = ls_key-%tky
                       %update        = lv_auth
                       %delete        = lv_auth
                       %action-submit = if_abap_behv=>auth-allowed
                     ) TO result.

    ENDLOOP.

  ENDMETHOD.

  METHOD setBurnoutRisk.

    READ ENTITIES OF ZI_RESONANCE_REQUEST IN LOCAL MODE
      ENTITY Request
        BY \_Employee
        FIELDS ( EmployeeId WorkloadPct )
        WITH CORRESPONDING #( keys )
      RESULT DATA(employees)
      FAILED DATA(failed_emp).

    READ ENTITIES OF ZI_RESONANCE_REQUEST IN LOCAL MODE
      ENTITY Request
        FIELDS ( EmployeeId LeaveType )
        WITH CORRESPONDING #( keys )
      RESULT DATA(requests).

    DATA: lv_workload TYPE zrlv_emp-workload_pct,
          lv_balance  TYPE zrlv_bal-remaining_days,
          lv_risk     TYPE zrlv_req-burnout_risk_score,
          lv_year     TYPE zrlv_bal-leave_year.

    lv_year = sy-datum(4).

    LOOP AT keys INTO DATA(ls_key).

      CLEAR: lv_workload, lv_balance.

      READ TABLE requests INTO DATA(ls_req)
        WITH KEY %tky-RequestId = ls_key-%tky-RequestId.

      IF sy-subrc = 0.

        READ TABLE employees INTO DATA(ls_emp)
          WITH KEY EmployeeId = ls_req-EmployeeId.
        IF sy-subrc = 0.
          lv_workload = ls_emp-WorkloadPct.
        ENDIF.

        SELECT SINGLE remaining_days
          FROM zrlv_bal
          WHERE employee_id = @ls_req-EmployeeId
            AND leave_type  = @ls_req-LeaveType
            AND leave_year  = @lv_year
          INTO @lv_balance.

        IF sy-subrc <> 0.
          lv_balance = 999.
        ENDIF.

      ENDIF.

      IF lv_workload > 80 AND lv_balance < 5.
        lv_risk = 3.
      ELSEIF lv_workload > 70 OR lv_balance < 10.
        lv_risk = 2.
      ELSE.
        lv_risk = 1.
      ENDIF.

      MODIFY ENTITIES OF ZI_RESONANCE_REQUEST IN LOCAL MODE
        ENTITY Request
          UPDATE FIELDS ( BurnoutRiskScore )
          WITH VALUE #( ( %tky = ls_key-%tky BurnoutRiskScore = lv_risk ) ).

    ENDLOOP.

  ENDMETHOD.

  METHOD submit.

    READ ENTITIES OF ZI_RESONANCE_REQUEST IN LOCAL MODE
      ENTITY Request
        FIELDS ( EmployeeId LeaveType RequestStatus DaysRequested )
        WITH CORRESPONDING #( keys )
      RESULT DATA(requests)
      FAILED DATA(failed_read).

    READ ENTITIES OF ZI_RESONANCE_REQUEST IN LOCAL MODE
      ENTITY Request
        BY \_Employee
        FIELDS ( EmployeeId TeamSkillGroup )
        WITH CORRESPONDING #( keys )
      RESULT DATA(employees)
      FAILED DATA(failed_emp).

    DATA lv_year TYPE zrlv_bal-leave_year.
    lv_year = sy-datum(4).

    DATA allocation_creates TYPE TABLE FOR CREATE ZI_RESONANCE_REQUEST\_Allocations.
    DATA status_updates      TYPE TABLE FOR UPDATE ZI_RESONANCE_REQUEST.

    LOOP AT keys INTO DATA(ls_key).

      READ TABLE requests INTO DATA(ls_req)
        WITH KEY %tky-RequestId = ls_key-%tky-RequestId.
      IF sy-subrc <> 0.
        CONTINUE.
      ENDIF.

      IF ls_req-RequestStatus <> 'D'.
        APPEND VALUE #( %tky = ls_key-%tky ) TO failed-request.
        CONTINUE.
      ENDIF.

      SELECT SINGLE remaining_days
        FROM zrlv_bal
        WHERE employee_id = @ls_req-EmployeeId
          AND leave_type  = @ls_req-LeaveType
          AND leave_year  = @lv_year
        INTO @DATA(lv_remaining).

      IF sy-subrc <> 0 OR lv_remaining < ls_req-DaysRequested.
        APPEND VALUE #( %tky = ls_key-%tky ) TO failed-request.
        CONTINUE.
      ENDIF.

      READ TABLE employees INTO DATA(ls_emp)
        WITH KEY EmployeeId = ls_req-EmployeeId.

      DATA lv_coverage_id TYPE zrlv_emp-employee_id.
      CLEAR lv_coverage_id.

      IF sy-subrc = 0.
        SELECT employee_id
          FROM zrlv_emp
          WHERE team_skill_group = @ls_emp-TeamSkillGroup
            AND employee_id     <> @ls_req-EmployeeId
            AND workload_pct     < 80
          ORDER BY workload_pct ASCENDING
          INTO TABLE @DATA(lt_candidates)
          UP TO 1 ROWS.

        IF lines( lt_candidates ) > 0.
          lv_coverage_id = lt_candidates[ 1 ].
        ENDIF.
      ENDIF.

      DATA lv_coverage_status TYPE zrlv_req-coverage_status.

      IF lv_coverage_id IS NOT INITIAL.
        lv_coverage_status = 'F'.
        APPEND VALUE #( %tky            = ls_key-%tky
                         %target         = VALUE #( (
                           %cid                 = cl_system_uuid=>create_uuid_x16_static( )
                           CoveringEmployeeId    = lv_coverage_id
                           AllocStatus            = 'P'
                         ) )
                       ) TO allocation_creates.
      ELSE.
        lv_coverage_status = 'U'.
      ENDIF.

      " DB write deferred to save phase (native SQL not allowed here)
      lsc_saver=>queue_balance_update(
        iv_employee_id = ls_req-EmployeeId
        iv_leave_type  = ls_req-LeaveType
        iv_leave_year  = lv_year
        iv_days        = ls_req-DaysRequested ).

      APPEND VALUE #( %tky           = ls_key-%tky
                       RequestStatus  = 'S'
                       CoverageStatus = lv_coverage_status
                     ) TO status_updates.

    ENDLOOP.

    IF allocation_creates IS NOT INITIAL.
      MODIFY ENTITIES OF ZI_RESONANCE_REQUEST IN LOCAL MODE
        ENTITY Request
          CREATE BY \_Allocations
          FIELDS ( CoveringEmployeeId AllocStatus )
          WITH allocation_creates.
    ENDIF.

    IF status_updates IS NOT INITIAL.
      MODIFY ENTITIES OF ZI_RESONANCE_REQUEST IN LOCAL MODE
        ENTITY Request
          UPDATE FIELDS ( RequestStatus CoverageStatus )
          WITH status_updates.
    ENDIF.

    READ ENTITIES OF ZI_RESONANCE_REQUEST IN LOCAL MODE
      ENTITY Request
        ALL FIELDS
        WITH CORRESPONDING #( keys )
      RESULT DATA(final_requests).

    result = VALUE #( FOR r IN final_requests ( %tky = r-%tky %param = r ) ).

  ENDMETHOD.

    METHOD validateDates.

    READ ENTITIES OF ZI_RESONANCE_REQUEST IN LOCAL MODE
      ENTITY Request
        FIELDS ( StartDate EndDate DaysRequested )
        WITH CORRESPONDING #( keys )
      RESULT DATA(requests).

    LOOP AT requests INTO DATA(ls_req).

      IF ls_req-StartDate > ls_req-EndDate.
        APPEND VALUE #( %tky = ls_req-%tky ) TO failed-request.
        APPEND VALUE #( %tky = ls_req-%tky
                         %msg = new_message_with_text(
                                  severity = if_abap_behv_message=>severity-error
                                  text     = 'Start date must be before end date' )
                       ) TO reported-request.
      ENDIF.

      IF ls_req-DaysRequested <= 0.
        APPEND VALUE #( %tky = ls_req-%tky ) TO failed-request.
        APPEND VALUE #( %tky = ls_req-%tky
                         %msg = new_message_with_text(
                                  severity = if_abap_behv_message=>severity-error
                                  text     = 'Days requested must be greater than zero' )
                       ) TO reported-request.
      ENDIF.

    ENDLOOP.

  ENDMETHOD.

ENDCLASS.
