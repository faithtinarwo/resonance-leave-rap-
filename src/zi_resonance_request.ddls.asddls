@AccessControl.authorizationCheck: #CHECK
@EndUserText.label: 'Resonance Leave - Request Interface'
define root view entity ZI_RESONANCE_REQUEST
  as select from zrlv_req
  composition [0..*] of ZI_RESONANCE_ALLOC as _Allocations

  association [0..1] to ZI_RESONANCE_EMPLOYEE as _Employee
    on $projection.EmployeeId = _Employee.EmployeeId
  association [0..*] to ZI_RESONANCE_BALANCE   as _Balance
    on  $projection.EmployeeId = _Balance.EmployeeId
    and $projection.LeaveType  = _Balance.LeaveType
{
  key request_id           as RequestId,
      employee_id           as EmployeeId,
      leave_type             as LeaveType,
      start_date              as StartDate,
      end_date                as EndDate,
      days_requested           as DaysRequested,
      request_status            as RequestStatus,
      burnout_risk_score        as BurnoutRiskScore,

      case burnout_risk_score
        when 3 then 1
        when 2 then 2
        when 1 then 3
        else 0
      end                        as RiskCriticality,

      coverage_status            as CoverageStatus,
      local_created_by            as LocalCreatedBy,
      local_created_at            as LocalCreatedAt,
      local_last_changed_by       as LocalLastChangedBy,
      local_last_changed_at       as LocalLastChangedAt,

      // Associations
      _Allocations,
      _Employee,
      _Balance
}
