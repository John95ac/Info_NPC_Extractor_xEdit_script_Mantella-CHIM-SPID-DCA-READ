# 📜 PASCAL "Info NPC Extractor xEdit script Mantella - CHIM - SPID - DCA - READ"

Script for SSEEdit, with the function to extract information from the NPC and utilize Mantella - CHIM - SPID - DCA or Reading.

---

# What does it do?

#### NPC Info John95ac INI

Generates a structured INI file with sections per NPC ([NPC_# = Name]), subsections (BASIC INFORMATION, CHARACTER DETAILS, FACTIONS, KEYWORDS), and a summary at the end. More readable for humans or parsing. Includes detailed logging in xEdit. Output: NPC_Extracted_Info.ini

Example NPC_Extracted_Info.ini

```ini
[00:00] Start: Applying script "Mantella - SPID - CHIM - DCA - READ - Info NPC Extractor FULL"

-----------------------------------------------------------------------------------------

[NPC_1 = Dragonborn]
BASIC INFORMATION:
  Name=Dragonborn
  FormIDXX=XX000800
  EditorID=Player
  Gender=Male

CHARACTER DETAILS:
  Location=Whiterun (WhiterunExterior01)
  Race=Nord
  Class=Dragonborn
  Voice=NPCMaleNord

FACTIONS:
  Faction1=No factions

KEYWORDS:
  Keyword1=ActorTypeNPC
  Keyword2=No Keywords

[Summary]
TotalNPCs=1
TemporaryInvulnRemovals=0
InvulnerableCount=0

---------------------------------------------------
===================================================
                 PROCESSING SUMMARY                
===================================================
Total NPCs processed:         1
Invulnerable NPCs found:      0
===================================================
  /\_/\           
 ( o.o )         
  > ^ <           
Script completed with kitty!
===================================================
```

#### NPC Info John95ac CSV

This script extracts detailed NPC information (NPC_ and ACHR records) from ESP/ESM files, focused on Mantella/SPID integration. It generates a tabular CSV file with columns: FormID (normalized), EditorID, Name, Gender, Location, Race, Voice Type, Class, Factions (joined by ';'), Keywords (joined by ';'). Includes invulnerability detection (count only, no modifications). Deduplicates NPCs to avoid repetitions. Output: NPC_Extracted_Info.csv

Example NPC_Extracted_Info.csv

```csv
FormID,EditorID,Name,Gender,Location,Race,Voice Type,Class,Factions,Keywords
XX000800,Player,Dragonborn,Male,Whiterun (WhiterunExterior01),Nord,NPCMaleNord,Dragonborn,"No factions","ActorTypeNPC; No Keywords"
```

#### At the end of a process

<table>
<tr>
<td><img src="Edit Scripts/001_3D.png" width="100" height="100" alt="001_3D"></td>
<td>If this image appears in the completion dialog, it means the script was executed successfully.</td>
</tr>
</table>

# Acknowledgements

to all those who use the Mantella Adding NPCs Back History NG mod and its SKSE plugin, this is for you and for me, so you can get the information faster and also help in SPID and more things,

many thanks to **Papitas**, for his work on the Pascal [**Get RefIds - xEdit script**](https://www.nexusmods.com/skyrimspecialedition/mods/87787). The way he creates the CSV seemed fascinating to me, but it gave me problems with NPCs categorized as invulnerable, so I created a modified version of my script from INI to CSV inspired by his, many thanks, really Pascal is not my coding style, and with some reverse engineering I managed to understand many things about Pascal.

# Requirements

- [SSEEdit](https://www.nexusmods.com/skyrimspecialedition/mods/164?tab=files)
