# ZR Grenade Effects - Copilot Instructions

## Repository Overview
This repository contains a SourceMod plugin for Counter-Strike: Source/Global Offensive that enhances grenades with special effects in Zombie Reloaded gameplay. The plugin transforms standard grenades into specialized tools:

- **HE Grenades → Napalm Grenades**: Ignite zombies on impact
- **Smoke Grenades → Freeze Grenades**: Freeze zombies within radius  
- **Flashbangs → Light Sources**: Create temporary lighting effects
- **Visual Effects**: Enhanced grenade trails, explosion rings, and lighting

## Technical Environment

### Core Technologies
- **Language**: SourcePawn (.sp files)
- **Platform**: SourceMod 1.11.0+ (Source engine game modification framework)
- **Build System**: SourceKnight 0.2 (automated SourceMod compilation)
- **Dependencies**: 
  - SourceMod 1.11.0-git6934+
  - Zombie Reloaded plugin (for ZR_* natives)

### Build Process
```bash
# Build using SourceKnight (handled by CI/CD)
sourceknight build
```
The build system automatically:
1. Downloads SourceMod and dependencies
2. Compiles `.sp` files to `.smx` plugins
3. Packages for distribution

## Project Structure

```
addons/sourcemod/scripting/
├── zr_grenade_effects.sp          # Main plugin (681 lines)
└── include/
    └── zr_grenade_effects.inc     # API forwards/natives (45 lines)

.github/
├── workflows/ci.yml               # Automated build/release
└── copilot-instructions.md        # This file

sourceknight.yaml                  # Build configuration
```

### Key Files
- **`zr_grenade_effects.sp`**: Main plugin implementation with all game logic
- **`zr_grenade_effects.inc`**: Public API defining forwards for other plugins
- **`sourceknight.yaml`**: Build dependencies and compilation settings

## Code Style & Standards

### SourcePawn Conventions
```sourcepawn
#pragma semicolon 1        // Mandatory semicolons
#pragma newdecls required  // New variable declaration syntax

// Global variables use g_ prefix
int g_iStyle;
bool g_bEnable;
float g_fDuration;
ConVar g_hCvar_Enable;
Handle g_hTimer[MAXPLAYERS+1];

// Function names use PascalCase
public void OnPluginStart()
bool DoSomething(int client)

// Local variables use camelCase  
int targetClient;
float grenadeOrigin[3];
char weaponName[32];
```

### Memory Management
```sourcepawn
// Preferred: Use delete (auto null-checks)
delete someHandle;

// Avoid: Manual null checking
if (someHandle != INVALID_HANDLE) {
    CloseHandle(someHandle);
    someHandle = INVALID_HANDLE;
}

// Timer cleanup
if (g_hFreeze_Timer[client] != INVALID_HANDLE) {
    KillTimer(g_hFreeze_Timer[client]);
    g_hFreeze_Timer[client] = INVALID_HANDLE;
}
```

## Plugin Architecture

### Core Systems

#### 1. ConVar Configuration System
The plugin uses extensive ConVar configuration:
```sourcepawn
// Global enable/disable
g_hCvar_Enable = CreateConVar("zr_greneffect_enable", "1", "Enables/Disables the plugin");

// Feature toggles
g_hCvar_VFX_Trails = CreateConVar("zr_greneffect_trails", "1", "Enables/Disables Grenade Trails");
g_hCvar_Napalm_HE = CreateConVar("zr_greneffect_napalm_he", "1", "Changes HE to napalm grenade");

// Auto-generate config file
AutoExecConfig(true, "grenade_effects", "zombiereloaded");
```

#### 2. Event-Driven Architecture
```sourcepawn
// Hook game events
HookEvent("hegrenade_detonate", OnHeDetonate);
HookEvent("smokegrenade_detonate", OnSmokeDetonate);
HookEvent("player_hurt", OnPlayerHurt);

// Entity creation hooks
public void OnEntityCreated(int entity, const char[] classname)
{
    if (!strcmp(classname, "hegrenade_projectile")) {
        BeamFollowCreate(entity, FragColor);
    }
}
```

#### 3. Forward/Native API
The plugin provides forwards for other plugins:
```sourcepawn
// In .inc file:
forward Action ZR_OnClientFreeze(int client, int attacker, float &duration);
forward void ZR_OnClientFreezed(int client, int attacker, float duration);

// In main plugin:
Action Forward_OnClientFreeze(int client, int attacker, float &time) {
    Call_StartForward(g_hfwdOnClientFreeze);
    Call_PushCell(client);
    Call_PushCell(attacker);  
    Call_PushFloatRef(time);
    Call_Finish(result);
    return result;
}
```

### Common Patterns

#### Visual Effects Creation
```sourcepawn
// Beam effects for grenade trails
void BeamFollowCreate(int entity, int color[4]) {
    TE_SetupBeamFollow(entity, BeamSprite, 0, 1.0, 10.0, 10.0, 5, color);
    TE_SendToAll();
}

// Ring effects for explosions  
TE_SetupBeamRingPoint(origin, 10.0, 400.0, g_iBeamsprite, g_iHalosprite, 1, 1, 0.2, 100.0, 1.0, FragColor, 0, 0);
```

#### Dynamic Light Creation
```sourcepawn
// Prevent edict overflow
GetEdictsCount();
if (g_iEdictCount >= MAX_EDICTS - 148) return;

int iEntity = CreateEntityByName("light_dynamic");
DispatchKeyValue(iEntity, "_light", "255 255 255 255");
DispatchKeyValueFloat(iEntity, "distance", g_fFlash_LightDistance);
DispatchSpawn(iEntity);
```

## Development Guidelines

### Adding New Features
1. **Create ConVars**: Always add configuration options for new features
2. **Hook ConVar Changes**: Update cached values when settings change
3. **Add to .inc**: Expose new functionality via forwards if other plugins need it
4. **Test Edge Cases**: Validate with disconnecting players, round changes, etc.

### Performance Considerations
- **Edict Limits**: Always check entity count before creating dynamic entities
- **Timer Management**: Clean up timers on player disconnect/round end
- **Trace Rays**: Use filtered traces to avoid hitting unintended entities
- **String Operations**: Minimize string comparisons in frequently called functions

### Error Handling
```sourcepawn
// Validate clients
if (!IsClientInGame(client) || !IsPlayerAlive(client)) {
    return;
}

// Validate entities
if (!IsValidEntity(entity)) {
    return;
}

// Handle trace results
Handle trace = TR_TraceRayFilterEx(origin, targetOrigin, MASK_SOLID, RayType_EndPoint, FilterTarget, client);
if (TR_DidHit(trace) && TR_GetEntityIndex(trace) == client) {
    // Process hit
}
CloseHandle(trace);
```

## Testing & Validation

### Manual Testing Setup
1. Load plugin on CS:S/CS:GO server with Zombie Reloaded
2. Test each grenade type with various ConVar configurations
3. Verify visual effects render correctly
4. Test with multiple players and edge cases (disconnects, round changes)

### Common Issues to Test
- **Memory Leaks**: Verify timers are cleaned up properly
- **Entity Limits**: Test behavior when approaching MAX_EDICTS
- **Performance**: Monitor server performance with multiple grenades
- **Compatibility**: Test with other plugins that might hook same events

## API Documentation

### Forwards
```sourcepawn
/**
 * Called before a client is frozen by a grenade
 * @param client    Victim client index  
 * @param attacker  Attacker client index
 * @param duration  Freeze duration (modifiable)
 * @return          Plugin_Continue to allow, >= Plugin_Handled to block
 */
forward Action ZR_OnClientFreeze(int client, int attacker, float &duration);

/**
 * Called after a client has been frozen
 * @param client    Victim client index
 * @param attacker  Attacker client index  
 * @param duration  Freeze duration applied
 */
forward void ZR_OnClientFreezed(int client, int attacker, float duration);
```

## Deployment Notes

### Installation
1. Compile `.sp` to `.smx` using SourceMod compiler
2. Place `.smx` in `addons/sourcemod/plugins/`
3. Place `.inc` in `addons/sourcemod/scripting/include/`
4. Configuration auto-generates in `cfg/zombiereloaded/grenade_effects.cfg`

### Dependencies
- Zombie Reloaded plugin must be loaded first
- Requires SourceMod 1.11.0+ for methodmap support
- CS:S/CS:GO game with Source engine

### Configuration
Key ConVars for server operators:
- `zr_greneffect_enable`: Master enable/disable
- `zr_greneffect_napalm_he`: Convert HE to napalm grenades  
- `zr_greneffect_smoke_freeze`: Convert smoke to freeze grenades
- `zr_greneffect_flash_light`: Convert flashbangs to light sources

## Common Development Tasks

### Adding New Grenade Effects
1. Add ConVar configuration in `OnPluginStart()`
2. Hook relevant game events or entity creation
3. Implement visual/gameplay effects
4. Add cleanup in disconnect/round end handlers
5. Update `.inc` file if exposing new forwards

### Debugging Tips
- Use `LogMessage()` for debugging instead of `PrintToServer()`
- Monitor `sm_dump_admcache` for memory issues
- Use `sm_dump_handles` to check for handle leaks
- Test with `developer 1` for additional console output

This plugin serves as a good example of SourceMod event-driven programming, visual effects creation, and API design for extensibility.