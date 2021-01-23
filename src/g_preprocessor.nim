import g_error, g_rw
import strutils, os

proc preprocess*(input: string, sourcepath: string): string =
  var peekWord = ""
  var lss: seq[string]
  var output: seq[string]
  var skip_flag = false
  var sourcepath_split = sourcepath.split("/")
  
  var iss = input.split("\n")
  for line in iss:
    lss = line.split(" ")
    for wi, word in lss:
      if word == "":
        continue

      if wi != lss.len()-1:
        peekWord = lss[wi+1]
      else:
        peekWord = "EOL"
      
      if skip_flag:
        skip_flag = false
        continue

      case word
      of "include":
        var filepath = (sourcepath_split[0..sourcepath_split.len()-2] & peekWord).join("/")
        
        if filepath == sourcepath:
          echoErrorMessage("\"" & peekWord & "\"を読み込むことはできません", false, -1)
        elif os.existsFile(filepath) == false:
          echoErrorMessage("\"" & peekWord & "\"が見つからず、includeできませんでした", false, -1)
        elif filepath.endsWith(".grid") == false:
          echoErrorMessage("\"拡張子\".grid\"がありません " & peekWord & "\"", false, -1)
        
        output.add(readSource(filepath))
        skip_flag = true
      else:
        output.add(word)
    
    result.add(output.join(" "))
    output = @[]
    result.add("\n")