/**
*   
*/
public inherited sharing class DeepCloneService {

    /**
    * @description performs a deep clone of specified fields of a set of records along with their related child records
    * @param CloneSetting setting  Metadata which describes which object to clone and which child records to clone
    * @param Map<Id, Id> originalCloneMapping Map where the keys are the ids of the records to be cloned and the values
    *                    are the Ids of the corresponding cloned records
    * @ returns List<Id> Ids of the records that were cloned
    */
    public static List<Id> clone(DeepCloneSetting setting, Map<Id, Id> originalCloneMapping){
        if(originalCloneMapping == null || originalCloneMapping.size() == 0 || setting == null){
            return null;
        }
        //if the root use the id for the parent
        Set<Id> idsToClone = originalCloneMapping.keySet();
        String parentField = setting.parentField == null ? 'Id' : setting.parentField;
        if(!setting.fields.contains(parentField)){
            setting.fields.add(parentField);
        }
        //get records to clone from set
        List<String> fields = new List<String>();
        fields.addAll(setting.fields);
        List<SObject> recordsToClone = queryRecords(setting.sObjectName, fields, parentField, idsToClone);
        List<SObject> clones = new List<SObject>();
        Map<Id, Id> objectCloneMap = new Map<Id, Id>();
        if(recordsToClone.size() > 0){
            for(SObject record : recordsToClone){
                SObject clone = record.clone(false, true, false, false);
                if(setting.parentField != null && originalCloneMapping.containsKey((Id) record.get(setting.parentField))){
                    clone.put(setting.parentField, originalCloneMapping.get((Id) record.get(setting.parentField)));
                }
                clones.add(clone);
            }
            insert clones;
            Integer i = 0;
            for(SObject clone : clones){
                objectCloneMap.put((Id) recordsToClone[i].get('Id'), (Id) clone.get('Id'));
                ++i;
            }
            //free up some memory
            recordsToClone = null;
            clones = null;
            //clone children
            if(setting.children != null && setting.children.size() > 0){
                for(DeepCloneSetting childSetting : setting.children){
                    DeepCloneService.clone(childSetting, objectCloneMap);
                }
            }
        }
        return objectCloneMap.values();
    }

    /**
    * @description Query Records that are to be cloned
    *
    * @param String objectName The api name of the object to be cloned
    * @param List<String> fields The list of fields to be queried for cloning
    * @param String idField The Id or Refererence field's api name 
    * @param Set<Id> recordIds The Id of the records to be queried
    *
    * @returns List<SObject>
    * @throws System.QueryException
    */
    public static List<SObject> queryRecords(String objectName, List<String> fields, String idField, Set<Id> recordIds){
        String columns = String.join(fields, ',');
        String listTypeName = String.format('List<{0}>', new List<String>{objectName});
        List<SObject> objects = (List<SObject>) Type.forName(listTypeName).newInstance();
        objects = Database.query(String.format('SELECT {0} FROM {1} WHERE {2} IN :recordIds', new List<String>{columns, objectName, idField}));
        return objects;
    }
}
