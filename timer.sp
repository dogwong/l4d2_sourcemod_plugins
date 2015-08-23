/*

GPLv2
GPLv3

timer.sp
L4D2 timer 
by dogwong

version: 1.1.4.40
release date: 2010-01-28

note: This plugin use to count how long do the players used to finish a map or whole campaign, something like time attack
caution: Only support c1 - c5 (first 5 offical maps of L4D2)

While this plugin is in development, this plugin is written / compiled with SourceMod 1.2, as I remember.

L4D2 計時器
作者: dogwong

版本: 1.1.4.40
推出日期: 2010-01-28

介紹: 此插件用作計玩家完成一個關卡或整個故事的時間長度, 像時間競賽模式一樣
注意: 只支援c1 - c5地圖 (L4D2的首5個官方地圖)

開發此插件時所使用的環境是SourceMod 1.2, 我印象中...


*/

#include <sourcemod>
#define PLUGIN_VERSION    "1.1.4.40 (20:23 28-1-2010)"
#define BEBOP_LOG_PATH						"logs\\L4D2_timer.log"

/*
更新列表:
1.1.4.40 (20:23 28-1-2010)
修正:當伺服器因全部玩家離開而遊戲完結後, 遊戲可被暫停
1.1.4.39 (20:34 27-1-2010)
更正:死亡倒數開始後倖存者擊潰後重新開始, 計時會繼續
更正:死亡倒數開始後倖存者擊潰後重新開始, 總時間及地圖時間繼續
更改:死亡倒數的提示字眼
新增:死亡倒數, 未進入安全室的人會特別提醒他未進入
1.1.4.38 (19:24 8-1-2010)
更正:tto_safe不能在伺服器端執行
刪除:timer_load_record及timer_write_record指令
更改:L4D2_timer.cfg現在會每時地圖完結都會讀取
1.1.4.37	取消:在對話框的提示計時開始信息
			新增:載入地圖後暫停遊戲一段時間
			新增:關閉每?秒就提醒目前時間及最佳時間的通知
			新增:一半玩家進入安全室後一定時間就會將未進入安全室的玩家殺掉
1.1.3.36	新增:章節最佳時間功能
			更改:部份形容最佳時間的字眼, 讓章節紀錄及戰役紀錄不會混淆
			更正:新戰役時間紀錄提示中, 舊紀錄時間, 秒數的小數計錯
			更改:新戰役時間紀錄提示中, 新紀錄時間, 分鐘的計算方法
1.0.3.35	更正:計時器廣告不依時廣播
			更正:戰役完成後第2次通知時間時此地圖時間沒有小數
			取消:於地圖開始後, 計時開始前會不停讀取L4D2_Timer_record.txt
			更正:破不到紀錄沒有提示
			更正:教區-橋提示計時開始訊息錯誤
1.0.3.34	更正:總時間無故重設及重新開始同一戰役時不重設時間
1.0.3.33	新增:所有時間紀錄用sourcemod/configs/L4D2_Timer_record.txt儲存
			更正:計時器廣告有時不能運作
			更改:戰役完結後新紀錄提示將c1, c2等名稱改為戰役名稱
			新增:如地圖未有最佳紀錄會於每一定時間提示的框內, 提示開門會開始的框通知
			取消:各地圖最佳紀錄的console variable(convar)
			新增:破新戰役紀錄後log檔案中會寫舊紀錄時間
			更改:戰役完結時的舊及新紀錄時間的計算方法
			更正:提示開門會開始的框內的最佳時間長期是120分鐘
1.0.2.32	更改:此插件不會自動生成/讀取L4D2_timer.cfg, 因為會令最佳時間消失
			更改:總時間,地圖時間變數處理
			更正:距離最佳時間30秒提示中時間差1秒
			更改:重開tcfg_load指令
1.0.2.31	更改:戰役完結中此地圖時間改為會出到 x分鐘x.x秒
			新增:可設定計時器廣告內容及每次發布時間
			新增:戰役完結後破不到最佳紀錄會提示
			更正:戰役新紀錄log輸出新紀錄時間錯誤
			更改:"離開安全區...計時會立即開始, 目前時間:"加上最佳時間
1.0.2.30	新增:tvalid指令, 可將已作廢的時間變回有效
			新增:難易度變更前與難易度變更後的難易度一樣不會使計時作廢
			更正:每一章節完結後都會把戰役時間作廢
1.0.2.29	更正:應該只有戰役時間作廢仍會在log裹顯示"此戰役及章節時間作廢"
			新增:戰役及章節完結後的log會增加已過的0.1秒數(即用作設定最佳紀錄的數字)
			更正:log輸出, 章節因OnMapEnd而停止計時但在log中寫round_end
			更改:計時器廣告加插件版本
1.0.2.28	新增:log檔案輸出
1.0.1.28	刪除:取消round_end動作
			更正:最佳紀錄已過仍會提示還有多久
			更正:計時開始後有時仍會出現離開安全匿區/室時開始計時的訊息
			刪除:取消1.0.1.26的「計時開始後...」的更正
			更改:tshow_ad內測指令可於server端輸出
1.0.1.26	更正:計時開始後有時仍會出現離開安全匿區/室時開始計時的訊息
			新增:提示距離最佳紀錄還有?.?秒
			新增:tcfg_load指令
1.0.1.25	更正:c5m5地圖時門口不應即開始計時

*/

new int:time_passed = 0;
new int:time_passed_single_map = 0;
new timer_control = 0;
new int:ad_which = 7;
new timer_ad;
new ad_timer;
new ad_tick = 5;
new timer_long_show = 0;
new time_remind_interval;
new timer_auto_start;
new timer_start_reminder = 0;
new timer_ver;
new string:now_game[5];
static String:	logfilepath[256];
new timer_ad_interval
new timer_ad_content
new record_file
new int:first_enter_user = 0;
new entered[48];
//
new int:unpause_countdown = 0;
new unpause_time
new unpause_timer;
new safe_kill_timer;
new int:safe_kill_time;
new timer_safe_kill_time;

//record
new Handle:record_list = INVALID_HANDLE;
new int:record_valid = 2;//0=全無效, 1=章節有效 2=全有效
//new int:best_time = 72000;
new int:record_c1_impossible = 0;
new int:record_c2_impossible = 0;
new int:record_c3_impossible = 0;
new int:record_c4_impossible = 0;
new int:record_c5_impossible = 0;
new int:record_c1m1_impossible = 0;
new int:record_c1m2_impossible = 0;
new int:record_c1m3_impossible = 0;
new int:record_c1m4_impossible = 0;
new int:record_c2m1_impossible = 0;
new int:record_c2m2_impossible = 0;
new int:record_c2m3_impossible = 0;
new int:record_c2m4_impossible = 0;
new int:record_c2m5_impossible = 0;
new int:record_c3m1_impossible = 0;
new int:record_c3m2_impossible = 0;
new int:record_c3m3_impossible = 0;
new int:record_c3m4_impossible = 0;
new int:record_c4m1_impossible = 0;
new int:record_c4m2_impossible = 0;
new int:record_c4m3_impossible = 0;
new int:record_c4m4_impossible = 0;
new int:record_c4m5_impossible = 0;
new int:record_c5m1_impossible = 0;
new int:record_c5m2_impossible = 0;
new int:record_c5m3_impossible = 0;
new int:record_c5m4_impossible = 0;
new int:record_c5m5_impossible = 0;
new Handle:game_pauseable;
	


//users注意:計時器插件更新, 所有最佳紀錄暫停
new player1 = "";
new player2 = "";
new player3 = "";
new player4 = "";
new player5 = "";
new player6 = "";
new player7 = "";
new player8 = "";

#define CVAR_FLAGS FCVAR_PLUGIN

public Plugin:myinfo =
{
	name = "Timer",
	author = "dogwong/Marco Chan",//我的第1個插件
	description = "Timer",
	version = PLUGIN_VERSION,
	url = "http://www.poheart.com/space.php?uid=4411"
}
public OnPluginStart()
{
	timer_ver = CreateConVar("timer_version", PLUGIN_VERSION, "計時器版本", CVAR_FLAGS);
	timer_ad = CreateConVar("timer_ad", "0", "計時器廣告開關", CVAR_FLAGS,true,0.0,true,1.0);
	time_remind_interval = CreateConVar("timer_remind_interval", "150", "計時器每隔多少個0.1秒便提醒(10代表1秒, 0代表關閉)", CVAR_FLAGS,true,0);
	timer_ad_interval = CreateConVar("timer_ad_interval", "80", "計時器每隔多少個0.1秒便發表計時器廣告(10代表1秒)", CVAR_FLAGS,true,1);
	timer_ad_content = CreateConVar("timer_ad_content", "計時器啟動中!完成章節及戰役的時間會被紀錄(只限專家難道)", "計時器廣告內容([L4D2計時器vX.X.X.X會自動加上])", CVAR_FLAGS);
	timer_auto_start = CreateConVar("timer_auto_start", "1", "計時器當在玩家離開安全區/安全室時自動啟動", CVAR_FLAGS,true,0.0,true,1.0);
	timer_safe_kill_time = CreateConVar("timer_saferoom_time", "30", "當一半玩家進入安全室後, 多少秒後便將未進入的玩家殺掉(1代表1秒, 0代表關閉)", CVAR_FLAGS,true,0.0,true,60.0);
	unpause_time = CreateConVar("timer_unpause_time", "30", "每次伺服器端載入完成後會暫停遊戲多久(1代表1秒, 0代表關閉)", CVAR_FLAGS,true,0.0,true,60.0);
	game_pauseable = FindConVar("sv_pausable");
	SetConVarInt(game_pauseable, 0);
	//SetConVarString(timer_ver, PLUGIN_VERSION, false, false);
	//ResetConVar(timer_ver, false, false);
	
	RegConsoleCmd("time", show_now_time);
	RegAdminCmd("tstart", timer_start, ADMFLAG_GENERIC);
	RegAdminCmd("tstop", timer_stop, ADMFLAG_GENERIC);
	RegAdminCmd("treset", timer_reset, ADMFLAG_GENERIC);
	RegAdminCmd("tshow", timer_show_second, ADMFLAG_GENERIC);
	RegAdminCmd("tshowf", timer_show_forever, ADMFLAG_GENERIC);
	RegAdminCmd("tvalid", timer_become_valid, ADMFLAG_GENERIC);
	RegAdminCmd("tto_start", timer_warp_to_start, ADMFLAG_GENERIC);
	RegAdminCmd("tto_safe", timer_warp_to_checkpoint, ADMFLAG_GENERIC);
	RegAdminCmd("tunpause", timer_unpause, ADMFLAG_GENERIC);
	RegAdminCmd("tno_kill", timer_stop_safe_kill, ADMFLAG_GENERIC);
	RegConsoleCmd("tmap", timer_map);
	RegConsoleCmd("tshow_ad", timer_show_ad);
	RegConsoleCmd("tver", timer_version);
	//RegConsoleCmd("tuser", timer_user);
	//RegServerCmd("tcfg_load", cfg_load, "讀取L4D2_timer.cfg");
	///RegServerCmd("timer_load_record", command_load_best_record, "讀取L4D2_Timer_record.txt");
	///RegServerCmd("timer_write_record", command_record_write_to_file, "輸出L4D2_Timer_record.txt");
	//RegServerCmd("timer_time_edit", timer_time_edit, "修改計時器時間(加或減多少, 每10代表1秒)");
	
	HookConVarChange(timer_ad, ConVarChange_timer_ad);
	
	//HookEvent("round_end", round_end);
	HookEvent("player_left_start_area", round_start);
	HookEvent("door_unlocked", round_start);
	HookEvent("finale_radio_start", round_finale_start);
	HookEvent("finale_vehicle_leaving", game_end);
	HookEvent("finale_win", game_win);
	HookEvent("difficulty_changed", difficulty_changed);
	HookEvent("player_entered_checkpoint", player_entered_checkpoint);
	HookEvent("player_left_checkpoint", player_left_checkpoint);
	HookEvent("mission_lost", mission_lost);
	//AutoExecConfig(true, "L4D2_timer");
	if (!FileExists("/addons/sourcemod/configs/L4D2_Timer_record.txt", false)){
		record_write_to_file();
	}
	BuildPath(Path_SM, logfilepath, sizeof(logfilepath), BEBOP_LOG_PATH);
	AutoExecConfig(true, "L4D2_timer");
	load_best_record()
}
public Action:show_now_time(client, args)
{
	if (timer_control!=0) 
	{
		PrintToChat(client, "計時中, 目前時間:%i分鐘%i.%i秒", (time_passed/10-((time_passed)/10%60))/60, (time_passed)/10%60, (time_passed)%10);
	}
	else
	{
		PrintToChat(client, "暫停中, 目前時間:%i分鐘%i.%i秒", ((time_passed)/10-((time_passed)/10%60))/60, (time_passed)/10%60, (time_passed)%10);
	}
	PrintToServer("目前時間:%i分鐘%i.%i秒", ((time_passed)/10-((time_passed)/10%60))/60, (time_passed)/10%60, (time_passed)%10);
	return Plugin_Handled;
}
public Action:timer_start(client, args)
{
	if (timer_control==0)
	{
		timer_control = CreateTimer(1, timer_tick, _, TIMER_REPEAT);
		LogToFile(logfilepath, "手動開始計時");
		PrintToChatAll("開始計時");
		PrintHintTextToAll("開始計時");
		PrintToServer("開始計時");
	}
	else
	{
		PrintToChat(client, "錯誤: 計時中");
		PrintToServer("錯誤: 計時中");
	}
	return Plugin_Handled;
}
public Action:timer_stop(client, args)
{
	if (timer_control!=0)
	{
		KillTimer(timer_control);
		timer_control = 0
		LogToFile(logfilepath, "手動停止計時");
		PrintToChatAll("停止計時");
		PrintHintTextToAll("停止計時");
		PrintToServer("停止計時");
	}
	else
	{
		PrintToChat(client, "錯誤: 計時已停止");
		PrintToServer("錯誤: 計時已停止");
	}
	return Plugin_Handled;
}
public Action:timer_show_second(client, args)
{
	PrintHintTextToAll("此地圖:%i分鐘%i秒\n總時間:%i分鐘%i.%i秒", (time_passed_single_map)/600, (time_passed_single_map)/10%60, (time_passed/10-((time_passed)/10%60))/60, (time_passed)/10%60, (time_passed)%10);
	PrintToServer("此地圖:%i分鐘%i秒\n總時間:%i分鐘%i.%i秒", (time_passed_single_map)/600, (time_passed_single_map)/10%60, (time_passed/10-((time_passed)/10%60))/60, (time_passed)/10%60, (time_passed)%10);
	return Plugin_Handled;
}
public Action:timer_tick(Handle:timer)
{

	time_passed = time_passed+1
	time_passed_single_map = time_passed_single_map + 1
	//PrintToServer("跳字");
	decl String:map_name[5];
	GetCurrentMap(map_name, 3);
	new int:best_time = 0;
	new int:best_time_map = 0;
	if (StrEqual(map_name, "c1")){
		best_time = record_c1_impossible
	} else if (StrEqual(map_name, "c2")){
		best_time = record_c2_impossible
	} else if (StrEqual(map_name, "c3")){
		best_time = record_c3_impossible
	} else if (StrEqual(map_name, "c4")){
		best_time = record_c4_impossible
	} else if (StrEqual(map_name, "c5")){
		best_time = record_c5_impossible
	}
	GetCurrentMap(map_name, 5);
	if (StrEqual(map_name, "c1m1")){
		best_time_map = record_c1m1_impossible;
	} else if (StrEqual(map_name, "c1m2")) {
		best_time_map = record_c1m2_impossible;
	} else if (StrEqual(map_name, "c1m3")) {
		best_time_map = record_c1m3_impossible;
	} else if (StrEqual(map_name, "c1m4")) {
		best_time_map = record_c1m4_impossible;
	} else if (StrEqual(map_name, "c2m1")) {
		best_time_map = record_c2m1_impossible;
	} else if (StrEqual(map_name, "c2m2")) {
		best_time_map = record_c2m2_impossible;
	} else if (StrEqual(map_name, "c2m3")) {
		best_time_map = record_c2m3_impossible;
	} else if (StrEqual(map_name, "c2m4")) {
		best_time_map = record_c2m4_impossible;
	} else if (StrEqual(map_name, "c2m5")) {
		best_time_map = record_c2m5_impossible;
	} else if (StrEqual(map_name, "c3m1")) {
		best_time_map = record_c3m1_impossible;
	} else if (StrEqual(map_name, "c3m2")) {
		best_time_map = record_c3m2_impossible;
	} else if (StrEqual(map_name, "c3m3")) {
		best_time_map = record_c3m3_impossible;
	} else if (StrEqual(map_name, "c3m4")) {
		best_time_map = record_c3m4_impossible;
	}else if (StrEqual(map_name, "c4m1")) {
		best_time_map = record_c4m1_impossible;
	} else if (StrEqual(map_name, "c4m2")) {
		best_time_map = record_c4m2_impossible;
	} else if (StrEqual(map_name, "c4m3")) {
		best_time_map = record_c4m3_impossible;
	} else if (StrEqual(map_name, "c4m4")) {
		best_time_map = record_c4m4_impossible;
	} else if (StrEqual(map_name, "c4m5")) {
		best_time_map = record_c4m5_impossible;
	} else if (StrEqual(map_name, "c5m1")) {
		best_time_map = record_c5m1_impossible;
	} else if (StrEqual(map_name, "c5m2")) {
		best_time_map = record_c5m2_impossible;
	} else if (StrEqual(map_name, "c5m3")) {
		best_time_map = record_c5m3_impossible;
	} else if (StrEqual(map_name, "c5m4")) {
		best_time_map = record_c5m4_impossible;
	} else if (StrEqual(map_name, "c5m5")) {
		best_time_map = record_c5m5_impossible;
	}
	if (best_time-time_passed<300 && best_time-time_passed>=0 && best_time > 0 && best_time_map-time_passed_single_map<150 && best_time_map-time_passed_single_map>=0 && best_time_map > 0){
		PrintHintTextToAll("章節時間距離最佳紀錄還有%i.%i秒\n總時間距離最佳紀錄還有%i.%i秒", (best_time_map-time_passed_single_map)/10%60, (best_time_map-time_passed_single_map)%10, (best_time-time_passed)/10%60, (best_time-time_passed)%10);
	} else if ((best_time-time_passed)<300 && (best_time-time_passed)>=0 && best_time > 0){
		PrintHintTextToAll("總時間距離最佳紀錄還有%i.%i秒", (best_time-time_passed)/10%60, (best_time-time_passed)%10);
	} else if (best_time_map-time_passed_single_map<200 && best_time_map-time_passed_single_map>=0 && best_time_map > 0){
		PrintHintTextToAll("章節時間距離最佳紀錄還有%i.%i秒", (best_time_map-time_passed_single_map)/10%60, (best_time_map-time_passed_single_map)%10);
	}
	if (GetConVarInt(time_remind_interval)>0){
		if ((time_passed)%(GetConVarInt(time_remind_interval))==0){
			SetConVarInt(game_pauseable, 0);
			PrintToChatAll("此地圖:%i分鐘%i秒, 總時間:%i分鐘%i秒", (time_passed_single_map)/600, (time_passed_single_map)/10%60, (time_passed)/600, (time_passed)/10%60);
			if (best_time > 0 && best_time_map>0){
				PrintHintTextToAll("此地圖:%i分鐘%i秒/%i分鐘%i秒(最佳)\n總時間:%i分鐘%i秒/%i分鐘%i秒(最佳)", (time_passed_single_map)/600, (time_passed_single_map)/10%60, best_time_map/600, best_time_map/10%60, (time_passed)/600, (time_passed)/10%60, (best_time)/600, (best_time)/10%60);
			} else if (best_time_map>0){
				PrintHintTextToAll("此地圖:%i分鐘%i秒/%i分鐘%i秒(最佳)\n總時間:%i分鐘%i秒(未有最佳時間)", (time_passed_single_map)/600, (time_passed_single_map)/10%60, best_time_map/600, best_time_map/10%60, (time_passed)/600, (time_passed)/10%60);
			} else if (best_time > 0){
				PrintHintTextToAll("此地圖:%i分鐘%i秒(未有最佳時間)\n總時間:%i分鐘%i秒/%i分鐘%i秒(最佳)", (time_passed_single_map)/600, (time_passed_single_map)/10%60, (time_passed)/600, (time_passed)/10%60, (best_time)/600, (best_time)/10%60);
			} else {
				PrintHintTextToAll("此地圖:%i分鐘%i秒(未有最佳時間)\n總時間:%i分鐘%i秒(未有最佳時間)", (time_passed_single_map)/600, (time_passed_single_map)/10%60, (time_passed)/600, (time_passed)/10%60);
			}
			PrintToServer("此地圖:%i分鐘%i秒, 總時間:%i分鐘%i秒", (time_passed_single_map)/600, (time_passed_single_map)/10%60, (time_passed)/600, (time_passed)/10%60);
		}
	}
	if (timer_long_show == 1){
		PrintHintTextToAll("此地圖:%i分鐘%i秒\n總時間:%i分鐘%i.%i秒", (time_passed_single_map)/600, (time_passed_single_map)/10%60, (time_passed/10-((time_passed)/10%60))/60, (time_passed)/10%60, (time_passed)%10);
	}
	//if (timer_start_reminder != INVALID_){
		//KillTimer(timer_start_reminder);
	//}
	return time_passed, timer_start_reminder;
}
public Action:ad_say(Handle:timer)
{
	//timer_ad = FindConVar("timer_ad");
	//if (ad_tick%GetConVarInt(timer_ad_interval)==0){
		decl string:ad_content[512];
		GetConVarString(timer_ad_content, ad_content, sizeof(ad_content));
		if (ad_which==5){
			PrintToChatAll("\x04-----今場為進行速度榜遊戲--請按H(預設)查看詳情-----");
		} else if (ad_which==6) {
			PrintToChatAll("\x04-----今場速度榜管理員: Marco Chan-----");
		} else if (ad_which==7) {
			PrintToChatAll("%s[L4D2計時器v%s]", ad_content, PLUGIN_VERSION);
		}
	//ad_which = ad_which+1;
	//}
	ad_tick = ad_tick+1;
	if (ad_which>8)
	{
		ad_which = 5;
	}
	if (ad_tick>(GetConVarInt(timer_ad_interval)+5))
	{
		ad_tick = 5;
	}
	return ad_which, ad_tick;
}
public ConVarChange_timer_ad(Handle:convar, const String:oldValue[], const String:newValue[]){
	if (GetConVarInt(timer_ad)==1){
		ad_timer = CreateTimer(GetConVarFloat(timer_ad_interval)/10, ad_say, _, TIMER_REPEAT);
	} else {
		KillTimer(ad_timer);
	}
}
public Action:timer_reset(client, args)
{
	time_passed = 0
	time_passed_single_map = 0
	LogToFile(logfilepath, "計時器時間已被重設");
	PrintToChatAll("計時器時間已被重設");
	PrintHintTextToAll("計時器時間已被重設");
	PrintToServer("計時器時間已被重設");
}
public Action:timer_map(client, args)
{
	/*decl String:map_name[5];
	GetCurrentMap(map_name, sizeof(map_name))
	PrintToChat(client, "目前地圖:%s", map_name);*/
	return Plugin_Handled;
}
/*public Action:round_end(Handle:event, const String:name[], bool:dontBroadcast){
	if (timer_control!=0)
	{
		KillTimer(timer_control);
		timer_control = 0
		record_valid = 1
		decl String:map_name[40];
		GetCurrentMap(map_name, sizeof(map_name))
		LogToFile(logfilepath, "章節(%s)完結, 此地圖:%i分鐘%i秒, 總時間:%i分鐘%i.%i秒(round_end)", map_name, (time_passed_single_map)/600, (time_passed_single_map)/10%60, (time_passed/10-((time_passed)/10%60))/60, (time_passed)/10%60, (time_passed)%10);
		PrintToServer("章節完結, 此地圖:%i分鐘%i秒, 總時間:%i分鐘%i.%i秒(round_end)", (time_passed_single_map)/600, (time_passed_single_map)/10%60, (time_passed/10-((time_passed)/10%60))/60, (time_passed)/10%60, (time_passed)%10);
		PrintToChatAll("\x04章節完結, 此地圖:%i分鐘%i秒, 總時間:%i分鐘%i.%i秒", (time_passed_single_map)/600, (time_passed_single_map)/10%60, (time_passed/10-((time_passed)/10%60))/60, (time_passed)/10%60, (time_passed)%10);
	}
	//PrintToChatAll("MapEnd");
	return Plugin_Handled;
}*/
public OnMapEnd(){
	if (timer_control!=0)
	{
		KillTimer(timer_control);
		timer_control = 0;
		decl String:map_name[5];
		GetCurrentMap(map_name, sizeof(map_name))
		LogToFile(logfilepath, "章節(%s)完結, 此地圖:%i分鐘%i.%i秒, 總時間:%i分鐘%i.%i秒(%i)(OnMapEnd)", map_name, (time_passed_single_map)/600, (time_passed_single_map)/10%60, time_passed_single_map%10, (time_passed/10-((time_passed)/10%60))/60, (time_passed)/10%60, (time_passed)%10, time_passed);
		PrintToServer("章節完結, 此地圖:%i分鐘%i.%i秒, 總時間:%i分鐘%i.%i秒(round_end)", (time_passed_single_map)/600, (time_passed_single_map)/10%60, time_passed_single_map%10, (time_passed/10-((time_passed)/10%60))/60, (time_passed)/10%60, (time_passed)%10);
		PrintToChatAll("\x04章節完結, 此地圖:%i分鐘%i.%i秒, 總時間:%i分鐘%i.%i秒", (time_passed_single_map)/600, (time_passed_single_map)/10%60, time_passed_single_map%10, (time_passed/10-((time_passed)/10%60))/60, (time_passed)/10%60, (time_passed)%10);		
		if (record_valid>=1){
			load_best_record();
			decl String:difficulty[12];
			GetConVarString(FindConVar("z_difficulty"), difficulty, sizeof(difficulty));
			if (StrEqual(difficulty, "Impossible", false)){
				LogToFile(logfilepath, "此章節時間可與最佳紀錄比較");
				if (StrEqual(map_name, "c1m1")){
					if (record_c1m1_impossible > time_passed_single_map || record_c1m1_impossible == 0){
						PrintToChatAll("新c1m1紀錄!!!\n舊紀錄:%i分鐘%i.%i秒\n新紀錄:%i分鐘%i.%i秒", record_c1m1_impossible/600, record_c1m1_impossible/10%60, record_c1m1_impossible%10, time_passed_single_map/600, (time_passed_single_map)/10%60, (time_passed_single_map)%10);
						LogToFile(logfilepath, "新地圖時間紀錄, 地圖:%s, 時間:%i分鐘%i.%i秒(%i)   舊紀錄:%i分鐘%i.%i秒(%i)", map_name, time_passed_single_map/600, (time_passed_single_map)/10%60, (time_passed_single_map)%10, time_passed_single_map, record_c1m1_impossible/600, record_c1m1_impossible/10%60, record_c1m1_impossible%10, record_c1m1_impossible);
						record_c1m1_impossible = time_passed_single_map;
					} else {
						PrintToChatAll("噢! 破不到最佳章節時間紀錄");
					}
				} else if (StrEqual(map_name, "c1m2")){
					if (record_c1m2_impossible > time_passed_single_map || record_c1m2_impossible == 0){
						PrintToChatAll("新c1m2紀錄!!!\n舊紀錄:%i分鐘%i.%i秒\n新紀錄:%i分鐘%i.%i秒", record_c1m2_impossible/600, record_c1m2_impossible/10%60, record_c1m2_impossible%10, time_passed_single_map/600, (time_passed_single_map)/10%60, (time_passed_single_map)%10);
						LogToFile(logfilepath, "新地圖時間紀錄, 地圖:%s, 時間:%i分鐘%i.%i秒(%i)   舊紀錄:%i分鐘%i.%i秒(%i)", map_name, time_passed_single_map/600, (time_passed_single_map)/10%60, (time_passed_single_map)%10, time_passed_single_map, record_c1m2_impossible/600, record_c1m2_impossible/10%60, record_c1m2_impossible%10, record_c1m2_impossible);
						record_c1m2_impossible = time_passed_single_map;
					} else {
						PrintToChatAll("噢! 破不到最佳章節時間紀錄");
					}
				} else if (StrEqual(map_name, "c1m3")){
					if (record_c1m3_impossible > time_passed_single_map || record_c1m3_impossible == 0){
						PrintToChatAll("新c1m3紀錄!!!\n舊紀錄:%i分鐘%i.%i秒\n新紀錄:%i分鐘%i.%i秒", record_c1m3_impossible/600, record_c1m3_impossible/10%60, record_c1m3_impossible%10, time_passed_single_map/600, (time_passed_single_map)/10%60, (time_passed_single_map)%10);
						LogToFile(logfilepath, "新地圖時間紀錄, 地圖:%s, 時間:%i分鐘%i.%i秒(%i)   舊紀錄:%i分鐘%i.%i秒(%i)", map_name, time_passed_single_map/600, (time_passed_single_map)/10%60, (time_passed_single_map)%10, time_passed_single_map, record_c1m3_impossible/600, record_c1m3_impossible/10%60, record_c1m3_impossible%10, record_c1m3_impossible);
						record_c1m3_impossible = time_passed_single_map;
					} else {
						PrintToChatAll("噢! 破不到最佳章節時間紀錄");
					}
				} else if (StrEqual(map_name, "c2m1")){
					if (record_c2m1_impossible > time_passed_single_map || record_c2m1_impossible == 0){
						PrintToChatAll("新c2m1紀錄!!!\n舊紀錄:%i分鐘%i.%i秒\n新紀錄:%i分鐘%i.%i秒", record_c2m1_impossible/600, record_c2m1_impossible/10%60, record_c2m1_impossible%10, time_passed_single_map/600, (time_passed_single_map)/10%60, (time_passed_single_map)%10);
						LogToFile(logfilepath, "新地圖時間紀錄, 地圖:%s, 時間:%i分鐘%i.%i秒(%i)   舊紀錄:%i分鐘%i.%i秒(%i)", map_name, time_passed_single_map/600, (time_passed_single_map)/10%60, (time_passed_single_map)%10, time_passed_single_map, record_c2m1_impossible/600, record_c2m1_impossible/10%60, record_c2m1_impossible%10, record_c2m1_impossible);
						record_c2m1_impossible = time_passed_single_map;
					} else {
						PrintToChatAll("噢! 破不到最佳章節時間紀錄");
					}
				} else if (StrEqual(map_name, "c2m2")){
					if (record_c2m2_impossible > time_passed_single_map || record_c2m2_impossible == 0){
						PrintToChatAll("新c2m2紀錄!!!\n舊紀錄:%i分鐘%i.%i秒\n新紀錄:%i分鐘%i.%i秒", record_c2m2_impossible/600, record_c2m2_impossible/10%60, record_c2m2_impossible%10, time_passed_single_map/600, (time_passed_single_map)/10%60, (time_passed_single_map)%10);
						LogToFile(logfilepath, "新地圖時間紀錄, 地圖:%s, 時間:%i分鐘%i.%i秒(%i)   舊紀錄:%i分鐘%i.%i秒(%i)", map_name, time_passed_single_map/600, (time_passed_single_map)/10%60, (time_passed_single_map)%10, time_passed_single_map, record_c2m2_impossible/600, record_c2m2_impossible/10%60, record_c2m2_impossible%10, record_c2m2_impossible);
						record_c2m2_impossible = time_passed_single_map;
					} else {
						PrintToChatAll("噢! 破不到最佳章節時間紀錄");
					}
				} else if (StrEqual(map_name, "c2m3")){
					if (record_c2m3_impossible > time_passed_single_map || record_c2m3_impossible == 0){
						PrintToChatAll("新c2m3紀錄!!!\n舊紀錄:%i分鐘%i.%i秒\n新紀錄:%i分鐘%i.%i秒", record_c2m3_impossible/600, record_c2m3_impossible/10%60, record_c2m3_impossible%10, time_passed_single_map/600, (time_passed_single_map)/10%60, (time_passed_single_map)%10);
						LogToFile(logfilepath, "新地圖時間紀錄, 地圖:%s, 時間:%i分鐘%i.%i秒(%i)   舊紀錄:%i分鐘%i.%i秒(%i)", map_name, time_passed_single_map/600, (time_passed_single_map)/10%60, (time_passed_single_map)%10, time_passed_single_map, record_c2m3_impossible/600, record_c2m3_impossible/10%60, record_c2m3_impossible%10, record_c2m3_impossible);
						record_c2m3_impossible = time_passed_single_map;
					} else {
						PrintToChatAll("噢! 破不到最佳章節時間紀錄");
					}
				} else if (StrEqual(map_name, "c2m4")){
					if (record_c2m4_impossible > time_passed_single_map || record_c2m4_impossible == 0){
						PrintToChatAll("新c2m4紀錄!!!\n舊紀錄:%i分鐘%i.%i秒\n新紀錄:%i分鐘%i.%i秒", record_c2m4_impossible/600, record_c2m4_impossible/10%60, record_c2m4_impossible%10, time_passed_single_map/600, (time_passed_single_map)/10%60, (time_passed_single_map)%10);
						LogToFile(logfilepath, "新地圖時間紀錄, 地圖:%s, 時間:%i分鐘%i.%i秒(%i)   舊紀錄:%i分鐘%i.%i秒(%i)", map_name, time_passed_single_map/600, (time_passed_single_map)/10%60, (time_passed_single_map)%10, time_passed_single_map, record_c2m4_impossible/600, record_c2m4_impossible/10%60, record_c2m4_impossible%10, record_c2m4_impossible);
						record_c2m4_impossible = time_passed_single_map;
					} else {
						PrintToChatAll("噢! 破不到最佳章節時間紀錄");
					}
				} else if (StrEqual(map_name, "c3m1")){
					if (record_c3m1_impossible > time_passed_single_map || record_c3m1_impossible == 0){
						PrintToChatAll("新c3m1紀錄!!!\n舊紀錄:%i分鐘%i.%i秒\n新紀錄:%i分鐘%i.%i秒", record_c3m1_impossible/600, record_c3m1_impossible/10%60, record_c3m1_impossible%10, time_passed_single_map/600, (time_passed_single_map)/10%60, (time_passed_single_map)%10);
						LogToFile(logfilepath, "新地圖時間紀錄, 地圖:%s, 時間:%i分鐘%i.%i秒(%i)   舊紀錄:%i分鐘%i.%i秒(%i)", map_name, time_passed_single_map/600, (time_passed_single_map)/10%60, (time_passed_single_map)%10, time_passed_single_map, record_c3m1_impossible/600, record_c3m1_impossible/10%60, record_c3m1_impossible%10, record_c3m1_impossible);
						record_c3m1_impossible = time_passed_single_map;
					} else {
						PrintToChatAll("噢! 破不到最佳章節時間紀錄");
					}
				} else if (StrEqual(map_name, "c3m2")){
					if (record_c3m2_impossible > time_passed_single_map || record_c3m2_impossible == 0){
						PrintToChatAll("新c3m2紀錄!!!\n舊紀錄:%i分鐘%i.%i秒\n新紀錄:%i分鐘%i.%i秒", record_c3m2_impossible/600, record_c3m2_impossible/10%60, record_c3m2_impossible%10, time_passed_single_map/600, (time_passed_single_map)/10%60, (time_passed_single_map)%10);
						LogToFile(logfilepath, "新地圖時間紀錄, 地圖:%s, 時間:%i分鐘%i.%i秒(%i)   舊紀錄:%i分鐘%i.%i秒(%i)", map_name, time_passed_single_map/600, (time_passed_single_map)/10%60, (time_passed_single_map)%10, time_passed_single_map, record_c3m2_impossible/600, record_c3m2_impossible/10%60, record_c3m2_impossible%10, record_c3m2_impossible);
						record_c3m2_impossible = time_passed_single_map;
					} else {
						PrintToChatAll("噢! 破不到最佳章節時間紀錄");
					}
				} else if (StrEqual(map_name, "c3m3")){
					if (record_c3m3_impossible > time_passed_single_map || record_c3m3_impossible == 0){
						PrintToChatAll("新c3m3紀錄!!!\n舊紀錄:%i分鐘%i.%i秒\n新紀錄:%i分鐘%i.%i秒", record_c3m3_impossible/600, record_c3m3_impossible/10%60, record_c3m3_impossible%10, time_passed_single_map/600, (time_passed_single_map)/10%60, (time_passed_single_map)%10);
						LogToFile(logfilepath, "新地圖時間紀錄, 地圖:%s, 時間:%i分鐘%i.%i秒(%i)   舊紀錄:%i分鐘%i.%i秒(%i)", map_name, time_passed_single_map/600, (time_passed_single_map)/10%60, (time_passed_single_map)%10, time_passed_single_map, record_c3m3_impossible/600, record_c3m3_impossible/10%60, record_c3m3_impossible%10, record_c3m3_impossible);
						record_c3m3_impossible = time_passed_single_map;
					} else {
						PrintToChatAll("噢! 破不到最佳章節時間紀錄");
					}
				} else if (StrEqual(map_name, "c4m1")){
					if (record_c4m1_impossible > time_passed_single_map || record_c4m1_impossible == 0){
						PrintToChatAll("新c4m1紀錄!!!\n舊紀錄:%i分鐘%i.%i秒\n新紀錄:%i分鐘%i.%i秒", record_c4m1_impossible/600, record_c4m1_impossible/10%60, record_c4m1_impossible%10, time_passed_single_map/600, (time_passed_single_map)/10%60, (time_passed_single_map)%10);
						LogToFile(logfilepath, "新地圖時間紀錄, 地圖:%s, 時間:%i分鐘%i.%i秒(%i)   舊紀錄:%i分鐘%i.%i秒(%i)", map_name, time_passed_single_map/600, (time_passed_single_map)/10%60, (time_passed_single_map)%10, time_passed_single_map, record_c4m1_impossible/600, record_c4m1_impossible/10%60, record_c4m1_impossible%10, record_c4m1_impossible);
						record_c4m1_impossible = time_passed_single_map;
					} else {
						PrintToChatAll("噢! 破不到最佳章節時間紀錄");
					}
				} else if (StrEqual(map_name, "c4m2")){
					if (record_c4m2_impossible > time_passed_single_map || record_c4m2_impossible == 0){
						PrintToChatAll("新c4m2紀錄!!!\n舊紀錄:%i分鐘%i.%i秒\n新紀錄:%i分鐘%i.%i秒", record_c4m2_impossible/600, record_c4m2_impossible/10%60, record_c4m2_impossible%10, time_passed_single_map/600, (time_passed_single_map)/10%60, (time_passed_single_map)%10);
						LogToFile(logfilepath, "新地圖時間紀錄, 地圖:%s, 時間:%i分鐘%i.%i秒(%i)   舊紀錄:%i分鐘%i.%i秒(%i)", map_name, time_passed_single_map/600, (time_passed_single_map)/10%60, (time_passed_single_map)%10, time_passed_single_map, record_c4m2_impossible/600, record_c4m2_impossible/10%60, record_c4m2_impossible%10, record_c4m2_impossible);
						record_c4m2_impossible = time_passed_single_map;
					} else {
						PrintToChatAll("噢! 破不到最佳章節時間紀錄");
					}
				} else if (StrEqual(map_name, "c4m3")){
					if (record_c4m3_impossible > time_passed_single_map || record_c4m3_impossible == 0){
						PrintToChatAll("新c4m3紀錄!!!\n舊紀錄:%i分鐘%i.%i秒\n新紀錄:%i分鐘%i.%i秒", record_c4m3_impossible/600, record_c4m3_impossible/10%60, record_c4m3_impossible%10, time_passed_single_map/600, (time_passed_single_map)/10%60, (time_passed_single_map)%10);
						LogToFile(logfilepath, "新地圖時間紀錄, 地圖:%s, 時間:%i分鐘%i.%i秒(%i)   舊紀錄:%i分鐘%i.%i秒(%i)", map_name, time_passed_single_map/600, (time_passed_single_map)/10%60, (time_passed_single_map)%10, time_passed_single_map, record_c4m3_impossible/600, record_c4m3_impossible/10%60, record_c4m3_impossible%10, record_c4m3_impossible);
						record_c4m3_impossible = time_passed_single_map;
					} else {
						PrintToChatAll("噢! 破不到最佳章節時間紀錄");
					}
				} else if (StrEqual(map_name, "c4m4")){
					if (record_c4m4_impossible > time_passed_single_map || record_c4m4_impossible == 0){
						PrintToChatAll("新c4m4紀錄!!!\n舊紀錄:%i分鐘%i.%i秒\n新紀錄:%i分鐘%i.%i秒", record_c4m4_impossible/600, record_c4m4_impossible/10%60, record_c4m4_impossible%10, time_passed_single_map/600, (time_passed_single_map)/10%60, (time_passed_single_map)%10);
						LogToFile(logfilepath, "新地圖時間紀錄, 地圖:%s, 時間:%i分鐘%i.%i秒(%i)   舊紀錄:%i分鐘%i.%i秒(%i)", map_name, time_passed_single_map/600, (time_passed_single_map)/10%60, (time_passed_single_map)%10, time_passed_single_map, record_c4m4_impossible/600, record_c4m4_impossible/10%60, record_c4m4_impossible%10, record_c4m4_impossible);
						record_c4m4_impossible = time_passed_single_map;
					} else {
						PrintToChatAll("噢! 破不到最佳章節時間紀錄");
					}
				} else if (StrEqual(map_name, "c5m1")){
					if (record_c5m1_impossible > time_passed_single_map || record_c5m1_impossible == 0){
						PrintToChatAll("新c5m1紀錄!!!\n舊紀錄:%i分鐘%i.%i秒\n新紀錄:%i分鐘%i.%i秒", record_c5m1_impossible/600, record_c5m1_impossible/10%60, record_c5m1_impossible%10, time_passed_single_map/600, (time_passed_single_map)/10%60, (time_passed_single_map)%10);
						LogToFile(logfilepath, "新地圖時間紀錄, 地圖:%s, 時間:%i分鐘%i.%i秒(%i)   舊紀錄:%i分鐘%i.%i秒(%i)", map_name, time_passed_single_map/600, (time_passed_single_map)/10%60, (time_passed_single_map)%10, time_passed_single_map, record_c5m1_impossible/600, record_c5m1_impossible/10%60, record_c5m1_impossible%10, record_c5m1_impossible);
						record_c5m1_impossible = time_passed_single_map;
					} else {
						PrintToChatAll("噢! 破不到最佳章節時間紀錄");
					}
				} else if (StrEqual(map_name, "c5m2")){
					if (record_c5m2_impossible > time_passed_single_map || record_c5m2_impossible == 0){
						PrintToChatAll("新c5m2紀錄!!!\n舊紀錄:%i分鐘%i.%i秒\n新紀錄:%i分鐘%i.%i秒", record_c5m2_impossible/600, record_c5m2_impossible/10%60, record_c5m2_impossible%10, time_passed_single_map/600, (time_passed_single_map)/10%60, (time_passed_single_map)%10);
						LogToFile(logfilepath, "新地圖時間紀錄, 地圖:%s, 時間:%i分鐘%i.%i秒(%i)   舊紀錄:%i分鐘%i.%i秒(%i)", map_name, time_passed_single_map/600, (time_passed_single_map)/10%60, (time_passed_single_map)%10, time_passed_single_map, record_c5m2_impossible/600, record_c5m2_impossible/10%60, record_c5m2_impossible%10, record_c5m2_impossible);
						record_c5m2_impossible = time_passed_single_map;
					} else {
						PrintToChatAll("噢! 破不到最佳章節時間紀錄");
					}
				} else if (StrEqual(map_name, "c5m3")){
					if (record_c5m3_impossible > time_passed_single_map || record_c5m3_impossible == 0){
						PrintToChatAll("新c5m3紀錄!!!\n舊紀錄:%i分鐘%i.%i秒\n新紀錄:%i分鐘%i.%i秒", record_c5m3_impossible/600, record_c5m3_impossible/10%60, record_c5m3_impossible%10, time_passed_single_map/600, (time_passed_single_map)/10%60, (time_passed_single_map)%10);
						LogToFile(logfilepath, "新地圖時間紀錄, 地圖:%s, 時間:%i分鐘%i.%i秒(%i)   舊紀錄:%i分鐘%i.%i秒(%i)", map_name, time_passed_single_map/600, (time_passed_single_map)/10%60, (time_passed_single_map)%10, time_passed_single_map, record_c5m3_impossible/600, record_c5m3_impossible/10%60, record_c5m3_impossible%10, record_c5m3_impossible);
						record_c5m3_impossible = time_passed_single_map;
					} else {
						PrintToChatAll("噢! 破不到最佳章節時間紀錄");
					}
				} else if (StrEqual(map_name, "c5m4")){
					if (record_c5m4_impossible > time_passed_single_map || record_c5m4_impossible == 0){
						PrintToChatAll("新c5m4紀錄!!!\n舊紀錄:%i分鐘%i.%i秒\n新紀錄:%i分鐘%i.%i秒", record_c5m4_impossible/600, record_c5m4_impossible/10%60, record_c5m4_impossible%10, time_passed_single_map/600, (time_passed_single_map)/10%60, (time_passed_single_map)%10);
						LogToFile(logfilepath, "新地圖時間紀錄, 地圖:%s, 時間:%i分鐘%i.%i秒(%i)   舊紀錄:%i分鐘%i.%i秒(%i)", map_name, time_passed_single_map/600, (time_passed_single_map)/10%60, (time_passed_single_map)%10, time_passed_single_map, record_c5m4_impossible/600, record_c5m4_impossible/10%60, record_c5m4_impossible%10, record_c5m4_impossible);
						record_c5m4_impossible = time_passed_single_map;
					} else {
						PrintToChatAll("噢! 破不到最佳章節時間紀錄");
					}
				}
			record_write_to_file();
			} else {
				PrintToChatAll("\x04此章節時間不能用作比較最佳時間, 原因: 難道不是專家(目前:%s)", difficulty);
			}
		}
		if (record_valid==0){
			record_valid = 1;
		}
		first_enter_user = 0;
		if (safe_kill_time>0){
			safe_kill_time = 0;
			KillTimer(safe_kill_timer);
		}
		
	}
	if (unpause_countdown>0){
		KillTimer(unpause_timer);
	}
	//PrintToChatAll("MapEnd");
	first_enter_user = 0;
	for (new i = 1; i<48; i++){
		entered[i] = 0;
	}
	return Plugin_Handled, record_valid;
}
public Action:game_end(Handle:event, const String:name[], bool:dontBroadcast){
	if (timer_control!=0)
	{
		KillTimer(timer_control);
		timer_control = 0
		decl String:map_name[5];
		GetCurrentMap(map_name, sizeof(map_name))
		LogToFile(logfilepath, "戰役(%s)完結, 此地圖:%i分鐘%i.%i秒, 總時間:%i分鐘%i.%i秒(%i)(round_end)", map_name, (time_passed_single_map)/600, (time_passed_single_map)/10%60, (time_passed_single_map)%10, (time_passed/10-((time_passed)/10%60))/60, (time_passed)/10%60, (time_passed)%10, time_passed);
		PrintToServer("戰役完結, 此地圖:%i分鐘%i.%i秒, 總時間:%i分鐘%i.%i秒", (time_passed_single_map)/600, (time_passed_single_map)/10%60, (time_passed_single_map)%10, (time_passed/10-((time_passed)/10%60))/60, (time_passed)/10%60, (time_passed)%10);
		PrintToChatAll("\x04戰役完結, 此地圖:%i分鐘%i.%i秒, 總時間:%i分鐘%i.%i秒", (time_passed_single_map)/600, (time_passed_single_map)/10%60, (time_passed_single_map)%10, (time_passed/10-((time_passed)/10%60))/60, (time_passed)/10%60, (time_passed)%10);
		if (record_valid == 0){
			LogToFile(logfilepath, "由於難易度已改變, 此戰役及章節時間作廢");
			PrintToChatAll("\x04由於難易度已改變, 此戰役及章節時間作廢, 開始另一個戰役可重新啟動計時, 請等侯轉場");
		} else if (record_valid == 1){
			LogToFile(logfilepath, "由於難易度已改變, 此戰役時間作廢");
			PrintToChatAll("\x04由於難易度已改變, 此戰役時間作廢, 下一個戰役可重新啟動計時");			
		} else if (record_valid == 2){
			
		}
		
		if (record_valid>=1){
			load_best_record();
			decl String:difficulty[12];
			GetConVarString(FindConVar("z_difficulty"), difficulty, sizeof(difficulty));
			if (StrEqual(difficulty, "Impossible", false)){
				LogToFile(logfilepath, "此章節時間可與最佳紀錄比較");
				if (StrEqual(map_name, "c1m4")){
					if (record_c1m4_impossible > time_passed_single_map || record_c1m4_impossible == 0){
						PrintToChatAll("新c1m4紀錄!!!\n舊紀錄:%i分鐘%i.%i秒\n新紀錄:%i分鐘%i.%i秒", record_c1m4_impossible/600, record_c1m4_impossible/10%60, record_c1m4_impossible%10, time_passed_single_map/600, (time_passed_single_map)/10%60, (time_passed_single_map)%10);
						LogToFile(logfilepath, "新地圖時間紀錄, 地圖:%s, 時間:%i分鐘%i.%i秒(%i)   舊紀錄:%i分鐘%i.%i秒(%i)", map_name, time_passed_single_map/600, (time_passed_single_map)/10%60, (time_passed_single_map)%10, time_passed_single_map, record_c1m4_impossible/600, record_c1m4_impossible/10%60, record_c1m4_impossible%10, record_c1m4_impossible);
						record_c1m4_impossible = time_passed_single_map;
					} else {
						PrintToChatAll("噢! 破不到最佳章節時間紀錄");
					}
				} else if (StrEqual(map_name, "c2m5")){
					if (record_c2m5_impossible > time_passed_single_map || record_c2m5_impossible == 0){
						PrintToChatAll("新c2m5紀錄!!!\n舊紀錄:%i分鐘%i.%i秒\n新紀錄:%i分鐘%i.%i秒", record_c2m5_impossible/600, record_c2m5_impossible/10%60, record_c2m5_impossible%10, time_passed_single_map/600, (time_passed_single_map)/10%60, (time_passed_single_map)%10);
						LogToFile(logfilepath, "新地圖時間紀錄, 地圖:%s, 時間:%i分鐘%i.%i秒(%i)   舊紀錄:%i分鐘%i.%i秒(%i)", map_name, time_passed_single_map/600, (time_passed_single_map)/10%60, (time_passed_single_map)%10, time_passed_single_map, record_c2m5_impossible/600, record_c2m5_impossible/10%60, record_c2m5_impossible%10, record_c2m5_impossible);
						record_c2m5_impossible = time_passed_single_map;
					} else {
						PrintToChatAll("噢! 破不到最佳章節時間紀錄");
					}
				} else if (StrEqual(map_name, "c3m4")){
					if (record_c3m4_impossible > time_passed_single_map || record_c3m4_impossible == 0){
						PrintToChatAll("新c3m4紀錄!!!\n舊紀錄:%i分鐘%i.%i秒\n新紀錄:%i分鐘%i.%i秒", record_c3m4_impossible/600, record_c3m4_impossible/10%60, record_c3m4_impossible%10, time_passed_single_map/600, (time_passed_single_map)/10%60, (time_passed_single_map)%10);
						LogToFile(logfilepath, "新地圖時間紀錄, 地圖:%s, 時間:%i分鐘%i.%i秒(%i)   舊紀錄:%i分鐘%i.%i秒(%i)", map_name, time_passed_single_map/600, (time_passed_single_map)/10%60, (time_passed_single_map)%10, time_passed_single_map, record_c3m4_impossible/600, record_c3m4_impossible/10%60, record_c3m4_impossible%10, record_c3m4_impossible);
						record_c3m4_impossible = time_passed_single_map;
					} else {
						PrintToChatAll("噢! 破不到最佳章節時間紀錄");
					}
				} else if (StrEqual(map_name, "c4m5")){
					if (record_c4m5_impossible > time_passed_single_map || record_c4m5_impossible == 0){
						PrintToChatAll("新c4m5紀錄!!!\n舊紀錄:%i分鐘%i.%i秒\n新紀錄:%i分鐘%i.%i秒", record_c4m5_impossible/600, record_c4m5_impossible/10%60, record_c4m5_impossible%10, time_passed_single_map/600, (time_passed_single_map)/10%60, (time_passed_single_map)%10);
						LogToFile(logfilepath, "新地圖時間紀錄, 地圖:%s, 時間:%i分鐘%i.%i秒(%i)   舊紀錄:%i分鐘%i.%i秒(%i)", map_name, time_passed_single_map/600, (time_passed_single_map)/10%60, (time_passed_single_map)%10, time_passed_single_map, record_c4m5_impossible/600, record_c4m5_impossible/10%60, record_c4m5_impossible%10, record_c4m5_impossible);
						record_c4m5_impossible = time_passed_single_map;
					} else {
						PrintToChatAll("噢! 破不到最佳章節時間紀錄");
					}
				} else if (StrEqual(map_name, "c5m5")){
					if (record_c5m5_impossible > time_passed_single_map || record_c5m5_impossible == 0){
						PrintToChatAll("新c5m5紀錄!!!\n舊紀錄:%i分鐘%i.%i秒\n新紀錄:%i分鐘%i.%i秒", record_c5m5_impossible/600, record_c5m5_impossible/10%60, record_c5m5_impossible%10, time_passed_single_map/600, (time_passed_single_map)/10%60, (time_passed_single_map)%10);
						LogToFile(logfilepath, "新地圖時間紀錄, 地圖:%s, 時間:%i分鐘%i.%i秒(%i)   舊紀錄:%i分鐘%i.%i秒(%i)", map_name, time_passed_single_map/600, (time_passed_single_map)/10%60, (time_passed_single_map)%10, time_passed_single_map, record_c5m5_impossible/600, record_c5m5_impossible/10%60, record_c5m5_impossible%10, record_c5m5_impossible);
						record_c5m5_impossible = time_passed_single_map;
					} else {
						PrintToChatAll("噢! 破不到最佳章節時間紀錄");
					}
				}
			record_write_to_file();
			} else {
				PrintToChatAll("\x04此章節時間不能用作比較最佳時間, 原因: 難道不是專家(目前:%s)", difficulty);
			}
		}
		
	}
	//PrintToChatAll("MapEnd");
	return Plugin_Handled;
}
public Action:game_win(Handle:event, const String:name[], bool:dontBroadcast){
	PrintToChatAll("\x04戰役完結, 此地圖:%i分鐘%i.%i秒, 總時間:%i分鐘%i.%i秒", (time_passed_single_map)/600, (time_passed_single_map)/10%60, (time_passed_single_map)%10, (time_passed/10-((time_passed)/10%60))/60, (time_passed)/10%60, (time_passed)%10);
	if (record_valid == 0){
		PrintToChatAll("\x04由於難易度已改變, 此戰役及章節時間作廢, 開始另一個戰役可重新啟動計時, 請等侯轉場");
	} else if (record_valid == 1){
		PrintToChatAll("\x04由於難易度已改變, 此戰役時間作廢, 下一個戰役可重新啟動計時");
	} else if (record_valid == 2){
		LogToFile(logfilepath, "此戰役時間可與最佳紀錄比較");
		new string:diff[11]
		GetEventString(event, "difficulty", diff, 11)
		load_best_record();
		if (StrEqual(diff, "3", false)){
			decl String:map_name[5];
			GetCurrentMap(map_name, sizeof(map_name))
			if (StrEqual(map_name, "c1m4")){
				if (record_c1_impossible > time_passed || record_c1_impossible == 0){
					PrintToChatAll("新死亡都心紀錄!!!\n舊紀錄:%i分鐘%i.%i秒\n新紀錄:%i分鐘%i.%i秒", record_c1_impossible/600, record_c1_impossible/10%60, record_c1_impossible%10, time_passed/600, (time_passed)/10%60, (time_passed)%10);
					LogToFile(logfilepath, "新戰役時間紀錄, 地圖:%s, 時間:%i分鐘%i.%i秒(%i)   舊紀錄:%i分鐘%i.%i秒(%i)", map_name, (time_passed)/600, time_passed/10%60, time_passed%10, time_passed, record_c1_impossible/600, record_c1_impossible/10%60, record_c1_impossible%10, record_c1_impossible);
					record_c1_impossible = time_passed;
					//死亡中心
				} else {
					PrintToChatAll("噢! 破不到最佳戰役時間紀錄");
				}
			} else if (StrEqual(map_name, "c2m5")){
				if (record_c2_impossible > time_passed || record_c2_impossible == 0){
					PrintToChatAll("新黑色嘉年華紀錄!!!\n舊紀錄:%i分鐘%i.%i秒\n新紀錄:%i分鐘%i.%i秒", record_c2_impossible/600, record_c2_impossible/10%60, record_c2_impossible%10, time_passed/600, (time_passed)/10%60, (time_passed)%10);
					LogToFile(logfilepath, "新戰役時間紀錄, 地圖:%s, 時間:%i分鐘%i.%i秒(%i)   舊紀錄:%i分鐘%i.%i秒(%i)", map_name, (time_passed)/600, time_passed/10%60, time_passed%10, time_passed, record_c2_impossible/600, record_c2_impossible/10%60, record_c2_impossible%10, record_c2_impossible);
					record_c2_impossible = time_passed;
					//黑色狂欢节
				} else {
					PrintToChatAll("噢! 破不到最佳戰役時間紀錄");
				}
			} else if (StrEqual(map_name, "c3m4")){
				if (record_c3_impossible > time_passed || record_c3_impossible == 0){
					PrintToChatAll("新痢疾紀錄!!!\n舊紀錄:%i分鐘%i.%i秒\n新紀錄:%i分鐘%i.%i秒", record_c3_impossible/600, record_c3_impossible/10%60, record_c3_impossible%10, time_passed/600, (time_passed)/10%60, (time_passed)%10);
					LogToFile(logfilepath, "新戰役時間紀錄, 地圖:%s, 時間:%i分鐘%i.%i秒(%i)   舊紀錄:%i分鐘%i.%i秒(%i)", map_name, (time_passed)/600, time_passed/10%60, time_passed%10, time_passed, record_c3_impossible/600, record_c3_impossible/10%60, record_c3_impossible%10, record_c3_impossible);
					record_c3_impossible = time_passed;
					//沼泽激战
				} else {
					PrintToChatAll("噢! 破不到最佳戰役時間紀錄");
				}
			} else if (StrEqual(map_name, "c4m5")){
				if (record_c4_impossible > time_passed || record_c4_impossible == 0){
					PrintToChatAll("新大雨紀錄!!!\n舊紀錄:%i分鐘%i.%i秒\n新紀錄:%i分鐘%i.%i秒", record_c4_impossible/600, record_c4_impossible/10%60, record_c4_impossible%10, time_passed/600, (time_passed)/10%60, (time_passed)%10);
					LogToFile(logfilepath, "新戰役時間紀錄, 地圖:%s, 時間:%i分鐘%i.%i秒(%i)   舊紀錄:%i分鐘%i.%i秒(%i)", map_name, (time_passed)/600, time_passed/10%60, time_passed%10, time_passed, record_c4_impossible/600, record_c4_impossible/10%60, record_c4_impossible%10, record_c4_impossible);
					record_c4_impossible = time_passed;
					//暴风骤雨
				} else {
					PrintToChatAll("噢! 破不到最佳戰役時間紀錄");
				}
			} else if (StrEqual(map_name, "c5m5")){
				if (record_c5_impossible > time_passed || record_c5_impossible == 0){
					PrintToChatAll("新教區紀錄!!!\n舊紀錄:%i分鐘%i.%i秒\n新紀錄:%i分鐘%i.%i秒", record_c5_impossible/600, record_c5_impossible/10%60, record_c5_impossible%10, time_passed/600, (time_passed)/10%60, (time_passed)%10);
					LogToFile(logfilepath, "新戰役時間紀錄, 地圖:%s, 時間:%i分鐘%i.%i秒(%i)   舊紀錄:%i分鐘%i.%i秒(%i)", map_name, (time_passed)/600, time_passed/10%60, time_passed%10, time_passed, record_c5_impossible/600, record_c5_impossible/10%60, record_c5_impossible%10, record_c5_impossible);
					record_c5_impossible = time_passed;
					//教区
				} else {
					PrintToChatAll("噢! 破不到最佳戰役時間紀錄");
				}
			}
		} else {
			PrintToChatAll("\x04此戰役時間不能用作比較最佳時間, 原因: 難道不是專家(目前:%s)", diff);
		}
		record_write_to_file();
	}
	time_passed = 0
	time_passed_single_map = 0
	record_valid = 2
	return Plugin_Handled, time_passed, time_passed_single_map, record_valid;
}
public Action:round_start(Handle:event, const String:name[], bool:dontBroadcast){
	decl String:map_name[5];
	GetCurrentMap(map_name, sizeof(map_name))
	for (new i = 1; i<48; i++){
		entered[i] = 0;
	}
	CreateTimer(20.0, reset_first_enter_user);
	//new String:current_map_name[5];
	//GetCurrentMap(current_map_name, 5)
	if (timer_control==0 && GetConVarInt(timer_auto_start)==1 && !StrEqual(map_name, "c5m5"))
	{
		KillTimer(timer_start_reminder);
		timer_control = CreateTimer(1, timer_tick, _, TIMER_REPEAT);
		LogToFile(logfilepath, "計時自動開始(開門)");
		PrintToServer("計時開始");
		PrintToChatAll("\x04計時開始", (time_passed/10-((time_passed)/10%60))/60, (time_passed)/10%60, (time_passed)%10);
		PrintHintTextToAll("計時開始");
	}
	return Plugin_Handled;
}
public Action:round_finale_start(Handle:event, const String:name[], bool:dontBroadcast){
	decl String:map_name[5];
	GetCurrentMap(map_name, sizeof(map_name))
	if (timer_control==0 && GetConVarInt(timer_auto_start)==1 && StrEqual(map_name, "c5m5"))
	{
		KillTimer(timer_start_reminder);
		timer_control = CreateTimer(1, timer_tick, _, TIMER_REPEAT);
		LogToFile(logfilepath, "計時自動開始(c5m5橋面降下)");
		PrintToServer("計時開始");
		PrintToChatAll("\x04計時開始", (time_passed/10-((time_passed)/10%60))/60, (time_passed)/10%60, (time_passed)%10);
		PrintHintTextToAll("計時開始");
	}
	return Plugin_Handled;
}
public Action:difficulty_changed(Handle:event, const String:name[], bool:dontBroadcast){
	decl string:newdifficulty[12];
	GetEventString(event, "newDifficulty", newdifficulty, sizeof(newdifficulty));
	decl string:olddifficulty[12];
	GetEventString(event, "oldDifficulty", olddifficulty, sizeof(olddifficulty));
	if (!StrEqual(newdifficulty,olddifficulty)){
		record_valid = 0;
		LogToFile(logfilepath, "計時作廢(難易度改變為%s)", newdifficulty);
		PrintToServer("計時作廢(難易度改變)");
		PrintToChatAll("\x04由於難易度已改變為%s, 此戰役及章節時間作廢, 開始另一個戰役可重新啟動計時", newdifficulty);
		PrintHintTextToAll("由於難易度已改變, 此戰役及章節時間作廢");
	}
}
public Action:player_entered_checkpoint(Handle:event, const String:name[], bool:dontBroadcast){
	entered[GetClientOfUserId(GetEventInt(event, "userid"))] = 1;
	if (GetConVarInt(timer_safe_kill_time)>0){
	decl string:doorname[32];
	GetEventString(event, "doorname", doorname, sizeof(doorname));
	/*if (first_enter_user==0 && !IsFakeClient(GetClientOfUserId(GetEventInt(event, "userid")))){
		first_enter_user = GetClientOfUserId(GetEventInt(event, "userid"));
		decl string:user_name[64];
		GetClientName(GetClientOfUserId(GetEventInt(event, "userid")), user_name, sizeof(user_name));
		PrintHintTextToAll("第一位玩家%s已進入安全室!", user_name);
		PrintToChatAll("\x03第一位玩家\x05%s\x03已進入安全室!", user_name);
		safe_kill_time = 60;
		//safe_kill_timer = CreateTimer(1.0, safe_kill_tick, _, TIMER_REPEAT);
	}*/
	new int:in_safe_count = 0;
	new int:survivor_count = 0;
	for( new i = 1; i < GetMaxClients(); i++ ) {
		if (IsClientInGame( i ) && IsClientConnected( i )){
			if (GetClientTeam(i)==2 && GetClientHealth(i)>0) {
				survivor_count++;
				if (entered[i]==1){
					in_safe_count++;
				}
			}
		}
	}
	if (time_passed_single_map>=600){
		//PrintToChatAll("\x04%i/%i已進入安全室(%s,%i,%i)", in_safe_count, survivor_count, doorname, time_passed_single_map, safe_kill_time);
	}
	if (time_passed_single_map>600 && in_safe_count >= survivor_count/2 && safe_kill_time<=0){
		PrintToChatAll("\x04多過一半玩家(%i/%i)已進入安全室, 開始計時", in_safe_count, survivor_count);
		PrintHintTextToAll("多過一半玩家(%i/%i)已進入安全室, 開始計時", in_safe_count, survivor_count);
		safe_kill_time = GetConVarInt(timer_safe_kill_time);
		safe_kill_timer = CreateTimer(1.0, safe_kill_tick, _, TIMER_REPEAT);
	}
	}
	return Plugin_Handled;
}
public Action:player_left_checkpoint(Handle:event, const String:name[], bool:dontBroadcast){
	entered[GetClientOfUserId(GetEventInt(event, "userid"))] = 0;
	/*if (safe_kill_time<=0){
		new flags_give = GetCommandFlags("kill");
		SetCommandFlags("kill", flags_give & ~FCVAR_CHEAT);
		FakeClientCommand(GetClientOfUserId(GetEventInt(event, "userid")), "kill");
	}*/
}
public Action:mission_lost(Handle:event, const String:name[], bool:dontBroadcast){
	if (safe_kill_time>0){
		safe_kill_time = 0;
		KillTimer(safe_kill_timer);
	}
	if (timer_control!=0){
		KillTimer(timer_control);
		timer_control = 0;
	}
}
public Action:reset_first_enter_user(Handle:timer){
	first_enter_user = 0;
}
public Action:safe_kill_tick(Handle:timer){
	safe_kill_time-=1;
	//PrintHintTextToAll("%i秒後未進入安全室便會死", safe_kill_time);
	if (safe_kill_time%10==0 && safe_kill_time>10){
		PrintHintTextToAll("%i秒後未進入安全室便會死", safe_kill_time);
		PrintToChatAll("\x04%i秒後未進入安全室便會死", safe_kill_time);
	}
	if (safe_kill_time<=10 && safe_kill_time>0){
		for (new i=1; i<GetMaxClients(); i++){
			if (IsClientConnected( i ) && IsClientInGame(i) && !IsFakeClient(i) && entered[i] == 0){
				PrintHintTextToAll("%你尚未進入安全室\n%i秒後仍未進入便會死", safe_kill_time);
			} else if(IsClientConnected( i ) && IsClientInGame(i) && GetClientTeam(i)==2 && !IsFakeClient(i) && entered[i] == 1){
				PrintHintTextToAll("%i秒後未進入安全室便會死", safe_kill_time);
			}
		}
	}
	if (safe_kill_time<=0){
		PrintToChatAll("\x04未進入安全室的玩家即將被殺死\n之後離開安全室的玩家亦會被殺!");
		new flags_give = GetCommandFlags("kill");
		SetCommandFlags("kill", flags_give & ~FCVAR_CHEAT);
		for( new i = 1; i < GetMaxClients(); i++ ) {
				if (IsClientInGame( i )){
					if (IsClientConnected( i ) && GetClientTeam(i)==2 && entered[i] == 0) {	//&& !IsFakeClient( i )
						FakeClientCommand(i, "kill");
					}
				}
			}
		KillTimer(safe_kill_timer);
	}
	return Plugin_Handled;
}
public Action:timer_stop_safe_kill(client, args){
	if (safe_kill_time>0){
		KillTimer(safe_kill_timer);
		PrintToChatAll("已停止死亡倒數");
	}
	return Plugin_Handled;
}
public Action:timer_show_ad(client, args)
{
	decl String:difficulty[12];
	GetConVarString(FindConVar("z_difficulty"), difficulty, sizeof(difficulty));
	
	new gamemode = FindConVar("mp_gamemode");
	//flags = GetConVarFlags(gamemode);
	SetConVarFlags(gamemode, GetConVarFlags(gamemode) & ~FCVAR_PROTECTED);
	decl String:currentGameMode[64];
	GetConVarString(gamemode, currentGameMode, sizeof(currentGameMode));
	PrintToServer("z_difficulty:%s game mode:%s", difficulty, currentGameMode);
	PrintToChat(client, "z_difficulty:%s game mode:%s", difficulty, currentGameMode);
	decl string:user[512];
	for( new i = 1; i < GetMaxClients(); i++ ) {
		if (IsClientInGame( i )){
			if (IsClientConnected( i ) && !IsFakeClient( i ) && GetClientTeam(i)==2) {	
				decl string:user_name[64];
				GetClientName(i, user_name, sizeof(user_name));
				if (entered[i] == 1){
					PrintToChat(client, "\x01玩家\x04%s\x01(%i)在安全室\x03內\x01HP:%i, 死:%i", user_name, i, GetClientHealth(i), GetClientDeaths(i));
				} else if (entered[i] == 0){
					PrintToChat(client, "\x01玩家\x04%s\x01(%i)在安全室\x04外\x01HP:%i, 死:%i", user_name, i, GetClientHealth(i), GetClientDeaths(i));
				}
			} else if (IsClientConnected( i ) && IsFakeClient( i ) && GetClientTeam(i)==2){
				decl string:user_name[64];
				GetClientName(i, user_name, sizeof(user_name));
				if (entered[i] == 1){
					PrintToChat(client, "\x01玩家\x04%s\x01(%i)(bot)在安全室\x03內\x01HP:%i, 死:%i", user_name, i, GetClientHealth(i), GetClientDeaths(i));
				} else if (entered[i] == 0){
					PrintToChat(client, "\x01玩家\x04%s\x01(%i)(bot)在安全室\x04外\x01HP:%i, 死:%i", user_name, i, GetClientHealth(i), GetClientDeaths(i));
				}
			}
		}
	}
	return Plugin_Handled;
}
public Action:timer_show_forever(client, args){
	if (timer_long_show == 0){
		timer_long_show = 1
		PrintToChat(client, "已開啟長期顯示");
	} else if (timer_long_show == 1){
		timer_long_show = 0
		PrintToChat(client, "已關閉長期顯示");
	}
	return Plugin_Handled;
}
public Action:timer_become_valid(client, args){
	record_valid = 2;
	PrintToChatAll("戰役及章節變回有效");
	LogToFile(logfilepath, "計時變回有效(ADMIN指令)");
	return Plugin_Handled, record_valid;
}
public Action:timer_warp_to_start(client, args){
	new flags_warp_start = GetCommandFlags("warp_to_start_area");
	SetCommandFlags("warp_to_start_area", flags_warp_start & ~FCVAR_CHEAT);
	for( new i = 1; i < GetMaxClients(); i++ ) {
		if (IsClientInGame( i )){
			if (IsClientConnected( i ) && GetClientTeam(i)==2) {	
				FakeClientCommand(client, "warp_to_start_area");
			}
		}
	}
	SetCommandFlags("warp_to_start_area", flags_warp_start|FCVAR_CHEAT);
	return Plugin_Handled;
}
public Action:timer_warp_to_checkpoint(client, args){
	new flags_warp_to_checkpoint = GetCommandFlags("warp_all_survivors_to_checkpoint");
	SetCommandFlags("warp_all_survivors_to_checkpoint", flags_warp_to_checkpoint & ~FCVAR_CHEAT);
	if (client>0){
		PrintToServer("管理員把所有倖存者移至安全室");
		FakeClientCommand(client, "warp_all_survivors_to_checkpoint");
	} else {
		for( new i = 1; i < GetMaxClients(); i++ ) {
			if (IsClientInGame( i )){
				if (IsClientConnected( i ) && GetClientTeam(i)==2) {	//&& !IsFakeClient( i )
					FakeClientCommand(i, "warp_all_survivors_to_checkpoint");
					break;
				}
			}
		}
	}
	SetCommandFlags("warp_all_survivors_to_checkpoint", flags_warp_to_checkpoint|FCVAR_CHEAT);
	return Plugin_Handled;
}
public OnMapStart(){
	timer_start_reminder = CreateTimer(6.0, timer_start_remind, _, TIMER_REPEAT);
	//first_enter_user = 0;
	for (new i = 1; i<48; i++){
		entered[i] = 0;
	}
	AutoExecConfig(true, "L4D2_timer");
	decl String:map_name[3];
	GetCurrentMap(map_name, sizeof(map_name));
	time_passed_single_map = 0;
	decl String:map_name_4[5];
	GetCurrentMap(map_name_4, sizeof(map_name_4))
	LogToFile(logfilepath, "新地圖開始, 地圖:%s", map_name_4);
	if (StrEqual(map_name_4, "c1m1") || StrEqual(map_name_4, "c2m1") || StrEqual(map_name_4, "c3m1") || StrEqual(map_name_4, "c4m1") || StrEqual(map_name_4, "c5m1")){
		time_passed = 0
		time_passed_single_map = 0
		record_valid = 2
		PrintToServer("計時器時間已被重設");
		now_game = map_name
		LogToFile(logfilepath, "新戰役開始, 時間重設");
	}
	load_best_record();
	if (GetConVarInt(unpause_time)>0){
		unpause_countdown = GetConVarInt(unpause_time);
		
		for( new i = 1; i < GetMaxClients(); i++ ) {
			if (IsClientInGame( i )){
				if (IsClientConnected( i ) && !IsFakeClient( i ) ) {	
					SetConVarInt(game_pauseable, 1);
					FakeClientCommand(i, "setpause");
					SetConVarInt(game_pauseable, 0);
					LogToFile(logfilepath, "暫停遊戲");
					break;
				}
			}
		}
		unpause_countdown = GetConVarInt(unpause_time)*10;
		unpause_timer = CreateTimer(0.5, unpause_tick, _, TIMER_REPEAT);
		if (safe_kill_time>0){
			safe_kill_time = 0;
			KillTimer(safe_kill_timer);
		}

	}
	//return time_passed, time_passed_single_map, record_valid, now_game;
	return Plugin_Handled;
}
public Action:unpause_tick(Handle:timer){
	//new flags_give = GetCommandFlags("warp_to_start_area");
	//SetCommandFlags("warp_to_start_area", flags_give & ~FCVAR_CHEAT);
	unpause_countdown-=5;
	PrintHintTextToAll("%i秒後會解除暫停遊戲", unpause_countdown/10);
	PrintCenterTextAll("%i秒後會解除暫停遊戲", unpause_countdown/10);
	if (unpause_countdown%50==0){
		PrintToChatAll("%i秒後會解除暫停遊戲", unpause_countdown/10);
		if (safe_kill_time>0){
			safe_kill_time = 0;
			KillTimer(safe_kill_timer);
		}
	}
	for( new i = 1; i < GetMaxClients(); i++ ) {
		if (IsClientInGame( i )){
			if (IsClientConnected( i ) && !IsFakeClient( i ) ) {	
				SetConVarInt(game_pauseable, 1);
				FakeClientCommand(i, "setpause");
				SetConVarInt(game_pauseable, 0);
				break;
			}
		}
	}
	if (unpause_countdown<=0){
		//SetConVarInt(game_pauseable, 1);
		for( new i = 1; i < GetMaxClients(); i++ ) {
			if (IsClientInGame( i )){
			if (IsClientConnected( i ) && !IsFakeClient( i ) ) {	
				SetConVarInt(game_pauseable, 1);
				FakeClientCommand(i, "unpause");
				SetConVarInt(game_pauseable, 0);
				LogToFile(logfilepath, "解除暫停遊戲");
				break;
			}
			}
		}
		KillTimer(unpause_timer);
	}
}
public Action:timer_unpause(client, args){
	unpause_countdown = 0;
	return Plugin_Handled;
}
public Action:timer_start_remind(Handle:timer){
		
	if (time_passed_single_map == 0){
		decl String:map_name[5];
		GetCurrentMap(map_name, 3);
		new int:best_time = 0;
		if (StrEqual(map_name, "c1")){
			best_time = record_c1_impossible
		} else if (StrEqual(map_name, "c2")){
			best_time = record_c2_impossible
		} else if (StrEqual(map_name, "c3")){
			best_time = record_c3_impossible
		} else if (StrEqual(map_name, "c4")){
			best_time = record_c4_impossible
		} else if (StrEqual(map_name, "c5")){
			best_time = record_c5_impossible
		}
		GetCurrentMap(map_name, 5);
		if (!StrEqual(map_name, "c5m5")){
			//PrintToChatAll("\x04注意: 離開安全區範圍/解鎖安全室的門計時會立即開始");
			if (best_time>0){
				PrintHintTextToAll("注意: 離開安全區範圍/解鎖安全室的門計時會立即開始\n目前時間:%i分鐘%i.%i秒/%i分鐘%i.%i秒(最佳)\n建議先等待所有玩家準備好才開始", (time_passed/10-((time_passed)/10%60))/60, (time_passed)/10%60, (time_passed)%10, (best_time)/600, (best_time)/10%60, (best_time)%10);
			} else {
				PrintHintTextToAll("注意: 離開安全區範圍/解鎖安全室的門計時會立即開始\n目前時間:%i分鐘%i.%i秒(未有最佳紀錄)\n建議先等待所有玩家準備好才開始", (time_passed/10-((time_passed)/10%60))/60, (time_passed)/10%60, (time_passed)%10);
			}
		} else if(StrEqual(map_name, "c5m5")){
			//PrintToChatAll("\x04注意: 橋面下降完成後計時會立即開始");
			if (best_time>0){
				PrintHintTextToAll("注意: 橋面下降完成後計時會立即開始\n目前時間:%i分鐘%i.%i秒/%i分鐘%i.%i秒(最佳)\n建議先等待所有玩家準備好才開始", (time_passed/10-((time_passed)/10%60))/60, (time_passed)/10%60, (time_passed)%10, (best_time)/600, (best_time)/10%60, (best_time)%10);
			} else {
				PrintHintTextToAll("注意: 橋面下降完成後計時會立即開始\n目前時間:%i分鐘%i.%i秒(未有最佳紀錄)\n建議先等待所有玩家準備好才開始", (time_passed/10-((time_passed)/10%60))/60, (time_passed)/10%60, (time_passed)%10);
			}
		}
	}
}
load_best_record(){
	if (record_list != INVALID_HANDLE) {
		CloseHandle(record_list);
	}
	if (!FileExists("/addons/sourcemod/configs/L4D2_Timer_record.txt", false)){
		record_write_to_file();
	}
	PrintToServer("讀取L4D2_Timer_record.txt");
	LogToFile(logfilepath, "讀取L4D2_Timer_record.txt");
	record_list = CreateKeyValues("Record");
	decl String:sFile[256], String:sPath[256];
	BuildPath(Path_SM, sPath, sizeof(sPath), "configs/L4D2_Timer_record.txt");
	
	if (FileExists(sPath)) {
		FileToKeyValues(record_list, sPath);
		KvGotoFirstSubKey(record_list);
	} else {
		SetFailState("找不到檔案: %s", sPath);
	}
	decl string:record_map_name[5], int:record_map_time;
	do {
		KvGetString(record_list, "map", record_map_name, sizeof(record_map_name));
		record_map_time = KvGetNum(record_list, "time_impossible");
		//PrintToServer("Map:%s time:%i", record_map_name, record_map_time);
		if (StrEqual(record_map_name, "c1")){
			record_c1_impossible = record_map_time
		} else if (StrEqual(record_map_name, "c2")){
			record_c2_impossible = record_map_time
		} else if (StrEqual(record_map_name, "c3")){
			record_c3_impossible = record_map_time
		} else if (StrEqual(record_map_name, "c4")){
			record_c4_impossible = record_map_time
		} else if (StrEqual(record_map_name, "c5")){
			record_c5_impossible = record_map_time
		} else if (StrEqual(record_map_name, "c1m1")){
			record_c1m1_impossible = record_map_time
		} else if (StrEqual(record_map_name, "c1m2")){
			record_c1m2_impossible = record_map_time
		} else if (StrEqual(record_map_name, "c1m3")){
			record_c1m3_impossible = record_map_time
		} else if (StrEqual(record_map_name, "c1m4")){
			record_c1m4_impossible = record_map_time
		} else if (StrEqual(record_map_name, "c2m1")){
			record_c2m1_impossible = record_map_time
		} else if (StrEqual(record_map_name, "c2m2")){
			record_c2m2_impossible = record_map_time
		} else if (StrEqual(record_map_name, "c2m3")){
			record_c2m3_impossible = record_map_time
		} else if (StrEqual(record_map_name, "c2m4")){
			record_c2m4_impossible = record_map_time
		} else if (StrEqual(record_map_name, "c2m5")){
			record_c2m5_impossible = record_map_time
		} else if (StrEqual(record_map_name, "c3m1")){
			record_c3m1_impossible = record_map_time
		} else if (StrEqual(record_map_name, "c3m2")){
			record_c3m2_impossible = record_map_time
		} else if (StrEqual(record_map_name, "c3m3")){
			record_c3m3_impossible = record_map_time
		} else if (StrEqual(record_map_name, "c3m4")){
			record_c3m4_impossible = record_map_time
		} else if (StrEqual(record_map_name, "c4m1")){
			record_c4m1_impossible = record_map_time
		} else if (StrEqual(record_map_name, "c4m2")){
			record_c4m2_impossible = record_map_time
		} else if (StrEqual(record_map_name, "c4m3")){
			record_c4m3_impossible = record_map_time
		} else if (StrEqual(record_map_name, "c4m4")){
			record_c4m4_impossible = record_map_time
		} else if (StrEqual(record_map_name, "c4m5")){
			record_c4m5_impossible = record_map_time
		} else if (StrEqual(record_map_name, "c5m1")){
			record_c5m1_impossible = record_map_time
		} else if (StrEqual(record_map_name, "c5m2")){
			record_c5m2_impossible = record_map_time
		} else if (StrEqual(record_map_name, "c5m3")){
			record_c5m3_impossible = record_map_time
		} else if (StrEqual(record_map_name, "c5m4")){
			record_c5m4_impossible = record_map_time
		} else if (StrEqual(record_map_name, "c5m5")){
			record_c5m5_impossible = record_map_time
		}
		
	}
	while (KvGotoNextKey(record_list));	
}
record_write_to_file(){
	PrintToServer("輸出L4D2_Timer_record.txt");
	LogToFile(logfilepath, "輸出L4D2_Timer_record.txt");
	record_file = OpenFile("/addons/sourcemod/configs/L4D2_Timer_record.txt", "w");
		WriteFileLine(record_file, "//此檔案用作紀錄各戰役及章節的最佳時間");
		WriteFileLine(record_file, "//timer.smx會讀取及修改此檔案的內容");
		WriteFileLine(record_file, "//所有數字每10代表1秒");
		WriteFileLine(record_file, "//map 的數值切勿修改");
		WriteFileLine(record_file, "//以下設定由計時器版本:%s 建立", PLUGIN_VERSION);
		WriteFileLine(record_file, "\"Record\"");
		WriteFileLine(record_file, "{");
		
		WriteFileLine(record_file, "\"1\"");
		WriteFileLine(record_file, "{");
		WriteFileLine(record_file, "map c1");
		WriteFileLine(record_file, "time_easy		0");
		WriteFileLine(record_file, "time_normal		0");
		WriteFileLine(record_file, "time_hard		0");
		WriteFileLine(record_file, "time_impossible		%i // %i分鐘%i.%i秒", record_c1_impossible, record_c1_impossible/600, record_c1_impossible/10%60, record_c1_impossible%10);
		WriteFileLine(record_file, "}");
		WriteFileLine(record_file, "\"2\"");
		WriteFileLine(record_file, "{");
		WriteFileLine(record_file, "map c2");
		WriteFileLine(record_file, "time_easy		0");
		WriteFileLine(record_file, "time_normal		0");
		WriteFileLine(record_file, "time_hard		0");
		WriteFileLine(record_file, "time_impossible		%i // %i分鐘%i.%i秒", record_c2_impossible, record_c2_impossible/600, record_c2_impossible/10%60, record_c2_impossible%10);
		WriteFileLine(record_file, "}");
		WriteFileLine(record_file, "\"3\"");
		WriteFileLine(record_file, "{");
		WriteFileLine(record_file, "map c3");
		WriteFileLine(record_file, "time_easy		0");
		WriteFileLine(record_file, "time_normal		0");
		WriteFileLine(record_file, "time_hard		0");
		WriteFileLine(record_file, "time_impossible		%i // %i分鐘%i.%i秒", record_c3_impossible, record_c3_impossible/600, record_c3_impossible/10%60, record_c3_impossible%10);
		WriteFileLine(record_file, "}");
		WriteFileLine(record_file, "\"4\"");
		WriteFileLine(record_file, "{");
		WriteFileLine(record_file, "map c4");
		WriteFileLine(record_file, "time_easy		0");
		WriteFileLine(record_file, "time_normal		0");
		WriteFileLine(record_file, "time_hard		0");
		WriteFileLine(record_file, "time_impossible		%i // %i分鐘%i.%i秒", record_c4_impossible, record_c4_impossible/600, record_c4_impossible/10%60, record_c4_impossible%10);
		WriteFileLine(record_file, "}");
		WriteFileLine(record_file, "\"5\"");
		WriteFileLine(record_file, "{");
		WriteFileLine(record_file, "map c5");
		WriteFileLine(record_file, "time_easy		0");
		WriteFileLine(record_file, "time_normal		0");
		WriteFileLine(record_file, "time_hard		0");
		WriteFileLine(record_file, "time_impossible		%i // %i分鐘%i.%i秒", record_c5_impossible, record_c5_impossible/600, record_c5_impossible/10%60, record_c5_impossible%10);
		WriteFileLine(record_file, "}");
		
		WriteFileLine(record_file, "\"6\"");
		WriteFileLine(record_file, "{");
		WriteFileLine(record_file, "map c1m1");
		WriteFileLine(record_file, "time_easy		0");
		WriteFileLine(record_file, "time_normal		0");
		WriteFileLine(record_file, "time_hard		0");
		WriteFileLine(record_file, "time_impossible		%i // %i分鐘%i.%i秒", record_c1m1_impossible, record_c1m1_impossible/600, record_c1m1_impossible/10%60, record_c1m1_impossible%10);
		WriteFileLine(record_file, "}");
		WriteFileLine(record_file, "\"7\"");
		WriteFileLine(record_file, "{");
		WriteFileLine(record_file, "map c1m2");
		WriteFileLine(record_file, "time_easy		0");
		WriteFileLine(record_file, "time_normal		0");
		WriteFileLine(record_file, "time_hard		0");
		WriteFileLine(record_file, "time_impossible		%i // %i分鐘%i.%i秒", record_c1m2_impossible, record_c1m2_impossible/600, record_c1m2_impossible/10%60, record_c1m2_impossible%10);
		WriteFileLine(record_file, "}");
		WriteFileLine(record_file, "\"8\"");
		WriteFileLine(record_file, "{");
		WriteFileLine(record_file, "map c1m3");
		WriteFileLine(record_file, "time_easy		0");
		WriteFileLine(record_file, "time_normal		0");
		WriteFileLine(record_file, "time_hard		0");
		WriteFileLine(record_file, "time_impossible		%i // %i分鐘%i.%i秒", record_c1m3_impossible, record_c1m3_impossible/600, record_c1m3_impossible/10%60, record_c1m3_impossible%10);
		WriteFileLine(record_file, "}");
		WriteFileLine(record_file, "\"9\"");
		WriteFileLine(record_file, "{");
		WriteFileLine(record_file, "map c1m4");
		WriteFileLine(record_file, "time_easy		0");
		WriteFileLine(record_file, "time_normal		0");
		WriteFileLine(record_file, "time_hard		0");
		WriteFileLine(record_file, "time_impossible		%i // %i分鐘%i.%i秒", record_c1m4_impossible, record_c1m4_impossible/600, record_c1m4_impossible/10%60, record_c1m4_impossible%10);
		WriteFileLine(record_file, "}");
		WriteFileLine(record_file, "\"10\"");
		WriteFileLine(record_file, "{");
		WriteFileLine(record_file, "map c2m1");
		WriteFileLine(record_file, "time_easy		0");
		WriteFileLine(record_file, "time_normal		0");
		WriteFileLine(record_file, "time_hard		0");
		WriteFileLine(record_file, "time_impossible		%i // %i分鐘%i.%i秒", record_c2m1_impossible, record_c2m1_impossible/600, record_c2m1_impossible/10%60, record_c2m1_impossible%10);
		WriteFileLine(record_file, "}");
		WriteFileLine(record_file, "\"11\"");
		WriteFileLine(record_file, "{");
		WriteFileLine(record_file, "map c2m2");
		WriteFileLine(record_file, "time_easy		0");
		WriteFileLine(record_file, "time_normal		0");
		WriteFileLine(record_file, "time_hard		0");
		WriteFileLine(record_file, "time_impossible		%i // %i分鐘%i.%i秒", record_c2m2_impossible, record_c2m2_impossible/600, record_c2m2_impossible/10%60, record_c2m2_impossible%10);
		WriteFileLine(record_file, "}");
		WriteFileLine(record_file, "\"12\"");
		WriteFileLine(record_file, "{");
		WriteFileLine(record_file, "map c2m3");
		WriteFileLine(record_file, "time_easy		0");
		WriteFileLine(record_file, "time_normal		0");
		WriteFileLine(record_file, "time_hard		0");
		WriteFileLine(record_file, "time_impossible		%i // %i分鐘%i.%i秒", record_c2m3_impossible, record_c2m3_impossible/600, record_c2m3_impossible/10%60, record_c2m3_impossible%10);
		WriteFileLine(record_file, "}");
		WriteFileLine(record_file, "\"13\"");
		WriteFileLine(record_file, "{");
		WriteFileLine(record_file, "map c2m4");
		WriteFileLine(record_file, "time_easy		0");
		WriteFileLine(record_file, "time_normal		0");
		WriteFileLine(record_file, "time_hard		0");
		WriteFileLine(record_file, "time_impossible		%i // %i分鐘%i.%i秒", record_c2m4_impossible, record_c2m4_impossible/600, record_c2m4_impossible/10%60, record_c2m4_impossible%10);
		WriteFileLine(record_file, "}");
		WriteFileLine(record_file, "\"14\"");
		WriteFileLine(record_file, "{");
		WriteFileLine(record_file, "map c2m5");
		WriteFileLine(record_file, "time_easy		0");
		WriteFileLine(record_file, "time_normal		0");
		WriteFileLine(record_file, "time_hard		0");
		WriteFileLine(record_file, "time_impossible		%i // %i分鐘%i.%i秒", record_c2m5_impossible, record_c2m5_impossible/600, record_c2m5_impossible/10%60, record_c2m5_impossible%10);
		WriteFileLine(record_file, "}");
		WriteFileLine(record_file, "\"15\"");
		WriteFileLine(record_file, "{");
		WriteFileLine(record_file, "map c3m1");
		WriteFileLine(record_file, "time_easy		0");
		WriteFileLine(record_file, "time_normal		0");
		WriteFileLine(record_file, "time_hard		0");
		WriteFileLine(record_file, "time_impossible		%i // %i分鐘%i.%i秒", record_c3m1_impossible, record_c3m1_impossible/600, record_c3m1_impossible/10%60, record_c3m1_impossible%10);
		WriteFileLine(record_file, "}");
		WriteFileLine(record_file, "\"16\"");
		WriteFileLine(record_file, "{");
		WriteFileLine(record_file, "map c3m2");
		WriteFileLine(record_file, "time_easy		0");
		WriteFileLine(record_file, "time_normal		0");
		WriteFileLine(record_file, "time_hard		0");
		WriteFileLine(record_file, "time_impossible		%i // %i分鐘%i.%i秒", record_c3m2_impossible, record_c3m2_impossible/600, record_c3m2_impossible/10%60, record_c3m2_impossible%10);
		WriteFileLine(record_file, "}");
		WriteFileLine(record_file, "\"17\"");
		WriteFileLine(record_file, "{");
		WriteFileLine(record_file, "map c3m3");
		WriteFileLine(record_file, "time_easy		0");
		WriteFileLine(record_file, "time_normal		0");
		WriteFileLine(record_file, "time_hard		0");
		WriteFileLine(record_file, "time_impossible		%i // %i分鐘%i.%i秒", record_c3m3_impossible, record_c3m3_impossible/600, record_c3m3_impossible/10%60, record_c3m3_impossible%10);
		WriteFileLine(record_file, "}");
		WriteFileLine(record_file, "\"18\"");
		WriteFileLine(record_file, "{");
		WriteFileLine(record_file, "map c3m4");
		WriteFileLine(record_file, "time_easy		0");
		WriteFileLine(record_file, "time_normal		0");
		WriteFileLine(record_file, "time_hard		0");
		WriteFileLine(record_file, "time_impossible		%i // %i分鐘%i.%i秒", record_c3m4_impossible, record_c3m4_impossible/600, record_c3m4_impossible/10%60, record_c3m4_impossible%10);
		WriteFileLine(record_file, "}");
		WriteFileLine(record_file, "\"19\"");
		WriteFileLine(record_file, "{");
		WriteFileLine(record_file, "map c4m1");
		WriteFileLine(record_file, "time_easy		0");
		WriteFileLine(record_file, "time_normal		0");
		WriteFileLine(record_file, "time_hard		0");
		WriteFileLine(record_file, "time_impossible		%i // %i分鐘%i.%i秒", record_c4m1_impossible, record_c4m1_impossible/600, record_c4m1_impossible/10%60, record_c4m1_impossible%10);
		WriteFileLine(record_file, "}");
		WriteFileLine(record_file, "\"20\"");
		WriteFileLine(record_file, "{");
		WriteFileLine(record_file, "map c4m2");
		WriteFileLine(record_file, "time_easy		0");
		WriteFileLine(record_file, "time_normal		0");
		WriteFileLine(record_file, "time_hard		0");
		WriteFileLine(record_file, "time_impossible		%i // %i分鐘%i.%i秒", record_c4m2_impossible, record_c4m2_impossible/600, record_c4m2_impossible/10%60, record_c4m2_impossible%10);
		WriteFileLine(record_file, "}");
		WriteFileLine(record_file, "\"21\"");
		WriteFileLine(record_file, "{");
		WriteFileLine(record_file, "map c4m3");
		WriteFileLine(record_file, "time_easy		0");
		WriteFileLine(record_file, "time_normal		0");
		WriteFileLine(record_file, "time_hard		0");
		WriteFileLine(record_file, "time_impossible		%i // %i分鐘%i.%i秒", record_c4m3_impossible, record_c4m3_impossible/600, record_c4m3_impossible/10%60, record_c4m3_impossible%10);
		WriteFileLine(record_file, "}");
		WriteFileLine(record_file, "\"22\"");
		WriteFileLine(record_file, "{");
		WriteFileLine(record_file, "map c4m4");
		WriteFileLine(record_file, "time_easy		0");
		WriteFileLine(record_file, "time_normal		0");
		WriteFileLine(record_file, "time_hard		0");
		WriteFileLine(record_file, "time_impossible		%i // %i分鐘%i.%i秒", record_c4m4_impossible, record_c4m4_impossible/600, record_c4m4_impossible/10%60, record_c4m4_impossible%10);
		WriteFileLine(record_file, "}");
		WriteFileLine(record_file, "\"23\"");
		WriteFileLine(record_file, "{");
		WriteFileLine(record_file, "map c4m5");
		WriteFileLine(record_file, "time_easy		0");
		WriteFileLine(record_file, "time_normal		0");
		WriteFileLine(record_file, "time_hard		0");
		WriteFileLine(record_file, "time_impossible		%i // %i分鐘%i.%i秒", record_c4m5_impossible, record_c4m5_impossible/600, record_c4m5_impossible/10%60, record_c4m5_impossible%10);
		WriteFileLine(record_file, "}");
		WriteFileLine(record_file, "\"24\"");
		WriteFileLine(record_file, "{");
		WriteFileLine(record_file, "map c5m1");
		WriteFileLine(record_file, "time_easy		0");
		WriteFileLine(record_file, "time_normal		0");
		WriteFileLine(record_file, "time_hard		0");
		WriteFileLine(record_file, "time_impossible		%i // %i分鐘%i.%i秒", record_c5m1_impossible, record_c5m1_impossible/600, record_c5m1_impossible/10%60, record_c5m1_impossible%10);
		WriteFileLine(record_file, "}");
		WriteFileLine(record_file, "\"25\"");
		WriteFileLine(record_file, "{");
		WriteFileLine(record_file, "map c5m2");
		WriteFileLine(record_file, "time_easy		0");
		WriteFileLine(record_file, "time_normal		0");
		WriteFileLine(record_file, "time_hard		0");
		WriteFileLine(record_file, "time_impossible		%i // %i分鐘%i.%i秒", record_c5m2_impossible, record_c5m2_impossible/600, record_c5m2_impossible/10%60, record_c5m2_impossible%10);
		WriteFileLine(record_file, "}");
		WriteFileLine(record_file, "\"26\"");
		WriteFileLine(record_file, "{");
		WriteFileLine(record_file, "map c5m3");
		WriteFileLine(record_file, "time_easy		0");
		WriteFileLine(record_file, "time_normal		0");
		WriteFileLine(record_file, "time_hard		0");
		WriteFileLine(record_file, "time_impossible		%i // %i分鐘%i.%i秒", record_c5m3_impossible, record_c5m3_impossible/600, record_c5m3_impossible/10%60, record_c5m3_impossible%10);
		WriteFileLine(record_file, "}");
		WriteFileLine(record_file, "\"27\"");
		WriteFileLine(record_file, "{");
		WriteFileLine(record_file, "map c5m4");
		WriteFileLine(record_file, "time_easy		0");
		WriteFileLine(record_file, "time_normal		0");
		WriteFileLine(record_file, "time_hard		0");
		WriteFileLine(record_file, "time_impossible		%i // %i分鐘%i.%i秒", record_c5m4_impossible, record_c5m4_impossible/600, record_c5m4_impossible/10%60, record_c5m4_impossible%10);
		WriteFileLine(record_file, "}");
		WriteFileLine(record_file, "\"28\"");
		WriteFileLine(record_file, "{");
		WriteFileLine(record_file, "map c5m5");
		WriteFileLine(record_file, "time_easy		0");
		WriteFileLine(record_file, "time_normal		0");
		WriteFileLine(record_file, "time_hard		0");
		WriteFileLine(record_file, "time_impossible		%i // %i分鐘%i.%i秒", record_c5m5_impossible, record_c5m5_impossible/600, record_c5m5_impossible/10%60, record_c5m5_impossible%10);
		WriteFileLine(record_file, "}");
		
		WriteFileLine(record_file, "}");
		FlushFile(record_file)
	
}
public Action:timer_version(client, args)
{
	PrintToServer("計時器 %s", PLUGIN_VERSION);
	PrintToChat(client, "計時器 %s", PLUGIN_VERSION);
	return Plugin_Handled;
}
public Action:cfg_load(args){
	//AutoExecConfig(true, "L4D2_timer");
	return Plugin_Handled;
}
public Action:command_load_best_record(args){
	load_best_record();
	return Plugin_Handled;
}
public Action:command_record_write_to_file(args){
	record_write_to_file();
	return Plugin_Handled;
}
public Action:timer_time_edit(args){
	if (GetCmdArgs()==1){
		decl string:edit_time[16];
		GetCmdArg(0, edit_time, sizeof(edit_time)); 
		time_passed = time_passed + StringToInt(edit_time, 10);
		PrintToChatAll("\x04計時器時間已被調較至%i分鐘%i.%i秒(改變:%i.%i秒)", time_passed/600, time_passed/10%60, time_passed%10, StringToInt(edit_time, 10)/10%60, StringToInt(edit_time, 10)%10);
		LogToFile(logfilepath, "計時器時間已被調較至%i分鐘%i.%i秒(%i)(改變:%i.%i秒)(%i)", time_passed/600, time_passed/10%60, time_passed%10, time_passed, StringToInt(edit_time, 10)/10%60, StringToInt(edit_time, 10)%10, StringToInt(edit_time, 10));
	}
}
/*
public OnClientConnected(client){
	new client_id[10];
	IntToString(client, client_id);
	if (StrEqual(player1, "")){
		IntToString(client_id, player1);
	} else if (StrEqual(player2, "")){
		IntToString(client_id, player2);
	} else if (StrEqual(player3, "")){
		IntToString(client_id, player3);
	} else if (StrEqual(player4, "")){
		IntToString(client_id, player4);
	} else if (StrEqual(player5, "")){
		IntToString(client_id, player5);
	} else if (StrEqual(player6, "")){
		IntToString(client_id, player6);
	} else if (StrEqual(player7, "")){
		IntToString(client_id, player7);
	} else if (StrEqual(player8, "")){
		IntToString(client_id, player8);
	}
	
	
	return player1, player2, player3, player4, player5, player6, player7, player8
}
public OnClientDisconnect(client){
	new string:client_id[10];
	IntToString(client, client_id);
	if (StrEqual(player1, client_id)){
		player1 = "";
	} else if (StrEqual(player2, client_id)){
		player2 = "";
	} else if (StrEqual(player3, client_id)){
		player3 = "";
	} else if (StrEqual(player4, client_id)){
		player4 = "";
	} else if (StrEqual(player5, client_id)){
		player5 = "";
	} else if (StrEqual(player6, client_id)){
		player6 = "";
	} else if (StrEqual(player7, client_id)){
		player7 = "";
	} else if (StrEqual(player8, client_id)){
		player8 = "";
	}
	return player1, player2, player3, player4, player5, player6, player7, player8
}
public Action:timer_user(client, args)
{
	new string:user_list
	if (!StrEqual(player1, "")){
		user_list = ("%s%s", user_list, player1);
	}
	PrintToChat(client, "計時器 %s", PLUGIN_VERSION);
	return Plugin_Handled;
}
*/
