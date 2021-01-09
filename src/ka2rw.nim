import ka2error
import system, os

proc readSource*(name: string): string =
  if os.existsFile(name):
    var f: File = open(name , FileMode.fmRead)
    defer: close(f)
    return f.readAll()
  else:
    echoErrorMessage("そのファイルは存在しません", false, -1)

proc writeCpp*(name: string, code: string) =
  var f: File = open(name ,FileMode.fmWrite)
  defer: close(f)
  f.write(code)