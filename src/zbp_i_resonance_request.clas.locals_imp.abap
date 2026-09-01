CLASS lhc_Request DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.
    METHODS setBurnoutRisk FOR DETERMINE ON SAVE
      IMPORTING keys FOR Request~setBurnoutRisk.
ENDCLASS.

CLASS lhc_Request IMPLEMENTATION.

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

      " Get this request's own EmployeeId / LeaveType first
      READ TABLE requests INTO DATA(ls_req)
        WITH KEY %tky-RequestId = ls_key-%tky-RequestId.

      IF sy-subrc = 0.

        " Match workload by EmployeeId, not RequestId
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

ENDCLASS.
