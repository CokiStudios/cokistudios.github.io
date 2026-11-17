using System;
using System.IO;

namespace HiOP.WinUI3.Services;

public static class WebStageService
{
    public const string VirtualHostName = "hiopstage.local";

    public static string ResolveWebStageDirectory(AppStateService state)
    {
        // Always ensure bundled stage.html exists, and refresh looping_core.js if webcache has a newer updated version
        var bundledDir = Path.Combine(AppContext.BaseDirectory, "Assets", "WebStage");
        var runtimeStageDir = Path.Combine(state.Smiledev.ConfigDir, "webstage");
        Directory.CreateDirectory(runtimeStageDir);

        var stageHtmlSrc = Path.Combine(bundledDir, "stage.html");
        var stageHtmlDest = Path.Combine(runtimeStageDir, "stage.html");
        if (File.Exists(stageHtmlSrc))
        {
            File.Copy(stageHtmlSrc, stageHtmlDest, overwrite: true);
        }

        // Priority for looping_core.js:
        // 1. Self-updated ~/.smiledev/webcache/looping_core.js
        // 2. Workspace LoopingEngine/looping_core.js
        // 3. Bundled Assets/WebStage/looping_core.js
        var cacheCore = Path.Combine(state.Smiledev.ConfigDir, "webcache", "looping_core.js");
        var wsCore = Path.Combine(state.Workspace.WorkspaceRoot, "LoopingEngine", "looping_core.js");
        var bundledCore = Path.Combine(bundledDir, "looping_core.js");

        string chosenCore = File.Exists(cacheCore) ? cacheCore : (File.Exists(wsCore) ? wsCore : bundledCore);
        if (File.Exists(chosenCore))
        {
            File.Copy(chosenCore, Path.Combine(runtimeStageDir, "looping_core.js"), overwrite: true);
        }

        return runtimeStageDir;
    }
}
