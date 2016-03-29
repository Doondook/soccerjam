#include <amxmodx>
#include <amxmisc>
#include <engine>
#include <fakemeta>
#include <cstrike>
#include <fun>
#include <colorchat>
#include <hamsandwich>
#include <dhudmessage>
#include <nvault>
#include <sqlx>
#include <screenfade_util>

#define PLUGIN "Football"
#define VERSION "1.0"
#define AUTHOR "Doondook"

#define MAX_PLAYERS 32

#define BALL_MODEL "models/eurofoot/sjniket1.mdl"

#define T		1
#define CT		2
#define SPECTATOR 	3

#define SetUserBot(%1) 		g_bIsBot |= 1<<(%1 & (MAX_PLAYERS - 1))
#define ClearUserBot(%1) 	g_bIsBot &= ~(1<<(%1 & (MAX_PLAYERS - 1)))
#define IsUserBot(%1) 		g_bIsBot & 1<<(%1 & (MAX_PLAYERS - 1))

#define SetUserAlive(%1) 	g_bIsAlive |= 1<<(%1 & (MAX_PLAYERS - 1))
#define ClearUserAlive(%1) 	g_bIsAlive &= ~(1<<(%1 & (MAX_PLAYERS - 1)))
#define IsUserAlive(%1) 	g_bIsAlive & 1<<(%1 & (MAX_PLAYERS - 1))

#define SetUserConnected(%1)    g_bIsConnected |= 1<<(%1 & (MAX_PLAYERS - 1))
#define ClearUserConnected(%1) 	g_bIsConnected &= ~(1<<(%1 & (MAX_PLAYERS - 1)))
#define IsUserConnected(%1) 	g_bIsConnected & 1<<(%1 & (MAX_PLAYERS - 1))

new g_bIsBot, g_bIsAlive, g_bIsConnected

#define NONE		0
#define PREGAME 	1
#define GAME		2
#define SHOOTOUT 	3

#define MAX_LEN_INFOBOARD 128
#define TURBO_ADD_SPEED 100.0
#define DEFAULT_SPEED 350.0
#define RESPAWN_DELAY 2.0
new g_maxplayers
new g_ball

new Float:g_w_speed
new g_cam[MAX_PLAYERS + 1]

// CVARs
new cv_time, cv_kickleft, cv_kickright, cv_score[2], cv_turbo, cv_turbo_rec, cv_ballidle, cv_sidejump

// Messages
new g_msg_roundtime
new g_msg_showtimer
new g_msg_centertext
new g_msg_hidehud
new g_msg_deathmsg

new Float:g_GN_T[6]
new Float:g_GN_CT[6]
new Float:g_GN_T_orig[3]
new Float:g_GN_CT_orig[3]

new MODE = PREGAME
new TeamColors[2][3] = { 
/* T */ {255,25,25}, 
/* CT */ {15,15,255} 
}
static const TeamNames[2][] = {"RED", "BLUE"}

new TIMELEFT
new g_infoboard[MAX_LEN_INFOBOARD]
new g_infoboard_colors[3] = {255, 255, 10}
new g_ballkicker[2]
new g_ballkicker_team
new g_ballkicker_name[2][32]

new g_start_time
new g_sidejump[MAX_PLAYERS + 1]
new Float:g_sidejump_delay[MAX_PLAYERS + 1]

new bool:g_once = false
new g_winner
new sd_whistle[] = "eurofoot/ball/whistle.wav"
new sd_whistle_long[] = "kickball/whistle_endgame.wav"
new sd_shoot[] = "eurofoot/ball/shoot.wav"
new Float:g_nextstep[MAX_PLAYERS + 1]
#define MAX_STEP_SOUND 12
new g_can_shoot[MAX_PLAYERS]
new spr_smoke, spr_beam, spr_fire
new const sd_steps[MAX_STEP_SOUND][] = {
	"eurofoot/player/step1.wav",
	"eurofoot/player/step2.wav",
	"eurofoot/player/step3.wav",
	"eurofoot/player/step4.wav",
	"eurofoot/player/step5.wav",
	"eurofoot/player/step6.wav",
	"eurofoot/player/step7.wav",
	"eurofoot/player/step8.wav",
	"eurofoot/player/step9.wav",
	"eurofoot/player/step10.wav",
	"eurofoot/player/step11.wav",
	"eurofoot/player/step12.wav"
}
new sd_crowd[] = "eurofoot/crowd/crowd.wav"
new sd_goal[2][] = {
	"eurofoot/crowd/goal1.wav",
	"eurofoot/crowd/goal2.wav"
}
new sd_goalnet[2][] = {
	"eurofoot/ball/net1.wav",
	"eurofoot/ball/net2.wav"
}
new g_showhelp[MAX_PLAYERS + 1]

public plugin_precache( ){
	new i
	spr_beam 	= 	precache_model("sprites/laserbeam.spr")
	spr_fire 	= 	precache_model("sprites/shockwave.spr")
	spr_smoke 	= 	precache_model("sprites/steam1.spr")
	precache_model(BALL_MODEL)
	precache_sound(sd_whistle);
	precache_sound(sd_whistle_long)
	precache_sound(sd_shoot)
	/*for(i = 0; i < MAX_STEP_SOUND; i++)
		precache_sound(sd_steps[i])
	precache_sound(sd_crowd)
	for(i = 0; i < 2; i++){
		precache_sound(sd_goal[i])
		precache_sound(sd_goalnet[i])
	}*/
	precache_model("models/rpgrocket.mdl")
}

public plugin_init() {
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	g_maxplayers = get_maxplayers()
	
	//--------------------- CVARs --------------------------
	cv_time 	= register_cvar("ef_time", 	"15")
	cv_kickleft 	= register_cvar("ef_lkick", 	"800")
	cv_kickright 	= register_cvar("ef_rkick", 	"1000")
	cv_score[0] 	= register_cvar("ef_scoret",	"0")
	cv_score[1] 	= register_cvar("ef_scorect",	"0")
	cv_turbo	= register_cvar("ef_turbo",	"10.0")
	cv_turbo_rec	= register_cvar("ef_turborec",	"20.0")
	cv_ballidle 	= register_cvar("ef_idletime",	"30.0")
	cv_sidejump	= register_cvar("ef_sidejump",	"5.0")
	//----------------------------- Events ------------------------------
	register_event("HLTV",		"Event_StartRound", "a", "1=0", "2=0")
	register_event("ResetHUD", 	"Event_ResetHUD", "b")
	
	RegisterHam(Ham_TakeDamage, 	"info_target", 	"SlashBall")
	RegisterHam(Ham_TakeDamage, 	"player", 	"SlashPlayer")
	RegisterHam(Ham_Spawn, 		"player", 	"PlayerSpawned", 1)
	RegisterHam(Ham_Killed, 	"player", 	"PlayerKilled")
	
	//------------------- Touches --------------------------
	register_touch("Ball", "player", 	"TouchPlayer")
	register_touch("Ball", "*",		"TouchWorld")
	
	
	//-------------------- Thinks --------------------------
	register_think("Ball", "BallThink")
	
	register_forward(FM_EmitSound, 		"FWd_Sound")
	register_forward(FM_PlayerPreThink, 	"FWd_Player", 0)
	register_forward(FM_AddToFullPack, 	"FWd_AddToFullpack", 1)
	//------------------- Messages -------------------------
	           
	g_msg_roundtime 	= get_user_msgid("RoundTime")
	g_msg_showtimer 	= get_user_msgid("ShowTimer")
	g_msg_centertext 	= get_user_msgid("TextMsg")
	g_msg_hidehud 		= get_user_msgid("HideWeapon")
	g_msg_deathmsg 		= get_user_msgid("DeathMsg")

	register_message(g_msg_roundtime, 	"Event_RoundTime")
	register_message(g_msg_centertext, 	"Event_CenterText")
	register_message(g_msg_hidehud, 	"Event_HideHud")
	
	//--------------- Client Commands ----------------------
	register_concmd("ef_restart", 	"RestartGame", ADMIN_KICK)
	register_clcmd("drop", 	"Turbo")
	register_clcmd("nightvision", 	"CameraChanger")
	register_clcmd("say /help", 	"Help")
	//register_clcmd("buyammo1", 	"GetBall")
	
	new sz_map[32]
	get_mapname(sz_map, 31)
	if(equal(sz_map, "soccerjam")){
		CreateGoalNets()
	}
	CreateBall()
	PrepareGame()
	
	set_task(0.2, "StatusDisplay", _, _, _, "b")

}

/*================================================================================================*/
/*====================================== BALL DESCRIPTION ========================================*/
/*================================================================================================*/
public GetBall(id){
	if(pev_valid(g_ball)){
		new Float: sz_orig[3]
		pev(id, pev_origin, sz_orig)
		sz_orig[2] += 100.0
		//set_pev(g_ball, pev_origin, sz_orig)
		engfunc(EngFunc_SetOrigin, g_ball, sz_orig)
		set_pev(g_ball, pev_velocity, Float:{0.0, 0.0, -1.0})
		client_print(id, print_chat, "Ball is up to you!")
	}
	
}
public CreateBall(){
	new sz_ball = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"))
	
	if(g_ball > 0 || !pev_valid(sz_ball)){
		return PLUGIN_HANDLED
	}
	
	engfunc(EngFunc_SetModel, sz_ball, BALL_MODEL)
	engfunc(EngFunc_SetSize, sz_ball, Float:{ -15.0, -15.0, -21.0 }, Float:{ 15.0, 15.0, 21.0 })
	//engfunc(EngFunc_SetOrigin, sz_ball, Float:{-9999.9, -9999.9, -9999.9})
	//entity_set_model(sz_ball, BALL_MODEL)
	//set_entity_visibility(sz_ball, 1)
	
	set_pev(sz_ball, pev_classname, "Ball")
	set_pev(sz_ball, pev_solid, SOLID_BBOX)

	set_pev(sz_ball, pev_movetype, MOVETYPE_BOUNCE)
	set_pev(sz_ball, pev_takedamage, 1.0)
	set_pev(sz_ball, pev_health, 255.0)
	set_pev(sz_ball, pev_nextthink, get_gametime() + 0.1)
	//entity_set_int(sz_ball, EV_INT_movetype, MOVETYPE_BOUNCE)

	g_ball = sz_ball
	
	set_task(2.0, "MoveBall", 1)
	
	return PLUGIN_HANDLED
}

public BallThink(){
	if(g_ball > 0){
		if(MODE == GAME){
			new Float:sz_origins[3]
			pev(g_ball, pev_origin, sz_origins)
			if(	g_GN_T[0] < sz_origins[0] + 15.0 < g_GN_T[1] && 
				g_GN_T[2] < sz_origins[1] + 15.0 < g_GN_T[3] && 
				g_GN_T[4] < sz_origins[2] < g_GN_T[5] &&  
				!g_infoboard[0]){
					Goal(2)		
			}
			if(	g_GN_CT[0] < sz_origins[0] + 15.0 < g_GN_CT[1] && 
				g_GN_CT[2] < sz_origins[1] + 15.0 < g_GN_CT[3] && 
				g_GN_CT[4] < sz_origins[2] < g_GN_CT[5] &&  
				!g_infoboard[0]){
					Goal(1)		
			}
		}
	
		new Float:sz_velocity[3], Float:sz_angles[3]
		pev(g_ball, pev_velocity, sz_velocity)
		pev(g_ball, pev_angles, sz_angles); 
		
		if(sz_velocity[0] || sz_velocity[1])
			sz_angles[0] -= g_w_speed
			
		set_pev(g_ball, pev_angles, sz_angles)
		set_pev(g_ball, pev_nextthink, halflife_time() + 0.01)	
	}

}
public empty_handler(){}

public test_hit(id){
	id-=535
	HitBall(g_ball, id, get_pcvar_num(cv_kickright), 0)	
}

public TouchPlayer(ball, player){
	if(MODE == SHOOTOUT || task_exists(player + 111))
		return PLUGIN_HANDLED
	//remove_task(102233)
	//set_task(get_pcvar_float(cv_ballidle), "FlameWave", 102233)	
	new Float:sz_b_velocity[3], Float: sz_p_velocity[3]
	pev(ball, pev_velocity, sz_b_velocity)
	pev(player, pev_velocity, sz_p_velocity)
	new sz_speed = get_speed(ball)
	

	//client_print(player, print_chat, "touch [debug]")

	if(sz_speed > 500){
		sz_b_velocity[0] *= 0.8
		sz_b_velocity[1] *= 0.8
		if(!task_exists(20035)){
			set_task(0.1, "PlayEntSound", 20035, sd_shoot, strlen(sd_shoot))	
		}
	}
	else{
		sz_b_velocity[0] = 0.50 * sz_b_velocity[0] + sz_p_velocity[0] * 0.35
		sz_b_velocity[1] = 0.50 * sz_b_velocity[1] + sz_p_velocity[1] * 0.35
	}
				
	sz_b_velocity[2] *= 0.70
	
	if(entity_get_int(player, EV_INT_button) & IN_JUMP){
		sz_b_velocity[2] += 800.0
	}
	
	g_ballkicker[0] = player
	g_ballkicker_team = get_user_team(player)
	get_user_name(player, g_ballkicker_name[0], 31)
	Glow(g_ball, TeamColors[g_ballkicker_team - 1])
	
	set_pev(ball, pev_velocity, sz_b_velocity)
	
	
	return PLUGIN_HANDLED
	
}

public PlayTouchSound(){
	emit_sound(g_ball, CHAN_ITEM, sd_shoot, 1.0, ATTN_NORM, 0, PITCH_NORM)
}

public TouchWorld(ball){
	if(get_speed(ball) > 5){
		new Float:sz_velocity[3], Float: sz_angles[3], Float:sz_temp_angles[3]
		pev(ball, pev_velocity, sz_velocity)
		sz_velocity[0] *= 0.99
		sz_velocity[1] *= 0.99
		sz_velocity[2] *= 0.40
		
		// Easy anti-stuck
		if(floatabs(sz_velocity[2]) < 1.0)
			sz_velocity[2] = 8.0

		pev(ball, pev_angles, sz_angles)
		vector_to_angle(sz_velocity, sz_temp_angles)
		sz_temp_angles[0] = sz_angles[0]
		sz_temp_angles[2] = sz_angles[2]
		set_pev(ball, pev_angles, sz_temp_angles)

		g_w_speed = floatsqroot(sz_velocity[0] * sz_velocity[0] + sz_velocity[1] * sz_velocity[1]) / 35.0
		
		set_pev(ball, pev_velocity, sz_velocity)
	}
}

public HitBall(ball, player, str, addtnl){
	
	new Float:sz_temp_vel[3]
	if(addtnl)
		str += get_speed(ball) / 2
	
	//remove_task(102233)
	//set_task(get_pcvar_float(cv_ballidle), "FlameWave", 102233)
	velocity_by_aim(player, str, sz_temp_vel)
	new Float:sz_angles[3]
	vector_to_angle(sz_temp_vel, sz_angles)
	set_pev(ball, pev_angles, sz_angles)
	set_pev(ball, pev_velocity, sz_temp_vel)
	//client_print(0, print_chat, "%1.f ; %1.f ; %1.f", sz_temp_vel[0], sz_temp_vel[1], sz_temp_vel[2])
	g_w_speed = floatsqroot(sz_temp_vel[0] * sz_temp_vel[0] + sz_temp_vel[1] * sz_temp_vel[1]) / 28.0
	
	new sz_team = get_user_team(player)
	if(g_ballkicker_team == sz_team || !(1 <= g_ballkicker_team <= 2)){
		if(g_ballkicker[0] && player != g_ballkicker[0]){
			g_ballkicker[1] = g_ballkicker[0]
			copy(g_ballkicker_name[1], 31, g_ballkicker_name[0])
		}
	}
	else{
		g_ballkicker[1] = 0
	}
	
	g_ballkicker[0] = player
	g_ballkicker_team = get_user_team(player)
	get_user_name(player, g_ballkicker_name[0], 31)
	
	Glow(g_ball, TeamColors[g_ballkicker_team - 1])
	
	if(!task_exists(20035))
		set_task(0.1, "PlayEntSound", 20035, sd_shoot, strlen(sd_shoot))
}

public SlashBall(ball, player, idattacker, Float:damage, damagebits ){
	new button = pev(player, pev_button)
	if(button & IN_ATTACK)
		HitBall(ball, player, get_pcvar_num(cv_kickleft), 0)
	else if(button & IN_ATTACK2)
		HitBall(ball, player, get_pcvar_num(cv_kickright), 1)
	
	return HAM_SUPERCEDE
}






/*================================================================================================*/
/*==================================== GAMEPLAY DESCRIPTION ======================================*/
/*================================================================================================*/


public StatusDisplay(){
	new id
	switch(MODE){
		case (NONE):{
			//g_infoboard_colors = {255, 255, 10} 
			for(id = 1; id <= g_maxplayers; id++){
				if(IsUserConnected(id) && ~IsUserBot(id) && !g_showhelp[id]){
					set_dhudmessage(g_infoboard_colors[0], g_infoboard_colors[1], g_infoboard_colors[2], -1.0, 0.15, 0, 0.2, 0.2, 0.2, 0.2)
					show_dhudmessage(id, g_infoboard)
				}
			}
		}
		case(PREGAME):{
			
			for(id = 1; id <= g_maxplayers; id++){
				if(IsUserConnected(id) && ~IsUserBot(id) && !g_showhelp[id]){
					set_dhudmessage(255, 255, 10, -1.0, 0.05, 0, 0.2, 0.2, 0.2, 0.2)
					show_dhudmessage(id, ".:  SLASH THE BALL  :.")
				}
			}
			if(!g_winner){
				
				for(id = 1; id <= g_maxplayers; id++){
					if(IsUserConnected(id) && ~IsUserBot(id) && !g_showhelp[id]){
						set_hudmessage(10, 255, 10, -1.0, 0.1, 0, 0.2, 0.2, 0.2, 0.2, -1)
						show_hudmessage(id, "- Waiting for an opponent -")
					}
				}
			}
			else{
				
				for(id = 1; id <= g_maxplayers; id++){
					if(IsUserConnected(id) && ~IsUserBot(id) && !g_showhelp[id]){
						set_hudmessage(10, 255, 10, -1.0, 0.1, 0, 0.2, 0.2, 0.2, 0.2, -1)
						show_hudmessage(id, "- Match Statistics -")
					}
				}
			}
				
		}
		case(GAME):{

			for(id = 1; id <= g_maxplayers; id++){
				if(IsUserConnected(id) && ~IsUserBot(id) && !g_showhelp[id]){
					set_dhudmessage(TeamColors[0][0], TeamColors[0][1], TeamColors[0][2], (get_pcvar_num(cv_score[0])/10)?0.42:0.43, 0.05, 0, 0.3, 0.3, 0.3, 0.3)
					show_dhudmessage(id, "%s - %d", TeamNames[0], get_pcvar_num(cv_score[0]))

					set_dhudmessage(TeamColors[1][0], TeamColors[1][1], TeamColors[1][2], 0.52, 0.05, 0, 0.3, 0.3, 0.3, 0.3)
					show_dhudmessage(id, "%d - %s", get_pcvar_num(cv_score[1]), TeamNames[1])
					
					set_dhudmessage(255, 255, 10, 0.50, 0.05, 0, 0.3, 0.3, 0.3, 0.1)
					show_dhudmessage(id, ":")
				}
			}

			
		
			if( TIMELEFT - floatround(get_gametime()) + g_start_time <= 0){
				new sz_score[2]
				sz_score[0] = get_pcvar_num(cv_score[0])
				sz_score[1] = get_pcvar_num(cv_score[1])
				if(sz_score[0] > sz_score[1]){
					g_winner = 1
					g_infoboard_colors = TeamColors[0]
					format(g_infoboard, MAX_LEN_INFOBOARD - 1, "%s WIN!", TeamNames[0])
					MODE = NONE
					PlaySound(sd_whistle_long)
					
				}
				else if(sz_score[0] < sz_score[1]){
					g_winner = 2
					g_infoboard_colors = TeamColors[1]
					format(g_infoboard, MAX_LEN_INFOBOARD - 1, "%s WIN!", TeamNames[1])
					MODE = NONE
					PlaySound(sd_whistle_long)
	
				}
				else{
					MODE = SHOOTOUT
					g_infoboard_colors = {255, 255, 10} 
					format(g_infoboard, MAX_LEN_INFOBOARD - 1, "- DRAW GAME! MOVING TO SHOOTOUT! -")
					PlaySound(sd_whistle)
					set_task(0.5, "PlaySound", _, sd_whistle, sizeof(sd_whistle) - 1)
					
				}
				remove_task(112001)
				server_cmd("sv_restart 5")
				//set_task(4.0, "RestartRound", 112001)
			}	
		}
		case SHOOTOUT:{
			g_infoboard_colors = {255, 255, 10} 
			for(id = 1; id <= g_maxplayers; id++){
				if(IsUserConnected(id) && ~IsUserBot(id) && !g_showhelp[id]){
					set_dhudmessage(g_infoboard_colors[0], g_infoboard_colors[1], g_infoboard_colors[2], -1.0, 0.05, 0, 0.2, 0.2, 0.2, 0.2)
					show_dhudmessage(id, g_infoboard)
				}
			}
		}
	}
}

public RestartGame(id, level, cid){
	if(!cmd_access(id, level, cid, 0))
		return PLUGIN_HANDLED
	MODE = PREGAME
	PrepareGame()
	new sz_name[32]
	get_user_name(id, sz_name, 31)
	ColorChat(0, GREEN, "[EF] ^1ADMIN: %s has restarted the game!", sz_name)
	if(!task_exists(112001))
		set_task(0.1, "RestartRound", 112001)
	
	return PLUGIN_HANDLED
}

public Event_StartRound(){
	g_infoboard[0] = 0
	
	if(g_winner)
		MODE = PREGAME
	if(MODE == PREGAME){
		if(!g_winner){
			PrepareGame()
			MODE = GAME
		}
		else{
			MoveBall(0)
		}
	}
	if(MODE == GAME){
		MoveBall(1)
		message_begin(MSG_BROADCAST, g_msg_showtimer)
		message_end();
	}
	if(MODE == SHOOTOUT){
		format(g_infoboard, MAX_LEN_INFOBOARD - 1, "- SHOOTOUT! -")
		
	}
	for(new id = 1; id <= g_maxplayers; id++){
		if(IsUserConnected(id)){
			g_sidejump[id] = 0
			g_sidejump_delay[id] = 0.0
			set_user_armor(id, 100)
			remove_task(id + 11000)
		}
	}
}

public PrepareGame(){
	g_winner = 0
	set_pcvar_num(cv_score[0], 0)
	set_pcvar_num(cv_score[1], 0)
	TIMELEFT = get_pcvar_num(cv_time) * 60

}

public Goal(team){
	set_pcvar_num(cv_score[team - 1], get_pcvar_num(cv_score[team - 1]) + 1)
	//g_infoboard_colors = TeamColors[team - 1]
	//format(g_infoboard, MAX_LEN_INFOBOARD - 1, "%s SCORED!", g_ballkicker_name)
	if(team == 1){
		if(g_ballkicker_team == 1){
			if(g_ballkicker[1])
				format(g_infoboard, MAX_LEN_INFOBOARD - 1, "%s ^4SCORED! ^1- ^3%s ^1assisted", g_ballkicker_name[0], g_ballkicker_name[1])
			else
				format(g_infoboard, MAX_LEN_INFOBOARD - 1, "%s ^4SCORED!", g_ballkicker_name[0])
			ColorChat(0, RED, g_infoboard)
		}
		else{
			format(g_infoboard, MAX_LEN_INFOBOARD - 1, "%s ^1scored an own goal!", g_ballkicker_name[0])
			ColorChat(0, BLUE, g_infoboard)
			
		}
		
	
	}
	else{
		if(g_ballkicker_team == 2){
			if(g_ballkicker[1])
				format(g_infoboard, MAX_LEN_INFOBOARD - 1, "%s ^4SCORED! ^1(^3%s ^1assisted)", g_ballkicker_name[0], g_ballkicker_name[1])
			else
				format(g_infoboard, MAX_LEN_INFOBOARD - 1, "%s ^4SCORED!", g_ballkicker_name[0])
			ColorChat(0, BLUE, g_infoboard)
		}
		else{
			format(g_infoboard, MAX_LEN_INFOBOARD - 1, "%s ^1scored an own goal! :'(", g_ballkicker_name[0][0]==EOS?"[error]":g_ballkicker_name[0])
			ColorChat(0, RED, g_infoboard)
			
		}
		
		
	
	}
	g_ballkicker[0] = 0
	g_ballkicker[1] = 0
	g_ballkicker_team = 0
	PlaySound(sd_whistle)
	//PlaySound(sd_goal[random(1)])
	new sz_speed = get_speed(g_ball)
	/*if(sz_speed > 600)
		set_task(0.1, "PlayEntSound", _, sd_goalnet[0], 1)
	else if(sz_speed > 50)
		set_task(0.2, "PlayEntSound", _, sd_goalnet[1], 1)*/
	if(!task_exists(112001))
		set_task(4.0, "RestartRound", 112001)
}

public Turbo(id){
	if(get_user_armor(id) == 100 && !task_exists(id + 11000)){
		set_user_maxspeed(id, DEFAULT_SPEED + TURBO_ADD_SPEED)
		set_task(get_pcvar_float(cv_turbo) / 100.0, "TurboUsing", id + 11000, _, _, "b")
		
	}
	return PLUGIN_HANDLED
}

public TurboRecovery(id){
	set_user_armor(id - 11000, 100)
}

public TurboUsing(id){
	id -= 11000
	if(~IsUserAlive(id)){
		remove_task(id + 11000)
		return PLUGIN_HANDLED
	}
	
	
	new sz_armor = get_user_armor(id)
	set_user_armor(id, sz_armor - 1)
	if(sz_armor == 0){	
		remove_task(id + 11000)
		set_user_maxspeed(id, DEFAULT_SPEED)
		set_task(get_pcvar_float(cv_turbo_rec), "TurboRecovery", id + 11000)
	}
	return PLUGIN_HANDLED
	
}
stock print(sz_msg[]){
	client_print(0, print_chat, "%s", sz_msg)
}
public MoveBall(sz_where){
	if(!pev_valid(g_ball))
		return -1
	
	set_pev(g_ball, pev_velocity, Float:{0.0, 0.0, 0.0})
	set_pev(g_ball, pev_angles, Float:{270.0, 0.0, 0.0})
	switch(sz_where){
		case 0:{
			engfunc(EngFunc_SetOrigin, g_ball, Float:{-9999.9, -9999.9, -9999.9})
			//print("0")
		
		}
		case 1:{
			new Float:sz_origin[3]
			sz_origin[0] = (g_GN_CT_orig[0] + g_GN_T_orig[0]) / 2
			sz_origin[1] = (g_GN_CT_orig[1] + g_GN_T_orig[1]) / 2
			sz_origin[2] = g_GN_CT_orig[2]
			//entity_set_origin(g_ball, sz_origin)
			engfunc(EngFunc_SetOrigin, g_ball, sz_origin)
			//client_print(0, print_chat, "%1.f, %1.f, %1.f", sz_origin[0], sz_origin[1], sz_origin[2])
			set_pev(g_ball, pev_velocity, Float:{0.0, 0.0, -1.0})
			Glow(g_ball, {255, 255, 255})
			//print("1")
		}
	}
	//remove_task(102233)
	//set_task(1.0, "FlameWave", 102233)
	
	return 0 
}

public client_PreThink(id){
	if(IsUserAlive(id) && get_user_maxspeed(id) == DEFAULT_SPEED){
		//client_print(id, print_center, "%d", g_sidejump[id])
		new button 	= pev(id, pev_button)	
		new up 		= (button & IN_FORWARD)
		new down 	= (button & IN_BACK)
		new moveright 	= (button & IN_MOVERIGHT)
		new moveleft 	= (button & IN_MOVELEFT)
		new jump 	= (button & IN_JUMP)
		new onground 	= pev(id, pev_flags) & FL_ONGROUND
		
		if(g_sidejump[id] == 1)
			g_sidejump[id] = 0
			
		if((moveright || moveleft) && !up && !down && jump && onground && g_sidejump[id] != 2){
			g_sidejump[id] = 1
		}
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
		
		if((gametime - g_sidejump_delay[id]) > get_pcvar_float(cv_sidejump)){
			if(g_sidejump[id] == 1 && jump && (moveright || moveleft) && !up && !down){
				new Float:vel[3]
				pev(id, pev_velocity, vel)
				vel[0] *= 2.0
				vel[1] *= 2.0
				vel[2] = 300.0
				g_sidejump[id] = 2
				set_pev(id, pev_velocity, vel)
				g_sidejump_delay[id] = gametime	
			}	
		}
	}
	return PLUGIN_CONTINUE
}

public FWd_AddToFullpack(es_handle, e, id, host, flags, player){
	if(id && player && IsUserAlive(id) && g_sidejump[id] == 2){
		if(!(pev(id, pev_flags) & FL_ONGROUND) && get_speed(id) > 250){
			set_es(es_handle, ES_Sequence, 8)
			set_es(es_handle, ES_Frame, Float:13.0)
			set_es(es_handle, ES_FrameRate, Float:0.0)
				
			return FMRES_HANDLED
		}
		if((get_gametime() - g_sidejump_delay[id]) > 0.1){
			g_sidejump[id] = 0
		}
	}

	return FMRES_IGNORED
}

/*================================================================================================*/
/*===================================== PLAYER DESCRIPTION =======================================*/
/*================================================================================================*/

public Event_ResetHUD(id){
	if(MODE == PREGAME){
		message_begin(MSG_ONE, g_msg_hidehud, _, id)
		write_byte(1 << 4)
		message_end()
	}
	else{
		message_begin(MSG_ONE, g_msg_hidehud, _, id)
		write_byte(0)
		message_end()
	}
	
}

public FWd_Player(id){
	if(~IsUserAlive(id))
		return FMRES_IGNORED;
    
	set_pev(id, pev_flTimeStepSound, 999);
	
	if(g_nextstep[id] < get_gametime() || (pev(id, pev_button) & IN_JUMP)){
		new Float: sz_speed = fm_get_ent_speed(id)
		if(sz_speed && (pev(id, pev_flags) & FL_ONGROUND)){
			//emit_sound(id, CHAN_BODY, sd_steps[random(MAX_STEP_SOUND - 1)], VOL_NORM, ATTN_STATIC, 0, PITCH_NORM)
		}
		if(sz_speed < 251.0)
			g_nextstep[id] = get_gametime() + 0.5
		else
			g_nextstep[id] = get_gametime() + 0.4
	}
	
	return FMRES_IGNORED;
}

public PlayerSpawned(id){
	if(is_user_alive(id))
		SetUserAlive(id)
	set_task(0.1, "PlayerSpawnedSettings", id)
}

public Event_HideHud(){
	if(MODE == PREGAME)
		set_msg_arg_int(1, ARG_BYTE, get_msg_arg_int(1) | 1 << 4)
}

public PlayerSpawnedSettings(id){
	if(IsUserAlive(id)){
		remove_task(11000 + id)
		set_user_maxspeed(id, DEFAULT_SPEED)
		set_user_armor(id, 100)
	}
}

public RespawnPlayer(id){
	id -= 11200
	
	if (~IsUserConnected(id) || IsUserAlive(id) ||  get_pdata_int(id, 126, 5) == 0xFF || IsUserAlive(id) || !(1 <= get_user_team(id) <= 2)){
		remove_task(id + 11200)	
		set_task(RESPAWN_DELAY, "RespawnPlayer", id + 11200)
		return
	}
	
	set_pev(id, pev_deadflag, DEAD_RESPAWNABLE)
	dllfunc(DLLFunc_Think, id)
	if(~IsUserAlive(id))
		dllfunc(DLLFunc_Spawn, id)
}

public PlayerKilled(victim, killer, shouldgib){
	ClearUserAlive(victim)
	
	set_task(RESPAWN_DELAY, "RespawnPlayer", victim + 11200)
}

public CreateGoalNets(){
	new endzone
	new Float:MinBox[3], Float:MaxBox[3]
	for(new x = 1; x < 3; x++){
		endzone = create_entity("info_target")
		if (endzone){
			//MinBox[0] = -25.0;	MinBox[1] = -145.0;	MinBox[2] = -36.0
			//MaxBox[0] =  25.0;	MaxBox[1] =  145.0;	MaxBox[2] =  70.0
			
			//entity_set_model(endzone, "models/chick.mdl")
			entity_set_int(endzone, EV_INT_solid, SOLID_BBOX)
			entity_set_int(endzone, EV_INT_movetype, MOVETYPE_NONE)
	
			//entity_set_vector(endzone, EV_VEC_mins, MinBox)
			//entity_set_vector(endzone, EV_VEC_maxs, MaxBox)
			set_pev(endzone, pev_size, Float:{50.0, 290.0, 106.0})
			set_pev(endzone, pev_team, x)
			entity_set_string(endzone, EV_SZ_classname, "soccerjam_goalnet")
			if(x == 1){
				g_GN_T_orig[0] = 2110.0 
				g_GN_T_orig[1] = 0.0 
				g_GN_T_orig[2] = 1604.0
				set_pev(endzone, pev_origin, g_GN_T_orig)
			}
			else{
				g_GN_CT_orig[0] = -2550.0 
				g_GN_CT_orig[1] = 0.0 
				g_GN_CT_orig[2] = 1604.0
				set_pev(endzone, pev_origin, g_GN_CT_orig)
			}
			entity_set_int(endzone, EV_INT_team, x)
			set_entity_visibility(endzone, 0)
			new data[2]
			data[0] = x
			data[1] = endzone
			FinalizeGoalNet(data)
			//GoalEnt[x] = endzone
		}
	}
}

public pfn_keyvalue(entid) {
	
	if(!g_once) {
		g_once = true
		
		new entity = create_entity("game_player_equip");
		if(entity) {
			DispatchKeyValue(entity, "weapon_knife", "1");
			DispatchKeyValue(entity, "targetname", "roundstart");
			DispatchSpawn(entity);
		}
	}
	
	new classname[32], key[32], value[32]
	copy_keyvalue(classname, 31, key, 31, value, 31)
	new data[2]
	
	if(equal(key, "classname") && equal(value, "soccerjam_goalnet")){
		DispatchKeyValue("classname", "func_wall")	
	}
	if(equal(classname, "game_player_equip")){
		remove_entity(entid)
	}
	else if(equal(classname, "func_wall")){
		if(equal(key, "team")){
			
			data[0] = str_to_num(value)
			
			if(data[0] == 1 || data[0] == 2) {
				data[1] = entid
				set_task(1.0, "FinalizeGoalNet", _, data, 2)
			}
		}	
	}
}

public FinalizeGoalNet(data[]) {
	new sz_team = data[0], sz_entid = data[1]
	new Float:sz_size[3], Float:sz_origin[3]
	
	pev(sz_entid, pev_size, sz_size)
	pev(sz_entid, pev_origin, sz_origin)
	//get_brush_entity_origin(sz_entid, sz_origin)
	set_entity_visibility(sz_entid, 0)
	
	if(sz_team == 1){
		g_GN_T_orig[0] = sz_origin[0]
		g_GN_T_orig[1] = sz_origin[1]
		g_GN_T_orig[2] = sz_origin[2]
		
		g_GN_T[0] = sz_origin[0] - (sz_size[0] / 2)
		g_GN_T[1] = sz_origin[0] + (sz_size[0] / 2)
		g_GN_T[2] = sz_origin[1] - (sz_size[1] / 2)
		g_GN_T[3] = sz_origin[1] + (sz_size[1] / 2)
		g_GN_T[4] = sz_origin[2] - (sz_size[2] / 2)
		g_GN_T[5] = sz_origin[2] + (sz_size[2] / 2)
		log_amx(" %1.f", g_GN_T[0])
		log_amx(" %1.f", g_GN_T[1])
		log_amx(" %1.f", g_GN_T[2])
		log_amx(" %1.f", g_GN_T[3])
		log_amx(" %1.f", g_GN_T[4])
		log_amx(" %1.f", g_GN_T[5])
	}
	else if(sz_team == 2){
		g_GN_CT_orig[0] = sz_origin[0]
		g_GN_CT_orig[1] = sz_origin[1]
		g_GN_CT_orig[2] = sz_origin[2]
		
		g_GN_CT[0] = sz_origin[0] - (sz_size[0] / 2)
		g_GN_CT[1] = sz_origin[0] + (sz_size[0] / 2)
		g_GN_CT[2] = sz_origin[1] - (sz_size[1] / 2)
		g_GN_CT[3] = sz_origin[1] + (sz_size[1] / 2)
		g_GN_CT[4] = sz_origin[2] - (sz_size[2] / 2)
		g_GN_CT[5] = sz_origin[2] + (sz_size[2] / 2)
	}
	log_amx("%d = %0.f %0.f %0.f", sz_entid, sz_origin[0], sz_origin[1], sz_origin[2])
	remove_entity(data[1])
}

public Event_RoundTime(){
	set_msg_arg_int(1, ARG_SHORT, TIMELEFT)
	g_start_time = floatround(get_gametime())
}

public SlashPlayer(vitcim, attacker, idattacker, Float:damage, damagebits ){
	//if(1 <= attacker <= 32)
		//return HAM_SUPERCEDE
	
	return HAM_IGNORED
}






/*================================================================================================*/
/*===================================== EFFECTS DESCRIPTION ======================================*/
/*================================================================================================*/
public FWd_Sound(id, channel, const sound[], Float:volume, Float:attenuation, flags, pitch){

	if(~IsUserConnected(id))
		return FMRES_IGNORED;
	//client_print(0, print_chat, "[Chan=%d] [Sound=%s] [Vol=%f] [Att=%f] [Flags=%d] [Pitch=%d]", channel, sound, volume, attenuation, flags, pitch);
    
	if(containi(sound, "knife_hit") != -1)
		return FMRES_SUPERCEDE;

	return FMRES_IGNORED;
} 

Glow(sz_entity, sz_color[3]) {
	set_rendering(sz_entity, kRenderFxGlowShell, sz_color[0], sz_color[1], sz_color[2], kRenderNormal, 25)
}

public PlayEntSound(sz_sound[]){
	emit_sound(g_ball, CHAN_ITEM, sz_sound, 1.0, ATTN_NORM, 0, PITCH_NORM)
}

public PlaySound(sz_sound[]){
	for(new id = 1; id <= g_maxplayers; id++){
		if(~IsUserConnected(id) || IsUserBot(id))
			continue
		client_cmd(id, "spk %s", sz_sound)
	}
}

public PlayWav(id){
	id -= 19220
	client_cmd(id, "spk %s", sd_crowd)
	set_task(58.0, "PlayWav", id + 19220)
	
}

public FlameWave() {
	new sz_orig[3]
	new Float:sz_forig[3]
	pev(g_ball, pev_origin, sz_forig)
	//pev(g_ball, sz_forig)
	for(new i = 0; i < 3; i++)
		sz_orig[i] = floatround(sz_forig[i])
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY, sz_orig) 
	write_byte(21) 
	write_coord(sz_orig[0]) 
	write_coord(sz_orig[1]) 
	write_coord(sz_orig[2]) 
	write_coord(sz_orig[0]) 
	write_coord(sz_orig[1]) 
	write_coord(sz_orig[2] + 300) 
	write_short(spr_beam)
	write_byte(0) 		// startframe 
	write_byte(0) 		// framerate 
	write_byte(5) 		// life 2
	write_byte(15) 		// width 16 
	write_byte(0) 		// noise 
	write_byte(255) 	// r 
	write_byte(255) 	// g 
	write_byte(255) 	// b 
	write_byte(150) 	// brightness 
	write_byte(1 / 10) 	// speed 
	message_end() 
	
	message_begin(MSG_BROADCAST,SVC_TEMPENTITY, sz_orig) 
	write_byte(21) 
	write_coord(sz_orig[0]) 
	write_coord(sz_orig[1]) 
	write_coord(sz_orig[2]) 
	write_coord(sz_orig[0]) 
	write_coord(sz_orig[1]) 
	write_coord(sz_orig[2] + 300) 
	write_short(spr_beam)
	write_byte(0) 		// startframe 
	write_byte(0) 		// framerate 
	write_byte(5) 		// life 2
	write_byte(30) 		// width 16 
	write_byte(0) 		// noise 
	write_byte(255) 	// r 
	write_byte(255) 	// g 
	write_byte(255) 	// b 
	write_byte(150) 	// brightness 
	write_byte(1 / 9) 	// speed 
	message_end() 
	
	message_begin(MSG_BROADCAST,SVC_TEMPENTITY, sz_orig)
	write_byte(21)
	write_coord(sz_orig[0])
	write_coord(sz_orig[1])
	write_coord(sz_orig[2]) 
	write_coord(sz_orig[0]) 
	write_coord(sz_orig[1]) 
	write_coord(sz_orig[2] + 300) 
	write_short(spr_beam)
	write_byte(0) 		// startframe 
	write_byte(0) 		// framerate 
	write_byte(5) 		// life 2
	write_byte(40) 		// width 16 
	write_byte(0) 		// noise 
	write_byte(255) 	// r 
	write_byte(255) 	// g 
	write_byte(255) 	// b 	
	write_byte(150) 	// brightness 
	write_byte(1 / 8) 	// speed 
	message_end() 
	
	/*//Explosion2 
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY) 
	write_byte(12) 
	write_coord(sz_orig[0]) 
	write_coord(sz_orig[1]) 
	write_coord(sz_orig[2])
	write_byte(80) 	// byte (scale in 0.1's) 188 
	write_byte(10) 	// byte (framerate) 
	message_end() 
	
	//TE_Explosion 
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY) 
	write_byte(3) 
	write_coord(sz_orig[0]) 
	write_coord(sz_orig[1]) 
	write_coord(sz_orig[2])
	write_short(spr_fire) 
	write_byte(65) 	// byte (scale in 0.1's) 188 
	write_byte(10) 	// byte (framerate) 
	write_byte(0) 	// byte flags 
	message_end() 
	*/
	set_task(1.0, "FlameWave", 102233)
	return PLUGIN_HANDLED
}





/*================================================================================================*/
/*==================================== COMMANDS DESCRIPTION ======================================*/
/*================================================================================================*/
public CameraChanger(id){
	if(g_cam[id]){
		set_view(id, CAMERA_NONE)
		g_cam[id] = false
	}
	else{
		set_view(id, CAMERA_3RDPERSON)
		g_cam[id] = true
	}
	
	return PLUGIN_HANDLED
}

public Spectate(id){
	if(get_user_team(id) != 3){
		cs_set_user_team(id, CS_TEAM_SPECTATOR, CS_DONTCHANGE)
		if(IsUserAlive(id))
			user_kill(id)
	}
}

public Help(id){
	g_showhelp[id] = true
	//UTIL_ScreenFade(
	UTIL_ScreenFade(id, {0, 0, 0}, 1.5, 11.0, 220, FFADE_OUT)
	
	set_task(1.5, "HelpOn", id + 45405)
	set_task(11.0, "HelpOff", id + 45405)
}
public HelpOn(id){
	id -= 45405
	//UTIL_ScreenFade(id, {0, 0, 0}, 1.5, 10.0, 0, FFADE_IN)
	set_dhudmessage(255, 255, 255, 0.17, 0.9, 0, 3.0, 8.0)
	show_dhudmessage(id, "TURBO - Press G")
	set_dhudmessage(255, 255, 255, -1.0, 0.9, 0, 3.0, 8.0)
	show_dhudmessage(id, "MATCH TIME LEFT")
	set_dhudmessage(255, 255, 255, 0.75, -1.0, 0, 3.0, 8.0)
	show_dhudmessage(id, "SLASH THE BALL^nLEFT - WEAK SHOOT^nRIGHT - POWER SHOOT ")
}
public HelpOff(id){
	id -= 45405
	UTIL_ScreenFade(id, {0, 0, 0}, 1.5, 1.0, 220, FFADE_IN)
	g_showhelp[id] = false
}






/*================================================================================================*/
/*============================================= MISC.=============================================*/
/*================================================================================================*/

public client_putinserver(id){
	ClearUserAlive(id)
	SetUserConnected(id)
	if(is_user_bot(id) || is_user_hltv(id)){
		SetUserBot(id)
	}
	else{
		set_task(RESPAWN_DELAY, "RespawnPlayer", id + 11200)
	}
	
	g_showhelp[id] = false
	
	//set_task(0.1, "PlayWav", id + 19220)	
}
public client_disconnect(id){
	ClearUserAlive(id)
	ClearUserConnected(id)
	if(IsUserBot(id)){
		ClearUserBot(id)
	}

}
public Event_CenterText() {
	new string[64]
	get_msg_arg_string(2, string, 63)
	if(containi(string, 	"#Game_will_restart") 	!= -1 
	|| containi(string, 	"#Spec_Mode") 		!= -1 
	|| containi(string, 	"#Spec_NoTarget") 	!= -1)	
		return PLUGIN_HANDLED
		
	return PLUGIN_CONTINUE
}

 
public RestartRound(){
	TIMELEFT -= floatround(get_gametime()) - g_start_time
	server_cmd("sv_restart 1")
}

stock Float:fm_get_ent_speed(id){
	if(!pev_valid(id))
		return 0.0;
    
	static Float:vVelocity[3];
	pev(id, pev_velocity, vVelocity);
    
	vVelocity[2] = 0.0;
    
	return vector_length(vVelocity);
}  
