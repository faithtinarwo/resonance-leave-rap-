@AccessControl.authorizationCheck: #CHECK
@EndUserText.label: 'Resonance Leave - Live Employee Risk'
define root view entity ZI_RESONANCE_EMPLOYEE_RISK
  as select from zrlv_emp as emp
  left outer join zrlv_bal as bal
    on  emp.employee_id = bal.employee_id
    and bal.leave_type  = 'ANNL'
{
  key emp.employee_id                              as EmployeeId,
      emp.employee_name                            as EmployeeName,
      emp.department                                as Department,
      emp.team_skill_group                          as TeamSkillGroup,
      emp.workload_pct                              as WorkloadPct,
      coalesce( bal.remaining_days, cast( 999 as abap.dec( 5, 1 ) ) )  as RemainingDays,

      case
        when emp.workload_pct > 80
         and coalesce( bal.remaining_days, cast( 999 as abap.dec( 5, 1 ) ) ) < 5
        then 'CRITICAL'
        when emp.workload_pct > 70
          or coalesce( bal.remaining_days, cast( 999 as abap.dec( 5, 1 ) ) ) < 10
        then 'ELEVATED'
        else 'STABLE'
      end                                            as RiskTier,

      case
        when emp.workload_pct > 80
         and coalesce( bal.remaining_days, cast( 999 as abap.dec( 5, 1 ) ) ) < 5
        then cast( 1 as abap.int4 )
        when emp.workload_pct > 70
          or coalesce( bal.remaining_days, cast( 999 as abap.dec( 5, 1 ) ) ) < 10
        then cast( 2 as abap.int4 )
        else cast( 3 as abap.int4 )
      end                                            as RiskCriticality,

      cast( 1 as abap.int4 )                          as EmployeeCount
}
