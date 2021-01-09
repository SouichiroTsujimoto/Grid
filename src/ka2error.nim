proc echoErrorMessage*(message: string, test: bool, line: int) =
  if line < 0:
    echo "[error] \"" & message & "\""
  else:
    echo "[error][line:" & $line & "] \"" & message & "\""
  
  if test == false:
    quit()
