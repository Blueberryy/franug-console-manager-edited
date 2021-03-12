/*  SM Console Chat Manager
 *
 *  Copyright (C) 2017 Francisco 'Franc1sco' García
 * 
 * This program is free software: you can redistribute it and/or modify it
 * under the terms of the GNU General Public License as published by the Free
 * Software Foundation, either version 3 of the License, or (at your option) 
 * any later version.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT 
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS 
 * FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License along with 
 * this program. If not, see http://www.gnu.org/licenses/.
 */

#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <multicolors>
#include <geoip>
//#include <emitsoundany>
//#include <csgocolors_fix>
#include <clientprefs>

#pragma newdecls required // let's go new syntax! 

#define VERSION "1.5.0"

Handle kv;
char Path[PLATFORM_MAX_PATH];
float x=0.2;
int j=0;
bool csgo;

int		g_iVolume[MAXPLAYERS + 1] = {100, ...};

Handle g_hConsoleSoundCookie;
Handle g_hConsoleCookie_Volume = INVALID_HANDLE;
bool g_bConsoleSound[MAXPLAYERS + 1];

public Plugin myinfo = 
{
	name = "SM Console Chat Manager with sound and HUD support",
	author = "Franc1sco Steam: franug, nuclear silo",
	description = "",
	version = VERSION,
	url = ""
};

public void OnPluginStart()
{
	CreateConVar("sm_consolechatmanager_version", VERSION, "", FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	
	RegConsoleCmd("say", SayConsole);
	
	LoadTranslations("console_phrase.phrases");
	
	RegConsoleCmd("sm_console", Command_Console, "Brings up the console menu");
	
	g_hConsoleSoundCookie = RegClientCookie("Console_Sound", "Console Sound", CookieAccess_Private);
	g_hConsoleCookie_Volume	= RegClientCookie("cookie_map_music_volume", "Disable Map Music Volume", CookieAccess_Private);
	SetCookieMenuItem(ItemCookieMenu, 0, "Console Volume Control");
	
	//SetCookieMenuItem(PrefMenu, 0, "");
	//SetCookiePrefabMenu(g_hConsoleSoundCookie,CookieMenu_OnOff_Int,"Console_Sound", PrefMenu);
	
}

public void OnClientCookiesCached(int client)
{
    char sValue[8];
    GetClientCookie(client, g_hConsoleSoundCookie, sValue, sizeof(sValue));
	
	g_bConsoleSound[client] = (sValue[0] != '\0' && StringToInt(sValue));
	//g_bConsoleSound[client] = view_as<bool>(StringToInt(sValue));
	
	GetClientCookie(client, g_hConsoleCookie_Volume, sValue, sizeof(sValue));
	if(StrEqual(sValue,""))
	{
		SetClientCookie(client, g_hConsoleCookie_Volume, "100");
		strcopy(sValue, sizeof(sValue), "100");
	}
	g_iVolume[client] = StringToInt(sValue);
	//g_bAutoRetry[client] = GetClientCookie(client);
} 

public void ItemCookieMenu(int iClient, CookieMenuAction hAction, any Info, char[] sBuffer, int iMaxlen)
{
	switch(hAction)
	{
		case CookieMenuAction_DisplayOption: FormatEx(sBuffer, iMaxlen, "Console Volume Control", iClient);
		case CookieMenuAction_SelectOption: ConsoleMenu(iClient);
	}
}

void ConsoleMenu(int iClient)
{
	Menu hMenu = CreateMenu(ConsoleMenuHandler, MENU_ACTIONS_DEFAULT);

	char sMenuTranslate[256];
	FormatEx(sMenuTranslate, sizeof(sMenuTranslate), "%T %T", "Console Tag Menu", iClient, "Console Menu Title", iClient);
	hMenu.SetTitle(sMenuTranslate);
	hMenu.ExitBackButton = true;
	
	FormatEx(sMenuTranslate, sizeof(sMenuTranslate), "%T \n%T", "Console Menu Music", iClient, g_bConsoleSound[iClient] ? "Console Disabled" : "Console Enabled", iClient, "Console Menu AdjustDesc", iClient);
	hMenu.AddItem(g_bConsoleSound[iClient] ? "enable" : "disable", sMenuTranslate);

	FormatEx(sMenuTranslate, sizeof(sMenuTranslate), "%T", "Console Menu Vol", iClient, g_iVolume[iClient]);

	switch(g_iVolume[iClient])
	{
		case 100:	hMenu.AddItem("vol_90", sMenuTranslate);
		case 90:	hMenu.AddItem("vol_80", sMenuTranslate);
		case 80:	hMenu.AddItem("vol_70", sMenuTranslate);
		case 70:	hMenu.AddItem("vol_60", sMenuTranslate);
		case 60:	hMenu.AddItem("vol_50", sMenuTranslate);
		case 50:	hMenu.AddItem("vol_40", sMenuTranslate);
		case 40:	hMenu.AddItem("vol_30", sMenuTranslate);
		case 30:	hMenu.AddItem("vol_20", sMenuTranslate);
		case 20:	hMenu.AddItem("vol_10", sMenuTranslate);
		case 10:	hMenu.AddItem("vol_5", sMenuTranslate);
		case 5:		hMenu.AddItem("vol_100", sMenuTranslate);
		default:	hMenu.AddItem("vol_100", sMenuTranslate);
	}
	hMenu.Display(iClient, MENU_TIME_FOREVER);
}

public int ConsoleMenuHandler(Menu hMenu, MenuAction hAction, int iClient, int iParam2)
{
	switch(hAction)
	{
		case MenuAction_End: delete hMenu;
		case MenuAction_Cancel: if(iParam2 == MenuCancel_ExitBack) ShowCookieMenu(iClient);
		case MenuAction_Select:
		{
			char sOption[8];
			hMenu.GetItem(iParam2, sOption, sizeof(sOption));
			if(StrEqual(sOption, "disable"))
			{
				g_bConsoleSound[iClient] = true;
				CPrintToChat(iClient, "%t %t", "Console Tag", "Console Text Disable");
				SetClientCookie(iClient, g_hConsoleSoundCookie, "1");
				//Client_StopSound(iClient);
			}else if(StrEqual(sOption, "enable"))
			{
				//if(g_bConsoleSound[iClient]) Client_UpdateMusics(iClient);
				g_bConsoleSound[iClient] = false;
				CPrintToChat(iClient, "%t %t", "Console Tag", "Console Text Enable");
				SetClientCookie(iClient, g_hConsoleSoundCookie, "0");
			}else if(StrContains(sOption, "vol") >= 0)
			{
				g_bConsoleSound[iClient] = false;
				SetClientCookie(iClient, g_hConsoleSoundCookie, "0");
				g_iVolume[iClient] = StringToInt(sOption[4]);
				SetClientCookie(iClient, g_hConsoleCookie_Volume, sOption[4]);
				CPrintToChat(iClient, "%t %t", "Console Tag", "Console Text Volume", g_iVolume[iClient]);
				//Client_UpdateMusics(iClient);
			}
			ConsoleMenu(iClient);
		}
	}
}

/*
public void PrefMenu(int client, CookieMenuAction actions, any info, char[] buffer, int maxlen)
{
	if (actions == CookieMenuAction_DisplayOption)
	{
		switch(g_bConsoleSound[client])
		{
			case false: FormatEx(buffer, maxlen, "Console Sound: Enabled");
			case true: FormatEx(buffer, maxlen, "Console Sound: Disabled");
		}
	}

	if (actions == CookieMenuAction_SelectOption)
	{
		CMD_ConsoleSound(client);
		ShowCookieMenu(client);
	}
}

void CMD_ConsoleSound(int client)
{
	char sCookieValue[8];

	switch(g_bConsoleSound[client])
	{
		case false:
		{
			g_bConsoleSound[client] = true;
			IntToString(1, sCookieValue, sizeof(sCookieValue));
			SetClientCookie(client, g_hConsoleSoundCookie, sCookieValue);
			CPrintToChat(client, "\x04[Console]:\x05 Sound: \x07Disabled");
		}
		case true:
		{
			g_bConsoleSound[client] = false;
			IntToString(0, sCookieValue, sizeof(sCookieValue));
			SetClientCookie(client, g_hConsoleSoundCookie, sCookieValue);
			CPrintToChat(client, "\x04[Console]:\x05 Sound: \x07Enabled ", "Prefix");
		}
	}
}
*/
public APLRes AskPluginLoad2(Handle myself, bool late, char [] error, int err_max)
{
	if(GetEngineVersion() == Engine_CSGO)
	{
		csgo = true;
	} else csgo = false;
	
	return APLRes_Success;
}

public void OnMapStart()
{
	ReadT();
	// add mp3 files without sound/
	// add wav files with */
	PrecacheSound("music/AIF/CMSL.mp3");
	PrecacheSound("*/common/talk.wav");
}

public void ReadT()
{
	delete kv;
	
	char map[64];
	GetCurrentMap(map, sizeof(map));
	BuildPath(Path_SM, Path, sizeof(Path), "configs/franug_consolechatmanager/%s.txt", map);
	
	kv = CreateKeyValues("Console_C");
	
	if(!FileExists(Path)) KeyValuesToFile(kv, Path);
	else FileToKeyValues(kv, Path);
	
	//CheckSounds();
}

void CheckSounds()
{
	
	//PrecacheSound("music/AIF/CMSL.mp3", true);
	char buffer[255];
	
	if(KvGotoFirstSubKey(kv))
	{
		do
		{
			KvGetString(kv, "sound", buffer, 64, "default");
			if(!StrEqual(buffer, "default"))
			{
				if(!csgo) PrecacheSound(buffer);
				else PrecacheSoundAny(buffer);
				
				Format(buffer, 255, "sound/%s", buffer);
				AddFileToDownloadsTable(buffer);
			}
			
		} while (KvGotoNextKey(kv));
	}
	
	KvRewind(kv);
}

/*
public void SendHudMsg(int client, char[] szMessage)
{
	SetHudTextParams(HudPos[0], HudPos[1], 1.5, HudColor[0], HudColor[1], HudColor[2], 255, 0, 0.0, 0.0, 0.0);
	ShowSyncHudText(client, HudSync, szMessage);
}*/

public Action Command_Console(int iClient, int iArgs)
{
	if(IsClientConnected(iClient) && IsClientInGame(iClient))
	{
		if(iArgs >= 1)
		{
			char sArg[6];
			GetCmdArg(1, sArg, sizeof(sArg));
			int iVolume = StringToInt(sArg);
			if(StrEqual(sArg, "disallow", false) || StrEqual(sArg, "off", false) || iVolume <= 0)
			{
				g_bConsoleSound[iClient] = true;
				CPrintToChat(iClient, "%t %t", "Console Tag", "Console Text Disable");
				SetClientCookie(iClient, g_hConsoleSoundCookie, "1");
				//Client_StopSound(iClient);
				return Plugin_Handled;
			}else if(StrEqual(sArg, "allow", false) || StrEqual(sArg, "on", false))
			{
				//if(g_bConsoleSound[iClient]) Client_UpdateMusics(iClient);
				g_bConsoleSound[iClient] = false;
				CPrintToChat(iClient, "%t %t", "Console Tag", "Console Text Enable");
				SetClientCookie(iClient, g_hConsoleSoundCookie, "0");
				return Plugin_Handled;
			}else
			{
				if(iVolume > 100) iVolume = 100;
				g_bConsoleSound[iClient] = false;
				SetClientCookie(iClient, g_hConsoleSoundCookie, "0");
				g_iVolume[iClient] = iVolume;
				CPrintToChat(iClient, "%t %t", "Console Tag", "Console Text Volume", g_iVolume[iClient]);
				char sVolume[8];
				IntToString(g_iVolume[iClient], sVolume, sizeof(sVolume));
				SetClientCookie(iClient, g_hConsoleCookie_Volume, sVolume);
				//Client_UpdateMusics(iClient);
				return Plugin_Handled;
			}
		}

		ConsoleMenu(iClient);
	}
	return Plugin_Handled;
}

public Action SayConsole(int client, int args)
{
	
	if (client==0)
	{
		char buffer[255], buffer2[255],soundp[255], soundt[255];
		
		GetCmdArgString(buffer,sizeof(buffer));
		StripQuotes(buffer);
		if(kv == INVALID_HANDLE)
		{
			ReadT();
		}
		
		if(!KvJumpToKey(kv, buffer))
		{
			KvJumpToKey(kv, buffer, true);
			Format(buffer2, sizeof(buffer2), "{darkred}[ {green}J1BroS{darkred} ]: {green} %s", buffer);
			KvSetString(kv, "default", buffer2);
			KvRewind(kv);
			KeyValuesToFile(kv, Path);
			KvJumpToKey(kv, buffer);
		}
		
		//for (j=0;j<=3;j++) if (j==3) j=0; // this shit cause inf loop
		j++;
		x+=0.045;
		if(j==3) 
		{
			j=0;
			x=0.2;
		}
		
		
		
		for (client = 1; client <= MaxClients; client++) 
		{
			if (IsClientInGame(client)) 
			{
				
				KvJumpToKey(kv, buffer, true);
				KvSetString(kv, "default", buffer2);
				KvRewind(kv);
				KeyValuesToFile(kv, Path);
				KvJumpToKey(kv, buffer);
				SetHudTextParams(-1.0, x, 1.65, 0, 255, 0, 255, 2, 0.01, 0.02, 0.02);
				ShowHudText(client, -1, "%s", buffer);
				float fPlayVolume = float(g_iVolume[client])/100;
				if (g_bConsoleSound[client] == false)
				{
					EmitSoundToClient(client, "music/AIF/CMSL.mp3", _, _, _, _,fPlayVolume);
				}
				else EmitSoundToClient(client, "*/common/talk.wav");
			
				//CreateTimer(3.0, ResetHud, client);
			}
		}
			//SetHudTextParams(-1.0, 0.275, 1.0, 0, 255, 0, 255, 0, 0.0, 0.0, 0.0);
			//ShowHudText(client, 1, "%s", buffer);
		
		char sText[256];
		char sCountryTag[3];
		char sIP[26];
		
		bool blocked = (KvGetNum(kv, "blocked", 0)?true:false);
		
		if(blocked)
		{
			KvRewind(kv);
			return Plugin_Stop;
		}
		//&& g_bAutoRetry[client] == true
		KvGetString(kv, "sound", soundp, sizeof(soundp), "default");

		if(g_bConsoleSound[client] == false)
			Format(soundt, 255, "music/AIF/CMSL.mp3");
		else
			Format(soundt, 255, "*/common/talk.wav");		

		for(int i = 1 ; i < MaxClients; i++)
			if(IsClientInGame(i))
			{
				GetClientIP(i, sIP, sizeof(sIP));
				GeoipCode2(sIP, sCountryTag);
				KvGetString(kv, sCountryTag, sText, sizeof(sText), "LANGMISSING");

				if (StrEqual(sText, "LANGMISSING")) KvGetString(kv, "default", sText, sizeof(sText));
				
				CPrintToChat(i, sText);
			}
		if(KvJumpToKey(kv, "hinttext"))
		{
			for(int i = 1 ; i < MaxClients; i++)
				if(IsClientInGame(i))
				{
					GetClientIP(i, sIP, sizeof(sIP));
					GeoipCode2(sIP, sCountryTag);
					KvGetString(kv, sCountryTag, sText, sizeof(sText), "LANGMISSING");

					if (StrEqual(sText, "LANGMISSING")) KvGetString(kv, "default", sText, sizeof(sText));
				
					PrintHintText(i, sText);
				}
		}

		KvRewind(kv);
		return Plugin_Stop;
	}  
	return Plugin_Continue;
}