  ; Acrobat support ($R1 contains path to Acrobat base)
  ReadRegStr $R1 HKEY_LOCAL_MACHINE "SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\Acrobat.exe" "Path"
  IfErrors NoAcrobat YesAcrobat
NoAcrobat:
  ReadRegStr $R1 HKEY_LOCAL_MACHINE "SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\AcroRd32.exe" "Path"
  IfErrors NoReader YesReader
YesAcrobat:
  ReadRegStr $R1 HKEY_LOCAL_MACHINE "SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\Acrobat.exe" "Path"
  Goto Exit
YesReader:
  ReadRegStr $R1 HKEY_LOCAL_MACHINE "SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\AcroRd32.exe" "Path"
  Goto Exit

NoReader:
  MessageBox MB_OK "Acrobat or Reader not found, you will not be able to view PDF files"

Exit:
  ; end
