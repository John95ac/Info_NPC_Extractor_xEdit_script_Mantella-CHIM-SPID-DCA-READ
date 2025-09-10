{
  Gets detailed NPC information from ESP/ESM files for Mantella/SPID/CHIM/OPDC/READ integration
  Combines functionality of John95AC scripts with structured INI output
  Modifications:
  - Generates INI file with sections for each NPC including basic info, character details, factions, keywords
  - Includes read-only invulnerability detection (no modifications)
  - Displays cute cat ASCII art at the end
  - Saves to ScriptsPath + NPC_info_report folder with plugin name in filename
  
  Author: Based on JOHN95AC with improvements and kitties
}

unit UserScript;

uses
  SysUtils, Classes, Contnrs;

var
  NPCCount: integer;
  InvulnRemovedCount: integer;
  InvulnerableCount: integer; // read-only count of invulnerable NPC bases God help
  LastSignature: string;
  OriginallyInvulnerableNPCs: TStringList;
  HasInvulnerableNPCs: boolean;
  OutIni: TStringList;
  PluginName: string;
  SeenNPCs: TStringList; // to avoid duplicate NPC_ outputs

// ================================================================
// INITIALIZATION
// ================================================================

function Initialize: integer;
begin
  OriginallyInvulnerableNPCs := TStringList.Create;
  OriginallyInvulnerableNPCs.Sorted := True;
  OriginallyInvulnerableNPCs.Duplicates := dupIgnore;
  NPCCount := 0;
  InvulnRemovedCount := 0;
  InvulnerableCount := 0;
  HasInvulnerableNPCs := False;
  OutIni := TStringList.Create;
  SeenNPCs := TStringList.Create;
  SeenNPCs.Sorted := True;
  SeenNPCs.Duplicates := dupIgnore;
  Result := 0;
end;

// ================================================================
// INVULNERABILITY HANDLING FUNCTIONS
// ================================================================

function IsOriginallyInvulnerable(e: IInterface): boolean;
var
  InvulnPath: string;
  val: string;
begin
  InvulnPath := 'ACBS\Flags\Invulnerable';
  if ElementExists(e, InvulnPath) then
  begin
    Result := GetElementEditValues(e, InvulnPath) = '1';
    Exit;
  end;

  // Safe textual fallback: check flags string contains 'Invulnerable'
  val := GetElementEditValues(e, 'ACBS\Flags');
  Result := Pos('Invulnerable', val) > 0;
end;

function GetLocationForRef(achr: IInterface): string;
var
  cellRec, wsRec, elem: IInterface;
  cellName, cellEdid, wsName, wsEdid, a, b: string;
const
  locFmt = '%s (%s)';
begin
  Result := '';
  cellRec := nil;
  elem := ElementByPath(achr, 'Cell');
  if Assigned(elem) then
    cellRec := WinningOverride(LinksTo(elem));
  if Assigned(cellRec) then
  begin
    elem := ElementByPath(cellRec, 'FULL - Name');
    if not Assigned(elem) then elem := ElementByPath(cellRec, 'FULL');
    if Assigned(elem) then cellName := Trim(GetEditValue(elem)) else cellName := '';
    elem := ElementByPath(cellRec, 'EDID - Editor ID');
    if not Assigned(elem) then elem := ElementByPath(cellRec, 'EDID');
    if Assigned(elem) then cellEdid := Trim(GetEditValue(elem)) else cellEdid := '';
    // worldspace
    wsRec := nil;
    elem := ElementByPath(cellRec, 'XCLC\\Worldspace');
    if Assigned(elem) then wsRec := WinningOverride(LinksTo(elem));
    if (cellName <> '') or (cellEdid <> '') then
    begin
      if cellName <> '' then a := cellName else a := cellEdid;
      if cellEdid <> '' then b := cellEdid else b := cellName;
      Result := Format(locFmt, [a, b]);
    end
    else if Assigned(wsRec) then
    begin
      elem := ElementByPath(wsRec, 'FULL - Name');
      if not Assigned(elem) then elem := ElementByPath(wsRec, 'FULL');
      if Assigned(elem) then wsName := Trim(GetEditValue(elem)) else wsName := '';
      elem := ElementByPath(wsRec, 'EDID - Editor ID');
      if not Assigned(elem) then elem := ElementByPath(wsRec, 'EDID');
      if Assigned(elem) then wsEdid := Trim(GetEditValue(elem)) else wsEdid := '';
      if (wsName <> '') or (wsEdid <> '') then
      begin
        if wsName <> '' then a := wsName else a := wsEdid;
        if wsEdid <> '' then b := wsEdid else b := wsName;
        Result := Format(locFmt, [a, b]);
      end;
    end;
  end;
  if Result = '' then Result := 'Unknown (Unknown)';
end;

procedure RemoveInvulnerability(e: IInterface; FormID: string);
var
  FlagsElement: IInterface;
  InvulnPath: string;
begin
  if IsOriginallyInvulnerable(e) then
  begin
    OriginallyInvulnerableNPCs.Add(FormID);
    Inc(InvulnRemovedCount);
    HasInvulnerableNPCs := True;
  end;

  InvulnPath := 'ACBS\Flags\Invulnerable';
  if ElementExists(e, InvulnPath) then
  begin
    SetElementEditValues(e, InvulnPath, '0');
    Exit;
  end;

  FlagsElement := ElementByPath(e, 'ACBS\Flags');
  if Assigned(FlagsElement) then
    SetNativeValue(FlagsElement, GetNativeValue(FlagsElement) and not 4);
end;

procedure RestoreInvulnerability(e: IInterface; FormID: string);
var
  FlagsElement: IInterface;
  InvulnPath: string;
begin
  if OriginallyInvulnerableNPCs.IndexOf(FormID) >= 0 then
  begin
    InvulnPath := 'ACBS\Flags\Invulnerable';
    if ElementExists(e, InvulnPath) then
    begin
      SetElementEditValues(e, InvulnPath, '1');
      Exit;
    end;

    FlagsElement := ElementByPath(e, 'ACBS\Flags');
    if Assigned(FlagsElement) then
      SetNativeValue(FlagsElement, GetNativeValue(FlagsElement) or 4);
  end;
end;

// ================================================================
// INFORMATION EXTRACTION FUNCTIONS
// ================================================================

// Helper: check if character is hexadecimal
function IsHexChar(ch: Char): boolean;
begin
  ch := UpCase(ch);
  Result := (ch >= '0') and (ch <= '9') or (ch >= 'A') and (ch <= 'F');
end;

// Helper: extract the last 8 hex characters found when scanning from the end of a string
function ExtractLastHex8(const s: string): string;
var
  i, count: Integer;
  buf: string;
begin
  buf := '';
  count := 0;
  for i := Length(s) downto 1 do
  begin
    if IsHexChar(s[i]) then
    begin
      buf := s[i] + buf;
      Inc(count);
      if count = 8 then
        Break;
    end
    else if count > 0 then
      Break;
  end;
  if Length(buf) = 8 then
    Result := UpperCase(buf)
  else
    Result := '';
end;

// Helper: convert any 8-hex FormID to XX + last 6
function FormatFormIdToXX(const s: string): string;
var
  hex8: string;
begin
  hex8 := ExtractLastHex8(s);
  if hex8 <> '' then
    Result := 'XX' + Copy(hex8, 3, 6)
  else
    Result := s; // fallback
end;

// Helper: replace bracketed IDs like [TYPE:XXXXXXXX] -> [TYPE:XX######]
function TransformBracketedIds(const s: string): string;
var
  i, j, k, colonPos: Integer;
  inside, before, bracket, idPart, hexOnly, hex8: string;
begin
  Result := s;
  i := 1;
  while i <= Length(Result) do
  begin
    if Result[i] = '[' then
    begin
      j := i + 1;
      while (j <= Length(Result)) and (Result[j] <> ']') do
        Inc(j);
      if (j <= Length(Result)) and (Result[j] = ']') then
      begin
        inside := Copy(Result, i + 1, j - i - 1);
        colonPos := Pos(':', inside);
        if colonPos > 0 then
        begin
          before := Copy(inside, 1, colonPos);
          idPart := Copy(inside, colonPos + 1, MaxInt);
          // keep only hex chars
          hexOnly := '';
          for k := 1 to Length(idPart) do
            if IsHexChar(idPart[k]) then
              hexOnly := hexOnly + UpCase(idPart[k]);
          if Length(hexOnly) >= 8 then
          begin
            hex8 := Copy(hexOnly, Length(hexOnly) - 7, 8);
            bracket := '[' + before + 'XX' + Copy(hex8, 3, 6) + ']';
            Result := Copy(Result, 1, i - 1) + bracket + Copy(Result, j + 1, MaxInt);
            i := i + Length(bracket);
            Continue;
          end;
        end;
      end;
    end;
    Inc(i);
  end;
end;

function GetVoiceType(e: IInterface): string;
var
  VoiceTypeElement: IInterface;
begin
  VoiceTypeElement := ElementByPath(e, 'VTCK');
  if Assigned(VoiceTypeElement) then
    Result := GetEditValue(VoiceTypeElement)
  else
    Result := 'No Voice Type';
end;

function GetNPCGender(e: IInterface): string;
var
  femalePath: string;
  val: string;
begin
  // Prefer explicit flag element when available to avoid type issues
  femalePath := 'ACBS\Flags\Female';
  if ElementExists(e, femalePath) then
  begin
    val := GetElementEditValues(e, femalePath);
    if val = '1' then
      Result := 'Female'
    else
      Result := 'Male';
    Exit;
  end;

  // Fallback: try reading the combined flags as text and parse safely
  val := GetElementEditValues(e, 'ACBS\Flags');
  if val <> '' then
  begin
    // Many xEdit builds expose a textual flags list; check for 'Female' token
    if Pos('Female', val) > 0 then
      Result := 'Female'
    else
      Result := 'Male';
  end
  else
    Result := 'Unknown';
end;

function GetRace(e: IInterface): string;
var
  RaceElement: IInterface;
begin
  RaceElement := ElementByPath(e, 'RNAM');
  if Assigned(RaceElement) then
    Result := GetEditValue(RaceElement)
  else
    Result := 'No Race';
end;

function GetClass(e: IInterface): string;
var
  ClassElement: IInterface;
begin
  ClassElement := ElementByPath(e, 'CNAM');
  if Assigned(ClassElement) then
    Result := GetEditValue(ClassElement)
  else
    Result := 'No Class';
end;

function GetFactions(e: IInterface): string;
var
  FactionsElement, FactionEntry: IInterface;
  i, Rank: Integer;
  FactionData: TStringList;
begin
  FactionsElement := ElementByPath(e, 'SNAM');
  FactionData := TStringList.Create;
  try
    if Assigned(FactionsElement) then
    begin
      for i := 0 to ElementCount(FactionsElement) - 1 do
      begin
        FactionEntry := ElementByIndex(FactionsElement, i);
        Rank := GetNativeValue(ElementByPath(FactionEntry, 'Rank'));
        FactionData.Add(Format('    %s (Rank: %d)', [
          GetEditValue(ElementByIndex(FactionEntry, 0)), 
          Rank
        ]));
      end;
    end;
    
    if FactionData.Count > 0 then
      Result := TransformBracketedIds(FactionData.Text)
    else
      Result := '    No factions';
  finally
    FactionData.Free;
  end;
end;

function GetKeywords(e: IInterface): string;
var
  KeywordsElement, KeywordEntry: IInterface;
  i: Integer;
  KeywordData: TStringList;
begin
  KeywordsElement := ElementByPath(e, 'KWDA');
  KeywordData := TStringList.Create;
  try
    if Assigned(KeywordsElement) then
    begin
      for i := 0 to ElementCount(KeywordsElement) - 1 do
      begin
        KeywordEntry := ElementByIndex(KeywordsElement, i);
        KeywordData.Add('    ' + TransformBracketedIds(GetEditValue(KeywordEntry)));
      end;
    end;
    
    if KeywordData.Count > 0 then
      Result := KeywordData.Text
    else
      Result := '    No keywords';
  finally
    KeywordData.Free;
  end;
end;

// ================================================================
// MAIN PROCESSING FUNCTION
// ================================================================

function Process(e: IInterface): integer;
var
  Signature, FormID, EditorID, Name, VoiceType, Gender, Race, ClassData, Factions, Keywords: string;
  LocationField: string;
  sec: string;
  tmp: TStringList;
  i, k: Integer;
  baseRec: IInterface;
begin
  Signature := GetElementEditValues(e, 'Record Header\Signature');

  if Signature = 'NPC_' then
  begin
    FormID := GetEditValue(ElementByPath(e, 'Record Header\FormID'));
    // Keep plugin name for INI naming (first time only)
    if PluginName = '' then
      PluginName := ChangeFileExt(GetFileName(GetFile(e)), '');

    // Deduplicate base NPCs by normalized FormID (shared key with ACHR branch)
    if SeenNPCs.IndexOf('BASE|' + FormatFormIdToXX(FormID)) >= 0 then
    begin
      Result := 0;
      Exit;
    end;
    SeenNPCs.Add('BASE|' + FormatFormIdToXX(FormID));
    // Read-only count of invulnerable bases
    if IsOriginallyInvulnerable(e) then
      Inc(InvulnerableCount);

    // Step 2: Extract NPC information
    EditorID := GetEditValue(ElementByPath(e, 'EDID - Editor ID'));
    Name := GetEditValue(ElementByPath(e, 'FULL - Name'));
    VoiceType := GetVoiceType(e);
    Gender := GetNPCGender(e);
    Race := TransformBracketedIds(GetRace(e));
    ClassData := TransformBracketedIds(GetClass(e));
    Factions := GetFactions(e);
    Keywords := GetKeywords(e);
    LocationField := 'Unknown (Unknown)';   

    // Display organized information
    if Signature <> LastSignature then
    begin
      AddMessage('===================================================');
      AddMessage('               NPC PROCESSING REPORT               ');
      AddMessage('===================================================');
      AddMessage('');
    end;

    AddMessage(Format('NPC #%d: %s', [NPCCount + 1, Name]));
    AddMessage('---------------------------------------------------');
    AddMessage('BASIC INFORMATION:');
    AddMessage(Format('  FormID:    %s', [FormatFormIdToXX(FormID)]));
    AddMessage(Format('  EditorID:  %s', [EditorID]));
    AddMessage(Format('  Gender:    %s', [Gender]));
    
    AddMessage('CHARACTER DETAILS:');
    AddMessage(Format('  Location:  %s', [LocationField]));
    AddMessage(Format('  Race:      %s', [Race]));
    AddMessage(Format('  Class:     %s', [ClassData]));
    AddMessage(Format('  Voice:     %s', [VoiceType]));
    
    AddMessage('FACTIONS:');
    AddMessage(Factions);
    
    AddMessage('KEYWORDS:');
    AddMessage(Keywords);
    
    AddMessage('---------------------------------------------------');
    AddMessage('');

    // Write to INI per NPC section with requested structure
    // Ensure exactly one blank line BEFORE each new [NPC_*] section, except the first
    if NPCCount > 0 then
      OutIni.Add('');
    sec := Format('NPC_%d', [NPCCount + 1]);
    OutIni.Add(Format('[%s = %s]', [sec, Name]));
    OutIni.Add('BASIC INFORMATION:');
    OutIni.Add(Format('  Name=%s', [Name]));
    OutIni.Add(Format('  FormIDXX=%s', [FormatFormIdToXX(FormID)]));
    OutIni.Add(Format('  EditorID=%s', [EditorID]));
    OutIni.Add(Format('  Gender=%s', [Gender]));
    OutIni.Add('');
    OutIni.Add('CHARACTER DETAILS:');
    OutIni.Add(Format('  Location=%s', [LocationField]));
    OutIni.Add(Format('  Race=%s', [Race]));
    OutIni.Add(Format('  Class=%s', [ClassData]));
    OutIni.Add(Format('  Voice=%s', [VoiceType]));
    OutIni.Add('');
    OutIni.Add('FACTIONS:');
    tmp := TStringList.Create;
    try
      tmp.Text := Factions;
      // remove possible header like '    No factions'
      if (tmp.Count = 1) and (Pos('No faction', LowerCase(Trim(tmp[0]))) > 0) then
        tmp.Clear;
      for i := 0 to tmp.Count - 1 do
        OutIni.Add(Format('  Faction%d=%s', [i + 1, Trim(tmp[i])]))
    finally
      tmp.Free;
    end;
    OutIni.Add('');
    OutIni.Add('KEYWORDS:');
    tmp := TStringList.Create;
    try
      tmp.Text := Keywords;
      if (tmp.Count = 1) and (Pos('No keyword', LowerCase(Trim(tmp[0]))) > 0) then
        tmp.Clear;
      if tmp.Count = 0 then
        OutIni.Add('  Keyword1=No keywords')
      else
        for k := 0 to tmp.Count - 1 do
          OutIni.Add(Format('  Keyword%d=%s', [k + 1, Trim(tmp[k])]))
    finally
      tmp.Free;
    end;
    // no trailing blank line here; spacing handled before next header
    
    // No invulnerability toggling to avoid freezes

    Inc(NPCCount);
    LastSignature := Signature;
  end
  else if Signature = 'ACHR' then
  begin
    // Resolve base NPC
    baseRec := nil;
    if Assigned(ElementByPath(e, 'NAME - Base')) then
      baseRec := WinningOverride(LinksTo(ElementByPath(e, 'NAME - Base')));

    if Assigned(baseRec) then
    begin
      FormID := GetEditValue(ElementByPath(baseRec, 'Record Header\FormID'));
      // Skip if this base NPC was already printed by NPC_ branch or another ACHR of same base
      if SeenNPCs.IndexOf('BASE|' + FormatFormIdToXX(FormID)) >= 0 then
      begin
        Result := 0;
        Exit;
      end;
      SeenNPCs.Add('BASE|' + FormatFormIdToXX(FormID));
      // Read-only count on the base record
      if IsOriginallyInvulnerable(baseRec) then
        Inc(InvulnerableCount);
      EditorID := GetEditValue(ElementByPath(baseRec, 'EDID - Editor ID'));
      Name := GetEditValue(ElementByPath(baseRec, 'FULL - Name'));
      VoiceType := GetVoiceType(baseRec);
      Gender := GetNPCGender(baseRec);
      Race := TransformBracketedIds(GetRace(baseRec));
      ClassData := TransformBracketedIds(GetClass(baseRec));
      Factions := GetFactions(baseRec);
      Keywords := GetKeywords(baseRec);
    end
    else
    begin
      FormID := GetEditValue(ElementByPath(e, 'Record Header\FormID'));
      EditorID := '';
      Name := '';
      VoiceType := '';
      Gender := '';
      Race := '';
      ClassData := '';
      Factions := '';
      Keywords := '';
    end;

    LocationField := GetLocationForRef(e);

    if Signature <> LastSignature then
    begin
      AddMessage('===================================================');
      AddMessage('               NPC PROCESSING REPORT               ');
      AddMessage('===================================================');
      AddMessage('');
    end;

    AddMessage(Format('NPC #%d: %s', [NPCCount + 1, Name]));
    AddMessage('---------------------------------------------------');
    AddMessage('BASIC INFORMATION:');
    AddMessage(Format('  FormID:    %s', [FormatFormIdToXX(FormID)]));
    AddMessage(Format('  EditorID:  %s', [EditorID]));
    AddMessage(Format('  Gender:    %s', [Gender]));

    AddMessage('CHARACTER DETAILS:');
    AddMessage(Format('  Location:  %s', [LocationField]));
    AddMessage(Format('  Race:      %s', [Race]));
    AddMessage(Format('  Class:     %s', [ClassData]));
    AddMessage(Format('  Voice:     %s', [VoiceType]));

    AddMessage('FACTIONS:');
    AddMessage(Factions);

    AddMessage('KEYWORDS:');
    AddMessage(Keywords);

    AddMessage('---------------------------------------------------');
    AddMessage('');

    // INI section with requested structure
    // Ensure exactly one blank line BEFORE each new [NPC_*] section, except the first
    if NPCCount > 0 then
      OutIni.Add('');
    sec := Format('NPC_%d', [NPCCount + 1]);
    OutIni.Add(Format('[%s = %s]', [sec, Name]));
    OutIni.Add('BASIC INFORMATION:');
    OutIni.Add(Format('  Name=%s', [Name]));
    OutIni.Add(Format('  FormIDXX=%s', [FormatFormIdToXX(FormID)]));
    OutIni.Add(Format('  EditorID=%s', [EditorID]));
    OutIni.Add(Format('  Gender=%s', [Gender]));
    OutIni.Add('');
    OutIni.Add('CHARACTER DETAILS:');
    OutIni.Add(Format('  Location=%s', [LocationField]));
    OutIni.Add(Format('  Race=%s', [Race]));
    OutIni.Add(Format('  Class=%s', [ClassData]));
    OutIni.Add(Format('  Voice=%s', [VoiceType]));
    OutIni.Add('');
    OutIni.Add('FACTIONS:');
    tmp := TStringList.Create;
    try
      tmp.Text := Factions;
      if (tmp.Count = 1) and (Pos('No faction', LowerCase(Trim(tmp[0]))) > 0) then
        tmp.Clear;
      for i := 0 to tmp.Count - 1 do
        OutIni.Add(Format('  Faction%d=%s', [i + 1, Trim(tmp[i])]))
    finally
      tmp.Free;
    end;
    OutIni.Add('');
    OutIni.Add('KEYWORDS:');
    tmp := TStringList.Create;
    try
      tmp.Text := Keywords;
      if (tmp.Count = 1) and (Pos('No keyword', LowerCase(Trim(tmp[0]))) > 0) then
        tmp.Clear;
      if tmp.Count = 0 then
        OutIni.Add('  Keyword1=No keywords')
      else
        for k := 0 to tmp.Count - 1 do
          OutIni.Add(Format('  Keyword%d=%s', [k + 1, Trim(tmp[k])]))
    finally
      tmp.Free;
    end;

    Inc(NPCCount);
    LastSignature := Signature;
  end;

  Result := 0;
end;

// ================================================================
// FINALIZATION FUNCTION WITH CUTE CAT
// ================================================================

function Finalize: integer;
var
  OutputDir, OutputPath: string;
begin
  AddMessage('===================================================');
  AddMessage('                 PROCESSING SUMMARY                ');
  AddMessage('===================================================');
  AddMessage('');
  AddMessage(Format('Total NPCs processed:         %d', [NPCCount]));
  AddMessage(Format('Invulnerable NPCs found:      %d', [InvulnerableCount]));
  
  AddMessage('');
  AddMessage('===================================================');
  AddMessage('');
  AddMessage('  /\_/\           ');
  AddMessage(' ( o.o )          ');
  AddMessage('  > ^ <           ');
  AddMessage('Script completed with kitty!');
  AddMessage('===================================================');
  
  // Save INI with all data printed
  if PluginName = '' then
    PluginName := 'Selection';
  OutputDir := ScriptsPath + 'NPC_info_report\';
  if not DirectoryExists(OutputDir) then
    CreateDir(OutputDir);
  // Prepend header requested by user at the very top of the INI
  OutIni.Insert(0, '-----------------------------------------------------------------------------------------');
  OutIni.Insert(0, '[00:00] Start: Applying script "Mantella - SPID - CHIM - READ - Info NPC Extractor FULL"');
  // Blank line after header block
  OutIni.Insert(2, '');
  // Add summary section at the end
  OutIni.Add('[Summary]');
  OutIni.Add(Format('TotalNPCs=%d', [NPCCount]));
  if HasInvulnerableNPCs then
  begin
    OutIni.Add(Format('TemporaryInvulnRemovals=%d', [InvulnRemovedCount]));
    OutIni.Add(Format('InvulnRestorations=%d', [OriginallyInvulnerableNPCs.Count]));
  end
  else
    OutIni.Add('TemporaryInvulnRemovals=0');
  // Also record read-only count
  OutIni.Add(Format('InvulnerableCount=%d', [InvulnerableCount]));

  // Decorative processing summary block at the very end
  OutIni.Add('---------------------------------------------------');
  OutIni.Add('===================================================');
  OutIni.Add('                 PROCESSING SUMMARY                ');
  OutIni.Add('===================================================');
  OutIni.Add(Format('Total NPCs processed:         %d', [NPCCount]));
  OutIni.Add(Format('Invulnerable NPCs found:      %d', [InvulnerableCount]));
  OutIni.Add('===================================================');
  OutIni.Add('  /\_/\           ');
  OutIni.Add(' ( o.o )          ');
  OutIni.Add('  > ^ <           ');
  OutIni.Add('Script completed with kitty!');
  OutIni.Add('===================================================');
  OutIni.Add('');
  OutputPath := OutputDir + PluginName + '_NPC_Info.ini';
  try
    OutIni.SaveToFile(OutputPath);
    AddMessage(Format('INI saved to "%s"', [OutputPath]));
  except
    on ex: Exception do
      AddMessage('Failed to save INI: ' + ex.Message);
  end;

  OriginallyInvulnerableNPCs.Free;
  OutIni.Free;
  SeenNPCs.Free;
  Result := 0;
end;

end.
