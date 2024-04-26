#if defined _grenade_effects_included
 #endinput
#endif
#define _grenade_effects_included

/**
 * Called when a player is about to be freezed by a grenade
 *
 * @param client 	The victim index
 * @param attacker 	The client index who threw the grenade
 * @param duration	The freeze duration, set by reference 
 * @return		Plugin_Changed to apply new values, Plugin_Contninue to allow as is and >= Plugin_Handled to block
 */
forward Action ZR_OnClientFreeze(int client, int attacker, float &duration);

/**
 * Called when a player has been freezed by a grenade
 *
 * @param client 	The victim index
 * @param attacker 	The client index who threw the grenade
 * @param duration	The freeze duration
 * @noreturn
 */
forward void ZR_OnClientFreezed(int client, int attacker, float duration);

/**
 * Called when a player is about to be ignited by a grenade
 *
 * @param client 	The victim index
 * @param attacker 	The client index who threw the grenade
 * @param duration	The ignite duration, set by reference 
 * @return		Plugin_Changed to apply new values, Plugin_Contninue to allow as is and >= Plugin_Handled to block
 */
forward Action ZR_OnClientIgnite(int client, int attacker, float &duration);

/**
 * Called when a player has been ignited by a grenade
 *
 * @param client 	The victim index
 * @param attacker 	The client index who threw the grenade
 * @param duration	The freeze duration
 * @noreturn
 */
forward void ZR_OnClientIgnited(int client, int attacker, float duration);
