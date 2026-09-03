@EndUserText.label: 'Employee Risk Dashboard'
@Metadata.allowExtensions: true

@UI: {
  headerInfo: {
    typeName: 'Employee Risk',
    typeNamePlural: 'Employee Risk Overview',
    title: { type: #STANDARD, value: 'EmployeeName' }
  },
  chart: [
    {
      qualifier: 'RiskChart',
      chartType: #COLUMN,
      dimensions: [ 'RiskTier' ],
      measures: [ 'EmployeeCount' ]
    },
    {
      qualifier: 'DeptChart',
      chartType: #COLUMN,
      dimensions: [ 'Department', 'RiskTier' ],
      measures: [ 'EmployeeCount' ]
    }
  ],
  presentationVariant: [
    {
      qualifier: 'DefaultChart',
      visualizations: [ { type: #AS_CHART, qualifier: 'RiskChart' } ],
      groupBy: [ 'RiskTier' ]
    }
  ]
}

define root view entity ZC_RESONANCE_RISK_DASHBOARD
  as projection on ZI_RESONANCE_EMPLOYEE_RISK
{
      @UI.lineItem: [ { position: 10 } ]
      @UI.selectionField: [ { position: 10 } ]
  key EmployeeId,

      @UI.lineItem: [ { position: 20 } ]
      EmployeeName,

      @UI.lineItem: [ { position: 30 } ]
      @UI.selectionField: [ { position: 20 } ]
      Department,

      @UI.lineItem: [ { position: 40 } ]
      TeamSkillGroup,

      @UI.lineItem: [ { position: 50 } ]
      WorkloadPct,

      @UI.lineItem: [ { position: 60 } ]
      RemainingDays,

      @UI.lineItem: [ { position: 70, criticality: 'RiskCriticality' } ]
      @UI.selectionField: [ { position: 30 } ]
      RiskTier,

      @UI.hidden: true
      RiskCriticality,

      @DefaultAggregation: #SUM
      EmployeeCount
}
