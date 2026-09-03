@EndUserText.label: 'Resonance Leave Requests'
@Metadata.allowExtensions: true

@UI: {
  headerInfo: {
    typeName: 'Leave Request',
    typeNamePlural: 'Leave Requests',
    title: { type: #STANDARD, value: 'EmployeeId' }
  }
}

define root view entity ZC_RESONANCE_REQUEST
  as projection on ZI_RESONANCE_REQUEST
{
      @UI.lineItem: [ { position: 10 } ]
      @UI.selectionField: [ { position: 10 } ]
  key RequestId,

      @UI.lineItem: [ { position: 20 } ]
      @UI.selectionField: [ { position: 20 } ]
      EmployeeId,

      @UI.lineItem: [ { position: 30 } ]
      LeaveType,

      @UI.lineItem: [ { position: 40 } ]
      StartDate,

      @UI.lineItem: [ { position: 50 } ]
      EndDate,

      @UI.lineItem: [ { position: 60 } ]
      DaysRequested,

      @UI.lineItem: [ { position: 70 } ]
      @UI.selectionField: [ { position: 30 } ]
      RequestStatus,

      @UI.lineItem: [ { position: 80 } ]
      BurnoutRiskScore,

      @UI.hidden: true
      RiskCriticality,

      @UI.lineItem: [ { position: 90, criticality: 'RiskCriticality' } ]
      CoverageStatus,

      _Employee,
      _Allocations
}
