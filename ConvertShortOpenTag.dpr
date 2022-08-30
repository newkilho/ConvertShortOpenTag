program ConvertShortOpenTag;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  WinAPI.Windows, System.Classes, System.IOUtils, System.StrUtils, System.SysUtils;

const
  PHPExt: array[0..1] of string = ('.php', '.php3');

procedure ChangeTag(FileName: String; var Count: Integer; Shortcut: Boolean);
var
  FS: TFileStream;
  Data, Line, Patt: String;
  DataLen, FindCnt, FindPos: Integer;
begin
  if IndexStr(LowerCase(ExtractFileExt(FileName)), PHPExt) = -1 then Exit;

  Data := TFile.ReadAllText(FileName, TEncoding.UTF8);
  FindCnt := 0;
  FindPos := 1;
  if Shortcut then Patt := #10#13#32#61 else Patt := #10#13#32;
  while True do
  begin
    FindPos := Pos('<?', Data, FindPos);
    if (FindPos = 0) or (FindPos > Length(Data)-2) then Break;
    if Pos(Data[FindPos+2], Patt) > 0 then
    begin
      if Data[FindPos+2] = #61 then
      begin
        Data[FindPos+2] := ' ';
        Insert('echo ', Data, FindPos+3);
        Insert('; ', Data, Pos('?>', Data, FindPos));
      end;

      Insert('php', Data, FindPos+2);
      Inc(FindPos, 3);

      Inc(FindCnt);
    end;
    Inc(FindPos, 3);
  end;

  if FindCnt > 0 then
  begin
    WriteLn(Format('%s(%d)', [FileName, FindCnt]));
    CopyFile(PChar(FileName), PChar(FileName+'.bak'), False);
    TFile.WriteAllText(FileName, Data, TEncoding.UTF8);
    Inc(Count);
  end;
end;

procedure SearchFile(FileName: String; var Count: Integer; Shortcut: Boolean);
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
          SearchFile(Path+SR.Name, Count, Shortcut);
          Continue;
        end;

        ChangeTag(Path+SR.Name, Count, Shortcut);
      Until FindNext(SR) <> 0;
      FindClose(SR);
    end;
  end
  else
    ChangeTag(FileName, Count, Shortcut);
end;

var
  FileName: String;
  Shortcut, Help: Boolean;
  Count, I: Integer;
begin
  WriteLn('ConvertShortOpenTag version 1.1 Copyright (c) 2022 Kilho.net');
  WriteLn('');

  ShortCut := True;
  Help := False;
  Count := 0;

  for I := 1 to ParamCount do
  begin
    case IndexStr(ParamStr(I), ['-s']) of
      0: ShortCut := False;
    else
      if (FileExists(ParamStr(I)) or DirectoryExists(ParamStr(I))) then
        FileName := ParamStr(I)
      else
        Help := True;
    end;
  end;

  if (FileName = '') or (Help) then
  begin
    WriteLn('Usage: ChangeShortOpen [option] {FileName or Directory}');
    WriteLn(' -s          Ignore Echo shortcut(<?=)');

    Exit;
  end;

  SearchFile(ParamStr(1), Count, Shortcut);
  if Count = 0 then
  begin
    WriteLn('No files have been modified.');
  end;
end.

