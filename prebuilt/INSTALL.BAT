echo off
copy ..\src\*.x .
losetup -w ZUSB.XDF
copy *.x k:
losetup -D
