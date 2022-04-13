/*
 * PogoChamp has intentional support for Autosplitters built into the game. The data is exposed
 * through the static class "AutosplitData", which has the following fields:

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

 *
 * If you have an idea for a new speedrun category that can't be autosplit with these values,
 * join the PogoChamp Discord and let the game's developer (me!) know. Discord link: https://discord.gg/GRxYEWr
 */

state("PogoChamp") {}

startup
{
    vars.Log = (Action<object>)(output => print("[] " + output));
    vars.Unity = Assembly.Load(File.ReadAllBytes(@"Components\UnityASL.bin")).CreateInstance("UnityASL.Unity");

    /*
     * Gate star reqs (skipping the 1 star gate) as of 2022_04_11: 
     * 7, 15, 25, 36, 46, 56, 65, 77, 88, 100, 110, 120, 130, 150, 168, 180, 191
     */
    vars.gateBreakpoints = new int[] { 7, 15, 25, 36, 46, 56, 65, 77, 88, 100, 110, 120, 130, 150, 168, 180, 191 };

    settings.Add("pick_one", true, "Pick ONE of the following:");
    settings.Add("gates", true, "Split on gates (18 splits)", "pick_one");
    settings.SetToolTip("gates", "Split whenever you get enough stars to open the next gate. Skips the first 1-star gate.");
    // foreach (int breakpoint in vars.gateBreakpoints)
    // {
    //     settings.Add("gate_" + breakpoint.ToString(), true, breakpoint.ToString() + " Star Gate", "gates");
    // }

    settings.Add("levels", false, "Split every 10 levels (10 splits)", "pick_one");
    settings.SetToolTip("levels", "Split every 10 levels completed. Final split has 11 levels.");
    // for (int levelNumber = 10; levelNumber < 99; levelNumber += 10)
    // {
    //     settings.Add("level_" + levelNumber.ToString(), true, "Level " + levelNumber.ToString(), "levels");
    // }

    settings.Add("stars", false, "Split every 50 stars (6 splits).", "pick_one");
    settings.SetToolTip("stars", "Split every 50 stars. Final split has 53 stars.");
    // for (int starCounts = 0; starCounts < 350; starCounts += 50)
    // {
    //     settings.Add("stars_" + starCounts.ToString(), true, "Level " + starCounts.ToString(), "stars");
    // }

    settings.Add("rainbowGems", false, "Split every 10 Rainbow Gems.", "pick_one");
    settings.SetToolTip("rainbowGems", "Split every 10 Rainbow Gems. Final split has 11 gems.");
    // for (int starCounts = 0; starCounts < 350; starCounts += 50)
    // {
    //     settings.Add("stars_" + starCounts.ToString(), true, "Level " + starCounts.ToString(), "stars");
    // }

    settings.Add("vs_mode", false, "VS Mode splits.", "pick_one");
    settings.SetToolTip("vs_mode", "Split on every attempt, reset splits on entering a level. Uses attempt time instead of realtime.");

    vars.nextSplitLevelIndex = 9;
    vars.justUnlockedGate = false;
}

init
{
    vars.Unity.TryOnLoad = (Func<dynamic, bool>)(helper =>
    {
        var myClass = helper.GetClass("Assembly-CSharp", "AutosplitData");

        vars.Unity.Make<bool>(myClass.Static, myClass["isLoading"]).Name = "isLoading";
        vars.Unity.MakeString(myClass.Static, myClass["gameState"]).Name = "gameState";
        
        vars.Unity.Make<int>(myClass.Static, myClass["isInLevel"]).Name = "isInLevel";
        vars.Unity.Make<int>(myClass.Static, myClass["levelIndex"]).Name = "levelIndex";

        vars.Unity.Make<float>(myClass.Static, myClass["attemptTime"]).Name = "attemptTime";
        vars.Unity.Make<float>(myClass.Static, myClass["speedrunTime"]).Name = "speedrunTime";
        vars.Unity.Make<float>(myClass.Static, myClass["totalPlaytime"]).Name = "totalPlaytime";

        vars.Unity.Make<int>(myClass.Static, myClass["starCount"]).Name = "starCount";
        vars.Unity.Make<int>(myClass.Static, myClass["rainbowGemCount"]).Name = "rainbowGemCount";
        vars.Unity.Make<int>(myClass.Static, myClass["jumpCount"]).Name = "jumpCount";

        return true;
    });

    vars.Unity.Load(game);
}

update
{
    if (!vars.Unity.Loaded) return false;

    vars.Unity.Update();
}

start
{
    if (settings["vs_mode"])
    {
        var gameState = vars.Unity["gameState"];
        return gameState.Changed && gameState.Old == "Loading" && gameState.Current == "Playing";
    }
    else
    {
        /* Leaving the main menu means starting the game, if you start the game with an in-game
        * speedrun time of 0, you're clearly playing a reset file.
        */
        if (vars.Unity["gameState"].Current != "Main Menu" && vars.Unity["totalPlaytime"].Current == 0) 
        {
            vars.nextSplitLevelIndex = 9; // Reset the next split level index.
            vars.justUnlockedGate = false;
            return true;
        }
    }
}

split
{
    if (settings["gates"])
    {
        // Split each time a gate is opened. This checks that your last star gain was enough to unlock a gate,
        // and then waits for you to get back to the Level Select after the gate open animation.
        var starCount = vars.Unity["starCount"];

        if (starCount.Changed) {
            // Only check if the star count has changed.
            foreach (int breakpoint in vars.gateBreakpoints) {
                if (starCount.Current < breakpoint) {
                    // Early exit if you don't have enough stars.
                    break;
                }

                if (starCount.Old < breakpoint && breakpoint <= starCount.Current) {
                    // If you didn't have enough stars before, but you do have enough stars now, you've opened the gate.
                    vars.justUnlockedGate = true;
                    break;
                }
            }
        }

        if (vars.justUnlockedGate && vars.Unity["gameState"].Current == "Level Select" && vars.Unity["gameState"].Old == "Cinematic")
        {
            vars.justUnlockedGate = false;
            return true;
        }

        // If you finished the final level, that's the final split
        if (vars.Unity["gameState"].Current == "Victory" && vars.Unity["levelIndex"].Current == 100) // level 101's index is 100.
        {
            return true;
        }
    } 
    else if (settings["levels"])
    {
        if (!vars.Unity["starCount"].Changed) {
            return false;
        }

        if (vars.Unity["levelIndex"].Current == vars.nextSplitLevelIndex)
        {
            vars.nextSplitLevelIndex += 10;
            if (vars.nextSplitLevelIndex == 99) {
                vars.nextSplitLevelIndex = -1;
            }
            return true;
        }
        
        // If you finished the final level, that's the final split
        if (vars.Unity["gameState"].Current == "Victory" && vars.Unity["levelIndex"].Current == 100) // level 101's index is 100.
        {
            return true;
        }
    }
    else if (settings["stars"]) 
    {
        var starCount = vars.Unity["starCount"];

        if (starCount.Changed) 
        {
            // This only goes up to 250 because the last split requires 303 stars instead of 300.
            for (int splitPoint = 50; splitPoint < 251; splitPoint += 50)
            {
                if (starCount.Current < splitPoint) {
                    // Early exit if you don't have enough stars.
                    return false;
                }

                if (starCount.Old < splitPoint && splitPoint <= starCount.Current)
                {
                    return true;
                }
            }

            if (starCount.Current == 303)
            {
                return true;
            }
        }
    }
    else if (settings["rainbowGems"]) 
    {
        var gemCount = vars.Unity["rainbowGems"];

        if (gemCount.Changed) 
        {
            // This only goes up to 99 because the last split requires 101 stars instead of 100.
            for (int splitPoint = 10; splitPoint < 99; splitPoint += 10)
            {
                if (gemCount.Current < splitPoint) {
                    // Early exit if you don't have enough stars.
                    return false;
                }

                if (gemCount.Old < splitPoint && splitPoint <= gemCount.Current)
                {
                    return true;
                }
            }

            if (gemCount.Current == 101)
            {
                return true;
            }
        }
    }
    else if (settings["vs_mode"])
    {
        var gameState = vars.Unity["gameState"];
        if (gameState.Changed && gameState.Current == "Playing" && vars.Unity["attemptTime"].Old > 0)
        {
            return true;
        }
    }
}

isLoading
{
    return vars.Unity["isLoading"].Current;
}

reset 
{
    if (settings["vs_mode"])
    {
        var gameState = vars.Unity["gameState"];
        return gameState.Changed && gameState.Current == "Level Select";
    }
    else
    {
        /* If you're in the main menu with a playtime of 0, you probably just reset your save file,
        * and you definitely aren't in a current run, so reset the timer.
        */
        return vars.Unity["gameState"].Current == "Main Menu" && vars.Unity["totalPlaytime"].Current == 0;
    }
}

exit
{
    vars.Unity.Reset();
}

shutdown
{
    vars.Unity.Reset();
}

gameTime
{
    if (settings["vs_mode"])
    {
        return TimeSpan.FromSeconds(vars.Unity["attemptTime"].Current);
    }
}
