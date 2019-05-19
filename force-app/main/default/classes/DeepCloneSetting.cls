/*{
  "sObjectName": "Account",
  "fields": ["Name", "Industry","AccountNumber","AnnualRevenue"],
  "parentField": null,
  "children": [
      {
        "sObjectName": "Case",
        "fields": ["Status", "Subject","Type","Description","Priority","Origin","Reason"],
        "parentField": "AccountId",
        "children": []
      },
      {
        "sObjectName": "Opportunity",
        "fields": ["Name", "Amount","StageName","CloseDate"],
        "parentField": "AccountId",
        "children": [
            {
              "sObjectName": "OpportunityLineItem",
              "fields": ["Product2Id", "Quantity","UnitPrice","Description","ProductCode","PricebookEntryId"],
              "parentField": "OpportunityId",
              "children": []
            }
          ]
      }
    ]
}*/

global inherited sharing class DeepCloneSetting {
    public string sObjectName;
    public Set<String> fields;
    public String parentField;
    public List<DeepCloneSetting> children;
}

