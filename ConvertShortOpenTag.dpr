program ConvertShortOpenTag;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  WinAPI.Windows, System.Classes, System.IOUtils, System.StrUtils, System.SysUtils;

const
  PHPExt: array[0..1] of string = ('.php', '.php3');

procedure ChangeTag(FileName: String);
var
  FS: TFileStream;
  Data, Line: String;
  DataLen, FindCnt, FindPos: Integer;
begin
  if IndexStr(LowerCase(ExtractFileExt(FileName)), PHPExt) = -1 then Exit;

  Data := TFile.ReadAllText(FileName, TEncoding.UTF8);
  FindCnt := 0;
  FindPos := 1;

  while True do
  begin
    FindPos := Pos('<?', Data, FindPos);
    if (FindPos = 0) or (FindPos > Length(Data)-2) then Break;
    if Pos(Data[FindPos+2], #10#13#32) > 0 then
    begin
      Insert('php', Data, FindPos+2);
      Inc(FindCnt);
      Inc(FindPos, 3);
    end;
    Inc(FindPos, 3);
  end;

  if FindCnt > 0 then
  begin
    WriteLn(Format('%s(%d)', [FileName, FindCnt]));
    CopyFile(PChar(FileName), PChar(FileName+'.bak'), False);
    TFile.WriteAllText(FileName, Data, TEncoding.UTF8);
  end;
end;

procedure SearchFile(FileName: String);
var
  SR: TSearchRec;
  Path: string;
begin
  Path := IncludeTrailingPathDelimiter(FileName);

  if TDirectory.Exists(Path) then
  begin
    if FindFirst(Path+'*.*', faAnyFile, SR) = 0 then
    begin
      Repeat
        if ((SR.Name = '.') or (SR.Name = '..')) then Continue;

        if (SR.Attr and faDirectory) = faDirectory then
        begin
          SearchFile(Path+SR.Name);
          Continue;
        end;

        ChangeTag(Path+SR.Name);
      Until FindNext(SR) <> 0;
      FindClose(SR);
    end;
  end
  else
    ChangeTag(FileName);
end;

begin
  if ParamCount <> 1 then
    WriteLn('Usage: ChangeShortOpen <FileName or Directory>')
  else
    SearchFile(ParamStr(1));
end.

