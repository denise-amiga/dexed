unit u_dastworx;
{$I u_defines.inc}

interface

uses
  Classes, SysUtils, process, jsonscanner, fpjson, jsonparser,
  u_common, u_dialogs;

(**
 * Gets the module name and the imports of the source code located in
 * "source". The first line of "import" contains the module name, double quoted.
 * Each following line contain an import.
 *)
procedure getModuleImports(source, imports: TStrings);

(**
 * Gets the module names and the imports of the sources in "files".
 * source. Each line in "import" that contains double quoted text indicates
 * that a new group of import starts.
 *)
procedure getModulesImports(files: string; results: TStrings);

procedure getHalsteadMetrics(source: TStrings; out jsn: TJSONObject);

procedure getDdocTemplate(source, res: TStrings;caretLine: integer; plusComment: boolean);

implementation

var
  toolname: string;

function getToolName: string;
begin
  if toolname = '' then
    toolname := exeFullName('dastworx' + exeExt);
  exit(toolname);
end;

procedure getModuleImports(source, imports: TStrings);
var
  str: string;
  prc: TProcess;
begin
  str := getToolName;
  if str.isEmpty then
    exit;
  prc := TProcess.Create(nil);
  try
    prc.Executable := str;
    prc.Parameters.Add('-i');
    prc.Options := [poUsePipes{$IFDEF WINDOWS}, poNewConsole{$ENDIF}];
    prc.ShowWindow := swoHIDE;
    prc.Execute;
    str := source.Text;
    prc.Input.Write(str[1], str.length);
    prc.CloseInput;
    processOutputToStrings(prc, imports);
    while prc.Running do ;
    {$IFDEF DEBUG}
    tryRaiseFromStdErr(prc);
    {$ENDIF}
  finally
    prc.free;
  end;
end;

procedure getModulesImports(files: string; results: TStrings);
var
  str: string;
  prc: TProcess;
  {$ifdef WINDOWS}
  cdr: string = '';
  itm: string;
  spl: TStringList;
  i: integer;
  {$endif}
begin
  str := getToolName;
  if str.isEmpty then
    exit;
  {$ifdef WINDOWS}
  if files.length > 32760{not 8 : "-f -i" length} then
  begin
    spl := TStringList.Create;
    try
      spl.LineBreak := ';';
      spl.AddText(files);
      cdr := commonFolder(spl);
      if not cdr.dirExists then
      begin
        dlgOkError('Impossible to find the common directory in the list to analyze the imports:  ' + shortenPath(files, 200));
        exit;
      end;
      for i:= 0 to spl.count-1 do
      begin
        itm := spl.strings[i];
        spl.strings[i] := itm[cdr.length + 2 .. itm.length];
      end;
      files := spl.strictText;
      if files.length > 32760 then
      begin
        dlgOkError('Too much files in the list to analyze the imports:  ' + shortenPath(files, 200));
        exit;
      end;
    finally
      spl.Free;
    end;
  end;
  {$endif}
  prc := TProcess.Create(nil);
  try
    prc.Executable := str;
    prc.Parameters.Add('-f' + files);
    prc.Parameters.Add('-i');
    prc.Options := [poUsePipes {$IFDEF WINDOWS}, poNewConsole{$ENDIF}];
    prc.ShowWindow := swoHIDE;
    {$ifdef WINDOWS}
    if cdr.isNotEmpty then
      prc.CurrentDirectory := cdr;
    {$endif}
    prc.Execute;
    prc.CloseInput;
    processOutputToStrings(prc, results);
    while prc.Running do ;
    {$IFDEF DEBUG}
    tryRaiseFromStdErr(prc);
    {$ENDIF}
  finally
    prc.free;
  end;
end;

procedure getHalsteadMetrics(source: TStrings; out jsn: TJSONObject);
var
  prc: TProcess;
  prs: TJSONParser;
  jps: TJSONData;
  str: string;
  lst: TStringList;
begin
  str := getToolName;
  if str.isEmpty then
    exit;
  prc := TProcess.Create(nil);
  lst := TStringList.create;
  try
    prc.Executable := str;
    prc.Parameters.Add('-H');
    prc.Options := [poUsePipes {$IFDEF WINDOWS}, poNewConsole{$ENDIF}];
    prc.ShowWindow := swoHIDE;
    prc.Execute;
    str := source.Text;
    prc.Input.Write(str[1], str.length);
    prc.CloseInput;
    processOutputToStrings(prc, lst);
    prs := TJSONParser.Create(lst.Text, [joIgnoreTrailingComma, joUTF8]);
    jps := prs.Parse;
    if jps.isNotNil and (jps.JSONType = jtObject) then
      jsn := TJSONObject(jps.Clone);
    jps.Free;
    while prc.Running do ;
  finally
    prs.Free;
    prc.Free;
    lst.free;
  end;
end;

procedure getDdocTemplate(source, res: TStrings; caretLine: integer; plusComment: boolean);
var
  prc: TProcess;
  str: string;
begin
  str := getToolName;
  if str.isEmpty then
    exit;
  prc := TProcess.Create(nil);
  try
    prc.Executable := str;
    prc.Parameters.Add('-l' + caretLine.ToString);
    if plusComment then
      prc.Parameters.Add('-o');
    prc.Parameters.Add('-K');
    prc.Options := [poUsePipes {$IFDEF WINDOWS}, poNewConsole{$ENDIF}];
    prc.ShowWindow := swoHIDE;
    prc.Execute;
    str := source.Text;
    prc.Input.Write(str[1], str.length);
    prc.CloseInput;
    processOutputToStrings(prc, res);
  finally
    prc.Free;
  end;
end;

end.

