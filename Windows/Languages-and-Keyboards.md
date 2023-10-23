# See the Existing Installed Languages & Keyboards
Either use the built-in PowerShell cmdlet. It might not show all the keyboards.
```PowerShell
Get-WinUserLanguageList
```
Or use the Registry key/value
```PowerShell
Get-ChildItem -Path "HKLM:\SYSTEM\CurrentControlSet\Control\ContentIndex\Language"
```

# Fix issues with Windows Languages & Keyboard Layouts
Windows is stupid and, for unknown reasons (at least to me), add some languages you didn't ask for. No surprise that you can't remove them as you have not added them 🙄

Follow these steps to fix it.

1. Go to the Languages and Keyboards settings.
```
Settings --> Time & Languages --> Language & Region
```
2. Add all the languages and/or keyboards you see in the language bar (`Win + Space`) but do not see in the settings (previous step).<br>
![Windows Keyboards and Languages settings](img/keyboard-layout.png)<br>
  🔸Uncheck all the features in the pop window.<br>
  🔸Add all `languages` and `keyboards` (from _Language Options_).
3. Remove unwanted languages and/or keyboards.
