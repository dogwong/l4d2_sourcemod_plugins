/*
GPLv2
GPLv3
admin_hp.sp

!hp HP management
by dogwong
version: 2.3
release date: 2010-10-10
note: This plugin provides server admin an interface to quickly recover HP for survivors or infected, real player or AI.
In the newer version of this plugin, health regeneration and health recovery point(!ahp) let players able to stand still for HP restoration or built up a recovery point using a first aid kit to heal everyone in the area.
caution: -
While this plugin is in development, this plugin is written / compiled with SourceMod 1.3, as I remember....

!hp生命管理
作者: dogwong
版本: 2.3
推出日期: 2010-10-10
介紹: 此插件提供管理員一個方便回血的介面, 可快速分別地為真人/電腦, 倖存者隊/感染者隊回血, 
後期新版本加入自動補血及回血點功能, 玩家只需站在原地即可自動回血, 及手持藥包可建立回血點, 為附近隊友回血
注意: -
開發此插件時所使用的環境是SourceMod 1.3, 我印象中...

Codes after this comment block are copied from original sp file.
此段註解後的代碼是從原裝的sp檔案中複製
==========================================
*/

#include <sourcemod>
#undef REQUIRE_PLUGIN
#include <adminmenu>
#include <sdktools>
#define PLUGIN_VERSION    "2.3 (15:29 10/10/10)"
#define CVAR_FLAGS FCVAR_PLUGIN
/*
1.0.0.3 (11:11 8/1/10)
2.0.0.0 (12:07 4/7/10)

*/
//new Handle:hAdminMenu = INVALID_HANDLE
new Handle:hp_on_hpregeneration;
new Handle:hp_regeneration_timer;
new Handle:hp_fill_point_timer;
new player_pos[64];
new hp_not_change_time[64];
new last_time_hp[64];
new greenColor[4]	= {0, 255, 0, 20};
new blueColor[4]	= {0, 200, 255, 20};
new Float:hp_fill_point[3];
new Float:hp_fill_time_left = 0.0;
new g_BeamSprite;
new g_HaloSprite;

public Plugin:myinfo =
{
	name = "!hp生命管理",
	author = "dogwong/Marco Chan",//我的第3個插件
	description = "將玩家回血, 加血上限等等",
	version = PLUGIN_VERSION,
	url = "http://www.poheart.com/space.php?uid=4411"
}
public OnPluginStart(){
	hp_on_hpregeneration = CreateConVar("hp_regeneration_onoff", "1", "是否開啟自動補血(0=關, 1=開)", CVAR_FLAGS,true,0.0,true,1.0);
	RegConsoleCmd("ahp", restore_hp_area, "使用範圍補血招式");
	RegAdminCmd("hp", restore_hp, ADMFLAG_ROOT, "回復hp選單");
	RegAdminCmd("hpi", restore_hp_immd, ADMFLAG_ROOT, "即時把所有倖存者回復hp");
	RegAdminCmd("hp_all_survivor", restore_hp_2, ADMFLAG_ROOT, "把所有倖存者回復hp");
	RegAdminCmd("hp_all_real_survivor", restore_hp_3, ADMFLAG_ROOT, "把真人倖存者回復hp");
	RegAdminCmd("hp_all_bot_survivor", restore_hp_4, ADMFLAG_ROOT, "把電腦倖存者回復hp");
	RegAdminCmd("hp_all_specal_infected", restore_hp_5, ADMFLAG_ROOT, "把所有特感回復hp");
	RegAdminCmd("hp_all_real_specal_infected", restore_hp_6, ADMFLAG_ROOT, "把真人特感回復hp");
	RegAdminCmd("hp_all_bot_specal_infected", restore_hp_7, ADMFLAG_ROOT, "把電腦特感回復hp");
	RegAdminCmd("hp_all", restore_hp_8, ADMFLAG_ROOT, "把所有人回復hp");
	RegAdminCmd("hp_all_real", restore_hp_9, ADMFLAG_ROOT, "把所有真人回復hp");
	RegAdminCmd("hp_all_bot", restore_hp_10, ADMFLAG_ROOT, "把所有電腦回復hp");
	RegConsoleCmd("hp_ver", version);
	
	/* new Handle:topmenu;
	if (LibraryExists("adminmenu") && ((topmenu = GetAdminTopMenu()) != INVALID_HANDLE))
	{
		// If so, manually fire the callback 
		OnAdminMenuReady(topmenu);
	}
	*/
	g_BeamSprite = PrecacheModel("materials/sprites/laserbeam.vmt");
	g_HaloSprite = PrecacheModel("materials/sun/overlay.vmt");
}
public Action:hp_regen_func(Handle:timer){
	if (GetConVarInt(hp_on_hpregeneration)){
		//PrintToServer("!");
		for( new i = 1; i < GetMaxClients(); i++ ) {
			if (IsClientInGame( i )){
				if (IsClientConnected( i ) && GetClientTeam(i)==2 && IsPlayerAlive(i) && !IsPlayerIncapped(i) && !IsPlayerGrapEdge(i)) {	//&& !IsFakeClient( i )
					//SetEntityHealth(i, );//GetEntProp(i, Prop_Data, "m_iMaxHealth"));
					if (last_time_hp[i] == GetClientHealth(i)){
						decl Float:player_position[3];
						GetClientEyePosition(i, player_position);
						if (RoundFloat((player_position[0]+player_position[1]+player_position[2])*1000) == player_pos[i]){
							if (GetClientHealth(i)+1 <= GetEntProp(i, Prop_Data, "m_iMaxHealth")){
								SetEntityHealth(i, GetClientHealth(i) + 1);
								new Float:vec[3];
								GetClientAbsOrigin(i, vec);
								vec[2] += 45;
								//TE_SetupBeamRingPoint(vec, 5.0, 60.0, g_BeamSprite, g_HaloSprite, 0, 40, 1.0, 10.0, 0.0, greenColor, 10, 0);
								TE_SetupBeamRingPoint(vec, 60.0, 5.0, g_BeamSprite, g_HaloSprite, 0, 40, 1.0, 10.0, 0.0, greenColor, 10, 0);
								//TE_SetupBeamRingPoint(const Float:center[3], Float:Start_Radius, Float:End_Radius, ModelIndex, HaloIndex, StartFrame, 
								//FrameRate, Float:Life, Float:Width, Float:Amplitude, const Color[4], Speed, Flags)
								TE_SendToAll();
							}
							/*if (!IsFakeClient(i)){
								PrintToChat(i,"+");
							}*/
						}
						/*if (!IsFakeClient(i)){
							PrintToChat(i,"%i==%i", RoundFloat((player_position[0])*1000), player_pos[i]);
						}*/
						player_pos[i] = RoundFloat((player_position[0]+player_position[1]+player_position[2])*1000);// + player_position[1] + player_position[2];
					}
					last_time_hp[i] = GetClientHealth(i);
				}
			}
		}
		//player_pos
	}
}
public Action:hp_fill_point_func(Handle:timer){
	if (hp_fill_time_left > 0.0){
		hp_fill_time_left = hp_fill_time_left - 1.0;
		if (RoundFloat(hp_fill_time_left) % 5 == 0){
			PrintToChatAll("補血點補血中... 效果還有%i秒", RoundFloat(hp_fill_time_left));
		}
		decl Float:player_position[3];
		player_position[0] = hp_fill_point[0];
		player_position[1] = hp_fill_point[1];
		player_position[2] = hp_fill_point[2];
		TE_SetupBeamRingPoint(hp_fill_point, 5.0, 300.0, g_BeamSprite, g_HaloSprite, 0, 40, 1.0, 50.0, 0.0, blueColor, 30, 0);
		TE_SendToAll();
		for( new i = 1; i < GetMaxClients(); i++ ) {
			if (IsClientInGame( i )){
				if (IsClientConnected( i ) && GetClientTeam(i)==2 && IsPlayerAlive(i) && !IsPlayerIncapped(i) && !IsPlayerGrapEdge(i)) {	//&& !IsFakeClient( i )
					//SetEntityHealth(i, );//GetEntProp(i, Prop_Data, "m_iMaxHealth"));
					decl Float:player2_position[3];
					GetClientAbsOrigin(i, player2_position);
					//if (player_position[2] > player2_position[2] - 100 && player_position[2] < player2_position[2] + 100){
					if (150.0 > GetVectorDistance(player2_position, player_position, false)){//SquareRoot((player2_position[0] - player_position[0])*(player2_position[0] - player_position[0]) + (player2_position[1] - player_position[1])*(player2_position[1] - player_position[1]))){
						if (GetClientHealth(i)+2 <= GetEntProp(i, Prop_Data, "m_iMaxHealth")){
							SetEntityHealth(i, GetClientHealth(i) + 2);
							new Float:vec[3];
							GetClientAbsOrigin(i, vec);
							vec[2] += 45;
							TE_SetupBeamRingPoint(vec, 60.0, 5.0, g_BeamSprite, g_HaloSprite, 0, 40, 0.6, 10.0, 0.0, blueColor, 10, 0);
							//TE_SetupBeamRingPoint(const Float:center[3], Float:Start_Radius, Float:End_Radius, ModelIndex, HaloIndex, StartFrame, 
							//FrameRate, Float:Life, Float:Width, Float:Amplitude, const Color[4], Speed, Flags)
							TE_SendToAll();
						} else if (GetClientHealth(i) < GetEntProp(i, Prop_Data, "m_iMaxHealth")) {
							SetEntityHealth(i, GetEntProp(i, Prop_Data, "m_iMaxHealth"));
							new Float:vec[3];
							GetClientAbsOrigin(i, vec);
							vec[2] += 45;
							TE_SetupBeamRingPoint(vec, 60.0, 5.0, g_BeamSprite, g_HaloSprite, 0, 40, 0.6, 10.0, 0.0, blueColor, 10, 0);
							//TE_SetupBeamRingPoint(const Float:center[3], Float:Start_Radius, Float:End_Radius, ModelIndex, HaloIndex, StartFrame, 
							//FrameRate, Float:Life, Float:Width, Float:Amplitude, const Color[4], Speed, Flags)
							TE_SendToAll();
						}
					}
					//}
					/*if (!IsFakeClient(i)){
						PrintToChat(i,"%i==%i", RoundFloat((player_position[0])*1000), player_pos[i]);
					}*/
				}
			}
		}
	}
}
public OnMapStart(){
	hp_regeneration_timer = CreateTimer(1.5, hp_regen_func, _, TIMER_REPEAT);
	hp_fill_point_timer = CreateTimer(1.0, hp_fill_point_func, _, TIMER_REPEAT);
	g_BeamSprite = PrecacheModel("materials/sprites/laserbeam.vmt");
	g_HaloSprite = PrecacheModel("materials/sun/overlay.vmt");
}
public OnMapEnd(){
	KillTimer(hp_regeneration_timer);
	KillTimer(hp_fill_point_timer);
}
/*
public OnLibraryRemoved(const String:name[])
{
	if (StrEqual(name, "adminmenu"))
	{
		hAdminMenu = INVALID_HANDLE;
	}
}
 
public OnAdminMenuReady(Handle:topmenu)
{
	// Block us from being called twice 
	if (topmenu == hAdminMenu)
	{
		return;
	}
 
	// :TODO: Add everything to the menu! 
	
	hAdminMenu = topmenu;
	
	new TopMenuObject:player_commands = FindTopMenuCategory(hAdminMenu, ADMINMENU_PLAYERCOMMANDS);
	if (player_commands != INVALID_TOPMENUOBJECT)
	{
		AddToTopMenu(hAdminMenu, "sm_poke", TopMenuObject_Item, AdminMenu_Poke, player_commands, "sm_poke", ADMFLAG_SLAY);
	}
}
public AdminMenu_Poke(Handle:topmenu, 
			TopMenuAction:action,
			TopMenuObject:object_id,
			param,
			String:buffer[],
			maxlength)
{
	if (action == TopMenuAction_DisplayOption)
	{
		Format(buffer, maxlength, "Poke");
	}
	else if (action == TopMenuAction_SelectOption)
	{
		// Do something! client who selected item is in param 
		PrintToChatAll("!");
	}
}
*/
public Action:restore_hp_immd(client, args){
	for( new i = 1; i < GetMaxClients(); i++ ) {
		if (IsClientInGame( i )){
			if (IsClientConnected( i ) && GetClientTeam(i)==2 ) {	//&& !IsFakeClient( i )
				SetEntityHealth(i, GetEntProp(i, Prop_Data, "m_iMaxHealth"));
			}
		}
	}
	PrintToChatAll("\x01[SM]\x05管理員\x04[%N]\x01把\x04所有倖存者\x03回滿血", client);
	PrintToServer("[SM]管理員[%N]把所有倖存者回滿血", client);
	return Plugin_Handled;
}
new String:weapon[32];
public Action:restore_hp_area(client, args){
	if (client>0){
	GetClientWeapon(client, weapon, 32);
	//PrintToChat(client, "%s", weapon);
		if (StrEqual(weapon, "weapon_first_aid_kit")){
			if (hp_fill_time_left <= 0.0){
				hp_fill_time_left = 10.0;
				//PrintToChat(client, "ok");
				PrintToChatAll("%N使用了!ahp建立範圍回血點", client);
				PrintToServer("%N使用了!ahp建立範圍回血點", client);
				RemovePlayerItem(client, GetPlayerWeaponSlot(client, 3));
				decl Float:player_position[3];
				new Float:vec[3];
				GetClientAbsOrigin(client, vec);
				vec[2] += 30;
				hp_fill_point = vec;
				//TE_SetupBeamRingPoint(vec, 5.0, 250.0, g_BeamSprite, g_HaloSprite, 0, 40, 0.5, 40.0, 0.0, blueColor, 30, 0);
				//TE_SendToAll();
			} else {
				new Float:vec[3];
				GetClientAbsOrigin(client, vec);
				vec[2] += 30;
				if (150.0 > GetVectorDistance(vec, hp_fill_point, false)){
					RemovePlayerItem(client, GetPlayerWeaponSlot(client, 3));
					PrintToChatAll("%N加長了回血點的有效時間!", client);
					PrintToServer("%N加長了回血點的有效時間!", client);
					hp_fill_time_left = hp_fill_time_left+15.0;
				} else {
					PrintToChat(client, "已有其他的回血點, 請在回血點補完血後再建立或在已有的回血點上使用此指令, 加長回血點有效時間");
				}
			}
			/*
			GetClientAbsOrigin(client, player_position);
			for( new i = 1; i < GetMaxClients(); i++ ) {
				if (IsClientInGame( i )){
					if (IsClientConnected( i ) && GetClientTeam(i)==2 && IsPlayerAlive(i) && !IsPlayerIncapped(i) && !IsPlayerGrapEdge(i)) {	//&& !IsFakeClient( i )
						//SetEntityHealth(i, );//GetEntProp(i, Prop_Data, "m_iMaxHealth"));
						decl Float:player2_position[3];
						GetClientAbsOrigin(i, player2_position);
						//if (player_position[2] > player2_position[2] - 100 && player_position[2] < player2_position[2] + 100){
						if (125.0 > GetVectorDistance(player2_position, player_position, false)){//SquareRoot((player2_position[0] - player_position[0])*(player2_position[0] - player_position[0]) + (player2_position[1] - player_position[1])*(player2_position[1] - player_position[1]))){
							if (GetClientHealth(i)+20 <= GetEntProp(i, Prop_Data, "m_iMaxHealth")){
								SetEntityHealth(i, GetClientHealth(i) + 20);
								//new Float:vec[3];
								GetClientAbsOrigin(i, vec);
								vec[2] += 45;
								TE_SetupBeamRingPoint(vec, 60.0, 5.0, g_BeamSprite, g_HaloSprite, 0, 40, 0.6, 10.0, 0.0, blueColor, 10, 0);
								//TE_SetupBeamRingPoint(const Float:center[3], Float:Start_Radius, Float:End_Radius, ModelIndex, HaloIndex, StartFrame, 
								//FrameRate, Float:Life, Float:Width, Float:Amplitude, const Color[4], Speed, Flags)
								TE_SendToAll();
							} else if (GetClientHealth(i) < GetEntProp(i, Prop_Data, "m_iMaxHealth")) {
								SetEntityHealth(i, GetEntProp(i, Prop_Data, "m_iMaxHealth"));
								//new Float:vec[3];
								GetClientAbsOrigin(i, vec);
								vec[2] += 45;
								TE_SetupBeamRingPoint(vec, 60.0, 5.0, g_BeamSprite, g_HaloSprite, 0, 40, 0.6, 10.0, 0.0, blueColor, 10, 0);
								//TE_SetupBeamRingPoint(const Float:center[3], Float:Start_Radius, Float:End_Radius, ModelIndex, HaloIndex, StartFrame, 
								//FrameRate, Float:Life, Float:Width, Float:Amplitude, const Color[4], Speed, Flags)
								TE_SendToAll();
							}
						}
						//}
						//if (!IsFakeClient(i)){
						//	PrintToChat(i,"%i==%i", RoundFloat((player_position[0])*1000), player_pos[i]);
						//}
					}
				}
			}*/
			
		} else {
			PrintToChat(client, "請先手持藥包!");
		}
	} else {
		PrintToServer("只供遊戲內玩家使用");
	}
	return Plugin_Handled;
}
public Action:restore_hp(client, args){
	if (client>0){
		new Handle:hPl = CreateMenu(join_game_meun);
		SetMenuTitle(hPl, "誰要回復hp?");
		AddMenuItem(hPl, "option1", "自己");
		AddMenuItem(hPl, "option2", "所有倖存者");
		AddMenuItem(hPl, "option3", "真人倖存者");
		AddMenuItem(hPl, "option4", "電腦倖存者");
		AddMenuItem(hPl, "option5", "所有特感");
		AddMenuItem(hPl, "option6", "真人特感");
		AddMenuItem(hPl, "option7", "電腦特感");
		AddMenuItem(hPl, "option8", "所有人");
		AddMenuItem(hPl, "option9", "所有真人");
		AddMenuItem(hPl, "option10", "所有電腦");
		DisplayMenu(hPl, client, 60);
	} else {
		PrintToServer("!hp只供遊戲內玩家使用, 伺服器端請使用以下指令:\nhp_all_survivor - 把所有倖存者回復hp\nhp_all_real_survivor - 把真人倖存者回復hp\nhp_all_bot_survivor - 把電腦倖存者回復hp\n要回復特感血請將survivor改為specal_infected\n要回復所有人請刪除_survivor");
	}
	return Plugin_Handled;
}
public join_game_meun(Handle:menu, MenuAction:action, client, itemNum){
	new flags_give = GetCommandFlags("give");
	SetCommandFlags("give", flags_give & ~FCVAR_CHEAT);	
	decl String:name[128];
	GetClientName(client, name, sizeof(name)); 
	if ( action == MenuAction_Select ){
		if(itemNum == 0){
			if (IsClientInGame( client )){
				if (IsClientConnected( client )) {	//&& !IsFakeClient( i )
					FakeClientCommand(client, "give health");
				}
			}
			PrintToChatAll("\x01[SM]\x05管理員\x04[%N]\x01把\x04自己\x03回滿血", client);
			PrintToServer("[SM]管理員[%N]把自己回滿血", client);
		} else if(itemNum == 1){
			for( new i = 1; i < GetMaxClients(); i++ ) {
				if (IsClientInGame( i )){
					if (IsClientConnected( i ) && GetClientTeam(i)==2 ) {	//&& !IsFakeClient( i )
						FakeClientCommand(i, "give health");
					}
				}
			}
			PrintToChatAll("\x01[SM]\x05管理員\x04[%N]\x01把\x04所有倖存者\x03回滿血", client);
			PrintToServer("[SM]管理員[%N]把所有倖存者回滿血", client);
		} else if(itemNum == 2){
			for( new i = 1; i < GetMaxClients(); i++ ) {
				if (IsClientInGame( i )){
					if (IsClientConnected( i ) && GetClientTeam(i)==2 && !IsFakeClient(i) ) {	//&& !IsFakeClient( i )
						FakeClientCommand(i, "give health");
					}
				}
			}
			PrintToChatAll("\x01[SM]\x05管理員\x04[%N]\x01把\x04真人倖存者\x03回滿血", client);
			PrintToServer("[SM]管理員[%N]把真人倖存者回滿血", client);
		} else if(itemNum == 3){
			for( new i = 1; i < GetMaxClients(); i++ ) {
				if (IsClientInGame( i )){
					if (IsClientConnected( i ) && GetClientTeam(i)==2 && IsFakeClient(i) ) {	//&& !IsFakeClient( i )
						FakeClientCommand(i, "give health");
					}
				}
			}
			PrintToChatAll("\x01[SM]\x05管理員\x04[%N]\x01把\x04電腦倖存者\x03回滿血", client);
			PrintToServer("[SM]管理員[%N]把電腦倖存者回滿血", client);
		} else if(itemNum == 4){
			for( new i = 1; i < GetMaxClients(); i++ ) {
				if (IsClientInGame( i )){
					if (IsClientConnected( i ) && GetClientTeam(i)==3) {	//&& !IsFakeClient( i )
						FakeClientCommand(i, "give health");
					}
				}
			}
			PrintToChatAll("\x01[SM]\x05管理員\x04[%N]\x01把\x04所有特感\x03回滿血", client);
			PrintToServer("[SM]管理員[%N]把所有特感回滿血", client);
		} else if(itemNum == 5){
			for( new i = 1; i < GetMaxClients(); i++ ) {
				if (IsClientInGame( i )){
					if (IsClientConnected( i ) && GetClientTeam(i)==3 && !IsFakeClient(i) ) {	//&& !IsFakeClient( i )
						FakeClientCommand(i, "give health");
					}
				}
			}
			PrintToChatAll("\x01[SM]\x05管理員\x04[%N]\x01把\x04真人特感\x03回滿血", client);
			PrintToServer("[SM]管理員[%N]把真人特感回滿血", client);
		} else if(itemNum == 6){
			for( new i = 1; i < GetMaxClients(); i++ ) {
				if (IsClientInGame( i )){
					if (IsClientConnected( i ) && GetClientTeam(i)==3 && IsFakeClient(i) ) {	//&& !IsFakeClient( i )
						FakeClientCommand(i, "give health");
					}
				}
			}
			PrintToChatAll("\x01[SM]\x05管理員\x04[%N]\x01把\x04電腦特感\x03回滿血", client);
			PrintToServer("[SM]管理員[%N]把電腦特感回滿血", client);
		} else if(itemNum == 7){
			for( new i = 1; i < GetMaxClients(); i++ ) {
				if (IsClientInGame( i )){
					if (IsClientConnected( i )) {	//&& !IsFakeClient( i )
						FakeClientCommand(i, "give health");
					}
				}
			}
			PrintToChatAll("\x01[SM]\x05管理員\x04[%N]\x01把\x04所有人\x03回滿血", client);
			PrintToServer("[SM]管理員[%N]把所有人回滿血", client);
		} else if(itemNum == 8){
			for( new i = 1; i < GetMaxClients(); i++ ) {
				if (IsClientInGame( i )){
					if (IsClientConnected( i ) && !IsFakeClient(i) ) {	//&& !IsFakeClient( i )
						FakeClientCommand(i, "give health");
					}
				}
			}
			PrintToChatAll("\x01[SM]\x05管理員\x04[%N]\x01把\x04所有真人\x03回滿血", client);
			PrintToServer("[SM]管理員[%N]把所有真人回滿血", client);
		} else if(itemNum == 9){
			for( new i = 1; i < GetMaxClients(); i++ ) {
				if (IsClientInGame( i )){
					if (IsClientConnected( i ) && IsFakeClient(i) ) {	//&& !IsFakeClient( i )
						FakeClientCommand(i, "give health");
					}
				}
			}
			PrintToChatAll("\x01[SM]\x05管理員\x04[%N]\x01把\x04所有電腦\x03回滿血", client);
			PrintToServer("[SM]管理員[%N]把所有電腦回滿血", client);
		}
	}
	SetCommandFlags("give", flags_give|FCVAR_CHEAT);
}
public Action:restore_hp_2(client, args){
	new flags_give = GetCommandFlags("give");
	SetCommandFlags("give", flags_give & ~FCVAR_CHEAT);	
	if (client<=0){
		for( new i = 1; i < GetMaxClients(); i++ ) {
			if (IsClientInGame( i )){
				if (IsClientConnected( i ) && GetClientTeam(i)==2) {	//&& !IsFakeClient( i )
					FakeClientCommand(i, "give health");
				}
			}
		}
		PrintToChatAll("\x01[SM]\x05伺服器\x01把\x04所有倖存者\x03回滿血");
		PrintToServer("[SM]伺服器把所有倖存者回滿血");
	} else {
		PrintToChat(client, "此指令只供伺服器端使用");
	}
	SetCommandFlags("give", flags_give|FCVAR_CHEAT);
	return Plugin_Handled;
}
public Action:restore_hp_3(client, args){
	new flags_give = GetCommandFlags("give");
	SetCommandFlags("give", flags_give & ~FCVAR_CHEAT);
	if (client<=0){
		for( new i = 1; i < GetMaxClients(); i++ ) {
			if (IsClientInGame( i )){
				if (IsClientConnected( i ) && GetClientTeam(i)==2 && !IsFakeClient(i) ) {	//&& !IsFakeClient( i )
					FakeClientCommand(i, "give health");
				}
			}
		}
		PrintToChatAll("\x01[SM]\x05伺服器\x01把\x04真人倖存者\x03回滿血");
		PrintToServer("[SM]伺服器把真人倖存者回滿血");
	} else {
		PrintToChat(client, "此指令只供伺服器端使用");
	}
	SetCommandFlags("give", flags_give|FCVAR_CHEAT);
	return Plugin_Handled;
}
public Action:restore_hp_4(client, args){
	new flags_give = GetCommandFlags("give");
	SetCommandFlags("give", flags_give & ~FCVAR_CHEAT);
	if (client<=0){
		for( new i = 1; i < GetMaxClients(); i++ ) {
			if (IsClientInGame( i )){
				if (IsClientConnected( i ) && GetClientTeam(i)==2 && IsFakeClient(i) ) {	//&& !IsFakeClient( i )
					FakeClientCommand(i, "give health");
				}
			}
		}
		PrintToChatAll("\x01[SM]\x05伺服器\x01把\x04電腦倖存者\x03回滿血");
		PrintToServer("[SM]伺服器把電腦倖存者回滿血");
	} else {
		PrintToChat(client, "此指令只供伺服器端使用");
	}
	SetCommandFlags("give", flags_give|FCVAR_CHEAT);
	return Plugin_Handled;
}
public Action:restore_hp_5(client, args){
	new flags_give = GetCommandFlags("give");
	SetCommandFlags("give", flags_give & ~FCVAR_CHEAT);
	if (client<=0){
		for( new i = 1; i < GetMaxClients(); i++ ) {
			if (IsClientInGame( i )){
				if (IsClientConnected( i ) && GetClientTeam(i)==3) {	//&& !IsFakeClient( i )
					FakeClientCommand(i, "give health");
				}
			}
		}
		PrintToChatAll("\x01[SM]\x05伺服器\x01把\x04所有特感\x03回滿血");
		PrintToServer("[SM]伺服器把所有特感回滿血");
	} else {
		PrintToChat(client, "此指令只供伺服器端使用");
	}
	SetCommandFlags("give", flags_give|FCVAR_CHEAT);
	return Plugin_Handled;
}
public Action:restore_hp_6(client, args){
	new flags_give = GetCommandFlags("give");
	SetCommandFlags("give", flags_give & ~FCVAR_CHEAT);
	if (client<=0){
		for( new i = 1; i < GetMaxClients(); i++ ) {
			if (IsClientInGame( i )){
				if (IsClientConnected( i ) && GetClientTeam(i)==3 && !IsFakeClient(i) ) {	//&& !IsFakeClient( i )
					FakeClientCommand(i, "give health");
				}
			}
		}
		PrintToChatAll("\x01[SM]\x05伺服器\x01把\x04真人特感\x03回滿血");
		PrintToServer("[SM]伺服器把真人特感回滿血");
	} else {
		PrintToChat(client, "此指令只供伺服器端使用");
	}
	SetCommandFlags("give", flags_give|FCVAR_CHEAT);
	return Plugin_Handled;
}
public Action:restore_hp_7(client, args){
	new flags_give = GetCommandFlags("give");
	SetCommandFlags("give", flags_give & ~FCVAR_CHEAT);
	if (client<=0){
		for( new i = 1; i < GetMaxClients(); i++ ) {
			if (IsClientInGame( i )){
				if (IsClientConnected( i ) && GetClientTeam(i)==3 && IsFakeClient(i) ) {	//&& !IsFakeClient( i )
					FakeClientCommand(i, "give health");
				}
			}
		}
		PrintToChatAll("\x01[SM]\x05伺服器\x01把\x04電腦特感\x03回滿血");
		PrintToServer("[SM]伺服器把電腦特感回滿血");
	} else {
		PrintToChat(client, "此指令只供伺服器端使用");
	}
	SetCommandFlags("give", flags_give|FCVAR_CHEAT);
	return Plugin_Handled;
}
public Action:restore_hp_8(client, args){
	new flags_give = GetCommandFlags("give");
	SetCommandFlags("give", flags_give & ~FCVAR_CHEAT);
	if (client<=0){
		for( new i = 1; i < GetMaxClients(); i++ ) {
			if (IsClientInGame( i )){
				if (IsClientConnected( i )) {
					FakeClientCommand(i, "give health");
				}
			}
		}
		PrintToChatAll("\x01[SM]\x05伺服器\x01把\x04所有人\x03回滿血");
		PrintToServer("[SM]伺服器把所有人回滿血");
	} else {
		PrintToChat(client, "此指令只供伺服器端使用");
	}
	SetCommandFlags("give", flags_give|FCVAR_CHEAT);
	return Plugin_Handled;
}
public Action:restore_hp_9(client, args){
	new flags_give = GetCommandFlags("give");
	SetCommandFlags("give", flags_give & ~FCVAR_CHEAT);
	if (client<=0){
		for( new i = 1; i < GetMaxClients(); i++ ) {
			if (IsClientInGame( i )){
				if (IsClientConnected( i ) && !IsFakeClient(i) ) {
					FakeClientCommand(i, "give health");
				}
			}
		}
		PrintToChatAll("\x01[SM]\x05伺服器\x01把\x04所有真人\x03回滿血");
		PrintToServer("[SM]伺服器把所有真人回滿血");
	} else {
		PrintToChat(client, "此指令只供伺服器端使用");
	}
	SetCommandFlags("give", flags_give|FCVAR_CHEAT);
	return Plugin_Handled;
}
public Action:restore_hp_10(client, args){
	new flags_give = GetCommandFlags("give");
	SetCommandFlags("give", flags_give & ~FCVAR_CHEAT);
	if (client<=0){
		for( new i = 1; i < GetMaxClients(); i++ ) {
			if (IsClientInGame( i )){
				if (IsClientConnected( i ) && IsFakeClient(i) ) {
					FakeClientCommand(i, "give health");
				}
			}
		}
		PrintToChatAll("\x01[SM]\x05伺服器\x01把\x04所有電腦\x03回滿血");
		PrintToServer("[SM]伺服器把所有電腦回滿血");
	} else {
		PrintToChat(client, "此指令只供伺服器端使用");
	}
	SetCommandFlags("give", flags_give|FCVAR_CHEAT);
	return Plugin_Handled;
}
new buttons;
public Action:version(client, args){
	if (client>0){
		PrintToChat(client, "hp回復v%s", PLUGIN_VERSION);
		/*
		decl Float:player_position[3];
		GetClientEyePosition(client, player_position);
		decl bool:a, bool:b;
		a=false;
		b=false;
		if ((buttons & IN_DUCK)) a=true;
		if ((buttons & IN_USE)) b=true;
		buttons = GetClientButtons(client);
		new Float:vec[3];
		GetClientAbsOrigin(client, vec);
		vec[2] += 30;
		PrintToChat(client, "duck:%i / use:%i, %f", a, b, SquareRoot(2.0));
		//TE_SetupBeamRingPoint(const Float:center[3], Float:Start_Radius, Float:End_Radius, ModelIndex, HaloIndex, StartFrame, 
		//FrameRate, Float:Life, Float:Width, Float:Amplitude, const Color[4], Speed, Flags)
		//SetEntityHealth(client, GetClientHealth(client) + 1);
		/////TE_SetupBeamRingPoint(vec, 5.0, 250.0, g_BeamSprite, g_HaloSprite, 0, 40, 0.5, 60.0, 0.0, blueColor, 30, 0);
		/////TE_SendToAll();
		//decl Float:player_position[3];
		GetClientAbsOrigin(client, player_position);
		for( new i = 1; i < GetMaxClients(); i++ ) {
			if (IsClientInGame( i )){
				if (IsClientConnected( i ) && GetClientTeam(i)==2 && IsPlayerAlive(i) && !IsPlayerIncapped(i) && !IsPlayerGrapEdge(i)) {	//&& !IsFakeClient( i )
					//SetEntityHealth(i, );//GetEntProp(i, Prop_Data, "m_iMaxHealth"));
						decl Float:player2_position[3];
						GetClientAbsOrigin(i, player2_position);
						//if (player_position[2] > player2_position[2] - 100 && player_position[2] < player2_position[2] + 100){
						PrintToChat(client, "%f, %f", GetVectorDistance(player2_position, player_position, false), GetVectorDistance(player2_position, player_position, true));
							if (125.0 > GetVectorDistance(player2_position, player_position, false)){//SquareRoot((player2_position[0] - player_position[0])*(player2_position[0] - player_position[0]) + (player2_position[1] - player_position[1])*(player2_position[1] - player_position[1]))){
								if (GetClientHealth(i)+20 <= GetEntProp(i, Prop_Data, "m_iMaxHealth")){
									SetEntityHealth(i, GetClientHealth(i) + 20);
									new Float:vec[3];
									GetClientAbsOrigin(i, vec);
									vec[2] += 45;
									TE_SetupBeamRingPoint(vec, 60.0, 5.0, g_BeamSprite, g_HaloSprite, 0, 40, 0.6, 10.0, 0.0, blueColor, 10, 0);
									//TE_SetupBeamRingPoint(const Float:center[3], Float:Start_Radius, Float:End_Radius, ModelIndex, HaloIndex, StartFrame, 
									//FrameRate, Float:Life, Float:Width, Float:Amplitude, const Color[4], Speed, Flags)
									TE_SendToAll();
								} else if (GetClientHealth(i) < GetEntProp(i, Prop_Data, "m_iMaxHealth")) {
									SetEntityHealth(i, GetEntProp(i, Prop_Data, "m_iMaxHealth"));
									new Float:vec[3];
									GetClientAbsOrigin(i, vec);
									vec[2] += 45;
									TE_SetupBeamRingPoint(vec, 60.0, 5.0, g_BeamSprite, g_HaloSprite, 0, 40, 0.6, 10.0, 0.0, blueColor, 10, 0);
									//TE_SetupBeamRingPoint(const Float:center[3], Float:Start_Radius, Float:End_Radius, ModelIndex, HaloIndex, StartFrame, 
									//FrameRate, Float:Life, Float:Width, Float:Amplitude, const Color[4], Speed, Flags)
									TE_SendToAll();
								}
							}
						//}
						//if (!IsFakeClient(i)){
						//	PrintToChat(i,"%i==%i", RoundFloat((player_position[0])*1000), player_pos[i]);
						//}
				}
			}
		}
		*/
	} else {
		PrintToServer("hp回復v%s", PLUGIN_VERSION);
	}
	return Plugin_Handled;
}
bool:IsPlayerIncapped(client)
{
	if (GetEntProp(client, Prop_Send, "m_isIncapacitated", 1)) return true;
 	return false;
}
bool:IsPlayerGrapEdge(client)
{
 	if (GetEntProp(client, Prop_Send, "m_isHangingFromLedge", 1))return true;
	return false;
}
