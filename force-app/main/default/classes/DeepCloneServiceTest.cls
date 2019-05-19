@isTest
private with sharing class DeepCloneServiceTest {
    private static final String ACCOUNT_NAME = 'Universal Parts';
    private static final Integer NUMBER_OF_PARENTS = 1, NUMBER_OF_CHILDREN = 3;

    @TestSetup
    static void makeData(){
        List<Account> accts = TestDataFactory.createSobjectRecords(new Account(Name = ACCOUNT_NAME, Industry = 'Entertainment', AccountNumber = '12345', AnnualRevenue = 10000), NUMBER_OF_PARENTS);
        insert accts;
        List<Opportunity> opps = new List<Opportunity>();
        for(Account a : accts){
            opps.addAll((List<Opportunity>)TestDataFactory.createSobjectRecords(new Opportunity(AccountId = a.Id), NUMBER_OF_CHILDREN));
        }
        insert opps;

    }
    @isTest
    static void deepCloneTest(){
        DeepCloneSetting childSetting = new DeepCloneSetting();
        childSetting.sObjectName = 'Opportunity'; 
        childSetting.fields = new Set<String>{'Name', 'Amount','StageName','CloseDate'};
        childSetting.parentField = 'AccountId';
        DeepCloneSetting setting = new DeepCloneSetting();
        setting.sObjectName = 'Account';
        setting.fields = new Set<String>{'Industry','Name','AccountNumber'}; //do not clone revenue field
        setting.children = new List<DeepCloneSetting>{childSetting};
        List<Account> accounts = [SELECT Industry,Name,AccountNumber,AnnualRevenue, (SELECT Name, Amount, StageName, CloseDate FROM Opportunities) FROM Account];
        System.assert(accounts.size() == NUMBER_OF_PARENTS, 'Number of accounts not eqiaul to expected');
        System.assert(accounts[0].Opportunities.size() == NUMBER_OF_CHILDREN, 'Number of opportunities not eqiaul to expected');
        Test.startTest();
        Map<Id, Id> originalCloneMap = new Map<Id, Id>();
        originalCloneMap.put(accounts[0].Id, null);
        DeepCloneService.clone(setting, originalCloneMap);
        Test.stopTest();
        List<Account> resultAccounts = [SELECT Industry,Name,AccountNumber,AnnualRevenue, (SELECT Name, Amount, StageName, CloseDate FROM Opportunities) FROM Account];
        System.assertEquals(NUMBER_OF_PARENTS * 2, resultAccounts.size(), 'Number of accounts did not double');
        for(Account a : resultAccounts){
            System.assertEquals(NUMBER_OF_CHILDREN, a.Opportunities.size());
        }
        resultAccounts = [SELECT Industry,Name,AccountNumber,AnnualRevenue FROM Account WHERE Id <> :accounts[0].Id];
        System.assertEquals(accounts[0].Name, resultAccounts[0].Name);
        System.assertEquals(accounts[0].AccountNumber, resultAccounts[0].AccountNumber);
        System.assertEquals(accounts[0].Industry, resultAccounts[0].Industry);
        System.assertNotEquals(accounts[0].AnnualRevenue, resultAccounts[0].AnnualRevenue);
    }


    @isTest
    static void deepCloneNullTest(){
        List<Id> actual;
        Test.startTest();
        actual = DeepCloneService.clone(null, null);
        Test.stopTest();
        System.assertEquals(null, actual);
    }


    @isTest
    static void deepCloneQueryExceptionTest(){
        Boolean expected = true, exceptionOccured = false;

        DeepCloneSetting childSetting = new DeepCloneSetting();
        childSetting.sObjectName = 'Opportunity'; 
        childSetting.fields = new Set<String>{'Name', 'Amount','StageName','FakeField'};
        childSetting.parentField = 'AccountId';
        DeepCloneSetting setting = new DeepCloneSetting();
        setting.sObjectName = 'Account';
        setting.fields = new Set<String>{'Industry','Name','FakeField'}; //do not clone revenue field
        setting.children = new List<DeepCloneSetting>{childSetting};
        List<Account> accounts = [SELECT Industry,Name,AccountNumber,AnnualRevenue, (SELECT Name, Amount, StageName, CloseDate FROM Opportunities) FROM Account];
        Test.startTest();
        Map<Id, Id> originalCloneMap = new Map<Id, Id>();
        originalCloneMap.put(accounts[0].Id, null);
        try {
            DeepCloneService.clone(setting, originalCloneMap);
        } catch (System.QueryException e) {
            exceptionOccured = true;
        }
        Test.stopTest();
        System.assertEquals(expected, exceptionOccured);
    }
}
