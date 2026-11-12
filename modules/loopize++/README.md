# loopize++ (v1.0.0)

`loopize++` es la librería modular oficial de **Looping Engine** para desarrollo de juegos **3D y 2D**, unificando:

1. **Pipeline 3D Wavefront `.obj` (`obj3d.*` / `spawn3d.obj`)**: carga de archivos `.obj` (`v`, `vt`, `vn`, `f`), normalización de escala y pivote, subdivisión, exportación `.obj`, raycasting por triángulo (**Möller–Trumbore**) y renderizado en TUI, HTML5 Canvas, Tkinter y Metal 4.
2. **Integración C# (`csharp.*` / `cs!` / `cssnippet`)**: VM C# integrada sin dependencias externas (más autodetección de `dotnet`/`mcs+mono` si están instalados), clases `MonoBehaviour` (`Start`, `Update`), `Vector3`, `Quaternion`, `Mathf`, `Time`, `Debug.Log`, `Scene3D.Rotate/Translate/SetPosition`, sincronización bidireccional `LoopingBridge` y exportación `.cs`.
3. **Adiciones de Juego (`loopize.*` / `lz.*`)**:
   - **ECS**: `ecs_spawn`, `ecs_set`, `ecs_get`, `ecs_tag`, `ecs_query_tag`, `ecs_destroy`
   - **Wave Director**: `wave_add`, `wave_next`, `wave_create`, `wave_start`, `wave_step`
   - **FSM (Finite State Machine)**: `fsm_create`, `fsm_rule`, `fsm_trigger`, `fsm_state`
   - **Spring-Arm Camera & Trauma Shake**: `camera_update`, `shake`, `camera_pos`
   - **Combos, XP, Tweens, Inventario, Quests y Proyectiles**: `combo_hit`, `combo_multiplier`, `tween`, `ease`, `inventory_add`, `inventory_has`, `quest_add`, `quest_progress`, `spawn_projectile`, `step_projectiles`, `spatial_radius`.

## Ejemplo Rápido

```loop
use "loopize++"
use csharp

lz_banner("Starbound Fleet 3D")
lz_spawn_obj("StarfighterHero", "assets/models/starfighter.obj", 0, 2, 0, 1.4, "#00f5d4", "StarfighterPilotCS")
lz_spawn_obj("TitanBoss", "assets/models/omega_titan.obj", 0, 5, 36, 1.8, "#f43f5e", "OmegaTitanBossAI")

csharp.step_scripts(0.016)
lz_report()
```
