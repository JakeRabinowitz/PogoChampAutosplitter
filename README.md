# PogoChampAutosplitter
"Official" autosplit files for [PogoChamp](https://store.steampowered.com/app/1357220/PogoChamp/).

Feel free to use / modify for whatever splits & runs you want, this is just some examples to get started and show off the integration.

## Setup/Troubleshooting
Using the PogoChamp.asl file requires you to have UnityASL.bin in your `Livesplit/Components/` folder.  If it isn't working, a missing UnityASL is likely the problem, you can download UnityASL.bin here: https://github.com/just-ero/asl-help/raw/main/libraries/UnityASL.bin

## Usage
The PogoChamp.asl file has 5 different split patterns that you can pick from by going to `Edit Layout > Scriptable AutoSplitter`, the options are:
* Split on gates: Has 18 splits, one for each gate in the game. Useful for Any % runs.
* Split every 10 levels: Useful for All Levels Complete runs.
* Split every 50 stars: Useful for All Stars runs.
* Split every 10 Rainbow Gems: Useful for All Rainbow Gem runs.
* VS Mode Splits: These are splits for the ["Unofficial VS Mode"](https://store.steampowered.com/app/1357220/PogoChamp/) way to play PogoChamp. This will split every time you restart a level, and will reset any time you exit to the level select. The actual split times when playing VS don't matter, this is just an easy way to keep track of your remaining attempts.

## Dev Info
The game has fields exposed specifically for Autosplitters:
```csharp
/// <summary>
/// True if the game is in a load screen.
/// </summary>
public static bool isLoading = false;

/// <summary>
/// The current state of the game in human readable format.
/// 
/// Possible values are: 
/// "Playing", "Crashed", "Replay", "Victory", "Exiting Level", "Level Select", 
/// "Cinematic", "Main Menu", "Loading", or null.
/// </summary>
private static string gameState = null;

/// <summary>
/// True if the player is in a level, false otherwise.
/// </summary>
public static bool isInLevel = false;

/// <summary>
/// The index of the level the player is in. -1 if not in a level.
/// </summary>
public static int levelIndex = -1;

/// <summary>
/// The in-game time for the current attempt on this level.
/// </summary>
public static float attemptTime = 0f;

/// <summary>
/// The in-game time that's shown when the in-game "Speedrun Timer" is on.
/// The in-game timer includes any time where your character is alive in a level (including pauses),
/// but does not include things like navigating the level select or cutscenes.
/// </summary>
public static float speedrunTime = 0f;

/// <summary>
/// The total playtime of this save file that you are playing on.  This is the same time that is shown
/// in the save file selection menu.
/// </summary>
public static float totalPlaytime = 0f;

/// <summary>
/// The number of stars that you have unlocked.
/// </summary>
public static int starCount = 0;

/// <summary>
/// The number of rainbow gems that you have unlocked.  This will be 0 unless rainbow gems are
/// visible (either by enabling them in the in-game speedrun settings, or by collecting all stars).
/// </summary>
public static int rainbowGemCount = 0;

/// <summary>
/// The total number of jumps that you have done on this save file.
/// </summary>
public static int jumpCount = 0;
```
If you have an idea for a new run type that isn't supported by these variables, let me know over on the [PogoChamp Discord](https://discord.gg/GRxYEWr) and I'll see if I can add what you need to the game!
