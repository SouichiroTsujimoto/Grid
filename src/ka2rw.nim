proc readSource*(name: string): string =
  var f: File = open(name , FileMode.fmRead)
  defer: close(f)
  return f.readAll()

proc writeCpp*(name: string, code: string) =
  var f: File = open(name ,FileMode.fmWrite)
  defer: close(f)
  f.write(code)