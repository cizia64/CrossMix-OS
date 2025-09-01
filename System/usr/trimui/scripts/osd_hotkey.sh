#!/bin/sh

value=$(/usr/trimui/bin/shmvar osdshortcut)

case "$value" in
  0)  echo -n "MENU+SELECT" ;;
  1)  echo -n "MENU+START" ;;
  2)  echo -n "MENU+MENU" ;;
  3)  echo -n "MENU+L2" ;;
  4)  echo -n "MENU+R2" ;;
  5)  echo -n "MENU+L" ;;
  6)  echo -n "MENU+R" ;;
  7)  echo -n "MENU+A" ;;
  8)  echo -n "MENU+B" ;;
  9)  echo -n "MENU+X" ;;
 10)  echo -n "MENU+Y" ;;
 11)  echo -n "SELECT+START" ;;
 12)  echo -n "SELECT+L2" ;;
 13)  echo -n "SELECT+R2" ;;
 14)  echo -n "SELECT+L" ;;
 15)  echo -n "SELECT+R" ;;
 16)  echo -n "START+L2" ;;
 17)  echo -n "START+R2" ;;
 18)  echo -n "START+L" ;;
 20)  echo -n "START+R" ;;
 21)  echo -n "MENU+L2+R2" ;;
 *)  echo "Unknown shortcut: $value" ;;
esac
