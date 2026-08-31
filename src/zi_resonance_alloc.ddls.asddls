@AccessControl.authorizationCheck: #CHECK
@EndUserText.label: 'Resonance Leave - Allocation Interface'
define view entity ZI_RESONANCE_ALLOC
  as select from zrlv_alloc

  association to parent ZI_RESONANCE_REQUEST as _Request
    on $projection.RequestId = _Request.RequestId
{
  key alloc_id               as AllocId,
      request_id              as RequestId,
      covering_employee_id     as CoveringEmployeeId,
      alloc_status              as AllocStatus,
      local_created_at          as LocalCreatedAt,

      // Association
      _Request
}
