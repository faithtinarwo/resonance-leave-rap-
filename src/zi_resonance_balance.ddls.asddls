@AccessControl.authorizationCheck: #CHECK
@EndUserText.label: 'Resonance Leave - Balance Interface'
define view entity ZI_RESONANCE_BALANCE
  as select from zrlv_bal
{
  key employee_id        as EmployeeId,
  key leave_type          as LeaveType,
  key leave_year           as LeaveYear,
      entitled_days         as EntitledDays,
      taken_days             as TakenDays,
      remaining_days         as RemainingDays,
      local_last_changed_at  as LocalLastChangedAt
}
