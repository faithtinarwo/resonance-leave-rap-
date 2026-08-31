@AccessControl.authorizationCheck: #CHECK
@EndUserText.label: 'Resonance Leave - Employee Interface'
define root view entity ZI_RESONANCE_EMPLOYEE
  as select from zrlv_emp
{
  key employee_id       as EmployeeId,
      employee_name      as EmployeeName,
      department         as Department,
      manager_id         as ManagerId,
      team_skill_group   as TeamSkillGroup,
      hire_date          as HireDate,
      local_created_by      as LocalCreatedBy,
      local_created_at      as LocalCreatedAt,
      local_last_changed_by as LocalLastChangedBy,
      local_last_changed_at as LocalLastChangedAt
}
