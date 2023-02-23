Id fromUserId = '0054z000008Sl7x';
Id toUserId = '0054z00000Aby1J';

List<PermissionSetAssignment> fromPSAs = [
  SELECT 
    Id, 
    PermissionSetId, 
    IsActive, 
    ExpirationDate 
  FROM PermissionSetAssignment 
  WHERE AssigneeId = :fromUserId AND 
  PermissionSet.ProfileId = NULL
];

List<PermissionSetAssignment> newPSAs = new List<PermissionSetAssignment>();

for( PermissionSetAssignment psa : fromPSAs){
  PermissionSetAssignment ass = psa.clone(false,false,false,false);
  ass.AssigneeId = toUserId;
  newPSAs.add(ass);
}

insert newPSAs;






