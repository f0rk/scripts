  ; Register the scheme xxx to for app
  WriteRegStr HKEY_CLASSES_ROOT "xxx" "" "URL:xxx Organization Application" 
  WriteRegDWORD HKEY_CLASSES_ROOT "xxx" "EditFlags" 0x2
  WriteRegStr HKEY_CLASSES_ROOT "xxx" "URL Protocol" ""
  WriteRegStr HKEY_CLASSES_ROOT "xxx\DefaultIcon" "" "$INSTDIR\executable.exe,1"
  WriteRegStr HKEY_CLASSES_ROOT "xxx\shell\open\command" "" "$\"$INSTDIR\executable.exe$\" $\"$INSTDIR\application.ini$\" $\"%1$\""  
