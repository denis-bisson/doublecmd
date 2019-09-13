unit uWorker;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, SyncObjs, uService;

const
  RPC_Execute     = 1;

type

  { TMasterService }

  TMasterService = class(TBaseService)
  private
    FEvent: TEvent;
  public
    function Wait: Boolean;
    constructor Create(const AName: String); override;
    procedure ProcessRequest(ATransport: TBaseTransport; ACommand: Int32; ARequest: TStream); override;
  end;

const
  RPC_Terminate  = 0;
  RPC_FileOpen   = 1;
  RPC_FileCreate = 2;
  RPC_DeleteFile = 3;
  RPC_RenameFile = 4;

  RPC_CreateDirectory = 5;
  RPC_RemoveDirectory = 6;

type

  { TWorkerService }

  TWorkerService = class(TBaseService)
  public
    constructor Create(const AName: String); override;
    procedure ProcessRequest(ATransport: TBaseTransport; ACommand: Int32; ARequest: TStream); override;
  end;

var
  WorkerProcessId: SizeUInt = 0;

implementation

uses
  DCOSUtils;

{ TMasterService }

function TMasterService.Wait: Boolean;
begin
  Result:= FEvent.WaitFor(60000) = wrSignaled;
end;

constructor TMasterService.Create(const AName: String);
begin
  inherited Create(AName);
  Self.FVerifyChild:= True;
  FEvent:= TEvent.Create(nil, False, False, '');
end;

procedure TMasterService.ProcessRequest(ATransport: TBaseTransport; ACommand: Int32;
  ARequest: TStream);
var
  Result: LongBool = True;
begin
  case ACommand of
    RPC_Execute:
      begin
        ARequest.ReadBuffer(WorkerProcessId, SizeOf(SizeUInt));
        ATransport.WriteBuffer(Result, SizeOf(Result));
        FEvent.SetEvent;
      end;
  end;
end;

{ TWorkerService }

constructor TWorkerService.Create(const AName: String);
begin
  inherited Create(AName);
  Self.FVerifyParent:= True;
end;

procedure TWorkerService.ProcessRequest(ATransport: TBaseTransport; ACommand: Int32;
  ARequest: TStream);
var
  Handle: THandle;
  FileName: String;
  Mode: Integer;
  Result: LongBool;
begin
  case ACommand of
  RPC_DeleteFile:
    begin
      FileName:= ARequest.ReadAnsiString;
      WriteLn('DeleteFile ', FileName);
      Result:= mbDeleteFile(FileName);
      ATransport.WriteBuffer(Result, SizeOf(Result));
    end;
  RPC_FileOpen:
    begin
      FileName:= ARequest.ReadAnsiString;
      Mode:= ARequest.ReadDWord;
      WriteLn('FileOpen ', FileName);
      Handle:= mbFileOpen(FileName, Mode);
      ATransport.WriteHandle(Handle);
    end;
  RPC_FileCreate:
    begin
      FileName:= ARequest.ReadAnsiString;
      Mode:= ARequest.ReadDWord;
      WriteLn('FileCreate ', FileName);
      Handle:= mbFileCreate(FileName, Mode);
      ATransport.WriteHandle(Handle);
    end;
  RPC_CreateDirectory:
    begin
      FileName:= ARequest.ReadAnsiString;
      WriteLn('CreateDirectory ', FileName);
      Result:= mbCreateDir(FileName);
      ATransport.WriteBuffer(Result, SizeOf(Result));
    end;
  RPC_RemoveDirectory:
    begin
      FileName:= ARequest.ReadAnsiString;
      WriteLn('RemoveDirectory ', FileName);
      Result:= mbRemoveDir(FileName);
      ATransport.WriteBuffer(Result, SizeOf(Result));
    end;
  RPC_Terminate: Halt;
  end;
end;

end.
