class AminGetMapInfo extends Commandlet;

function int Main(string TextParameters) {

 local LevelInfo LevelInfo;
 LevelInfo = LevelInfo(DynamicLoadObject(TextParameters $ ".LevelInfo0", class 'LevelInfo'));

 Log("Information about" @ TextParameters $ ":");
 Log("Title:" @ LevelInfo.Title);
 Log("Author:" @ LevelInfo.Author);
 Log("BestCount:" @ LevelInfo.IdealPlayerCount);
 Log("EnterText:" @ LevelInfo.LevelEnterText);
 Log("DefGameType:" @ LevelInfo.DefaultGameType);
}
