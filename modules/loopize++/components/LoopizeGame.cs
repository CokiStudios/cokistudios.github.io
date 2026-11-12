// =========================================================================
//  loopize++ C# Game SDK (MonoBehaviour + 3D .obj + WaveDirector + Camera)
//  Runs zero-dependency inside Looping C# VM OR .NET 8 / Unity / Godot
// =========================================================================

using System;
using System.Collections.Generic;

namespace Loopize
{
    public class LoopizeGameController : MonoBehaviour
    {
        public string Title = "Loopize++ 3D Arena";
        public int Wave = 1;
        public int Score = 0;
        public float ComboMultiplier = 1.0f;
        public float BoostEnergy = 100.0f;

        public void Start()
        {
            Debug.Log("[Loopize.cs] LoopizeGameController initialized for " + Title);
        }

        public void Update(float dt)
        {
            BoostEnergy = Mathf.Clamp(BoostEnergy + dt * 12.0f, 0.0f, 100.0f);
        }

        public void RegisterKill(int basePoints)
        {
            ComboMultiplier = Mathf.Min(12.0f, ComboMultiplier + 0.25f);
            Score = Score + basePoints;
            LoopingBridge.Set("lz_cs_score", Score);
            LoopingBridge.Set("lz_cs_combo", ComboMultiplier);
        }
    }

    public class StarfighterPilotCS : MonoBehaviour
    {
        public float ThrustSpeed = 28.0f;
        public float RollBankDeg = 18.0f;
        public int Shield = 100;

        public void Start()
        {
            Debug.Log("[Loopize.cs] StarfighterPilotCS armed at ThrustSpeed=" + ThrustSpeed);
        }

        public void Update(float dt)
        {
            Scene3D.Rotate("StarfighterHero", 0.0f, 24.0f * dt, 0.0f);
        }
    }

    public class OmegaTitanBossAI : MonoBehaviour
    {
        public int Phase = 1;
        public float Rage = 0.0f;

        public void Start()
        {
            Debug.Log("[Loopize.cs] OmegaTitanBossAI online — Phase 1");
        }

        public void Update(float dt)
        {
            Rage = Mathf.Clamp(Rage + dt * 5.0f, 0.0f, 100.0f);
            if (Rage >= 60.0f && Phase == 1)
            {
                Phase = 2;
                Debug.Log("[Loopize.cs] OMEGA TITAN entered ENRAGED PHASE 2!");
            }
        }
    }
}
