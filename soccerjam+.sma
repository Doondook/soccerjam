/*
* --------------------------------------------------------------------------------------------------
*
* 	      _____                         ___                  ______ _           
* 	     /  ___|                       |_  |                 | ___ \ |          
* 	     \ `--.  ___   ___ ___ ___ _ __  | | __ _ _ __ ___   | |_/ / |_   _ ___ 
* 	      `--. \/ _ \ / __/ __/ _ \ '__| | |/ _` | '_ ` _ \  |  __/| | | | / __|
* 	     /\__/ / (_) | (_| (_|  __/ |/\__/ / (_| | | | | | | | |   | | |_| \__ \
* 	     \____/ \___/ \___\___\___|_|\____/ \__,_|_| |_| |_| \_|   |_|\__,_|___/
*
*
* --------------------------------------------------------------------------------------------------
*
* 	Improved version of original SoccerJam Mod made by OneEyed:
* 		http://forums.alliedmods.net/showthread.php?t=41447
*
* 	Complete description, bug reoprts and suggestions:
* 		http://
*
* --------------------------------------------------------------------------------------------------
*
* - Change log:
*
* - - version 1.0.0 (release):
*
* 	Added switching between public and tournament modes;
*	Added multi-ball support;
* 	Added SQL stats saving, clan and server management;
*	Added auto-recording and auto-uploading HLTV-demos to FTP-server (tournament mode only);
* 	Added nVault-saving experience, stats and skills of current game;
* 	Fixed respawn system;
* 	Fixed variety of bugs and errors;
* 	Added anti-lame settings;
* 	Added anti-hunt settings;
* 	Added ability to view players skills, stats (for public mode);
* 	Added configuration file allowing additional customization;
*	Added menu for admins with frequently used settings/commands;
* 	Added variety of design features and improvements;
* 	Added ability of showing current game status (score, time) instead of game description;
* 	Added integrated 3rd-person camera view support;
*	Added integrated /whois support;
*
* 	Improved stats and skills systems:
* 		- added disarm, ball losses, passes stats;
* 		- improved assists and possession stats;
* 		- using money as experience;
* 		- added reseting skills (for public mode);
* 		- disarm does not retrieve opponent's knife (for public mode);
* 		- stamina increases health after next spawn (prevent /reset spam).
*
* 	Added chat commands:
* 		- /top [number] - show top [number] players [SQL];
* 		- /rank [player] - show your [player's] rank [SQL];
* 		- /rankstats [player] - show your [player's] stats [SQL];
* 		- /stats [player] - show your [player's] stats in current game;
* 		- /skills [player] - show your [player's] skills in current game;
* 		- /reset - reset skills;
* 		- /cam /camera - toggle camera view;
* 		- /firstperson /first - 1st-person camera view;
* 		- /thirdperson /third - 3rd-person camera view;
* 		- /spec - go to spectators;
* 		- /$ <player> <money> - donate your <money> to the <player> (limit is $99999).
*	
*		Note: prefix "." is either supported.
*
* 	Added commands:
* 		- "nightvision" (default: "N") - toggle camera view;
* 		- "+alt1" (default: "ALT") - shows "!" sprite above a player (asking for a pass);
* 		- "showbriefing" (default: "L" or "I") - SJ admin menu [ADMIN_KICK].
*
* 	Added / remade CVars:
* 		- sj_multiball (20) - amount of the balls for "multiball" command 
* 		     		      (32 balls is the limit to prevent server crashes);
* 		- sj_lamedist (0) - max distance to the opposite goals as far you can score, 
* 		    		    if there is no opponents in alien zone in moment of shoot;
* 		- sj_huntdist (100) - enough distance between player and ball to be hunted;
*		- sj_huntgk (5.0) - time in seconds for cancelling goals after goalkeeper hunt;
* 		- sj_turbo (2) - turbo refresh:
* 			2 - default;
* 			20 - fast.
* 		- sj_resptime (2.0) - delay in seconds before respawning.
* 		- sj_nogoal (0) - goals:
* 			0 - enable;
* 			1 - disable.
* 		- sj_smack (1.0) - smack chance multiplier;
* 		- sj_ljdelay (5.0) - delay in seconds between doing long jumps;
* 		- sj_donate (1) - setting for /$ chat command (public mode only):
* 			0 - no one can donate or give money;
* 			1 - everyone can only donate money;
* 			2 - player can donate and admins can give money;
* 			3 - everyone can give money.
* 		- sj_alienzone (650.0) - radius of alien strikes;
* 		- sj_alienthink (1.0) - period of time in seconds of alien strikes;
* 		- sj_alienmin (8.0) - minimal damage done by alien;
* 		- sj_alienmax (12.0) - maximum damage done by alien;
*		- sj_score - winning score (public mode only);
*		- sj_scoret - current Terrorists score;
*		- sj_scorect - current Counter-Terrorists score;
* 		- sj_idleball (30.0) - idle ball time in seconds.
* 
* 	Remade multi-language support;
* 	Remade help.
*											[Doondook]
*
* --------------------------------------------------------------------------------------------------
*/

#pragma dynamic 131072

#include <amxmisc>
#include <engine>
#include <fakemeta>
#include <cstrike>
#include <fun>
#include <colorchat>
#include <hamsandwich>
//#include <dhudmessage>
#include <nvault>
#include <sqlx>
#include <xs>
#include <geoip>
#include <screenfade_util>
#include <cellarray>
//#include <playermodel>
#include <ftp>
#include <sockets>
//#include <sockets2>
//#include <sockets_hz>
#include <regex>

#define PLUGIN 		"SoccerJam+"
#define VERSION 	"1.0.2"
#define LASTCHANGE 	"2015-01-13"
#define AUTHOR 		"OneEyed&Doondook"

#define MAX_PLAYERS 32

new g_bIsBot, g_bIsAlive, g_bIsConnected

#define SetUserBot(%1) 		g_bIsBot |= 1<<(%1 & (MAX_PLAYERS - 1))
#define ClearUserBot(%1) 	g_bIsBot &= ~(1<<(%1 & (MAX_PLAYERS - 1)))
#define IsUserBot(%1) 		g_bIsBot & 1<<(%1 & (MAX_PLAYERS - 1))

#define SetUserAlive(%1) 	g_bIsAlive |= 1<<(%1 & (MAX_PLAYERS - 1))
#define ClearUserAlive(%1) 	g_bIsAlive &= ~(1<<(%1 & (MAX_PLAYERS - 1)))
#define IsUserAlive(%1) 	g_bIsAlive & 1<<(%1 & (MAX_PLAYERS - 1))

#define SetUserConnected(%1)    g_bIsConnected |= 1<<(%1 & (MAX_PLAYERS - 1))
#define ClearUserConnected(%1) 	g_bIsConnected &= ~(1<<(%1 & (MAX_PLAYERS - 1)))
#define IsUserConnected(%1) 	g_bIsConnected & 1<<(%1 & (MAX_PLAYERS - 1))

#define TOURNAMENTID 	10

#define TEAMS 		4

#define T		1
#define CT		2
#define SPECTATOR 	3
#define UNASSIGNED 	0
static const mdl_mascots[TEAMS][] = {
	"NULL",
	"models/kingpin.mdl",
	"models/garg.mdl",
	"NULL"	
}
static const mdl_mask[TEAMS][] = {
	"NULL", 
	"models/kickball/jason.mdl", 
	"models/kickball/jason.mdl", 
	"NULL"
}
static const mdl_players[TEAMS][] = {
	"NULL", 
	"models/kickball/ronaldo.mdl", 
	"models/kickball/messi.mdl", 
	"NULL"
}


new TeamNames[TEAMS][32] = {
	"Unassigned",
	"T",
	"CT",
	"Spectator"
}
new TeamId[TEAMS]

#define MODE_NONE 	0
#define MODE_PREGAME 	1
#define MODE_GAME 	2
#define MODE_HALFTIME 	3
#define MODE_SHOOTOUT 	4
#define MODE_OVERTIME 	5

#define TYPE_PUBLIC 	0
#define TYPE_TOURNAMENT 1

new GAME_MODE = MODE_PREGAME
new GAME_TYPE

#define SETS_DEFAULT 	0
#define SETS_TRAINING 	1
#define SETS_HEADTOHEAD 2
#define SETS_ROCKET 	3

new GAME_SETS = SETS_DEFAULT

#define BASE_HP 		100
#define BASE_SPEED 		250.0
#define BASE_DISARM		5

#define AMOUNT_POWERPLAY 	5
#define MAX_POWERPLAY		5

// Curve Ball Defines
#define CURVE_ANGLE		15	// Angle for spin kick multipled by current direction
#define CURVE_COUNT		6	// Curve this many times
#define CURVE_TIME		0.2	// Time to curve again
#define DIRECTIONS		2	// # of angles allowed
#define	ANGLEDIVIDE		6	// Divide angle this many times for curve

#define SHOTCLOCK_TIME 		12
#define COUNTDOWN_TIME 		10

#define GOALY_POINTS_CAMP	3

#define HEALTH_REGEN_AMOUNT 	12
#define MAX_GOALY_DISTANCE	600
#define MAX_GOALY_DELAY		7.0

#define MAX_ENEMY_SHOOTOUT_DIST 1200

// $$ for each action
#define POINTS_GOALY_CAMP	20
#define POINTS_GOAL		100
#define POINTS_ASSIST		80
#define POINTS_STEAL		30
#define POINTS_HUNT		0
#define POINTS_BALLKILL		20
#define POINTS_PASS		5
#define POINTS_DISHITS		0
#define POINTS_FAIL		0
#define POINTS_GOALSAVE 	10
#define POINTS_TEAMGOAL		0
#define POINTS_LATEJOIN		60

#define STARTING_CREDITS 	12

// Skills bonuses
#define AMOUNT_STA 		20	// Health
#define AMOUNT_STR 		25	// Stronger kicking
#define AMOUNT_AGI 		13	// Faster Speed 
#define AMOUNT_DEX 		18	// Better Catching
#define AMOUNT_DIS 		6	// Disarm ball chance (disarm lvl * this)

#define MVP_GOAL	100
#define MVP_ASSIST	60
#define MVP_STEAL	30
#define MVP_GOALSAVE	10
#define MVP_HUNT	3
#define MVP_LOSSES	-15

#define MAX_ASSISTERS 	 2
#define MAX_PENSHOOTERS  5
#define PEN_STAND_RADIUS 50.0

#define LIMIT_BALLS 100

#define RECORDS 16
enum {
	GOAL = 1,
	ASSIST,
	STEAL,
	GOALSAVE,
	SMACK,
	HUNT,
	DEATH,
	POSSESSION,
	LOSS,
	PASS,
	BALLKILL,
	HITS,
	BHITS,
	DISHITS,
	DISARMED,
	DISTANCE
}

static const RecordTitles[RECORDS + 1][] = { 	
	"NULL", "GOL", "AST", "STL", "GSV", "SMK", "HNT", "DTH", "POS", 
	"BLS", "PAS", "BKL", "HITS", "BHITS", "DIS", "DISED", "FGL"
}

#define UPGRADES 5
enum {
	STA = 1,	// stamina
	STR,		// strength
	AGI,		// agility
	DEX,		// dexterity
	DIS		// disarm
}

static const UpgradeTitles[UPGRADES + 1][] = { "NULL", "STA", "STR", "AGI", "DEX", "DIS" }
new UpgradeMax[UPGRADES + 1]
new UpgradePrice[UPGRADES + 1][16]
new PlayerUpgrades[MAX_PLAYERS + 1][UPGRADES + 1]
new PlayerDefaultUpgrades[MAX_PLAYERS + 1][UPGRADES + 1]

new PowerPlay[LIMIT_BALLS], PowerPlay_list[LIMIT_BALLS][MAX_POWERPLAY + 1]
new Float:fire_delay[LIMIT_BALLS]

new GoalEnt[TEAMS]

new gTimerEnt
new Float:gTimerEntThink
new PressedAction[MAX_PLAYERS + 1]
new seconds[MAX_PLAYERS + 1]
new g_sprint[MAX_PLAYERS + 1]

new SideJump[MAX_PLAYERS + 1]
new Float:SideJumpDelay[MAX_PLAYERS + 1]

new Mascots[TEAMS]

new menu_upgrade[MAX_PLAYERS + 1]

new winner

new Float:BallSpawnOrigin[3]
new Float:TeamPossOrigins[TEAMS][3]

new Float:TeamBallOrigins[TEAMS][3]
new Float:TEMP_TeamBallOrigins[3]

new Float:MascotsOrigins[3]
new Float:MascotsAngles[3]

new TopPlayer[2][RECORDS + 1]
new MadeRecord[MAX_PLAYERS + 1][RECORDS + 1]
new TempRecord[MAX_PLAYERS + 1][RECORDS + 1]
new TeamRecord[TEAMS][RECORDS + 1]
new TopPlayerName[RECORDS + 1][32]
new g_Experience[MAX_PLAYERS + 1]

new TeamColors[TEAMS][3]

new mdl_ball[256]

new snd_kicked[]	= "kickball/kicked.wav"
new snd_ballhit[] 	= "kickball/bounce.wav"
new snd_distress[] 	= "kickball/distress.wav"
new snd_returned[] 	= "kickball/returned.wav"
new snd_amaze[] 	= "kickball/amaze.wav"
new snd_laugh[] 	= "kickball/laugh.wav"
new snd_perfect[] 	= "kickball/perfect.wav"
new snd_diebitch[] 	= "kickball/diebitch.wav"
new snd_pussy[] 	= "kickball/pussy.wav"
new snd_prepare[] 	= "kickball/prepare.wav"
new snd_gotball[] 	= "kickball/gotball.wav"
new snd_bday[] 		= "kickball/bday.wav"
new snd_levelup[] 	= "kickball/levelup.wav"
new snd_boomchaka[] 	= "kickball/boomchakalaka.wav"
new snd_whistle[] 	= "kickball/whistle.wav"
new snd_whistle_long[] 	= "kickball/whistle_endgame.wav"

new g_maxplayers

// Sprites
new spr_fire
new spr_smoke
new spr_beam
new spr_burn
new spr_fxbeam
new spr_porange
new spr_pass[TEAMS]
new spr_blood_spray
new spr_blood_drop

new g_ballholder[LIMIT_BALLS]
new g_last_ballholder[LIMIT_BALLS ]
new g_last_ballholdername[LIMIT_BALLS][32]
new g_last_ballholderteam[LIMIT_BALLS]
new g_ball[LIMIT_BALLS], g_ball_touched[2]
new g_count_balls
new g_count_scores

new Float:testorigin[LIMIT_BALLS][3], Float:velocity[LIMIT_BALLS][3]
new scoreboard[128]
new g_temp[64], g_temp2[64]
new distorig[2][3] // distance recorder

new msg_deathmsg, msg_statusicon, msg_roundtime, msg_scoreboard, msg_screenshake
new bool:RunOnce

new curvecount[LIMIT_BALLS]
new direction[LIMIT_BALLS]
new Float:BallSpinDirection[LIMIT_BALLS][3]

new g_authid[MAX_PLAYERS + 1][36]

new cv_nogoal, cv_alienzone, cv_alienthink, cv_kick, cv_turbo, cv_reset, cv_resptime, cv_smack, 
cv_ljdelay, cv_huntdist, cv_huntgk, cv_score[3], cv_multiball, cv_lamedist, cv_donate, cv_alienmin, cv_alienmax,
cv_type, cv_time, cv_pointmult, cv_balldist, cv_players, cv_chat, cv_pause

new Handle:sql_tuple, sql_host[64], sql_user[64], sql_pass[64], sql_db[64], sql_table[64], 
sql_mix_table[64], sql_cw_table[64], sql_live_table[64], sql_server_table[64], sql_players, sql_error[512]

new g_cam[MAX_PLAYERS + 1]

new g_vault
new g_current_match, gMatchId, g_temp_current_match

#define MAX_ASSISTERS 2
new g_assisters[MAX_ASSISTERS]
new Float:g_assisttime[MAX_ASSISTERS]

new g_PlayerDeaths[MAX_PLAYERS + 1]

new g_showhelp[MAX_PLAYERS + 1]
new g_distshot

new g_Time[MAX_PLAYERS + 1]
new bool:g_lame = false, bool:g_nogk[TEAMS] = false

new g_votescore[2], g_votechoice[10]

new OFFSET_INTERNALMODEL

new g_Timeleft
new bool:g_Ready[MAX_PLAYERS + 1]
new ROUND

new g_maxcredits

new g_GK[TEAMS]
new g_hatent[MAX_PLAYERS + 1]
new bool:g_GK_immunity[MAX_PLAYERS + 1]

new g_MVP_points[MAX_PLAYERS + 1], g_MVP, g_MVPwebId, g_MVP_name[32]
new gTopPlayers[5]

new g_showhud[MAX_PLAYERS + 1]

static Float:g_StPen[3] = {-224.0, 365.0, 1604.0}
new Float:g_PenOrig[MAX_PLAYERS + 1][3]
new Float:g_penstep[TEAMS] = {0.0, 0.0, 0.0, 0.0}
new freeze_player[MAX_PLAYERS + 1]

new g_regtype

new g_iTeamBall
new ShootOut
new timer
new GoalyPoints[MAX_PLAYERS + 1]
new Float:GoalyCheckDelay[MAX_PLAYERS + 1]
new GoalyCheck[MAX_PLAYERS + 1]
new candidates[TEAMS]
new LineUp[MAX_PENSHOOTERS], PenGoals[TEAMS][MAX_PENSHOOTERS]
new next

new g_Credits[MAX_PLAYERS + 1]

new g_serverip[32]
new g_userip[MAX_PLAYERS + 1][32]
new g_userUTC[MAX_PLAYERS + 1]
new g_list_authid[64][36]
new g_userClanName[MAX_PLAYERS + 1][32]
new g_userClanId[MAX_PLAYERS]
new g_userNationalName[MAX_PLAYERS + 1][32]
new g_userCountry[MAX_PLAYERS + 1][64]
new g_userCountry_2[MAX_PLAYERS + 1][3]
new g_userCountry_3[MAX_PLAYERS + 1][4]
new g_userCity[MAX_PLAYERS + 1][46]
new g_userNationalId[MAX_PLAYERS + 1]

new g_PlayerId[MAX_PLAYERS + 1]
new g_mvprank[MAX_PLAYERS + 1][32]
new g_saveall = 1
new g_TempTeamNames[TEAMS][32]

new HLTV_NAME[] = "^"[AUTO-RECORDING] SJ-PRO.COM^""
new HLTV_IP[] = ""	
new HLTV_PORT = 27221
new HLTV_PW[] = ""
new s_error = 0
new s_handle = 0
new recvattempts = 0
new query_in_progress = 0
new rec_in_progress = 0
new command[256]
new demofile[64]
new bool:is_stopped
new hltvrcon[32]

new FTP_WEB_Server[] = ""
new FTP_WEB_Port = 21
new FTP_WEB_User[] = ""
new FTP_WEB_Pass[] = ""
new FTP_WEB_demo_remotedir[] = "www/sj-pro.com/demos"
new FTP_WEB_plugin_local[] = "soccerjam+.amxx"
new FTP_WEB_plugin_localdir[] = "addons/amxmodx/plugins"
new FTP_WEB_plugin_remote[] = "soccerjam+.amxx"
new FTP_WEB_plugin_remotedir[] = "www/sj-pro.com/plugin/amxmodx/plugins"

new FTP_HLTV_Server[] = "93.191.12.180"
new FTP_HLTV_Port = 21
new FTP_HLTV_User[] = "hltv18027221"
new FTP_HLTV_Pass[] = "hh7TQgEfXE"
new FTP_HLTV_demo_local[] = ""
new FTP_HLTV_demo_localdir[] = ""
new FTP_HLTV_demo_remote[] = ""
new FTP_HLTV_demo_remotedir[] = ""

new Regex:RegexHandle;
new szSocket
new g_wserverip[16], g_serverport[8], g_servername[64]
new g_mapname[32]
new gTournamentId

stock client_cmd2(id, cmd[])
{
	message_begin(MSG_ONE, SVC_DIRECTOR, _, id)
	write_byte(strlen(cmd) + 2)
	write_byte(10)
	write_string(cmd)
	message_end()
}


new wlist_pistols[][] = {
	"weapon_glock18",
	"weapon_usp",
	"weapon_p228",
	"weapon_deagle",
	"weapon_fiveseven"
}
new wlist_primary[][] = {
	"weapon_elite",
	"weapon_galil",
	"weapon_m4a1",
	"weapon_mp5navy",
	"weapon_famas",
	"weapon_ak47",
	"weapon_sg552",
	"weapon_aug",
	"weapon_tmp",
	"weapon_ump45",
	"weapon_mac10",
	"weapon_p90",
	"weapon_scout",
	"weapon_m3",
	"weapon_xm1014",
	"weapon_sg550",
	"weapon_g3sg1",
	"weapon_awp",
	"weapon_m249"
}
enum ReasonCodes{
	DR_TIMEDOUT,
	DR_DROPPED,
	DR_KICKED,
	DR_OTHER
}

new Trie:gTrieStats

//antibhop
enum _:PLAYER_DATA
{
    m_GroundFrames,
    m_OldGroundFrames,
    m_PreJumpGroundFrames,
    m_OldPreJumpGroundFrames,
    m_AirFrames,//useless
    m_JumpHoldFrames,
    m_JumpPressCount,
    m_DuckHoldFrames,
    Float:m_Velocity//useless
};
enum _:WARNINGS_DATA
{
    m_WarnEqualFrames,
    m_WarnGroundEqualFrames,
    m_WarnJumpSpam
}
 
#define MAX_JUMPCOUNT 16
#define MAX_GROUND_FRAME_COINCIDENCE 16
#define MAX_JUMP_SPAM 8
 
new g_ePlayerInfo[33][PLAYER_DATA];
new g_ePlayerWarn[33][WARNINGS_DATA];
new g_ePlayerWarnMax[33][WARNINGS_DATA];

new gGKVoteIsRunning, gGKVoteCount[TEAMS]

// For "gore" shit
new Offset[8][3] = {{0,0,10},{0,0,30},{0,0,16},{0,0,10},{4,4,16},{-4,-4,16},{4,4,-12},{-4,-4,-12}}
new blood_small_red[8]
new blood_large_red[2]
new hiddenCorpse[MAX_PLAYERS + 1]
new mdl_gib_flesh, mdl_gib_head, mdl_gib_legbone
new mdl_gib_lung, mdl_gib_meat, mdl_gib_spine

/*
+-----------------------+--------------------------------------------------------------------------+
|			| ************************************************************************ |
|      [PRECACHE]	| ************************************************************************ |
|			| ************************************************************************ |
+-----------------------+--------------------------------------------------------------------------+
*/

public plugin_precache(){
	new path[64]
	get_configsdir(path, charsmax(path))
	format(path, charsmax(path), "%s/%s", path, "sj_public_plus.cfg")
	
	if (!file_exists(path)){
		log_amx("[SJ] - Can not allocate config file %s", path)
		log_amx("Continue with default settings.")
	} else {
		new linedata[1024], key[64], value[960]
		
		new file = fopen(path, "rt")
		
		new sz_red[4], sz_green[4], sz_blue[4], i, sz_temp[64], x
		//mdl_ball = ArrayCreate(64, 1)
		while(file && !feof(file)){
			i = 0
			fgets(file, linedata, charsmax(linedata))
			
			replace(linedata, charsmax(linedata), "^n", "")
			
			if(!linedata[0] || linedata[0] == ';' 
			|| (linedata[0] == '/' && linedata[1] == '/')
			|| (linedata[0] == '-' && linedata[1] == '-')) 
				continue
			
			strtok(linedata, key, charsmax(key), value, charsmax(value), '=')
			
			trim(key)
			trim(value)
			remove_quotes(value)
	
			if(equal(key, "BALL_MODEL")){
				format(mdl_ball, charsmax(mdl_ball), value)
				precache_model(mdl_ball)
			} else if(equal(key, "BALL_COLOR")){
				strtok(value, sz_red, charsmax(sz_red), value, charsmax(value), ',')
				trim(value)
				strtok(value, sz_green, charsmax(sz_green), sz_blue, charsmax(sz_blue), ',')
				TeamColors[0][0] = str_to_num(sz_red)
				TeamColors[0][1] = str_to_num(sz_green)
				TeamColors[0][2] = str_to_num(sz_blue)
			} else if(equal(key, "T_TEAM_COLOR")){
				strtok(value, sz_red, charsmax(sz_red), value, charsmax(value), ',')
				trim(value)
				strtok(value, sz_green, charsmax(sz_green), sz_blue, charsmax(sz_blue), ',')
				TeamColors[T][0] = str_to_num(sz_red)
				TeamColors[T][1] = str_to_num(sz_green)
				TeamColors[T][2] = str_to_num(sz_blue)
			} else if(equal(key, "CT_TEAM_COLOR")){
				strtok(value, sz_red, charsmax(sz_red), value, charsmax(value), ',')
				strtok(value, sz_green, charsmax(sz_green), sz_blue, charsmax(sz_blue), ',')
				TeamColors[CT][0] = str_to_num(sz_red)
				TeamColors[CT][1] = str_to_num(sz_green)
				TeamColors[CT][2] = str_to_num(sz_blue)
			} else if(contain(key, "LVL_") != -1){
				strtok(key, sz_temp, charsmax(sz_temp), key, charsmax(key), '_')
				for(i = 1; i <= UPGRADES; i++){
					if(equal(key, UpgradeTitles[i])){
						UpgradeMax[i] = str_to_num(value)
						break
					}
				}
			} else if(contain(key, "PRICE_") != -1){
				strtok(key, sz_temp, charsmax(sz_temp), key, charsmax(key), '_')
				for(i = 1; i <= UPGRADES; i++){
					if(equal(key, UpgradeTitles[i])){
						add(value, charsmax(value), ",")
						x = 0
						while(replace(value, charsmax(value), ",", "#") && x < UpgradeMax[i]){
							strtok(value, sz_temp, charsmax(sz_temp), value, charsmax(value), '#')
							UpgradePrice[i][x++] = str_to_num(sz_temp)
						}
						break
					}
				}
			} else if(contain(key, "POINTS_") != -1){
				
			
			} else if(equal(key, "VOTE_GOALS")){
				add(value, charsmax(value), " ")
				x = 1
				while(replace(value, charsmax(value), ",", "#") && x < 10){
					strtok(value, sz_temp, charsmax(sz_temp), value, charsmax(value), '#')
					g_votechoice[x++] = str_to_num(value)
				}
				g_votechoice[0] = x
			} else if(equal(key, "SQL_HOST")){
				format(sql_host, charsmax(sql_host), value)
			} else if(equal(key, "SQL_USER")){
				format(sql_user, charsmax(sql_user), value)
			} else if(equal(key, "SQL_PASS")){
				format(sql_pass, charsmax(sql_pass), value)
			} else if(equal(key, "SQL_DATABASE")){
				format(sql_db, charsmax(sql_db), value)
			} else if(equal(key, "SQL_TABLE")){
				format(sql_table, charsmax(sql_table), value)
			} else if(equal(key, "SQL_SERVER_TABLE")){
				format(sql_server_table, charsmax(sql_server_table), value)
			} else if(equal(key, "SQL_MIX_TABLE")){
				format(sql_mix_table, charsmax(sql_table), value)
			} else if(equal(key, "SQL_CW_TABLE")){
				format(sql_cw_table, charsmax(sql_table), value)
			} else if(equal(key, "SQL_LIVE_TABLE")){
				format(sql_live_table, charsmax(sql_table), value)
			} else if(equal(key, "GAME_DESC")){
				if(str_to_num(value)){
				}
			} else if(equal(key, "LONG_JUMP_ANIM")){
				if(str_to_num(value)){
					register_forward(FM_AddToFullPack, "FWD_AddToFullpack", 1)
				}
			}
			//else log_amx("[SJ] - Key %s from config file has not been found!", key)
		}
		if(file) fclose(file)
	}
	
	g_vault = nvault_open("nv_soccerjam+")
	
	if(g_vault == INVALID_HANDLE)
		log_amx("[SJ] - Error opening nVault!")
		
	precache_model(mdl_mascots[T])
	precache_model(mdl_mascots[CT])
	precache_model("models/chick.mdl")
	precache_model("models/rpgrocket.mdl")
	precache_model(mdl_mask[T])
	precache_model(mdl_mask[CT])
	mdl_gib_flesh = precache_model("models/Fleshgibs.mdl")
	mdl_gib_meat = precache_model("models/GIB_B_Gib.mdl")
	mdl_gib_head = precache_model("models/GIB_Skull.mdl")
	mdl_gib_spine = precache_model("models/GIB_B_Bone.mdl")
	mdl_gib_lung = precache_model("models/GIB_Lung.mdl")
	mdl_gib_legbone = precache_model("models/GIB_Legbone.mdl")

	//precache_model(mdl_players[T])
	//precache_model(mdl_players[CT])
	
	
	spr_beam 	= 	precache_model("sprites/laserbeam.spr")
	spr_fire 	= 	precache_model("sprites/shockwave.spr")
	spr_smoke 	= 	precache_model("sprites/steam1.spr")
	spr_fxbeam 	= 	precache_model("sprites/laserbeam.spr")
	spr_burn 	= 	precache_model("sprites/xfireball3.spr")
	if(GAME_TYPE == TYPE_PUBLIC){
		spr_porange 	= 	precache_model("sprites/kickball/orange.spr")	
	}
	spr_pass[T]	= 	precache_model("sprites/kickball/Tpass.spr")
	spr_pass[CT]	= 	precache_model("sprites/kickball/CTpass.spr")
	spr_blood_spray 	=	precache_model("sprites/bloodspray.spr")
	spr_blood_drop 	= 	precache_model("sprites/blood.spr")
	
	precache_sound(snd_amaze)
	precache_sound(snd_laugh)
	precache_sound(snd_perfect)
	precache_sound(snd_diebitch)
	precache_sound(snd_pussy)
	precache_sound(snd_prepare)
	precache_sound(snd_ballhit)
	precache_sound(snd_gotball)
	precache_sound(snd_bday)
	precache_sound(snd_returned)
	precache_sound(snd_distress)
	precache_sound(snd_kicked)
	precache_sound(snd_levelup)
	precache_sound(snd_boomchaka)
	precache_sound(snd_whistle)
	precache_sound(snd_whistle_long)
	
	//precache_generic("sound/misc/loading/ussr.mp3")
}

/*
+-----------------------+--------------------------------------------------------------------------+
|			| ************************************************************************ |
|      [INITIALIZE]	| ************************************************************************ |
|			| ************************************************************************ |
+-----------------------+--------------------------------------------------------------------------+
*/
new g_debug = 0

public plugin_init(){
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	get_mapname(g_mapname, 31)
	
	if(contain(g_mapname, "soccer") == -1 && contain(g_mapname, "sj") == -1){
		set_fail_state("[SJ] - SoccerJam works only at sj_ maps!")
	}
	
	if(	
		contain(g_mapname, "soccerjam") != -1
	){
		CreateGoalNets()
	}
	
	if(	
		equal(g_mapname, "soccerjam")
	){
		CreateWall()
	}
	set_cvar_num("sv_proxies", 1) // for HLTV part
	set_cvar_num("mp_friendlyfire", 0)
	
	register_dictionary("sj_public_plus_hud.txt")
	register_dictionary("sj_public_plus_motd.txt")
	
	register_forward(FM_GetGameDescription, "FWD_GameDescription")
	register_forward(FM_CmdStart, 		"FWD_CmdStart")
	
	g_maxplayers 	= get_maxplayers()
	
	msg_deathmsg 	= get_user_msgid("DeathMsg")
	msg_statusicon 	= get_user_msgid("StatusIcon")
	msg_roundtime 	= get_user_msgid("RoundTime")
	msg_scoreboard 	= get_user_msgid("ScoreInfo")
	msg_screenshake = get_user_msgid( "ScreenShake" );
	
	OFFSET_INTERNALMODEL = is_amd64_server() ? 152 : 126
	
	set_msg_block(get_user_msgid("RoundTime"), 	BLOCK_SET)
	set_msg_block(get_user_msgid("ClCorpse"), 	BLOCK_SET)
	
	register_message(get_user_msgid("Money"), 	"Msg_Money")
  	register_message(get_user_msgid("TextMsg"), 	"Msg_CenterText")
	register_message(get_user_msgid("SendAudio"),	"Msg_Sound")
  	register_message(msg_statusicon, 		"Msg_StatusIcon")
	//register_message(122, 	"Msg_ClCorpse")
	
	register_event("HLTV",		"Event_StartRound", "a", "1=0", "2=0")
	register_event("ShowMenu", 	"menuclass", "b", "4&CT_Select", "4&Terrorist_Select")
	register_event("VGUIMenu", 	"menuclass", "b", "1=26", "1=27")
	register_event("TeamScore", 	"Event_TeamScore", "b")	
	
	RegisterHam(Ham_TakeDamage, 	"player", "PlayerDamage")
	RegisterHam(Ham_Spawn, 		"player", "PlayerSpawned", 1)
	RegisterHam(Ham_Killed, 	"player", "PlayerKilled")
	
	cv_type		=	register_cvar("sj_type", 	"1")
	cv_huntdist 	=	register_cvar("sj_huntdist", 	"0")
	cv_huntgk	=	register_cvar("sj_huntgk", 	"5.0")
	cv_lamedist 	=	register_cvar("sj_lamedist", 	"0")
	cv_score[0] 	= 	register_cvar("sj_score", 	"30")
	cv_score[T] 	= 	register_cvar("sj_scoret", 	"0")
	cv_score[CT] 	= 	register_cvar("sj_scorect", 	"0")
	cv_reset 	= 	register_cvar("sj_idleball",	"30.0")
	cv_alienzone 	= 	register_cvar("sj_alienzone",	"650")
	cv_alienthink	=	register_cvar("sj_alienthink",	"1.0")
	cv_alienmin	=	register_cvar("sj_alienmin",	"8.0")
	cv_alienmax	=	register_cvar("sj_alienmax",	"12.0")
	cv_kick 	= 	register_cvar("sj_kick",	"650")
	cv_turbo 	= 	register_cvar("sj_turbo", 	"2")
	cv_resptime 	=	register_cvar("sj_resptime", 	"2.0")
	cv_nogoal 	=	register_cvar("sj_nogoal", 	"0")
	cv_smack	=	register_cvar("sj_smack", 	"80")
	cv_ljdelay	=	register_cvar("sj_ljdelay", 	"5.0")
	cv_multiball	=	register_cvar("sj_multiball", 	"15")
	cv_donate 	= 	register_cvar("sj_donate", 	"1")
	cv_chat 	=	register_cvar("sj_chat", 	"1")
	cv_time 	= 	register_cvar("sj_time", 	"30")
	cv_pointmult 	=	register_cvar("sj_mpoint",	"3.5")
	cv_balldist	= 	register_cvar("sj_balldist", 	"1600")
	cv_players 	= 	register_cvar("sj_players", 	"5")
	cv_pause	= 	register_cvar("sj_pause", 	"0")
	
	register_touch("PwnBall", "player", 		"touch_Player")
	register_touch("PwnBall", "soccerjam_goalnet",	"touch_Goalnet")
	register_touch("PwnBall", "worldspawn",		"touch_World")
	register_touch("PwnBall", "func_wall",		"touch_World")
	register_touch("PwnBall", "func_door",		"touch_World")
	register_touch("PwnBall", "func_door_rotating", "touch_World")
	register_touch("PwnBall", "func_wall_toggle",	"touch_World")
	register_touch("PwnBall", "func_breakable",	"touch_World")
	register_touch("PwnBall", "func_blocker",	"touch_World")
	//register_touch("PwnBall", "PwnBall",		"touch_Ball")
	
	set_task(0.4, "Meter", _, _, _, "b")
	set_task(1.0, "Event_Radar", _, _, _, "b")
	
	set_task(180.0, "Announce", _, _, _, "b")
	
	register_think("PwnBall", 	"think_Ball")
	register_think("Mascot", 	"think_Alien")
	
	register_clcmd("say",		"ChatCommands")		// handle say
	register_clcmd("say_team",	"ChatCommands_team")	// handle say_team
	register_clcmd("drop",		"Turbo")		// use turbo
	register_clcmd("lastinv",	"BuyUpgrade")		// skills menu
	register_clcmd("radio1", 	"CurveLeft")		// curve left
	register_clcmd("radio2", 	"CurveRight")		// curve right
	register_clcmd("fullupdate", 	"BlockCommand")		// block fullupdate
	
	register_concmd("amx_endgame", 	"EndGame", 	ADMIN_KICK, 	"Ends a current match")
	register_concmd("sj_endgame", 	"EndGame", 	ADMIN_KICK, 	"Ends a current match")
	register_concmd("showbriefing", "AdminMenu", 	ADMIN_KICK, 	"SJ Admin Menu")
	register_concmd("nightvision", 	"CameraChanger",_,		"Switches camera view")
	//register_concmd("sj_update", 	"Update", 	_,  		"Updates plugin")
	register_concmd("amx_restart", 	"Restart",	ADMIN_KICK, 	"Restart server")
	register_concmd("test", 	"test",		ADMIN_KICK, 	"Test command")
	register_concmd("sj_version", 	"Version",	_, 		"Shows plugin's version info")
	register_concmd("jointeam", 	"BlockCommand")
	
	register_menucmd(register_menuid("Team_Select",1), (1<<0)|(1<<1)|(1<<4)|(1<<5), "team_select")

	set_pcvar_num(cv_score[T], 0)
	set_pcvar_num(cv_score[CT], 0)
	
	GAME_TYPE = get_pcvar_num(cv_type)
	if(GAME_TYPE == TYPE_PUBLIC){
		GAME_MODE = MODE_GAME
		gTournamentId = TOURNAMENTID
	} else {
		GAME_MODE = MODE_NONE
		gTournamentId = TOURNAMENTID
	}
	g_Timeleft = get_pcvar_num(cv_time) * 60
	new x
	for(x = 1; x <= UPGRADES; x++){
		g_maxcredits += (UpgradeMax[x] + 1)
	}
	for(x = 1; x <= g_maxplayers; x++){
		g_Credits[x] = STARTING_CREDITS
		g_Experience[x] = 0
		g_PenOrig[x][0] = g_StPen[0]
		g_PenOrig[x][1] = 0.0
		g_PenOrig[x][2] = g_StPen[2]
	}
	TeamId[UNASSIGNED] = 0
	TeamId[SPECTATOR] = 0
	TeamId[T] = -1
	TeamId[CT] = -2
	
	gTimerEnt = create_entity("info_target")
	if(gTimerEnt) {
		if(GAME_TYPE == TYPE_PUBLIC){
			gTimerEntThink = 0.2
		} else {
			gTimerEntThink = 0.5
		}
		set_pev(gTimerEnt, pev_classname, "StatusTimer")
		register_think("StatusTimer", "StatusDisplay")
		set_pev(gTimerEnt, pev_nextthink, halflife_time() + gTimerEntThink)
	} else {
		set_fail_state("Cannot create StatusTimer entity.")
	}
	
	
	get_user_ip(0, g_serverip, charsmax(g_serverip), 0)
	get_user_ip(0, g_userip[0], 31, 1)
	
	gTrieStats = TrieCreate()
	
	sql_connect()

	SwitchGameSettings(0, SETS_DEFAULT)
	
	set_task(300.0, "sql_updateServerInfo", 43041, _, _, "b")
	
	/*get_cvar_string( "port", g_serverport, charsmax(g_serverport))
	get_cvar_string( "ip", g_wserverip, charsmax(g_wserverip))
	get_cvar_string( "hostname", g_servername, charsmax(g_servername))
	new result, errorstr[ 2 ], errorno
	RegexHandle = regex_compile( "jsonp=(.+)&_=", result, errorstr, charsmax( errorstr ), "i" )
	szSocket = socket_listen( g_wserverip, 1107, SOCKET_TCP, errorno )
	set_task( 0.1, "OnSocketReply", _, _, _, "b")*/
	
	blood_small_red = {190,191,192,193,194,195,196,197}
	blood_large_red = {204,205}
	
	if(!g_current_match)
		PostGame()

	set_task(30.0, "AutoMultiBall")
		
	return PLUGIN_HANDLED
}

public test(id, level, cid){
	if(!cmd_access(id, level, cid, 0))
		return PLUGIN_HANDLED
		
	//WakeUpNonReady(id)
	FX_ScreenShake(id)
	return PLUGIN_HANDLED
}

public AutoMultiBall(){
	if(GAME_MODE == MODE_PREGAME || GAME_MODE == MODE_HALFTIME){
		new szCount = 0
		for(new i = 1; i <= MAX_PLAYERS; i++){
			if(IsUserConnected(i) && ~IsUserBot(i)){
				szCount++
			}
		}
		
		if(szCount == 0){
			if(!g_count_balls){
				new sz_cvar = get_pcvar_num(cv_multiball)
				if(sz_cvar < 0 || sz_cvar > LIMIT_BALLS){
					sz_cvar = g_maxplayers
					set_pcvar_num(cv_multiball, sz_cvar)
				}
				for(new i = 1; i < sz_cvar; i++){
					CreateBall(i)
					MoveBall(1, 0, i)
				}
				if(GAME_SETS == SETS_DEFAULT){
					SwitchGameSettings(0, SETS_TRAINING)
				}
			}
		}
	}
}

public Announce(){
	if(GAME_MODE == MODE_PREGAME){
		for(new id = 1; id <= g_maxplayers; id++){
			if(~IsUserConnected(id) || IsUserBot(id) || g_showhelp[id])
				continue
				
			//ColorChat(id, RED, "^3Lonely Tournament ^4(1 vs. 1) is coming up!")
			//ColorChat(id, BLUE, "^1You need to register ^3(link on http://sj-pro.com)")
			//ColorChat(id, GREY, "^1Weed Arena Public ^3->^4 89.40.233.146:27015")
			ColorChat(id, RED, "^3SoccerJam World Cup 2018^1 [23.06.2018 - 10.07.2018]")
			ColorChat(id, GREY, "Link in your console.")
			client_print(id, print_console, "occerJam World Cup 2018 [23.06.2018 - 10.07.2018]")
			client_print(id, print_console, "https://steamcommunity.com/groups/SJ-Pro#announcements/detail/1648761723416537141")
			
			
		}
	}	
}

public Restart(id, level, cid){
	if(!cmd_access(id, level, cid, 0))
		return PLUGIN_HANDLED
	new sz_name[32]
	get_user_name(id, sz_name, charsmax(sz_name))
	client_print(0, print_console, "[SJ] - Restart server. (ADMIN: %s)", sz_name)
	ColorChat(0, GREEN, "^4[SJ] ^1- Restart server. (ADMIN: %s)", sz_name)
	set_task(2.0, "task_Restart")
	return PLUGIN_HANDLED
}

public task_Restart(){
	server_cmd("restart")
}

public Version(id){
	console_print(id, "SoccerJam+ v.%s | %s", VERSION, LASTCHANGE)
	console_print(id, "Original version by OneEyed. Improved by Doondook.")
	console_print(id, "Official web-site: http://sj-pro.com")
	
	return PLUGIN_HANDLED
}

public Update(id){
	if(is_user_admin(id) || equal(g_authid[id], "STEAM_0:0:19857433")){
		FTP_Open(FTP_WEB_Server, FTP_WEB_Port, FTP_WEB_User, FTP_WEB_Pass, "FwdFuncOpen")
		set_task(2.0, "Get_Plugin")
	} else {
		console_print(id, "You have no access to this command!")
	}
	return PLUGIN_HANDLED
}
/*
+-----------------------+--------------------------------------------------------------------------+
|			| ************************************************************************ |
|	  [BALL]	| ************************************************************************ |
|			| ************************************************************************ |
+-----------------------+--------------------------------------------------------------------------+
*/

public CreateBall(i){
	if(i >= LIMIT_BALLS)
		return PLUGIN_HANDLED
		
	g_ballholder[i] = 0
	g_last_ballholder[i] = 0 
	g_last_ballholderteam[i] = 0
	fire_delay[i] = 0.0
	PowerPlay[i] = 0
	for(new x = 0; x <= MAX_POWERPLAY; x++)
		PowerPlay_list[i][x] = 0	
	
	if(!is_valid_ent(g_ball[i])){	
		new entity = create_entity("info_target")
		if(entity){
			entity_set_model(entity, mdl_ball)
			set_pev(entity, pev_classname, "PwnBall")
			
			set_pev(entity, pev_solid, SOLID_BBOX)
			set_pev(entity, pev_movetype, MOVETYPE_BOUNCE)
		
			entity_set_vector(entity, EV_VEC_mins, Float:{ -15.0, -15.0, 0.0 })
			entity_set_vector(entity, EV_VEC_maxs, Float:{ 15.0, 15.0, 12.0 })
			set_pev(entity, pev_framerate, 0.0)
			set_pev(entity, pev_sequence, 0)
			
			glow(entity, TeamColors[0][0], TeamColors[0][1], TeamColors[0][2])
			
			g_ball[i] = entity
		
			remove_task(i + 55555)
	
			set_pev(entity, pev_nextthink, halflife_time() + 0.05)
			
			if(i) g_count_balls++
		} else {
			client_print(0, print_chat, "[CreateBall] - Creating ball #%d error!")
		}	
	}
	
	return PLUGIN_HANDLED
}

public RemoveBall(i){
	if(i >= LIMIT_BALLS)
		return PLUGIN_HANDLED
		
	if(is_valid_ent(g_ball[i])){
		remove_entity(g_ball[i])
		if(g_ballholder[i])
			glow(g_ballholder[i], 0, 0, 0)
		g_ballholder[i] = 0
		g_last_ballholder[i] = 0 
		g_last_ballholderteam[i] = 0
		g_ball[i] = 0
		format(g_last_ballholdername[i], 31, "")
		fire_delay[i] = 0.0
		PowerPlay[i] = 0
		for(new x = 0; x <= MAX_POWERPLAY; x++)
			PowerPlay_list[i][x] = 0
		if(i) g_count_balls--
	}
	
	return PLUGIN_HANDLED
}

public think_Ball(){
	new x
	for(new i = 0; i <= g_count_balls; i++){
		if(is_valid_ent(g_ball[i])){
			if(PowerPlay[i] >= MAX_POWERPLAY && get_gametime() - fire_delay[i] >= 0.3){
				on_fire(i)
			}
			
			if(g_ballholder[i]){
				pev(g_ballholder[i], pev_origin, testorigin[i])
				
				if(pev(g_ball[i], pev_solid) != SOLID_NOT)
					set_pev(g_ball[i], pev_solid, SOLID_NOT)
	
				// Put ball in front of player
				ball_infront(g_ballholder[i], 50.0)
				for(x = 0; x < 3; x++)	
					velocity[i][x] = 0.0

				// Add lift to z axis
				if(pev(g_ballholder[i], pev_flags) & FL_DUCKING){
					testorigin[i][2] -= 20
				} else {
					testorigin[i][2] -= 30
				}
				
				set_pev(g_ball[i], pev_velocity, velocity[i])
				set_pev(g_ball[i], pev_origin, testorigin[i])
			} else if(pev(g_ball[i], pev_solid) != SOLID_BBOX) {
				set_pev(g_ball[i], pev_solid, SOLID_BBOX)
			}
				
		}
		set_pev(g_ball[i], pev_nextthink, halflife_time() + 0.05)
	}
	
	return PLUGIN_HANDLED
}

stock MoveBall(where, team = 0, i){	
	new k = i
	if(i < 0){
		k = g_count_balls
		i = 0
	}
	for(; i <= k; i++){
		if(is_valid_ent(g_ball[i])){
			if(g_ballholder[i])
				glow(g_ballholder[i], 0, 0, 0)
			PowerPlay[i] = 0
			g_ballholder[i] = 0
			g_last_ballholder[i] = 0
			format(g_last_ballholdername[i], 31, "")
			for(new t = 0; t < MAX_ASSISTERS; t++){
				g_assisters[t] = 0
				g_assisttime[t] = 0.0
			}
			remove_task(-77002 + g_ball[i])
			if(team){
				// own goalnet
				if(g_iTeamBall == 0){
					entity_set_origin(g_ball[i], TeamBallOrigins[team])
					entity_set_vector(g_ball[i], EV_VEC_velocity, Float:{0.0, 0.0, 50.0})	
				// team side
				} else {
					new Float:sz_orig[3]
					for(new x = 0; x < 3; x++){
						sz_orig[x] = TeamPossOrigins[team][x]
					}
					
					if(team == T){
						sz_orig[0] -= get_pcvar_num(cv_balldist)
					} else {
						sz_orig[0] += get_pcvar_num(cv_balldist)
					}
					
					if(i & 1 || !i){
						sz_orig[1] -= 50.0 * i
						sz_orig[2] += 25.0 * i
					} else {
						sz_orig[1] += (50.0 * (i - 1))
						sz_orig[2] += 25.0 * (i - 1)
					}
					
					entity_set_origin(g_ball[i], sz_orig)
					formatex(g_temp, charsmax(g_temp), "Ball is at %s side!", TeamNames[team])
					entity_set_vector(g_ball[i], EV_VEC_velocity, Float:{0.0, 0.0, 50.0})		
				}
			} else {
				switch(where){
					case 0: { // outside map
						
						new Float:orig[3], x
						for(x = 0; x < 3; x++)
							orig[x] = -9999.9
						orig[1] += (50.0 * i)
						entity_set_origin(g_ball[i], orig)
						remove_task(i + 55555)
						
						PowerPlay[i] = 0
					}
					case 1: { // at middle	
						//set_pev(g_ball[i], pev_solid, SOLID_NOT)
						
						new Float:sz_orig[3] 
						sz_orig = BallSpawnOrigin
						if(i & 1 || !i){
							sz_orig[1] -= 50.0 * i
							sz_orig[2] += 25.0 * i
						} else {
							sz_orig[1] += (50.0 * (i - 1))
							sz_orig[2] += 25.0 * (i - 1)
						}
						
						/*new j
						for(j = 0; j <= g_count_balls; j++){
						}
						
						new Float:szKickX = 300.0, Float:szKickY = 0.0
						new Float:szAngle = (i * (360 / j / 3.14))
						new Float:szX = rotateX(szKickX, szKickY, szAngle)
						new Float:szY = rotateY(szKickX, szKickY, szAngle)
							
						new Float:szKickVec[3]
						szKickVec[0] = szX
						szKickVec[1] = szY
						szKickVec[2] = 200.0
						entity_set_origin(g_ball[i], sz_orig)
						entity_set_vector(g_ball[i], EV_VEC_velocity, szKickVec)
						client_print(0, print_chat, "[%d] %0.f , %0.f  (%0.f)", i, szX, szY, szAngle)
						
						set_task(1.5, "MakeBallsSolid")*/
						
						entity_set_origin(g_ball[i], sz_orig)
						entity_set_vector(g_ball[i], EV_VEC_velocity, Float:{0.0, 0.0, 400.0})
						format(g_temp, charsmax(g_temp), "%L", LANG_SERVER, "SJ_MIDDLEBALL")
					}
				}
			}
		}
	}
}
public MakeBallsSolid(){
	for(new i = 0; i <= g_count_balls; i++){
		if(is_valid_ent(g_ball[i])){
			set_pev(g_ball[i], pev_solid, SOLID_BBOX)
		}
	
	}
}

Float:rotateX(Float:X, Float:Y, Float: A){
	return (X * floatcos(A) - Y * floatsin(A))
}
Float:rotateY(Float:X, Float:Y, Float: A){
	return (X * floatsin(A) - Y * floatcos(A))
}
public KickBall(id, velType){
	new i
	for(i = 0; i <= g_count_balls; i++)
		if(id == g_ballholder[i])
			break
			
	if(i == g_count_balls + 1){
		client_print(id, print_chat, "[ERROR] Ball has not been found! [KickBall]")
		return PLUGIN_HANDLED
	}
	remove_task(55555 + i)
	set_task(get_pcvar_float(cv_reset), "ClearBall", 55555 + i)
	
	new team = get_user_team(id)
	new x
	
	// Give it some lift
	ball_infront(id, 55.0)

	testorigin[i][2] += 10

	new Float:tempO[3], Float:returned1[3]
	new Float:dist2

	pev(id, pev_origin, tempO)
	new tempEnt = trace_line(id, tempO, testorigin[i], returned1)

	dist2 = get_distance_f(testorigin[i], returned1)

	if(point_contents(testorigin[i]) != CONTENTS_EMPTY || (~IsUserConnected(tempEnt) && dist2)){	
		return PLUGIN_HANDLED
	} else {
		// Check if our ball isn't inside a wall before kicking
		new Float:ballF[3], Float:ballR[3], Float:ballL[3]
		new Float:ballB[3], Float:ballTR[3], Float:ballTL[3]
		new Float:ballBL[3], Float:ballBR[3]

		for(x = 0; x < 3; x++){
			ballF[x]  = testorigin[i][x];	ballR[x]  = testorigin[i][x]
			ballL[x]  = testorigin[i][x];	ballB[x]  = testorigin[i][x]
			ballTR[x] = testorigin[i][x];	ballTL[x] = testorigin[i][x]
			ballBL[x] = testorigin[i][x];	ballBR[x] = testorigin[i][x]
		}
		
		x = 6
		while(x--){
			ballF[1]  += 3.0;	ballB[1]  -= 3.0
			ballR[0]  += 3.0;	ballL[0]  -= 3.0
			ballTL[0] -= 3.0;	ballTL[1] += 3.0
			ballTR[0] += 3.0;	ballTR[1] += 3.0
			ballBL[0] -= 3.0;	ballBL[1] -= 3.0
			ballBR[0] += 3.0;	ballBR[1] -= 3.0

			if(point_contents(ballF) 	!= CONTENTS_EMPTY 
			|| point_contents(ballR) 	!= CONTENTS_EMPTY 
			|| point_contents(ballL) 	!= CONTENTS_EMPTY 
			|| point_contents(ballB)  	!= CONTENTS_EMPTY 
			|| point_contents(ballTR) 	!= CONTENTS_EMPTY 
			|| point_contents(ballTL) 	!= CONTENTS_EMPTY 
			|| point_contents(ballBL) 	!= CONTENTS_EMPTY 
			|| point_contents(ballBR) 	!= CONTENTS_EMPTY)
				return PLUGIN_HANDLED
		}
		
		new ent = -1
		testorigin[i][2] += 35.0

		while((ent = find_ent_in_sphere(ent, testorigin[i], 35.0)) != 0){
			if(ent > g_maxplayers){
				new classname[32]
				pev(ent, pev_classname, classname, 31)

				if((contain(classname, "goalnet") != -1 || contain(classname, "func_") != -1) &&
				!equal(classname, "func_water") && !equal(classname, "func_illusionary"))
					return PLUGIN_HANDLED
			}
		}
		testorigin[i][2] -= 35.0
	}
		
	new Float:ballorig[3], kickVel
	pev(id, pev_origin, ballorig)
	
	if(!velType){
		new str = (PlayerUpgrades[id][STR] * AMOUNT_STR) + (AMOUNT_POWERPLAY * (PowerPlay[i] * 5))
		kickVel = get_pcvar_num(cv_kick) + str
		kickVel += g_sprint[id] * 100
		
		if(direction[i]){
			pev(id, pev_angles, BallSpinDirection[i])
			curvecount[i] = CURVE_COUNT
		}
		new sz_data[2]
		sz_data[0] = id
		sz_data[1] = i
		set_task(CURVE_TIME * 2, "CurveBall", id, sz_data, 2)
	} else {
		curvecount[i] = 0
		direction[i] = 0
		kickVel = random_num(100, 600)
	}

	velocity_by_aim(id, kickVel, velocity[i])
	for(x = 0; x < 3; x++)
		distorig[0][x] = floatround(ballorig[x])
	
	if(PowerPlay[i] >= MAX_POWERPLAY){
		message_begin(MSG_ONE, msg_statusicon, {0,0,0}, g_ballholder[i])
		write_byte(0) // status (0 = hide, 1 = show, 2 = flash)
		write_string("dmg_heat") // sprite name
		write_byte(0) // red
		write_byte(0) // green
		write_byte(0) // blue
		message_end()
	}
	
	(g_nogk[team==T?CT:T])?(g_lame = true):(g_lame = false)
	
	g_ballholder[i] = 0
	g_last_ballholder[i] = id
	g_last_ballholderteam[i] = team
	
	set_pev(g_ball[i], pev_origin, testorigin[i])
	set_pev(g_ball[i], pev_velocity, velocity[i])
	
	emit_sound(g_ball[i], CHAN_ITEM, snd_kicked, 1.0, ATTN_NORM, 0, PITCH_NORM)
	
	glow(id, 0, 0, 0)
	
	beam(10, g_ball[i])
	
	get_user_name(id, g_last_ballholdername[i], 31)
	format(g_temp, charsmax(g_temp), "|%s| %s^n%L", TeamNames[team], g_last_ballholdername[i], 
	LANG_SERVER, "SJ_KICKBALL")

	return PLUGIN_HANDLED
}

public ball_infront(id, Float:dist){
	new i
	for(i = 0; i <= g_count_balls; i++){
		if(id == g_ballholder[i])
			break
	}
	if(i == g_count_balls + 1){
		client_print(id, print_chat, "[ERROR] Ball has not been found! [Ball infront]")
		return PLUGIN_HANDLED
	}
	new Float:nOrigin[3]
	new Float:vAngles[3] // plug in the view angles of the entity
	new Float:vReturn[3] // to get out an origin fDistance away
	
	pev(g_ball[i], pev_origin, testorigin[i])
	pev(id, pev_origin, nOrigin)
	pev(id, pev_v_angle, vAngles)
		
	vReturn[0] = floatcos(vAngles[1], degrees) * dist
	vReturn[1] = floatsin(vAngles[1], degrees) * dist
		
	vReturn[0] += nOrigin[0]
	vReturn[1] += nOrigin[1]
		
	testorigin[i][0] = vReturn[0] 
	testorigin[i][1] = vReturn[1]
	testorigin[i][2] = nOrigin[2]
	
	return PLUGIN_HANDLED
}

public on_fire(i){
	if(is_valid_ent(g_ball[i])){
		new Float:forig[3], forigin[3]
		fire_delay[i] = get_gametime()
			
		entity_get_vector(g_ball[i], EV_VEC_origin, forig)
		
		for(new x = 0; x < 3; x++)
			forigin[x] = floatround(forig[x])
			
		message_begin(MSG_BROADCAST,SVC_TEMPENTITY)
		write_byte(17)
		write_coord(forigin[0] + random_num(-5, 5))
		write_coord(forigin[1] + random_num(-5, 5))
		write_coord(forigin[2] + 10 + random_num(-5, 5))
		write_short(spr_burn)
		write_byte(7)
		write_byte(235)
		message_end()
	}
}

public CurveBall(sz_data[]){
	new id = sz_data[0]
	new i = sz_data[1]

	if(direction[i] && get_speed(g_ball[i]) > 5 && curvecount[i] > 0){
		new Float:v[3], Float:v_forward[3]
			
		pev(g_ball[i], pev_velocity, v)
		vector_to_angle(v, BallSpinDirection[i])
	
		BallSpinDirection[i][1] = normalize(BallSpinDirection[i][1] + float((direction[i] * CURVE_ANGLE) / ANGLEDIVIDE))
		BallSpinDirection[i][2] = 0.0
			
		angle_vector(BallSpinDirection[i], 1, v_forward)
			
		new Float:speed = vector_length(v)
		v[0] = v_forward[0] * speed
		v[1] = v_forward[1] * speed
			
		set_pev(g_ball[i], pev_velocity, v)

		curvecount[i]--
		new sz_data[2]
		sz_data[0] = id
		sz_data[1] = i
		set_task(CURVE_TIME, "CurveBall", id, sz_data, 2)
	}
}

public ClearBall(i){
	i -= 55555
	if(is_valid_ent(g_ball[i])){
		play_wav(0, snd_returned)
		format(g_temp, charsmax(g_temp), "%L", LANG_SERVER, "SJ_MIDDLEBALL")
		MoveBall(1, 0, i)
	}
}

/*
+-----------------------+--------------------------------------------------------------------------+
|			| ************************************************************************ |
|	[DISPLAY]	| ************************************************************************ |
|			| ************************************************************************ |
+-----------------------+--------------------------------------------------------------------------+
*/

public SetUserConfig(id, const cvar[], const value[]){
	if(str_to_num(value) != 0){
		server_cmd("kick #%d  ^"Set cl_filterstuffcmd to 0^"", get_user_userid(id))
	} else {
		client_cmd(id, "cl_updaterate 101;cl_cmdrate 101;fps_max 101;rate 25000")
	}
}
public StatusDisplay_Restart(){
	//new Float:szDelay = halflife_time() + 1.0
	
	new Float:szDelay = random_float(0.3, 0.4)
	new Float:nextAlien
	pev(Mascots[T], pev_nextthink, nextAlien)
	new Float:nextTimer 
	pev(gTimerEnt, pev_nextthink, nextTimer)

	if(nextAlien - nextTimer > gTimerEntThink){
		nextAlien -= szDelay
	}

	set_pev(gTimerEnt, pev_nextthink, nextTimer + szDelay)
	set_pev(Mascots[T], pev_nextthink, nextAlien + szDelay)
	set_pev(Mascots[CT], pev_nextthink, nextAlien + szDelay)
	
}

public StatusDisplay(szEntity){
	new id, sz_temp[1024]
	
	switch(GAME_MODE){
		case MODE_PREGAME:{
			new i, sz_lang[32], ss[10], sz_map[36], sz_len
			new Float: fb, Float:fh, Float:fb2

			for(id = 1; id <= g_maxplayers; id++){
				if(~IsUserConnected(id) || IsUserBot(id) || g_showhelp[id])
					continue
				
				//query_client_cvar(id, "cl_filterstuffcmd", "SetUserConfig")
				
				sz_len = 0
				
				sz_len += format(sz_temp[sz_len], charsmax(sz_temp) - sz_len, "Top Match Statistics [press F]^n^n")
				sz_len += format(sz_temp[sz_len], charsmax(sz_temp) - sz_len, 
				"%s - %d : %d - %s^n", g_TempTeamNames[T], get_pcvar_num(cv_score[T]), 
				get_pcvar_num(cv_score[CT]), g_TempTeamNames[CT])
				set_dhudmessage(255, 255, 20, -1.0, 0.05, 0, 0.1, 0.5, 0.3, 0.3)
				if(GAME_TYPE == TYPE_TOURNAMENT){
					if(gGKVoteIsRunning){
						set_dhudmessage(255, 255, 255, -1.0, 0.05, 0, 0.1, 0.5, 0.3, 0.3)
						show_dhudmessage(id, "CAPS!")
					} else {
						if(gTournamentId == 11){
							show_dhudmessage(id, "WORLD CUP 2018")
						} else {
							show_dhudmessage(id, "FULL-TIME")
						}
					}
				} else {
					show_dhudmessage(id, "CHANGING MAP...")
				}
				for(i = 1; i <= RECORDS; i++){
					if(i == POSSESSION){
						format(sz_lang, charsmax(sz_lang), "SJ_%s", RecordTitles[i])
						if(g_showhud[id] == 1) {
							num_to_str(TopPlayer[1][i], ss, 9)
							fb = str_to_float(ss)
							num_to_str(g_Time[0], ss, 9)
							fh = str_to_float(ss)
							sz_len += format(sz_temp[sz_len], charsmax(sz_temp) - sz_len, 
							"^n^n%L: %s%s%d", id, sz_lang, TopPlayerName[i], TopPlayer[1][i]?" - ":" ", 
							g_Time[0]?(floatround((fb / fh) * 100.0)):0)
						} else if(g_showhud[id] == 2) {
							num_to_str(TeamRecord[T][i], ss, 9)
							fb = str_to_float(ss)
							num_to_str(TeamRecord[CT][i], ss, 9)
							fb2 = str_to_float(ss)
							num_to_str(g_Time[0], ss, 9)
							fh = str_to_float(ss)
							
							sz_len += format(sz_temp[sz_len], charsmax(sz_temp) - sz_len, 
							"^n^n%d%%%% - %L - %d%%%%", g_Time[0]?(floatround((fb / fh) * 100.0)):0, id, sz_lang, 
							g_Time[0]?(floatround((fb2 / fh) * 100.0)):0)
						}
					} else {
						format(sz_lang, charsmax(sz_lang), "SJ_%s", RecordTitles[i])
						
						if(g_showhud[id] == 1) {
							sz_len += format(sz_temp[sz_len], charsmax(sz_temp) - sz_len, 
							"^n%L: %s%s%d", id, sz_lang, TopPlayerName[i], TopPlayer[1][i]?" - ":" ", TopPlayer[1][i])
						} else if(g_showhud[id] == 2) {
							sz_len += format(sz_temp[sz_len], charsmax(sz_temp) - sz_len, 
							"^n%d - %L - %d", TeamRecord[T][i], id, sz_lang, TeamRecord[CT][i])
						}
					}
					if(g_showhud[id] == 1){	
						switch(i){ 
							case POSSESSION:{
								sz_len += format(sz_temp[sz_len], charsmax(sz_temp) - sz_len, "%%%%")
								
								if(TopPlayer[1][i] != MadeRecord[id][i] && TopPlayer[1][i]){
									num_to_str(MadeRecord[id][i], ss, 9)
									fb = str_to_float(ss)
									num_to_str(g_Time[0], ss, 9)
									fh = str_to_float(ss)
									sz_len += format(sz_temp[sz_len], 
									charsmax(sz_temp) - sz_len, " (%d%%%%)", g_Time[0]?(floatround((fb / fh) * 100.0)):0)
								}
							}
							case DISHITS:{
								num_to_str(MadeRecord[id][DISHITS], ss, 9)
								fb = str_to_float(ss)
								num_to_str(MadeRecord[id][BHITS], ss, 9)
								fh = str_to_float(ss)
								sz_len += format(sz_temp[sz_len], charsmax(sz_temp) - sz_len, " (%d [%d%%%%])",
								MadeRecord[id][DISHITS], MadeRecord[id][BHITS]?(floatround((fb / fh) * 100.0)):0)
								
							}
							case DISTANCE:{
								sz_len += format(sz_temp[sz_len], charsmax(sz_temp) - sz_len, 
								" %L", id, "SJ_FT")
								
								if(TopPlayer[1][i] != MadeRecord[id][i] && TopPlayer[1][i]){
									sz_len += format(sz_temp[sz_len], 
									charsmax(sz_temp) - sz_len, " (%d) %L", MadeRecord[id][i], id, "SJ_FT")
								}
							}	
							default: {
								if(TopPlayer[1][i] != MadeRecord[id][i] && TopPlayer[1][i]){
									sz_len += format(sz_temp[sz_len], 
									charsmax(sz_temp) - sz_len, " (%d)", MadeRecord[id][i])
								}
							}
						}
					}
				}
				if(!equal(g_MVP_name, "")){
					set_dhudmessage(20, 255, 20, -1.0, 0.1, 0, 0.1, 0.4, 0.1, 0.1)
					show_dhudmessage(id, "MVP of the match is %s!", g_MVP_name)
				}
				/*if(false GAME_TYPE == TYPE_PUBLIC){
					get_cvar_string("amx_nextmap", sz_map, 35)
					if(!task_exists(9811) && !equal(sz_map, "-"))
						set_task(40.0, "ChangeMap", 9811)
						
					set_hudmessage(20, 255, 20, -1.0, 0.01, 0, 0.2, 0.2, 0.2, 0.2, 1)
					format(sz_temp, charsmax(sz_temp), 
					"- - - %L - - -", id, "SJ_STATSTITLE")
					show_hudmessage(id, sz_temp)
						
					set_dhudmessage(255, 20, 20, 0.44, 0.05, 0, 0.2, 0.2, 0.2, 0.2)
					show_dhudmessage(id, "%s - %d", TeamNames[T], get_pcvar_num(cv_score[1]))
						
					set_dhudmessage(20, 20, 255, 0.52, 0.05, 0, 0.2, 0.2, 0.2, 0.2)
					show_dhudmessage(id, "%d - %s", get_pcvar_num(cv_score[2]), TeamNames[CT])
						
					set_hudmessage(255, 255, 20, -1.0, 0.08, 0, 0.2, 0.2, 0.2, 0.2, 2)
					show_hudmessage(id, sz_temp)
				} else {*/
					if(winner && g_showhud[id]){
						if(g_showhud[id] == 1){
							set_hudmessage(255, 255, 20, 0.1, 0.08, 0, 0.2, 0.3, 0.3, 0.3, 4)
						} else if(g_showhud[id] == 2){
							set_hudmessage(20, 255, 20, 0.1, 0.08, 0, 0.2, 0.3, 0.3, 0.3, 4)
						}
						show_hudmessage(id, sz_temp)
					}
				//}
			}
			if(GAME_TYPE == TYPE_TOURNAMENT){
				ShowPregameStatus()
			}
		}
			
		case MODE_GAME:{	
			if(g_ballholder[0]){
				Event_Record(g_ballholder[0], POSSESSION)
			}
			if(GAME_TYPE == TYPE_PUBLIC){
				new sz_score = get_pcvar_num(cv_score[0])
				for(id = 1; id <= g_maxplayers; id++){
					if(~IsUserConnected(id) || IsUserBot(id) || g_showhelp[id])
						continue
						
					set_dhudmessage(255, 20, 20, 0.44, 0.05, 0, 0.2, 0.2, 0.2, 0.2)
					show_dhudmessage(id, "%s - %d", TeamNames[T], get_pcvar_num(cv_score[1]))
					
					set_dhudmessage(20, 20, 255, 0.52, 0.05, 0, 0.2, 0.2, 0.2, 0.2)
					show_dhudmessage(id, "%d - %s", get_pcvar_num(cv_score[2]), TeamNames[CT])
					
					if(!winner){
						format(sz_temp, charsmax(sz_temp), "[ %L ]", id, 
						(sz_score%10 == 1 && sz_score%100 != 11)?
						"SJ_GOALLIM1":"SJ_GOALLIM", sz_score)
						set_hudmessage(20, 250, 20, 1.0, 0.0, 0, 0.2, 0.2, 0.2, 0.2, 1)
						show_hudmessage(id, "%s^n^n^n^n^n^n%s", sz_temp, g_temp)
					}
				}
			} else {
				if(g_Timeleft == 0) {
					if(!ROUND) {
						play_wav(0, snd_whistle)
						g_Timeleft = -9932
						scoreboard[0] = 0
					
						format(scoreboard, 1024, "HALF-TIME")
						new data[3] = {255, 255, 10}
						set_task(1.0, "ShowDHud", _, data, 3, "a", 2)
						round_restart(4.0)
						set_task(4.5, "DoHalfTimeReport")
						for(id = 1; id <= g_maxplayers; id++) 
							g_Ready[id] = false
						ROUND = 1
					} else {
						GAME_MODE = MODE_NONE
						if(get_pcvar_num(cv_score[T]) > get_pcvar_num(cv_score[CT]))
							winner = T
						else if(get_pcvar_num(cv_score[CT]) >get_pcvar_num(cv_score[T]))
							winner = CT
						
						play_wav(0, snd_whistle_long)
								
						if(winner){
							scoreboard[0] = 0
							new data[3]
							format(scoreboard, charsmax(scoreboard), "Team %s WINS!",TeamNames[winner])
							if(winner == T)
								data = TeamColors[T]
							else
								data = TeamColors[CT]
							set_task(1.0, "ShowDHud", _, data, 3, "a", 3)
								
							round_restart(5.0)
						} else {
							GAME_MODE  = MODE_SHOOTOUT
							ShootOut = T
							remove_task(-13110)
							ROUND = 2
							round_restart(6.0)
							scoreboard[0] = 0
							new data[3]
							if(ShootOut == T)
								data = TeamColors[T]
							else
								data = TeamColors[CT]
							format(scoreboard, charsmax(scoreboard), "- SHOOTOUT -^nTeam %s is up first", TeamNames[ShootOut])
							set_task(1.0, "ShowDHud", _, data, 3, "a", 3)
						}
					}
					MoveBall(0, 0, -1)
				} else if(g_Timeleft > 0) {
					new bteam = get_user_team(g_ballholder[0]>0?g_ballholder[0]:g_last_ballholder[0])
					new sz_temp[32]
					new minutes = g_Timeleft / 60
					new seconds = g_Timeleft % 60
					format(sz_temp, charsmax(sz_temp), "%i:%s%i", minutes, seconds<10?"0":"", seconds)

					scoreboard[0] = 0
					for(id = 1; id <= g_maxplayers; id++) {
						if(~IsUserConnected(id) || g_showhelp[id])
							continue
							
						//query_client_cvar(id, "cl_filterstuffcmd", "SetUserConfig")
						
						format(scoreboard, charsmax(scoreboard), "%s HALF | %s%s^n %s - %i : %i - %s^nPoints: %i^n^n%s^n^n%s", 
						ROUND?"2ND":"1ST", minutes<10?" ":"", sz_temp, TeamNames[T], get_pcvar_num(cv_score[T]), get_pcvar_num(cv_score[CT]),
						TeamNames[CT], g_Experience[id], g_temp, get_user_team(id)==bteam?g_temp2:"")
						
						set_hudmessage(20, 255, 20, 1.0, 0.10, 0, 1.0, 1.5, 0.1, 0.1, 1)
						show_hudmessage(id, "%s", scoreboard)
	
						message_begin(MSG_ONE_UNRELIABLE, msg_roundtime, _, id)
						write_short(g_Timeleft + 1)
						message_end()
					}
					
					if(!get_pcvar_num(cv_pause)){
						g_Timeleft--
					}
				} else if(g_Timeleft != -9932) {
					if(g_Timeleft < -60)
						g_Timeleft = -60
						
					new bteam = get_user_team(g_ballholder[0]>0?g_ballholder[0]:g_last_ballholder[0])
					new timedisplay[32]
					new seconds = abs(g_Timeleft) % 60
					format(timedisplay, 31, ":%s%i", seconds<10?"0":"", seconds)
					scoreboard[0] = 0
					for(id = 1; id <= g_maxplayers; id++) {
						if(~IsUserConnected(id))
							continue
					
						format(scoreboard, 1024, "Infinite Time %s^n %s - %i : %i - %s^nPoints: %i^n^n%s^n^n%s", timedisplay,
						TeamNames[T], get_pcvar_num(cv_score[T]), get_pcvar_num(cv_score[CT]), TeamNames[CT], 
						g_Experience[id], g_temp, get_user_team(id)==bteam?g_temp2:"")
						
						set_hudmessage(20, 255, 20, 1.0, 0.10, 0, 1.0, 1.5, 0.1, 0.1, 1)
						show_hudmessage(id, "%s", scoreboard)
						
						message_begin(MSG_ONE_UNRELIABLE, msg_roundtime, _, id)
						write_short(abs(g_Timeleft) + 1)
						message_end()
					}
					g_Timeleft++
					if(g_Timeleft == 0)
						g_Timeleft = -60
				}
			}
		}
		case MODE_HALFTIME:{
			new i, sz_lang[32], ss[10], sz_len
			new Float: fb, Float:fh, Float:fb2

			for(id = 1; id <= g_maxplayers; id++){
				if(~IsUserConnected(id) || IsUserBot(id) || g_showhelp[id])
					continue
				
				//query_client_cvar(id, "cl_filterstuffcmd", "SetUserConfig")
				
				sz_len = 0
				
				
				sz_len += format(sz_temp[sz_len], charsmax(sz_temp) - sz_len, "Top Match Statistics [press F]^n^n")
				sz_len += format(sz_temp[sz_len], charsmax(sz_temp) - sz_len, 
				"%s - %d : %d - %s^n", TeamNames[T], get_pcvar_num(cv_score[T]), 
				get_pcvar_num(cv_score[CT]), TeamNames[CT]) 
				set_dhudmessage(255, 255, 20, -1.0, 0.05, 0, 0.1, 0.5, 0.3, 0.3)
				show_dhudmessage(id, "HALF-TIME")

				for(i = 1; i <= RECORDS; i++){
					if(i == POSSESSION){
						format(sz_lang, charsmax(sz_lang), "SJ_%s", RecordTitles[i])
						if(g_showhud[id] == 1){
							num_to_str(TopPlayer[1][i], ss, 9)
							fb = str_to_float(ss)
							num_to_str(g_Time[0], ss, 9)
							fh = str_to_float(ss)
							sz_len += format(sz_temp[sz_len], charsmax(sz_temp) - sz_len, 
							"^n^n%L: %s%s%d", id, sz_lang, TopPlayerName[i], TopPlayer[1][i]?" - ":" ", 
							g_Time[0]?(floatround((fb / fh) * 100.0)):0)
						} else if(g_showhud[id] == 2){
							num_to_str(TeamRecord[T][i], ss, 9)
							fb = str_to_float(ss)
							num_to_str(TeamRecord[CT][i], ss, 9)
							fb2 = str_to_float(ss)
							num_to_str(g_Time[0], ss, 9)
							fh = str_to_float(ss)
							
							sz_len += format(sz_temp[sz_len], charsmax(sz_temp) - sz_len, 
							"^n^n%d%%%% - %L - %d%%%%", g_Time[0]?(floatround((fb / fh) * 100.0)):0, id, sz_lang, 
							g_Time[0]?(floatround((fb2 / fh) * 100.0)):0)
						}
					} else {
						format(sz_lang, charsmax(sz_lang), "SJ_%s", RecordTitles[i])
						if(g_showhud[id] == 1){
							sz_len += format(sz_temp[sz_len], charsmax(sz_temp) - sz_len, 
							"^n%L: %s%s%d", id, sz_lang, TopPlayerName[i], TopPlayer[1][i]?" - ":" ", TopPlayer[1][i])
						} else if(g_showhud[id] == 2){
							sz_len += format(sz_temp[sz_len], charsmax(sz_temp) - sz_len, 
							"^n%d - %L - %d", TeamRecord[T][i], id, sz_lang, TeamRecord[CT][i])
						}
					}
					if(g_showhud[id] == 1){	
						switch(i){ 
							case POSSESSION:{
								sz_len += format(sz_temp[sz_len], charsmax(sz_temp) - sz_len, "%%%%")
								
								if(TopPlayer[1][i] != MadeRecord[id][i] && TopPlayer[1][i]){
									num_to_str(MadeRecord[id][i], ss, 9)
									fb = str_to_float(ss)
									num_to_str(g_Time[0], ss, 9)
									fh = str_to_float(ss)
									sz_len += format(sz_temp[sz_len], 
									charsmax(sz_temp) - sz_len, " (%d%%%%)", g_Time[0]?(floatround((fb / fh) * 100.0)):0)
								}
							}
							case DISHITS:{
								num_to_str(MadeRecord[id][DISHITS], ss, 9)
								fb = str_to_float(ss)
								num_to_str(MadeRecord[id][BHITS], ss, 9)
								fh = str_to_float(ss)
								sz_len += format(sz_temp[sz_len], charsmax(sz_temp) - sz_len, " (%d [%d%%%%])",
								MadeRecord[id][DISHITS], MadeRecord[id][BHITS]?(floatround((fb / fh) * 100.0)):0)
								
							}
							case DISTANCE:{
								sz_len += format(sz_temp[sz_len], charsmax(sz_temp) - sz_len, 
								" %L", id, "SJ_FT")
								
								if(TopPlayer[1][i] != MadeRecord[id][i] && TopPlayer[1][i]){
									sz_len += format(sz_temp[sz_len], 
									charsmax(sz_temp) - sz_len, " (%d) %L", MadeRecord[id][i], id, "SJ_FT")
								}
							}	
							default: if(TopPlayer[1][i] != MadeRecord[id][i] && TopPlayer[1][i]){
									sz_len += format(sz_temp[sz_len], 
									charsmax(sz_temp) - sz_len, " (%d)", MadeRecord[id][i])
							}
						}
					}
				}
				if(g_showhud[id]){
					if(g_showhud[id] == 1){
						set_hudmessage(255, 255, 20, 0.1, 0.08, 0, 0.2, 0.3, 0.3, 0.3, 4)
					} else if(g_showhud[id] == 2) {
						set_hudmessage(20, 255, 20, 0.1, 0.08, 0, 0.2, 0.3, 0.3, 0.3, 4)
					}
					show_hudmessage(id, sz_temp)
				}
			}

			ShowPregameStatus()

		}
		case MODE_SHOOTOUT: {
			if(next >= 0 && IsUserConnected(LineUp[next])){
				new sz_name[32], sz_team, sz_tempT[128], sz_tempCT[128], sz_tempGoaksT[64], sz_tempGoalsCT[64]
				get_user_name(LineUp[next], sz_name, 31)
				sz_team = get_user_team(LineUp[next])
				for(new i = 0, sz_lenT = 0; i < MAX_PENSHOOTERS; i++){
					sz_lenT += format(sz_tempGoaksT[sz_lenT], charsmax(sz_tempGoaksT) - sz_lenT, " %s ", PenGoals[T][i]==1?"O":(PenGoals[T][i]==2?"X":"."))
				}
				for(new i = MAX_PENSHOOTERS - 1, sz_lenCT = 0; i >= 0; i--){
					sz_lenCT += format(sz_tempGoalsCT[sz_lenCT], charsmax(sz_tempGoalsCT) - sz_lenCT, " %s ", PenGoals[CT][i]==1?"O":(PenGoals[CT][i]==2?"X":"."))
				}
				
				format(sz_tempT, 127, "%s  %s", sz_tempGoaksT, TeamNames[T])
				format(sz_tempCT, 127, "%s  %s", TeamNames[CT], sz_tempGoalsCT)
				//format(sz_tempCT, 127, "%s- %s | %s | %s -%s", sz_tempT, TeamNames[T], sz_name, TeamNames[CT], sz_tempCT)
				
				for(id = 1; id <= g_maxplayers; id++){
					if(~IsUserConnected(id) || IsUserBot(id) || g_showhelp[id])
						continue
					
					//query_client_cvar(id, "cl_filterstuffcmd", "SetUserConfig")
					
					if(timer >= 0){
						set_dhudmessage(TeamColors[sz_team][0], TeamColors[sz_team][1], TeamColors[sz_team][2], -1.0, 0.65, 0, 0.1, 0.4, 0.1, 0.1)
						show_dhudmessage(id, "%s: %d", sz_name, timer)
					}
					set_dhudmessage(TeamColors[T][0], TeamColors[T][1], TeamColors[T][2], 0.35, 0.6, 0, 0.1, 0.4, 0.1, 0.1)
					show_dhudmessage(id, "%s", sz_tempT)

					set_dhudmessage(TeamColors[CT][0], TeamColors[CT][1], TeamColors[CT][2], 0.53, 0.6, 0, 0.1, 0.4, 0.1, 0.1)
					show_dhudmessage(id, "%s", sz_tempCT)
				}
			}
			
		}
		case MODE_OVERTIME: {
			if(g_ballholder[0]){
				Event_Record(g_ballholder[0], POSSESSION)
			}
	
			if(!winner){
				if(g_Timeleft < -60)
					g_Timeleft = -60
						
				new bteam = get_user_team(g_ballholder[0]>0?g_ballholder[0]:g_last_ballholder[0])
				new timedisplay[32]
				new seconds = abs(g_Timeleft) % 60
				format(timedisplay, charsmax(timedisplay), ":%s%i", seconds<10?"0":"", seconds)
				scoreboard[0] = 0
				for(id = 1; id <= g_maxplayers; id++) {
					if(~IsUserConnected(id))
						continue
						
					//query_client_cvar(id, "cl_filterstuffcmd", "SetUserConfig")
					
					format(scoreboard, 1024, "OVERTIME | inf%s^n %s - %i : %i - %s^nPoints: %i^n^n%s^n^n%s", timedisplay,
					TeamNames[T], get_pcvar_num(cv_score[T]), get_pcvar_num(cv_score[CT]), TeamNames[CT], 
					g_Experience[id], g_temp, get_user_team(id)==bteam?g_temp2:"")
						
					set_hudmessage(20, 255, 20, 1.0, 0.10, 0, 1.0, 1.5, 0.1, 0.1, 1)
					show_hudmessage(id, "%s", scoreboard)
						
					message_begin(MSG_ONE_UNRELIABLE, msg_roundtime, _, id)
					write_short(abs(g_Timeleft) + 1)
					message_end()
				}
				if(++g_Timeleft == 0)
					g_Timeleft = -60
			}
		}

	}
	//client_print(0, print_chat, "%d : %0.f", szEntity, pev(szEntity, pev_nextthink))
	set_pev(szEntity, pev_nextthink, halflife_time() + gTimerEntThink)
	
	return PLUGIN_HANDLED
}

ShowPregameStatus(){
	new teamready[TEAMS][512], teamLen[TEAMS], id, team, sz_temp[32], x
	new player_name[32], teamcount[TEAMS], readycount[TEAMS], sz_temp2[32], sz_rank[32]
	new sz_checkClanId[TEAMS], sz_checkClanId2[TEAMS], sz_checkclan[TEAMS][32], sz_checkclantwo[TEAMS][32], sz_checkteamclan[TEAMS], sz_checkteamclantwo[TEAMS]
	new sz_nationalteam[32]
	for(id = 1; id <= g_maxplayers; id++){
		if(IsUserConnected(id) && ~IsUserBot(id)){
			team = get_user_team(id)
			if(team != T && team != CT)
				continue
			get_user_name(id, player_name, 31)

			format(sz_temp, charsmax(sz_temp), "")
			format(sz_temp2, charsmax(sz_temp2), "")
			format(sz_rank, charsmax(sz_rank), "")
			format(sz_nationalteam, charsmax(sz_nationalteam), "")
			
			if(id == g_GK[team]){
				format(sz_temp, charsmax(sz_temp), " [GK]")
			}
			if(g_mvprank[id][0] != EOS){
				format(sz_rank, charsmax(sz_rank), "#%s | ", g_mvprank[id])
			}
			if(g_userClanName[id][0] != EOS){
				format(sz_temp2, charsmax(sz_temp2), " | %s", g_userClanName[id])
			}
			/*else{
				sz_len += format(sz_temp[sz_len], 31 - sz_len, " [")
				for(x = 1; x <= UPGRADES; x++){
					if(x != UPGRADES)
						sz_len += format(sz_temp[sz_len], 31 - sz_len, "%d ", PlayerUpgrades[id][x])
					else
						sz_len += format(sz_temp[sz_len], 31 - sz_len, "%d", PlayerUpgrades[id][x])
				}
				sz_len += format(sz_temp[sz_len], 31 - sz_len, "]")
			}*/
			if(sz_checkteamclan[team] != -1){
				if(!sz_checkteamclan[team] || equal(g_userClanName[id], sz_checkclan[team])){
					format(sz_checkclan[team], 31, "%s", g_userClanName[id])
					sz_checkClanId[team] = g_userClanId[id]
					sz_checkteamclan[team]++
				} else if (!sz_checkteamclantwo[team] || equal(g_userClanName[id], sz_checkclantwo[team])){
					format(sz_checkclantwo[team], 31, "%s", g_userClanName[id])
					sz_checkClanId2[team] = g_userClanId[id]
					sz_checkteamclantwo[team]++
				} else {
					sz_checkteamclan[team] = -1
				}
			}
			
			teamcount[team]++
			if(g_userCountry_3[id][0] != EOS){
				format(sz_nationalteam, charsmax(sz_nationalteam), "(%s) ", g_userCountry_3[id]) 
			}
			
			if(g_Ready[id]){
				readycount[team]++
				teamLen[team] += format(teamready[team][teamLen[team]], 511 - teamLen[team], "%s%s%s%s%s^n", sz_nationalteam, sz_rank, player_name, sz_temp, sz_temp2)
			} else {
				teamLen[team] += format(teamready[team][teamLen[team]], 511 - teamLen[team], "         %s%s%s%s%s^n", sz_nationalteam, sz_rank, player_name, sz_temp, sz_temp2)
			}
		}
	}
	for(team = T; team <= CT; team++){
		if(GAME_MODE == MODE_PREGAME && g_saveall){
			if((teamcount[team] < 5) || (sz_checkteamclan[team] > 1 && sz_checkteamclantwo[team] > 1)){
				sz_checkteamclan[team] = -1
			} 
			if(sz_checkteamclan[team] != -1){
				if((sz_checkteamclan[team] >= 4 && sz_checkteamclantwo[team] == 1 && g_GK[team] > 0 && g_userClanId[g_GK[team]] != sz_checkClanId[team]) || sz_checkteamclan[team] > 4){
					if(sz_checkclan[team][0] != EOS){
						format(TeamNames[team], 31, "%s", sz_checkclan[team])
						TeamId[team] = sz_checkClanId[team]
					} else {
						format(TeamNames[team], 31, team==T?"T":"CT")
						(team==T)?(TeamId[team]=-1):(TeamId[team]=-2)
					}
				} else if((sz_checkteamclantwo[team] >= 4 && sz_checkteamclan[team] == 1 && g_GK[team] > 0 && g_userClanId[g_GK[team]] != sz_checkClanId2[team]) || sz_checkteamclantwo[team] > 4){
					if(sz_checkclantwo[team][0] != EOS){
						format(TeamNames[team], 31, "%s", sz_checkclantwo[team])
						TeamId[team] = sz_checkClanId2[team]
					} else {
						format(TeamNames[team], 31, team==T?"T":"CT")
						(team==T)?(TeamId[team]=-1):(TeamId[team]=-2)
					}
					
				} else {
					format(TeamNames[team], 31, team==T?"T":"CT")
					(team==T)?(TeamId[team]=-1):(TeamId[team]=-2)
				}
			} else {
				format(TeamNames[team], 31, team==T?"T":"CT")
				(team==T)?(TeamId[team]=-1):(TeamId[team]=-2)
			}
		}
		
	}

	new required = get_pcvar_num(cv_players)
	
	new missing[64]
	if(teamcount[T] <= 3 && teamcount[CT] <= 3 && teamcount[SPECTATOR] < 5){
		if(teamcount[T] == 1 || teamcount[CT] == 1)
			required = 0
	}
	
	for(x = 1; x < 3; x++){
		if(teamcount[x] < required) {
			format(missing, charsmax(missing), "Missing: %i", required - teamcount[x])
		} else if(teamcount[x] != readycount[x]) {
			format(missing, charsmax(missing), "Waiting: %i", teamcount[x] - readycount[x])
		} else if(teamcount[x] == readycount[x]) {
			format(missing, charsmax(missing), "Ready")
		}

		set_hudmessage(TeamColors[x][0], TeamColors[x][1], TeamColors[x][2], 0.60, x==T?0.2:0.55, 0, 0.5, 0.4, 0.4, 0.4, x==T?2:1)
		show_hudmessage(0, "%sTEAM %s | %s^n%s", x==1?"^n^n^n":"", TeamNames[x], missing, teamready[x])
	}
	
	new sz_start
	for(x = 1; x < 3; x++){
		if(teamcount[x] >= required && teamcount[x] == readycount[x])
			sz_start++
		
		if(teamcount[T] != 5 || teamcount[CT] != 5) {
			g_regtype = 0
		} else if(equal(TeamNames[T], "T") || equal(TeamNames[CT], "CT")) {
			g_regtype = 1
		} else {
			g_regtype = 2
		}
	}

	if(sz_start == 2){
		if(GAME_MODE == MODE_PREGAME) {
			CleanUp()
			g_iTeamBall = 0
			if(g_regtype == 2){
				set_pcvar_num(cv_chat, 0)
				new sz_name[32]
				get_user_name(0, sz_name, charsmax(sz_name))
				ColorChat(0, RED, "^4[SJ] ^1- ^1Global chat is ^3OFF! ^1(ADMIN: %s)", sz_name)
			}
		}
		
		BeginCountdown()
		
		GAME_MODE = MODE_NONE
	}
		
}

public ShowDHud(sz_colors[]){
	set_dhudmessage(sz_colors[0], sz_colors[1], sz_colors[2], -1.0, 0.3, 0, 0.2, 0.5, 0.7, 0.7)
	show_dhudmessage(0, "%s", scoreboard)
}

/*
+-----------------------+--------------------------------------------------------------------------+
|			| ************************************************************************ |
|	[TOUCHES]	| ************************************************************************ |
|			| ************************************************************************ |
+-----------------------+--------------------------------------------------------------------------+
*/
public touch_World(ball, world){
	if(get_speed(ball) > 5){
		new Float:v[3]
		pev(ball, pev_velocity, v)
		v[0] *= 0.85
		v[1] *= 0.85
		v[2] *= 0.85
		//sprite_portal(ball)
		set_pev(ball, pev_velocity, v)
		emit_sound(ball, CHAN_ITEM, snd_ballhit, 1.0, ATTN_NORM, 0, PITCH_NORM)
	}
}

public touch_Ball(ball1, ball2){
	if(
		(ball1 == g_ball_touched[0] && ball2 == g_ball_touched[1]) ||
		(ball2 == g_ball_touched[0] && ball1 == g_ball_touched[1])
	){
		g_ball_touched[0] = 0
		g_ball_touched[1] = 0
		return PLUGIN_HANDLED
	}
	g_ball_touched[0] = ball1
	g_ball_touched[1] = ball2
	
	if(get_speed(ball1) > 5){
		sprite_portal(ball1)
		emit_sound(ball1, CHAN_ITEM, snd_ballhit, 1.0, ATTN_NORM, 0, PITCH_NORM)	
	}
	if(get_speed(ball2) > 5){
		sprite_portal(ball2)
		emit_sound(ball2, CHAN_ITEM, snd_ballhit, 1.0, ATTN_NORM, 0, PITCH_NORM)	
	}
	
	new Float:sz_vel1[3], Float:sz_vel2[3]
	pev(ball1, pev_velocity, sz_vel1)
	pev(ball2, pev_velocity, sz_vel2)

	for(new x = 0; x < 3; x++){
		sz_vel1[x] *= 0.85
		sz_vel2[x] *= 0.85
		if(get_speed(ball1) < 5.0)
			sz_vel1[x] = 0.15 * sz_vel2[x]
		if(get_speed(ball2) < 5.0)
			sz_vel2[x] = 0.15 * sz_vel1[x]
	}
	
	set_pev(ball1, pev_velocity, sz_vel2)
	set_pev(ball2, pev_velocity, sz_vel1)
	
	return PLUGIN_HANDLED
}

public touch_Player(ball, player){
	if(~IsUserAlive(player))
		return PLUGIN_HANDLED
	new i
	new Float:vp[3], Float: vb[3], k
	for(i = 0; i <= g_count_balls; i++){
		if(player == g_ballholder[i]){
			pev(player, pev_velocity, vp)
			pev(ball, pev_velocity, vb)
			for(k = 0; k < 3; k++){
				vb[k] += vp[k]
			}

			set_pev(ball, pev_velocity, vb)
			
			return PLUGIN_HANDLED
		}
	}
	for(i = 0; i <= g_count_balls; i++){
		if(g_ball[i] == ball)
			break
	}
	if(i == g_count_balls + 1){
		client_print(player, print_chat, "[ERROR] Ball has not been found! [Touch Player]")
		return PLUGIN_HANDLED
	}
	new playerteam = get_user_team(player)
	if(!(T <= playerteam <= CT) || (freeze_player[player] && player != LineUp[next]))
		return PLUGIN_HANDLED
	
	remove_task(55555 + i)
	
	new aname[32], stolen
	get_user_name(player, aname, 31)

	//if(task_exists(-5311 + player))
		//client_print(0, print_chat, "ALIEN")
	if(g_ballholder[i] == 0){
		if(g_last_ballholder[i] > 0 && playerteam != g_last_ballholderteam[i]){
			new speed = get_speed(ball)
			if(speed > 500 && PlayerUpgrades[player][DEX] < UpgradeMax[DEX]){
				// configure catching algorithm
				new dexlevel = PlayerUpgrades[player][DEX]
				new bstr = (PlayerUpgrades[g_last_ballholder[i]][STR] * AMOUNT_STR) / 10
				new dex = dexlevel * (AMOUNT_DEX + 1)
				new pct = ((pev(player, pev_button) & IN_USE) ? 10 : 0) + dex
			
				pct += (dexlevel * (g_sprint[player] ? 1 : 0))	// give Dex Lvl * 2 if turboing
				pct += (g_sprint[player] ? 5 : 0 )		// player turboing? give 5% 
				pct -= (g_sprint[g_last_ballholder[i]] ? 10 : 0) // g_last_ballholder turboing? lose 5%
				pct -= bstr					// g_last_ballholder has strength? remove bstr
				
				//pct /= get_pcvar_float(cv_smack)
				
				//client_print(0, print_chat, "%d", pct)
				// will player avoid damage?
				if(random_num(0, get_pcvar_num(cv_smack)) > pct){
					new Float:dodmg = (float(speed) / 13.0) + bstr - (dex - dexlevel)
					if(dodmg < 10.0){
						dodmg = 10.0
					}
					for(new id = 1; id <= g_maxplayers; id++){
						if(IsUserConnected(id)){
							ColorChat(id, (playerteam == T)?RED:BLUE, "^3%s ^1%L", 
							aname, id, "SJ_SMACKED", floatround(dodmg))
						}
					}
					
					Event_Record(player, SMACK)
					
					set_msg_block(msg_deathmsg, BLOCK_ONCE)
					fakedamage(player, "AssWhoopin", dodmg, 1)
					set_msg_block(msg_deathmsg, BLOCK_NOT)
					
					if(~IsUserAlive(player)){
						message_begin(MSG_ALL, msg_deathmsg)
						write_byte(g_last_ballholder[i])
						write_byte(player)
						write_string("AssWhoopin")
						message_end()
						
						//new frags = get_user_frags(g_last_ballholder[i])
						Event_Record(g_last_ballholder[i], BALLKILL)
						
						client_print(player, print_chat, 
						"%L", player, "SJ_BALLKILLED")
						client_print(g_last_ballholder[i], print_chat, "%L", 
						g_last_ballholder[i], "SJ_BALLKILL", aname)
					} else {
						new Float:pushVel[3]
						pushVel[0] = velocity[i][0]
						pushVel[1] = velocity[i][1]
						pushVel[2] = velocity[i][2] + ((velocity[i][2] < 0)?
						random_float(-200.0,-50.0):random_float(50.0, 200.0))
						set_pev(player, pev_velocity, pushVel)
						
						FX_ScreenShake(player)
					}
					
					for(new x = 0; x < 3; x++)
						velocity[i][x] = (velocity[i][x] * random_float(0.1, 0.9))
					
					set_pev(ball, pev_velocity, velocity[i])
					direction[i] = 0
					
					return PLUGIN_HANDLED
				}
			}
			
			if(speed > 950){
				play_wav(0, snd_pussy)
				FX_ScreenShake(player)
			}
			
			new Float:pOrig[3]
			entity_get_vector(player, EV_VEC_origin, pOrig)
			new Float:dist = get_distance_f(pOrig, TeamBallOrigins[playerteam])
			
			// give more points the closer it is to net
			new sz_fail
			if(dist < 600.0 && speed > 300){
				if((float(speed) / 1000.0) - (dist / 2000.0) > 0.0){
					Event_Record(player, GOALSAVE)
					sz_fail = 1
				}
			}
			
			Event_Record(player, STEAL)
			if(!sz_fail)
				Event_Record(g_last_ballholder[i], LOSS)
				
			format(g_temp, charsmax(g_temp), "|%s| %s^n%L", TeamNames[playerteam], aname, 
			LANG_SERVER, "SJ_STOLEBALL")
	
			stolen = 1
			
			if(GAME_MODE == MODE_SHOOTOUT) {
				new oteam = (ShootOut == T ? CT:T)
				if(playerteam == oteam) {
					MoveBall(0, 0, -1)
					SetAsWatcher(LineUp[next], oteam)
				}
			}
			
			for(new k = 0; k < MAX_ASSISTERS; k++){
				g_assisters[k] = 0
				g_assisttime[k] = 0.0
			}
		}
	
		emit_sound(ball, CHAN_ITEM, snd_gotball, 1.0, ATTN_NORM, 0, PITCH_NORM)
		
		g_ballholder[i] = player
		
		if(stolen){
			PowerPlay[i] = 0
		} else {
			format(g_temp, charsmax(g_temp), "|%s| %s^n%L", TeamNames[playerteam], aname, 
			LANG_SERVER, "SJ_PICKBALL")
		}
			
		new bool:check
		if(((PowerPlay[i] > 1 && PowerPlay_list[i][PowerPlay[i] - 2] == player) || 
		    (PowerPlay[i] > 0 && PowerPlay_list[i][PowerPlay[i] - 1] == player)) 
		    && PowerPlay[i] != MAX_POWERPLAY)
			check = true
					
		if(PowerPlay[i] <= MAX_POWERPLAY && !check){
			PowerPlay_list[i][PowerPlay[i]] = player
			PowerPlay[i]++
		}
		curvecount[i] = 0
		direction[i] = 0
		
		format(g_temp2, charsmax(g_temp2), "%L: %i", LANG_SERVER, "SJ_POWERPLAY", 
		(PowerPlay[i] > 0)?(PowerPlay[i] - 1):0)
		
		if(g_last_ballholder[i] != g_ballholder[i] && g_last_ballholder[i]){
			if(playerteam == g_last_ballholderteam[i]){
				Event_Record(g_last_ballholder[i], PASS)
				for(new x = MAX_ASSISTERS - 1; x; x--){
					g_assisters[x] = g_assisters[x - 1]
					g_assisttime[x] = g_assisttime[x - 1]
				}
				g_assisters[0] = g_last_ballholder[i]
				g_assisttime[0] = get_gametime()
			}
		}
		
		if(PowerPlay[i] >= MAX_POWERPLAY){
			message_begin(MSG_ONE, msg_statusicon, {0,0,0}, g_ballholder[i])
			write_byte(1) 	// status (0 = hide, 1 = show, 2 = flash)
			write_string("dmg_heat") // sprite name
			write_byte(255)	// red
			write_byte(255)	// green
			write_byte(25)	// blue
			message_end()
		}
		
		set_hudmessage(255, 20, 20, -1.0, 0.4, 1, 1.0, 1.5, 0.1, 0.1, 2)
		
		show_hudmessage(player, "%L", player, "SJ_UHAVEBALL")
		if(IsUserBot(player)){
			set_task(random_float(3.0, 15.0), "BotKickBall", player - 5219)
		}
		beam(10, ball)
		glow(player, TeamColors[playerteam][0], TeamColors[playerteam][1], TeamColors[playerteam][2])
	}
	
	return PLUGIN_HANDLED
}

public BotKickBall(id){
	id += 5219
	KickBall(id, 0)
}

public touch_Goalnet(ball, goalpost){
	new i
	for(i = 0; i <= g_count_balls; i++){
		if(g_ball[i] == ball)
			break
	}
	if(i == g_count_balls + 1){
		client_print(0, print_chat, "[ERROR] Ball has not been found! [touch_Goalnet]")
		return PLUGIN_HANDLED
	}
	
	new team = g_last_ballholderteam	[i]
	new goalent = GoalEnt[team]
	//set_pev(goalpost, pev_solid, SOLID_NOT)
	if(goalpost != goalent && g_last_ballholder[i] > 0 && !g_ballholder[i]){
		if(!get_pcvar_num(cv_nogoal) && GAME_MODE != MODE_PREGAME && GAME_MODE != MODE_HALFTIME && GAME_MODE != MODE_NONE){
			new Float:ccorig[3], Float:gnorig[3]
			new ccorig2[3] 
			
			entity_get_vector(ball, EV_VEC_origin, ccorig)
			new t
			for(t = 0; t < 3; t++) 
				ccorig2[t] = floatround(ccorig[t])
			
			for(t = 0; t < 3; t++)
				distorig[1][t] = floatround(ccorig[t])
			pev(goalpost, pev_origin, gnorig)
			g_distshot = (get_distance(distorig[0], distorig[1]) / 12)
			
			if(g_lame &&  g_distshot > get_pcvar_num(cv_lamedist)){ 
				MoveBall(0, team==T?CT:T, i)
				for(i = 1; i < g_maxplayers; i++){
					if(IsUserConnected(i) && ~IsUserBot(i))
						ColorChat(i, RED, "^4[SJ] ^1- ^3%L %L", 
						i, "SJ_LAME", get_pcvar_num(cv_lamedist), i, "SJ_FT")
				}
			
				return PLUGIN_HANDLED
			}
			if((task_exists(-5005) && team == CT) || (task_exists(-5006) && team == T)){
				ColorChat(0, (team == T)?RED:BLUE, "^4[SJ] ^1- ^3GK hunt! ^1Goal has been cancelled.")
				for(t = 1; t <= g_maxplayers; t++){
					if(IsUserAlive(t) && (T <= get_user_team(t) <= CT)){
						cs_user_spawn(t)
					}
				}
				MoveBall(0, team==T?CT:T, i)
				return PLUGIN_HANDLED
			}
			format(g_temp, charsmax(g_temp), "|%s| %s^n%L %L!", 
			TeamNames[team], g_last_ballholdername[i], 
			LANG_SERVER, "SJ_SCORE", g_distshot, LANG_SERVER, "SJ_FT")
			
			new sz_temp[MAX_ASSISTERS * 45]
			format(sz_temp, charsmax(sz_temp), "^3%s", g_last_ballholdername[i])
			
			if(!g_count_balls && GAME_MODE != MODE_SHOOTOUT){
				// register assists
				new sz_assist_name[MAX_ASSISTERS][32]
				new sz_assist_num
				for(t = 0; t < MAX_ASSISTERS; t++){	
					if(!g_assisters[t] || g_assisters[t] == g_last_ballholder[i])
						break	
					if(~IsUserConnected(g_assisters[t]))
						continue
					if(get_gametime() - g_assisttime[t] > 10.0){
						continue
					}
					sz_assist_num++
					Event_Record(g_assisters[t], ASSIST)
					get_user_name(g_assisters[t], sz_assist_name[t], 31)
				}
				
				new sz_len
				t = sz_assist_num - 1
				if(sz_assist_num){
					while(t >= 0){
						sz_len += format(sz_temp[sz_len], 
						charsmax(sz_temp) - sz_len, "^3%s ^4-> ", sz_assist_name[t--])
					}
					sz_len += format(sz_temp[sz_len], 
					charsmax(sz_temp) - sz_len, "^3%s", g_last_ballholdername[i])
				}
			}
			
			if(g_distshot > MadeRecord[g_last_ballholder[i]][DISTANCE])
				Event_Record(g_last_ballholder[i], DISTANCE) 
			
			flameWave(ccorig2, team==T?CT:T)
			play_wav(0, snd_distress)
			
			for(t = 0; t < MAX_ASSISTERS; t++){
				g_assisters[t] = 0
				g_assisttime[t] = 0.0
			}
				
			for(new i = 1; i <= g_maxplayers; i++){
				if(~IsUserConnected(i))
					continue
			
				if(GAME_TYPE == TYPE_PUBLIC){
					sql_updatePlayerStats(i)
					if(get_user_team(i) == team)
						g_Experience[i] += POINTS_TEAMGOAL
				}
					
				if(T <= get_user_team(i) <= CT)
					save_stats(i)

				if(floatabs(ccorig[1] - gnorig[1]) > 20.0){
					ColorChat(i, (team == T)?RED:BLUE, "%s ^4%L %L!", sz_temp, i, "SJ_SCORE", g_distshot, i, "SJ_FT")
				} else {
					ColorChat(i, (team == T)?RED:BLUE, "%s ^4%L %L ^3[MIDDLE]!", sz_temp, i, "SJ_SCORE", g_distshot, i, "SJ_FT")
				}
			}
			Event_Record(g_last_ballholder[i], GOAL)
			
			g_iTeamBall = team
			MoveBall(0, 0, i)
			g_count_scores++
			set_pcvar_num(cv_score[team], get_pcvar_num(cv_score[team]) + 1)
			if(GAME_TYPE == TYPE_PUBLIC){
				if(get_pcvar_num(cv_score[team]) >= get_pcvar_num(cv_score[0]))
					winner = team
			}

			cs_set_team_score(CS_TEAM_T, get_pcvar_num(cv_score[T]))
			cs_set_team_score(CS_TEAM_CT, get_pcvar_num(cv_score[CT]))
			
			switch(random_num(1,6)){
				case 1: play_wav(0, snd_amaze)
				case 2: play_wav(0, snd_laugh)
				case 3: play_wav(0, snd_perfect)
				case 4: play_wav(0, snd_diebitch)
				case 5: play_wav(0, snd_bday)
				case 6: play_wav(0, snd_boomchaka)
			}
			
			if(GAME_MODE == MODE_OVERTIME){
				winner = team
			}
			if(winner){
				play_wav(0, snd_whistle_long)
				format(scoreboard, charsmax(scoreboard), "%L", LANG_SERVER, "SJ_TEAMWIN", TeamNames[winner])
				
				set_task(1.0, "ShowDHud", _, TeamColors[winner], 3, "a", 3)
				
				if(g_count_balls){
					for(i = g_count_balls; i >= 0; i--){
						RemoveBall(i)
					}
					g_count_balls = 0
				}
				round_restart(5.0)
			} else if(g_count_scores == g_count_balls + 1) {
				if(GAME_MODE != MODE_SHOOTOUT){
					if(g_Timeleft > 12){
						set_task(3.0, "SvRestart", -13110)
						StatusDisplay_Restart()
					}
				} else {
					PenGoals[team][next] = 1
				}
				g_count_scores = 0
			}
		} else {
			new florig[3], Float:borig[3]
			if(task_exists(-3312 - i)){
				if(g_last_ballholder[i]){
					pev(g_last_ballholder[i], pev_origin, borig)
					set_pev(ball, pev_origin, borig)
				} else {
					MoveBall(1, 0, i)
				}
				remove_task(-3312 - i)
				
				return PLUGIN_HANDLED	
			}
			
			pev(ball, pev_origin, borig)
			for(new t = 0; t < 3; t++) 
				florig[t] = floatround(borig[t])			
			flameWave(florig, team==T?CT:T)	
				
			set_task(0.1, "Done_Handler", -3312 - i)
		}
	} else if(goalpost == goalent) {
		if(get_pcvar_num(cv_nogoal) || GAME_MODE == MODE_PREGAME || GAME_MODE == MODE_HALFTIME || GAME_MODE == MODE_NONE){
			new florig[3], Float:borig[3]
			pev(ball, pev_origin, borig)
			if(task_exists(-3312 - i)){
				if(g_last_ballholder[i]){
					pev(g_last_ballholder[i], pev_origin, borig)
					set_pev(ball, pev_origin, borig)
				} else {
					MoveBall(1, 0, i)
				}
				
				remove_task(-3312 - i)
				
				return PLUGIN_HANDLED	
			}
			
			for(new t = 0; t < 3; t++) 
				florig[t] = floatround(borig[t])
			
			flameWave(florig, team)
			
			set_task(0.1, "Done_Handler", -3312 - i)
		} else {
			if(g_last_ballholder[i]){
				MoveBall(0, team, i)
				client_print(g_last_ballholder[i], print_chat, 
				"%L", g_last_ballholder[i], "SJ_OWNGOAL")
			}
			
		}
	}
	return PLUGIN_HANDLED
}


/*
+-----------------------+--------------------------------------------------------------------------+
|			| ************************************************************************ |
|   [BLOCKED COMMANDS]	| ************************************************************************ |
|			| ************************************************************************ |
+-----------------------+--------------------------------------------------------------------------+
*/
public BlockCommand(id){
	return PLUGIN_HANDLED
}

public client_kill(id){
	return PLUGIN_HANDLED
}

// fix for an exploit
public menuclass(id){	
	// They changed teams
	set_pdata_int(id, OFFSET_INTERNALMODEL, 0xFF, 5)
}

public Msg_Sound(){
	new sz_snd[36]
	get_msg_arg_string(2, sz_snd, charsmax(sz_snd))
	
	if(contain(sz_snd, "rounddraw")	!= -1
	|| contain(sz_snd, "terwin") 	!= -1
	|| contain(sz_snd, "ctwin") 	!= -1)
		return PLUGIN_HANDLED

        return PLUGIN_CONTINUE
}

public Msg_CenterText(){
	new string[64], radio[64]
	get_msg_arg_string(2, string, 63)
	
	if(get_msg_args() > 2) 
		get_msg_arg_string(3, radio, 63)
	//client_print(0, print_chat, "event: %s", string)	
	if(contain(string, 	"#Game_will_restart") 	!= -1 
	|| contain(radio, 	"#Game_radio") 		!= -1 
	|| contain(string, 	"#Spec_Mode") 		!= -1 
	|| contain(string, 	"#Spec_NoTarget") 	!= -1)
		return PLUGIN_HANDLED
	
	if(contain(string, 	"#Round_Draw") 		!= -1 
	|| contain(string, 	"#Terrorists_Win") 	!= -1 
	|| contain(string, 	"#CTs_Win") 		!= -1){
		if(!task_exists(-4789))
			infinite_restart()
		return PLUGIN_HANDLED
	}

	return PLUGIN_CONTINUE
}

public infinite_restart(){
	set_cvar_num("sv_restart", 60)
	
	remove_task(-4566)
	set_task(57.0, "infinite_restart", -4566)
}

public team_select(id, key) { 
	if(key == 0 || key == 1 || key == 4) 
		if(join_team(id, key))
			return PLUGIN_HANDLED
	
	return PLUGIN_CONTINUE 
} 

public vgui_jointeamone(id){
	if(join_team(id, 0)){
		return PLUGIN_HANDLED
	}
	
	remove_task(id + 412)
	set_task(get_pcvar_float(cv_resptime), "RespawnPlayer", id + 412)
	
	return PLUGIN_HANDLED
}

public vgui_jointeamtwo(id){
	if(join_team(id, 1)){
		return PLUGIN_HANDLED
	}
	
	remove_task(id + 412)
	set_task(get_pcvar_float(cv_resptime), "RespawnPlayer", id + 412)
	
	return PLUGIN_HANDLED
}

bool:join_team(id, key=-1) {
	if(GAME_MODE == MODE_NONE){
		ColorChat(id, RED, "^4[SJ] ^1- ^3You can not join the game right now!")
		return true
	}
	if(gGKVoteIsRunning == true){
		ColorChat(id, RED, "^4[SJ] ^1- ^3You can not join the game during caps!")
		return true
	}
	
	new team = get_user_team(id)
	if(key == 4){
		ColorChat(id, GREY, "Please choose a team manually!") 
		return true
	}
	if((team == 1 || team == 2) && (key == team - 1)){		
		ColorChat(id, RED, "You can not rejoin the same team!") 
		engclient_cmd(id, "chooseteam")
		return true			
	}	
	if(g_regtype == 2){
		if((0 <= key <= 1) && !equal(TeamNames[key + 1], g_userClanName[id])){
			ColorChat(id, key?BLUE:RED, "^4[SJ] ^1- You are not member of clan ^3%s^1!", TeamNames[key + 1])
			engclient_cmd(id, "chooseteam")
			return true
		} else if(GAME_MODE != MODE_PREGAME && GAME_MODE != MODE_HALFTIME) {
			new sz_count
			for(new i = 1; i <= g_maxplayers; i++)
				if(IsUserConnected(i) && ~IsUserBot(i) && equal(TeamNames[key + 1], g_userClanName[i]) && get_user_team(i) == (key + 1))
					sz_count++
			
			if(sz_count >= 5){
				ColorChat(id, key?BLUE:RED, "^4[SJ] ^1- Too many players for ^3%s^1!", TeamNames[key + 1])
				engclient_cmd(id,"chooseteam")
				return true
			}
		}
		remove_task(id + 412)
		set_task(get_pcvar_float(cv_resptime), "RespawnPlayer", id + 412)
	
		return false
	}
	if(GAME_MODE == MODE_SHOOTOUT){
		for(new i = 0; i < MAX_PENSHOOTERS; i++)
			if(id == LineUp[i] && candidates[key + 1] == 0)
				return false
	
		if(candidates[key + 1] == id)
			return false

		ColorChat(id, RED, "^4[SJ] ^1- ^3You can not join this team during shootout!")
		return true
	} else if(GAME_MODE != MODE_PREGAME && GAME_MODE != MODE_HALFTIME) {
		new sz_count
		for(new i = 1; i <= g_maxplayers; i++)
			if(IsUserConnected(i) && ~IsUserBot(i) && get_user_team(i) == key + 1)
				sz_count++
			
		if(sz_count >= get_pcvar_num(cv_players) && get_pcvar_num(cv_players)){
			ColorChat(id, key?BLUE:RED, "^4[SJ] ^1- %d players for ^3%s ^1is allowed", get_pcvar_num(cv_players), TeamNames[key + 1])
				
			engclient_cmd(id,"chooseteam")
			return true
		}	
	}
	
	remove_task(id + 412)
	set_task(get_pcvar_float(cv_resptime), "RespawnPlayer", id + 412)
	
	return false
}

/*
+-----------------------+--------------------------------------------------------------------------+
|			| ************************************************************************ |
|       [EVENTS]  	| ************************************************************************ |
|			| ************************************************************************ |
+-----------------------+--------------------------------------------------------------------------+
*/
public PlayerDamage(victim, inflictor, attacker, Float:damage, damagetype){
	if(~IsUserAlive(victim) || ~IsUserAlive(attacker) || !(1 <= attacker <= 32))
		return HAM_IGNORED
	
	new i

	for(i = 0; i <= g_count_balls; i++){
		if(is_valid_ent(g_ball[i])){
			if(!get_pcvar_num(cv_huntdist) || get_entity_distance(g_ball[i], attacker) < get_pcvar_num(cv_huntdist)){
				break
			}
		}
	}
	if(GAME_MODE != MODE_GAME && GAME_MODE != MODE_OVERTIME){
		if(get_entity_distance(victim, Mascots[get_user_team(victim)]) < get_pcvar_num(cv_alienzone) 
		|| freeze_player[victim] || freeze_player[attacker]){
			if(!task_exists(attacker - 2432)){
				set_task(2.0, "Done_Handler", attacker - 2432)
				play_wav(attacker, "barney/donthurtem")
			}
			if(!task_exists(victim - 2432)){
				set_task(2.0, "Done_Handler", victim - 2432)
				play_wav(victim, "barney/donthurtem")
			}
			SetHamParamFloat(4, 0.0)
			return HAM_SUPERCEDE
		}	
	}

	if(i == g_count_balls + 1 && (GAME_MODE == MODE_GAME || GAME_MODE == MODE_OVERTIME)){
		if(!task_exists(attacker - 2432)){
			set_task(2.0, "Done_Handler", attacker - 2432)
			play_wav(attacker, "barney/donthurtem")
		}
		if(!task_exists(victim - 2432)){
			set_task(2.0, "Done_Handler", victim - 2432)
			play_wav(victim, "barney/donthurtem")
		}
		SetHamParamFloat(4, 0.0)
		return HAM_SUPERCEDE
	}
	if(get_user_team(victim) != get_user_team(attacker)){
		Event_Record(attacker, HITS)
		for(i = 0; i <= g_count_balls; i++){
			if(victim == g_ballholder[i])
				break
		}
		if(IsUserAlive(victim)){
			if(i <= g_count_balls){
				new upgrade = PlayerUpgrades[attacker][DIS]
				Event_Record(attacker, BHITS)
				if(upgrade){
					new disarm = upgrade * AMOUNT_DIS
					new disarmpct = BASE_DISARM + disarm
					new rand = random_num(1,100)
							
					if(disarmpct >= rand){
						new vname[32], aname[32]
						get_user_name(victim, vname, 31)
						get_user_name(attacker, aname, 31)
						Event_Record(attacker, DISHITS)
						Event_Record(victim, DISARMED)
						
						KickBall(victim, 1)
						client_print(0, print_chat, "%s disarmed %s", aname, vname)
						//client_print(attacker, print_chat, "%L", attacker, "SJ_DISA", vname)
						//client_print(victim, print_chat, "%L", victim, "SJ_DISED", aname)
					}
				}
			} else if(!task_exists(attacker - 2432)) {
				new sz_vteam = get_user_team(victim)
				if(victim == g_GK[sz_vteam] && (GAME_MODE == MODE_GAME || GAME_MODE == MODE_OVERTIME)){
					new Float:sz_origin[3]
					pev(victim, pev_origin, sz_origin)
					new sz_name [32]
					get_user_name(attacker, sz_name, charsmax(sz_name))
					switch (sz_vteam){
						case T:{
							if(1763.0 <= sz_origin[0] <= 2068.0 && -308.0 <= sz_origin[1] <= 308.0){
								set_task(2.0, "Done_Handler", attacker - 2432)
								set_task(get_pcvar_float(cv_huntgk), "Done_Handler", -5005)
								ColorChat(0, BLUE, "%s ^1is hunting GK!", sz_name)
							}
						}
						case CT:{
							if(-2519.0 <= sz_origin[0] <= -2212.0 && -308.0 <= sz_origin[1] <= 308.0){
								set_task(2.0, "Done_Handler", attacker - 2432)
								set_task(get_pcvar_float(cv_huntgk), "Done_Handler", -5006)
								ColorChat(0, RED, "%s ^1is hunting GK!", sz_name)
							}
						}
					}
					
				}
			}
		}
	} else {
		return HAM_SUPERCEDE
	}
	return HAM_IGNORED
}
stock cs_set_team_score(CsTeams: iTeam, iScore){     
	if(!(CS_TEAM_T <= iTeam <= CS_TEAM_CT)) 
		return PLUGIN_CONTINUE
		
	message_begin(MSG_ALL,get_user_msgid("TeamScore"), {0, 0, 0})
	write_string(iTeam == CS_TEAM_T ? "TERRORIST" : "CT")
	write_short(iScore)
	message_end()
		
	return PLUGIN_HANDLED
}  

public Event_TeamScore(){
	cs_set_team_score(CS_TEAM_T, get_pcvar_num(cv_score[T]))
	cs_set_team_score(CS_TEAM_CT, get_pcvar_num(cv_score[CT]))
}

public Event_Radar(){
	if(!pev_valid(g_ball[0]))
		return PLUGIN_HANDLED
		
	new Float:sz_origin[3]
	pev(g_ball[0], pev_origin, sz_origin)
	if(sz_origin[2] < 0.0)
		return PLUGIN_HANDLED
	for(new id = 1; id <= g_maxplayers; id++){
		if(~IsUserConnected(id) || IsUserBot(id))
			continue

		message_begin(MSG_ONE_UNRELIABLE, get_user_msgid("HostagePos"), { 0, 0, 0}, id)
		write_byte(id)   // I don't know it really. Just logged the msg and it seems to be the id. So I tried it too and it works since 2 years :)
		write_byte(16)   // This is the Hostage ID, I just set it to 16. Important is that you use another ID for another dot :)
		write_coord(floatround(sz_origin[0]))   // x coordinate
		write_coord(floatround(sz_origin[1]))   // y coordinate
		write_coord(floatround(sz_origin[2]))   // z coordinate
		message_end()
		
		message_begin(MSG_ONE_UNRELIABLE, get_user_msgid("HostageK"), { 0, 0, 0}, id)
		write_byte(16)   // Hostage ID from above
		message_end()  
	}
	
	return PLUGIN_HANDLED
}

public Event_StartRound(){
	if(winner){
		GAME_MODE = MODE_PREGAME
		
		if(GAME_TYPE == TYPE_PUBLIC){	
			if(cvar_exists("amx_extendmap_max")){
				server_cmd("mp_timelimit 2")
			} else {
				server_cmd("mp_timelimit 1")
			}
			
			set_cvar_string("amx_nextmap", "-")
			set_task(40.0, "ChangeMap", 9811)
			if(g_count_balls){
				new sz_balls = g_count_balls
				for(new i = 1; i <= sz_balls; i++){
					CreateBall(i)
					MoveBall(1, 0, i)
				}
			}
			//SwitchGameSettings(0, SETS_TRAINING)
		} else {
			sql_saveall()
			PostGame()
		}
	} else {
		if(ROUND == 3){
			g_iTeamBall = 0
			GAME_MODE = MODE_OVERTIME
		}
		
		if(GAME_TYPE == TYPE_PUBLIC){
			SetupRound()
		} else {
			switch(GAME_MODE){
				case MODE_PREGAME: {
					if(g_count_balls){
						new sz_balls = g_count_balls
						for(new i = 1; i <= sz_balls; i++){
							CreateBall(i)
							MoveBall(1, 0, i)
						}
					}
				}
				case MODE_GAME: {
					if(g_Timeleft == -9932) {
						GAME_MODE = MODE_HALFTIME
						
						g_iTeamBall = 0
					} else {
						SetupRound()
					}
				}
				case MODE_SHOOTOUT: {
					set_task(1.0, "PostSetupShootoutRound")
			
				}
				case MODE_OVERTIME: {
					g_Timeleft = -60
					SetupRound()
				}	
			}
		}
	}
	for(new id = 1; id <= g_maxplayers; id++){	
		seconds[id] = 0
		g_sprint[id] = 0
		PressedAction[id] = 0
		SideJump[id] = 0
		SideJumpDelay[id] = 0.0
		if(IsUserAlive(id))
			glow(id, 0, 0, 0)
	}
	remove_task(-4566)
	remove_task(-4789)
	
	sql_updateMatch()
	return PLUGIN_HANDLED
}

public SetupRound(){
	new i, sz_balls = g_count_balls
	for(i = 0; i <= sz_balls; i++){
		CreateBall(i)
		if(g_iTeamBall == 0)
			MoveBall(1, 0, i)
		else
			MoveBall(0, g_iTeamBall==T?CT:T, i)
	}	
	
	g_iTeamBall = 0
	
	for(i = 0; i < MAX_ASSISTERS; i++){
		g_assisters[i] = 0
		g_assisttime[i] = 0.0
	}
	
	play_wav(0, snd_prepare)
		
	g_count_scores = 0
}
public DoHalfTimeReport(){
	new Float:sz_points
	
	for(new id = 1; id <= g_maxplayers; id++){
		if(IsUserConnected(id) && ~IsUserBot(id)){
			sz_points = float(g_Experience[id])
			sz_points /= 100.0
			sz_points /= get_pcvar_float(cv_pointmult)
			g_showhud[id] = 1
			if(sz_points){	
				g_Credits[id] = floatround(sz_points)
				if(sz_points < g_Credits[id])
					g_Credits[id]--
	
				if(g_Credits[id] > g_maxcredits)
					g_Credits[id] = g_maxcredits
			}	
		}
	}
}

public ShootoutSetup(team){
	new id, t, oteam = (team == T ? CT : T)
	next = 0
	candidates[oteam] = 0
	new goaly = 0

	for(new k = 0; k < MAX_ASSISTERS; k++){
		g_assisters[k] = 0
		g_assisttime[k] = 0.0
	}
	for(id = 1; id <= g_maxplayers; id++){
		t = get_user_team(id)
		if(IsUserConnected(id)){
			if(t == T){
				g_PenOrig[id][1] = g_StPen[1] + g_penstep[T]
				g_penstep[T] += PEN_STAND_RADIUS
		
			} else if(t == CT) {
				g_PenOrig[id][1] = -(g_StPen[1] + g_penstep[CT])
				g_penstep[CT] += PEN_STAND_RADIUS
			}
			SetAsWatcher(id, oteam)
			if(t == oteam){
				if(g_GK[oteam] && goaly == g_GK[oteam])
					continue
				if(!goaly || id == g_GK[oteam]) {
					goaly = id
				} else if(PlayerUpgrades[id][DEX] > PlayerUpgrades[goaly][DEX]) {
					goaly = id
				} else if(PlayerUpgrades[id][DEX] == PlayerUpgrades[goaly][DEX]) {
					if(MadeRecord[id][GOALSAVE] > MadeRecord[goaly][GOALSAVE])
						goaly = id
				}
			} else if(t == team) {
				if(next < MAX_PENSHOOTERS)
					LineUp[next++] = id
			}
		}
	}
	new i = 0
	while(next && next < MAX_PENSHOOTERS){
		LineUp[next++] = LineUp[i++]
	}
	next--
	new name[32]

	if(goaly){
		candidates[oteam] = goaly
		get_user_name(goaly, name, 31)
		ColorChat(0, (oteam == T)?RED:BLUE,"^3%s ^1is ^4GOALKEEPER",name)
		freeze_player[goaly] = false
		entity_set_float(goaly, EV_FL_takedamage, 0.0)
	}	
}

public PostSetupShootoutRound() {
	ShootoutSetup(ShootOut)
	if(next >= 0){
		MoveBall(1, 0, -1)
		new id = LineUp[next]
		cs_user_spawn(id)
		entity_set_origin(id, BallSpawnOrigin)
		freeze_player[id] = true
		timer = SHOTCLOCK_TIME
			
		set_task(5.0, "ShotClock", 0)
	} else {
		timer = 0
		set_task(5.0, "ShotClock", 0)
	}
}

public ChangeMap(){
	new cmd[64], map[32]
	get_cvar_string("amx_nextmap", map, 31)
	if(equal(map, "-") || !cvar_exists("amx_nextmap")){
		get_mapname(map, charsmax(map))
	}
	format(cmd, charsmax(cmd), "changelevel %s", map)
	server_cmd(cmd)
}

public PlayerKilled(victim, killer, shouldgib){
	ClearUserAlive(victim)
	
	for(new i = 0; i <= g_count_balls; i++){
		if(g_ballholder[i] == victim){
			new sz_name[32], sz_team = get_user_team(g_ballholder[i])
			get_user_name(g_ballholder[i], sz_name, 31)
										
			remove_task(55555 + i)
			set_task(get_pcvar_float(cv_reset), "ClearBall", 55555 + i)
							
			format(g_temp, charsmax(g_temp), "|%s| %s^n%L", TeamNames[sz_team], sz_name, 
			LANG_SERVER, "SJ_DROPBALL")
										
			// remove glow of owner and set ball velocity really really low
			glow(g_ballholder[i], 0, 0, 0)
										
			g_last_ballholderteam[i] = sz_team
			format(g_last_ballholdername[i], 31, sz_name)
			g_last_ballholder[i] = g_ballholder[i]
			
			pev(g_ballholder[i], pev_origin, testorigin[i])				
			g_ballholder[i] = 0
				
			testorigin[i][2] += 10
			set_pev(g_ball[i], pev_origin, testorigin[i])
						
			set_pev(g_ball[i], pev_velocity, Float:{1.0, 1.0, 1.0})
			
			break
		}
	}
	remove_task(victim + 412)
	set_task(get_pcvar_float(cv_resptime), "RespawnPlayer", victim + 412)

	if(GAME_MODE == MODE_GAME || GAME_MODE == MODE_OVERTIME){
		//g_PlayerDeaths[victim]++
		Event_Record(victim, DEATH)
		if(killer != victim && 1 <= killer <= 31)
			Event_Record(killer, HUNT)
	}
	
	return PLUGIN_HANDLED
}

public PlayerSpawned(id){
	if(is_user_alive(id))
		SetUserAlive(id)

	remove_task(id + 412)
	set_task(0.1, "PlayerSpawnedSettings", id)
}

public RespawnPlayer(id){
	id = id - 412
	
	if (~IsUserConnected(id) || is_user_alive(id) 
	|| get_pdata_int(id, OFFSET_INTERNALMODEL, 5) == 0xFF || !(T <= get_user_team(id) <= CT)
	|| (GAME_MODE == MODE_SHOOTOUT && id != candidates[get_user_team(id)])){
		remove_task(id + 412)	
		set_task(get_pcvar_float(cv_resptime), "RespawnPlayer", id + 412)
		return
	}
	
	remove_task(id + 412)	
		
	set_pev(id, pev_deadflag, DEAD_RESPAWNABLE)
	
	dllfunc(DLLFunc_Think, id)
	if(~IsUserAlive(id)){
		dllfunc(DLLFunc_Spawn, id)	
	}
	set_pev(id, pev_rendermode, kRenderNormal)
}

public User_Spawn(id){
	dllfunc(DLLFunc_Spawn, id)
}

public PlayerSpawnedSettings(id){
	if(IsUserAlive(id)){
		CsSetUserScore(id, g_MVP_points[id], MadeRecord[id][DEATH])
		set_speedchange(id)
		
		set_pev(id, pev_health, float(100 + (PlayerUpgrades[id][STA] * AMOUNT_STA))) 
		
		if(g_Credits[id] && (GAME_MODE == MODE_PREGAME || GAME_MODE == MODE_HALFTIME)){
			TNT_BuyUpgrade(id)
		}
			
		ChangeGK(id)
		
		/*for(new i = 0; i < 5; i++){
			if(gTopPlayers[i] == g_PlayerId[id]){
				fm_reset_user_model(id)
				fm_reset_user_model(id)
				fm_set_user_model(id, mdl_players[get_user_team(id)], true)

				set_task(0.5, "taskSetTopPlayerModel", id - 5311)
				break
			}
		}*/
		
		// prevent bug when transfered from spec or non-team 
		new sz_clip
		get_user_weapon(id, sz_clip)
		if(!sz_clip){
			set_pdata_int(id, 121, 5) 
			set_task(0.1, "User_Spawn", id)
		}
		
		hiddenCorpse[id]  = false
		
	}
}

/*public taskSetTopPlayerModel(id){
	id += 5311
	fm_reset_user_model(id)
	fm_reset_user_model(id)
	fm_set_user_model(id, mdl_players[get_user_team(id)], true)
}
*/

/*
+-----------------------+--------------------------------------------------------------------------+
|			| ************************************************************************ |
|      [CONTROLS]	| ************************************************************************ |
|			| ************************************************************************ |
+-----------------------+--------------------------------------------------------------------------+
*/
public Turbo(id){
	if(IsUserAlive(id) && !seconds[id])
		g_sprint[id] = 1
	
	return PLUGIN_HANDLED
}

public client_PreThink(id){
	if(IsUserAlive(id)){
		if(freeze_player[id]){
			entity_set_float(id, EV_FL_maxspeed, 0.1)
			return PLUGIN_CONTINUE
		}
		new button 	= pev(id, pev_button)	
		new usekey 	= (button & IN_USE)
		new up 		= (button & IN_FORWARD)
		new down 	= (button & IN_BACK)
		new moveright 	= (button & IN_MOVERIGHT)
		new moveleft 	= (button & IN_MOVELEFT)
		new jump 	= (button & IN_JUMP)
		new onground 	= pev(id, pev_flags) & FL_ONGROUND
		
		new i
		for(i = 0; i <= g_count_balls; i++)
			if(id == g_ballholder[i])
				break	
		
		if(SideJump[id] == 1)
			SideJump[id] = 0
			
		if((moveright || moveleft) && !up && !down && jump
		&& !g_sprint[id] && onground && i == g_count_balls + 1 && SideJump[id] != 2){
			SideJump[id] = 1
		}
		
		if(g_sprint[id])
			entity_set_float(id, EV_FL_fuser2, 0.0)

		if(i == g_count_balls + 1){
			if(GAME_TYPE == TYPE_PUBLIC && button & IN_ALT1){
				if(!task_exists(id + 3122))
					set_task(0.1, "ShowPassSprite", id + 3122)
			}	
			PressedAction[id] = usekey
		} else {
			if(usekey && !PressedAction[id]){
				KickBall(id, 0)
			} else if(!usekey && PressedAction[id]){
				PressedAction[id] = 0
			}
		}
		
		
		//if(g_sprint[id] == false) return PLUGIN_CONTINUE;
   
		/*new buttons = pev(id, pev_button);
		new oldbuttons = pev(id, pev_oldbuttons);
   
		if(buttons & IN_JUMP)
		{
			g_ePlayerInfo[id][m_JumpHoldFrames]++;
		}
		if(buttons & IN_JUMP && ~oldbuttons & IN_JUMP)
		{
			g_ePlayerInfo[id][m_JumpPressCount]++;
		}
    if(~buttons & IN_JUMP && oldbuttons & IN_JUMP)
    {
        ///**************************************
    }
    if(buttons & IN_DUCK)
    {
        g_ePlayerInfo[id][m_DuckHoldFrames]++;
    }
   
    new on_ground = bool:(pev(id, pev_flags) & FL_ONGROUND);
   
    if(on_ground)
    {
        g_ePlayerInfo[id][m_GroundFrames]++;
    }
    else
    {
        if(g_ePlayerInfo[id][m_GroundFrames])
        {
            new Float:velocity[3]; pev(id, pev_velocity, velocity); velocity[2] = 0.0;
            g_ePlayerInfo[id][m_Velocity] = _:vector_length(velocity);
            g_ePlayerInfo[id][m_PreJumpGroundFrames] = g_ePlayerInfo[id][m_GroundFrames];
        }
        g_ePlayerInfo[id][m_GroundFrames] = 0;
        g_ePlayerInfo[id][m_AirFrames]++;
    }
   
    if(g_ePlayerInfo[id][m_OldGroundFrames] == 0 && g_ePlayerInfo[id][m_GroundFrames])
    {
        if(g_ePlayerInfo[id][m_JumpPressCount] == 0 && g_ePlayerInfo[id][m_JumpHoldFrames] == 0 && g_ePlayerInfo[id][m_DuckHoldFrames] == 0)
        {
            //console_print(id, "wtf? JumpPressCount 0, JumpHoldFrames 0, DuckHoldFrames 0");
        }
        if(g_ePlayerInfo[id][m_JumpPressCount] > 0)
        {
            /// if g_ePlayerInfo[id][m_JumpHoldFrames] == g_ePlayerInfo[id][m_JumpPressCount] cheat
            /// if g_ePlayerInfo[id][m_JumpPressCount] > 16 script
           
            //console_print(id, "ground [%d], air [%d], jumphold [%d], jumpcount [%d], velocity [%.3f]", g_ePlayerInfo[id][m_PreJumpGroundFrames],  g_ePlayerInfo[id][m_AirFrames], g_ePlayerInfo[id][m_JumpHoldFrames], g_ePlayerInfo[id][m_JumpPressCount], g_ePlayerInfo[id][m_Velocity]);
           
            /// TODO: сделать цикл
            if(g_ePlayerInfo[id][m_JumpHoldFrames] == g_ePlayerInfo[id][m_JumpPressCount])
            {
                g_ePlayerWarn[id][m_WarnEqualFrames]++;
                if(g_ePlayerWarn[id][m_WarnEqualFrames] > g_ePlayerWarnMax[id][m_WarnEqualFrames])
                {
                    g_ePlayerWarnMax[id][m_WarnEqualFrames] = g_ePlayerWarn[id][m_WarnEqualFrames];
                }
            }
            else if(g_ePlayerWarn[id][m_WarnEqualFrames])
            {
                g_ePlayerWarn[id][m_WarnEqualFrames]--;
	      // g_ePlayerWarn[id][m_WarnEqualFrames]=0;
            }
           
            if(g_ePlayerInfo[id][m_PreJumpGroundFrames] == g_ePlayerInfo[id][m_OldPreJumpGroundFrames])
            {
                g_ePlayerWarn[id][m_WarnGroundEqualFrames]++;
                if(g_ePlayerWarn[id][m_WarnGroundEqualFrames] > g_ePlayerWarnMax[id][m_WarnGroundEqualFrames])
                {
                    g_ePlayerWarnMax[id][m_WarnGroundEqualFrames] = g_ePlayerWarn[id][m_WarnGroundEqualFrames];
                }
            }
            else if(g_ePlayerWarn[id][m_WarnGroundEqualFrames])
            {
                g_ePlayerWarn[id][m_WarnGroundEqualFrames]--;
            }
           
            if(g_ePlayerInfo[id][m_JumpPressCount] >= MAX_JUMPCOUNT)
            {
                g_ePlayerWarn[id][m_WarnJumpSpam]++;
                if(g_ePlayerWarn[id][m_WarnJumpSpam] > g_ePlayerWarnMax[id][m_WarnJumpSpam])
                {
                    g_ePlayerWarnMax[id][m_WarnJumpSpam] = g_ePlayerWarn[id][m_WarnJumpSpam];
                }
            }
            else if(g_ePlayerWarn[id][m_WarnJumpSpam])
            {
                g_ePlayerWarn[id][m_WarnJumpSpam]--;
            }
           
          //  //console_print(id, "groundequal [%d], jumpequal[%d], jumpspam [%d]", g_ePlayerWarn[id][m_WarnGroundEqualFrames], g_ePlayerWarn[id][m_WarnEqualFrames], g_ePlayerWarn[id][m_WarnJumpSpam]);
           client_print(id, print_chat,"groundequal [%d], jumpequal[%d], jumpspam [%d]", g_ePlayerWarn[id][m_WarnGroundEqualFrames], g_ePlayerWarn[id][m_WarnEqualFrames], g_ePlayerWarn[id][m_WarnJumpSpam]);
           
            if(g_ePlayerWarn[id][m_WarnGroundEqualFrames] >= MAX_GROUND_FRAME_COINCIDENCE)
            {
                //PunishPlayer(id, "BhopHack[g]");
                g_ePlayerWarn[id][m_WarnGroundEqualFrames] = 0;
            }
	    if(g_ePlayerWarn[id][m_WarnEqualFrames] >= 30)
            {
               // PunishPlayer(id, "BhopHack[g]");
                g_ePlayerWarn[id][m_WarnEqualFrames]=0;
            }
            if(g_ePlayerWarn[id][m_WarnJumpSpam] >= MAX_JUMP_SPAM)
            {
                //PunishPlayer(id, "BhopHack[s]");
                g_ePlayerWarn[id][m_WarnJumpSpam] = 0;
            }
        }
       
        g_ePlayerInfo[id][m_AirFrames] = 0;
        g_ePlayerInfo[id][m_JumpHoldFrames] = 0;
        g_ePlayerInfo[id][m_JumpPressCount] = 0;
        g_ePlayerInfo[id][m_DuckHoldFrames] = 0;
        g_ePlayerInfo[id][m_OldPreJumpGroundFrames] = g_ePlayerInfo[id][m_PreJumpGroundFrames];
    }
   
    g_ePlayerInfo[id][m_OldGroundFrames] = g_ePlayerInfo[id][m_GroundFrames];*/
		
		
	}
	
	return PLUGIN_CONTINUE
}

public client_PostThink(id){
	if(IsUserAlive(id)){
		new Float:gametime = get_gametime()
		new button = entity_get_int(id, EV_INT_button)
			
		new up = (button & IN_FORWARD)
		new down = (button & IN_BACK)
		new moveright = (button & IN_MOVERIGHT)
		new moveleft = (button & IN_MOVELEFT)
		new jump = (button & IN_JUMP)
		
		if((gametime - SideJumpDelay[id]) > get_pcvar_float(cv_ljdelay)){
			if(SideJump[id] == 1 && jump && (moveright || moveleft) && !up && !down){
				new Float:vel[3]
				pev(id, pev_velocity, vel)
				vel[0] *= 2.0
				vel[1] *= 2.0
				vel[2] = 300.0
				SideJump[id] = 2
				set_pev(id, pev_velocity, vel)
				SideJumpDelay[id] = gametime
				
				return PLUGIN_CONTINUE
			}	
		}
	}
	return PLUGIN_CONTINUE
}

public CurveRight(id){
	new i
	for(i = 0; i <= g_count_balls; i++){
		if(id == g_ballholder[i])
			break
	}
	if(i != g_count_balls + 1){
		if(--direction[i] < -(DIRECTIONS))
			direction[i] = -(DIRECTIONS)
		SendCenterText(id, direction[i] * CURVE_ANGLE)
	} else {
		client_print(id, print_chat, "%L", id, "SJ_RCANTCURVE")
	}

	return PLUGIN_HANDLED
}

SendCenterText(id, dir){
	new sz_temp[12]
	if(dir < 0){
		format(sz_temp, charsmax(sz_temp), "%L", id, "SJ_RIGHT")
	} else if(dir == 0) {
		format(sz_temp, charsmax(sz_temp), "")
	} else if(dir > 0) {
		format(sz_temp, charsmax(sz_temp), "%L", id, "SJ_LEFT")
	}
		
	client_print(id, print_center, "%i %L %s", (dir < 0?-(dir):dir), id, "SJ_DEGREES", sz_temp)	
}

public CurveLeft(id){
	new i
	for(i = 0; i <= g_count_balls; i++){
		if(id == g_ballholder[i])
			break
	}

	if(i != g_count_balls + 1){
		if(++direction[i] > DIRECTIONS)
			direction[i] = DIRECTIONS
		SendCenterText(id, direction[i] * CURVE_ANGLE)
	} else {
		client_print(id, print_chat, "%L", id, "SJ_LCANTCURVE")
	}
	
	return PLUGIN_HANDLED
}

/*
+-----------------------+--------------------------------------------------------------------------+
|			| ************************************************************************ |
|      [COMMANDS]	| ************************************************************************ |
|			| ************************************************************************ |
+-----------------------+--------------------------------------------------------------------------+
*/

public EndGame(id, level, cid) {
	if(!cmd_access(id, level, cid, 0) || GAME_TYPE == TYPE_PUBLIC)
		return PLUGIN_HANDLED
		
	new name[64]
	get_user_name(id, name, charsmax(name))
	
	ColorChat(0, GREEN, "^4[SJ] ^1- End Game (ADMIN: %s)", name)
	
	MoveBall(0, 0, 0)
	g_current_match = 0
	gMatchId = 0
	g_saveall = 1
	set_pcvar_num(cv_score[T], 0)
	set_pcvar_num(cv_score[CT], 0)
	remove_task(9999)
	
	ROUND = -1
	
	set_task(3.0, "PostGame")
	
	round_restart(3.0)
	
	return PLUGIN_HANDLED
}

public ChatCommands(id){
	new said[192]
	read_args(said, 192)
	remove_quotes(said)
	new sz_cmd[32], info[32], x, sz_name[32]
	parse(said, sz_cmd, 31, info, 31)
	get_user_name(id, sz_name, charsmax(sz_name))
	new sz_team = get_user_team(id)
	if(GAME_MODE == MODE_PREGAME || GAME_MODE == MODE_HALFTIME) {
		if((equal(sz_cmd, ".ready") || equal(sz_cmd, "/ready")) && T <= sz_team <= CT) {
			if(g_Credits[id]) {
				ColorChat(id, RED, "You must use all your credits before becoming ready!")
				TNT_BuyUpgrade(id)
				return PLUGIN_HANDLED_MAIN
			}
			
			if(!get_pcvar_num(cv_chat)){
				g_Ready[id] = true
				return PLUGIN_HANDLED_MAIN
			} else {
				if(g_Ready[id] == false){
					ColorChat(0, (sz_team == T)?RED:BLUE, "^3%s ^1: ^4.ready", sz_name)
					
					g_Ready[id] = true
					return PLUGIN_HANDLED_MAIN
				}
				
			}
		} else if((equal(sz_cmd, ".wait") || equal(sz_cmd, "/wait")) && T <= sz_team <= CT) {
			g_Ready[id] = false
			if(!get_pcvar_num(cv_chat)) {
				return PLUGIN_HANDLED_MAIN
			} else {
				ColorChat(0, (sz_team == T)?RED:BLUE, "^3%s ^1: ^4.wait", sz_name)
				
				return PLUGIN_HANDLED_MAIN
			}
		} else if((equal(sz_cmd, ".reset") || equal(sz_cmd, "/reset")) && T <= sz_team <= CT) {
			if(gGKVoteIsRunning && (id == g_GK[T] || id == g_GK[CT])){
				ColorChat(id, RED, "You can not reset your skills being a GK during caps.")
				return PLUGIN_HANDLED_MAIN
			}
			if(GAME_TYPE == TYPE_PUBLIC){
				new sz_money, k	
				for(x = 1; x <= UPGRADES; x++){
					for(k = 0; k < PlayerUpgrades[id][x]; k++)
						sz_money += UpgradePrice[x][k]
					PlayerUpgrades[id][x] = 0
				}
				g_Experience[id] += sz_money
				cs_set_user_money(id, g_Experience[id])
				BuyUpgrade(id)
			} else {
				ResetSkills(id)
					
				ChangeGK(id)
					
				g_Ready[id] = false
					
				TNT_BuyUpgrade(id)
			}
			if(!get_pcvar_num(cv_chat)){
				return PLUGIN_HANDLED_MAIN
			} else {
				ColorChat(0, (sz_team == T)?RED:BLUE, "^3%s ^1: ^4.reset", sz_name)
						
				return PLUGIN_HANDLED_MAIN
			}
		}
	}
	if(contain(sz_cmd, ".stats") != -1 || contain(sz_cmd, "/stats") != -1){
		if(!info[0]){
			if(GAME_MODE != MODE_PREGAME && GAME_MODE != MODE_HALFTIME){
				ShowMenuStats(id)
			} else {
				(g_showhud[id])?(g_showhud[id] = 0):(g_showhud[id] = 1)
			}
			//ShowMOTDStats(id, id)	
		} else {
			new player = cmd_target(id, info, 8)
			if(player){
				TNT_ShowMenuPlayerStats(id, player)
				//ShowMOTDStats(id, player)
			} else {
				ColorChat(id, RED, "^4[SJ] ^1- ^3%L", id, "SJ_INVPLAYER")
			}
		}
		if(!get_pcvar_num(cv_chat))
			return PLUGIN_HANDLED_MAIN
	} else if(contain(sz_cmd, ".skills") != -1 || contain(sz_cmd, "/skills") != -1){
		new player = cmd_target(id, info, 8)
		if(!info[0]){
			TNT_ShowUpgrade(id, id)
		} else if(player) {
			TNT_ShowUpgrade(id, player)
		} else {
			ColorChat(id, RED, "^4[SJ] ^1- ^3%L", id, "SJ_INVPLAYER")
		}
		
		if(!get_pcvar_num(cv_chat))
			return PLUGIN_HANDLED_MAIN
	} else if(equal(sz_cmd, "/spec") || equal(sz_cmd, ".spec")){
		cmdSpectate(id)
		if(!get_pcvar_num(cv_chat))
			return PLUGIN_HANDLED_MAIN
	} else if(equal(sz_cmd, "/cam") || equal(sz_cmd, ".cam")){
		CameraChanger(id)
		if(!get_pcvar_num(cv_chat))
			return PLUGIN_HANDLED_MAIN
	} else if(equal(sz_cmd, "/whois") || equal(sz_cmd, ".whois")
		|| equal(sz_cmd, "/players") || equal(sz_cmd, ".players")
		|| equal(sz_cmd, "/users") || equal(sz_cmd, ".users")){
		WhoIs(id)
		if(!get_pcvar_num(cv_chat))
			return PLUGIN_HANDLED_MAIN
	} else if(equal(sz_cmd, "/first") || equal(sz_cmd, ".first")
		|| equal(sz_cmd, "/firstperson") || equal(sz_cmd, ".firstperson")){
		g_cam[id] = true
		CameraChanger(id)
		if(!get_pcvar_num(cv_chat))
			return PLUGIN_HANDLED_MAIN
	} else if(equal(sz_cmd, "/third") || equal(sz_cmd, ".third") 
		|| equal(sz_cmd, "/thirdperson") || equal(sz_cmd, ".thirdperson")){
		g_cam[id] = false
		CameraChanger(id)
		if(!get_pcvar_num(cv_chat))
			return PLUGIN_HANDLED_MAIN
	} /*else if(contain(sz_cmd, "/top") != -1 || contain(sz_cmd, ".top") != -1){
		if(sql_error[0] == EOS && sql_tuple){
			new i = str_to_num(sz_cmd[4])
			cmd_top(id, i)
		}
		else
			ColorChat(id, RED, "^4[SJ] ^1- ^3%L", id, "SJ_SQLNOTAV")
		if(!get_pcvar_num(cv_chat))
			return PLUGIN_HANDLED_MAIN
		//client_print(0, print_chat, "[SJ] - Could not connect to SQL-database: Host: %s User: %s Pass %s Database: %s", 
		//sql_host, sql_user, sql_pass, sql_db)
	}*/
	else if(equal(sz_cmd, "/help") || equal(sz_cmd, ".help")){
		Help(id)
		if(!get_pcvar_num(cv_chat))
			return PLUGIN_HANDLED_MAIN
	} else if(equal(sz_cmd, "/rank") || equal(sz_cmd, ".rank")){
		if(sql_error[0] == EOS && sql_tuple){
			new player = cmd_target(id, info, 8)
			if(equal(info, "")){
				//sql_rank(id, id, 0)
			} else if(1 <= player <= MAX_PLAYERS) {
				//sql_rank(id, player, 0)
			} else {
				ColorChat(id, RED, "^4[SJ] ^1- ^3%L", id, "SJ_INVPLAYER")
			}
		} else {
			ColorChat(id, RED, "^4[SJ] ^1- ^3%L", id, "SJ_SQLNOTAV")
		}
		if(!get_pcvar_num(cv_chat))
			return PLUGIN_HANDLED_MAIN
		
	} else if(equal(sz_cmd, "/rankstats") || equal(sz_cmd, ".rankstats")){
		if(sql_error[0] == EOS && sql_tuple){
			new player = cmd_target(id, info, 8)
			if(equal(info, "")){
				//sql_rank(id, id, 1)
			} else if(1 <= player <= MAX_PLAYERS) {
				//sql_rank(id, player, 1)
			} else {
				ColorChat(id, RED, "^4[SJ] ^1- ^3%L", id, "SJ_INVPLAYER")
			}
		} else {
			ColorChat(id, RED, "^4[SJ] ^1- ^3%L", id, "SJ_SQLNOTAV")
		}
		if(!get_pcvar_num(cv_chat))
			return PLUGIN_HANDLED_MAIN
	} else if(equal(sz_cmd, "/helpmenu") || equal(sz_cmd, ".helpmenu")){
		PlayerHelpMenu(id)
		if(!get_pcvar_num(cv_chat))
			return PLUGIN_HANDLED_MAIN
	} else if(contain(sz_cmd, ".setskills") != -1 || contain(sz_cmd, "/setskills") != -1){
		if(!is_user_admin(id)){
			ColorChat(id, RED, "^4[SJ] ^1- ^3You have no access to this command.")
			return PLUGIN_HANDLED_MAIN
		}
		new sz_skills[16], sz_buff[64], sz_name[32], i, sz_len
		
		parse(said, sz_buff, charsmax(sz_buff), sz_name, charsmax(sz_name), sz_skills, charsmax(sz_skills))
		
		if(strlen(said) < strlen(sz_cmd) + 2 || sz_skills[0] == EOS){
			for(i = 1; i <= UPGRADES; i++)
				sz_len += format(sz_buff[sz_len], charsmax(sz_buff) - sz_len, "<0-%d>", UpgradeMax[i])
		
			ColorChat(id, RED, "^4[SJ] ^1- ^4Usage: ^1/setskills <player> %s", sz_buff)
			ColorChat(id, RED, "^1This example sets GK skills for Player: ^4/setskills Player 00550")
			return PLUGIN_HANDLED_MAIN
		}
		
		new x = str_to_num(sz_skills)
		new sz_sk[UPGRADES + 1]
		for(i = UPGRADES; i; i--){
			if((sz_sk[i] = (x % 10)) > UpgradeMax[i]){
				ColorChat(id, RED, "^4[SJ] ^1- ^3Invalid skills!")
				return PLUGIN_HANDLED_MAIN
			}
			x /= 10
		}
		if(x < 0){
			ColorChat(id, RED, "^4[SJ] ^1- ^3Invalid skills!")
			return PLUGIN_HANDLED_MAIN
		} else { 
			new player = cmd_target(id, info, 2 | 8)
			if(player){
				new sz_aname[32], sz_color[3]
				get_user_name(id, sz_aname, charsmax(sz_aname))
				get_user_name(player, sz_name, charsmax(sz_name))
				sz_len = 0
				for(i = UPGRADES; i; i--){
					PlayerUpgrades[player][i] = sz_sk[i]
				}
				for(i = 1; i <= UPGRADES; i++){
					if(PlayerUpgrades[player][i] == UpgradeMax[i]){
						format(sz_color, charsmax(sz_color), "^3")
					} else if(PlayerUpgrades[player][i]) {
						format(sz_color, charsmax(sz_color), "^4")
					} else {
						format(sz_color, charsmax(sz_color), "^1")
					}
					sz_len += format(sz_buff[sz_len], charsmax(sz_buff) - sz_len, "%s %d", sz_color, PlayerUpgrades[player][i])
				}
				g_Credits[player] = 0

				ColorChat(0, RED, "^4[SJ] ^1- %s skills are set:%s ^1(ADMIN: %s)", sz_name, sz_buff, sz_aname)
				ChangeGK(player)
			} else {
				ColorChat(id, RED, "^4[SJ] ^1- ^3%L", id, "SJ_INVPLAYER")
			}
		}
		
		if(!get_pcvar_num(cv_chat))
			return PLUGIN_HANDLED_MAIN
	} else if(GAME_TYPE == TYPE_PUBLIC && (equal(sz_cmd, "/$") || equal(sz_cmd, ".$") || equal(sz_cmd, "$"))){
		new sz_cvar = get_pcvar_num(cv_donate)
		if(sz_cvar == 0){
			ColorChat(id, GREEN, "[SJ] ^1- ^3%L", id, "SJ_DONDIS")
			return PLUGIN_CONTINUE
		}

		new sz_exp[16], sz_buff[16], sz_name[32]
		
		parse(said, sz_buff, 15, sz_name, 31, sz_exp, 15)
		
		if(strlen(said) < strlen(sz_cmd) + 2 || sz_exp[0] == EOS){
			ColorChat(id, GREEN, "[SJ] ^1- %L", id, "SJ_DONUSAGE")
			return PLUGIN_CONTINUE
		}
		
		new x = str_to_num(sz_exp)
		if(x < 1){
			ColorChat(id, GREEN, "[SJ] ^1- %L", id, "SJ_DONINVAM")
			return PLUGIN_CONTINUE
		}
		if(equal(info, "*")){
			GiveXP(id, 0, x)
		} else {
			new player = cmd_target(id, info, 2 | 8)
			if(player){
				GiveXP(id, player, x)
			} else {
				ColorChat(id, RED, "^4[SJ] ^1- ^3%L", id, "SJ_INVPLAYER")
			}
		}
		if(!get_pcvar_num(cv_chat))
			return PLUGIN_HANDLED_MAIN
	}
	if(!get_pcvar_num(cv_chat)){
		client_print(id, print_center, "- Global chat is blocked -")
		return PLUGIN_HANDLED
	}
	new sz_len = strlen(said)
	if(!sz_len)
		return PLUGIN_HANDLED_MAIN
	new sz_empty
	for(x = 0; x < sz_len; x++){
		if(said[x] != ' ' && said[x] != '%')
			sz_empty = 1
		if(said[x] == '%')
			said[x] = ' '
	}
			
	if(x == sz_len && !sz_empty)
		return PLUGIN_HANDLED_MAIN
			
	for(new i = 1; i <= g_maxplayers; i++){
		if(~IsUserConnected(i) || (IsUserBot(i) && !is_user_hltv(i)))
			continue
				
		get_user_name(id, sz_name, 31)
		
		if(sz_team == T){
			ColorChat(i, RED, "%s ^1: %s", sz_name, said)
		} else if(sz_team == CT) {
			ColorChat(i, BLUE, "%s ^1: %s", sz_name, said)
		} else {
			ColorChat(i, GREY, "%s ^1: %s", sz_name, said)
		}
	}

	return PLUGIN_HANDLED_MAIN
	
}

public ChatCommands_team(id){
	new said[192]
	read_args(said, 192)
	remove_quotes(said)
	new sz_cmd[32], info[32], x, sz_name[32]
	parse(said, sz_cmd, 31, info, 31)
	get_user_name(id, sz_name, 31)
	new sz_team = get_user_team(id)
	if(GAME_MODE == MODE_PREGAME || GAME_MODE == MODE_HALFTIME) {
		if((equal(sz_cmd, ".ready") || equal(sz_cmd, "/ready")) && (T <= sz_team <= CT)){	
			if(g_Credits[id]) {
				ColorChat(id, RED, "You must use all your credits before becoming ready!")
				TNT_BuyUpgrade(id)
			} else {
				if(g_Ready[id] == false){
					g_Ready[id] = true
	
					if(sz_team == T){
						for(new i = 1; i <= g_maxplayers; i++){
							if(IsUserConnected(i) && get_user_team(i) == T)
								ColorChat(i, RED, "^1(Terrorist) ^3%s ^1: ^4.ready", sz_name)
						}
					} else {
						for(new i = 1; i <= g_maxplayers; i++){
							if(IsUserConnected(i) && get_user_team(i) == CT)
								ColorChat(i, BLUE, "^1(Counter-Terrorist) ^3%s ^1: ^4.ready", sz_name)
						}
					}
					
					return PLUGIN_HANDLED_MAIN
				}
			}
		} else if((equal(sz_cmd, ".wait") || equal(sz_cmd, "/wait")) && (T <= sz_team <= CT)){
			g_Ready[id] = false
			
			if(sz_team == T){
				for(new i = 1; i <= g_maxplayers; i++){
					if(IsUserConnected(i) && get_user_team(i) == T)
						ColorChat(i, RED, "^1(Terrorist) ^3%s ^1: ^4.wait", sz_name)
				}
			} else {
				for(new i = 1; i <= g_maxplayers; i++){
					if(IsUserConnected(i) && get_user_team(i) == CT)
						ColorChat(i, BLUE, "^1(Counter-Terrorist) ^3%s ^1: ^4.wait", sz_name)
				}
			}
			
			return PLUGIN_HANDLED_MAIN
		} else if((equal(sz_cmd, ".reset") || equal(sz_cmd, "/reset")) && T <= sz_team <= CT) {
			if(gGKVoteIsRunning && (id == g_GK[T] || id == g_GK[CT])){
				ColorChat(id, RED, "You can not reset your skills being a GK during caps.")
				return PLUGIN_HANDLED_MAIN
			}
			if(GAME_TYPE == TYPE_PUBLIC){
				new sz_money, k	
				for(x = 1; x <= UPGRADES; x++){
					for(k = 0; k < PlayerUpgrades[id][x]; k++)
						sz_money += UpgradePrice[x][k]
					PlayerUpgrades[id][x] = 0
				}
				g_Experience[id] += sz_money
				cs_set_user_money(id, g_Experience[id])
				BuyUpgrade(id)
			} else {
				ResetSkills(id)
					
				ChangeGK(id)
					
				g_Ready[id] = false
					
				TNT_BuyUpgrade(id)

				if(sz_team == T){
					for(new i = 1; i <= g_maxplayers; i++){
						if(IsUserConnected(i) && get_user_team(i) == T)
							ColorChat(i, RED, "^1(Terrorist) ^3%s ^1: ^4.reset", sz_name)
					}
				} else {
					for(new i = 1; i <= g_maxplayers; i++){
						if(IsUserConnected(i) && get_user_team(i) == CT)
							ColorChat(i, BLUE, "^1(Counter-Terrorist) ^3%s ^1: ^4.reset", sz_name)
					}
				}
					
				return PLUGIN_HANDLED_MAIN
			}
		}
	}
	if(contain(sz_cmd, ".stats") != -1 || contain(sz_cmd, "/stats") != -1){
		if(!info[0]){
			if(GAME_MODE != MODE_PREGAME && GAME_MODE != MODE_HALFTIME) {
				ShowMenuStats(id)
			} else {
				(g_showhud[id])?(g_showhud[id] = 0):(g_showhud[id] = 1)
			}
		} else {
			new player = cmd_target(id, info, 8)
			if(player){
				TNT_ShowMenuPlayerStats(id, player)
			} else {
				ColorChat(id, RED, "^4[SJ] ^1- ^3%L", id, "SJ_INVPLAYER")
			}
		}
	} else if(contain(sz_cmd, ".skills") != -1 || contain(sz_cmd, "/skills") != -1 ){
		new player = cmd_target(id, info, 8)
		if(!info[0]) {
			TNT_ShowUpgrade(id, id)
		} else if(player) {
			TNT_ShowUpgrade(id, player)
		} else {
			ColorChat(id, RED, "^4[SJ] ^1- ^3%L", id, "SJ_INVPLAYER")
		}
	} else if(equal(sz_cmd, "/spec") || equal(sz_cmd, ".spec")){
		cmdSpectate(id)
	} else if(equal(sz_cmd, "/cam") || equal(sz_cmd, ".cam")){
		CameraChanger(id)
	} else if(equal(sz_cmd, "/whois") || equal(sz_cmd, ".whois")
		|| equal(sz_cmd, "/players") || equal(sz_cmd, ".players")
		|| equal(sz_cmd, "/users") || equal(sz_cmd, ".users")){
		WhoIs(id)
	} else if(equal(sz_cmd, "/first")|| equal(sz_cmd, ".first")
		|| equal(sz_cmd, "/firstperson") || equal(sz_cmd, ".firstperson")){
		g_cam[id] = true
		CameraChanger(id)
	} else if(equal(sz_cmd, "/third") || equal(sz_cmd, ".third")
		|| equal(sz_cmd, "/thirdperson") || equal(sz_cmd, ".thirdperson")){
		g_cam[id] = false
		CameraChanger(id)
	}
	/*else if(contain(sz_cmd, "/top") != -1 || contain(sz_cmd, ".top") != -1){
		if(sql_error[0] == EOS && sql_tuple){
			new i = str_to_num(sz_cmd[4])
			cmd_top(id, i)
		}
		else
			ColorChat(id, RED, "^4[SJ] ^1- ^3%L", id, "SJ_SQLNOTAV")
		//client_print(0, print_chat, "[SJ] - Could not connect to SQL-database: Host: %s User: %s Pass %s Database: %s", 
		//sql_host, sql_user, sql_pass, sql_db)
	}*/
	else if(equal(sz_cmd, "/help") || equal(sz_cmd, ".help")){
		Help(id)
	} else if(contain(sz_cmd, ".setskills") != -1 || contain(sz_cmd, "/setskills") != -1){
		if(!is_user_admin(id)){
			ColorChat(id, RED, "^4[SJ] ^1- ^3You have no access to this command.")
			return PLUGIN_CONTINUE
		}
		new sz_skills[16], sz_buff[64], sz_name[32], i, sz_len
		
		parse(said, sz_buff, charsmax(sz_buff), sz_name, charsmax(sz_name), sz_skills, charsmax(sz_skills))
		
		if(strlen(said) < strlen(sz_cmd) + 2 || sz_skills[0] == EOS){
			for(i = 1; i <= UPGRADES; i++)
				sz_len += format(sz_buff[sz_len], charsmax(sz_buff) - sz_len, "<0-%d>", UpgradeMax[i])
		
			ColorChat(id, RED, "^4[SJ] ^1- ^4Usage: ^1/setskills <player> %s", sz_buff)
			ColorChat(id, RED, "^1This example sets GK skills for Player: ^4/setskills Player 00550")
			return PLUGIN_CONTINUE
		}
		
		new x = str_to_num(sz_skills)
		new sz_sk[UPGRADES + 1]
		for(i = UPGRADES; i; i--){
			if((sz_sk[i] = (x % 10)) > UpgradeMax[i]){
				ColorChat(id, RED, "^4[SJ] ^1- ^3Invalid skills!")
				return PLUGIN_CONTINUE
			}
			x /= 10
		}
		if(x < 0){
			ColorChat(id, RED, "^4[SJ] ^1- ^3Invalid skills!")
			return PLUGIN_CONTINUE
		} else { 
			new player = cmd_target(id, info, 2 | 8)
			if(player){
				new sz_aname[32], sz_color[3]
				get_user_name(id, sz_aname, charsmax(sz_aname))
				get_user_name(player, sz_name, charsmax(sz_name))
				sz_len = 0
				for(i = UPGRADES; i; i--){
					PlayerUpgrades[player][i] = sz_sk[i]
				}
				for(i = 1; i <= UPGRADES; i++){
					if(PlayerUpgrades[player][i] == UpgradeMax[i]) {
						format(sz_color, charsmax(sz_color), "^3")
					} else if(PlayerUpgrades[player][i]) {
						format(sz_color, charsmax(sz_color), "^4")
					} else {
						format(sz_color, charsmax(sz_color), "^1")
					}
					sz_len += format(sz_buff[sz_len], charsmax(sz_buff) - sz_len, "%s %d", sz_color, PlayerUpgrades[player][i])
				}
				g_Credits[player] = 0

				ColorChat(0, RED, "^4[SJ] ^1- %s skills are set:%s ^1(ADMIN: %s)", sz_name, sz_buff, sz_aname)
				ChangeGK(player)
			} else {
				ColorChat(id, RED, "^4[SJ] ^1- ^3%L", id, "SJ_INVPLAYER")
			}
		}
	} else if(equal(sz_cmd, "/rank") || equal(sz_cmd, ".rank")){
		if(sql_error[0] == EOS && sql_tuple){
			new player = cmd_target(id, info, 8)
			if(equal(info, "")) {
				//sql_rank(id, id, 0)
			} else if(1 <= player <= MAX_PLAYERS) {
				//sql_rank(id, player, 0)
			} else {
				ColorChat(id, RED, "^4[SJ] ^1- ^3%L", id, "SJ_INVPLAYER")
			}
		} else {
			ColorChat(id, RED, "^4[SJ] ^1- ^3%L", id, "SJ_SQLNOTAV")
		}
	} else if(equal(sz_cmd, "/rankstats") || equal(sz_cmd, ".rankstats")) {
		if(sql_error[0] == EOS && sql_tuple){
			new player = cmd_target(id, info, 8)
			if(equal(info, "")){
				//sql_rank(id, id, 1)
			} else if(1 <= player <= MAX_PLAYERS) {
				//sql_rank(id, player, 1)
			} else {
				ColorChat(id, RED, "^4[SJ] ^1- ^3%L", id, "SJ_INVPLAYER")
			}
		} else {
			ColorChat(id, RED, "^4[SJ] ^1- ^3%L", id, "SJ_SQLNOTAV")
		}
	} else if(equal(sz_cmd, "/helpmenu") || equal(sz_cmd, ".helpmenu")){
		PlayerHelpMenu(id)
	} else if(GAME_TYPE == TYPE_PUBLIC && (equal(sz_cmd, "/$") || equal(sz_cmd, ".$") || equal(sz_cmd, "$"))){
		new sz_cvar = get_pcvar_num(cv_donate)
		if(sz_cvar == 0){
			ColorChat(id, GREEN, "[SJ] ^1- ^3%L", id, "SJ_DONDIS")
			return PLUGIN_CONTINUE
		}

		new sz_exp[16], sz_buff[16], sz_name[32]
		
		parse(said, sz_buff, 15, sz_name, 31, sz_exp, 15)
		
		if(strlen(said) < strlen(sz_cmd) + 2 || sz_exp[0] == EOS){
			ColorChat(id, GREEN, "[SJ] ^1- %L", id, "SJ_DONUSAGE")
			return PLUGIN_CONTINUE
		}
		
		new x = str_to_num(sz_exp)
		if(x < 1){
			ColorChat(id, GREEN, "[SJ] ^1- %L", id, "SJ_DONINVAM")
			return PLUGIN_CONTINUE
		}
		if(equal(info, "*")){
			GiveXP(id, 0, x)
		} else {
			new player = cmd_target(id, info, 2 | 8)
			if(player){
				GiveXP(id, player, x)
			} else {
				ColorChat(id, RED, "^4[SJ] ^1- ^3%L", id, "SJ_INVPLAYER")
			}
		}
	}
	
	new sz_len = strlen(said)
	if(!sz_len)
		return PLUGIN_HANDLED_MAIN
	new sz_empty
	for(x = 0; x < sz_len; x++){
		if(said[x] != ' ' && said[x] != '%')
			sz_empty = 1
		if(said[x] == '%')
			said[x] = ' '
	}
			
	if(x == sz_len && !sz_empty)
		return PLUGIN_HANDLED_MAIN
	
	for(new i = 1; i <= g_maxplayers; i++){
		if(~IsUserConnected(i) || IsUserBot(i) || get_user_team(i) != sz_team)
			continue		
		
		get_user_name(id, sz_name, 31)
		
		if(sz_team == T) {
			ColorChat(i, RED, "^1(Terrorist) ^3%s ^1: %s", sz_name, said)
		} else if(sz_team == CT) {
			ColorChat(i, BLUE, "^1(Counter-Terrorist) ^3%s ^1: %s", sz_name, said)
		} else {
			ColorChat(i, GREY, "^1(Spectator) ^3%s ^1: %s", sz_name, said)	
		}
	}
	
	return PLUGIN_HANDLED_MAIN
}
public ResetSkills(id){
	for(new x = 1; x <= UPGRADES; x++)
		PlayerUpgrades[id][x] = 0
		
	g_Credits[id] = STARTING_CREDITS
			
	if(GAME_MODE == MODE_HALFTIME){
		new Float:sz_points
		sz_points = float(g_Experience[id])
		sz_points /= 100.0
		sz_points /= get_pcvar_float(cv_pointmult)
	
		if(sz_points){	
			g_Credits[id] += floatround(sz_points)
					
			if(sz_points < floatround(sz_points))
				g_Credits[id]--
				
			if(g_Credits[id] > g_maxcredits)
				g_Credits[id] = g_maxcredits
		}
	}
	
	if(g_GK[T] == id){
		g_GK[T] = 0
		Remove_Hat(id)
	}
	if(g_GK[CT] == id){
		g_GK[CT] = 0
		Remove_Hat(id)
	}
}

stock GiveXP(id, player, xp){
	new sz_aname[32], sz_bname[32]
	get_user_name(id, sz_aname, 31)
	get_user_name(player, sz_bname, 31)
	new sz_cvar = get_pcvar_num(cv_donate)		
	if(sz_cvar == 1 || (sz_cvar == 2 && !is_user_admin(id))){
		if(id == player){
			ColorChat(id, GREEN, "[SJ] ^1- %L", id, "SJ_DONOWN")
			return
		} else if(g_Experience[id] >= xp) {
			g_Experience[player] += xp
			g_Experience[id] -= xp
			ColorChat(id, GREEN, "[SJ] ^1- %s %L %s", 
			sz_aname, id, "SJ_DONDONE", xp, sz_bname)
		} else {
			ColorChat(id, GREEN, "[SJ] ^1- %L", xp, id, "SJ_DONCANT")
			return
		}
	} else { 	
		if(player > 0){
			g_Experience[player] += xp
			if(g_Experience[player] > 99999){
				g_Experience[player] = 99999
			}
			cs_set_user_money(id, g_Experience[player])
		} else {
			format(sz_bname, charsmax(sz_bname), "ALL")
		}
		for(new i = 1; i <= g_maxplayers; i++){
			if(IsUserConnected(i)){
				if(!player){
					g_Experience[i] += xp
					if(g_Experience[i] > 99999){
						g_Experience[i] = 99999
					}
					cs_set_user_money(id, g_Experience[i])
				}
					
				ColorChat(i, GREEN, "[SJ] ^1- %s %L %s", 
				sz_aname, i, "SJ_DONGIVEN", xp, sz_bname) 	
			}
		}
	}
	return
}

public CameraChanger(id){
	if(g_cam[id]){
		set_view(id, CAMERA_NONE)
		g_cam[id] = false
	} else {
		set_view(id, CAMERA_3RDPERSON)
		g_cam[id] = true
	}
}

/*
+-----------------------+--------------------------------------------------------------------------+
|			| ************************************************************************ |
|      [UPGRADES]	| ************************************************************************ |
|			| ************************************************************************ |
+-----------------------+--------------------------------------------------------------------------+
*/
public BuyUpgrade(id){
	
	if(GAME_TYPE == TYPE_TOURNAMENT){
		TNT_BuyUpgrade(id)	
		return PLUGIN_HANDLED
	}
	
	if(!(T <= get_user_team(id) <= CT)){
		ShowUpgrade(id, id)
		return PLUGIN_HANDLED
	}
	new sz_temp[64], num[2], mTitle[101], x, sz_lang[32]
	format(mTitle, charsmax(mTitle), "\y%L:", id, "SJ_SKILLS")
	menu_upgrade[id] = menu_create(mTitle, "Upgrade_Handler")
	for(x = 1; x <= UPGRADES; x++){
		format(sz_lang, charsmax(sz_lang), "SJ_%s", UpgradeTitles[x])
		if(PlayerUpgrades[id][x] == UpgradeMax[x]){
			format(sz_temp, charsmax(sz_temp), "\r%L \y-- \r%d / %d%s", 
			id, sz_lang, UpgradeMax[x], UpgradeMax[x] , (x==UPGRADES)?("^n"):(""))
		}
		else if(g_Experience[id] >=  UpgradePrice[x][PlayerUpgrades[id][x]]){
			if(PlayerUpgrades[id][x] == 0){
				format(sz_temp, charsmax(sz_temp), "\d%L \y-- \d%d / %d \y($%d)%s", 
				id, sz_lang, PlayerUpgrades[id][x], UpgradeMax[x], 
				UpgradePrice[x][PlayerUpgrades[id][x]], (x==UPGRADES)?("^n"):(""))
			}
			else{
				format(sz_temp, charsmax(sz_temp), "\w%L \y-- \w%d / %d \y($%d)%s", 
				id, sz_lang, PlayerUpgrades[id][x], UpgradeMax[x], 
				UpgradePrice[x][PlayerUpgrades[id][x]], (x==UPGRADES)?("^n"):(""))
			}
		}
		else{
			if(PlayerUpgrades[id][x] == 0){
				format(sz_temp, charsmax(sz_temp), "\d%L \y-- \d%d / %d \d($%d)%s", 
				id, sz_lang, PlayerUpgrades[id][x], UpgradeMax[x], 
				UpgradePrice[x][PlayerUpgrades[id][x]], (x==UPGRADES)?("^n"):(""))
			}
			else{
				format(sz_temp, charsmax(sz_temp), "\w%L \y-- \w%d / %d \d($%d)%s", 
				id, sz_lang, PlayerUpgrades[id][x], UpgradeMax[x], 
				UpgradePrice[x][PlayerUpgrades[id][x]], (x==UPGRADES)?("^n"):(""))
			}
		}		
		
		format(num, 1, "%i", x)
		menu_additem(menu_upgrade[id], sz_temp, num)
	}

	menu_addblank(menu_upgrade[id], (UPGRADES+1))
	menu_setprop(menu_upgrade[id], MPROP_EXIT, MEXIT_NEVER)
	menu_display(id, menu_upgrade[id], 0)
	
	return PLUGIN_HANDLED
}

public Upgrade_Handler(id, menu, item){

	if(item == MENU_EXIT || !(T <= get_user_team(id) <= CT)){
		menu_destroy(menu)
		return PLUGIN_HANDLED
	}
	
	item++
	
	if(PlayerUpgrades[id][item] != UpgradeMax[item]){
		if(g_Experience[id] < UpgradePrice[item][PlayerUpgrades[id][item]]){
			return PLUGIN_HANDLED
		} else {
			PlayerUpgrades[id][item]++
			if(PlayerUpgrades[id][item] == UpgradeMax[item])	
				play_wav(id, snd_levelup)
				
			g_Experience[id] -= UpgradePrice[item][PlayerUpgrades[id][item]]
			cs_set_user_money(id, g_Experience[id])
			
			switch(item){
				case STA: {
					set_pev(id, pev_max_health, float(BASE_HP + 
					PlayerUpgrades[id][item] * AMOUNT_STA))
				}
				case AGI: {
					if(!g_sprint[id]){
						set_speedchange(id)
					}
				}
			}
		}

		BuyUpgrade(id)
	}
	
	return PLUGIN_HANDLED
}

public ShowUpgrade(id, player){
	new sz_temp[32], sz_level[64], sz_name[32]
	get_user_name(player, sz_name, 31)
	format(sz_temp, charsmax(sz_temp), "%L:^n\w%s", id, "SJ_SKILLS", sz_name)
		
	menu_upgrade[id] = menu_create(sz_temp, "Done_Handler")
	new x, sz_color[2], num[1], sz_lang[32]
	for(x = 1; x <= UPGRADES; x++){
		format(sz_lang, charsmax(sz_lang), "SJ_%s", UpgradeTitles[x])
		if(PlayerUpgrades[player][x]){
			format(sz_color, 2, "\w")
			if(PlayerUpgrades[player][x] == UpgradeMax[x])
				format(sz_color, 2, "\r")
		} else {
			format(sz_color, 2, "\d")
		}
		if(x < UPGRADES){
			format(sz_level, charsmax(sz_level), "%s%L \y-- %s%i", 
			sz_color, id, sz_lang, sz_color, PlayerUpgrades[player][x])
		} else {
			format(sz_level, charsmax(sz_level), "%s%L \y-- %s%i^n ", 
			sz_color, id, sz_lang, sz_color, PlayerUpgrades[player][x])
		}
		format(num, 1, "%i", x)
		menu_additem(menu_upgrade[id], sz_level, num, 0)
	}
	
		
	menu_setprop(menu_upgrade[id], MPROP_EXIT, MEXIT_NEVER)
	menu_display(id, menu_upgrade[id], 0)
	menu_upgrade[id] =  player
	
	return PLUGIN_CONTINUE
}

public TNT_BuyUpgrade(id) {
	new sz_temp[64], num[2], mTitle[101]
	if(!g_Credits[id] || (GAME_MODE != MODE_PREGAME && GAME_MODE != MODE_HALFTIME) || !(T <= get_user_team(id) <= CT)){
		TNT_ShowUpgrade(id, id)
		return PLUGIN_HANDLED
	}
	
	format(mTitle, 100, "\yPlayer Skills:^nCredits: %d", g_Credits[id])
	new x, sz_lang[32], sz_skillInfo[32]
	menu_upgrade[id] = menu_create(mTitle, "TNT_Upgrade_Handler")
	for(x = 1; x <= UPGRADES; x++){
		switch(x){
			case STA:{
				format(sz_skillInfo, charsmax(sz_skillInfo), "%d HP", 
				BASE_HP + (PlayerUpgrades[id][x] * AMOUNT_STA))
			}
			case STR:{
				format(sz_skillInfo, charsmax(sz_skillInfo), "%d u/sec, +%d%% smack", 
				get_pcvar_num(cv_kick) + (PlayerUpgrades[id][x] * AMOUNT_STR), (PlayerUpgrades[id][x] * AMOUNT_STR) / 10)
			}
			case AGI:{
				format(sz_skillInfo, charsmax(sz_skillInfo), "%d u/sec", 
				floatround(BASE_SPEED) + (PlayerUpgrades[id][x] * AMOUNT_AGI))
			}
			case DEX:{
				new szSmack = (PlayerUpgrades[id][x]<UpgradeMax[x])?(PlayerUpgrades[id][x] * AMOUNT_DEX + 1):(100)
				new szTemp[10], szCvarTemp[10]
				num_to_str(szSmack, szTemp, charsmax(szTemp))
				num_to_str(get_pcvar_num(cv_smack), szCvarTemp, charsmax(szCvarTemp))
				new Float:szCatch = str_to_float(szTemp) / (str_to_float(szCvarTemp) / 100.0)
				format(sz_skillInfo, charsmax(sz_skillInfo), "%0.f%% catch", szCatch>100.0?100.0:szCatch)
			}
			case DIS:{
				format(sz_skillInfo, charsmax(sz_skillInfo), "%d%%", 
				(PlayerUpgrades[id][x])?(BASE_DISARM + PlayerUpgrades[id][x] * AMOUNT_DIS):(0))
			}
		}
		format(sz_lang, charsmax(sz_lang), "SJ_%s", UpgradeTitles[x])
		if((PlayerUpgrades[id][x] + 1) > UpgradeMax[x])
			format(sz_temp, 63, "\r%L \y-- \r%d / %d \d[%s]%s", id, sz_lang, UpgradeMax[x], UpgradeMax[x], sz_skillInfo, (x==UPGRADES)?("^n"):(""))
		else if((PlayerUpgrades[id][x] + 1) == UpgradeMax[x] && g_Credits[id] < 2)
			format(sz_temp, 63, "\d%L \y-- \d%d / %d \d[%s]%s", id, sz_lang, PlayerUpgrades[id][x], UpgradeMax[x], sz_skillInfo, (x==UPGRADES)?("^n"):(""))
		else
			format(sz_temp, 63, "\w%L \y-- \w%d / %d \d[%s]%s", id, sz_lang, PlayerUpgrades[id][x], UpgradeMax[x], sz_skillInfo, (x==UPGRADES)?("^n"):(""))
		
		format(num, 1,"%i",x)
		menu_additem(menu_upgrade[id], sz_temp, num, 0)
	}
	format(num, 1,"%i",x)
	//if(get_user_used_credits(id) <= STARTING_CREDITS)
	menu_additem(menu_upgrade[id], "\yUse default skills", num, 0)
	//else
		//menu_additem(menu_upgrade[id], "\dUse default skills", num, 0)
	menu_addblank(menu_upgrade[id], (UPGRADES+1))
	menu_setprop(menu_upgrade[id], MPROP_EXIT, MEXIT_NEVER)
	menu_display(id, menu_upgrade[id], 0)
	
	return PLUGIN_HANDLED
}

public TNT_Upgrade_Handler(id, menu, item) {

	if(item == MENU_EXIT || !(T <= get_user_team(id) <= CT)){
		menu_destroy(menu)
		return PLUGIN_HANDLED
	}
	
	new cmd[6], iName[64]
	new access, callback;
	menu_item_getinfo(menu, item, access, cmd,5, iName, 63, callback) 

	if(!g_Credits[id]) {
		if(!g_Ready[id])
			ColorChat(id, GREEN, "^1Type ^4.ready ^1or ^4.reset^1!")
		return PLUGIN_HANDLED
	}
	if(item == UPGRADES){
		//if(get_user_used_credits(id) < STARTING_CREDITS)
			//load_skills(id, 0)
		loadDefaultSkills(id)
		TNT_BuyUpgrade(id)
		return PLUGIN_HANDLED
	}
	
	new upgrade = str_to_num(cmd)
	new playerupgrade = PlayerUpgrades[id][upgrade]
	new maxupgrade = UpgradeMax[upgrade]
	
	if(playerupgrade != maxupgrade) {
		if(PlayerUpgrades[id][upgrade] == maxupgrade-1 && g_Credits[id] < 2) {
			ColorChat(id, RED, "Not enough credits to upgrade %s level %i", UpgradeTitles[upgrade], maxupgrade)	
		}
		else {
			playerupgrade++
				
			g_Credits[id]--
			
			if(playerupgrade == maxupgrade){
				g_Credits[id]--
				play_wav(id, snd_levelup)
			}
			switch(upgrade) {
				case STA: {
					new stam = playerupgrade * AMOUNT_STA
					entity_set_float(id, EV_FL_health, float(BASE_HP + stam))
				}
				case AGI: {
					if(!g_sprint[id]) {
						set_speedchange(id)
					}
				}
			}
		}
		PlayerUpgrades[id][upgrade] = playerupgrade
	}
	
	if(!g_Credits[id]){
		if(!g_Ready[id])
			ColorChat(id, GREEN, "^1Type ^4.ready ^1or ^4.reset^1!")
		new sz_team = get_user_team(id)
		
		if(PlayerUpgrades[id][DEX] == UpgradeMax[DEX]){
			if(!g_GK[sz_team] && (T <= sz_team <= CT)){
				new sz_name[32]
				get_user_name(id, sz_name, charsmax(sz_name))
				g_GK[sz_team] = id
				client_print(id, print_center, "You are %s goalkeeper!", TeamNames[sz_team])
				ColorChat(0, (sz_team == T)?RED:BLUE, "^3%s ^1is ^4GOALKEEPER", sz_name)
				Set_Hat(id)
			}
		}
	}
	TNT_BuyUpgrade(id)
	
	return PLUGIN_HANDLED
}

public TNT_ShowUpgrade(id, player){
	if(g_regtype == 2){
		if(!equal(g_userClanName[id], g_userClanName[player])){
			ColorChat(id, RED, "[SJ] ^1- ^3This player is not member of your clan!")
			return PLUGIN_HANDLED
		}
	}
	new sz_temp[32], sz_level[64], sz_name[32], sz_skillInfo[32]
	get_user_name(player, sz_name, 31)
	format(sz_temp, 31,"Player Skills:^n\w%s", sz_name)
		
	menu_upgrade[id] = menu_create(sz_temp, "TNT_ShowUpgrade_Handler")
	new x, sz_color[3], num[2], sz_lang[32]
	for(x = 1; x <= UPGRADES; x++){
		switch(x){
			case STA:{
				format(sz_skillInfo, charsmax(sz_skillInfo), "%d HP", BASE_HP + (PlayerUpgrades[player][x] * AMOUNT_STA))
			}
			case STR:{
				format(sz_skillInfo, charsmax(sz_skillInfo), "%d u/sec, +%d%% smack", get_pcvar_num(cv_kick) + (PlayerUpgrades[id][x] * AMOUNT_STR), (PlayerUpgrades[player][x] * AMOUNT_STR) / 10)
			}
			case AGI:{
				format(sz_skillInfo, charsmax(sz_skillInfo), "%d u/sec", floatround(BASE_SPEED) + (PlayerUpgrades[player][x] * AMOUNT_AGI))
			}
			case DEX:{
				new szSmack = (PlayerUpgrades[id][x]<UpgradeMax[x])?(PlayerUpgrades[id][x] * AMOUNT_DEX + 1):(100)
				new szTemp[10], szCvarTemp[10]
				num_to_str(szSmack, szTemp, charsmax(szTemp))
				num_to_str(get_pcvar_num(cv_smack), szCvarTemp, charsmax(szCvarTemp))
				new Float:szCatch = str_to_float(szTemp) / (str_to_float(szCvarTemp) / 100.0)
				format(sz_skillInfo, charsmax(sz_skillInfo), "%0.f%% catch", szCatch>100.0?100.0:szCatch)
			}
			case DIS:{
				format(sz_skillInfo, charsmax(sz_skillInfo), "%d%%", (PlayerUpgrades[player][x])?(BASE_DISARM + PlayerUpgrades[player][x] * AMOUNT_DIS):(0))
			}
		}
		format(sz_lang, charsmax(sz_lang), "SJ_%s", UpgradeTitles[x])
		if(PlayerUpgrades[player][x]){
			format(sz_color, 2, "\w")
			if(PlayerUpgrades[player][x] == UpgradeMax[x])
				format(sz_color, 2, "\r")
		}
		else
			format(sz_color, 2, "\d")
		if(x < UPGRADES)
			format(sz_level,63,"%s%L \y-- %s%i \d[%s]", sz_color, id, sz_lang, sz_color, PlayerUpgrades[player][x], sz_skillInfo)
		else
			format(sz_level,63,"%s%L \y-- %s%i \d[%s]^n ", sz_color, id, sz_lang, sz_color, PlayerUpgrades[player][x], sz_skillInfo)
		format(num, 1,"%i",x)
		menu_additem(menu_upgrade[id], sz_level, num, 0)
	}
	
		
	if((T <= get_user_team(id) <= CT) && player == id){
		switch(GAME_MODE){
			case MODE_PREGAME:{ 	
				g_Ready[id]?menu_additem(menu_upgrade[id], "\rWait"):menu_additem(menu_upgrade[id], "\yReady")
				menu_additem(menu_upgrade[id], "\ySet as default")
			}
			case MODE_HALFTIME:{
				g_Ready[id]?menu_additem(menu_upgrade[id], "\rWait"):menu_additem(menu_upgrade[id], "\yReady")
				//if(get_user_used_credits(id) <= STARTING_CREDITS)
				//menu_additem(menu_upgrade[id], "\yUse default skills")
				//else
					//menu_additem(menu_upgrade[id], "\dUse default skills")

			}
			default:{
				menu_additem(menu_upgrade[id], "\yTop stats")
			}
		}
	}
	else{
		menu_additem(menu_upgrade[id], "\yTop stats")
		menu_additem(menu_upgrade[id], "\yPlayer stats")
	}
		
	menu_setprop(menu_upgrade[id], MPROP_EXIT, MEXIT_NEVER)
	menu_display(id, menu_upgrade[id], 0)
	menu_upgrade[id] =  player
	
	return PLUGIN_CONTINUE
}

public TNT_ShowUpgrade_Handler(id, menu, item){
	if(item == UPGRADES){
		if((T <= get_user_team(id) <= CT) && menu_upgrade[id] == id){
			switch(GAME_MODE){
				case MODE_PREGAME:{ 	
					(g_Ready[id])?(g_Ready[id]=false):(g_Ready[id]=true)
					TNT_ShowUpgrade(id, id)
				}
				case MODE_HALFTIME:{
					(g_Ready[id])?(g_Ready[id]=false):(g_Ready[id]=true)
					TNT_ShowUpgrade(id, id)
				}
				default:{
					ShowMenuStats(id)
				}
			}
		}
		else{
			ShowMenuStats(id)
		}
	}
	else if(item == UPGRADES + 1){
		if((T <= get_user_team(id) <= CT) && menu_upgrade[id] == id){
			switch(GAME_MODE){
				case MODE_PREGAME:{ 	
					saveDefaultSkills(id)
					TNT_ShowUpgrade(id, id)
				}
				case MODE_HALFTIME:{
					loadDefaultSkills(id)
					TNT_ShowUpgrade(id, id)
				}
				default:{}
			}
		}
		else{
			TNT_ShowMenuPlayerStats(id, menu_upgrade[id])
		}
	}
	return PLUGIN_HANDLED
}

stock get_user_used_credits(id){
	new k = 0
	for(new i = 1; i <= UPGRADES; i++){
		k += PlayerUpgrades[id][i]
		if(PlayerUpgrades[id][i] == UpgradeMax[i])
			k++
	}
	return k
}

public Done_Handler(id, menu, item){
	return PLUGIN_HANDLED
}

/*
+-----------------------+--------------------------------------------------------------------------+
|			| ************************************************************************ |
|        [TURBO]	| ************************************************************************ |
|			| ************************************************************************ |
+-----------------------+--------------------------------------------------------------------------+
*/
public Meter(){
	new id
	new sprintText[256], sec
	new sz_len, x
	new szTitle[32]
	new ndir = -(DIRECTIONS)
	new i
	for(id = 1; id <= g_maxplayers; id++){
		sec = seconds[id]
		if(~IsUserAlive(id))
			continue
		for(i = 0; i <= g_count_balls; i++)
			if(id == g_ballholder[i])
				break
				
		if(i != g_count_balls + 1){
			set_hudmessage(0, 255, 0, -1.0, 0.75, 0, 0.0, 0.6, 0.0, 0.0, 4)
			sz_len = format(sprintText, charsmax(sprintText), "  %L ^n[", id, "SJ_CURVE")

			for(x = DIRECTIONS; x >= ndir; x--){
				(x==0)?
				(sz_len += format(sprintText[sz_len], charsmax(sprintText) - sz_len, "%s%s",
				direction[i]==x?"0":"+", x==ndir?"]":"  ")):
				(sz_len += format(sprintText[sz_len], charsmax(sprintText) - sz_len, "%s%s",
				direction[i]==x?"0":"=", x==ndir?"]":"  "))
			}
	
			show_hudmessage(id, "%s", sprintText)
		}		
			
		set_hudmessage(0, 255, 0, -1.0, 0.85, 0, 0.0, 0.6, 0.0, 0.0, 3)
		
		format(szTitle, charsmax(szTitle), "- SPEED: %d -", get_speed(id))
	
		if(sec > 30){
			sec -= get_pcvar_num(cv_turbo)
			format(sprintText, charsmax(sprintText), "  %s ^n[==============]", szTitle)
			set_speedchange(id)
			g_sprint[id] = 0
		} else if(sec >= 0 && sec < 30 && g_sprint[id]) {
			sec += 2
			set_speedchange(id, 100.0) 
		}
			
		switch(sec){
			case 0:		format(sprintText, charsmax(sprintText), "  %s ^n[||||||||||||||]", szTitle)
			case 2:		format(sprintText, charsmax(sprintText), "  %s ^n[|||||||||||||=]", szTitle)
			case 4:		format(sprintText, charsmax(sprintText), "  %s ^n[||||||||||||==]", szTitle)
			case 6:		format(sprintText, charsmax(sprintText), "  %s ^n[|||||||||||===]", szTitle)
			case 8:		format(sprintText, charsmax(sprintText), "  %s ^n[||||||||||====]", szTitle)
			case 10:	format(sprintText, charsmax(sprintText), "  %s ^n[|||||||||=====]", szTitle)
			case 12:	format(sprintText, charsmax(sprintText), "  %s ^n[||||||||======]", szTitle)
			case 14:	format(sprintText, charsmax(sprintText), "  %s ^n[|||||||=======]", szTitle)
			case 16:	format(sprintText, charsmax(sprintText), "  %s ^n[||||||========]", szTitle)
			case 18:	format(sprintText, charsmax(sprintText), "  %s ^n[|||||=========]", szTitle)
			case 20:	format(sprintText, charsmax(sprintText), "  %s ^n[||||==========]", szTitle)
			case 22:	format(sprintText, charsmax(sprintText), "  %s ^n[|||===========]", szTitle)
			case 24:	format(sprintText, charsmax(sprintText), "  %s ^n[||============]", szTitle)
			case 26:	format(sprintText, charsmax(sprintText), "  %s ^n[|=============]", szTitle)
			case 28:	format(sprintText, charsmax(sprintText), "  %s ^n[==============]", szTitle)
			case 30: { 	
				format(sprintText, charsmax(sprintText), "  %s ^n[==============]", szTitle)
				sec = 92
			}
			case 32: sec = 0
		}
		
		seconds[id] = sec
		show_hudmessage(id, "%s", sprintText)
	}
}

set_speedchange(id, Float:speed = 0.0){
	new i
	for(i = 0; i <= g_count_balls; i++)
		if(id == g_ballholder[i])
			break
			
	new Float:agi = float((PlayerUpgrades[id][AGI] * AMOUNT_AGI) + 
	((i <= g_count_balls)?(AMOUNT_POWERPLAY * PowerPlay[i] * 2):0))
	agi += (BASE_SPEED + speed)
	entity_set_float(id, EV_FL_maxspeed, agi)
}

/*
+-----------------------+--------------------------------------------------------------------------+
|			| ************************************************************************ |
|      [ENVIROMENT]	| ************************************************************************ |
|			| ************************************************************************ |
+-----------------------+--------------------------------------------------------------------------+
*/
public CreateGoalNets(){
	new endzone
	new Float:MinBox[3], Float:MaxBox[3]
	for(new x = 1; x < 3; x++){
		endzone = create_entity("info_target")
		if(endzone){
			MinBox[0] = -25.0;	MinBox[1] = -145.0;	MinBox[2] = -36.0
			MaxBox[0] =  25.0;	MaxBox[1] =  145.0;	MaxBox[2] =  70.0
			entity_set_string(endzone, EV_SZ_classname, "soccerjam_goalnet")
			entity_set_model(endzone, "models/chick.mdl")
			entity_set_int(endzone, EV_INT_solid, SOLID_BBOX)
			entity_set_int(endzone, EV_INT_movetype, MOVETYPE_NONE)
	
			entity_set_vector(endzone, EV_VEC_mins, MinBox)
			entity_set_vector(endzone, EV_VEC_maxs, MaxBox)
			
			(x==1)?	(entity_set_origin(endzone, Float:{ 2116.0, 0.0, 1604.0 })):
				(entity_set_origin(endzone, Float:{-2566.0, 0.0, 1604.0 }))
			
			entity_set_int(endzone, EV_INT_team, x)
			set_entity_visibility(endzone, 0)
			GoalEnt[x] = endzone
		}
	}
}

stock CreateWall(){
	new wall = create_entity("func_wall")
	if(wall){
		new Float:MinBox[3], Float:MaxBox[3]
		MinBox[0] = -72.0;	MinBox[1] = -100.0;	MinBox[2] = -72.0
		MaxBox[0] =  72.0;	MaxBox[1] =  100.0;	MaxBox[2] =  72.0
		
		entity_set_string(wall, EV_SZ_classname, "func_blocker")
		entity_set_model(wall, "models/chick.mdl")
		
		entity_set_int(wall, EV_INT_solid, SOLID_BBOX)
		entity_set_int(wall, EV_INT_movetype, MOVETYPE_NONE)
			
		entity_set_vector(wall, EV_VEC_mins, MinBox)
		entity_set_vector(wall, EV_VEC_maxs, MaxBox)
			
		entity_set_origin(wall, Float:{2355.0, 1696.0, 1604.0})
		set_entity_visibility(wall, 0)
	}
}

stock CreateMascot(team){
	new mascot = create_entity("info_target")
	if(mascot){
		entity_set_string(mascot, EV_SZ_classname,"Mascot")
		entity_set_model(mascot, mdl_mascots[team])
		Mascots[team] = mascot
		
		entity_set_int(mascot, EV_INT_solid, SOLID_NOT)
		entity_set_int(mascot, EV_INT_movetype, MOVETYPE_NONE)
		entity_set_int(mascot, EV_INT_team, team)

		entity_set_vector(mascot, EV_VEC_mins, Float:{ -16.0, -16.0, -72.0 })
		entity_set_vector(mascot, EV_VEC_maxs, Float:{ 16.0, 16.0, 72.0 })
		
		entity_set_origin(mascot, MascotsOrigins)
		entity_set_float(mascot, EV_FL_animtime,2.0)
		entity_set_float(mascot, EV_FL_framerate,1.0)
		entity_set_int(mascot, EV_INT_sequence,0)
		
		if(team == 2)
			entity_set_byte(mascot, EV_BYTE_controller1, 115)
		
		entity_set_vector(mascot, EV_VEC_angles, MascotsAngles)
		entity_set_float(mascot, EV_FL_nextthink, halflife_time() + 1.0)
	}
}

public think_Alien(mascot){
	//if(GAME_MODE == MODE_NONE){
		
	
		//set_pev(mascot, pev_nextthink, halflife_time() + get_pcvar_float(cv_alienthink))
		//return PLUGIN_HANDLED
	//}
	if((!g_count_balls && (GAME_MODE == MODE_PREGAME || GAME_MODE == MODE_HALFTIME)) || get_pcvar_num(cv_pause)){
		set_pev(mascot, pev_nextthink, halflife_time() + get_pcvar_float(cv_alienthink))
		return PLUGIN_HANDLED
	}

	new team = pev(mascot, pev_team)
	new distance = get_pcvar_num(cv_alienzone)		
	new indist[32], inNum, i
	new bool:sz_nogk
	if(get_pcvar_num(cv_lamedist) > 0)
		sz_nogk = true
	new id, sz_dist, sz_team, Float:sz_gametime = get_gametime()
	for(id = 1; id <= g_maxplayers; id++){
		if(IsUserAlive(id)){
			sz_team = get_user_team(id)
			sz_dist = get_entity_distance(id, mascot)
					
			if(sz_dist < distance){
				if(sz_team != team ){
					for(i = 0; i <= g_count_balls; i++){
						if(id == g_ballholder[i]){
							TerminatePlayer(id, mascot, team, float(pev(id, pev_health)) + 1.0, TeamColors[team])
							process_death(mascot, id)
							set_pev(mascot, pev_nextthink, halflife_time() + get_pcvar_float(cv_alienthink))
								
							return PLUGIN_HANDLED
						}
					}
					indist[inNum++] = id
				} else if(sz_nogk) {
					g_nogk[team] = false
					sz_nogk = false
				}
			}
			if(sz_team == team){
				if(GAME_TYPE == TYPE_TOURNAMENT && (sz_gametime - GoalyCheckDelay[id] >= MAX_GOALY_DELAY)){
					goaly_checker(id, sz_dist, sz_gametime) 
				}
				if(GAME_MODE == MODE_SHOOTOUT && sz_team != ShootOut && id == candidates[sz_team]){
					if(sz_dist >= MAX_ENEMY_SHOOTOUT_DIST){
						spawn(id)
						entity_set_float(id, EV_FL_takedamage, 0.0)
					}
				}
			}
		}
	}
	g_nogk[team] = sz_nogk
	new rnd = random_num(0, (inNum - 1))
	new chosen = indist[rnd]
	if(chosen){
		new Float:sz_min = get_pcvar_float(cv_alienmin), Float:sz_max = get_pcvar_float(cv_alienmax)
		if(sz_min < 0 || sz_max < 0){
			sz_max = 12.0
			sz_min = 8.0
		}
		set_task(0.5, "Done_Handler", -5311 + chosen)
		TerminatePlayer(chosen, mascot, team, random_float(sz_min, sz_max), TeamColors[team]) 
	}

	set_pev(mascot, pev_nextthink, halflife_time() + get_pcvar_float(cv_alienthink))
	return PLUGIN_HANDLED
}

// Goaly Points System				
goaly_checker(id, dist, Float:gametime){
	if(dist < MAX_GOALY_DISTANCE){
		if(GoalyCheck[id] > 1 && GAME_MODE == MODE_GAME || GAME_MODE == MODE_OVERTIME){
			g_Experience[id] += POINTS_GOALY_CAMP
			GoalyPoints[id] += GOALY_POINTS_CAMP
			cs_set_user_money(id, g_Experience[id])
			
			new hp = get_user_health(id)
			new diff = BASE_HP - hp		
			if(hp <= BASE_HP) {
				if(diff < HEALTH_REGEN_AMOUNT) {
					set_user_health( id, hp + (BASE_HP - hp))
				} else {
					set_user_health(id, hp + HEALTH_REGEN_AMOUNT)
				}
			}
		} else {
			GoalyCheck[id]++
		}
		GoalyCheckDelay[id] = gametime
	} else {
		GoalyCheck[id] = 0
	}
}

public pfn_keyvalue(entid){
	if(!RunOnce){
		RunOnce = true
		
		new entity = create_entity("game_player_equip")
		if(entity){
			DispatchKeyValue(entity, "weapon_knife", "1")
			DispatchKeyValue(entity, "targetname", "roundstart")
			DispatchSpawn(entity)
		}
	}
	new classname[32], key[32], value[32]
	copy_keyvalue(classname, 31, key, 31, value, 31)

	new temp_origins[3][10], x, team
	new temp_angles[3][10]
	
	if(equal(key, "classname") && equal(value, "soccerjam_goalnet"))
		DispatchKeyValue("classname", "func_wall")
		
	if(equal(classname, "game_player_equip")){
		remove_entity(entid)
	} else if(equal(classname, "func_wall")) {
		if(equal(key, "team")){
			team = str_to_num(value)
			if(team == 1 || team == 2){
				GoalEnt[team] = entid
				set_task(1.0, "FinalizeGoalNet", team)
			}
		}	
	} else if(equal(classname, "soccerjam_mascot")) {
		if(equal(key, "team")){
			team = str_to_num(value)
			CreateMascot(team)
		} else if(equal(key, "origin")) {
			parse(value, temp_origins[0], 9, temp_origins[1], 9, temp_origins[2], 9)
			for(x = 0; x < 3; x++)
				MascotsOrigins[x] = floatstr(temp_origins[x])
		} else if(equal(key, "angles")) {
			parse(value, temp_angles[0], 9, temp_angles[1], 9, temp_angles[2], 9)
			for(x = 0; x < 3; x++)
				MascotsAngles[x] = floatstr(temp_angles[x])
		}
	} else if(equal(classname, "soccerjam_teamball")) {
		if(equal(key, "team")){
			team = str_to_num(value)
			for(x = 0; x < 3; x++){
				TeamBallOrigins[team][x] = TEMP_TeamBallOrigins[x]
				TeamPossOrigins[team][x] = TEMP_TeamBallOrigins[x]
			}
			
		} else if(equal(key, "origin")) {
			parse(value, temp_origins[0], 9, temp_origins[1], 9, temp_origins[2], 9)
			for(x = 0; x < 3; x++)
				TEMP_TeamBallOrigins[x] = floatstr(temp_origins[x])	
		}
	} else if(equal(classname, "soccerjam_ballspawn")) {
		if(equal(key, "origin")){
			new szOrigin[3][10]
			parse(value, szOrigin[0], 9, szOrigin[1], 9, szOrigin[2], 9)
			
			BallSpawnOrigin[0] = floatstr(szOrigin[0])
			BallSpawnOrigin[1] = floatstr(szOrigin[1])
			BallSpawnOrigin[2] = floatstr(szOrigin[2]) + 10.0
		}
	}
}

public FinalizeGoalNet(team){
	new goalnet = GoalEnt[team]
	entity_set_string(goalnet, EV_SZ_classname, "soccerjam_goalnet")
	entity_set_int(goalnet, EV_INT_team, team)
	set_entity_visibility(goalnet, 0)
}

/*
+-----------------------+--------------------------------------------------------------------------+
|			| ************************************************************************ |
|      	  [MISC]  	| ************************************************************************ |
|			| ************************************************************************ |
+-----------------------+--------------------------------------------------------------------------+
*/
public PostGame(){
	format(g_TempTeamNames[T], 31, TeamNames[T])
	format(g_TempTeamNames[CT], 31, TeamNames[CT])
	
	if(GAME_TYPE == TYPE_PUBLIC){
		set_pcvar_num(cv_score[0], 10)
		
		for(new id = 1; id <= g_maxplayers; id++){
			//g_PlayerDeaths[id] = 0
			for(new x = 1; x <= UPGRADES; x++)
				PlayerUpgrades[id][x] = 0
		}
		g_current_match = get_systime()
		set_task(30.0, "VoteStart")
	} else {
		GAME_MODE = MODE_PREGAME
		//hltv_disconnect()
		MoveBall(0, 0, -1)
		Remove_Hat(g_GK[T])
		Remove_Hat(g_GK[CT])
		g_GK[T] = 0
		g_GK[CT] = 0
		g_regtype = 0
		g_saveall = 1
		
		new x
		for(new id = 1; id <= g_maxplayers; id++){
			save_stats(id)
			g_Ready[id] = false
			//g_PlayerDeaths[id] = 0
			freeze_player[id] = false
			g_showhud[id] = 1
			g_Credits[id] = STARTING_CREDITS
			g_Experience[id] = 0
			for(x = 1; x <= UPGRADES; x++)
				PlayerUpgrades[id][x] = 0
		}
		g_current_match = 0
		gMatchId = 0
	}
	server_cmd("mp_timelimit 0")
}

public CleanUp(){
	new m, x

	for(x = 1; x <= RECORDS; x++) {
		TopPlayer[0][x] = 0
		TopPlayer[1][x] = 0
		TeamRecord[T][x] = 0
		TeamRecord[CT][x] = 0
		format(TopPlayerName[x], 31, "")
	}
	
	for(x = 1; x <= g_maxplayers; x++) {
		GoalyPoints[x] = 0
		g_Ready[x] = false
		g_Experience[x] = 0
		g_Credits[x] = 0
		freeze_player[x] = false
		//g_PlayerDeaths[x] = 0
		g_MVP_points[x] = 0
		g_PenOrig[x][0] = g_StPen[0]
		g_PenOrig[x][1] = 0.0
		g_PenOrig[x][2] = g_StPen[2]
		for(m = 1; m <= RECORDS; m++)
			MadeRecord[x][m] = 0
	}
	for(x = 0; x < 64; x++){
		format(g_list_authid[x], 35, "")
	}
	
	TrieClear(gTrieStats)
	
	(g_regtype == 0)?(g_saveall = 1):(g_saveall = 0)

	g_Time[0] = 0

	g_penstep[T] = 0.0
	g_penstep[CT] = 0.0
	candidates[T] = 0
	candidates[CT] = 0
	
	for(x = 0; x < MAX_PENSHOOTERS; x++){
		LineUp[x] = 0
		PenGoals[T][x] = 0
		PenGoals[CT][x] = 0
	}
	
	format(g_MVP_name, charsmax(g_MVP_name), "")
	g_MVP = 0	
	g_MVPwebId = 0
	
	g_current_match = get_systime()
	winner = 0
	ROUND = 0
	timer = COUNTDOWN_TIME
	g_Timeleft = (get_pcvar_num(cv_time) * 60)
	set_pcvar_num(cv_score[T], 0)
	set_pcvar_num(cv_score[CT], 0)
	ShootOut = 0
	
	for(x = 0; x <= g_count_balls; x++) {
		PowerPlay[x] = 0
	}
}

// GK Hats
public Remove_Hat(id){
	if(g_hatent[id] > 0) {
		remove_entity(g_hatent[id])
		g_hatent[id] = 0
	}
}

public ChangeGK(id){
	if(GAME_TYPE == TYPE_PUBLIC)
		return PLUGIN_HANDLED
	
	new sz_team = get_user_team(id)
	if(PlayerUpgrades[id][DEX] == UpgradeMax[DEX] && (T <= sz_team <= CT)){
		if(get_user_team(g_GK[sz_team]) != sz_team || ~IsUserConnected(g_GK[sz_team])){
			g_GK[sz_team] = 0
			Remove_Hat(id)
		}
		new op_sz_team, sz_name[32]
		(sz_team == T)?(op_sz_team = CT):(op_sz_team = T)
		if(g_GK[op_sz_team] == id){
			g_GK[op_sz_team] = 0
			Remove_Hat(id)
			for(new i = 1; i <= g_maxplayers; i++){
				if(IsUserConnected(i) && get_user_team(i) == op_sz_team && PlayerUpgrades[i][DEX] == UpgradeMax[DEX]){
					g_GK[op_sz_team] = i
					Set_Hat(i)
					client_print(i, print_center, "You are %s goalkeeper!", TeamNames[sz_team])
					get_user_name(i, sz_name, charsmax(sz_name))
					ColorChat(0, (op_sz_team == T)?RED:BLUE, "^3%s ^1is ^4GOALKEEPER", sz_name)
					break
				}
			}
		}
		if(!g_GK[sz_team] || ~IsUserConnected(g_GK[sz_team]) || PlayerUpgrades[g_GK[sz_team]][DEX] != UpgradeMax[DEX]){
			client_print(id, print_center, "You are %s goalkeeper!", TeamNames[sz_team])
			g_GK[sz_team] = id
			get_user_name(id, sz_name, charsmax(sz_name))
			ColorChat(0, (sz_team == T)?RED:BLUE, "^3%s ^1is ^4GOALKEEPER", sz_name)
			Set_Hat(id)
		}
			
	} else {
		if(g_GK[T] == id)
			g_GK[T] = 0
		if(g_GK[CT] == id)
			g_GK[CT] = 0
				
		Remove_Hat(id)
	}
	return PLUGIN_HANDLED
}

public Set_Hat(id) {
	if(g_hatent[id] < 1) {
		g_hatent[id] = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"))
		if(g_hatent[id] > 0) {
			set_pev(g_hatent[id], pev_movetype, MOVETYPE_FOLLOW)
			set_pev(g_hatent[id], pev_aiment, id)
			set_pev(g_hatent[id], pev_rendermode, kRenderNormal)
			engfunc(EngFunc_SetModel, g_hatent[id], mdl_mask[get_user_team(id)])
		}
	} else {
		engfunc(EngFunc_SetModel, g_hatent[id], mdl_mask[get_user_team(id)])
	}
}

public FWD_GameDescription(){ 
	new sz_temp[32]
	/*if(GAME_TYPE == TYPE_PUBLIC){
		format(sz_temp, charsmax(sz_temp), "%s - %d : %d - %s", 
		TeamNames[T], get_pcvar_num(cv_score[T]), get_pcvar_num(cv_score[CT]), TeamNames[CT])
	}
	else{
		switch(GAME_MODE){
			case MODE_PREGAME:
				format(sz_temp, charsmax(sz_temp), "FULLTIME | %s - %d : %d - %s", 
				g_TempTeamNames[T], get_pcvar_num(cv_score[T]), get_pcvar_num(cv_score[CT]), g_TempTeamNames[CT])
			case MODE_NONE:{
				format(sz_temp, charsmax(sz_temp), "STARTING GAME")
			}
			case MODE_GAME:{
				new sz_time[32]
				new minutes = g_Timeleft / 60
				new seconds = g_Timeleft % 60
				format(sz_time, charsmax(sz_time), "%i:%s%i", minutes, seconds<10?"0":"", seconds)
				if(ROUND == 0)
					format(sz_temp, charsmax(sz_temp), "1st | %s | %s - %d : %d - %s", 
					sz_time, TeamNames[T], get_pcvar_num(cv_score[T]), get_pcvar_num(cv_score[CT]), TeamNames[CT])
				else
					format(sz_temp, charsmax(sz_temp), "2nd | %s | %s - %d : %d - %s", 
					sz_time, TeamNames[T], get_pcvar_num(cv_score[T]), get_pcvar_num(cv_score[CT]), TeamNames[CT])
			}
			case MODE_HALFTIME:
				format(sz_temp, charsmax(sz_temp), "HALFTIME | %s - %d : %d - %s", 
				TeamNames[T], get_pcvar_num(cv_score[T]), get_pcvar_num(cv_score[CT]), TeamNames[CT])
			case MODE_SHOOTOUT:
				format(sz_temp, charsmax(sz_temp), "SHOOTOUT | %s - %d : %d - %s", 
				TeamNames[T], get_pcvar_num(cv_score[T]), get_pcvar_num(cv_score[CT]), TeamNames[CT])
			case MODE_OVERTIME:{
				new sz_time[32]
				new minutes = g_Timeleft / 60
				new seconds = g_Timeleft % 60
				format(sz_time, charsmax(sz_time), "%i:%s%i", minutes, seconds<10?"0":"", seconds)
				format(sz_temp, charsmax(sz_temp), "OT #%d | %s |%s - %d : %d - %s", 
				ROUND - 1, sz_time, TeamNames[T], get_pcvar_num(cv_score[T]), get_pcvar_num(cv_score[CT]), TeamNames[CT])
			}
		}
	}*/
	
	format(sz_temp, charsmax(sz_temp), ".: http://sj-pro.com :.")
	forward_return(FMV_STRING, sz_temp)
	
	
	return FMRES_SUPERCEDE 
}

public FWD_CmdStart( id, uc_handle, seed ) { 
    if(get_uc(uc_handle, UC_Impulse) == 100) { // change 201 to your impulse. 
    	if(g_showhud[id]){
		(g_showhud[id]==1)?(g_showhud[id] = 2):(g_showhud[id] = 1)
	}
    } 
     
    return FMRES_IGNORED; 
}

public FWD_AddToFullpack(es_handle, e, id, host, flags, player){
	if(id && player && IsUserAlive(id) && SideJump[id] == 2){
		/*if(!(pev(id, pev_flags) & FL_ONGROUND) && get_speed(id) > BASE_SPEED){
			set_es(es_handle, ES_Sequence, 8)
			set_es(es_handle, ES_Frame, Float:13.0)
			set_es(es_handle, ES_FrameRate, Float:0.0)
				
			return FMRES_HANDLED
		}*/
		if((get_gametime() - SideJumpDelay[id]) > 0.1){
			SideJump[id] = 0
		}
	}

	return FMRES_IGNORED
}

public client_connect(id){
	set_user_info(id, "_vgui_menus", "0")	
}

public client_putinserver(id){
	ClearUserAlive(id)
	SetUserConnected(id)
	if(is_user_bot(id) || is_user_hltv(id) || !id){
		SetUserBot(id)
		return PLUGIN_HANDLED
	}

	g_cam[id] = false
	seconds[id] = 0
	g_GK_immunity[id] = false
	g_sprint[id] = 0
	PressedAction[id] = 0
	g_showhelp[id] = false
	g_count_balls?(g_showhud[id] = false):(g_showhud[id] = true)
	cs_set_user_money(id, 0)
	
	for(new i = 1; i <= RECORDS; i++){
		MadeRecord[id][i] = 0
		TempRecord[id][i] = 0
		if(TopPlayer[0][i] == id)
			TopPlayer[0][i] = 0
	}
	
	g_Credits[id] = 0
	for(new i = 1; i <= UPGRADES; i++){
		PlayerUpgrades[id][i] = 0
	}
	
	get_user_authid(id, g_authid[id], 35)
	get_user_ip(id, g_userip[id], 31, 1)

	format(g_mvprank[id], 31, "")
	
	g_userClanId[id] = 0
	format(g_userClanName[id], 31, "")
	g_userNationalId[id] = 0
	format(g_userNationalName[id], 31, "")
	
	format(g_userCountry[id], 63, "")
	format(g_userCountry_2[id], 2, "")
	format(g_userCountry_3[id], 3, "")
	format(g_userCity[id], 45,  "")
	if(contain(g_userip[id], "192.168.")!=-1 || equal(g_userip[id], "127.0.0.1") || equal(g_userip[id], "loopback")){
		format(g_userCountry[id], 63, "")
		format(g_userCountry_2[id], 2, "")
		format(g_userCountry_3[id], 3, "")
		format(g_userCity[id], 45,  "")
	} else {
		geoip_country(g_userip[id], g_userCountry[id], 63)
		geoip_code2_ex(g_userip[id], g_userCountry_2[id])
		geoip_code3_ex(g_userip[id], g_userCountry_3[id])
		geoip_city(g_userip[id], g_userCity[id], 45)
			
		if(contain(g_userCity[id], "error") != -1 || g_userCity[id][0] == 0) {
			format(g_userCity[id], 45, "")
		} else if(contain(g_userCity[id], "Moscow") != -1) {
			format(g_userCountry[id], 63, "Russia")
			format(g_userCountry_2[id], 2, "RU")
			format(g_userCountry_3[id], 3, "RUS")
		}
			
		if(contain(g_userCountry_2[id], "erro") != -1 || g_userCountry_2[id][0] == 0 || contain(g_userCountry_3[id], "erro") != -1 || g_userCountry_3[id][0] == 0){
			format(g_userCountry[id], 63, "")
			format(g_userCountry_2[id], 2, "")
			format(g_userCountry_3[id], 3, "")
		}
	}
	
	new sz_temp[7], sz_name[32]
	get_user_name(id, sz_name, charsmax(sz_name))
	if(equal(g_userCountry_3[id], "")){
		if(contain(g_userip[id], "192.168.") != -1 || equal(g_userip[id], "127.0.0.1") || equal(g_userip[id], "loopback")){
			format(sz_temp, 6, "[LAN] ")
		} else {
			format(sz_temp, 6, "")
		}
	} else {
		format(sz_temp, 6, "[%s] ", g_userCountry_3[id])
	}
	
	
	ColorChat(0, GREY, "^4-> ^3%s^1%s%s ^4has joined", sz_temp, sz_name, is_user_admin(id)?" ^3[ADMIN]":"")
	
	remove_task(id - 8122)

	if(!task_exists(97753)){
		set_task(5.0, "sql_updateServerInfo", 97753)
	}
	
	sql_getPlayerInfo(id)
	
	//load_skills(id, 0)
	
	set_task(get_pcvar_float(cv_resptime), "RespawnPlayer", id + 412)
	
	client_cmd(id, "cl_forwardspeed 1000")
	client_cmd(id, "cl_backspeed 1000")
	client_cmd(id, "cl_sidespeed 1000")

	return PLUGIN_HANDLED
}

public WhoIs(id){
	new plist[2048]
	new len = 0
	new title[32] 
	new ip[22], buffname[64], sz_name[64]
	
	get_user_name(0, buffname, 63)
	
	for(new x = 0, k = 0; x < 64; x++){	// replace invalid symbols (cannot be performed in MOTD)
		if(buffname[x] > 0x7F || buffname[x] < 0)
			continue
		sz_name[k] = buffname[x]
		k++
	}
	
	get_user_ip(0, ip, charsmax(ip))
	
	format(title, charsmax(title), "Players List")
	
	
	len += format(plist[len], charsmax(plist) - len, "<head>")
	len += format(plist[len], charsmax(plist) - len, "<title>SJ-PRO.COM</title>")
	len += format(plist[len], charsmax(plist) - len, "<style type='text/css'>body {background: #000000;margin: auto;padding: auto;background-image: url('http://sj-pro.com/img/Soccerjamp_MOTD2.jpg');background-repeat:no-repeat;background-size:cover;}</style>")
	len += format(plist[len], charsmax(plist) - len, "<link rel='stylesheet' type='text/css' href='http://sj-pro.com/css/flags.css'></head>")
	len += format(plist[len], charsmax(plist) - len, "<body text=#FFFFFF bgcolor=#000000 background=^"http://sj-pro.com/img/main.jpg^"><center>")
	len += format(plist[len], charsmax(plist) - len, "<font color=#FFB000 size=3><b>%s<br>%s<br><br>", sz_name, ip)
	len += format(plist[len], charsmax(plist) - len, "<table border=0 width=90%% cellpadding=0 cellspacing=6>")
	len += format(plist[len], charsmax(plist) - len, "<tr style='color:green;font-weight:bold;text-decoration:underline;'><td>PLAYER<td>TEAM<td>LOCATION")
	
	for(new i = 1; i <= g_maxplayers; i++) { 
		if(~IsUserConnected(i) || IsUserBot(i))
			continue
		/*get_user_ip(i, ip, 21, 1)
		format(country, 3, "N/A")
		format(city, 45, "N/A")
		if(contain(ip, "192.168.")!=-1 || equal(ip, "127.0.0.1") || equal(ip, "loopback")){
			format(country, 3, "LAN")
			format(city, 45,  "LAN")
		} else {
			geoip_code3_ex(ip, country)
			geoip_city(ip, city, 45)
			
			if(contain(city, "error") != -1 || city[0] == 0) {
				format(city, 45, "N/A")
			} else if(contain(city, "Moscow") != -1) {
				format(country, 3, "RUS")
			}
			
			if(contain(country, "erro") != -1 || country[0] == 0){
				format(country, 3, "N/A")
			}
		}*/
		get_user_name(i, sz_name, charsmax(sz_name))

		
		len += format(plist[len], charsmax(plist) - len, "<tr><td>")
		if(g_userCountry_2[i][0] != EOS){
			len += format(plist[len], charsmax(plist) - len, "<img src='img/blank.gif' class='flag flag-%s' /> ", g_userCountry_2[i])
			len += format(plist[len], charsmax(plist) - len, "%s%s<td>%s<td>%s, %s", sz_name, is_user_admin(i)?"<font color=red> [A]":"", g_userClanName[i], g_userCountry[i], g_userCity[i])
		} else {
			len += format(plist[len], charsmax(plist) - len, "%s%s<td>%s<td>%s", sz_name, is_user_admin(i)?"<font color=red> [A]":"", g_userClanName[i], "N/A")
		}
	}
	
	show_motd(id, plist, title )
}

public client_disconnect(id){
	ClearUserAlive(id)
	ClearUserConnected(id)
	if(IsUserBot(id)){
		ClearUserBot(id)
	}
	
	remove_task(id)
	new i
	for(i = 0; i <= g_count_balls; i++){
		if(id == g_ballholder[i])
			break
	}
	if(i != g_count_balls + 1){
		new sz_name[32]
	
		glow(g_ballholder[i], 0, 0, 0)
		
		remove_task(55555 + i)
		set_task(get_pcvar_float(cv_reset), "ClearBall", 55555 + i)
		
		g_last_ballholderteam[i] = 0
		g_last_ballholder[i] = 0
		format(g_last_ballholdername[i], 31, "")
		
		get_user_name(id, sz_name, 31)
		format(g_temp, charsmax(g_temp), "|%s| %s^n%L", TeamNames[get_user_team(id)], sz_name, 
		LANG_SERVER, "SJ_DROPBALL")
		
		g_ballholder[i] = 0
		
		testorigin[i][2] += 10
		entity_set_origin(g_ball[i], testorigin[i])		
		entity_set_vector(g_ball[i], EV_VEC_velocity, Float:{1.0, 1.0, 1.0})
	}
	new name[32]

	get_user_name(id, name, 31)
	for(new i = 1; i <= g_maxplayers; i++){
		if(~IsUserConnected(i))
			continue
		
		ColorChat(i, RED, "^3<- ^1%s ^3has left", name)
	}
	
	save_stats(id)
	
	if(!task_exists(97753)){
		set_task(5.0, "sql_updateServerInfo", 97753)
	}
	
	AutoMultiBall()
	
	//format(g_authid[id], 35, "")
}

/*public client_disconnect_reason(id, ReasonCodes:drReason, const szReason[]){
	if(is_user_hltv(id))
		return PLUGIN_HANDLED
		
	new name[32], sz_temp[32]

	get_user_name(id, name, 31)
	switch (drReason){
		case DR_TIMEDOUT: format(sz_temp, charsmax(sz_temp), "^1[^4timed out^1]")
		case DR_DROPPED: {
			format(sz_temp, charsmax(sz_temp), "")
			new sz_team = get_user_team(id), sz_opteam
			if(1 <= sz_team <= 2){
				(sz_team == 1)?(sz_opteam = 2):(sz_opteam = 1)
				if(g_regtype && (GAME_MODE != MODE_PREGAME || GAME_MODE != MODE_HALFTIME) &&
				(((get_pcvar_num(cv_score[sz_opteam]) - get_pcvar_num(cv_score[sz_team])) >= 5 && ROUND == 1 && g_Timeleft < 600)
				|| (get_pcvar_num(cv_score[sz_opteam]) - get_pcvar_num(cv_score[sz_team])) >= 10)){
					format(sz_temp, charsmax(sz_temp), "^1[^3RAGEQUIT^1]")
				}
			}
			
			
		}
		case DR_KICKED: format(sz_temp, charsmax(sz_temp), "^1[^4kicked^1]")
		case DR_OTHER: format(sz_temp, charsmax(sz_temp), "^1[^4unknown reason^1]")
	}
	for(new i = 1; i <= g_maxplayers; i++){
		if(~IsUserConnected(i))
			continue
		
		ColorChat(i, RED, "^3<- ^1%s ^3has left %s", name, sz_temp)
	}

	return PLUGIN_HANDLED
}*/

play_wav(id, wav[]){
	client_cmd(id, "spk %s", wav)
}

Float:normalize(Float:nVel){
	if(nVel > 180.0) {
		nVel -= 360.0
	} else if(nVel < -179.0) {
		nVel += 360.0
	}

	return nVel
}

public Msg_StatusIcon(msgid, msgdest, id){
	static szIcon[8]
	get_msg_arg_string(2, szIcon, 7)
 
	if(equal(szIcon, "buyzone") && get_msg_arg_int(1)){
		set_pdata_int(id, 235, get_pdata_int(id, 235) & ~(1<<0))
		return PLUGIN_HANDLED
	}
 
	return PLUGIN_CONTINUE
}

public Msg_Money(MsgId, MsgDest, id){
	set_msg_arg_int(1, ARG_LONG, g_Experience[id])
}

public SvRestart(){
	server_cmd("sv_restart 1")
	remove_task(-4566)
	set_task(1.0, "Done_Handler", -4789)
}

public VoteStart(){
	for(new id = 1; id <= g_maxplayers; id++){
		if(IsUserBot(id) || ~IsUserConnected(id))
			continue
		g_votescoreMenu(id)
	}
	set_task(10.0, "VoteEnd")
	return PLUGIN_HANDLED
}

public g_votescoreMenu(id){
	new sz_temp[128]
	format(sz_temp, charsmax(sz_temp), "\y[SJ] \w- %L?", id, "SJ_GOL")
	new menu = menu_create(sz_temp, "g_votescoreMenu_handler")
	
	for(new i = 1; i < g_votechoice[0]; i++){
		format(sz_temp, charsmax(sz_temp), "%d", g_votechoice[i])
		menu_additem(menu, sz_temp)
	}
	
	menu_setprop(menu, MPROP_EXIT, MEXIT_NEVER)
	
	menu_display(id, menu)

	return PLUGIN_HANDLED
}

public g_votescoreMenu_handler(id, menu, item){	
	if(item == MENU_EXIT){
		menu_destroy(menu)
		return PLUGIN_HANDLED
	}
	
	new data[6], sz_name[64], name[32]
	new access, callback
	menu_item_getinfo(menu, item, access, data, charsmax(data), sz_name, charsmax(sz_name), callback)
	get_user_name(id, name, 31)
	
	g_votescore[0] += str_to_num(sz_name)
	g_votescore[1]++
	
	menu_destroy(menu)
	return PLUGIN_HANDLED
}

public VoteEnd(){
	new sz_score
	(g_votescore[1])?(sz_score = g_votescore[0] / g_votescore[1]):(sz_score = 10)
			
	set_pcvar_num(cv_score[0], sz_score)
	for(new id = 1; id <= g_maxplayers; id++){
		if(~IsUserConnected(id) || IsUserBot(id))
			continue
		
		show_menu(id, 0, "^n", 1)
		ColorChat(id, GREEN, "^4[SOCCER JAM] ^1- %L", 
		id, (sz_score%10 == 1 && sz_score%100 != 11)?"SJ_GOALLIM1":"SJ_GOALLIM", sz_score)
	}
}

public ShotClock(){
	if(timer <= 0){
		timer = SHOTCLOCK_TIME
		if(next >= 0 && !freeze_player[LineUp[next]] && IsUserConnected(LineUp[next])){
			SetAsWatcher(LineUp[next], ShootOut)
			if(PenGoals[get_user_team(LineUp[next])][next] == 0){
				PenGoals[get_user_team(LineUp[next])][next] = 2
			}
		}
		next--
		
		if(next >= 0){
			new shooter = LineUp[next]
			if(~IsUserConnected(shooter)){
				timer = 0
				ShotClock()
			} else {
				cs_user_spawn(shooter)
			}
			MoveBall(1, 0, 0)
			
			entity_set_origin(shooter, BallSpawnOrigin)

			seconds[shooter] = 0
			g_sprint[shooter] = 0
			PressedAction[shooter] = 0
			//entity_set_float(shooter,EV_FL_maxspeed, 0.1)
			freeze_player[shooter] = true
			set_task(3.0, "ShotClock", 0)
			
		} else {
			for(new id = 1; id <= g_maxplayers; id++)
				freeze_player[id] = false
		
			MoveBall(0, 0, -1)
			entity_set_float(candidates[ShootOut==T?CT:T], EV_FL_takedamage, 1.0)
			if(ShootOut == 2){
				round_restart(6.0)
				
				if(get_pcvar_num(cv_score[T]) > get_pcvar_num(cv_score[CT])){
					winner = T
				} else if(get_pcvar_num(cv_score[CT]) > get_pcvar_num(cv_score[T])) {
					winner = CT
				}
				
				if(winner){
					GAME_MODE = MODE_NONE
					scoreboard[0] = 0
					play_wav(0, snd_whistle_long)
					format(scoreboard, 1024, "Team %s WINS!", TeamNames[winner])
					new data[3]
					if(winner == 1)
						data = {255, 25, 25}
					else
						data = {25, 25, 255}
					set_task(1.0, "ShowDHud", _, data, 3, "a", 3)
					
					
				} else {
					play_wav(0, snd_whistle)
					ShootOut = 0
					ROUND = 3
					GAME_MODE = MODE_NONE
					scoreboard[0] = 0;
					format(scoreboard, 1024, "- OVERTIME -^nFirst team to score wins!")
					new data[3] = {255, 255, 10}
					set_task(1.0, "ShowDHud", _, data, 3, "a", 6)
				}
			} else {				
				round_restart(5.0)
				ShootOut = 2
				scoreboard[0] = 0;
				format(scoreboard, 1024, "Team %s is next to shootout! ", TeamNames[ShootOut])
				new data[3]
				if(ShootOut == T){
					data = TeamColors[T]
				} else {
					data = TeamColors[CT]
				}
				set_task(1.0, "ShowDHud", _, data, 3, "a", 3)
			}
		}
	} else {
		if(IsUserConnected(LineUp[next]) && freeze_player[LineUp[next]]){
			play_wav(0, snd_whistle)
			set_speedchange(LineUp[next], 0.0)
			freeze_player[LineUp[next]] = false
				
			new goaly = candidates[ShootOut==T?CT:T]
			seconds[goaly] = 0
			g_sprint[goaly] = 0
			set_speedchange(goaly)
		}

		timer--
		set_task(0.9, "ShotClock", 0)
	}
}

public SetAsWatcher(id, team){
	new Float:ang[3]
	
	if(g_PenOrig[id][1] == 0.0 || !(T <= get_user_team(id) <= CT)){
		cmdSpectate(id)
		return PLUGIN_HANDLED
	}
	
	
	freeze_player[id] = true
	
	entity_set_origin(id, g_PenOrig[id])
	
	entity_get_vector(Mascots[team], EV_VEC_v_angle, ang)
	entity_set_vector(id, EV_VEC_v_angle, ang)
	
	return PLUGIN_HANDLED
}

cmdSpectate(id){
	if((T <= get_user_team(id) <= CT) && get_pdata_int(id, OFFSET_INTERNALMODEL, 5) != 0xFF){
		cs_set_user_team(id, CS_TEAM_SPECTATOR, CS_DONTCHANGE)
		Remove_Hat(id)
		if(g_GK[T] == id){
			g_GK[T] = 0
		}
		if(g_GK[CT] == id){
			g_GK[CT] = 0
		}
		if(is_user_alive(id)){
			user_kill(id)
		}
	}
}

public round_restart(Float:x){
	set_cvar_num("sv_restart", floatround(x))
	set_task(x, "Done_Handler", -4789)
	remove_task(-4566)
}
public BeginCountdown(){
	if(!timer){
		timer = COUNTDOWN_TIME

		g_Timeleft = (get_pcvar_num(cv_time) * 60)
		GAME_MODE = MODE_GAME

	} else {
		new output[32]
		num_to_word(timer, output, 31)
		client_cmd(0, "spk vox/%s.wav", output)
		
		if(timer > (COUNTDOWN_TIME / 2)) {
			set_hudmessage(20, 250, 20, -1.0, 0.55, 1, 1.0, 1.0, 1.0, 0.5, 1)
		} else {
			set_hudmessage(255, 0, 0, -1.0, 0.55, 1, 1.0, 1.0, 1.0, 0.5, 1)
		}
			
		show_hudmessage(0, "GAME BEGINS IN:^n%i", timer)	
				
		if(timer == 1)
			round_restart(1.0)
		
		timer--
		set_task(0.9, "BeginCountdown", 9999)
	}
}

public CsSetUserScore(id, frags, deaths) { 
	message_begin(MSG_BROADCAST, msg_scoreboard)
	write_byte(id)
	write_short(frags)
	write_short(deaths)
	write_short(0)
	write_short(get_user_team(id))
	message_end()  
} 

/*
+-----------------------+--------------------------------------------------------------------------+
|			| ************************************************************************ |
|      	  [ADMIN]  	| ************************************************************************ |
|			| ************************************************************************ |
+-----------------------+--------------------------------------------------------------------------+
*/
public AdminMenu(id, level, cid){	
	if(!cmd_access(id, level, cid, 0))
		return PLUGIN_HANDLED	

	new sz_temp[256]
	format(sz_temp, charsmax(sz_temp), "\y[SJ] \w- %L", id, "SJ_ADMINMENU")
	new menu = menu_create(sz_temp, "AdminMenu_handler")
	new sz_langsets[32], sz_color[2]
	switch (GAME_SETS) {
		case SETS_DEFAULT: {format(sz_langsets, charsmax(sz_langsets), "SJ_DEFSET"); format(sz_color, charsmax(sz_color), "w");}
		case SETS_TRAINING: {format(sz_langsets, charsmax(sz_langsets), "SJ_TRAINING"); format(sz_color, charsmax(sz_color), "y");}
		case SETS_HEADTOHEAD: {format(sz_langsets, charsmax(sz_langsets), "SJ_HEADTOHEAD"); format(sz_color, charsmax(sz_color), "w");}
		case SETS_ROCKET: {format(sz_langsets, charsmax(sz_langsets), "SJ_ROCKETBALL"); format(sz_color, charsmax(sz_color), "r");}
	}
	format(sz_temp, charsmax(sz_temp), "\%s%L",sz_color, id, sz_langsets)
	menu_additem(menu, sz_temp)
	
	get_pcvar_num(cv_chat)?menu_additem(menu, "\wGlobal chat"):menu_additem(menu, "\dGlobal chat")
	
	menu_additem(menu, "\yCaps!")
	
	format(sz_temp, charsmax(sz_temp), "\%s%L",(g_count_balls)?("w"):("d"), id, "SJ_MULTIBALL")
	menu_additem(menu, sz_temp)
	
	get_pcvar_num(cv_pause)?menu_additem(menu, "\rPause timer"):menu_additem(menu, "\dPause timer")
	
	format(sz_temp, charsmax(sz_temp), "\wWake up call")
	menu_additem(menu, sz_temp)
	
	//format(sz_temp, charsmax(sz_temp), "%d_%d", level, cid)
	//menu_additem(menu, "\wManage teams", sz_temp)
	

	menu_display(id, menu, 0)
	return PLUGIN_HANDLED
}

public AdminMenu_handler(id, menu, item){	
	if(item == MENU_EXIT){
		menu_destroy(menu)
		return PLUGIN_HANDLED
	}
	new sz_name[32], data[6], access, callback
	menu_item_getinfo(menu, item, access, data, charsmax(data), sz_name, charsmax(sz_name), callback)

	new i, j
	get_user_name(id, sz_name, 31)
	if(task_exists(-4211)){
		remove_task(-4211)
		ColorChat(id, RED, "^4[SJ] ^1- ^3%L", id, "SJ_RAPIDSET")
		menu_destroy(menu)
		AdminMenu(id, 0, 0)
		return PLUGIN_HANDLED
	}
	if(item){
		set_task(0.1, "Done_Handler", -4211)
	}
	switch(item){
		case 0:	{
			SwitchGameSettings(id, GAME_SETS + 1)
		}
		case 1:	{
			if(get_pcvar_num(cv_chat)){
				set_pcvar_num(cv_chat, 0)
				set_cvar_num("sv_alltalk", 0)
				ColorChat(0, RED, "^4[SJ] ^1- ^1Global chat is ^3OFF! ^1(ADMIN: %s)", sz_name)
			} else {
				set_pcvar_num(cv_chat, 1)
				set_cvar_num("sv_alltalk", 1)
				ColorChat(0, GREEN, "^4[SJ] ^1- ^1Global chat is ^4ON! ^1(ADMIN: %s)", sz_name)
			}
		}
		case 2:	{
			if(GAME_MODE != MODE_PREGAME){
				ColorChat(id, RED, "^4[SJ] ^1- Need to end the current game to do caps!")
				menu_destroy(menu)
				AdminMenu(id, 0, 0)
				return PLUGIN_HANDLED
			}
			if((g_GK[T] && get_user_team(g_GK[T]) != T) || ~IsUserConnected(g_GK[T])){
				g_GK[T] = 0
			}
			if((g_GK[CT] && get_user_team(g_GK[CT]) != CT) || ~IsUserConnected(g_GK[CT])){
				g_GK[CT] = 0
			}
			new sz_random[TEAMS + 1][MAX_PLAYERS + 1]
			for(i = 1, j = 0; i <= g_maxplayers; i++){
				if(~IsUserConnected(i) || IsUserBot(i) || i == g_GK[T] || i == g_GK[CT]){
					continue
				}
				sz_random[T][j++] = i
			}
			
			if((g_GK[T] == 0 || ~IsUserConnected(g_GK[T])) && j){
				i = sz_random[T][random_num(0, j - 1)]
				
				for(new k = UPGRADES; k; k--){
					PlayerUpgrades[i][k] = 0
				}
				g_GK[T] = 0
				PlayerUpgrades[i][DEX] = UpgradeMax[DEX]
				PlayerUpgrades[i][AGI] = UpgradeMax[AGI]
				g_Credits[i] = 0
				cs_set_user_team(i, CS_TEAM_T)
				RespawnPlayer(i + 412)
				ChangeGK(i)
			}
			for(i = 1, j = 0; i <= g_maxplayers; i++){
				if(~IsUserConnected(i) || IsUserBot(i) || i == g_GK[T] || i == g_GK[CT]){
					continue
				}
				sz_random[CT][j++] = i
			}
			if((g_GK[CT] == 0 || ~IsUserConnected(g_GK[CT])) && j){
				i = sz_random[CT][random_num(0, j - 1)]

				for(new k = UPGRADES; k; k--){
					PlayerUpgrades[i][k] = 0
				}
				g_GK[CT] = 0
				PlayerUpgrades[i][DEX] = UpgradeMax[DEX]
				PlayerUpgrades[i][AGI] = UpgradeMax[AGI]
				cs_set_user_team(i, CS_TEAM_CT)
				g_Credits[i] = 0
				RespawnPlayer(i + 412)
				ChangeGK(i)
			}
			if(g_GK[T] == 0 || ~IsUserConnected(g_GK[T])){
				ColorChat(id, RED, "^4[SJ] ^1- ^1Need a goalkeeper for team ^3%s^1!", TeamNames[T])
				menu_destroy(menu)
				AdminMenu(id, 0, 0)
				return PLUGIN_HANDLED
			}
			if(g_GK[CT] == 0 || ~IsUserConnected(g_GK[CT])){
				ColorChat(id, BLUE, "^4[SJ] ^1- ^1Need a goalkeeper for team ^3%s^1!", TeamNames[CT])
				menu_destroy(menu)
				AdminMenu(id, 0, 0)
				return PLUGIN_HANDLED
			}
			if(g_GK[T] != 0 && IsUserConnected(g_GK[T]) && g_GK[CT] != 0 && IsUserConnected(g_GK[CT])){
				SwitchGameSettings(0, SETS_DEFAULT)
				for(i = 1; i <= g_maxplayers; i++){
					if(i == g_GK[T] || i == g_GK[CT])
						continue
					set_task(i * 0.3, "Task_cmdSpectate", i - 155) // need to make a delay
				}
				new sz_namet[32], sz_namect[32]
				get_user_name(g_GK[T], sz_namet, charsmax(sz_namet))
				get_user_name(g_GK[CT], sz_namect, charsmax(sz_namect))
				server_cmd("amx_vote ^"First to choose^" ^"%s^" ^"%s^"", sz_namet, sz_namect)
				
				/*if(!gGKVoteIsRunning){
					ColorChat(0, GREY, "^4[SJ] ^1- ^3Caps! ^1(ADMIN: %s)", sz_name)
					StartGKVote(id)
				} else {
					ColorChat(id, RED, "^4[SJ] ^1- Caps has been already proceed.")
				}*/
			}
			return PLUGIN_HANDLED
		}		
		case 3:	{
			MultiBall(id, 0, 0)
		}
		case 4:	{
			if(GAME_MODE == MODE_GAME){
				if(get_pcvar_num(cv_pause)){
					set_pcvar_num(cv_pause, 0)
					ColorChat(0, GREEN, "^4[SJ] ^1- ^1Timer has been ^4resumed! ^1(ADMIN: %s)", sz_name)
					server_cmd("sv_restart 1")
				} else {
					set_pcvar_num(cv_pause, 1)	
					ColorChat(0, RED, "^4[SJ] ^1- ^1Timer has been ^3stopped! ^1(ADMIN: %s)", sz_name)
					MoveBall(0, 0, 0)
				}
			} else {
				ColorChat(0, RED, "^4[SJ] ^1- You can stop timer only during the game.", sz_name)
			}
		}
		
		case 5:	{
			if(GAME_MODE == MODE_PREGAME || GAME_MODE == MODE_HALFTIME){
				new szTeam, sz_name[32]
				get_user_name(id, sz_name, charsmax(sz_name))
				client_print(0, print_console, "[SJ] - Wake up non-ready players. (ADMIN: %s)", sz_name)
				ColorChat(0, GREEN, "^4[SJ] ^1- Wake up non-ready players. (ADMIN: %s)", sz_name)
				for(new id = 1; id <= g_maxplayers; id++){
					szTeam = get_user_team(id)
					if(~IsUserConnected(id) || IsUserBot(id) || g_Ready[id] == true || (szTeam != T  && szTeam != CT))
						continue
					
					fakedamage(id, "Alien", float(pev(id, pev_health)) + 1.0, 1)
					client_cmd2(id, "cd eject")
				}
			
			} else {
				ColorChat(id, GREEN, "^4[SJ] ^1- You can use this command only at pre-game or half-time.")
				menu_destroy(menu)
				AdminMenu(id, 0, 0)
			}
			//show_motd(id, "<html bgcolor=#000000><head><meta http-equiv='cache-control' content='no-cache'><meta http-equiv='refresh' content='0; URL=http://sj-pro.com/syncSteamGroups.html'></head></html>", "SJ-Pro.com | Manage teams")
			//ColorChat(id, RED, "^4[SJ] ^1- Disabled. Only the God can do it.")
			return PLUGIN_HANDLED
		
		}
	
	}
	menu_destroy(menu)
	AdminMenu(id, 0, 0)
	
	return PLUGIN_HANDLED
}

public SwitchGameSettings(id, sz_set){
	new sz_data[1]
	sz_data[0] = id	
			
	switch (sz_set){
		case SETS_DEFAULT: 	GAME_SETS = SETS_DEFAULT
		case SETS_TRAINING: 	GAME_SETS = SETS_TRAINING
		case SETS_HEADTOHEAD: 	GAME_SETS = SETS_HEADTOHEAD
		case SETS_ROCKET: 	GAME_SETS = SETS_ROCKET
		
		default:{		
			SwitchGameSettings(id, SETS_DEFAULT)
			return PLUGIN_HANDLED
		}
	}
	remove_task(-2363)

	set_task(2.0, "ApplyGameSettings", -2363, sz_data, 1)
	
	return PLUGIN_HANDLED
}

public ApplyGameSettings(sz_data[]){
	new sz_langsets[32], sz_color[2], Color:sz_symb
			
	switch (GAME_SETS){
		case SETS_DEFAULT:{
			format(sz_langsets, charsmax(sz_langsets), "SJ_DEFSET")
			format(sz_color, charsmax(sz_color), "^1")
			sz_symb = GREEN
			set_pcvar_num(cv_turbo, 2)
			set_pcvar_num(cv_nogoal, 0)
			set_pcvar_num(cv_lamedist, 0)
			set_pcvar_num(cv_alienzone, 650)
			set_pcvar_num(cv_kick, 650)
			set_pcvar_num(cv_multiball, 15)
			set_pcvar_num(cv_players, 5)
			set_pcvar_num(cv_huntdist, 0)
			set_pcvar_num(cv_smack, 80)
			set_pcvar_num(cv_pause, 0)
			set_pcvar_float(cv_alienthink, 1.0)
			set_pcvar_float(cv_alienmin, 8.0)
			set_pcvar_float(cv_alienmax, 12.0)
			set_pcvar_float(cv_ljdelay, 5.0)
			set_pcvar_float(cv_resptime, 2.0)
			set_pcvar_float(cv_reset, 30.0)
			set_cvar_num("sv_alltalk", 1)
			set_cvar_num("sv_gravity", 800)
			set_cvar_num("sv_maxspeed", 900)
			GAME_SETS = SETS_DEFAULT
		}
		case SETS_TRAINING:{
			format(sz_langsets, charsmax(sz_langsets), "SJ_TRAINING") 
			format(sz_color, charsmax(sz_color), "^3")
			sz_symb = BLUE
			set_pcvar_num(cv_turbo, 20)
			set_pcvar_num(cv_nogoal, 1)
			set_pcvar_num(cv_lamedist, 0)
			set_pcvar_num(cv_players, 5)
			set_pcvar_num(cv_alienzone, 650)
			set_pcvar_num(cv_kick, 650)
			set_pcvar_float(cv_reset, 30.0)
			set_pcvar_num(cv_multiball, 15)
			GAME_SETS = SETS_TRAINING
		}
		case SETS_HEADTOHEAD:{
			format(sz_langsets, charsmax(sz_langsets), "SJ_HEADTOHEAD") 
			format(sz_color, charsmax(sz_color), "^3")
			sz_symb = GREY
			set_pcvar_num(cv_turbo, 20)
			set_pcvar_num(cv_nogoal, 0)
			set_pcvar_num(cv_alienzone, 650)
			set_pcvar_num(cv_players, 1)
			set_pcvar_num(cv_kick, 650)
			set_pcvar_float(cv_reset, 30.0)
			GAME_SETS = SETS_HEADTOHEAD
		}
		case SETS_ROCKET:{
			format(sz_langsets, charsmax(sz_langsets), "SJ_ROCKETBALL") 
			format(sz_color, charsmax(sz_color), "^3")
			sz_symb = RED
			set_pcvar_num(cv_turbo, 20)
			set_pcvar_num(cv_nogoal, 0)
			set_pcvar_num(cv_lamedist, 0)
			set_pcvar_num(cv_players, 5)
			set_pcvar_num(cv_alienzone, 2350)
			set_pcvar_num(cv_kick, 2000)
			set_pcvar_float(cv_reset, 30.0)
			GAME_SETS = SETS_ROCKET
		}
		default: return PLUGIN_HANDLED
	}

	new sz_name[32]
	get_user_name(sz_data[0], sz_name, charsmax(sz_name))
	for(new i = 1; i <= g_maxplayers; i++){
		if(IsUserConnected(i)){
			ColorChat(i, sz_symb, "^4[SJ] ^1- %s%L ^1(%L: %s)", 
			sz_color, i, sz_langsets, i, "SJ_ADMIN", sz_name) 
			seconds[i] = 0
		}
	}
	return PLUGIN_HANDLED
}

public Task_cmdSpectate(id){
	id += 155
	cmdSpectate(id)
		
}
public MultiBall(id, level, cid){
	if(!cmd_access(id, level, cid, 0))
		return PLUGIN_HANDLED
	if(g_regtype && GAME_MODE != MODE_PREGAME){
		//ColorChat(id, RED, "^4[SJ] ^1- ^3%L", id, "SJ_MULTIAV")
		ColorChat(id, RED, "^4[SJ] ^1- This command is not available now!")
		
		return PLUGIN_HANDLED
	}
	new i
	if(g_count_balls){
		for(i = g_count_balls; i; i--){
			RemoveBall(i)
		}
		if(GAME_TYPE == TYPE_PUBLIC)
			MoveBall(1, 0, 0)
		else if(GAME_MODE == MODE_PREGAME || GAME_MODE == MODE_HALFTIME || GAME_MODE == MODE_NONE)
			MoveBall(0, 0, 0)
	} else {
		new sz_cvar = get_pcvar_num(cv_multiball)
		if(sz_cvar < 0 || sz_cvar > LIMIT_BALLS){
			sz_cvar = g_maxplayers
			set_pcvar_num(cv_multiball, sz_cvar)
		}
		for(i = 1; i < sz_cvar; i++){
			CreateBall(i)
			MoveBall(1, 0, i)
		}
		if(GAME_SETS == SETS_DEFAULT){
			SwitchGameSettings(id, SETS_TRAINING)
		}
			
	}

	g_count_scores = 0
	
	new sz_name[32]
	get_user_name(id, sz_name, 31)
	for(i = 1; i <= g_maxplayers; i++){
		if(IsUserConnected(i)){
			ColorChat(i, RED, "^4[SJ] ^1- %L: %s%L! ^1(%L: %s)", 
			i, "SJ_MULTIBALL", g_count_balls?("^4"):("^3"),
			i, g_count_balls?("SJ_ON"):("SJ_OFF"), i, "SJ_ADMIN", sz_name) 
			
			g_count_balls?(g_showhud[i] = false):(g_showhud[i] = true)
		}
	}
	return PLUGIN_HANDLED	
}

public StartGKVote(id){
	if(gGKVoteIsRunning){
		ColorChat(id, RED, "^4[SJ] ^1- Caps has been already proceed.")
		return PLUGIN_HANDLED
	}
	gGKVoteIsRunning = true
	
	gGKVoteCount[T] = 0
	gGKVoteCount[CT] = 0
	
	for(new i = 1; i <= MAX_PLAYERS; i++){
		if(~IsUserConnected(i) /*|| i == g_GK[T] || i == g_GK[CT]*/){			
			continue
		}
		ShowGKVoteMenu(i, false)
	}
	remove_task(4433001)
	set_task(7.0, "FinishGKVote", 4433001)
	return PLUGIN_HANDLED
}

public ShowGKVoteMenu(id, bool:hasVoted)
{
	new szItemInfo[3], szTitle[101]

	format(szTitle, charsmax(szTitle), "Who chooses first?")

	new szMenu = menu_create(szTitle, "GKVoteMenuHandler")
	
	new szName[32], szTemp[64]
	
	if(g_GK[T] && IsUserConnected(g_GK[T])){
		/*if(hasVoted == false){
			get_user_name(g_GK[T], szName, charsmax(szName))
			format(szTemp, charsmax(szTemp), "\w%s", szPlayerName)
		} else {
			get_user_name(g_GK[T], szName, charsmax(szName))
			format(szTemp, charsmax(szTemp), "\d%s", szPlayerName)
		}*/
		menu_additem(szMenu, szName)
	} else {
		ColorChat(0, RED, "^4[SJ] ^1- No GK for ^3%s ^1team.", TeamNames[T])
		return PLUGIN_HANDLED 
	}
	
	if(g_GK[CT] && IsUserConnected(g_GK[CT])){
		get_user_name(g_GK[CT], szName, charsmax(szName))
		menu_additem(szMenu, szName)
	} else {
		ColorChat(0, BLUE, "^4[SJ] ^1- No GK for ^3%s ^1team.", TeamNames[CT])
		return PLUGIN_HANDLED 
	}
	
	menu_display(id, szMenu, 0)
	
	return PLUGIN_HANDLED
}

public GKVoteMenuHandler(id, menu, item){
	if(!gGKVoteIsRunning || !task_exists(4433001) || item == MENU_EXIT){
		menu_destroy(menu)
		return PLUGIN_HANDLED
	}
	
	new szName[32], szGKName[32]
	get_user_name(id, szName, charsmax(szName))
	if(item == 0){
		if(g_GK[T] && IsUserConnected(g_GK[T])){
			get_user_name(g_GK[T], szGKName, charsmax(szGKName))
			ColorChat(0, RED, "^4%s ^1voted for ^3%s", szName, szGKName)
			gGKVoteCount[T]++
		} else {
			FinishGKVote()
		}
	} else if(item == 1) {
		if(g_GK[CT] && IsUserConnected(g_GK[CT])){
			get_user_name(g_GK[CT], szGKName, charsmax(szGKName))
			ColorChat(0, BLUE, "^4%s ^1voted for ^3%s", szName, szGKName)
			gGKVoteCount[CT]++
		} else {
			FinishGKVote()
		}
	}

	menu_destroy(menu)
	return PLUGIN_HANDLED
}

public FinishGKVote(){
	if(!gGKVoteIsRunning){
		return PLUGIN_HANDLED
	}
	
	if(!g_GK[T] || ~IsUserConnected(g_GK[T])){
		ColorChat(0, RED, "^4[SJ] ^1- No GK for ^3%s ^1team. Voting failed.", TeamNames[T])
		gGKVoteIsRunning = false
		return PLUGIN_HANDLED
	}
	
	if(!g_GK[CT] || ~IsUserConnected(g_GK[CT])){
		ColorChat(0, BLUE, "^4[SJ] ^1- No GK for ^3%s ^1team. Voting failed.", TeamNames[CT])
		gGKVoteIsRunning = false
		return PLUGIN_HANDLED
	}
	
	new szName[32]
	if((gGKVoteCount[T] + gGKVoteCount[CT]) > 0){
		if(gGKVoteCount[T] > gGKVoteCount[CT]){
			get_user_name(g_GK[T], szName, charsmax(szName))
			ColorChat(0, RED, "^4[SJ] ^1- ^3%s ^1chooses first.", szName)
			set_task(0.0, "ShowGKPlayersMenu", 443300 + g_GK[T])
		} else if(gGKVoteCount[T] < gGKVoteCount[CT]){
			get_user_name(g_GK[CT], szName, charsmax(szName))
			ColorChat(0, BLUE, "^4[SJ] ^1- ^3%s ^1chooses first.", szName)
			set_task(0.0, "ShowGKPlayersMenu", 443300 + g_GK[CT])
		} else {
			new szRandomTeam = random_num(T, CT)
			get_user_name(g_GK[szRandomTeam], szName, charsmax(szName))
			ColorChat(0, (szRandomTeam == T)?RED:BLUE, "^4[SJ] ^1- Equal amount of votes. Random choice: ^3%s ^1chooses first.", szName)	
			set_task(0.0, "ShowGKPlayersMenu", 443300 + g_GK[szRandomTeam])
		}
	} else {
		new szRandomTeam = random_num(T, CT)
		get_user_name(g_GK[szRandomTeam], szName, charsmax(szName))
		ColorChat(0, (szRandomTeam == T)?RED:BLUE, "^4[SJ] ^1- No one voted. Random choice: ^3%s ^1chooses first.", szName)
		set_task(0.0, "ShowGKPlayersMenu", 443300 + g_GK[szRandomTeam])
	}
	
	return PLUGIN_HANDLED
		
}

public ShowGKPlayersMenu(id)
{
	id -= 443300
	new szTeam = get_user_team(id)
	if(~IsUserConnected(id) || !g_GK[szTeam]){
		ColorChat(0, RED, "^4[SJ] ^1- One of captians left. Choosing is ended.")
		gGKVoteIsRunning = false
		remove_task(443300 + id)
		remove_task(443300 + g_GK[((szTeam == T)?CT:T)])
		return PLUGIN_HANDLED 
	}
	
	new szItemInfo[3], szTitle[101]
	format(szTitle, charsmax(szTitle), "Choose a player for team %s", TeamNames[get_user_team(id)])
	new szMenu = menu_create(szTitle, "GKPlayersMenuHandler")
	
	new szPlayerName[32], szTemp[64], szPlayerTeam = -1
	for(new i = 1; i <= MAX_PLAYERS; i++)
	{
		if(~IsUserConnected(i) || i == g_GK[T] || i == g_GK[CT])
			continue
			
		szPlayerTeam = get_user_team(i)	
		if(szPlayerTeam == T || szPlayerTeam == CT){
			continue
		}
		get_user_name(i, szPlayerName, charsmax(szPlayerName))
		
		format(szTemp, charsmax(szTemp), "\w%s", szPlayerName)
		
		format(szItemInfo, 2, "%i", i)
		menu_additem(szMenu, szTemp, szItemInfo, 0)
	}
	if(szPlayerTeam == -1){
		ColorChat(0, RED, "^4[SJ] ^1- No players to choose. Choosing is ended.")
		gGKVoteIsRunning = false
		remove_task(443300 + id)
		remove_task(443300 + g_GK[((szTeam == T)?CT:T)])
		return PLUGIN_HANDLED 
	}
	set_task(0.0, "ShowGKPlayersMenu", 443300 + id)
	//set_task(60.0, "ShowGKPlayersMenu", 443300 + g_GK[((szTeam == T)?CT:T)])
	
	menu_display(id, szMenu, 0)
	
	return PLUGIN_HANDLED 
}

public GKPlayersMenuHandler(id, menu, item)
{
	if(!gGKVoteIsRunning || item == MENU_EXIT){
		menu_destroy(menu)
		return PLUGIN_HANDLED
	}
	new szTeam = get_user_team(id)
	if(~IsUserConnected(id) || !g_GK[szTeam] || (szTeam != T && szTeam != CT)){
		ColorChat(0, RED, "^4[SJ] ^1- One of captians left. ^3Caps has been interrupted.")
		gGKVoteIsRunning = false
		remove_task(443300 + id)
		remove_task(443300 + g_GK[((szTeam == T)?CT:T)])
		menu_destroy(menu)
		return PLUGIN_HANDLED 
	}
	
	if(item != MENU_BACK && item != MENU_MORE){
		new szAccess, szItemInfo[3], szCallback
		menu_item_getinfo(menu, item, szAccess, szItemInfo, charsmax(szItemInfo), _, _, szCallback)
		
		new szChosenPlayer = str_to_num(szItemInfo)
		
		if(~IsUserConnected(szChosenPlayer)){
			ColorChat(id, RED, "^4[SJ] ^1- This player has been disconnected. Choose another one.")
			menu_destroy(menu)
			ShowGKPlayersMenu(id)
			return PLUGIN_HANDLED
		}
		new szName[32]
		get_user_name(id, szName, charsmax(szName))
		
		new szPlayerName[32], szPlayerTeam
		get_user_name(szChosenPlayer, szPlayerName, charsmax(szPlayerName))
		
		ColorChat(0, (szTeam == T)?RED:BLUE, "^3%s ^1chose ^3%s", szName, szPlayerName)
		cs_set_user_team(szChosenPlayer, szTeam, CS_DONTCHANGE)
		RespawnPlayer(szChosenPlayer)
		new szCountPlayers[TEAMS]
		szCountPlayers[T] = 0
		szCountPlayers[CT] = 0
		
		for(new i = 1; i <= MAX_PLAYERS; i++){
			szPlayerTeam = get_user_team(i)	
			
			if(~IsUserConnected(i) || (szPlayerTeam != T && szPlayerTeam != CT))
				continue
				
			szCountPlayers[szPlayerTeam]++
		}
		
		if(szCountPlayers[T] >= get_pcvar_num(cv_players) && szCountPlayers[CT] >= get_pcvar_num(cv_players)){
			gGKVoteIsRunning = false
			remove_task(443300 + id)
			remove_task(443300 + g_GK[((szTeam == T)?CT:T)])
			ColorChat(0, RED, "^4[SJ] ^1- Caps is ^4finished^1! Restarting server and get ^3READY.")
			server_cmd("amx_restart")
			
		} else if(szCountPlayers[((szTeam == T)?CT:T)] < get_pcvar_num(cv_players)) {
			remove_task(443300 + id)
			remove_task(443300 + g_GK[((szTeam == T)?CT:T)])
			set_task(0.0, "ShowGKPlayersMenu", 443300 + g_GK[((szTeam == T)?CT:T)])
			
			
			
		} else if(szCountPlayers[szTeam] < get_pcvar_num(cv_players)) {
			remove_task(443300 + id)
			remove_task(443300 + g_GK[((szTeam == T)?CT:T)])
			set_task(0.0, "ShowGKPlayersMenu", 443300 + id)
			ColorChat(id, RED, "^4[SJ] ^1- Choose one more player.")
			
		} else {
			
			remove_task(443300 + id)
			remove_task(443300 + g_GK[((szTeam == T)?CT:T)])
			ColorChat(id, RED, "^4[SJ] ^1- Uknown error. Caps has been interrupted.")
		}
	}
	
	menu_destroy(menu)
	return PLUGIN_HANDLED
}

public update_allclan(){
	for(new id = 1; id <= g_maxplayers; id++){
		if(IsUserConnected(id) && ~IsUserBot(id))
			sql_getPlayerInfo(id)
			
	}
}

/*
+-----------------------+--------------------------------------------------------------------------+
|			| ************************************************************************ |
|      [STATS]		| ************************************************************************ |
|			| ************************************************************************ |
+-----------------------+--------------------------------------------------------------------------+
*/
ShowMOTDStats(id, cid){
	new sz_temp[2048], sz_len, title[32], i, ss[10], sz_name[32], sz_team, sz_color[16]
	new Float:fb, Float:fh
	sz_team = get_user_team(id)
	switch (sz_team){
		case 0: copy(sz_color, charsmax(sz_color), "white")
		case 1: copy(sz_color, charsmax(sz_color), "red")
		case 2: copy(sz_color, charsmax(sz_color), "#3366FF")
	}
	
	/*for(i = 1; i <= RECORDS; i++){
		if(!TopPlayer[0][i])
			format(TopPlayerName[i], charsmax(sz_name), "-")
	}*/
	
	format(title, charsmax(title), "%L", id, "SJ_STATSTITLE")
	   	
	sz_len += format(sz_temp[sz_len], charsmax(sz_temp) - sz_len, 
	"<body bgcolor=#000000 text=#FFFFFF><center>")
	
	
	sz_len += format(sz_temp[sz_len], charsmax(sz_temp) - sz_len, 
	"<hr width=50%% color=%s><font color=orange size=5><b>%L<hr width=50%% color=%s>", 
	sz_color, id, "SJ_MOTD_STITLE", sz_color)
	
	sz_len += format(sz_temp[sz_len], charsmax(sz_temp) - sz_len, 
	"<table width=45%% border=0 align=center cellpadding=0 cellspacing=6>")
	
	get_user_name(cid, sz_name, 31)
	
	sz_len += format(sz_temp[sz_len], charsmax(sz_temp) - sz_len, 
	"<tr align=center><td align=left> <td><u><b><font color=green>%L<td><u><b><font color=green>%L<td><font color=orange><u>%s",
	id, "SJ_MOTD_PLAYER", id, "SJ_MOTD_TOP", sz_name)
	
	new sz_lang[32]

	for(i = 1; i <= RECORDS; i++){
		if(i == HITS || i == BHITS)
			continue
							
		format(sz_lang, 31, "SJ_MOTD_%s", RecordTitles[i])
		
		if(i != POSSESSION){
			sz_len += format(sz_temp[sz_len], charsmax(sz_temp) - sz_len, 
			"<tr align=center><td><font color=yellow>%L<td>%s<td>%d", 
			id, sz_lang, TopPlayerName[i], TopPlayer[1][i])
		}
		else{
			num_to_str(TopPlayer[1][i], ss, 9)
			fb = str_to_float(ss)
			num_to_str(g_Time[0], ss, 9)
			fh = str_to_float(ss)
			//client_print(0, print_chat, "%2.f , %2.f", fb, fh)
			sz_len += format(sz_temp[sz_len], charsmax(sz_temp) - sz_len, 
			"<tr align=center><td><font color=yellow>%L<td>%s<td>%d%", 
			id, sz_lang, TopPlayerName[i], g_Time[0]?(floatround((fb / fh) * 100.0)):0)
			
		}
		switch(i){ 
			case DISTANCE:{
				sz_len += format(sz_temp[sz_len], charsmax(sz_temp) - sz_len, " %L", 
				id, "SJ_MOTD_FT")
				
				sz_len += format(sz_temp[sz_len], charsmax(sz_temp) - sz_len, 
				"<td> %d %L", MadeRecord[cid][i], id, "SJ_MOTD_FT")
			}
			case POSSESSION:{
				num_to_str(MadeRecord[cid][i], ss, 9)
				fb = str_to_float(ss)
				num_to_str(g_Time[0], ss, 9)
				fh = str_to_float(ss)
				sz_len += format(sz_temp[sz_len], charsmax(sz_temp) - sz_len, 
				"<td> %d%",  g_Time[0]?(floatround((fb / fh) * 100.0)):0)
			}
							
			default:{
				sz_len += format(sz_temp[sz_len], charsmax(sz_temp) - sz_len, 
				"<td> %d", MadeRecord[cid][i])
			}
		}			
	}
	
	sz_len += format(sz_temp[sz_len], charsmax(sz_temp) - sz_len, 
	"</table><hr width=50%% color=%s><br>", sz_color)
	
	show_motd(id, sz_temp, title )
}

public ShowMOTDPlayerStats(id, player){
	new sz_temp[2048], sz_len, title[32], i, sz_name[32]
	get_user_name(player, sz_name, 31)
	new sz_team = get_user_team(id)
	format(title, charsmax(title), "%L", id, "SJ_STATSTITLE")
	   	
	sz_len += format(sz_temp[sz_len], charsmax(sz_temp) - sz_len, 
	"<body bgcolor=#000000 text=#FFFFFF><center>")
	
	sz_len += format(sz_temp[sz_len], charsmax(sz_temp) - sz_len, 
	"<br><font color=%s size=6><b>%s", 
	sz_team==1?"red":"#3366FF", sz_name)
	
	sz_len += format(sz_temp[sz_len], charsmax(sz_temp) - sz_len, 
	"<hr width=50%% color=%s>", sz_team==1?"red":"#3366FF")
	
	sz_len += format(sz_temp[sz_len], charsmax(sz_temp) - sz_len, 
	"<table width=45%% border=0 align=center cellpadding=0 cellspacing=6>")
	
	new sz_lang[32], ss[10]
	new Float:fh, Float: fb

	for(i = 1; i <= RECORDS; i++){
		if(i == HITS || i == BHITS)
			continue
							
		format(sz_lang, charsmax(sz_lang), "SJ_MOTD_%s", RecordTitles[i])
		
		if(i != POSSESSION){
			sz_len += format(sz_temp[sz_len], charsmax(sz_temp) - sz_len, 
			"<tr align=center><td align=left><font color=yellow>%L<td><b>%d", 
			id, sz_lang, MadeRecord[player][i])
		}
		else{
			num_to_str(MadeRecord[id][i], ss, 9)
			fb = str_to_float(ss)
			num_to_str(g_Time[0], ss, 9)
			fh = str_to_float(ss)
			sz_len += format(sz_temp[sz_len], charsmax(sz_temp) - sz_len, 
			"<tr align=center><td align=left><font color=yellow>%L<td><b>%d%", 
			id, sz_lang, g_Time[0]?(floatround((fb / fh) * 100.0)):0)
		}				
	}
	
	sz_len += format(sz_temp[sz_len], charsmax(sz_temp) - sz_len, 
	"</table><hr width=50%% color=%s>", sz_team==1?"red":"#3366FF")
    
	show_motd(id, sz_temp, title)
}

public ShowMenuStats(id){		
	new sz_temp[1024], sz_len, sz_buff[32], sz_name[13]
	//sz_len += format(sz_temp[sz_len], charsmax(sz_temp) - sz_len, "%L:^n", id, "SJ_STATSTITLE")
	sz_len += format(sz_temp[sz_len], charsmax(sz_temp) - sz_len, "Stats:^n")
	for(new x = 1; x <= RECORDS; x++){
		if(x == POSSESSION || x == DISTANCE || x == BALLKILL)
			continue
		//format(sz_lang, charsmax(sz_lang), "SJ_%s", RecordTitles[x])
		format(sz_name, 15, TopPlayerName[x])
		if(TopPlayer[0][x] != id){
			format(sz_buff, 8, "\d%d", MadeRecord[id][x])
		} else {
			format(sz_buff, 8, "")
		}
		sz_len += format(sz_temp[sz_len], charsmax(sz_temp) - sz_len, "^n\w%s \y%s \r%d %s", RecordTitles[x],
		TopPlayer[1][x]?sz_name:"", TopPlayer[1][x], sz_buff)
		
		//menu_additem(menu, x, sz_temp)
	}
	//console_print(id, sz_temp)
	new menu = menu_create(sz_temp, "Done_Handler")
	menu_setprop(menu, MPROP_EXIT, MEXIT_NEVER)
	//format(sz_temp, charsmax(sz_temp), "%L", id, "SJ_EXIT")
	//menu_setprop(menu, MPROP_EXITNAME, sz_temp)
	menu_additem(menu, "Close")

	menu_display(id, menu, 0)
	return PLUGIN_HANDLED
}

public ShowMenuPlayerStats(id, player){		
	new sz_temp[1024], sz_len
	new sz_name[32], sz_lang[32]
	
	get_user_name(player, sz_name, 31)
	//sz_len = format(sz_temp[sz_len], charsmax(sz_temp) - sz_len, 
	//"\y%L:^n\w%s^n^n", id, "SJ_SKILLS", sz_name)
	sz_len = format(sz_temp[sz_len], charsmax(sz_temp) - sz_len, "%s^n^n", sz_name)
	for(new x = 1; x <= RECORDS; x++){
		if(x == POSSESSION)
			continue
		format(sz_lang, charsmax(sz_lang), "SJ_%s", RecordTitles[x])
		sz_len += format(sz_temp[sz_len], charsmax(sz_temp) - sz_len,  
		"%L \r%d \w%d^n", id, sz_lang,
		MadeRecord[player][x], TopPlayer[1][x])
	}

	new menu = menu_create(sz_temp, "Done_Handler")
	menu_additem(menu, "")
	menu_setprop(menu, MPROP_EXIT, MEXIT_ALL)
	format(sz_lang, charsmax(sz_lang), "%L", id, "SJ_EXIT")
	menu_setprop(menu, MPROP_EXITNAME, sz_lang)

	menu_display(id, menu, 0)
	return PLUGIN_HANDLED
}
public TNT_ShowMenuPlayerStats(id, player){		
	new sz_temp[1024], sz_len
	new sz_name[32]
	
	get_user_name(player, sz_name, 31)
	sz_len = format(sz_temp[sz_len], 1023 - sz_len, "\yStats:^n\w%s^n^n", sz_name)
	
	for(new x = 1; x <= RECORDS; x++){
		if(x == POSSESSION)
			continue
		sz_len += format(sz_temp[sz_len], 1023 - sz_len,  "\w%s \r%d \d%d^n", RecordTitles[x], 
		MadeRecord[player][x], TopPlayer[1][x])
	}
	new menu = menu_create(sz_temp, "Done_Handler")

	menu_additem(menu, "Close")
	menu_setprop(menu, MPROP_EXIT, MEXIT_NEVER)

	menu_display(id, menu, 0)
	return PLUGIN_HANDLED
}
/*
+-----------------------+--------------------------------------------------------------------------+
|			| ************************************************************************ |
|        [HELP]		| ************************************************************************ |
|			| ************************************************************************ |
+-----------------------+--------------------------------------------------------------------------+
*/
public PlayerHelpMenu(id){		
	new sz_temp[512]
	format(sz_temp, charsmax(sz_temp),"\y[SJ] \w- %L", id, "SJ_HELPTITLE")
	new menu = menu_create(sz_temp, "PlayerHelpMenu_handler")
	
	format(sz_temp, charsmax(sz_temp), "%L", id, "SJ_HELPGENINF")
	menu_additem(menu, sz_temp)
	format(sz_temp, charsmax(sz_temp), "%L", id, "SJ_HELPSKILLS")
	menu_additem(menu, sz_temp)
	format(sz_temp, charsmax(sz_temp), "%L", id, "SJ_HELPCONTR")
	menu_additem(menu, sz_temp)
	format(sz_temp, charsmax(sz_temp), "%L", id, "SJ_HELPCHAT")
	menu_additem(menu, sz_temp)
	format(sz_temp, charsmax(sz_temp), "%L", id, "SJ_HELPTRICKS")
	menu_additem(menu, sz_temp)

	menu_setprop(menu, MPROP_EXIT, MEXIT_ALL)
	format(sz_temp, charsmax(sz_temp), "%L", id, "SJ_EXIT")
	menu_setprop(menu, MPROP_EXITNAME, sz_temp)
	
	menu_display(id, menu, 0)
	
	return PLUGIN_HANDLED
}

public PlayerHelpMenu_handler(id, menu, item){
	if(item == MENU_EXIT){
		return PLUGIN_HANDLED	
	}
	
	ShowHelp(id, item)
	
	menu_destroy(menu)
	PlayerHelpMenu(id)
	
	return PLUGIN_HANDLED
}

public ShowHelp(id, x){
	new help_title[64], sz_temp[2048], sz_len
	format(help_title, charsmax(help_title), "%L", id, "SJ_HELP_MOTD")
	switch(x){
		case(0):{
			sz_len += format(sz_temp[sz_len], charsmax(sz_temp) - sz_len, "<body bgcolor=#000000 text=yellow><br>")
			sz_len += format(sz_temp[sz_len], charsmax(sz_temp) - sz_len, 
			"<h2><center><font color=5da130>%L</font></center></h2>", 
			id, "SJ_MOTD_HELP_GENINFO_TITLE")
			sz_len += format(sz_temp[sz_len], charsmax(sz_temp) - sz_len, "%L<br>", id, "SJ_MOTD_HELP_GENINFO_1")
			sz_len += format(sz_temp[sz_len], charsmax(sz_temp) - sz_len, "%L<br>", id, "SJ_MOTD_HELP_GENINFO_2")
			sz_len += format(sz_temp[sz_len], charsmax(sz_temp) - sz_len, "%L<br>", id, "SJ_MOTD_HELP_GENINFO_3")
			sz_len += format(sz_temp[sz_len], charsmax(sz_temp) - sz_len, "%L", id, "SJ_MOTD_HELP_GENINFO_4")
		}
		case(1):{
			sz_len += format(sz_temp[sz_len], charsmax(sz_temp) - sz_len, "<body bgcolor=#000000 text=yellow><br>")
			sz_len += format(sz_temp[sz_len], charsmax(sz_temp) - sz_len, 
			"<h2><center><font color=5da130>%L</font></center></h2>", 
			id, "SJ_MOTD_HELP_SKILLS_TITLE")
			sz_len += format(sz_temp[sz_len], charsmax(sz_temp) - sz_len, "%L<br>", id, "SJ_MOTD_HELP_SKILLS_STA")
			sz_len += format(sz_temp[sz_len], charsmax(sz_temp) - sz_len, "%L<br>", id, "SJ_MOTD_HELP_SKILLS_STR")
			sz_len += format(sz_temp[sz_len], charsmax(sz_temp) - sz_len, "%L<br>", id, "SJ_MOTD_HELP_SKILLS_AGI")
			sz_len += format(sz_temp[sz_len], charsmax(sz_temp) - sz_len, "%L<br>", id, "SJ_MOTD_HELP_SKILLS_DEX")
			sz_len += format(sz_temp[sz_len], charsmax(sz_temp) - sz_len, "%L<br>", id, "SJ_MOTD_HELP_SKILLS_DIS")
			sz_len += format(sz_temp[sz_len], charsmax(sz_temp) - sz_len, "%L<br>", id, "SJ_MOTD_HELP_SKILLS_GEN")
			sz_len += format(sz_temp[sz_len], charsmax(sz_temp) - sz_len, "%L<br><br>", id, "SJ_MOTD_HELP_SKILLS_RESET")
			
			sz_len += format(sz_temp[sz_len], charsmax(sz_temp) - sz_len, "%L: +$%d<br>", id, "SJ_MOTD_GOL", POINTS_GOAL)
			sz_len += format(sz_temp[sz_len], charsmax(sz_temp) - sz_len, "%L: +$%d<br>", id, "SJ_MOTD_AST", POINTS_ASSIST)
			sz_len += format(sz_temp[sz_len], charsmax(sz_temp) - sz_len, "%L: +$%d<br>", id, "SJ_MOTD_STL", POINTS_STEAL)
			sz_len += format(sz_temp[sz_len], charsmax(sz_temp) - sz_len, "%L: +$%d<br>", id, "SJ_MOTD_GSV", POINTS_GOALSAVE)
			sz_len += format(sz_temp[sz_len], charsmax(sz_temp) - sz_len, "%L: +$%d<br>", id, "SJ_MOTD_HNT", POINTS_HUNT)
			sz_len += format(sz_temp[sz_len], charsmax(sz_temp) - sz_len, "%L: +$%d<br>", id, "SJ_MOTD_PAS", POINTS_PASS)
			sz_len += format(sz_temp[sz_len], charsmax(sz_temp) - sz_len, "%L: -$%d<br>", id, "SJ_MOTD_BLS", abs(POINTS_FAIL))
			sz_len += format(sz_temp[sz_len], charsmax(sz_temp) - sz_len, "%L: +$%d", id, "SJ_MOTD_DHITS",	POINTS_DISHITS)
		}
		case(2):{	
			sz_len += format(sz_temp[sz_len], charsmax(sz_temp) - sz_len, "<body bgcolor=#000000 text=yellow><br>")
			sz_len += format(sz_temp[sz_len], charsmax(sz_temp) - sz_len, 
			"<h2><center><font color=5da130>%L</font></center></h2>",
			id, "SJ_MOTD_HELP_CONTR_TITLE")
			sz_len += format(sz_temp[sz_len], charsmax(sz_temp) - sz_len, "%L<br>", id, "SJ_MOTD_HELP_CONTR_KICK")
			sz_len += format(sz_temp[sz_len], charsmax(sz_temp) - sz_len, "%L<br>", id, "SJ_MOTD_HELP_CONTR_TURBO")
			sz_len += format(sz_temp[sz_len], charsmax(sz_temp) - sz_len, "%L<br>", id, "SJ_MOTD_HELP_CONTR_CURVE")
			sz_len += format(sz_temp[sz_len], charsmax(sz_temp) - sz_len, "%L<br>", id, "SJ_MOTD_HELP_CONTR_UPMENU")
			sz_len += format(sz_temp[sz_len], charsmax(sz_temp) - sz_len, "%L<br>", id, "SJ_MOTD_HELP_CONTR_PASS")
			sz_len += format(sz_temp[sz_len], charsmax(sz_temp) - sz_len, "%L<br>", id, "SJ_MOTD_HELP_CONTR_ADMMENU")
			sz_len += format(sz_temp[sz_len], charsmax(sz_temp) - sz_len, "%L<br>", id, "SJ_MOTD_HELP_CONTR_MULTI")
			sz_len += format(sz_temp[sz_len], charsmax(sz_temp) - sz_len, "%L<br>", id, "SJ_MOTD_HELP_CONTR_1")
			sz_len += format(sz_temp[sz_len], charsmax(sz_temp) - sz_len, "%L", id, "SJ_MOTD_HELP_CONTR_2")

		}
		case(3):{
			sz_len += format(sz_temp[sz_len], charsmax(sz_temp) - sz_len, "<body bgcolor=#000000 text=yellow><br>")
			sz_len += format(sz_temp[sz_len], charsmax(sz_temp) - sz_len, 
			"<h2><center><font color=5da130>%L</font></center></h2>", 
			id, "SJ_MOTD_HELP_CHAT_TITLE")
			sz_len += format(sz_temp[sz_len], charsmax(sz_temp) - sz_len, "%L<br>", id, "SJ_MOTD_HELP_CHAT_STATS")
			sz_len += format(sz_temp[sz_len], charsmax(sz_temp) - sz_len, "%L<br>", id, "SJ_MOTD_HELP_CHAT_SKILLS")
			sz_len += format(sz_temp[sz_len], charsmax(sz_temp) - sz_len, "%L<br>", id, "SJ_MOTD_HELP_CHAT_RESET")
			sz_len += format(sz_temp[sz_len], charsmax(sz_temp) - sz_len, "%L<br>", id, "SJ_MOTD_HELP_CHAT_TOP")
			sz_len += format(sz_temp[sz_len], charsmax(sz_temp) - sz_len, "%L<br>", id, "SJ_MOTD_HELP_CHAT_RANK")
			sz_len += format(sz_temp[sz_len], charsmax(sz_temp) - sz_len, "%L<br>", id, "SJ_MOTD_HELP_CHAT_RANKSTATS")
			sz_len += format(sz_temp[sz_len], charsmax(sz_temp) - sz_len, "%L<br>", id, "SJ_MOTD_HELP_CHAT_CAM")
			sz_len += format(sz_temp[sz_len], charsmax(sz_temp) - sz_len, "%L<br>", id, "SJ_MOTD_HELP_CHAT_DONATE")
			sz_len += format(sz_temp[sz_len], charsmax(sz_temp) - sz_len, "%L<br>", id, "SJ_MOTD_HELP_CHAT_SPEC")
			sz_len += format(sz_temp[sz_len], charsmax(sz_temp) - sz_len, "%L<br>", id, "SJ_MOTD_HELP_CHAT_HELP")
			sz_len += format(sz_temp[sz_len], charsmax(sz_temp) - sz_len, "%L", id, "SJ_MOTD_HELP_CHAT_HELPMENU")	
		}
		case(4):{
			sz_len += format(sz_temp[sz_len], charsmax(sz_temp) - sz_len, "<body bgcolor=#000000 text=yellow><br>")
			sz_len += format(sz_temp[sz_len], charsmax(sz_temp) - sz_len, 
			"<h2><center><font color=5da130>%L</font></center></h2>", 
			id, "SJ_MOTD_HELP_TRICKS_TITLE")
			sz_len += format(sz_temp[sz_len], charsmax(sz_temp) - sz_len, "%L<br>", id, "SJ_MOTD_HELP_TRICKS_BOOST")
			sz_len += format(sz_temp[sz_len], charsmax(sz_temp) - sz_len, "%L<br>", id, "SJ_MOTD_HELP_TRICKS_SLIDE")
			sz_len += format(sz_temp[sz_len], charsmax(sz_temp) - sz_len, "%L<br>", id, "SJ_MOTD_HELP_TRICKS_BALLJUMP")
			sz_len += format(sz_temp[sz_len], charsmax(sz_temp) - sz_len, "%L<br>", id, "SJ_MOTD_HELP_TRICKS_ALIEN")
			sz_len += format(sz_temp[sz_len], charsmax(sz_temp) - sz_len, "%L", id, "SJ_MOTD_HELP_TRICKS_45CURVE")
		}
	}	
	show_motd(id, sz_temp, help_title)
}

public Help(id){
	g_showhelp[id] = true
	if(task_exists(id + 45475)){
		remove_task(id + 45475)
		set_task(13.0, "HelpOff", id + 45475)
	} else {
		UTIL_ScreenFade(id, {0, 0, 0}, 1.5, 13.0, 220, FFADE_OUT)
		set_task(1.5, "HelpOn", id + 45405)
		set_task(13.0, "HelpOff", id + 45475)
	}
}

public HelpOn(id){
	id -= 45405
	
	set_dhudmessage(255, 255, 255, -1.0, 0.1, 0, 3.0, 10.0)
	show_dhudmessage(id, "%L", id, "SJ_HUDHELP")
	set_dhudmessage(255, 255, 255, 0.02, 0.24, 0, 3.0, 10.0)
	show_dhudmessage(id, "%L", id, "SJ_HUDHELP1")
	set_dhudmessage(255, 255, 255, -1.0, 0.8, 0, 3.0, 10.0)
	show_dhudmessage(id, "%L", id, "SJ_HUDHELP2")
	set_dhudmessage(255, 255, 255, -1.0, -1.0, 0, 3.0, 10.0)
	show_dhudmessage(id, "%L", id, "SJ_HUDHELP3")
	set_dhudmessage(255, 255, 255, 0.7, 0.6, 0, 3.0, 10.0)
	show_dhudmessage(id, "%L", id, "SJ_HUDHELP4")
	
	BuyUpgrade(id)
}

public HelpOff(id){
	id -= 45475
	PlayerHelpMenu(id)
	UTIL_ScreenFade(id, {0, 0, 0}, 1.5, 1.0, 220, FFADE_IN)
	g_showhelp[id] = false
}

public Event_Record(id, recordtype){
	if(id && IsUserConnected(id) && !get_pcvar_num(cv_pause) && (GAME_MODE == MODE_GAME || GAME_MODE == MODE_OVERTIME || GAME_MODE == MODE_SHOOTOUT)){
		if(recordtype != DISTANCE){
			MadeRecord[id][recordtype]++
			TempRecord[id][recordtype]++
			new szTeam = get_user_team(id)
			if(T <= szTeam <= CT){
				TeamRecord[szTeam][recordtype]++
			}
		} else {
			MadeRecord[id][recordtype] = g_distshot
		}
		
		if(MadeRecord[id][recordtype] > TopPlayer[1][recordtype]){
			TopPlayer[0][recordtype] = id
			TopPlayer[1][recordtype] = MadeRecord[id][recordtype]
			
			new sz_name[32]
			get_user_name(id, sz_name, charsmax(sz_name))
			format(TopPlayerName[recordtype], 12, "%s", sz_name)
		}
		
		if(recordtype == POSSESSION){
			g_Time[0]++
			return
		}
			
		g_MVP_points[id] = 
		MadeRecord[id][GOAL] 		* MVP_GOAL 	+ 
		MadeRecord[id][ASSIST] 		* MVP_ASSIST 	+ 
		MadeRecord[id][STEAL] 		* MVP_STEAL 	+ 
		MadeRecord[id][GOALSAVE] 	* MVP_GOALSAVE 	+ 
		MadeRecord[id][HUNT] 		* MVP_HUNT 	+ 
		MadeRecord[id][LOSS] 		* MVP_LOSSES
		if(g_MVP_points[id] > g_MVP){
			g_MVP = g_MVP_points[id]
			g_MVPwebId = g_PlayerId[id]
			get_user_name(id, g_MVP_name, charsmax(g_MVP_name))
		}	
		switch(recordtype){
			case GOAL: 	g_Experience[id] += POINTS_GOAL
			case ASSIST: 	g_Experience[id] += POINTS_ASSIST
			case STEAL: 	g_Experience[id] += POINTS_STEAL
			case HUNT: 	g_Experience[id] += POINTS_HUNT
			case PASS: 	g_Experience[id] += POINTS_PASS
			case DISHITS: 	g_Experience[id] += POINTS_DISHITS
			case BALLKILL: 	g_Experience[id] += POINTS_BALLKILL
			case LOSS: 	g_Experience[id] += POINTS_FAIL
			case GOALSAVE: 	g_Experience[id] += POINTS_GOALSAVE
		}
		if(g_Experience[id] < 0)
			g_Experience[id] = 0
		cs_set_user_money(id, g_Experience[id])
		CsSetUserScore(id, g_MVP_points[id], MadeRecord[id][DEATH])
	}
}

/*
+-----------------------+--------------------------------------------------------------------------+
|			| ************************************************************************ |
|	[SPRITES]	| ************************************************************************ |
|			| ************************************************************************ |
+-----------------------+--------------------------------------------------------------------------+
*/

public get_origin_int(index, origin[3])
{
	new Float:FVec[3]

	pev(index,pev_origin,FVec)

	origin[0] = floatround(FVec[0])
	origin[1] = floatround(FVec[1])
	origin[2] = floatround(FVec[2])

	return 1
}

process_death(iAgressor, iVictim)
{
	//server_print("************************* DEATH: %d %d %d %d", iVictim, iAgressor, iWeapon, iHitPlace)

	new iOrigin[3], iOrigin2[3]


	if (!is_user_connected(iVictim)) return

	get_origin_int(iVictim, iOrigin)
	get_origin_int(iAgressor, iOrigin2)


	//fx_headshot(iOrigin)



	// Effects
	fx_invisible(iVictim)
	hiddenCorpse[iVictim] = true

	fx_gib_explode(iOrigin,iOrigin2)
	fx_blood_large(iOrigin,4)
	fx_blood_small(iOrigin,4)
	
	

	//fx_blood_small(iOrigin,8)


	fx_extra_blood(iOrigin)
	//fx_blood_large(iOrigin,2)
	//fx_blood_small(iOrigin,4)
}

fx_gib_explode(origin[3],origin2[3])
{
	new flesh[2]
	flesh[0] = mdl_gib_flesh
	flesh[1] = mdl_gib_meat
	new mult, gibtime = 400 //40 seconds

	mult = 80

	new rDistance = get_distance(origin,origin2) ? get_distance(origin,origin2) : 1
	new rX = ((origin[0]-origin2[0]) * mult) / rDistance
	new rY = ((origin[1]-origin2[1]) * mult) / rDistance
	new rZ = ((origin[2]-origin2[2]) * mult) / rDistance
	new rXm = rX >= 0 ? 1 : -1
	new rYm = rY >= 0 ? 1 : -1
	new rZm = rZ >= 0 ? 1 : -1

	// Gib explosions

	// Head
	message_begin(MSG_BROADCAST,SVC_TEMPENTITY)
	write_byte(TE_MODEL)
	write_coord(origin[0])
	write_coord(origin[1])
	write_coord(origin[2]+40)
	write_coord(rX + (rXm * random_num(0,80)))
	write_coord(rY + (rYm * random_num(0,80)))
	write_coord(rZ + (rZm * random_num(80,200)))
	write_angle(random_num(0,360))
	write_short(mdl_gib_head)
	write_byte(0) // bounce
	write_byte(gibtime) // life
	message_end()

	// Parts
	for(new i = 0; i < 4; i++) {
		message_begin(MSG_BROADCAST,SVC_TEMPENTITY)
		write_byte(TE_MODEL)
		write_coord(origin[0])
		write_coord(origin[1])
		write_coord(origin[2])
		write_coord(rX + (rXm * random_num(0,80)))
		write_coord(rY + (rYm * random_num(0,80)))
		write_coord(rZ + (rZm * random_num(80,200)))
		write_angle(random_num(0,360))
		write_short(flesh[random_num(0,1)])
		write_byte(0) // bounce
		write_byte(gibtime) // life
		message_end()
	}


		// Spine
		message_begin(MSG_BROADCAST,SVC_TEMPENTITY)
		write_byte(TE_MODEL)
		write_coord(origin[0])
		write_coord(origin[1])
		write_coord(origin[2]+30)
		write_coord(rX + (rXm * random_num(0,80)))
		write_coord(rY + (rYm * random_num(0,80)))
		write_coord(rZ + (rZm * random_num(80,200)))
		write_angle(random_num(0,360))
		write_short(mdl_gib_spine)
		write_byte(0) // bounce
		write_byte(gibtime) // life
		message_end()

		// Lung
		for(new i = 0; i <= 1; i++) {
			message_begin(MSG_BROADCAST,SVC_TEMPENTITY)
			write_byte(TE_MODEL)
			write_coord(origin[0])
			write_coord(origin[1])
			write_coord(origin[2]+10)
			write_coord(rX + (rXm * random_num(0,80)))
			write_coord(rY + (rYm * random_num(0,80)))
			write_coord(rZ + (rZm * random_num(80,200)))
			write_angle(random_num(0,360))
			write_short(mdl_gib_lung)
			write_byte(0) // bounce
			write_byte(gibtime) // life
			message_end()
		}

		//Legs
		for(new i = 0; i <= 1; i++) {
			message_begin(MSG_BROADCAST,SVC_TEMPENTITY)
			write_byte(TE_MODEL)
			write_coord(origin[0])
			write_coord(origin[1])
			write_coord(origin[2]-10)
			write_coord(rX + (rXm * random_num(0,80)))
			write_coord(rY + (rYm * random_num(0,80)))
			write_coord(rZ + (rZm * random_num(80,200)))
			write_angle(random_num(0,360))
			write_short(mdl_gib_legbone)
			write_byte(0) // bounce
			write_byte(gibtime) // life
			message_end()
		}
	
	
	message_begin(MSG_BROADCAST,SVC_TEMPENTITY)
	write_byte(TE_BLOODSPRITE)
	write_coord(origin[0])
	write_coord(origin[1])
	write_coord(origin[2]+20)
	write_short(spr_blood_spray)
	write_short(spr_blood_drop)
	write_byte(247) // color index
	write_byte(10) // size
	message_end()
}
public Msg_ClCorpse()
{
	client_print(0, print_chat, "WTF")
	//If there is not 12 args something is wrong
	if (get_msg_args() != 12) return PLUGIN_CONTINUE

	//Arg 12 is the player id the corpse is for
	new id = get_msg_arg_int(12)

	//If the corpse should be hidden block this message
	if (hiddenCorpse[id]) return PLUGIN_HANDLED

	return PLUGIN_CONTINUE
}

fx_invisible(id)
{
	set_pev(id, pev_renderfx, kRenderFxNone)
	set_pev(id, pev_rendermode, kRenderTransAlpha)
	set_pev(id, pev_renderamt, 0.0)
}
process_damage(iAgressor, iVictim)
{
	
	new iOrigin[3], iOrigin2[3]
	get_origin_int(iVictim,iOrigin)
	get_origin_int(iAgressor,iOrigin2)

	fx_blood(iOrigin,iOrigin2,7)
	fx_blood_small(iOrigin,8)
	
		fx_blood(iOrigin,iOrigin2,7)
		fx_blood(iOrigin,iOrigin2,7)
		fx_blood(iOrigin,iOrigin2,7)
		fx_blood_small(iOrigin,4)

}
fx_extra_blood(origin[3])
{
	new x, y, z

	for(new i = 0; i < 3; i++) {
		x = random_num(-15,15)
		y = random_num(-15,15)
		z = random_num(-20,25)
		for(new j = 0; j < 2; j++) {
			message_begin(MSG_BROADCAST,SVC_TEMPENTITY)
			write_byte(TE_BLOODSPRITE)
			write_coord(origin[0]+(x*j))
			write_coord(origin[1]+(y*j))
			write_coord(origin[2]+(z*j))
			write_short(spr_blood_spray)
			write_short(spr_blood_drop)
			write_byte(247) // color index
			write_byte(15) // size
			message_end()
		}
	}
}
fx_headshot(origin[3])
{

	new Sprays = 8
	

	message_begin(MSG_BROADCAST,SVC_TEMPENTITY)
	write_byte(TE_BLOODSPRITE)
	write_coord(origin[0])
	write_coord(origin[1])
	write_coord(origin[2]+40)
	write_short(spr_blood_spray)
	write_short(spr_blood_drop)
	write_byte(247) // color index
	write_byte(15) // size
	message_end()

	// Blood sprays
	for (new i = 0; i < Sprays; i++) {
		message_begin(MSG_BROADCAST,SVC_TEMPENTITY)
		write_byte(TE_BLOODSTREAM)
		write_coord(origin[0])
		write_coord(origin[1])
		write_coord(origin[2]+40)
		write_coord(random_num(-30,30)) // x
		write_coord(random_num(-30,30)) // y
		write_coord(random_num(80,300)) // z
		write_byte(247) // color
		write_byte(random_num(100,200)) // speed
		message_end()
	}
}

fx_blood(origin[3],origin2[3],HitPlace)
{
	//Crash Checks
	if (HitPlace < 0 || HitPlace > 7) HitPlace = 0
	new rDistance = get_distance(origin,origin2) ? get_distance(origin,origin2) : 1

	new rX = ((origin[0]-origin2[0]) * 300) / rDistance
	new rY = ((origin[1]-origin2[1]) * 300) / rDistance
	new rZ = ((origin[2]-origin2[2]) * 300) / rDistance

	message_begin(MSG_BROADCAST,SVC_TEMPENTITY)
	write_byte(TE_BLOODSTREAM)
	write_coord(origin[0]+Offset[HitPlace][0])
	write_coord(origin[1]+Offset[HitPlace][1])
	write_coord(origin[2]+Offset[HitPlace][2])
	write_coord(rX) // x
	write_coord(rY) // y
	write_coord(rZ) // z
	write_byte(247) // color
	write_byte(random_num(100,200)) // speed
	message_end()
}

fx_bleed(origin[3])
{
	// Blood spray
	message_begin(MSG_BROADCAST,SVC_TEMPENTITY)
	write_byte(TE_BLOODSTREAM)
	write_coord(origin[0])
	write_coord(origin[1])
	write_coord(origin[2]+10)
	write_coord(random_num(-360,360)) // x
	write_coord(random_num(-360,360)) // y
	write_coord(-10) // z
	write_byte(BLOOD_STREAM_RED) // color
	write_byte(random_num(50,100)) // speed
	message_end()
}

fx_blood_small(origin[3],num)
{

	// Write Small splash decal
	for (new j = 0; j < num; j++) {
		message_begin(MSG_BROADCAST,SVC_TEMPENTITY)
		write_byte(TE_WORLDDECAL)
		write_coord(origin[0]+random_num(-100,100))
		write_coord(origin[1]+random_num(-100,100))
		write_coord(1604 - 36)
		write_byte(blood_small_red[random_num(0,8 - 1)]) // index
		message_end()
	}
}

fx_blood_large(origin[3],num)
{
	// Write Large splash decal
	for (new i = 0; i < num; i++) {
		message_begin(MSG_BROADCAST,SVC_TEMPENTITY)
		write_byte(TE_WORLDDECAL)
		write_coord(origin[0]+random_num(-50,50))
		write_coord(origin[1]+random_num(-50,50))
		write_coord(1604 - 36)
		write_byte(blood_large_red[random_num(0,2 - 1)]) // index
		message_end()
	}
}

TerminatePlayer(id, mascot, team, Float:dmg, color[]){
	new orig[3], Float:morig[3], iMOrig[3], x
	
	get_user_origin(id, orig)
	entity_get_vector(mascot, EV_VEC_origin, morig)
	
	for(x = 0; x < 3; x++)
		iMOrig[x] = floatround(morig[x])
	
	fakedamage(id, "Alien", dmg, 1)

	new loc = (team == 1 ? 0 : 0)
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
	write_byte(0)
	write_coord(iMOrig[0])		// (start positionx) 
	write_coord(iMOrig[1])		// (start positiony)
	write_coord(iMOrig[2] + loc)	// (start positionz)
	write_coord(orig[0])		// (end positionx)
	write_coord(orig[1])		// (end positiony)
	write_coord(orig[2])		// (end positionz) 
	write_short(spr_fxbeam) 	// (sprite index) 
	write_byte(0) 			// (starting frame) 
	write_byte(0) 			// (frame rate in 0.1's) 
	write_byte(7) 			// (life in 0.1's) 
	write_byte(120) 		// (line width in 0.1's) 
	write_byte(25) 			// (noise amplitude in 0.01's) 
	write_byte(color[0])		// r
	write_byte(color[1])		// g
	write_byte(color[2])		// b
	write_byte(220)			// brightness
	write_byte(1) 			// (scroll speed in 0.1's)
	message_end()
}

glow(id, r, g, b){
	set_rendering(id, kRenderFxGlowShell, r, g, b, kRenderNormal, 255)
	entity_set_float(id, EV_FL_renderamt, 1.0)
}

beam(life, ball){
	if(!task_exists(-77002 + ball)){
		set_task(9.9, "Done_Handler", -77002 + ball)
		message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
		write_byte(22)			// TE_BEAMFOLLOW
		write_short(ball)		// ball
		write_short(spr_beam)		// laserbeam
		write_byte(life)		// life
		write_byte(3)			// width
		write_byte(TeamColors[0][0]) 	// r
		write_byte(TeamColors[0][1]) 	// g
		write_byte(TeamColors[0][2]) 	// b
		write_byte(40)			// brightness
		message_end()
	}
}

flameWave(myorig[3], team){
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY, myorig) 
	write_byte(21) 
	write_coord(myorig[0]) 
	write_coord(myorig[1]) 
	write_coord(myorig[2] + 16) 
	write_coord(myorig[0]) 
	write_coord(myorig[1]) 
	write_coord(myorig[2] + 500) 
	write_short(spr_fire)
	write_byte(0) 			// startframe 
	write_byte(0) 			// framerate 
	write_byte(15) 			// life 2
	write_byte(50) 			// width 16 
	write_byte(10) 			// noise 
	write_byte(TeamColors[team][0]) // r 
	write_byte(TeamColors[team][1]) // g 
	write_byte(TeamColors[team][2]) // b 
	write_byte(255) 		// brightness
	write_byte(1 / 10) 		// speed 
	message_end() 
	
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY, myorig) 
	write_byte(21) 
	write_coord(myorig[0]) 
	write_coord(myorig[1]) 
	write_coord(myorig[2] + 16) 
	write_coord(myorig[0]) 
	write_coord(myorig[1]) 
	write_coord(myorig[2] + 500) 
	write_short(spr_fire)
	write_byte(0) 				// startframe 
	write_byte(0) 				// framerate 
	write_byte(10) 				// life 2
	write_byte(70) 				// width 16 
	write_byte(10) 				// noise 
	write_byte(TeamColors[team][0]) 	// r 
	write_byte(TeamColors[team][1] + 50) 	// g 
	write_byte(TeamColors[team][2]) 	// b 
	write_byte(200) 			// brightness 
	write_byte(1 / 9) 			// speed 
	message_end() 
	
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY, myorig)
	write_byte(21)
	write_coord(myorig[0])
	write_coord(myorig[1])
	write_coord(myorig[2] + 16) 
	write_coord(myorig[0]) 
	write_coord(myorig[1]) 
	write_coord(myorig[2] + 500) 
	write_short(spr_fire)
	write_byte(0) 				// startframe 
	write_byte(0) 				// framerate 
	write_byte(10) 				// life 2
	write_byte(90) 				// width 16 
	write_byte(10) 				// noise 
	write_byte(TeamColors[team][0]) 	// r 
	write_byte(TeamColors[team][1] + 100) 	// g 
	write_byte(TeamColors[team][2]) 	// b 	
	write_byte(200) 			// brightness 
	write_byte(1 / 8) 			// speed 
	message_end() 
	
	//Explosion2 
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY) 
	write_byte(12) 
	write_coord(myorig[0]) 
	write_coord(myorig[1]) 
	write_coord(myorig[2])
	write_byte(80) 	// byte (scale in 0.1's) 188 
	write_byte(10) 	// byte (framerate) 
	message_end() 
	
	//TE_Explosion 
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY) 
	write_byte(3) 
	write_coord(myorig[0]) 
	write_coord(myorig[1]) 
	write_coord(myorig[2])
	write_short(spr_fire) 
	write_byte(65) 	// byte (scale in 0.1's) 188 
	write_byte(10) 	// byte (framerate) 
	write_byte(0) 	// byte flags 
	message_end() 
	
	//Smoke 
	message_begin(MSG_BROADCAST,SVC_TEMPENTITY, myorig) 
	write_byte(5)
	write_coord(myorig[0]) 
	write_coord(myorig[1]) 
	write_coord(myorig[2]) 
	write_short(spr_smoke)
	write_byte(50)
	write_byte(10)
	message_end()
	
	return PLUGIN_HANDLED
}

stock get_wall_angles(id, Float:fReturnAngles[3], Float:fNormal[3]){
	new Float:fOrigin[3]
	pev(id, pev_origin, fOrigin)
	
	new Float:fAngles[3]
	pev(id, pev_v_angle, fAngles)
	angle_vector(fAngles, ANGLEVECTOR_FORWARD, fAngles)
	
	fAngles[0] = fAngles[0] * 9999.0
	fAngles[1] = fAngles[1] * 9999.0
	fAngles[2] = fAngles[2] * 9999.0
	
	new Float:fEndPos[3]
	fEndPos[0] = fAngles[0] + fOrigin[0]
	fEndPos[1] = fAngles[1] + fOrigin[1]
	fEndPos[2] = fAngles[2] + fOrigin[2]
	
	new ptr = create_tr2()	
	engfunc(EngFunc_TraceLine, fOrigin, fEndPos, IGNORE_MISSILE | IGNORE_MONSTERS | IGNORE_GLASS, id, ptr)
	
	new Float:vfNormal[3]
	get_tr2(ptr, TR_vecPlaneNormal, vfNormal)
	
	vector_to_angle(vfNormal, fReturnAngles)
	
	xs_vec_copy(vfNormal, fNormal)
}

public sprite_portal(id){
	new Float:fWallAngles[3], Float:fNormal[3]
	get_wall_angles(id, fWallAngles, fNormal)
	
	new Float:fAimOrigin[3]
	pev(id, pev_origin, fAimOrigin)
	
	new Float:fInvalidOriginStart[3], Float:fInvalidOriginEnd[3]
	xs_vec_mul_scalar(fNormal, 4.0, fInvalidOriginStart)
	xs_vec_mul_scalar(fNormal, 20.0, fInvalidOriginEnd)
	xs_vec_add(fAimOrigin, fInvalidOriginStart, fInvalidOriginStart)
	xs_vec_add(fAimOrigin, fInvalidOriginEnd, fInvalidOriginEnd)
	new iInvalidOriginStart[3], iInvalidOriginEnd[3]
	FVecIVec(fInvalidOriginStart, iInvalidOriginStart)
	FVecIVec(fInvalidOriginEnd, iInvalidOriginEnd)
	
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
	write_byte(TE_SPRITETRAIL)
	write_coord(iInvalidOriginStart[0])
	write_coord(iInvalidOriginStart[1])
	write_coord(iInvalidOriginStart[2])
	write_coord(iInvalidOriginEnd[0])
	write_coord(iInvalidOriginEnd[1])
	write_coord(iInvalidOriginEnd[2])
	write_short(spr_porange)
	write_byte(25)
	write_byte(1)
	write_byte(1)
	write_byte(20)
	write_byte(14)
	message_end()
}

public ShowPassSprite(id){
	id -= 3122
	
	remove_task(id - 4122)
	set_task(0.2, "RemovePassSprite", id - 4122)
	
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
	write_byte(124)
	write_byte(id)
	write_coord(45)
	write_short(spr_pass[get_user_team(id)])
	write_short(100)
	message_end()
}

public RemovePassSprite(id){
	id += 4122
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
   	write_byte(125)
   	write_byte(id)
   	message_end()
}

public FX_ScreenShake(id)
{
	/*message_begin( MSG_ONE_UNRELIABLE, msg_screenshake, .player = id );
	write_short( 500 );  // --| Shake amount.
	write_short( 500 );  // --| Shake lasts this long.
	write_short( 100 );  // --| Shake noise frequency.
	message_end ();*/
	
	message_begin(MSG_ONE, msg_screenshake, {0,0,0}, id)
	write_short(255<< 15) //ammount 
	write_short(10 << 10) //lasts this long 
	write_short(255<< 14) //frequency 
	message_end() 
}

/*
+-----------------------+--------------------------------------------------------------------------+
|			| ************************************************************************ |
|     [nVault-PART]	| ************************************************************************ |
|			| ************************************************************************ |
+-----------------------+--------------------------------------------------------------------------+
*/

public save_stats(id){
	if(contain(g_authid[id], "LAN") != -1 || contain(g_authid[id], "PEND") != -1 
	|| contain(g_authid[id], "STEAM") == -1 || g_authid[id][0] == EOS)
		return PLUGIN_HANDLED
	
	new sz_data[1024], sz_key[45]
	new sz_team = get_user_team(id)
	
	new szKey[128], x
	
	for(new i = 0; i < 64; i++){
		if(equal(g_list_authid[i], g_authid[id]))
			break
		if(g_list_authid[i][0] == EOS){
			format(g_list_authid[i], 35, "%s", g_authid[id])
			break
		}
	}
	
	for(x = 1; x <= RECORDS; x++){
		format(szKey, charsmax(szKey), "%s_RECORDS@%s", g_authid[id], RecordTitles[x])
		TrieSetCell(gTrieStats, szKey, MadeRecord[id][x])
	}
	
	format(szKey, charsmax(szKey), "%s_MVP_POINTS", g_authid[id])
	TrieSetCell(gTrieStats, szKey, g_MVP_points[id])
	
	format(szKey, charsmax(szKey), "%s_EXPERIENCE", g_authid[id])
	TrieSetCell(gTrieStats, szKey, g_Experience[id])
	
	format(szKey, charsmax(szKey), "%s_CREDITS", g_authid[id])
	TrieSetCell(gTrieStats, szKey, g_Credits[id])
	
	for(x = 1; x <= UPGRADES; x++){
		format(szKey, charsmax(szKey), "%s_SKILLS@%s", g_authid[id], UpgradeTitles[x])
		TrieSetCell(gTrieStats, szKey, PlayerUpgrades[id][x])
	}
	
	format(szKey, charsmax(szKey), "%s_MATCH_ID", g_authid[id])
	TrieSetCell(gTrieStats, szKey, gMatchId)
	
	format(szKey, charsmax(szKey), "%s_PLAYER_ID", g_authid[id])
	TrieSetCell(gTrieStats, szKey, g_PlayerId[id])
	
	if(T <= sz_team <= CT){
		format(szKey, charsmax(szKey), "%s_TEAM_ID", g_authid[id])
		TrieSetCell(gTrieStats, szKey, TeamId[sz_team])
	
		format(szKey, charsmax(szKey), "%s_RINGER", g_authid[id])
		TrieSetCell(gTrieStats, szKey, (TeamId[sz_team]>0 && TeamId[sz_team]!=g_userClanId[id])?1:0)
	}
	return PLUGIN_HANDLED
}

public load_stats(id){
	if(contain(g_authid[id], "LAN") != -1 || contain(g_authid[id], "PEND") != -1 
	|| contain(g_authid[id], "STEAM") == -1 || g_authid[id][0] == EOS)
		return PLUGIN_HANDLED
	
	new sz_data[128]
	new sz_key[45]
	new sz_temp[64]
	
	
	new szKey[128], x
	
	format(szKey, charsmax(szKey), "%s_MATCH_ID", g_authid[id])
	if(!TrieKeyExists(gTrieStats, szKey)){
		loadDefaultSkills(id)
		return PLUGIN_HANDLED
	}
	
	for(x = 1; x <= RECORDS; x++){
		format(szKey, charsmax(szKey), "%s_RECORDS@%s", g_authid[id], RecordTitles[x])
		TrieGetCell(gTrieStats, szKey, MadeRecord[id][x])
	}
	
	format(szKey, charsmax(szKey), "%s_MVP_POINTS", g_authid[id])
	TrieGetCell(gTrieStats, szKey, g_MVP_points[id])
	
	format(szKey, charsmax(szKey), "%s_EXPERIENCE", g_authid[id])
	TrieGetCell(gTrieStats, szKey, g_Experience[id])
	
	format(szKey, charsmax(szKey), "%s_CREDITS", g_authid[id])
	TrieGetCell(gTrieStats, szKey, g_Credits[id])
	
	for(x = 1; x <= UPGRADES; x++){
		format(szKey, charsmax(szKey), "%s_SKILLS@%s", g_authid[id], UpgradeTitles[x])
		if(!TrieGetCell(gTrieStats, szKey, PlayerUpgrades[id][x])){
			loadDefaultSkills(id)
			break
		}
	}

	if(IsUserAlive(id)){
		set_speedchange(id)
	}
	
	return PLUGIN_HANDLED
}

public saveDefaultSkills(id){
	if(sql_error[0] != EOS || !sql_tuple){ 
		log_amx("[SJ] - No connection to SQL server! Error: %s", sql_error)
		return PLUGIN_HANDLED
	}
	if(contain(g_authid[id], "LAN") != -1 || contain(g_authid[id], "PEND") != -1 || contain(g_authid[id], "STEAM") == -1 || g_authid[id][0] == EOS){
		ColorChat(id, RED, "^4[SJ] ^1- ^3%L", id, "SJ_STEAMUNA")
		return PLUGIN_HANDLED
	}
	
	new sz_credits = 0
	for(new i = 1; i <= UPGRADES; i++){
		sz_credits += (PlayerUpgrades[id][i]==UpgradeMax[i]?(PlayerUpgrades[id][i] + 1):PlayerUpgrades[id][i])
	}
	if(sz_credits > STARTING_CREDITS){
		ColorChat(id, RED, "^4[SJ] ^1- ^3Currently used amount of credits is more than %d. Default skill can not be saved.", STARTING_CREDITS)	
		return PLUGIN_HANDLED
	}
	new sz_len = 0
	new sz_temp[512]
	
	sz_len += format(sz_temp[sz_len], charsmax(sz_temp) - sz_len, "UPDATE sj_players SET ")
	for(new i = 1; i <= UPGRADES; i++){
		PlayerDefaultUpgrades[id][i] = PlayerUpgrades[id][i]
		sz_len += format(sz_temp[sz_len], charsmax(sz_temp) - sz_len, "%s%s=%d", i==1?"":",", UpgradeTitles[i], PlayerDefaultUpgrades[id][i])
	}
	sz_len += format(sz_temp[sz_len], charsmax(sz_temp) - sz_len, " WHERE ID=%d", g_PlayerId[id])
	
	ColorChat(id, RED, "^4[SJ] ^1- Default skills have been saved.")
	
	SQL_ThreadQuery(sql_tuple, "QueryHandle", sz_temp)
	
	
	return PLUGIN_HANDLED
}

public loadDefaultSkills(id){
	ResetSkills(id)
	
	g_Credits[id] -= STARTING_CREDITS
	
	for(new i = 1; i <= UPGRADES; i++){
		PlayerUpgrades[id][i] = PlayerDefaultUpgrades[id][i]
	}
	
	if(IsUserAlive(id)){
		set_speedchange(id)
	}
}

/*
+-----------------------+--------------------------------------------------------------------------+
|			| ************************************************************************ |
|      [SQL-PART]	| ************************************************************************ |
|			| ************************************************************************ |
+-----------------------+--------------------------------------------------------------------------+
*/

public sql_connect(){
	if(sql_host[0] == EOS){
		return PLUGIN_HANDLED	
	}
	
	sql_tuple = SQL_MakeDbTuple(sql_host, sql_user, sql_pass, sql_db)

	new ErrorCode, Handle:SqlConnection = SQL_Connect(sql_tuple, ErrorCode, sql_error, charsmax(sql_error))
	if(SqlConnection == Empty_Handle || !sql_tuple || ErrorCode != 0 || sql_error[0] != EOS){
		log_amx("[SJ] -  Could not connect to SQL-database:^nHost: %s^nUser: %s^nDatabase: %s", sql_host, sql_user, sql_db)
		
		return PLUGIN_HANDLED
	}
	sql_getServerInfo()
	sql_getTopPlayers()
/*	NEED TO REMAKE PROCEDURES FOR CREATING ORIGINAL TABLES
----------------------------------------------------------------------------------------------------

	new sz_temp[1024], sz_len, i

	sz_len += format(sz_temp[sz_len], charsmax(sz_temp) - sz_len, 
	"CREATE TABLE IF NOT EXISTS %s (SERVER_IP CHAR(32),SERVERNAME CHAR(64),PASSWORD CHAR(64), START_TIME INT,CRYPT CHAR(64),PLAYERS INT, MAXPLAYERS INT", 
	sql_server_table)
	
	while(i++ < 32){
		sz_len += format(sz_temp[sz_len], charsmax(sz_temp) - sz_len, ",STEAM_%d CHAR(36)", i)
	}
	sz_len += format(sz_temp[sz_len], charsmax(sz_temp) - sz_len, ")")

	SQL_ThreadQuery(sql_tuple, "QueryHandle", sz_temp)
	
// -------------------------------------------------------------------------------------------------
	sz_len = 0
	
	format(sz_temp, charsmax(sz_temp), "")
	
	sz_len += format(sz_temp[sz_len], charsmax(sz_temp) - sz_len, 
	"CREATE TABLE IF NOT EXISTS sj_players (ID INT, STEAM_ID CHAR(36),STEAM_ID_64 CHAR(36), NAME CHAR(32), PRIMARY KEY (ID)")
	
	for(i = 1; i <= RECORDS; i++)
		sz_len += format(sz_temp[sz_len], charsmax(sz_temp) - sz_len, ",`%s` INT", RecordTitles[i])
	sz_len += format(sz_temp[sz_len], charsmax(sz_temp) - sz_len, ")")

	SQL_ThreadQuery(sql_tuple, "QueryHandle", sz_temp)
		
// -------------------------------------------------------------------------------------------------
	sz_len = 0
	
	format(sz_temp, charsmax(sz_temp), "")
	
	sz_len += format(sz_temp[sz_len], charsmax(sz_temp) - sz_len, 
	"CREATE TABLE IF NOT EXISTS %s (PLAYER CHAR(32),STEAM_ID CHAR(36),START_TIME INT,SERVER_IP CHAR(32)", 
	sql_table)
	
	for(i = 1; i <= RECORDS; i++)
		sz_len += format(sz_temp[sz_len], charsmax(sz_temp) - sz_len, ",`%s` INT", RecordTitles[i])
	sz_len += format(sz_temp[sz_len], charsmax(sz_temp) - sz_len, ")")

	SQL_ThreadQuery(sql_tuple, "QueryHandle", sz_temp)
	
// -------------------------------------------------------------------------------------------------
	sz_len = 0
	format(sz_temp, charsmax(sz_temp), "")

	sz_len += format(sz_temp[sz_len], charsmax(sz_temp) - sz_len, 
	"CREATE TABLE IF NOT EXISTS %s (PLAYER CHAR(32),STEAM_ID CHAR(36),USER_IP CHAR(32),START_TIME INT,END_TIME INT,SERVER_IP CHAR(32),TEAM CHAR(32),ROUND INT", 
	sql_mix_table)
	
	for(i = 1; i <= RECORDS; i++)
		sz_len += format(sz_temp[sz_len], charsmax(sz_temp) - sz_len, ",`%s` INT", RecordTitles[i])
	sz_len += format(sz_temp[sz_len], charsmax(sz_temp) - sz_len, ")")

	SQL_ThreadQuery(sql_tuple, "QueryHandle", sz_temp)
	
// -------------------------------------------------------------------------------------------------
	sz_len = 0
	format(sz_temp, charsmax(sz_temp), "")
	
	sz_len += format(sz_temp[sz_len], charsmax(sz_temp) - sz_len, 
	"CREATE TABLE IF NOT EXISTS %s (CLAN CHAR(32),CLAN_SHORT CHAR(32),STEAM_GROUP CHAR(128),STEAM_LEADER CHAR(36),STEAM_COLEADER CHAR(36), WINS INT, LOSSES INT)", 
	sql_cw_table)

	SQL_ThreadQuery(sql_tuple, "QueryHandle", sz_temp)
	
// -------------------------------------------------------------------------------------------------
	sz_len = 0
	format(sz_temp, charsmax(sz_temp), "")

	sz_len += format(sz_temp[sz_len], charsmax(sz_temp) - sz_len, 
	"CREATE TABLE IF NOT EXISTS %s (SERVER_IP CHAR(32),START_TIME INT,END_TIME INT,T_SCORE INT,CT_SCORE INT,T_TEAM CHAR(32),CT_TEAM CHAR(32),TIMELEFT CHAR(16),GAME_MODE INT,ROUND INT",
	sql_live_table)

	sz_len += format(sz_temp[sz_len], charsmax(sz_temp) - sz_len, ")")
	
	SQL_ThreadQuery(sql_tuple, "QueryHandle", sz_temp)
	
*/
	
	return PLUGIN_HANDLED
}

public QueryHandle(FailState,Handle:Query,Error[],Errcode,Data[],DataSize){
	if(FailState == TQUERY_CONNECT_FAILED){
		log_amx("[SJ] - Could not connect to SQL database.  [%d] %s", Errcode, Error)
	} else if(FailState == TQUERY_QUERY_FAILED){
		log_amx("[SJ] - Load Query failed. [%d] %s", Errcode, Error)
	}
	if(Errcode){
		return log_amx("[SJ] - Error on query: %s", Error)
	}

	return PLUGIN_CONTINUE
}

public sql_saveall(){
	if(sql_error[0] != EOS || !sql_tuple){ 
		log_amx("[SJ] - No connection to SQL server! Error: %s", sql_error)
		return PLUGIN_HANDLED
	}
	if(g_saveall){
		return PLUGIN_HANDLED
	}
		
	new sz_temp[1024], i, sz_len, sz_match = g_current_match
	new sz_data[1024]
	new sz_key[45]
	new sz_records[RECORDS + 1], sz_name[32], sz_team[32], sz_ip[32], sz_deaths, sz_ringer,
	sz_currentMatch = gMatchId, sz_teamId, sz_webId, sz_mvpPoints, sz_upgrades[UPGRADES + 1]
	for(i = 1; i <= g_maxplayers; i++){
		if(~IsUserConnected(i) || IsUserBot(i))
			continue
	
		if(T <= get_user_team(i) <= CT)
			save_stats(i)
	}

	new szKey[128], x
	
	for(i = 0; i < 64; i++){
		if(g_list_authid[i][0] == EOS)
			continue
		
		format(szKey, charsmax(szKey), "%s_MATCH_ID", g_list_authid[i])
		if(!TrieGetCell(gTrieStats, szKey, sz_currentMatch)){
			continue
		}
		
		for(x = 1; x <= UPGRADES; x++){
			format(szKey, charsmax(szKey), "%s_SKILLS@%s", g_list_authid[i], UpgradeTitles[x])
			TrieGetCell(gTrieStats, szKey, sz_upgrades[x])
		}
		
		for(x = 1; x <= RECORDS; x++){
			format(szKey, charsmax(szKey), "%s_RECORDS@%s", g_list_authid[i], RecordTitles[x])
			TrieGetCell(gTrieStats, szKey, sz_records[x])
		}
		
		format(szKey, charsmax(szKey), "%s_MVP_POINTS", g_list_authid[i])
		TrieGetCell(gTrieStats, szKey, sz_mvpPoints)
		
		format(szKey, charsmax(szKey), "%s_PLAYER_ID", g_list_authid[i])
		TrieGetCell(gTrieStats, szKey, sz_webId)
		
		format(szKey, charsmax(szKey), "%s_TEAM_ID", g_list_authid[i])
		TrieGetCell(gTrieStats, szKey, sz_teamId)
		
		format(szKey, charsmax(szKey), "%s_RINGER",g_list_authid[i])
		TrieGetCell(gTrieStats, szKey, sz_ringer)
		
		sz_len += format(sz_temp[sz_len], charsmax(sz_temp) - sz_len, 
		"INSERT INTO sj_stats (MATCH_ID, PLAYER_ID, TEAM_ID, RINGER, WIN, LOSE, MVP")
					
		for(x = 1; x <= RECORDS; x++){
			sz_len += format(sz_temp[sz_len], charsmax(sz_temp) - sz_len, ", `%s`", RecordTitles[x])
		}
			
		for(x = 1; x <= UPGRADES; x++){
			sz_len += format(sz_temp[sz_len], charsmax(sz_temp) - sz_len, ", `SKL_%s`", UpgradeTitles[x])
		}
		sz_len += format(sz_temp[sz_len], charsmax(sz_temp) - sz_len, ") VALUES (%d,%d,%d,%d,%d,%d,%d", 
		sz_currentMatch, sz_webId, sz_teamId, sz_ringer, (TeamId[winner]==sz_teamId && sz_teamId != 0)?1:0, (TeamId[winner]==sz_teamId && sz_teamId != 0)?0:1, sz_mvpPoints)
					
		for(x = 1; x <= RECORDS; x++){
			sz_len += format(sz_temp[sz_len], charsmax(sz_temp) - sz_len, ",%d", sz_records[x])
		}
		for(x = 1; x <= UPGRADES; x++){
			sz_len += format(sz_temp[sz_len], charsmax(sz_temp) - sz_len, ",%d", sz_upgrades[x])
		}
		sz_len += format(sz_temp[sz_len], charsmax(sz_temp) - sz_len, ")")		
			
		SQL_ThreadQuery(sql_tuple, "QueryHandle", sz_temp)

		format(sz_temp, charsmax(sz_temp), "")
		sz_len = 0
		
		format(g_list_authid[i], 35, "")
		g_list_authid[i][0] = EOS
	}
	
	sql_updateMatch()
	
	format(sz_temp, charsmax(sz_temp), "UPDATE sj_matches SET MVP_PLAYER_ID = %d, DATE_END = NOW(), TIMELEFT = 0, GAMEROUND = %d WHERE ID = %d", g_MVPwebId, GAME_MODE + 10 * ROUND, sz_currentMatch)
	SQL_ThreadQuery(sql_tuple, "QueryHandle", sz_temp)

	//if(!task_exists(-1313))
		//set_task(3.0, "Task_Query", -1313, sz_temp, charsmax(sz_temp))

	if(g_GK[T] && IsUserConnected(g_GK[T]) && g_PlayerId[g_GK[T]]){
		format(sz_temp, charsmax(sz_temp), "UPDATE sj_players SET LAST_GK = NOW() WHERE ID = %d", g_PlayerId[g_GK[T]])
		SQL_ThreadQuery(sql_tuple, "QueryHandle", sz_temp)
		g_GK_immunity[g_GK[T]] = true
	}
	
	if(g_GK[CT] && IsUserConnected(g_GK[CT]) && g_PlayerId[g_GK[CT]]){
		format(sz_temp, charsmax(sz_temp), "UPDATE sj_players SET LAST_GK = NOW() WHERE ID = %d", g_PlayerId[g_GK[CT]])
		SQL_ThreadQuery(sql_tuple, "QueryHandle", sz_temp)
		g_GK_immunity[g_GK[CT]] = true
	}
	
	format(sz_temp, charsmax(sz_temp), "UPDATE sj_teams SET WIN = WIN + 1, POINTS = POINTS + %d WHERE ID = %d", ROUND==1?2:1, winner==T?TeamId[T]:TeamId[CT])
	SQL_ThreadQuery(sql_tuple, "QueryHandle", sz_temp)
	
	format(sz_temp, charsmax(sz_temp), "UPDATE sj_teams SET LOSE = LOSE + 1, POINTS = POINTS + %d WHERE ID = %d", ROUND==1?0:1, winner==T?TeamId[CT]:TeamId[T])
	SQL_ThreadQuery(sql_tuple, "QueryHandle", sz_temp)

	g_saveall = 1
	
	if(!get_pcvar_num(cv_chat)){
		set_pcvar_num(cv_chat, 1)
		new sz_admname[32]
		get_user_name(0, sz_admname, charsmax(sz_admname))
		ColorChat(0, GREEN, "^4[SJ] ^1- ^1Global chat is ^4ON! ^1(ADMIN: %s)", sz_admname)
	}
	ColorChat(0, RED, "^4[SJ] ^1- ^3[!] ^1Check out your stats at ^4https://sj-pro.com")
	
	TrieClear(gTrieStats)
	
	return PLUGIN_HANDLED
}

public Task_Query(sz_temp[]){
	SQL_ThreadQuery(sql_tuple, "QueryHandle", sz_temp)
}
public sql_getPlayerInfo(id){
	if(sql_error[0] != EOS || !sql_tuple){ 
		log_amx("[SJ] - No connection to SQL server! Error: %s", sql_error)
		return PLUGIN_HANDLED
	}
	if(contain(g_authid[id], "LAN") != -1 || contain(g_authid[id], "PEND") != -1 || contain(g_authid[id], "STEAM") == -1 || g_authid[id][0] == EOS){
		ColorChat(id, RED, "^4[SJ] ^1- ^3%L", id, "SJ_STEAMUNA")
		return PLUGIN_HANDLED
	}
	g_PlayerId[id] = -1
	new sz_temp[2048], Data[1]
	Data[0] = id
	
	format(sz_temp, charsmax(sz_temp), "SELECT sj_players.*, a.TAG, b.TAG as NATIONAL_TAG FROM sj_players LEFT OUTER JOIN sj_teams a ON a.ID = sj_players.TEAM_ID LEFT OUTER JOIN sj_teams b ON b.ID = sj_players.NATIONAL_TEAM_ID WHERE sj_players.STEAM_ID = '%s'", g_authid[id])
	SQL_ThreadQuery(sql_tuple, "q_getPlayerInfo", sz_temp, Data, 1)
	
	
	return PLUGIN_HANDLED
}

public q_getPlayerInfo(FailState,Handle:Query,Error[],Errcode,Data[],DataSize){
	if(FailState == TQUERY_CONNECT_FAILED)
		log_amx("[SJ] - Could not connect to SQL database.  [%d] %s", Errcode, Error)	
	else if(FailState == TQUERY_QUERY_FAILED)
		log_amx("[SJ] - Load Query failed. [%d] %s", Errcode, Error)
	if(Errcode)	
		return log_amx("[SJ] - Error on query: %s", Error)
	
	new sz_temp[1024]
	new id = Data[0]
	if(SQL_NumResults(Query)){
		if(SQL_ReadResult(Query, SQL_FieldNameToNum(Query, "BANNED")) == 1){
			server_cmd("amx_ban #%d %d ^" Banned by sj-pro.com.^"", get_user_userid(id), 0)
			client_cmd(id, "disconnect")
			return PLUGIN_HANDLED
		}
		
		// Team info
		g_PlayerId[id] = SQL_ReadResult(Query, SQL_FieldNameToNum(Query, "ID"))
		g_userClanId[id] = SQL_ReadResult(Query, SQL_FieldNameToNum(Query, "TEAM_ID"))
		SQL_ReadResult(Query, SQL_FieldNameToNum(Query, "TAG"), g_userClanName[id], 31)
		
		// National team info
		g_userNationalId[id] = SQL_ReadResult(Query, SQL_FieldNameToNum(Query, "NATIONAL_TEAM_ID"))
		SQL_ReadResult(Query, SQL_FieldNameToNum(Query, "NATIONAL_TAG"), g_userNationalName[id], 31)
		
		// Skills
		// add check for skills in curr. match?
		for(new i = 1; i <= UPGRADES; i++){
			PlayerDefaultUpgrades[id][i] = SQL_ReadResult(Query, SQL_FieldNameToNum(Query, UpgradeTitles[i]))
		}
		
		load_stats(id)
		/*if(GAME_MODE == MODE_PREGAME){
			loadDefaultSkills(id)
		} else {
			// set current match skills
		}*/
		if(g_userCountry_2[id][0] != EOS){
			format(sz_temp, charsmax(sz_temp), "UPDATE sj_players SET IP = '%s', COUNTRY = '%s', COUNTRY_2 = LOWER('%s'), COUNTRY_3 = '%s', CITY = '%s', LAST_JOIN_TIME = NOW() WHERE ID = %d", 
			g_userip[id], g_userCountry[id], g_userCountry_2[id], g_userCountry_3[id], g_userCity[id], g_PlayerId[id])
		} else {
			format(sz_temp, charsmax(sz_temp), "UPDATE sj_players SET IP = '%s', LAST_JOIN_TIME = NOW() WHERE ID = %d",
			g_userip[id], g_PlayerId[id])
		}
		
		SQL_ThreadQuery(sql_tuple, "QueryHandle", sz_temp)
	} else {
		format(sz_temp, charsmax(sz_temp), "INSERT INTO sj_players (STEAM_ID) VALUES ('%s')", g_authid[id])
		SQL_ThreadQuery(sql_tuple, "QueryHandle", sz_temp)
		sql_getPlayerInfo(id)
	}
	
	return PLUGIN_HANDLED
}

public sql_getServerInfo(){
	if(sql_error[0] != EOS || !sql_tuple){ 
		log_amx("[SJ] - No connection to SQL server! Error: %s", sql_error)
		return PLUGIN_HANDLED
	}
	
	new sz_temp[512]
	
	g_PlayerId[0] = 0
	
	format(sz_temp, charsmax(sz_temp), "SELECT * FROM sj_servers WHERE IP = '%s' AND ACTIVE > 0", g_serverip)
	SQL_ThreadQuery(sql_tuple, "q_getServerInfo", sz_temp)
	
	return PLUGIN_HANDLED
}

public q_getServerInfo(FailState,Handle:Query,Error[],Errcode,Data[],DataSize){
	if(FailState == TQUERY_CONNECT_FAILED){
		log_amx("[SJ] - Could not connect to SQL database.  [%d] %s", Errcode, Error)
	}
	else if(FailState == TQUERY_QUERY_FAILED){
		log_amx("[SJ] - Load Query failed. [%d] %s", Errcode, Error)
	}
	if(Errcode){
		return log_amx("[SJ] - Error on query: %s", Error)
	}
		
	if(!SQL_NumResults(Query)){
		log_amx("[SJ] - This server (%s) is not registered. Continue without SQL statistics.", g_serverip)
		if(sql_tuple) SQL_FreeHandle(sql_tuple)
		return PLUGIN_HANDLED
	}
	
	g_PlayerId[0] = SQL_ReadResult(Query, SQL_FieldNameToNum(Query, "ID"))
	g_userUTC[0] = SQL_ReadResult(Query, SQL_FieldNameToNum(Query, "UTC"))
	
	return PLUGIN_HANDLED
}

public sql_updateServerInfo(){
	if(g_PlayerId[0]){
		new sz_temp[2048], sz_name[64], sz_players = 0, sz_pass[32]
		get_user_name(0, sz_name, charsmax(sz_name))
		replace_all(sz_name, charsmax(sz_name), "'", "''")

		for(new id = 1; id <= g_maxplayers; id++){
			if(IsUserConnected(id) && ~IsUserBot(id)){
				sz_players++
			}
		}
		get_cvar_string("sv_password", sz_pass, charsmax(sz_pass))

		format(sz_temp, charsmax(sz_temp), "UPDATE sj_servers SET NAME = '%s', PASSWORD = '%s', PLAYERS = '%d', MAXPLAYERS = '%d', TIME_EDIT = NOW() WHERE ID = %d", sz_name, sz_pass, sz_players, g_maxplayers, g_PlayerId[0])
		SQL_ThreadQuery(sql_tuple, "QueryHandle", sz_temp)	
	}
}

public sql_updateMatch(){
	if(sql_error[0] != EOS || !sql_tuple){ 
		log_amx("[SJ] - No connection to SQL server! Error: %s", sql_error)
		return PLUGIN_HANDLED
	}
	if(g_regtype == 0)
		return PLUGIN_HANDLED
	
	new sz_temp[512]

	if(!gMatchId){ 
		format(sz_temp, charsmax(sz_temp), "INSERT INTO sj_matches (DATE_START, SERVER_ID, T_TEAM_ID, CT_TEAM_ID, GAMEROUND, TOURNAMENT_ID) VALUES (NOW(),%d,%d,%d,%d,%d)", 
		g_PlayerId[0], TeamId[T], TeamId[CT], (GAME_MODE + 10 * ROUND), gTournamentId)
		SQL_ThreadQuery(sql_tuple,"q_insertMatch",sz_temp)
	} else {
		format(sz_temp, charsmax(sz_temp), "UPDATE sj_matches SET T_TEAM_ID = %d, CT_TEAM_ID = %d, T_SCORE = %d, CT_SCORE = %d, TIMELEFT = %d, GAMEROUND = %d WHERE ID = %d", 
		TeamId[T], TeamId[CT], get_pcvar_num(cv_score[T]), get_pcvar_num(cv_score[CT]), g_Timeleft, (GAME_MODE + 10 * ROUND), gMatchId)
		SQL_ThreadQuery(sql_tuple, "QueryHandle", sz_temp)
	}
	
	return PLUGIN_HANDLED
}

public q_insertMatch(FailState,Handle:Query,Error[],Errcode,Data[],DataSize){
	if(FailState == TQUERY_CONNECT_FAILED){
		log_amx("[SJ] - Could not connect to SQL database.  [%d] %s", Errcode, Error)
	} else if(FailState == TQUERY_QUERY_FAILED){
		log_amx("[SJ] - Load Query failed. [%d] %s", Errcode, Error)
	}
	if(Errcode){
		return log_amx("[SJ] - Error on query: %s", Error)
	}
	new sz_temp[512]
	
	gMatchId = SQL_GetInsertId(Query)
	
	format(sz_temp, charsmax(sz_temp), "UPDATE sj_matches SET GAMEROUND = -1 WHERE SERVER_ID = %d AND DATE_END is NULL", g_PlayerId[0])
	SQL_ThreadQuery(sql_tuple,"QueryHandle",sz_temp)
	
	return PLUGIN_HANDLED
}

public sql_updatePlayerStats(id){
	if(sql_error[0] != EOS || !sql_tuple){ 
		log_amx("[SJ] - No connection to SQL server! Error: %s", sql_error)
		return PLUGIN_HANDLED
	}
	if(contain(g_authid[id], "LAN") != -1 || contain(g_authid[id], "PEND") != -1 || contain(g_authid[id], "STEAM") == -1 || g_authid[id][0] == EOS){
		ColorChat(id, RED, "^4[SJ] ^1- ^3%L", id, "SJ_STEAMUNA")
		return PLUGIN_HANDLED
	}
	new sz_temp[512], Data[1]
	Data[0] = id
	format(sz_temp, charsmax(sz_temp), "SELECT * FROM sj_stats WHERE MATCH_ID = %d AND PLAYER_ID = %d ", gMatchId, g_PlayerId[id])
	SQL_ThreadQuery(sql_tuple, "q_updatePlayerStats", sz_temp, Data, 1)
	
	return PLUGIN_HANDLED
}

public q_updatePlayerStats(FailState,Handle:Query,Error[],Errcode,Data[],DataSize){
	if(FailState == TQUERY_CONNECT_FAILED){
		log_amx("[SJ] - Could not connect to SQL database.  [%d] %s", Errcode, Error)
	} else if(FailState == TQUERY_QUERY_FAILED) {
		log_amx("[SJ] - Load Query failed. [%d] %s", Errcode, Error)
	}
	if(Errcode) {	
		return log_amx("[SJ] - Error on query: %s", Error)
	}
		
	new sz_temp[512], sz_len
	new id = Data[0]
	
	if(!SQL_NumResults(Query)){ 
		format(sz_temp, charsmax(sz_temp), "INSERT INTO sj_stats (MATCH_ID, PLAYER_ID, TEAM_ID) VALUES (%d,%d,%d)", gMatchId, g_PlayerId[Data[0]], TeamId[get_user_team(id)])
		SQL_ThreadQuery(sql_tuple,"QueryHandle",sz_temp)
	} else {
		
		sz_len += format(sz_temp[sz_len], charsmax(sz_temp) - sz_len, "UPDATE sj_stats SET ")
		for(new i = 1; i <= RECORDS; i++){
			sz_len += format(sz_temp[sz_len], charsmax(sz_temp) - sz_len, "%s`%s`=%d", i==1?" ":",", RecordTitles[i], MadeRecord[id][i])
		}
		sz_len += format(sz_temp[sz_len], charsmax(sz_temp) - sz_len, " WHERE MATCH_ID = %d AND PLAYER_ID = %d", gMatchId, g_PlayerId[id])
			
		SQL_ThreadQuery(sql_tuple, "QueryHandle", sz_temp)
	}

	return PLUGIN_HANDLED
}

public sql_getTopPlayers(){
	if(sql_error[0] != EOS || !sql_tuple){ 
		log_amx("[SJ] - No connection to SQL server! Error: %s", sql_error)
		return PLUGIN_HANDLED
	}
	
	new sz_temp[1024]
	format(sz_temp, charsmax(sz_temp), "DROP TABLE IF EXISTS top_stats;")
	SQL_ThreadQuery(sql_tuple, "q_dropTopPlayers", sz_temp)
	
	return PLUGIN_HANDLED
}
public q_dropTopPlayers(FailState,Handle:Query,Error[],Errcode,Data[],DataSize){
	if(FailState == TQUERY_CONNECT_FAILED){
		log_amx("[SJ] - Could not connect to SQL database.  [%d] %s", Errcode, Error)
	}
	else if(FailState == TQUERY_QUERY_FAILED){
		log_amx("[SJ] - Load Query failed. [%d] %s", Errcode, Error)
	}
	if(Errcode){
		return log_amx("[SJ] - Error on query: %s", Error)
	}
	
	new sz_temp[1024]
	
	format(sz_temp, charsmax(sz_temp), "CREATE TABLE top_stats AS (SELECT sj_stats.PLAYER_ID,SUM(sj_stats.WIN) AS WIN,SUM(sj_stats.LOSE) AS LOSE FROM sj_stats JOIN sj_matches ON sj_matches.TOURNAMENT_ID=%d AND sj_matches.ID=sj_stats.MATCH_ID WHERE sj_stats.POS>0 GROUP BY sj_stats.PLAYER_ID);", gTournamentId)
	SQL_ThreadQuery(sql_tuple, "q_createTopPlayers", sz_temp)	
	
	return PLUGIN_HANDLED
}

public q_createTopPlayers(FailState,Handle:Query,Error[],Errcode,Data[],DataSize){
	if(FailState == TQUERY_CONNECT_FAILED){
		log_amx("[SJ] - Could not connect to SQL database.  [%d] %s", Errcode, Error)
	}
	else if(FailState == TQUERY_QUERY_FAILED){
		log_amx("[SJ] - Load Query failed. [%d] %s", Errcode, Error)
	}
	if(Errcode){
		return log_amx("[SJ] - Error on query: %s", Error)
	}
	
	new sz_temp[1024]
	format(sz_temp, charsmax(sz_temp), "SELECT sj_players.ID FROM sj_players LEFT OUTER JOIN top_stats ON top_stats.PLAYER_ID=sj_players.ID WHERE (top_stats.WIN>0 OR top_stats.LOSE>0)AND (ifnull(top_stats.WIN,0)+ifnull(top_stats.LOSE,0))>80 ORDER BY (ifnull(top_stats.WIN,0)/(ifnull(top_stats.WIN,0)+ifnull(top_stats.LOSE,0))) desc limit 5")
	SQL_ThreadQuery(sql_tuple, "q_getTopPlayers", sz_temp)	
	
	return PLUGIN_HANDLED
}
public q_getTopPlayers(FailState,Handle:Query,Error[],Errcode,Data[],DataSize){
	if(FailState == TQUERY_CONNECT_FAILED){
		log_amx("[SJ] - Could not connect to SQL database.  [%d] %s", Errcode, Error)
	}
	else if(FailState == TQUERY_QUERY_FAILED){
		log_amx("[SJ] - Load Query failed. [%d] %s", Errcode, Error)
	}
	if(Errcode){
		return log_amx("[SJ] - Error on query: %s", Error)
	}
		
	new i = 0
	
	while(SQL_MoreResults(Query) && i < 5){
		gTopPlayers[i++] = SQL_ReadResult(Query, SQL_FieldNameToNum(Query, "ID"))
	
		SQL_NextRow(Query)
	}
	
	return PLUGIN_HANDLED
}

public sql_get_players(){
	new sz_temp[128]
	format(sz_temp, charsmax(sz_temp), "SELECT COUNT(STEAM_ID) AS players FROM %s", sql_table)
	SQL_ThreadQuery(sql_tuple, "q_players", sz_temp)
}

public q_players(FailState,Handle:Query,Error[],Errcode,Data[],DataSize){
	if(FailState == TQUERY_CONNECT_FAILED)
		log_amx("[SJ] - Could not connect to SQL database.  [%d] %s", Errcode, Error)
	else if(FailState == TQUERY_QUERY_FAILED)
		log_amx("[SJ] - Load Query failed. [%d] %s", Errcode, Error)
	if(Errcode)
		return log_amx("[SJ] - Error on query: %s", Error)
		

	sql_players = SQL_ReadResult(Query, SQL_FieldNameToNum(Query, "players"))
	
	return PLUGIN_HANDLED
}

public sql_rank(id, cid, sz_type){
	if(contain(g_authid[cid], "LAN") != -1 || contain(g_authid[cid], "PEND") != -1 || g_authid[cid][0] == EOS){
		ColorChat(id, RED, "^4[SJ] ^1- ^3%L", id, "SJ_STEAMUNA")
		return PLUGIN_HANDLED
	}
	new sz_temp[512]

	new sz_data[3]
	sz_data[0] = id
	sz_data[1] = cid
	sz_data[2] = sz_type
	
	sql_get_players()
	
	format(sz_temp, charsmax(sz_temp), 
	"SELECT COUNT(STEAM_ID)+1 AS rank FROM %s WHERE `%s` > (SELECT `%s` FROM %s WHERE STEAM_ID = '%s')", 
	sql_table, RecordTitles[GOAL], RecordTitles[GOAL], sql_table, g_authid[cid])
	
	SQL_ThreadQuery(sql_tuple, "q_rank", sz_temp, sz_data, 3)
	
	return PLUGIN_HANDLED
}

public q_rank(FailState,Handle:Query,Error[],Errcode,Data[],DataSize){
	if(FailState == TQUERY_CONNECT_FAILED)
		log_amx("[SJ] -  Could not connect to SQL database.  [%d] %s", Errcode, Error)	
	else if(FailState == TQUERY_QUERY_FAILED)
		log_amx("[SJ] - Load Query failed. [%d] %s", Errcode, Error)
	if(Errcode)
		return log_amx("[SJ] - Error on query: %s", Error)
	
	new id = Data[0]
	new cid = Data[1]
	new sz_type = Data[2]
	if(SQL_MoreResults(Query)){
		new sz_rank = SQL_ReadResult(Query, SQL_FieldNameToNum(Query, "rank"))
		if(!sz_type){
			new sz_name[32]
			get_user_name(cid, sz_name, charsmax(sz_name))
			ColorChat(id, GREY, "^4[SJ] ^1- %s - ^4%d ^1%L ^4%d", 
			sz_name, sz_rank, id, "SJ_OF", sql_players)
		}
		else{
			new sz_temp[512]
			Data[2] = sz_rank
			format(sz_temp, charsmax(sz_temp), "SELECT * FROM %s WHERE STEAM_ID = '%s'", 
			sql_table, g_authid[cid])
			SQL_ThreadQuery(sql_tuple, "q_rankstats", sz_temp, Data, 3)
		}
	}
	else{
		ColorChat(id, RED, "^4[SJ SQL] ^1- ^3Could not retrieve your rank")
	}
	
	return PLUGIN_HANDLED
}

public q_rankstats(FailState,Handle:Query,Error[],Errcode,Data[],DataSize){
	if(FailState == TQUERY_CONNECT_FAILED)
		log_amx("[SJ] -  Could not connect to SQL database.  [%d] %s", Errcode, Error)	
	else if(FailState == TQUERY_QUERY_FAILED)
		log_amx("[SJ] - Load Query failed. [%d] %s", Errcode, Error)
	if(Errcode)
		return log_amx("[SJ] - Error on query: %s", Error)
	
	if(SQL_MoreResults(Query)){
		new id = Data[0]
		new cid = Data[1]
		new sz_rank = Data[2]
		new sz_len = 0
		new sz_temp[2048]
		new sz_name[32]
		new sz_lang[36]
		
		get_user_name(cid, sz_name, 31)
			
		sz_len = format(sz_temp, charsmax(sz_temp), "<body bgcolor=#000000 text=#FFFFFF><center><br>")
		
		sz_len += format(sz_temp[sz_len], charsmax(sz_temp) - sz_len, 
		"<font color=orange size=6><b>%s</font><hr width=25%% color=yellow>", sz_name)
		
		sz_len += format(sz_temp[sz_len], charsmax(sz_temp) - sz_len, 
		"<table border=0 width=25%% align=center cellpadding=0 cellspacing=6>")
		for(new i = 1; i <= RECORDS; i++){
			if(i == HITS || i == BHITS || i == POSSESSION)
				continue
			format(sz_lang, charsmax(sz_lang), "SJ_MOTD_%s", RecordTitles[i])
			sz_len += format(sz_temp[sz_len], charsmax(sz_temp) - sz_len, 
			"<tr><td align=left><font color=orange>%L<td align=right><font color=orange>%d", 
			id, sz_lang, SQL_ReadResult(Query, SQL_FieldNameToNum(Query, RecordTitles[i])))
			if(i == DISTANCE)
				sz_len += format(sz_temp[sz_len], charsmax(sz_temp) - sz_len, " %L", id, "SJ_MOTD_FT")
		}
		sz_len += format(sz_temp[sz_len], charsmax(sz_temp) - sz_len, "</table><hr width=25%% color=yellow>" )
		
		sz_len += format(sz_temp[sz_len], charsmax(sz_temp) - sz_len, 
		"<font color=#3366FF>%L %d %L %d<hr width=25%% color=yellow>", 
		id, "SJ_MOTD_RANK", sz_rank, id, "SJ_MOTD_OF", sql_players)
		
			
		new sz_header[64]
		format(sz_header, charsmax(sz_header), "%L", id, "SJ_STATS") 
			
		show_motd(id, sz_temp, sz_header)
	}
	
	return PLUGIN_HANDLED
}

public cmd_top(id, i){
	new sz_temp[128]
	new Data[2]
	Data[0] = id
	Data[1] = i
	format(sz_temp, charsmax(sz_temp), "SELECT * FROM %s ORDER BY `%s` DESC", sql_table, RecordTitles[GOAL])
	SQL_ThreadQuery(sql_tuple, "show_top", sz_temp, Data, 2)
}

public show_top(FailState,Handle:Query,Error[],Errcode,Data[],DataSize){
	if(FailState == TQUERY_CONNECT_FAILED)
		log_amx("[SJ] -  Could not connect to SQL database.  [%d] %s", Errcode, Error)	
	else if(FailState == TQUERY_QUERY_FAILED)
		log_amx("[SJ] - Load Query failed. [%d] %s", Errcode, Error)
	if(Errcode)
		return log_amx("[SJ] - Error on query: %s", Error)
	
	new id = Data[0]
	new sz_top = Data[1]
	if(sz_top > 10 || sz_top < 1)
		sz_top = 10
	new k
	new sz_len = 0
	new sz_temp[2048]
	new sz_name[32]
	new sz_lang[32]
	sz_len += format(sz_temp, charsmax(sz_temp), 
	"<body bgcolor=#000000 text=#FFB000><center><hr width=99%% color=yellow>")
	
	sz_len += format(sz_temp[sz_len], charsmax(sz_temp) - sz_len, 
	"<table border=0 width=99%% cellpadding=6 cellspacing=6>")
	
	sz_len += format(sz_temp[sz_len], charsmax(sz_temp) - sz_len, 
	"<tr><td>#<td>%L", id, "SJ_MOTD_PLAYER")
	for(k = 1; k <= RECORDS; k++){
		if(k == HITS || k == BHITS || k == POSSESSION)
			continue
		format(sz_lang, 31, "SJ_MOTD_%s", RecordTitles[k])
		sz_len += format(sz_temp[sz_len], charsmax(sz_temp) - sz_len, "<td>%L", id, sz_lang)
	}
	
	new i
	while(++i <= sz_top && SQL_MoreResults(Query)){
		SQL_ReadResult(Query, SQL_FieldNameToNum(Query, "PLAYER"), sz_name, 31)
		sz_len += format(sz_temp[sz_len], charsmax(sz_temp) - sz_len, "<tr><td>%d.<td>%s", i, sz_name)
		for(k = 1; k <= RECORDS; k++){
			if(k == HITS || k == BHITS || k == POSSESSION)
				continue
			sz_len += format(sz_temp[sz_len], charsmax(sz_temp) - sz_len, "<td align=center>%d", 
			SQL_ReadResult(Query, SQL_FieldNameToNum(Query, RecordTitles[k])))
			if(k == DISTANCE)
				sz_len += format(sz_temp[sz_len], charsmax(sz_temp) - sz_len, " %L", id, "SJ_MOTD_FT")
		}
		SQL_NextRow(Query)
	}
	sz_len += format(sz_temp[sz_len], charsmax(sz_temp) - sz_len, 
	"</table><hr width=99%% color=yellow><size=5><font color=#3366FF>%L: %d", 
	id, "SJ_MOTD_TOTALP", sql_players)
						
	new sz_header[64]
	format(sz_header, charsmax(sz_header), "%L - %d", id, "SJ_TOP", sz_top)
	show_motd(id, sz_temp, sz_header)
	
	return PLUGIN_HANDLED
}
/*
+-----------------------+--------------------------------------------------------------------------+
|			| ************************************************************************ |
|   [AUTO RECORD DEMO]	| ************************************************************************ |
|			| ************************************************************************ |
+-----------------------+--------------------------------------------------------------------------+
*/

public hltv_connect(){
	if (rec_in_progress){
		return PLUGIN_HANDLED
	}
	rec_in_progress = 1

	formatex (demofile, sizeof(demofile) - 1, "%s-%s-%d", TeamNames[T], TeamNames[CT], g_current_match)
	
	replace_all(demofile, sizeof(demofile) - 1,":","-")	
	
	formatex (command,sizeof (command) - 1,"name %s;delay %d;autoretry 1;connect %s", HLTV_NAME, 0, g_serverip)
	is_stopped = false
	
	sock_open()
	
	return PLUGIN_CONTINUE
}

public hltv_disconnect(){
	formatex (command, sizeof(command) - 1, "stoprecording;autoretry 0;stop")
	
	sock_open()
	
	is_stopped = true
	rec_in_progress = 0
	g_temp_current_match = g_current_match
	//set_task(2.0, "DemoUpload")
	
}
public DemoUpload(){
	if(demofile[0] != EOS && g_temp_current_match){
		new sz_temp[128],sz_newname[128], sz_map[64], sz_time[64]
		get_mapname(sz_map, charsmax(sz_map))
		format_time(sz_temp, charsmax(sz_temp), "%y%m%d%H%M", g_temp_current_match)
		format(sz_temp, charsmax(sz_temp), "%s-%s", sz_temp, sz_map)
		
		format(sz_newname, charsmax(sz_newname), "%s-%d_%d-%s", 
		TeamNames[T], get_pcvar_num(cv_score[T]), get_pcvar_num(cv_score[CT]), TeamNames[CT])
		replace_all(sz_newname, charsmax(sz_newname),":","-")
		format_time(sz_time, charsmax(sz_time), "%y.%m.%d_%H-%M", g_temp_current_match)
		format(sz_newname, charsmax(sz_newname), "%s-%s.dem", sz_newname, sz_time)
		
		format(sz_temp, charsmax(sz_temp), "%s-%s.dem", demofile, sz_temp)
		if(file_exists(sz_temp)){
			rename_file(sz_temp, sz_newname, 1)
			/*FTP_Open(FTP_WEB_Server, FTP_WEB_Port, FTP_WEB_User, FTP_WEB_Pass, "FwdFuncOpen")
			set_task(2.0, "Send_Demo", _, sz_newname, sizeof(sz_newname) - 1)*/
			g_temp_current_match = 0
			format(demofile, charsmax(demofile), "")
		}
		/*else{
			client_print(0, print_chat, "OK.")
			if(FTP_Ready())
				FTP_Close()
			FTP_Open(FTP_HLTV_Server, FTP_HLTV_Port, FTP_HLTV_User, FTP_HLTV_Pass, "FwdFuncOpen")
			//File_List(
			new sz_ip[16]
			get_user_ip(0, sz_ip, charsmax(sz_ip), 1)
			if(!equal(FTP_HLTV_Server, sz_ip)){
				FTP_Open(FTP_HLTV_Server, FTP_HLTV_Port, FTP_HLTV_User, FTP_HLTV_Pass, "FwdFuncOpen")
				set_task(2.0, "Get_Demo", _, sz_temp, sizeof(sz_temp) - 1)
			}
			else{
				if(FTP_Ready()){
					FTP_Close()
				}
				g_temp_current_match = 0
				format(demofile, charsmax(demofile), "")
			}
		}*/	
	}
}

public sock_open(){
	if (query_in_progress) {
		return PLUGIN_HANDLED
	}

	if (s_handle) {
		socket_close(s_handle)
	}
	
	query_in_progress = 1
	
	s_handle = socket_open(HLTV_IP,HLTV_PORT, SOCKET_UDP, s_error)
	
	if (s_error) {
		switch (s_error) {
			case 1:
				//log_amx("Error creating socket.")
				client_print(0, print_console, "Error creating socket.")
			case 2:
				//log_amx("Could not find server %s:%d", HLTV_IP,HLTV_PORT)
				client_print(0, print_console, "Could not find server %s:%d", HLTV_IP,HLTV_PORT)
			case 3:
				//log_amx("Could not connect to server.")
				client_print(0, print_console, "Could not connect to server.")
		}
		s_handle = 0
		query_in_progress = 0
		rec_in_progress = 0
		is_stopped = true
		
		return PLUGIN_HANDLED
	}
	
	set_task(0.1, "send_challenge_hltv")
	
	return PLUGIN_CONTINUE
}

public send_challenge_hltv(){
	new packetstr[32]
	
	//call challenge number from hltv-server
	formatex (packetstr,sizeof packetstr -1,"%c%c%c%cchallenge rcon^n",-1,-1,-1,-1)
	socket_send2(s_handle, packetstr, sizeof packetstr -1)
	
	set_task(0.1, "get_rconquery")
}

public get_rconquery(){
	if (!s_handle) {
		log_amx("get_rconquery called with null socket")
		client_print(0, print_console, "get_rconquery called with null socket")
		query_in_progress = 0
		is_stopped = true
		
		return PLUGIN_CONTINUE
	}
	
	if (!socket_change(s_handle)) { 
		recvattempts += 1
		if (recvattempts > 5) {
			log_amx("[ERROR] No response from the server.")
			client_print(0, print_console, "[ERROR] No response from the server.")
			abort_query()
			recvattempts = 0
			
			rec_in_progress = 0
			
			return PLUGIN_HANDLED
		} else {
			set_task(0.2, "get_rconquery")
			
			return PLUGIN_CONTINUE
		}
	}
	
	recvattempts = 0
	
	new packet[64]
	socket_recv(s_handle, packet, sizeof packet -1)
	
	if (!equal(packet, {-1,-1,-1,-1,'c'}, 5)) { 
		log_amx("[ERROR] wrong challenge-nr response from HLTV server.")
		log_amx("[ERROR] returning packet: %s",packet)
		client_print(0, print_console, "[ERROR] wrong challenge-nr response from HLTV server.")
		client_print(0, print_console, "[ERROR] returning packet: %s",packet)
		rec_in_progress = 0
		abort_query()
		
		return PLUGIN_HANDLED
	}
	
	//build challenge number
	new i
	new offset = 19
	
	while(47 < packet[i + offset] < 58) {
		copy(hltvrcon[i],1,packet[i + offset])
		i++
	}
	
	set_task(0.5,"send_command")
	
	return PLUGIN_CONTINUE
}

public send_command(){
	new gspassword[32]
	get_cvar_string("sv_password", gspassword, 31) //game-server has a password? then get it
	if(!equal(gspassword, "")) {
		new temp[256]
		copy(temp, sizeof(temp) - 1, command)
		formatex (command, sizeof(command) -1, "serverpassword %s;%s", gspassword, temp)
	}
	
	new packetstr[256]
	formatex (packetstr, sizeof(packetstr) - 1, "%c%c%c%crcon %s ^"%s^" %s^n", -1,-1,-1,-1,hltvrcon,HLTV_PW,command)
	socket_send2(s_handle, packetstr, sizeof(packetstr) - 1)
	
	if(!is_stopped) {
		set_task(1.0, "send_record")
	} else {
		abort_query()

	}
	return PLUGIN_CONTINUE
}

public send_record(){
	if (!hltv_is_connected()) {
		recvattempts += 1
		if (recvattempts > 5) {
			log_amx("[ERROR] No HLTV is connected, sending ^"record^" command failed.")

			abort_query()
			
			recvattempts = 0
			
			rec_in_progress = 0
			
			hltv_disconnect() //only safety
			
			return PLUGIN_HANDLED
		} else {
			
			set_task(1.0, "send_record")
			
			return PLUGIN_CONTINUE
		}
	}
	recvattempts = 0

	ColorChat(0, BLUE, "^4[SJ] ^1- ^1Demo of this match is recording.")
	
	
	new packetstr[128]
	
	//steambans support
	formatex (packetstr, sizeof packetstr -1, "%c%c%c%crcon %s ^"%s^" loopcmd 1 120 servercmd status ^n", -1,-1,-1,-1,hltvrcon,HLTV_PW)
	socket_send2(s_handle, packetstr, sizeof packetstr -1)
	
	formatex (packetstr, sizeof packetstr -1, "%c%c%c%crcon %s ^"%s^" record %s ^n", -1,-1,-1,-1,hltvrcon,HLTV_PW,demofile)
	socket_send2(s_handle, packetstr, sizeof packetstr -1)
	abort_query()
	
	rec_in_progress = 1
	
	return PLUGIN_CONTINUE
}
public abort_query(){
	socket_close(s_handle)
	query_in_progress = 0
	s_handle = 0
}

public delayed_hltv_stop(){
	query_in_progress = 0
	
	hltv_disconnect()
}

hltv_is_connected(){
	new HLTVs[32]
	new hltv_num = 0
	new pnum = 0
	
	get_players(HLTVs, pnum, "c")
	
	for(new i; i < pnum; i++){
		if(is_user_hltv(HLTVs[i])){
			hltv_num++
		}
	}
	return hltv_num
}

/*
+-----------------------+--------------------------------------------------------------------------+
|			| ************************************************************************ |
|         [FTP]		| ************************************************************************ |
|			| ************************************************************************ |
+-----------------------+--------------------------------------------------------------------------+
*/

/*public Send_Demo(sz_file[]){
	if(FTP_Ready()){
		new sz_remfile[256]
		format(sz_remfile, charsmax(sz_remfile), "%s/%s", FTP_WEB_demo_remotedir, sz_file)
		
		FTP_SendFile(sz_file, sz_remfile, "Send_Demo_Status")
	}
}

public Send_Demo_Status(szFile[], iBytesComplete, iTotalBytes){  
	if(iBytesComplete == iTotalBytes){
		ColorChat(0, BLUE, "^4[SJ] ^1- Demo of this match has been uploaded: ^3http://sj-pro.com/demos/%s", szFile)
		server_print("[FTP] - File %s transfer completed!", szFile)
		
		FTP_Close()
	}
}*/
// -------------------------------------------------------------------------------------------------
/*public File_List(){
	if(FTP_Ready()){
		FTP_GetList("demolist.txt" , "" , "File_List_Status" );
	}
}

public FwdFuncList(szFile[], iBytesComplete){
	server_print( "[%s] [ %d bytes ]" , szFile , iBytesComplete );
} 
// -------------------------------------------------------------------------------------------------
public Get_Demo(sz_file[]){
	if(FTP_Ready()){
		new sz_localfile[256], sz_remfile[256]
		format(sz_remfile, charsmax(sz_remfile), "%s/%s", FTP_HLTV_demo_remotedir, sz_file)
		
		FTP_GetFile(sz_file, sz_remfile, "Get_Demo_Status")
	}
}

public Get_Demo_Status(szFile[], iBytesComplete, iTotalBytes){  
	if(iBytesComplete == iTotalBytes){
		server_print("[FTP] - File %s transfer completed!", szFile)
		ColorChat(0, BLUE, "^4got it %s", szFile)
		format(demofile, charsmax(demofile), "")
		//DemoUpload()
	}
} 
*/

// -------------------------------------------------------------------------------------------------
public Get_Plugin(){
	if(FTP_Ready()){
		new sz_localfile[256], sz_remfile[256]
		format(sz_localfile, charsmax(sz_remfile), "%s/%s", FTP_WEB_plugin_localdir, FTP_WEB_plugin_local)
		format(sz_remfile, charsmax(sz_remfile), "%s/%s", FTP_WEB_plugin_remotedir, FTP_WEB_plugin_remote)
		
		FTP_GetFile(sz_localfile, sz_remfile, "Get_Plugin_Status")
	}
}
public Get_Plugin_Status(szFile[], iBytesComplete, iTotalBytes){  
	if(iBytesComplete == iTotalBytes){
		ColorChat(0, GREEN, "^4[SJ] ^1- Plugin has been updated! ^3Change map to prevent lags!")
		server_print("[FTP] - File %s transfer completed!", szFile)
		
		FTP_Close()
	}
} 
/*
//--------------------------------------------------------------------------------------------------
public OnSocketReply() {
	static const requestHeader      		[] = "HTTP/1.1 200 OK^r^nServer: Online Map^r^nConnection: close^r^nContent-Type: text/plain^r^n^r^n";
	static const requestMapHeader		[] = "({^r^n^t^"bombpos^": [ ^"%d^", ^"%d^", ^"%d^", ^"%d^" ],^r^n^t^"server^": [ ^"%s^", ^"%s^", ^"%s^", ^"%d^" ],^r^n^t^"map^": ^"%s^",^r^n^t^"users^": [";
	static const requestPlayerHeader	[] = "^r^n^t{^r^n^t^t^"name^": ^"%s^",^r^n^t^t^"status^": [ ^"%d^", ^"%d^", ^"%d^", ^"%d^" ],^r^n^t^t^"position^": [ ^"%d^", ^"%d^", ^"%d^" ],^r^n^t^t^"angle^": [ ^"%d^", ^"%d^", ^"%d^" ],^r^n^t^t^"stats^": [ ^"%d^", ^"%d^" ]^r^n^t},^r^n";
	static const requestEndHeader   		[] = "]^r^n})";
	
	static request;
	static accErr;

	if((request = socket_accept(szSocket, accErr)) > 0) {
		static requestData[ 8192 ];
		static requestRecv[ 256 ];
		static length;
		static result;
		
		socket_recv( request, requestRecv, charsmax( requestRecv ) );
		
		length = copy( requestData, charsmax( requestData ), requestHeader );
		
		if( regex_match_c( requestRecv, RegexHandle, result ) ) {
			static match[ 64 ];
			
			regex_substr( RegexHandle, 1, match, charsmax( match ) );
			length += copy( requestData[ length ] , charsmax( requestData ) - length, match );
	
		}
	
		length += formatex( requestData [ length ], charsmax( requestData ), requestMapHeader, 0, 0, 0, 0, g_wserverip, g_serverport, g_servername, g_maxplayers, g_mapname)
		
		static playersList[ 32 ], playersCount, player;
		static playerName[ 32 ];
		static angles[ 3 ];
		static origin[ 3 ];
		new Float:florigin[3]
		new i;
		
		get_players( playersList, playersCount );
		
		for( i = 0; i < playersCount; i++ ) {
			player = playersList[i];
			
			get_user_name(player, playerName, charsmax(playerName))
			get_user_origin( player, origin, 0 )
			get_user_origin( player, angles, 3 )
			
			length += formatex(requestData[length], charsmax(requestData) - length, requestPlayerHeader,
			playerName,
			is_user_alive( player ),
			cs_get_user_team( player ),
			get_user_weapon( player ),
			get_user_health( player ),
			origin[0], origin[1], origin[2],
			angles[0], angles[1], angles[2],
			get_user_frags( player ),
			get_user_deaths( player ) )
		}
		
		for(i = 0; i <= g_count_balls; i++){
			if(pev_valid(g_ball[i])){
				format(playerName, charsmax(playerName), "-----%d", i)
				pev(g_ball[i], pev_origin, florigin)
				length += formatex( requestData[ length ], charsmax( requestData ) - length,  requestPlayerHeader,
				playerName, 1, 0, 0, 100, floatround(florigin[0]), floatround(florigin[1]), floatround(florigin[2]), 0, 0, 0, 0, 0)
			}
		}
		length += copy( requestData[ length ] , charsmax( requestData ) - length, requestEndHeader );
		
		socket_recv( request, requestRecv, charsmax( requestRecv ) );
		socket_send( request, requestData, length );
		socket_close( request )
	}
}

// -------------------------------------------------------------------------------------------------
public FwdFuncOpen(bool:bLoggedIn){
	server_print("[FTP] - Login was %ssuccessful!", bLoggedIn ? "" : "un")
}
*/
// -------------------------------------------------------------------------------------------------

public plugin_end(){
	if(sql_tuple)
		SQL_FreeHandle(sql_tuple)
	//nvault_close(g_vault)
	
	TrieDestroy(gTrieStats)
	//hltv_disconnect()
	//socket_close(szSOCKET)
	//socket_close(szSocket)
	//if(FTP_Ready())
	//	FTP_Close()
	
}
