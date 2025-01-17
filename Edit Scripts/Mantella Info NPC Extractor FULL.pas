{
  update of pascal script, which allows to obtain useful information 
  for people who want to have relevant npc data at hand to use in 
  spid or mantella.
  
  Author: JOHN95AC  https://next.nexusmods.com/profile/John1995ac
}
unit UserScript;

var
  LastSignature: string; // Variable para almacenar el último tipo de registro
  NPCCount: integer;      // Variable para contar los NPC procesados

// Función para obtener el tipo de voz del NPC
function GetVoiceType(e: IInterface): string;
var
  VoiceTypeElement: IInterface;
begin
  VoiceTypeElement := ElementByPath(e, 'VTCK');
  if Assigned(VoiceTypeElement) then
    Result := GetEditValue(VoiceTypeElement)
  else
    Result := 'No Voice Type Found';
end;

// Función para obtener el género del NPC
function GetNPCGender(e: IInterface): string;
var
  FlagsElement: IInterface;
  GenderFlag: Integer;
begin
  FlagsElement := ElementByPath(e, 'ACBS\Flags');
  if Assigned(FlagsElement) then
  begin
    GenderFlag := GetNativeValue(FlagsElement);
    if (GenderFlag and 1) = 1 then
      Result := 'Female'
    else
      Result := 'Male';
  end
  else
    Result := 'Gender Not Found';
end;

// Función para obtener la raza del NPC
function GetRace(e: IInterface): string;
var
  RaceElement: IInterface;
begin
  RaceElement := ElementByPath(e, 'RNAM');
  if Assigned(RaceElement) then
    Result := GetEditValue(RaceElement)
  else
    Result := 'No Race Found';
end;

// Función para obtener la clase del NPC
function GetClass(e: IInterface): string;
var
  ClassElement: IInterface;
begin
  ClassElement := ElementByPath(e, 'CNAM');
  if Assigned(ClassElement) then
    Result := GetEditValue(ClassElement)
  else
    Result := 'No Class Found';
end;

// Función para obtener las facciones del NPC
function GetFactions(e: IInterface): string;
var
  FactionsElement, FactionEntry: IInterface;
  i, Rank: Integer;
  FactionData: string;
begin
  FactionsElement := ElementByPath(e, 'SNAM');
  if Assigned(FactionsElement) then
  begin
    FactionData := '';
    for i := 0 to ElementCount(FactionsElement) - 1 do
    begin
      FactionEntry := ElementByIndex(FactionsElement, i);
      Rank := GetNativeValue(ElementByPath(FactionEntry, 'Rank'));
      FactionData := FactionData + GetEditValue(ElementByIndex(FactionEntry, 0)) + ' {Rank: ' + IntToStr(Rank) + '}' + #13#10;
    end;
    Result := Trim(FactionData);
  end
  else
    Result := 'No Factions Found';
end;

// Función para obtener las palabras clave del NPC
function GetKeywords(e: IInterface): string;
var
  KeywordsElement, KeywordEntry: IInterface;
  i: Integer;
  KeywordsData: string;
begin
  KeywordsElement := ElementByPath(e, 'KWDA');
  if Assigned(KeywordsElement) then
  begin
    KeywordsData := '';
    for i := 0 to ElementCount(KeywordsElement) - 1 do
    begin
      KeywordEntry := ElementByIndex(KeywordsElement, i);
      KeywordsData := KeywordsData + GetEditValue(KeywordEntry) + #13#10;
    end;
    Result := Trim(KeywordsData);
  end
  else
    Result := 'No Keywords Found';
end;

// Función para verificar si el NPC es invulnerable
function IsNPCInvulnerable(e: IInterface): Boolean;
var
  FlagsElement: IInterface;
  InvulnerableFlag: Integer;
begin
  FlagsElement := ElementByPath(e, 'ACBS\Flags');
  if Assigned(FlagsElement) then
  begin
    InvulnerableFlag := GetNativeValue(FlagsElement);
    Result := (InvulnerableFlag and 4) = 4; // La bandera de invulnerabilidad es 4
  end
  else
    Result := False;
end;

// Función principal para procesar registros NPC
function Process(e: IInterface): integer;
var
  Signature, FormID, EditorID, Name, VoiceType, Gender, Race, ClassData, Factions, Keywords: string;
begin
  Signature := GetElementEditValues(e, 'Record Header\Signature');

  // Solo procesar registros de tipo NPC_
  if Signature = 'NPC_' then
  begin
    // Verificar si el NPC es invulnerable
    if IsNPCInvulnerable(e) then
    begin
      // Omitir el procesamiento de este NPC
      AddMessage('Skipping invulnerable NPC: ' + GetEditValue(ElementByPath(e, 'FULL - Name')));
      Result := 0; // Salir sin procesar este NPC
      Exit;
    end;

    FormID := GetEditValue(ElementByPath(e, 'Record Header\FormID'));
    EditorID := GetEditValue(ElementByPath(e, 'EDID - Editor ID'));
    Name := GetEditValue(ElementByPath(e, 'FULL - Name'));
    VoiceType := GetVoiceType(e);
    Gender := GetNPCGender(e);
    Race := GetRace(e);
    ClassData := GetClass(e);
    Factions := GetFactions(e);
    Keywords := GetKeywords(e);

    // Si el tipo de registro ha cambiado, mostrar un nuevo encabezado
    if Signature <> LastSignature then
    begin
      if LastSignature <> '' then
        AddMessage('----------------------------------------------------------------------------------------------------------------');
      AddMessage('----------------------------------------------------------------------------------------------------------------');
      AddMessage('');  
    end;

    // Mostrar valores específicos del registro
    AddMessage('FormID: ' + FormID);
    AddMessage('EditorID: ' + EditorID);
    AddMessage('Name: ' + Name);
    AddMessage('Voice Type: ' + VoiceType);
    AddMessage('Gender: ' + Gender);
    AddMessage('Race: ' + Race);
    AddMessage('Class: ' + ClassData);

    // Mostrar las facciones con el indicador V
    AddMessage('Factions:  V');
    if Factions <> '' then
      AddMessage(Factions);

    // Mostrar las palabras clave con el indicador V
    AddMessage('Keywords:  V');
    if Keywords <> '' then
      AddMessage(Keywords);

    AddMessage('----------------------------------------------------------------------------------------------------------------');
    AddMessage('----------------------------------------------------------------------------------------------------------------');
    AddMessage('');

    // Contar los NPC procesados
    NPCCount := NPCCount + 1;

    LastSignature := Signature;
  end;

  Result := 0;
end;

// Función para finalizar el procesamiento
function Finalize: integer;
begin
  // Mostrar la cantidad de NPC procesados
  AddMessage('Total NPCs processed : ' + IntToStr(NPCCount));
  LastSignature := '';
  Result := 0;
end;

end.
