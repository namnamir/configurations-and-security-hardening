# List All Languages
Either do it from PowerShell
```PowerShell
Get-WinUserLanguageList
```
Or check the list from the `Settings` menu.
```
Settings --> Time & Languages --> Language & Region
```
Or via the registry
```PowerShell
Get-ChildItem -Path "HKLM:\SYSTEM\CurrentControlSet\Control\ContentIndex\Language"
```

# Fix Issues with the Windows Language and Keyboard Layout
## Remove Unwanted Languages (e.g., British English - UK Language)
1. Follow these steps in Windows 11 to see the list of all installed keyboard layouts.
```
Settings --> Time & Languages --> Language & Region
```
2. Compare the list with the ones you see in the language bar or when you use the change language 
shortcut key (`Win + Space`).
![Unwanted Keyboard Languages and Layouts](img/keyboard-layout.png)
4. Add any language or keyboard you see in the language bar but not in the settings.<br>
🔸 Uncheck all the features in the pop window.<br>
🔸 Remember to add all keyboards as they are shown in the language bar.
5. Then remove the language from the setting.
