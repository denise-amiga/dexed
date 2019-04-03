unit u_simpleget;

{$I u_defines.inc}

interface

uses
  classes, {$ifdef posix}libcurl,{$else} fphttpclient,{$endif} fpjson, jsonparser, jsonscanner;

type
  PStream = ^TStream;

// Get the content of 'url' in the string 'data'
function simpleGet(url: string; var data: string): boolean; overload;
// Get the content of 'url' in the stream 'data'
function simpleGet(url: string; data: TStream): boolean; overload;
// Get the content of 'url' in the JSON 'data', supposed to be a nil instance.
function simpleGet(url: string; var data: TJSONData): boolean; overload;

const
  {$ifdef windows} libcurlFname = 'libeay32.dll, ssleay32.dll';    {$endif}
  {$ifdef linux}   libcurlFname = 'libcurl.so';     {$endif}
  {$ifdef darwin}  libcurlFname = 'libcurl.dylib';  {$endif}
  simpleGetErrMsg = 'no network or ' + libcurlFname + ' not setup correctly';

implementation

{$ifdef posix}
var
  fCurlHandle: CURL = nil;

function curlHandle(): CURL;
begin
  if not assigned(fCurlHandle) then
  begin
    curl_global_init(CURL_GLOBAL_SSL or CURL_GLOBAL_ALL);
    fCurlHandle := curl_easy_init();
  end;
  result := fCurlHandle;
end;

function simpleGetClbckForStream(buffer:Pchar; size:PtrInt; nitems:PtrInt;
  appender: PStream): PtrInt; cdecl;
begin
  try
    result := appender^.write(buffer^, size * nitems);
  except
    result := 0;
  end;
end;

function simpleGetClbckForString(buffer:Pchar; size:PtrInt; nitems:PtrInt;
  appender: PString): PtrInt; cdecl;
begin
  result := size* nitems;
  try
    (appender^) += buffer;
  except
    result := 0;
  end;
end;
{$endif}

function simpleGet(url: string; var data: string): boolean; overload;
{$ifdef posix}
var
  c: CURLcode;
  h: CURL;
{$endif}
begin
  {$ifdef posix}
  h := curlHandle();
  if not assigned(h) then
    exit(false);
  c := curl_easy_setopt(h, CURLOPT_USERAGENT, ['curl-fclweb']);
  if c <> CURLcode.CURLE_OK then
    exit(false);
  c := curl_easy_setopt(h, CURLOPT_URL, [PChar(url)]);
  if c <> CURLcode.CURLE_OK then
    exit(false);
  c := curl_easy_setopt(h, CURLOPT_WRITEDATA, [@data]);
  if c <> CURLcode.CURLE_OK then
    exit(false);
  c := curl_easy_setopt(h, CURLOPT_WRITEFUNCTION, [@simpleGetClbckForString]);
  if c <> CURLcode.CURLE_OK then
    exit(false);
  c := curl_easy_perform(h);
  result := c = CURLcode.CURLE_OK;
  {$else}
  result := true;
  with TFPHTTPClient.Create(nil) do
  try
    try
      AddHeader('User-Agent','Mozilla/5.0 (compatible; fpweb)');
      data := get(url);
    except
      result := false;
    end;
  finally
    free;
  end;
  {$endif}
end;

function simpleGet(url: string; data: TStream): boolean; overload;
{$ifdef posix}
var
  c: CURLcode;
  h: CURL;
{$endif}
begin
  {$ifdef posix}
  h := curlHandle();
  if not assigned(h) then
    exit(false);
  c := curl_easy_setopt(h, CURLOPT_USERAGENT, ['curl-fclweb']);
  if c <> CURLcode.CURLE_OK then
    exit(false);
  c := curl_easy_setopt(h, CURLOPT_URL, [PChar(url)]);
  if c <> CURLcode.CURLE_OK then
   exit(false);
  c := curl_easy_setopt(h, CURLOPT_WRITEDATA, [@data]);
  if c <> CURLcode.CURLE_OK then
   exit(false);
  c := curl_easy_setopt(h, CURLOPT_WRITEFUNCTION, [@simpleGetClbckForStream]);
  if c <> CURLcode.CURLE_OK then
   exit(false);
  c := curl_easy_perform(h);
  result := c = CURLcode.CURLE_OK;
  {$else}
  result := true;
  with TFPHTTPClient.Create(nil) do
  try
    try
      AddHeader('User-Agent','Mozilla/5.0 (compatible; fpweb)');
      get(url, data);
    except
      result := false;
    end;
  finally
    free;
  end;
  {$endif}
end;

function simpleGet(url: string; var data: TJSONData): boolean; overload;
var
  s: string = '';
begin
  if not simpleGet(url, s) then
    exit(false);
  result := true;
  with TJSONParser.Create(s, [joUTF8, joIgnoreTrailingComma]) do
  try
    try
      data := Parse();
    except
      result := false;
    end;
  finally
    free;
  end;
end;

finalization
  {$ifdef posix}
  if assigned(fCurlHandle) then
    curl_easy_cleanup(fCurlHandle);
  {$endif}
end.

