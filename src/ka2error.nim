proc echoErrorMessage*(message: string, test: bool) =
  echo message
  
  if test == false:
    quit()
