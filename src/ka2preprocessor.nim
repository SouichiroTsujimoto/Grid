import strutils, os, ka2error, ka2rw

proc preprocess*(input: string): string =
  var peekWord = ""
  var lss: seq[string]
  var output: seq[string]
  var skip_flag = false
  
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

      if word.startsWith("#"):
        case word
        of "#include":
          if os.existsFile(peekWord) == false:
            echoErrorMessage("\"" & peekWord & "\"が見つからず、includeできませんでした", false, -1)
          output.add(readSource(peekWord))
          skip_flag = true
        else:
          output.add(word)
      else:
        output.add(word)
    
    result.add(output.join(" "))
    output = @[]
    result.add("\n")