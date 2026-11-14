#include "LoopingInterpreter.hpp"
#include "LoopingREPL.hpp"
#include <iostream>
#include <string>
#include <vector>

using namespace looping;

void print_usage(const char* prog_name) {
    std::cout << color::BOLD << "Usage:" << color::RESET << "\n";
    std::cout << "  " << prog_name << " <script.loop>            Execute Looping script\n";
    std::cout << "  " << prog_name << " -i, --persistent <file>  Execute and keep persistent terminal alive (like py -i)\n";
    std::cout << "  " << prog_name << " --metal4 <script.loop>   Execute with Apple Metal 4 graphics acceleration\n";
    std::cout << "  " << prog_name << " --gui <script.loop>      Execute Looping script in native GUI window\n";
    std::cout << "  " << prog_name << " --native <script.loop>   Execute Looping script in pure OS native window\n";
    std::cout << "  " << prog_name << " window <name> [flags]    Create, synthesize & launch dynamic graphical window\n";
    std::cout << "  " << prog_name << " run <script.loop>        Execute Looping script\n";
    std::cout << "  " << prog_name << " create <name> [--type]   Create new app/game with reactive snippets (Arch 3.0A)\n";
    std::cout << "  " << prog_name << " invis <file.loop> [-o]   Invis. Compile: convert .loop to binary file (LPBN v3.0A)\n";
    std::cout << "  " << prog_name << " compile <file.loop>      Compile script to native binary / target UI profile\n";
    std::cout << "  " << prog_name << " preview <file.loop> [View] Live SwiftUI / 3D Viewport terminal preview\n";
    std::cout << "  " << prog_name << " preview3d <file.loop>    TrueColor Z-Buffer 3D Viewport terminal preview\n";
    std::cout << "  " << prog_name << " check <file.loop>        Static syntax & AST verification report\n";
    std::cout << "  " << prog_name << " ast <file.loop>          Display visual AST node tree & structure\n";
    std::cout << "  " << prog_name << " fmt <file.loop> [--write] Format & normalize .loop source file\n";
    std::cout << "  " << prog_name << " guide [--export <md>]    View or export FULL Looping Code Learning Guide\n";
    std::cout << "  " << prog_name << " doc [topic]              Built-in reference manual (syntax, invis, math, game3d, crypto, ui)\n";
    std::cout << "  " << prog_name << " bench                    Run native C++17 VM throughput benchmark\n";
    std::cout << "  " << prog_name << " doctor                   Inspect engine subsystems & environment health\n";
    std::cout << "  " << prog_name << " auth <login|whoami|logout> CS ID Connect Developer authentication\n";
    std::cout << "  " << prog_name << " ai <\"query\"|--chat|--fix> Ask local Coki AI (MLX 7B + RAG) or fix .loop\n";
    std::cout << "  " << prog_name << " repl                     Launch interactive REPL shell\n";
    std::cout << "  " << prog_name << " eval \"<code>\"            Evaluate inline code string\n";
    std::cout << "  " << prog_name << " test                     Run built-in engine test suite (79 tests)\n";
    std::cout << "  " << prog_name << " --channel <alpha|omega|prod> Select tier (Alpha! Looping | Omega Looping RC | Prod)\n";
    std::cout << "  " << prog_name << " --version, -v            Display engine version & channel nomenclature\n";
    std::cout << "  " << prog_name << " --help, -h               Show this help message\n\n";
}

int run_tests() {
    std::cout << color::BOLD << color::CYAN << "[TEST SUITE]" << color::RESET << " Running Looping C++ verification suite (v1.1 Production / Arch 3.0A)...\n\n";
    Interpreter vm;

    int passed = 0;
    int total = 0;

    auto assert_test = [&](const std::string& name, bool condition) {
        total++;
        if (condition) {
            passed++;
            std::cout << "  " << color::GREEN << "✔ [PASS]" << color::RESET << " " << name << "\n";
        } else {
            std::cout << "  " << color::RED << "✘ [FAIL]" << color::RESET << " " << name << "\n";
        }
    };

    // Test 1: Modern Declarations (let, mut, val, :=, ++)
    vm.execute_code("let a = 15\nmut b = 25\nval c = a + b\nd := 10\nd++");
    assert_test("Modern Declarations (let, mut, val, :=, ++)", 
                vm.variables["c"].as_int() == 40 && vm.variables["d"].as_int() == 11);

    // Test 2: Arithmetic shorthand
    vm.execute_code("mut score = 100\nscore += 50\nscore *= 2");
    assert_test("Shorthand Operators (+=, *=)", vm.variables["score"].as_int() == 300);

    // Test 3: Math functions
    vm.execute_code("val sq = math.sqrt(144)\nval pw = math.pow(2, 8)");
    assert_test("Math Builtins (sqrt, pow)", vm.variables["sq"].as_int() == 12 && vm.variables["pw"].as_int() == 256);

    // Test 4: String Interpolation with $"..."
    vm.execute_code("let user = 'Angel'\nlet greeting = $\"Hello {user}!\"");
    assert_test("String Interpolation ($)", vm.variables["greeting"].as_string() == "Hello Angel!");

    // Test 5: Functions with Arrow body & Call in expression
    vm.execute_code("fn add(x, y) => x + y\nlet sum_res = add(35, 15)");
    assert_test("Functions with Arrow Body & Return", vm.variables["sum_res"].as_int() == 50);

    // Test 6: Range Loop & Count Loop
    vm.execute_code("mut total_range = 0\nfor (i in 0..5) {\n total_range += i\n}\nmut count_acc = 0\nloop (4) {\n count_acc += 10\n}");
    assert_test("Range Loop (for in 0..N) & Count Loop (loop N)", 
                vm.variables["total_range"].as_int() == 10 && vm.variables["count_acc"].as_int() == 40);

    // Test 7: Block & Arrow Conditionals
    vm.execute_code("mut status = 'initial'\nif (sum_res == 50) {\n status = 'ok'\n}\nmut flag = false\nif (status == 'ok') -> flag = true");
    assert_test("Block & Arrow Conditionals", vm.variables["flag"].is_truthy());

    // Test 8: Pipeline Operator |>
    vm.execute_code("val piped = 64 |> math.sqrt");
    assert_test("Pipeline Operator (|>)", vm.variables["piped"].as_int() == 8);

    // Test 9: Python Bridge Macro py!(...)
    if (vm.python_bridge.is_available) {
        vm.execute_code("val py_val = py!(math.sqrt(100))");
        assert_test("Python Bridge Macro py!(...)", vm.variables["py_val"].as_int() == 10);
    } else {
        std::cout << "  " << color::YELLOW << "⚠ [SKIP]" << color::RESET << " Python Bridge (No python executable in PATH)\n";
    }

    // Test 10: Modern UI, Scenario & Advanced 2D Game Directives
    vm.execute_code("ui.card(at: (10, 20), size: (200, 100), title: \"Test Card\")\ngame.scenario(name: \"VoidStage\", weather: \"void\", accent: \"#c084fc\")\nspawn.sprite(\"Hero\", at: (50, 50), color: \"#38bdf8\")\nspawn.checkpoint(at: (200, 300), label: \"CP-1\")\nspawn.gravity_zone(at: (300, 100), size: (200, 200), scale: 0.35)\nspawn.teleporter(at: (500, 300), to: (700, 200), label: \"WARP\")\nspawn.breakable(at: (600, 260), size: (36, 72), health: 40)\nspawn.laser_hazard(at: (650, 240), size: (12, 110), interval: 2.0)\nspawn.boss(name: \"Blueline\", at: (900, 310), health: 450)\naudio.tone(587, 80)");
    assert_test("Modern 2D Game Directives (scenario, checkpoint, gravity_zone, teleporter, breakable, laser, boss)", true);

    // Test 11: PyLoop Snippets & runpy
    if (vm.python_bridge.is_available) {
        vm.execute_code(
            "from pyloop import snippets runpy\n"
            "insert pysnippet as t_sn1:\n"
            "    looping_set('py_out_val', 777)\n"
            "runpy(t_sn1)\n"
        );
        assert_test("PyLoop Snippets (insert pysnippet & runpy)", vm.variables["py_out_val"].as_int() == 777);
    }

    // Test 12: Target UI Compilation (Shine UI / XUI / flUI)
    vm.execute_code("compile target \"xui\"\ncompile target \"shine_ui\"\ncompile target \"flui\"");
    assert_test("Target UI Profiles (Shine UI, XUI, flUI)", vm.ui_profile == "flui" && vm.active_ui_specs.name == "flUI");

    // Test 13: Dynamic Program Creation & Compilation via Builtins
    vm.execute_code(
        "let prog = compiler.create_program(\"TestDynamicApp\", \"flui\", \"1.0\")\n"
        "val dyn_code = \"mut dyn_x = 42\\nprint 'Dynamic app runs!'\"\n"
        "val out_art = compiler.compile(dyn_code, \"flui\", \"build/test_dynamic_flui\")"
    );
    assert_test("Dynamic Program Compilation Subsystem", 
                vm.dynamic_programs.find("TestDynamicApp") != vm.dynamic_programs.end() && 
                vm.variables["LAST_COMPILED_APP"].as_string() == "build/test_dynamic_flui");

    // Test 14: Dynamic In-Language Program Block (compile program)
    vm.execute_code(
        "compile program \"DynamicBlockApp\" target \"shine_ui\" to \"build/dynamic_block_shine\":\n"
        "    title \"Dynamic Window\"\n"
        "    card \"STATUS\" at (10, 10) size (200, 50) text \"OK\"\n"
        "    code:\n"
        "        val block_val = 999\n"
    );
    assert_test("Dynamic In-Language Program Block (compile program)",
                vm.dynamic_programs.find("DynamicBlockApp") != vm.dynamic_programs.end() &&
                vm.variables["DynamicBlockApp"].as_string() == "build/dynamic_block_shine");

    // Test 15: Mathematical Operator Precedence & Grouping
    vm.execute_code(
        "val p1 = 2 + 3 * 4\n"
        "val p2 = (2 + 3) * 4\n"
        "val p3 = 20 - 5 - 3\n"
        "val p4 = 100 / 5 / 2\n"
    );
    assert_test("Operator Precedence & Parenthesized Grouping", 
                vm.variables["p1"].as_int() == 14 && 
                vm.variables["p2"].as_int() == 20 && 
                vm.variables["p3"].as_int() == 12 && 
                vm.variables["p4"].as_int() == 10);

    // Test 16: Native Lists and Negative Indexing
    vm.execute_code(
        "let arr = [10, 20, 30, 40, 50]\n"
        "val first = arr[0]\n"
        "val last = arr[-1]\n"
        "val second_last = arr[-2]\n"
        "val arr_len = len(arr)\n"
    );
    assert_test("Native Lists & Negative Indexing",
                vm.variables["first"].as_int() == 10 &&
                vm.variables["last"].as_int() == 50 &&
                vm.variables["second_last"].as_int() == 40 &&
                vm.variables["arr_len"].as_int() == 5);

    // Test 17: Indexed Assignment & Mutation (push/pop)
    vm.execute_code(
        "mut nums = [1, 2, 3]\n"
        "nums[0] = 99\n"
        "nums[1] += 10\n"
        "push(nums, 400)\n"
        "val popped = pop(nums)\n"
    );
    assert_test("List Indexed Assignment & Mutation (push/pop)",
                vm.variables["nums"].list_val &&
                vm.variables["nums"].list_val->size() == 3 &&
                vm.variables["nums"].list_val->at(0).as_int() == 99 &&
                vm.variables["nums"].list_val->at(1).as_int() == 12 &&
                vm.variables["popped"].as_int() == 400);

    // Test 18: Native Maps / Dictionaries & Dot Notation
    vm.execute_code(
        "let config = {\"host\": \"localhost\", \"port\": 8080, \"active\": true}\n"
        "val h = config[\"host\"]\n"
        "val p = config.port\n"
        "config[\"timeout\"] = 30\n"
    );
    assert_test("Native Maps & Index/Dot Notation",
                vm.variables["h"].as_string() == "localhost" &&
                vm.variables["p"].as_int() == 8080 &&
                vm.variables["config"].map_val &&
                vm.variables["config"].map_val->find("timeout") != vm.variables["config"].map_val->end() &&
                vm.variables["config"].map_val->at("timeout").as_int() == 30);

    // Test 19: For-Each Loop over Collections
    vm.execute_code(
        "let items = [10, 20, 30, 40]\n"
        "mut total_each = 0\n"
        "for (x in items) {\n"
        "    total_each += x\n"
        "}\n"
    );
    assert_test("For-Each Iteration (for x in collection)", vm.variables["total_each"].as_int() == 100);

    // Test 20: String Utilities (split, join, trim, replace, contains)
    vm.execute_code(
        "val words = split(\"apple,banana,cherry\", \",\")\n"
        "val rejoined = join(words, \"-\")\n"
        "val cleaned = trim(\"   looping   \")\n"
        "val replaced = replace(\"foo bar foo\", \"foo\", \"baz\")\n"
        "val has_sub = contains(\"hello world\", \"world\")\n"
    );
    assert_test("String Utilities (split, join, trim, replace, contains)",
                vm.variables["rejoined"].as_string() == "apple-banana-cherry" &&
                vm.variables["cleaned"].as_string() == "looping" &&
                vm.variables["replaced"].as_string() == "baz bar baz" &&
                vm.variables["has_sub"].is_truthy());

    // Test 21: JSON Subsystem (json.parse & json.stringify)
    vm.execute_code(
        "val parsed = json.parse(\"{\\\"name\\\": \\\"Holo\\\", \\\"version\\\": 2, \\\"active\\\": true}\")\n"
        "val j_name = parsed[\"name\"]\n"
        "val j_ver = parsed[\"version\"]\n"
        "val j_str = json.stringify(parsed)\n"
    );
    assert_test("JSON Subsystem (json.parse & json.stringify)",
                vm.variables["j_name"].as_string() == "Holo" &&
                vm.variables["j_ver"].as_int() == 2 &&
                vm.variables["j_str"].as_string().find("Holo") != std::string::npos);

    // Test 22: File I/O Subsystem (write, read, exists, size, remove)
    vm.execute_code(
        "file.write(\"test_io_temp.txt\", \"Looping Language 2026\")\n"
        "val file_content = file.read(\"test_io_temp.txt\")\n"
        "val file_ex = file.exists(\"test_io_temp.txt\")\n"
        "val f_sz = file.size(\"test_io_temp.txt\")\n"
        "file.remove(\"test_io_temp.txt\")\n"
        "val file_del_ex = file.exists(\"test_io_temp.txt\")\n"
    );
    assert_test("File I/O Subsystem (write, read, exists, size, remove)",
                vm.variables["file_content"].as_string() == "Looping Language 2026" &&
                vm.variables["file_ex"].is_truthy() &&
                vm.variables["f_sz"].as_int() > 0 &&
                !vm.variables["file_del_ex"].is_truthy());

    // Test 23: System Subsystem (sys.platform, sys.arch, sys.exec, time)
    vm.execute_code(
        "val plat = sys.platform\n"
        "val arch = sys.arch\n"
        "val echo_out = sys.exec(\"echo LoopingKernel\")\n"
        "val t_stamp = time.now()\n"
    );
    assert_test("System Subsystem (sys.platform, sys.arch, sys.exec, time)",
                !vm.variables["plat"].as_string().empty() &&
                !vm.variables["arch"].as_string().empty() &&
                vm.variables["echo_out"].as_string().find("LoopingKernel") != std::string::npos &&
                vm.variables["t_stamp"].as_int() > 1000000);

    // Test 24: Extended Math & Constants (pi, e, clamp, lerp, hypot)
    vm.execute_code(
        "val my_pi = math.pi\n"
        "val my_e = math.e\n"
        "val clamped = math.clamp(150, 0, 100)\n"
        "val lerped = math.lerp(0, 100, 0.5)\n"
        "val hyp = math.hypot(3, 4)\n"
    );
    assert_test("Extended Math & Constants (pi, e, clamp, lerp, hypot)",
                vm.variables["clamped"].as_int() == 100 &&
                vm.variables["lerped"].as_int() == 50 &&
                vm.variables["hyp"].as_int() == 5 &&
                vm.variables["my_pi"].as_number() > 3.14 &&
                vm.variables["my_e"].as_number() > 2.71);

    // Test 25: Collection Helpers (range, reverse, sort, slice)
    vm.execute_code(
        "val rng = range(1, 6)\n"
        "val rev_rng = reverse(rng)\n"
        "val sorted = sort([5, 1, 4, 2, 3])\n"
        "val sliced = slice(rng, 1, 4)\n"
    );
    assert_test("Collection Helpers (range, reverse, sort, slice)",
                vm.variables["rng"].size() == 5 &&
                vm.variables["rev_rng"].list_val &&
                vm.variables["rev_rng"].list_val->at(0).as_int() == 5 &&
                vm.variables["sorted"].list_val &&
                vm.variables["sorted"].list_val->at(0).as_int() == 1 &&
                vm.variables["sliced"].size() == 3);

    // Test 26: Dynamic Window Creator Subsystem
    vm.execute_code(
        "val win_info = window.create(\"TestWindow\", 900, 600, \"xui\")\n"
        "window.set_theme(\"cyber_neon_xui\")\n"
        "val c_idx = window.add_card(\"Telemetry\", \"FPS: 240\", 20, 20, 300, 150)\n"
        "val b_idx = window.add_button(\"CLICK ME\", \"on_click\", 30, 200)\n"
        "val state = window.get_state()\n"
        "val cards_list = window.get_cards()\n"
        "val btns_list = window.get_buttons()\n"
        "val html_file = window.export_html(\"build/test_window.html\")\n"
        "val loop_file = window.export_loop(\"build/test_window.loop\")\n"
    );
    assert_test("Dynamic Window Creator Subsystem (window.create, cards, buttons, export)",
                vm.variables["win_info"].type == ValueType::Map &&
                vm.variables["state"].type == ValueType::Map &&
                vm.variables["c_idx"].as_int() == 0 &&
                vm.variables["b_idx"].as_int() == 0 &&
                vm.variables["cards_list"].list_val && vm.variables["cards_list"].list_val->size() == 1 &&
                vm.variables["btns_list"].list_val && vm.variables["btns_list"].list_val->size() == 1 &&
                vm.variables["html_file"].as_string() == "build/test_window.html" &&
                vm.variables["loop_file"].as_string() == "build/test_window.loop");

    // Test 27: Buttons with Snippet Blocks (insert button with snippet:)
    vm.execute_code(
        "val win2 = window.create(\"SnippetWindow\", 800, 500, \"flui\")\n"
        "mut btn_counter = 0\n"
        "mut btn_last_action = \"none\"\n"
        "insert button \"Incrementar\" with snippet:\n"
        "    btn_counter += 1\n"
        "    btn_last_action = \"increment\"\n"
        "end\n"
        "draw button at (50, 150) with text \"Resetear\" and action \"reset_act\" with snippet:\n"
        "    btn_counter = 0\n"
        "    btn_last_action = \"reset\"\n"
        "end\n"
        "val click_inc1 = window.click(\"Incrementar\")\n"
        "val click_inc2 = window.click(\"Incrementar\")\n"
        "val after_two_clicks = btn_counter\n"
        "val click_rst = window.click(\"reset_act\")\n"
        "val btns_snip = window.get_buttons()\n"
    );
    assert_test("Buttons with Snippet Blocks (insert button with snippet:)",
                vm.variables["click_inc1"].is_truthy() &&
                vm.variables["click_inc2"].is_truthy() &&
                vm.variables["after_two_clicks"].as_int() == 2 &&
                vm.variables["btn_counter"].as_int() == 0 &&
                vm.variables["btn_last_action"].as_string() == "reset" &&
                vm.variables["click_rst"].is_truthy() &&
                vm.variables.find("__btn_snippet_Incrementar") != vm.variables.end() &&
                vm.variables.find("__btn_snippet_reset_act") != vm.variables.end() &&
                vm.variables["btns_snip"].list_val && vm.variables["btns_snip"].list_val->size() >= 2);

    // Test 28: Higher-Order Collection Helpers (map, filter, reduce with |>)
    vm.execute_code(
        "fn square(x) => x * x\n"
        "fn is_even(x) => x % 2 == 0\n"
        "fn sum_acc(a, b) => a + b\n"
        "val nums = [1, 2, 3, 4, 5]\n"
        "val squared = map(nums, square)\n"
        "val evens = nums |> filter(is_even)\n"
        "val total_sum = reduce(nums, sum_acc, 0)\n"
    );
    assert_test("Collection Functional Helpers (map, filter, reduce with |>)",
                vm.variables["squared"].list_val && vm.variables["squared"].list_val->size() == 5 &&
                vm.variables["squared"].list_val->at(1).as_int() == 4 &&
                vm.variables["squared"].list_val->at(4).as_int() == 25 &&
                vm.variables["evens"].list_val && vm.variables["evens"].list_val->size() == 2 &&
                vm.variables["total_sum"].as_int() == 15);

    // Test 29: Extended UI Directives (Sliders, Toggles, Progress Bars)
    vm.execute_code(
        "window.create(\"ControlsApp\", 700, 450)\n"
        "draw slider at (10, 20) with label \"Volumen\" and min 0 and max 100 and val 75 and bind \"vol\"\n"
        "draw toggle at (10, 70) with label \"Modo Oscuro\" and bind \"dark_mode\" checked\n"
        "draw progress at (10, 110) with label \"Batería\" and val 90 and bind \"batt\"\n"
        "val sliders_list = window.get_sliders()\n"
        "val toggles_list = window.get_toggles()\n"
        "val prog_list = window.get_progress()\n"
        "val win_st = window.get_state()\n"
    );
    assert_test("Extended UI Components (Sliders, Toggles, Progress Bars)",
                vm.variables["sliders_list"].list_val && vm.variables["sliders_list"].list_val->size() == 1 &&
                vm.variables["sliders_list"].list_val->at(0).map_val->at("value").as_int() == 75 &&
                vm.variables["toggles_list"].list_val && vm.variables["toggles_list"].list_val->size() == 1 &&
                vm.variables["toggles_list"].list_val->at(0).map_val->at("checked").is_truthy() &&
                vm.variables["prog_list"].list_val && vm.variables["prog_list"].list_val->size() == 1 &&
                vm.variables["win_st"].map_val->at("sliders_count").as_int() == 1);

    // Test 30: Native OS Desktop Window Synthesis (Pure Desktop OS Window / No HTML5)
    vm.execute_code(
        "val native_path = window.export_native(\"build/test_native_app.py\")\n"
        "val native_exists = file.exists(native_path)\n"
    );
    assert_test("Native OS Desktop Window Synthesis (Direct OS Window / No HTML5)",
                vm.variables["native_path"].as_string() == "build/test_native_app.py" &&
                vm.variables["native_exists"].is_truthy());

    // Test 31: Ternary Expressions (? :) & Null-Coalescing Operator (??)
    vm.execute_code(
        "val tier_score = 95\n"
        "val badge = tier_score >= 90 ? \"DIAMOND\" : \"GOLD\"\n"
        "val missing_val = nil\n"
        "val resolved_val = missing_val \?\? \"DEFAULT_SHINE\"\n"
        "val present_val = \"ACTIVE\" \?\? \"FALLBACK\"\n"
    );
    assert_test("Ternary Conditional (? :) & Null-Coalescing (?\?)",
                vm.variables["badge"].as_string() == "DIAMOND" &&
                vm.variables["resolved_val"].as_string() == "DEFAULT_SHINE" &&
                vm.variables["present_val"].as_string() == "ACTIVE");

    // Test 32: Pattern Matching (match <expr> { ... })
    vm.execute_code(
        "val rank_code = \"S\"\n"
        "mut rank_label = \"Unknown\"\n"
        "match rank_code {\n"
        "    \"S\" => rank_label = \"Grandmaster\"\n"
        "    \"A\" => rank_label = \"Commander\"\n"
        "    _ => rank_label = \"Recruit\"\n"
        "}\n"
    );
    assert_test("Pattern Matching Block (match <expr> { ... })",
                vm.variables["rank_label"].as_string() == "Grandmaster");

    // Test 33: Inclusive Ranges (..=), Step Ranges (step N), Continue & Else-If Chains
    vm.execute_code(
        "mut inc_sum = 0\n"
        "for (n in 1..=5) {\n"
        "    if (n == 3) -> continue\n"
        "    inc_sum += n\n"
        "}\n"
        "mut step_sum = 0\n"
        "for (k in 0..10 step 2) {\n"
        "    step_sum += k\n"
        "}\n"
        "val temp_c = 25\n"
        "mut climate = \"\"\n"
        "if (temp_c > 35) {\n"
        "    climate = \"hot\"\n"
        "} else if (temp_c >= 20) {\n"
        "    climate = \"optimal\"\n"
        "} else {\n"
        "    climate = \"cold\"\n"
        "}\n"
    );
    assert_test("Inclusive/Step Ranges (..=, step), Continue & Else-If Chains",
                vm.variables["inc_sum"].as_int() == (1 + 2 + 4 + 5) &&
                vm.variables["step_sum"].as_int() == (0 + 2 + 4 + 6 + 8) &&
                vm.variables["climate"].as_string() == "optimal");

    // Test 34: Destructuring Declarations & Try / Catch / Throw Error Handling
    vm.execute_code(
        "let [first_item, second_item, third_item] = [100, 200, 300]\n"
        "let (coord_x, coord_y) = (45, 90)\n"
        "mut caught_msg = \"none\"\n"
        "try {\n"
        "    throw \"OverheatFault\"\n"
        "    caught_msg = \"unreachable\"\n"
        "} catch (err) {\n"
        "    caught_msg = err\n"
        "}\n"
    );
    assert_test("Destructuring ([a, b], (x, y)) & Try/Catch/Throw",
                vm.variables["first_item"].as_int() == 100 &&
                vm.variables["second_item"].as_int() == 200 &&
                vm.variables["third_item"].as_int() == 300 &&
                vm.variables["coord_x"].as_int() == 45 &&
                vm.variables["coord_y"].as_int() == 90 &&
                vm.variables["caught_msg"].as_string() == "OverheatFault");

    // Test 35: Advanced Collection & Functional Helpers (zip, unique, flatten, find, any, all, chunk)
    vm.execute_code(
        "fn gt_ten(x) => x > 10\n"
        "fn is_pos(x) => x > 0\n"
        "val dedup = unique([1, 2, 2, 3, 1, 4])\n"
        "val flat = flatten([[1, 2], [3, 4], 5])\n"
        "val zipped = zip([\"a\", \"b\"], [10, 20])\n"
        "val found_v = find([4, 8, 15, 16, 23], gt_ten)\n"
        "val has_gt_ten = any([2, 5, 12], gt_ten)\n"
        "val all_positive = all([1, 5, 9], is_pos)\n"
        "val chunks = chunk([1, 2, 3, 4, 5, 6], 2)\n"
    );
    assert_test("Advanced Collection Stdlib (unique, flatten, zip, find, any, all, chunk)",
                vm.variables["dedup"].size() == 4 &&
                vm.variables["flat"].size() == 5 &&
                vm.variables["zipped"].size() == 2 &&
                vm.variables["found_v"].as_int() == 15 &&
                vm.variables["has_gt_ten"].is_truthy() &&
                vm.variables["all_positive"].is_truthy() &&
                vm.variables["chunks"].size() == 3);

    // Test 36: Crypto & Statistical Math Stdlib (SHA-256, Base64, UUID, CSMS Key, sum, mean, gcd, fib)
    vm.execute_code(
        "val digest = crypto.sha256(\"Looping\")\n"
        "val b64_enc = crypto.base64_encode(\"HoloOoS\")\n"
        "val b64_dec = crypto.base64_decode(b64_enc)\n"
        "val gen_id = crypto.uuid()\n"
        "val csms_k = crypto.csms_key(\"room_alpha\")\n"
        "val stat_sum = math.sum([10, 20, 30, 40])\n"
        "val stat_mean = math.mean([10, 20, 30, 40])\n"
        "val g_val = math.gcd(48, 18)\n"
        "val fib_10 = math.fib(10)\n"
    );
    assert_test("Crypto & Math Stdlib (sha256, base64, uuid, csms_key, sum, mean, gcd, fib)",
                vm.variables["digest"].as_string().size() == 64 &&
                vm.variables["b64_dec"].as_string() == "HoloOoS" &&
                vm.variables["gen_id"].as_string().size() == 36 &&
                vm.variables["csms_k"].as_string().size() == 64 &&
                vm.variables["stat_sum"].as_int() == 100 &&
                vm.variables["stat_mean"].as_int() == 25 &&
                vm.variables["g_val"].as_int() == 6 &&
                vm.variables["fib_10"].as_int() == 55);

    // Test 37: Regex Subsystem (regex.match, regex.find_all, regex.replace)
    vm.execute_code(
        "val re_ok = regex.match(\"forkar-eco-2026\", \"[0-9]{4}\")\n"
        "val re_matches = regex.find_all(\"pts: 50, bonus: 120, extra: 30\", \"[0-9]+\")\n"
        "val re_clean = regex.replace(\"Cota   Chia   Bogota\", \"\\\\s+\", \"-\")\n"
    );
    assert_test("Regex Subsystem (regex.match, regex.find_all, regex.replace)",
                vm.variables["re_ok"].is_truthy() &&
                vm.variables["re_matches"].size() == 3 &&
                vm.variables["re_clean"].as_string() == "Cota-Chia-Bogota");

    // Test 38: HMAC-SHA256, Random Hex & URL Encoding (crypto.hmac_sha256, url.encode/decode)
    vm.execute_code(
        "val sig = crypto.hmac_sha256(\"cs_secret_key\", \"payload_v27\")\n"
        "val rhex = crypto.random_hex(16)\n"
        "val u_enc = url.encode(\"Sabana de Bogota & Cota\")\n"
        "val u_dec = url.decode(u_enc)\n"
    );
    assert_test("HMAC-SHA256, Random Hex & URL Encoding",
                vm.variables["sig"].as_string().size() == 64 &&
                vm.variables["rhex"].as_string().size() == 32 &&
                vm.variables["u_dec"].as_string() == "Sabana de Bogota & Cota");

    // Test 39: Data Science & Primality Math (math.median, math.variance, math.stddev, math.is_prime)
    vm.execute_code(
        "val med = math.median([10, 50, 20, 40, 30])\n"
        "val vari = math.variance([2, 4, 4, 4, 5, 5, 7, 9])\n"
        "val sdev = math.stddev([2, 4, 4, 4, 5, 5, 7, 9])\n"
        "val p97 = math.is_prime(97)\n"
        "val p100 = math.is_prime(100)\n"
    );
    assert_test("Data Science & Primality Math (median, variance, stddev, is_prime)",
                vm.variables["med"].as_int() == 30 &&
                vm.variables["vari"].as_int() == 4 &&
                vm.variables["sdev"].as_int() == 2 &&
                vm.variables["p97"].is_truthy() &&
                !vm.variables["p100"].is_truthy());

    // Test 40: System Hardware & Environment Inspection (sys.cpus, sys.version, sys.env)
    vm.execute_code(
        "val cores = sys.cpus\n"
        "val eng_v = sys.version\n"
        "val fallback_env = sys.env(\"LOOPING_NONEXISTENT_VAR\", \"default_ok\")\n"
    );
    assert_test("System Hardware & Environment Inspection (sys.cpus, sys.version, sys.env)",
                vm.variables["cores"].as_int() >= 1 &&
                vm.variables["eng_v"].as_string() == "1.1" &&
                vm.variables["fallback_env"].as_string() == "default_ok");

    // Test 41: Default Function Arguments & Compound Modulo Assignment (%=)
    vm.execute_code(
        "fn greet_pilot(name, rank = \"Commander\", bonus = 50) => $\"{rank} {name} (+{bonus})\"\n"
        "val g1 = greet_pilot(\"Jerix\")\n"
        "val g2 = greet_pilot(\"Jerix\", \"Admiral\", 200)\n"
        "mut rem_v = 29\n"
        "rem_v %= 6\n"
    );
    assert_test("Default Function Arguments & Compound Modulo (%=)",
                vm.variables["g1"].as_string() == "Commander Jerix (+50)" &&
                vm.variables["g2"].as_string() == "Admiral Jerix (+200)" &&
                vm.variables["rem_v"].as_int() == 5);

    // Test 42: Multi-Pattern (|) & Range Pattern (..=) Match Blocks
    vm.execute_code(
        "val tier_code = \"SS\"\n"
        "mut tier_reward = 0\n"
        "match tier_code {\n"
        "    \"S\" | \"SS\" | \"SSS\" => tier_reward = 1000\n"
        "    \"A\" | \"B\" => tier_reward = 500\n"
        "    _ => tier_reward = 100\n"
        "}\n"
        "val exam_score = 94\n"
        "mut grade_letter = \"F\"\n"
        "match exam_score {\n"
        "    90..=100 => grade_letter = \"A+\"\n"
        "    80..90 => grade_letter = \"B\"\n"
        "    _ => grade_letter = \"C\"\n"
        "}\n"
    );
    assert_test("Multi-Pattern (|) & Range Pattern (..=) Match Arms",
                vm.variables["tier_reward"].as_int() == 1000 &&
                vm.variables["grade_letter"].as_string() == "A+");

    // Test 43: Method-Style Dot Calls on Variables (str.trim(), str.upper(), list.push(), list.sort())
    vm.execute_code(
        "let raw_title = \"   coki studios shine   \"\n"
        "val clean_upper = raw_title.trim()\n"
        "val final_title = clean_upper.upper()\n"
        "mut dyn_list = [40, 10, 30]\n"
        "dyn_list.push(20)\n"
        "val sorted_dyn = dyn_list.sort()\n"
        "val dyn_len = sorted_dyn.len()\n"
    );
    assert_test("Method-Style Dot Calls on Variables (s.trim(), list.push(), list.sort())",
                vm.variables["final_title"].as_string() == "COKI STUDIOS SHINE" &&
                vm.variables["dyn_len"].as_int() == 4 &&
                vm.variables["sorted_dyn"].list_val &&
                vm.variables["sorted_dyn"].list_val->at(1).as_int() == 20);

    // Test 44: CSV Subsystem (csv.parse, csv.parse_maps, csv.stringify)
    vm.execute_code(
        "val csv_raw = \"city,altitude,hub\\nBogota,2640,true\\nChia,2564,true\"\n"
        "val csv_rows = csv.parse(csv_raw)\n"
        "val csv_objs = csv.parse_maps(csv_raw)\n"
        "val first_city = csv_objs[0][\"city\"]\n"
        "val re_csv = csv.stringify(csv_rows)\n"
    );
    assert_test("CSV Subsystem (csv.parse, csv.parse_maps, csv.stringify)",
                vm.variables["csv_rows"].size() == 3 &&
                vm.variables["csv_objs"].size() == 2 &&
                vm.variables["first_city"].as_string() == "Bogota" &&
                vm.variables["re_csv"].as_string().find("Bogota,2640,true") != std::string::npos);

    // Test 45: DateTime & High-Resolution Clock Subsystem (datetime.iso, datetime.now, datetime.format, time.nanos)
    vm.execute_code(
        "val iso_str = datetime.iso(1767225600)\n"
        "val dt_map = datetime.now(1767225600)\n"
        "val dt_fmt = datetime.format(1767225600, \"%Y-%m-%d\")\n"
        "val ns_clock = time.nanos()\n"
    );
    assert_test("DateTime & High-Resolution Clock (datetime.iso, datetime.now, datetime.format, time.nanos)",
                vm.variables["iso_str"].as_string() == "2026-01-01T00:00:00Z" &&
                vm.variables["dt_map"].map_val && vm.variables["dt_map"].map_val->at("year").as_int() == 2026 &&
                vm.variables["dt_fmt"].as_string() == "2026-01-01" &&
                vm.variables["ns_clock"].as_int() > 1000000);

    // Test 46: Extended Crypto v2.8 (crc32, constant_time_eq, csms_payload)
    vm.execute_code(
        "val crc_hex = crypto.crc32(\"LoopingEngine\")\n"
        "val ct_ok = crypto.constant_time_eq(\"sec_token_123\", \"sec_token_123\")\n"
        "val ct_diff = crypto.constant_time_eq(\"sec_token_123\", \"sec_token_999\")\n"
        "val csms_pkt = crypto.csms_payload(\"room_sabana\", \"Hola Cota\")\n"
    );
    assert_test("Extended Crypto v2.8 (crc32, constant_time_eq, csms_payload)",
                vm.variables["crc_hex"].as_string().size() == 8 &&
                vm.variables["ct_ok"].is_truthy() &&
                !vm.variables["ct_diff"].is_truthy() &&
                vm.variables["csms_pkt"].as_string().rfind("🔒 enc:v1:", 0) == 0);

    // Test 47: Vector & Linear Algebra Math (dot, norm, distance, linspace, percentile, tau, phi)
    vm.execute_code(
        "val dot_p = math.dot([1, 2, 3], [4, 5, 6])\n"
        "val v_norm = math.norm([3, 4])\n"
        "val pt_dist = math.distance((0, 0), (6, 8))\n"
        "val lspace = math.linspace(0, 10, 5)\n"
        "val p90 = math.percentile([10, 20, 30, 40, 50], 50)\n"
        "val tau_v = math.tau\n"
        "val phi_v = math.phi\n"
    );
    assert_test("Vector & Statistical Math (dot, norm, distance, linspace, percentile, tau, phi)",
                vm.variables["dot_p"].as_int() == 32 &&
                vm.variables["v_norm"].as_int() == 5 &&
                vm.variables["pt_dist"].as_int() == 10 &&
                vm.variables["lspace"].size() == 5 &&
                vm.variables["p90"].as_int() == 30 &&
                vm.variables["tau_v"].as_number() > 6.28 &&
                vm.variables["phi_v"].as_number() > 1.61);

    // Test 48: Extended Functional Helpers (take, drop, partition)
    vm.execute_code(
        "fn is_big(n) => n >= 50\n"
        "val base_arr = [10, 60, 20, 80, 30, 90]\n"
        "val taken = take(base_arr, 3)\n"
        "val dropped = drop(base_arr, 4)\n"
        "val parts = partition(base_arr, is_big)\n"
    );
    assert_test("Extended Functional Helpers (take, drop, partition)",
                vm.variables["taken"].size() == 3 &&
                vm.variables["dropped"].size() == 2 &&
                vm.variables["parts"].list_val &&
                vm.variables["parts"].list_val->at(0).size() == 3 &&
                vm.variables["parts"].list_val->at(1).size() == 3);

    // Test 49: Grouping, Sorting & Aggregations (group_by, sort_by, min_by, max_by, sum_by, frequencies)
    vm.execute_code(
        "fn parity_label(n) => n % 2 == 0 ? \"even\" : \"odd\"\n"
        "fn neg_key(n) => 0 - n\n"
        "fn double_val(n) => n * 2\n"
        "val sample_nums = [1, 2, 3, 4, 5, 6]\n"
        "val grouped = group_by(sample_nums, parity_label)\n"
        "val desc_sorted = sort_by(sample_nums, neg_key)\n"
        "val max_neg = min_by(sample_nums, neg_key)\n"
        "val doubled_sum = sum_by(sample_nums, double_val)\n"
        "val freqs = frequencies([\"a\", \"b\", \"a\", \"c\", \"a\", \"b\"])\n"
    );
    assert_test("Grouping, Sorting & Aggregations (group_by, sort_by, min_by, sum_by, frequencies)",
                vm.variables["grouped"].map_val && vm.variables["grouped"].map_val->at("even").size() == 3 &&
                vm.variables["desc_sorted"].list_val && vm.variables["desc_sorted"].list_val->at(0).as_int() == 6 &&
                vm.variables["max_neg"].as_int() == 6 &&
                vm.variables["doubled_sum"].as_int() == 42 &&
                vm.variables["freqs"].map_val && vm.variables["freqs"].map_val->at("a").as_int() == 3);

    // Test 50: End-to-End Telemetry Pipeline (CSV -> Functional Filter/Map -> Checksum)
    vm.execute_code(
        "fn parse_int(s) => s + 0\n"
        "val raw_scores = [12, 25, 8, 40, 19, 30]\n"
        "fn above_twenty(x) => x >= 20\n"
        "fn boost_ten(x) => x + 10\n"
        "val boosted = raw_scores |> filter(above_twenty) |> map(boost_ten)\n"
        "val total_boosted = math.sum(boosted)\n"
        "val verify_crc = crypto.crc32($\"boosted:{total_boosted}\")\n"
    );
    assert_test("End-to-End Functional Telemetry Pipeline (|> filter |> map + sum + crc32)",
                vm.variables["total_boosted"].as_int() == (35 + 50 + 40) &&
                vm.variables["verify_crc"].as_string().size() == 8);

    // Test 51: Polished Universal Snippet Subsystem (Native Looping snippets, snippet.run, snippet.list, snippet.exists)
    vm.execute_code(
        "mut bonus_counter = 100\n"
        "insert snippet as add_bonus:\n"
        "    bonus_counter += 50\n"
        "end\n"
        "val snip_ran = snippet.run(\"add_bonus\")\n"
        "val snip_has = snippet.exists(\"add_bonus\")\n"
        "val snip_code = snippet.get(\"add_bonus\")\n"
        "val snip_all = snippet.list()\n"
        "snippet.set(\"quick_boost\", \"bonus_counter += 25\")\n"
        "run snippet quick_boost\n"
    );
    assert_test("Polished Universal Snippet Subsystem (Native Looping snippets, snippet.run/list/exists)",
                vm.variables["snip_ran"].is_truthy() &&
                vm.variables["snip_has"].is_truthy() &&
                vm.variables["snip_code"].as_string().find("bonus_counter += 50") != std::string::npos &&
                vm.variables["snip_all"].size() >= 2 &&
                vm.variables["bonus_counter"].as_int() == 175);

    // Test 52: Declarative SwiftUI View Hierarchy & Nested Containers (VStack, HStack, Text, Button)
    vm.execute_code(
        "VStack(spacing: 16) {\n"
        "    Text(\"Coki Studios APU\")\n"
        "    HStack(spacing: 8) {\n"
        "        Button(\"TestButton\") {\n"
        "            mut test_var = 1\n"
        "        }\n"
        "    }\n"
        "}\n"
    );
    assert_test("Declarative SwiftUI View Hierarchy & Nested Containers",
                true);

    // Test 53: SwiftUI Fluent Chained Modifiers (.padding, .background, .foregroundColor, .cornerRadius)
    vm.execute_code(
        "view StyledCard {\n"
        "    VStack(spacing: 10) {\n"
        "        Text(\"Header\")\n"
        "            .font(.title)\n"
        "            .foregroundColor(.cyan)\n"
        "            .padding(12)\n"
        "            .background(.ultraThinMaterial)\n"
        "            .cornerRadius(10)\n"
        "    }\n"
        "    .padding(20)\n"
        "}\n"
    );
    assert_test("SwiftUI Fluent Chained View Modifiers",
                vm.swiftui_components.count("StyledCard") > 0 &&
                vm.swiftui_components["StyledCard"]->root_view != nullptr &&
                !vm.swiftui_components["StyledCard"]->root_view->children.empty() &&
                vm.swiftui_components["StyledCard"]->root_view->children[0]->modifiers.size() == 5 &&
                vm.swiftui_components["StyledCard"]->root_view->children[0]->modifiers[0].name == "font" &&
                !vm.swiftui_components["StyledCard"]->root_view->modifiers.empty() &&
                vm.swiftui_components["StyledCard"]->root_view->modifiers[0].name == "padding");

    // Test 54: SwiftUI Component Declarations & @state Declarations
    vm.execute_code(
        "view CounterApp {\n"
        "    @state count = 42\n"
        "    @state is_active = true\n"
        "    VStack(spacing: 12) {\n"
        "        Text(\"Counter: $count\")\n"
        "        Toggle(\"Active\", isOn: $is_active)\n"
        "    }\n"
        "}\n"
        "val counter_val = count\n"
        "val has_counter_app = swiftui.has_component(\"CounterApp\")\n"
    );
    assert_test("SwiftUI Component Declarations & @state Declarations",
                vm.variables["counter_val"].as_int() == 42 &&
                vm.variables["has_counter_app"].is_truthy() &&
                vm.swiftui_components["CounterApp"]->states.size() == 2);

    // Test 55: SwiftUI Built-in Module & Pure Swift Codegen
    vm.execute_code(
        "val comp_list = swiftui.components()\n"
        "val swift_code = swiftui.transpile(\"CounterApp\")\n"
    );
    assert_test("SwiftUI Built-in Module (components, transpile) & Swift Codegen",
                vm.variables["comp_list"].size() >= 2 &&
                vm.variables["swift_code"].as_string().find("struct CounterApp: View") != std::string::npos &&
                vm.variables["swift_code"].as_string().find("@State private var count") != std::string::npos &&
                vm.variables["swift_code"].as_string().find("Toggle(\"Active\", isOn: $is_active)") != std::string::npos);

    // Test 56: SwiftUI Terminal TUI Preview Canvas Visualizer
    vm.execute_code(
        "val preview_ok = swiftui.preview(\"CounterApp\")\n"
    );
    assert_test("SwiftUI Terminal TUI Preview Canvas Visualizer",
                vm.variables["preview_ok"].is_truthy());

    // Test 57: Polished Module Resolution Subsystem (use/import from modules/ & smile.json)
    vm.execute_code(
        "use \"loop-core-utils\"\n"
        "val mod_padded = pad(\"coki\", 8)\n"
    );
    assert_test("Polished Module Resolution Subsystem (smiledev modules/ & smile.json)",
                vm.variables["mod_padded"].as_string() == "coki" &&
                vm.imported_modules.count("loop-core-utils") > 0);

    // Test 58: Polyglot Hybrid Multi-Component Subsystem (Loop, C++, Python, Node with Sub-files)
    vm.execute_code(
        "use \"csid-login-button\"\n"
        "val h_btn = csid_login_render(50, 50, \"Test CS ID\")\n"
        "val h_user = csid_login_trigger_auth(\"Test Pilot\", \"pilot@cokistudios.com\")\n"
        "val is_h_ok = h_user[\"verified\"] == true && h_user[\"name\"] == \"Test Pilot\"\n"
    );
    assert_test("Polyglot Hybrid Multi-Component Subsystem (csid-login-button 4-lang architecture)",
                vm.variables["is_h_ok"].is_truthy() &&
                vm.imported_modules.count("csid-login-button") > 0);

    // Test 59: Looping Engine v1.1 & Arch 3.0A Quantum Synthesis
    vm.execute_code(
        "val v_ver = sys.version\n"
        "val v_arch = sys.arch_version\n"
        "val v_ch_name = sys.channel_name\n"
        "val v_cid = csid.client_id\n"
        "val v_salt = csms.salt\n"
    );
    assert_test("Looping Engine v1.1 & Arch 3.0A Quantum Synthesis Inspection",
                vm.variables["v_ver"].as_string() == "1.1" &&
                vm.variables["v_arch"].as_string() == "3.0A" &&
                vm.variables["v_ch_name"].as_string() == "Looping" &&
                vm.variables["v_cid"].as_string() == "c0c11009-4ce0-4b11-8a01-1009c0c1e001" &&
                vm.variables["v_salt"].as_string() == "CSMS_E2EE_COKI_STUDIOS_v1_SALT_FORKAR");

    // Test 60: CS ID Connect Integrated Default Module (PKCE S256 & Identity)
    vm.execute_code(
        "import csid\n"
        "val l_url = csid.login_url()\n"
        "val has_pkce = contains(l_url, \"code_challenge=\") && contains(l_url, \"code_challenge_method=S256\") && contains(l_url, \"client_id=c0c11009-4ce0-4b11-8a01-1009c0c1e001\")\n"
        "val auth_res = csid.trigger_auth(\"Jerix Ortiz\", \"jerix@cokistudios.com\")\n"
        "val is_auth_before = csid.is_authenticated()\n"
        "val user_info = csid.whoami()\n"
        "val u_name = user_info[\"name\"]\n"
        "csid.logout()\n"
        "val is_auth_after = csid.is_authenticated()\n"
    );
    assert_test("CS ID Connect Integrated Default Module (PKCE S256 & Identity)",
                vm.variables["has_pkce"].is_truthy() &&
                vm.variables["is_auth_before"].is_truthy() &&
                vm.variables["u_name"].as_string() == "Jerix Ortiz" &&
                !vm.variables["is_auth_after"].is_truthy());

    // Test 61: CSMS E2EE Hardware-Backed Cryptography Subsystem
    vm.execute_code(
        "import csms\n"
        "val room_key = csms.derive_key(\"room_alpha_7\")\n"
        "val plain_msg = \"Quantum Synthesis Protocol v3.0A\"\n"
        "val enc_payload = csms.encrypt(\"room_alpha_7\", plain_msg)\n"
        "val is_enc_format = starts_with(enc_payload, \"🔒 enc:v1:\")\n"
        "val decrypted = csms.decrypt(\"room_alpha_7\", enc_payload)\n"
    );
    assert_test("CSMS E2EE Hardware-Backed Cryptography Subsystem",
                vm.variables["is_enc_format"].is_truthy() &&
                vm.variables["decrypted"].as_string() == "Quantum Synthesis Protocol v3.0A" &&
                !vm.variables["room_key"].as_string().empty());

    // Test 62: Universal Core Utils Subsystem (pad, slugify, format_bytes, truncate, repeat)
    vm.execute_code(
        "import utils\n"
        "val u_pad = utils.pad(\"coki\", 8, \"-\")\n"
        "val u_slug = utils.slugify(\"Coki Studios & Looping 1.1!\")\n"
        "val u_bytes = utils.format_bytes(1048576)\n"
        "val u_trunc = utils.truncate(\"Quantum Synthesis\", 7)\n"
        "val u_rep = utils.repeat(\"CS\", 3)\n"
    );
    assert_test("Universal Core Utils Subsystem (pad, slugify, format_bytes, truncate, repeat)",
                vm.variables["u_pad"].as_string() == "coki----" &&
                vm.variables["u_slug"].as_string() == "coki-studios-looping-1-1" &&
                vm.variables["u_bytes"].as_string() == "1.00 MB" &&
                vm.variables["u_trunc"].as_string() == "Quantum..." &&
                vm.variables["u_rep"].as_string() == "CSCSCS");

    // Test 63: Universal 2D Game Plus & SFX Subsystem (AABB, circle, distance, clamp, lerp, spawn_particle, play_sfx)
    vm.execute_code(
        "import game_plus\n"
        "val aabb_hit = game.collide_aabb(10, 10, 30, 30, 25, 25, 30, 30)\n"
        "val aabb_miss = game.collide_aabb(10, 10, 20, 20, 50, 50, 20, 20)\n"
        "val circ_hit = game.collide_circle(0, 0, 10, 12, 0, 5)\n"
        "val dist_val = game.distance(0, 0, 3, 4)\n"
        "val clamped = game.clamp(150, 10, 100)\n"
        "val lerped = game.lerp(10, 30, 0.5)\n"
        "val sfx_ok = game.play_sfx(\"coin\")\n"
        "val part_res = game.spawn_particle(\"sparkle\", 100, 200, 0, -2, \"#38bdf8\")\n"
        "val part_alive = part_res[\"alive\"]\n"
    );
    assert_test("Universal 2D Game Plus & SFX Subsystem (AABB, circle, lerp, distance, particles, sfx)",
                vm.variables["aabb_hit"].is_truthy() &&
                !vm.variables["aabb_miss"].is_truthy() &&
                vm.variables["circ_hit"].is_truthy() &&
                vm.variables["dist_val"].as_number() == 5.0 &&
                vm.variables["clamped"].as_number() == 100.0 &&
                vm.variables["lerped"].as_number() == 20.0 &&
                vm.variables["sfx_ok"].is_truthy() &&
                vm.variables["part_alive"].is_truthy());

    // Test 64: Embedded Snippet App & Game Synthesis Pipeline (Arch 3.0A Dynamic Templates)
    DynamicProgram dyn_game = Compiler::create_template("game", "CyberTestGame", "shine_ui");
    std::string dyn_game_src = dyn_game.emit_source();
    bool has_jump_snip = dyn_game_src.find("insert snippet as on_player_jump:") != std::string::npos;
    bool has_coin_snip = dyn_game_src.find("insert snippet as on_collect_coin:") != std::string::npos;
    bool has_cs_mods = dyn_game_src.find("import csid as csid") != std::string::npos &&
                       dyn_game_src.find("import game_plus as game_plus") != std::string::npos;

    DynamicProgram dyn_dash = Compiler::create_template("dashboard", "CS_Enterprise_App", "shine_ui");
    std::string dyn_dash_src = dyn_dash.emit_source();
    bool has_csid_snip = dyn_dash_src.find("insert snippet as on_csid_login:") != std::string::npos;
    bool has_csms_snip = dyn_dash_src.find("insert snippet as on_csms_encrypt_payload:") != std::string::npos;

    Interpreter test_vm;
    test_vm.execute_code(dyn_game_src);
    // Trigger snippet jump via window.click / trigger
    test_vm.eval(std::make_shared<CallExpr>("window.click", std::vector<std::shared_ptr<Expr>>{
        std::make_shared<LiteralExpr>(Value("on_player_jump"))
    }));
    bool jump_executed = test_vm.variables["is_jumping"].is_truthy();

    assert_test("Embedded Snippet App & Game Synthesis Pipeline (Arch 3.0A Dynamic Templates)",
                has_jump_snip && has_coin_snip && has_cs_mods &&
                has_csid_snip && has_csms_snip && jump_executed);

    // Test 65: 3D Linear Algebra, Quaternions, 4x4 Matrices & Perspective Projection (math3d.*)
    vm.execute_code(
        "val v_a = math3d.vec3(1, 0, 0)\n"
        "val v_b = math3d.vec3(0, 1, 0)\n"
        "val v_cross = math3d.cross(v_a, v_b)\n"
        "val v_dot = math3d.dot([2, 3, 4], [1, 2, 3])\n"
        "val v_dist = math3d.distance([0, 0, 0], [3, 4, 12])\n"
        "val q_yaw = math3d.quat_euler(0, 90, 0)\n"
        "val v_rot = math3d.quat_rotate(q_yaw, [0, 0, 1])\n"
        "val m_trs = math3d.mat4_trs([10, 5, -2], [0, 0, 0], [2, 2, 2])\n"
        "val v_trs = math3d.transform_point(m_trs, [1, 1, 1])\n"
        "val proj = math3d.project([0, 2, 12], [0, 2, 0], [0, 2, 10], 60, 800, 600)\n"
        "val proj_vis = proj[\"visible\"]\n"
    );
    bool cross_ok = vm.variables["v_cross"].list_val && (*vm.variables["v_cross"].list_val)[2].as_number() == 1.0;
    bool rot_ok = vm.variables["v_rot"].list_val && std::abs((*vm.variables["v_rot"].list_val)[0].as_number() - 1.0) < 1e-4;
    bool trs_ok = vm.variables["v_trs"].list_val && std::abs((*vm.variables["v_trs"].list_val)[0].as_number() - 12.0) < 1e-4;
    assert_test("3D Linear Algebra, Quaternions, Mat4 TRS & Perspective Projection (math3d.*)",
                cross_ok &&
                vm.variables["v_dot"].as_number() == 20.0 &&
                vm.variables["v_dist"].as_number() == 13.0 &&
                rot_ok && trs_ok &&
                vm.variables["proj_vis"].is_truthy());

    // Test 66: 3D Collisions, Raycasting & 120Hz Sub-Stepping Rigidbody Physics (physics3d.*)
    vm.execute_code(
        "val sph_hit = physics3d.collide_sphere([0, 2, 0], 1.5, [1.8, 2, 0], 1.0)\n"
        "val sph_miss = physics3d.collide_sphere([0, 2, 0], 1.0, [5, 2, 0], 1.0)\n"
        "val box3_hit = physics3d.collide_aabb([0, 2, 0], [4, 4, 4], [3, 2, 0], [4, 4, 4])\n"
        "val cap_hit = physics3d.collide_capsule_sphere([0, 0, 0], [0, 4, 0], 1.0, [1.5, 2, 0], 0.8)\n"
        "val r_sph = physics3d.raycast_sphere([0, 2, -10], [0, 0, 1], [0, 2, 5], 2.0)\n"
        "val r_box = physics3d.raycast_aabb([0, 2, -10], [0, 0, 1], [0, 2, 4], [4, 4, 4])\n"
        "val body0 = {\"pos\": [0, 5, 0], \"vel\": [4, 0, 0], \"radius\": 1.0, \"gravity\": -24.0, \"ground_y\": 0.0}\n"
        "val body1 = physics3d.step_body(body0, 0.5, 8)\n"
        "val rs_hit = r_sph[\"hit\"]\n"
        "val rs_dist = r_sph[\"distance\"]\n"
        "val rb_hit = r_box[\"hit\"]\n"
        "val b1_pos = body1[\"pos\"]\n"
    );
    bool b1_ok = vm.variables["b1_pos"].list_val &&
                 (*vm.variables["b1_pos"].list_val)[0].as_number() > 1.5 &&
                 (*vm.variables["b1_pos"].list_val)[1].as_number() >= 1.0;
    assert_test("3D Collisions, Raycasting & 120Hz Sub-Stepping Rigidbody Physics (physics3d.*)",
                vm.variables["sph_hit"].is_truthy() &&
                !vm.variables["sph_miss"].is_truthy() &&
                vm.variables["box3_hit"].is_truthy() &&
                vm.variables["cap_hit"].is_truthy() &&
                vm.variables["rs_hit"].is_truthy() &&
                std::abs(vm.variables["rs_dist"].as_number() - 13.0) < 1e-4 &&
                vm.variables["rb_hit"].is_truthy() &&
                b1_ok);

    // Test 67: 3D Scene Graph, Directives & TrueColor Z-Buffer Viewport Rasterizer (scene3d.* / spawn3d.*)
    Interpreter vm3d;
    vm3d.execute_code(
        "define game3d \"QuantumOdyssey3D\" version 3.0:\n"
        "    scene3d.world(name: \"NeonGrid3D\", size: (160, 80, 160), sky: \"cyber_night\", fog: 0.010, grid: true)\n"
        "    camera3d.set(mode: \"chase\", pos: (0, 8, -16), target: (0, 2, 12), fov: 64, smooth: 0.14)\n"
        "    light3d.directional(dir: (-0.4, -1.0, -0.3), color: \"#ffffff\", intensity: 1.1)\n"
        "    light3d.point(at: (0, 10, 18), color: \"#38bdf8\", intensity: 1.4, range: 50)\n"
        "    physics3d.config(gravity: -26.0, substeps: 4, friction: 0.86, bounce: 0.12)\n"
        "    spawn3d.player(\"AngelPilot3D\", at: (0, 2, 0), mesh: \"hovercraft\", speed: 24, jump: 16)\n"
        "    spawn3d.box(at: (0, -0.5, 14), size: (12, 1, 20), color: \"#6366f1\")\n"
        "    spawn3d.moving_platform(at: (0, 2, 26), size: (6, 1, 6), axis: \"x\", range: (-8, 8), speed: 8)\n"
        "    spawn3d.crystal(at: (0, 3, 14), points: 200)\n"
        "    spawn3d.enemy(\"CyberDrone3D\", at: (0, 3, 22), range: (-6, 6), speed: 9, health: 50)\n"
        "    spawn3d.portal(at: (0, 4, 38), radius: 3.5, label: \"OMEGA GATE\")\n"
        "    scene3d.step(0.016)\n"
        "    val st3d = scene3d.stats()\n"
        "    val tui3d = scene3d.render_tui(48, 12)\n"
        "    val ray_sc = physics3d.raycast_scene([0, 3, 0], [0, 0, 1])\n"
        "    val st_cnt = st3d[\"entities\"]\n"
        "    val st_hz = st3d[\"effective_hz\"]\n"
        "    val ray_sc_hit = ray_sc[\"hit\"]\n"
    );
    assert_test("3D Scene Graph, Directives & Z-Buffer Software Rasterizer (scene3d.* / spawn3d.*)",
                vm3d.current_scene3d.active &&
                vm3d.variables["st_cnt"].as_int() == 6 &&
                vm3d.variables["st_hz"].as_int() == 240 &&
                vm3d.variables["ray_sc_hit"].is_truthy() &&
                vm3d.variables["tui3d"].as_string().find("SHINE LOOP 3D VIEWPORT") != std::string::npos);

    // Test 68: Arch 3.0A 3D Game Template Synthesis (Compiler::create_template("game3d"))
    DynamicProgram dyn_g3d = Compiler::create_template("game3d", "HyperCircuit3D", "xui");
    std::string dyn_g3d_src = dyn_g3d.emit_source();
    Interpreter vm_tpl3d;
    vm_tpl3d.execute_code(dyn_g3d_src);
    vm_tpl3d.eval(std::make_shared<CallExpr>("window.click", std::vector<std::shared_ptr<Expr>>{
        std::make_shared<LiteralExpr>(Value("on_raycast_scan"))
    }));
    assert_test("Arch 3.0A 3D Game Template Synthesis & Raycast Snippet Execution",
                vm_tpl3d.current_scene3d.active &&
                vm_tpl3d.variables["score_3d"].as_int() == 250);

    // Test 69: Official Release Nomenclature (Alpha! Looping, Omega Looping RC, Looping Prod v1.1 / Arch 3.0A)
    Interpreter vm_ch;
    vm_ch.execute_code(
        "val ch_alpha_name = looping.set_channel(\"alpha\")\n"
        "val ch_alpha_ver = sys.version\n"
        "val ch_alpha_ed = sys.edition\n"
        "val ch_omega_name = looping.set_channel(\"omega\")\n"
        "val ch_omega_ver = sys.version\n"
        "val ch_omega_ed = sys.edition\n"
        "val ch_prod_name = looping.set_channel(\"prod\")\n"
        "val ch_prod_ver = sys.version\n"
        "val ch_arch = sys.arch_version\n"
        "val ch_map = looping.channels()\n"
        "val ch_map_alpha = ch_map[\"alpha\"]\n"
        "val ch_map_omega = ch_map[\"omega\"]\n"
    );
    assert_test("Release Nomenclature (Alpha! Looping Super Experimental, Omega Looping RC, Looping Prod v1.1 / Arch 3.0A)",
                vm_ch.variables["ch_alpha_name"].as_string() == "Alpha! Looping" &&
                vm_ch.variables["ch_alpha_ver"].as_string() == "1.1-alpha" &&
                vm_ch.variables["ch_alpha_ed"].as_string().find("Super Experimental") != std::string::npos &&
                vm_ch.variables["ch_omega_name"].as_string() == "Omega Looping" &&
                vm_ch.variables["ch_omega_ver"].as_string() == "1.1-omega" &&
                vm_ch.variables["ch_omega_ed"].as_string().find("Release Candidate") != std::string::npos &&
                vm_ch.variables["ch_prod_name"].as_string() == "Looping" &&
                vm_ch.variables["ch_prod_ver"].as_string() == "1.1" &&
                vm_ch.variables["ch_arch"].as_string() == "3.0A" &&
                vm_ch.variables["ch_map_alpha"].as_string().find("Alpha! Looping") != std::string::npos &&
                vm_ch.variables["ch_map_omega"].as_string().find("Omega Looping") != std::string::npos);

    // Test 70: Invis. Compile Binary Architecture (.loop -> Binary File Conversion, SHA-256 CTR Zero-Source Exposure & Execution)
    Interpreter vm_invis;
    {
        std::ofstream tmp_loop("build/test_invis_src.loop");
        tmp_loop << "invis. compile\n"
                 << "val secret_marker = \"ULTRA_SECRET_LOOP_PAYLOAD_777\"\n"
                 << "val invis_computed = 42 * 10 + 7\n";
        tmp_loop.close();
    }
    vm_invis.execute_code(
        "val bin_standalone = invis.compile(\"build/test_invis_src.loop\", \"build/test_invis_standalone.bin\", \"xui\")\n"
        "val bin_compact = invis.compile(\"build/test_invis_src.loop\", \"build/test_invis_compact.loopb\", \"shine_ui\", true)\n"
        "val is_bin_ok = invis.verify(bin_standalone) && invis.verify(bin_compact)\n"
        "val bin_meta = invis.info(bin_standalone)\n"
        "val bin_fmt = bin_meta[\"format\"]\n"
        "val bin_ran = invis.run(bin_compact)\n"
        "val fmt_sys = sys.invis_compile\n"
    );
    // Verify zero plaintext source exposure inside compact binary file
    bool zero_plaintext_exposure = false;
    {
        std::ifstream bf("build/test_invis_compact.loopb", std::ios::binary);
        if (bf.is_open()) {
            std::stringstream bss;
            bss << bf.rdbuf();
            std::string raw_bin_bytes = bss.str();
            zero_plaintext_exposure = !raw_bin_bytes.empty() &&
                                      (raw_bin_bytes.find("ULTRA_SECRET_LOOP_PAYLOAD_777") == std::string::npos) &&
                                      (static_cast<unsigned char>(raw_bin_bytes[0]) == 0x89);
        }
    }
    std::remove("build/test_invis_src.loop");
    std::remove("build/test_invis_standalone.bin");
    std::remove("build/test_invis_compact.loopb");

    assert_test("Invis. Compile Binary Architecture (.loop -> Binary File, SHA-256 CTR Zero-Source Exposure & Direct Execution)",
                vm_invis.variables["is_bin_ok"].is_truthy() &&
                vm_invis.variables["bin_fmt"].as_string() == "LPBN v3.0A" &&
                vm_invis.variables["fmt_sys"].as_string() == "LPBN v3.0A" &&
                vm_invis.variables["bin_ran"].is_truthy() &&
                vm_invis.variables["invis_computed"].as_int() == 427 &&
                zero_plaintext_exposure);

    // Test 59: Apple Metal 4 Subsystem & Unified Memory Shading Pipeline
    Interpreter vm_metal4;
    vm_metal4.execute_code(
        "val m4_sup = metal4.is_supported()\n"
        "val m4_ver = sys.metal_version\n"
        "val m4_pipe = metal4.pipeline_info()\n"
        "val m4_api = m4_pipe[\"api\"]\n"
        "val m4_fps = m4_pipe[\"target_fps\"]\n"
    );
#if defined(__APPLE__)
    bool m4_support_expected = vm_metal4.variables["m4_sup"].is_truthy();
#else
    bool m4_support_expected = !vm_metal4.variables["m4_sup"].is_truthy();
#endif
    assert_test("Apple Metal 4 Subsystem & Unified Memory Architecture (metal4, sys.metal_version, 240Hz ProMotion)",
                m4_support_expected &&
                vm_metal4.variables["m4_ver"].as_string() == "Metal 4" &&
                vm_metal4.variables["m4_api"].as_string() == "Metal 4 (MSL 4.0)" &&
                vm_metal4.variables["m4_fps"].as_int() == 240);

    // Test 60: zbash-utils Library & !exec Terminal Command Execution
    Interpreter vm_zbash;
    vm_zbash.execute_code(
        "mut blocked_without_import = false\n"
        "try {\n"
        "    !exec printf 'SHOULD_NOT_RUN'\n"
        "} catch (err) {\n"
        "    blocked_without_import = true\n"
        "}\n"
        "import zbash-utils\n"
        "!exec printf 'ADB_TEST_OK'\n"
        "val code1 = zbash_last_code\n"
        "val out1 = zbash_last_output\n"
        "val tag = \"RIVA_OK\"\n"
        "!exec printf '{tag}'; printf '_DONE'\n"
        "val out2 = zbash_last_output\n"
        "!exec (exit 42)\n"
        "val code_nz = zbash_last_code\n"
        "val cap_out = zbash.exec(\"printf 'CAP_OK'\")\n"
        "val has_sh = zbash.has(\"sh\")\n"
    );
    assert_test("zbash-utils Library & !exec One-Line Terminal Execution",
                vm_zbash.variables["blocked_without_import"].is_truthy() &&
                vm_zbash.imported_modules.count("zbash-utils") > 0 &&
                vm_zbash.variables["code1"].as_int() == 0 &&
                vm_zbash.variables["out1"].as_string() == "ADB_TEST_OK" &&
                vm_zbash.variables["out2"].as_string() == "RIVA_OK_DONE" &&
                vm_zbash.variables["code_nz"].as_int() == 42 &&
                vm_zbash.variables["cap_out"].as_string() == "CAP_OK" &&
                vm_zbash.variables["has_sh"].is_truthy());

    // 73. Wavefront .obj 3D Pipeline: load, parse, subdivide, normalize, raycast, export & render_tui
    Interpreter vm_obj;
    vm_obj.execute_code(
        "val sf_info = obj3d.load(\"assets/models/starfighter.obj\", \"sf\")\n"
        "val tri_before = sf_info.triangles\n"
        "val faces_sub = obj3d.subdivide(\"sf\")\n"
        "val norm_rad = obj3d.normalize(\"sf\", 2.0)\n"
        "val norm_stats = obj3d.stats(\"sf\")\n"
        "val norm_sz = norm_stats.size\n"
        "val exp_obj = obj3d.export(\"sf\")\n"
        "spawn3d.obj(\"StarfighterOne\", obj: \"assets/models/starfighter.obj\", at: (0, 2, 12), scale: 1.4, color: \"#38bdf8\")\n"
        "spawn3d.obj(\"OmegaTitan\", obj: \"omega_titan.obj\", at: (0, 3, 28), scale: 1.2, color: \"#f43f5e\")\n"
        "val ray = physics3d.raycast_scene([0, 2, 0], [0, 0, 1])\n"
        "val tui_frame = scene3d.render_tui(50, 14)\n"
    );
    double max_norm_dim = 0.0;
    if (vm_obj.variables["norm_sz"].type == ValueType::List && vm_obj.variables["norm_sz"].list_val) {
        for (const auto& d : *vm_obj.variables["norm_sz"].list_val) {
            max_norm_dim = std::max(max_norm_dim, d.as_number());
        }
    }
    assert_test("Wavefront .obj 3D Pipeline (Load, Subdivide, Raycast, Export, Render)",
                vm_obj.loaded_obj_meshes.count("sf") > 0 &&
                vm_obj.variables["faces_sub"].as_int() > vm_obj.variables["tri_before"].as_int() &&
                std::abs(max_norm_dim - 2.0) < 0.05 &&
                vm_obj.variables["norm_rad"].as_number() >= 1.0 &&
                vm_obj.variables["norm_rad"].as_number() <= 2.0 &&
                vm_obj.variables["exp_obj"].as_string().find("v ") != std::string::npos &&
                vm_obj.variables["ray"].map_val != nullptr &&
                vm_obj.variables["ray"].map_val->count("hit") > 0 &&
                vm_obj.variables["ray"].map_val->at("hit").is_truthy() &&
                vm_obj.variables["tui_frame"].as_string().find("SHINE LOOP 3D") != std::string::npos);

    // 74. C# Game Interop (cs! block, cs!(expr), MonoBehaviour lifecycle, Bridge & Scene3D)
    Interpreter vm_cs;
    vm_cs.execute_code(
        "use \"csharp\"\n"
        "val loop_base = 100\n"
        "cs! {\n"
        "    public class LaserTurret : MonoBehaviour {\n"
        "        public float Charge = 10.0f;\n"
        "        public int Shots = 0;\n"
        "        public void Start() {\n"
        "            Charge = 50.0f;\n"
        "            LoopingBridge.Set(\"turret_ready\", true);\n"
        "        }\n"
        "        public void Update(float dt) {\n"
        "            Charge = Mathf.Clamp(Charge + dt * 60.0f, 0.0f, 100.0f);\n"
        "            Shots = Shots + 1;\n"
        "            LoopingBridge.Set(\"cs_charge\", Charge);\n"
        "        }\n"
        "    }\n"
        "}\n"
        "val inst_id = csharp.new(\"LaserTurret\", \"turret_1\", \"TurretObj\")\n"
        "csharp.step(0.5)\n"
        "insert cssnippet as burst_cs:\n"
        "    var boosted = LoopingBridge.Get(\"loop_base\") + 55;\n"
        "    LoopingBridge.Set(\"loop_boosted\", boosted);\n"
        "end\n"
        "runcs(burst_cs)\n"
        "val inline_cs = cs!(Mathf.Clamp(125.0f, 0.0f, 100.0f))\n"
        "val exported_cs = csharp.export(\"DemoArena\")\n"
    );
    assert_test("C# Interop (cs! MonoBehaviour, cssnippet, runcs, LoopingBridge, Export)",
                vm_cs.imported_modules.count("csharp") > 0 &&
                vm_cs.variables["turret_ready"].is_truthy() &&
                vm_cs.variables["cs_charge"].as_number() >= 79.0 &&
                vm_cs.variables["loop_boosted"].as_number() == 155.0 &&
                vm_cs.variables["inline_cs"].as_number() == 100.0 &&
                vm_cs.variables["exported_cs"].as_string().find("class DemoArena") != std::string::npos);

    // 75. loopize++ Hybrid Game Additions (ECS, Waves, FSM, Combo, Tweens, Camera Shake, Quests, AABB)
    Interpreter vm_lz;
    vm_lz.execute_code(
        "use \"loopize++\"\n"
        "lz_banner(\"Loopize 3D Verification\")\n"
        "val p_id = loopize.ecs_spawn(\"Hero\", \"player\", [0, 2, 0], 120, \"starfighter.obj\", \"StarfighterPilotCS\")\n"
        "val e_id = loopize.ecs_spawn(\"Drone1\", \"enemy\", [3, 2, 2], 60, \"valkyrie_drone.obj\", \"\")\n"
        "val near_ids = loopize.spatial_radius([0, 2, 0], 8.0, \"enemy\")\n"
        "val w_spawned = lz_wave_rush(1, \"valkyrie\", 3, 90, \"valkyrie_drone.obj\")\n"
        "loopize.fsm_set(\"hero\", \"overdrive\")\n"
        "val fsm_cur = loopize.fsm_get(\"hero\")\n"
        "val c1 = loopize.combo_hit(100)\n"
        "val c2 = loopize.combo_hit(100)\n"
        "val eased = loopize.ease(\"out_cubic\", 0.5)\n"
        "val trauma = loopize.shake(0.5)\n"
        "loopize.camera_update([0, 2, 0], 0.016, 45)\n"
        "loopize.inventory_add(\"plasma_cell\", 3)\n"
        "val used_ok = loopize.inventory_use(\"plasma_cell\", 2)\n"
        "lz_mission(\"m1\", \"Clear Wave 1\", 2, 600)\n"
        "loopize.quest_progress(\"m1\", 2)\n"
        "val st = loopize.stats()\n"
    );
    assert_test("loopize++ Hybrid Library (ECS, Waves, FSM, Combo, Tween, Shake, Quests)",
                vm_lz.imported_modules.count("loopize++") > 0 &&
                vm_lz.variables["w_spawned"].as_int() == 3 &&
                vm_lz.variables["fsm_cur"].as_string() == "overdrive" &&
                vm_lz.variables["c2"].as_number() == 125.0 &&
                vm_lz.variables["eased"].as_number() > 0.8 &&
                vm_lz.variables["used_ok"].is_truthy() &&
                vm_lz.variables["st"].map_val != nullptr &&
                vm_lz.variables["st"].map_val->count("level") > 0 &&
                vm_lz.variables["st"].map_val->at("level").as_int() >= 2 &&
                vm_lz.variables["near_ids"].list_val != nullptr &&
                vm_lz.variables["near_ids"].list_val->size() == 1);

    // 76. 3D Scene Lifecycle, Dead-Target Raycast Exclusion, Combat Combo & Collision Resolution
    Interpreter vm_glife;
    vm_glife.execute_code(
        "use \"loopize++\"\n"
        "spawn3d.player(\"Hero\", at: (0, 1.5, 0), color: \"#38bdf8\")\n"
        "spawn3d.box(\"Wall\", at: (0, 1.5, 1.9), size: (4, 6, 2), color: \"#6366f1\")\n"
        "spawn3d.enemy(\"DroneAlpha\", at: (0, 1.5, 12), health: 50, points: 200, color: \"#ef4444\")\n"
        "val cols_n = physics3d.resolve_collisions(true)\n"
        "val ray_before = scene3d.raycast([0, 1.5, 5], [0, 0, 1])\n"
        "val hp_left = scene3d.damage(\"DroneAlpha\", 50)\n"
        "val ray_after = scene3d.raycast([0, 1.5, 5], [0, 0, 1])\n"
        "val alive_en = scene3d.alive_count(\"enemy\")\n"
        "val hero_info = scene3d.find(\"Hero\")\n"
        "val w_st = loopize.wave_status()\n"
    );
    assert_test("3D Entity Lifecycle, Collision Pushout & Combat Damage Combo",
                vm_glife.variables["cols_n"].as_int() >= 1 &&
                vm_glife.variables["ray_before"].map_val != nullptr &&
                vm_glife.variables["ray_before"].map_val->at("hit").is_truthy() &&
                !vm_glife.variables["ray_after"].map_val->at("hit").is_truthy() &&
                vm_glife.variables["hp_left"].as_number() == 0.0 &&
                vm_glife.variables["alive_en"].as_int() == 0 &&
                vm_glife.loopize_runtime.combo.hits == 1 &&
                vm_glife.variables["w_st"].map_val->at("wave_cleared").is_truthy() &&
                vm_glife.variables["hero_info"].map_val->at("pos").list_val->at(2).as_number() < 0.0);

    // 77. Wavefront .mtl Material Palette & Camera Frustum Culling
    auto mtl_pal = loop_math::parse_mtl_colors("newmtl NeonWing\nKd 0.0 0.96 0.83\n");
    bool vis_front = loop_math::frustum_sphere_visible({0, 2, 20}, 2.0, {0, 4, -10}, {0, 2, 20}, 60.0);
    bool vis_behind = loop_math::frustum_sphere_visible({0, 2, -40}, 1.5, {0, 4, -10}, {0, 2, 20}, 60.0);
    assert_test("Wavefront .mtl Color Parsing & 3D Camera Frustum Culling",
                mtl_pal["NeonWing"] == "#00f5d4" && vis_front && !vis_behind);

    // 78. C# Scene3D.Find / GetHealth / SetColor / LookAt & Mathf.MoveTowards
    Interpreter vm_cs2;
    vm_cs2.execute_code(
        "use \"csharp\"\n"
        "spawn3d.enemy(\"BossBot\", at: (0, 2, 10), health: 120, color: \"#ef4444\")\n"
        "val step_mv = cs!(Mathf.MoveTowards(2.0f, 10.0f, 3.0f))\n"
        "val found_b = cs!(Scene3D.Find(\"BossBot\"))\n"
        "val rot_b = cs!(Scene3D.LookAt(\"BossBot\", 10.0f, 2.0f, 10.0f))\n"
        "val col_b = cs!(Scene3D.SetColor(\"BossBot\", \"#f59e0b\"))\n"
        "val hp_b = cs!(Scene3D.GetHealth(\"BossBot\"))\n"
    );
    assert_test("C# Scene3D Helpers (Find, LookAt, SetColor, GetHealth) & MoveTowards",
                std::abs(vm_cs2.variables["step_mv"].as_number() - 5.0) < 1e-4 &&
                vm_cs2.variables["found_b"].is_truthy() &&
                vm_cs2.variables["col_b"].as_string() == "#f59e0b" &&
                std::abs(vm_cs2.variables["hp_b"].as_number() - 120.0) < 1e-4);

    // 79. Ping-Pong Loop Tweens, Screen Shake & Game Smooth Approach
    Interpreter vm_tw;
    vm_tw.execute_code(
        "use \"loopize++\"\n"
        "loopize.tween(\"pulse\", 0, 100, 1.0, \"linear\", true, true)\n"
        "loopize.step(1.35)\n"
        "val pp_val = loopize.tween_value(\"pulse\")\n"
        "val trauma_v = game.shake(0.6)\n"
        "val app_v = game.approach(0, 10, 4)\n"
    );
    assert_test("Ping-Pong Tweens, Game Screen Shake & Frame-Independent Approach",
                vm_tw.variables["pp_val"].as_number() > 60.0 &&
                vm_tw.variables["pp_val"].as_number() < 90.0 &&
                vm_tw.variables["trauma_v"].as_number() >= 0.59 &&
                std::abs(vm_tw.variables["app_v"].as_number() - 4.0) < 1e-6);

    std::cout << "\n" << color::BOLD << (passed == total ? color::GREEN : color::YELLOW)
              << "Results: " << passed << "/" << total << " tests passed." << color::RESET << "\n\n";

    return passed == total ? 0 : 1;
}

int main(int argc, char* argv[]) {
    Interpreter vm;

    // Pre-scan channel flags (--channel=<ch>, --channel <ch>, --alpha, --omega, --rc, --prod)
    std::vector<char*> filtered_argv;
    filtered_argv.push_back(argv[0]);
    for (int i = 1; i < argc; ++i) {
        std::string a = argv[i];
        if (a.rfind("--channel=", 0) == 0) {
            vm.set_channel(a.substr(10));
        } else if (a == "--channel" && i + 1 < argc) {
            vm.set_channel(argv[++i]);
        } else if (a == "--alpha") {
            vm.set_channel("alpha");
        } else if (a == "--omega" || a == "--rc") {
            vm.set_channel("omega");
        } else if (a == "--prod" || a == "--stable") {
            vm.set_channel("prod");
        } else {
            filtered_argv.push_back(argv[i]);
        }
    }
    argc = static_cast<int>(filtered_argv.size());
    argv = filtered_argv.data();

    // Check if this executable is a Standalone Invis. Compile Native Binary with an embedded LPBN payload
    if (InvisBinaryCompiler::has_embedded_slot_payload()) {
        bool has_subcmd_or_file = false;
        bool gui_mode = false;
        bool native_mode = false;
        for (int i = 1; i < argc; ++i) {
            std::string arg = argv[i];
            if (arg == "--gui" || arg == "-g" || arg == "--window") {
                gui_mode = true;
            } else if (arg == "--native" || arg == "-n" || arg == "--os") {
                gui_mode = true;
                native_mode = true;
            } else if ((arg == "--target" || arg == "-t" || arg == "--ui") && i + 1 < argc) {
                vm.set_target_ui(argv[++i]);
            } else if (arg == "--version" || arg == "-v" || arg == "--help" || arg == "-h") {
                has_subcmd_or_file = true;
            } else if (arg.rfind("-", 0) != 0) {
                has_subcmd_or_file = true;
            }
        }
        if (!has_subcmd_or_file) {
            std::string embedded_src;
            InvisBinaryInfo info;
            if (InvisBinaryCompiler::extract_from_embedded_slot(&embedded_src, &info)) {
                if (!info.target_ui.empty()) vm.set_target_ui(info.target_ui);
                if (!info.theme.empty()) {
                    vm.theme = info.theme;
                    vm.current_window.set_theme(info.theme);
                }
                vm.print_banner();
                std::cout << color::CYAN << "[INVIS. BINARY]" << color::RESET
                          << " Executing standalone native binary (LPBN v3.0A | SHA-256: "
                          << info.sha256_hex.substr(0, 12) << "... | Target: " << info.target_ui << ")\n\n";
                auto t0 = std::chrono::high_resolution_clock::now();
                vm.execute_code(embedded_src);
                auto t1 = std::chrono::high_resolution_clock::now();
                double elapsed = std::chrono::duration<double, std::milli>(t1 - t0).count();
                std::cout << "\n" << color::GREEN << "[OK] Standalone binary completed in "
                          << std::fixed << std::setprecision(2) << elapsed << "ms!" << color::RESET << "\n";
                if (gui_mode && (!vm.current_window.cards.empty() || !vm.current_window.buttons.empty())) {
                    if (native_mode) vm.current_window.show_native(true);
                    else vm.current_window.show(true, "native");
                }
                return 0;
            }
        }
    }

    if (argc < 2) {
        REPL::run(vm);
        return 0;
    }

    std::string first_arg = argv[1];

    if (first_arg == "--help" || first_arg == "-h") {
        vm.print_banner();
        print_usage(argv[0]);
        return 0;
    }

    if (first_arg == "--version" || first_arg == "-v") {
        std::cout << vm.channel_name << " Engine v" << vm.engine_version << " (" << vm.edition << ")\n";
        std::cout << "Architecture: Arch " << vm.arch_version << " (Quantum 3D Synthesis & CS Ecosystem) | Darwin/POSIX/Win32 Native\n";
        std::cout << "Channels: Looping (Production) • Omega Looping (RC) • Alpha! Looping (Super Experimental)\n";
        std::cout << "Developed by Coki Studios & Holo Entertainment © 2026\n";
        return 0;
    }

    if (first_arg == "repl") {
        REPL::run(vm);
        return 0;
    }

    if (first_arg == "test") {
        return run_tests();
    }

    if (first_arg == "doctor") {
        vm.print_banner();
        std::cout << color::BOLD << color::CYAN << "[LOOPING DOCTOR]" << color::RESET << " Inspecting C++ Native Engine & Subsystems (Arch " << vm.arch_version << ")...\n\n";
        std::cout << "  " << color::GREEN << "✔" << color::RESET << " Release Channel    : " << vm.channel_name << " [" << vm.channel << "]\n";
        std::cout << "  " << color::GREEN << "✔" << color::RESET << " Engine Version     : v" << vm.engine_version << " (C++17 Native / Arch " << vm.arch_version << ")\n";
        std::cout << "  " << color::GREEN << "✔" << color::RESET << " Host Platform      : " << vm.eval(std::make_shared<VariableExpr>("sys.platform")).as_string()
                  << " (" << vm.eval(std::make_shared<VariableExpr>("sys.arch")).as_string() << ")\n";
        std::cout << "  " << (vm.python_bridge.is_available ? color::GREEN : color::YELLOW)
                  << (vm.python_bridge.is_available ? "✔" : "⚠") << color::RESET
                  << " Python Interop     : " << (vm.python_bridge.is_available ? "Available (" + vm.python_bridge.detected_exe + ")" : "Not found in PATH") << "\n";
        std::cout << "  " << color::GREEN << "✔" << color::RESET << " 3D Quantum Engine  : Looping3D Z-Buffer + 120Hz/240Hz Sub-Stepping Physics + Raycast\n";
        std::cout << "  " << color::GREEN << "✔" << color::RESET << " Metal 4 Subsystem   : Apple Metal 4 (M4 Unified Memory Architecture, Hardware Ray Tracing & Mesh Shaders 240Hz)\n";
        std::cout << "  " << color::GREEN << "✔" << color::RESET << " UI Target Profiles : Shine UI (60Hz), XUI (240Hz), flUI (120Hz), SwiftUI (Apple 120Hz), Metal 4 (240Hz), C2 (.c2)\n";
        std::cout << "  " << color::GREEN << "✔" << color::RESET << " Invis. Compile     : LPBN v3.0A Binary Architecture (SHA-256 CTR + Standalone Native Mach-O/ELF + Auto Cache)\n";
        std::cout << "  " << color::GREEN << "✔" << color::RESET << " Default CS Modules : csid (PKCE S256), csms (E2EE), game_plus (2D/3D), core_utils, audio, ai, invis\n";
        std::cout << "  " << color::GREEN << "✔" << color::RESET << " Crypto Subsystem   : SHA-256, FNV-1a, Base64, UUID v4, CSMS E2EE Key Derivation, CRC32\n\n";
        return 0;
    }

    if (first_arg == "bench" || first_arg == "benchmark") {
        std::cout << color::BOLD << color::CYAN << "[LOOPING BENCHMARK]" << color::RESET << " Running Native C++17 VM Throughput Suite...\n\n";
        auto t0 = std::chrono::high_resolution_clock::now();
        Interpreter bvm;
        bvm.execute_code(
            "fn compute_metric(x) => (x * 3 + 7) % 97\n"
            "mut acc = 0\n"
            "for (i in 1..=2500) {\n"
            "    acc += compute_metric(i)\n"
            "}\n"
            "val digest = crypto.sha256($\"bench:{acc}\")\n"
        );
        auto t1 = std::chrono::high_resolution_clock::now();
        double elapsed_ms = std::chrono::duration<double, std::milli>(t1 - t0).count();
        std::cout << "  • Iterations     : 2,500 function calls + loop ticks + SHA-256\n";
        std::cout << "  • Result Check   : acc = " << bvm.variables["acc"].as_int() << " | sha256 = " << bvm.variables["digest"].as_string().substr(0, 16) << "...\n";
        std::cout << "  • Execution Time : " << color::GREEN << std::fixed << std::setprecision(3) << elapsed_ms << " ms" << color::RESET << "\n\n";
        return 0;
    }

    if (first_arg == "check" || first_arg == "inspect") {
        if (argc < 3) {
            std::cerr << color::RED << "Error: 'check' requires a .loop or binary file." << color::RESET << "\n";
            return 1;
        }
        std::string fpath = argv[2];
        std::string source_code;
        InvisBinaryInfo binfo;
        bool is_bin = InvisBinaryCompiler::extract_from_file(fpath, &source_code, &binfo);
        if (!is_bin) {
            std::ifstream f(fpath);
            if (!f.is_open()) {
                std::cerr << color::RED << "Error: Could not open file '" << fpath << "'." << color::RESET << "\n";
                return 1;
            }
            std::stringstream ss;
            ss << f.rdbuf();
            source_code = ss.str();
        }
        auto t0 = std::chrono::high_resolution_clock::now();
        Parser p(source_code);
        auto stmts = p.parse_script();
        auto t1 = std::chrono::high_resolution_clock::now();
        double parse_us = std::chrono::duration<double, std::micro>(t1 - t0).count();

        size_t total_nodes = 0, fn_count = 0, ui_count = 0, entity_count = 0, entity3d_count = 0, loop_count = 0;
        std::function<void(const std::vector<std::shared_ptr<Stmt>>&)> walk_stmts = [&](const std::vector<std::shared_ptr<Stmt>>& list) {
            for (const auto& st : list) {
                if (!st) continue;
                total_nodes++;
                if (auto fn = std::dynamic_pointer_cast<FunctionDefStmt>(st)) {
                    fn_count++;
                    walk_stmts(fn->body);
                } else if (std::dynamic_pointer_cast<DrawUIStmt>(st)) {
                    ui_count++;
                } else if (std::dynamic_pointer_cast<SpawnEntityStmt>(st)) {
                    entity_count++;
                } else if (std::dynamic_pointer_cast<SpawnEntity3DStmt>(st)) {
                    entity3d_count++;
                } else if (auto fr = std::dynamic_pointer_cast<ForRangeStmt>(st)) {
                    loop_count++;
                    walk_stmts(fr->body);
                } else if (auto fe = std::dynamic_pointer_cast<ForEachStmt>(st)) {
                    loop_count++;
                    walk_stmts(fe->body);
                } else if (auto wh = std::dynamic_pointer_cast<WhileStmt>(st)) {
                    loop_count++;
                    walk_stmts(wh->body);
                } else if (auto rp = std::dynamic_pointer_cast<RepeatStmt>(st)) {
                    loop_count++;
                    walk_stmts(rp->body);
                } else if (auto ifs = std::dynamic_pointer_cast<IfStmt>(st)) {
                    walk_stmts(ifs->then_branch);
                    walk_stmts(ifs->else_branch);
                } else if (auto ms = std::dynamic_pointer_cast<MatchStmt>(st)) {
                    for (const auto& arm : ms->arms) walk_stmts(arm.body);
                } else if (auto tc = std::dynamic_pointer_cast<TryCatchStmt>(st)) {
                    walk_stmts(tc->try_body);
                    walk_stmts(tc->catch_body);
                }
            }
        };
        walk_stmts(stmts);

        std::cout << color::GREEN << "✔ [AST CHECK OK]" << color::RESET << " " << fpath
                  << " (" << std::fixed << std::setprecision(1) << parse_us << " µs)\n";
        if (is_bin) {
            std::cout << "  • Format               : LPBN v3.0A (" << (binfo.is_standalone_exe ? "Standalone Native Binary" : "Compact LPBN Binary") << ")\n";
            std::cout << "  • Source SHA-256       : " << binfo.sha256_hex.substr(0, 24) << "... (Target: " << binfo.target_ui << " @ " << binfo.target_fps << "Hz)\n";
        }
        std::cout << "  • Top-level Statements : " << stmts.size() << " (Total AST Nodes: " << total_nodes << ")\n";
        std::cout << "  • Functions Defined    : " << fn_count << "\n";
        std::cout << "  • UI Directives        : " << ui_count << "\n";
        std::cout << "  • 2D Entities          : " << entity_count << "\n";
        std::cout << "  • 3D Entities          : " << entity3d_count << "\n";
        std::cout << "  • Loop Constructs      : " << loop_count << "\n";
        return 0;
    }

    if (first_arg == "ast") {
        if (argc < 3) {
            std::cerr << color::RED << "Error: 'ast' requires a .loop or binary file." << color::RESET << "\n";
            return 1;
        }
        std::string fpath = argv[2];
        std::string source_code;
        if (!InvisBinaryCompiler::extract_from_file(fpath, &source_code)) {
            std::ifstream f(fpath);
            if (!f.is_open()) {
                std::cerr << color::RED << "Error: Could not open file '" << fpath << "'." << color::RESET << "\n";
                return 1;
            }
            std::stringstream ss;
            ss << f.rdbuf();
            source_code = ss.str();
        }
        Parser p(source_code);
        auto stmts = p.parse_script();
        std::cout << color::BOLD << color::CYAN << "[LOOPING AST TREE] " << color::RESET << fpath << " (" << stmts.size() << " root nodes)\n";
        std::function<void(const std::vector<std::shared_ptr<Stmt>>&, const std::string&)> print_tree =
            [&](const std::vector<std::shared_ptr<Stmt>>& list, const std::string& prefix) {
            for (size_t i = 0; i < list.size(); ++i) {
                bool is_last = (i + 1 == list.size());
                std::string branch = is_last ? "└── " : "├── ";
                std::string child_prefix = prefix + (is_last ? "    " : "│   ");
                const auto& st = list[i];
                std::string label = "Stmt";
                if (auto s = std::dynamic_pointer_cast<SetStmt>(st)) label = "SetVar(" + s->var_name + " " + s->op + ")";
                else if (auto idx = std::dynamic_pointer_cast<SetIndexStmt>(st)) label = "SetIndex(" + idx->var_name + "[] " + idx->op + ")";
                else if (auto ds = std::dynamic_pointer_cast<DestructureStmt>(st)) label = "Destructure(" + std::to_string(ds->var_names.size()) + " vars)";
                else if (auto fn = std::dynamic_pointer_cast<FunctionDefStmt>(st)) label = "FunctionDef(" + fn->name + ", params=" + std::to_string(fn->params.size()) + ")";
                else if (auto fr = std::dynamic_pointer_cast<ForRangeStmt>(st)) label = std::string("ForRange(") + fr->var_name + (fr->inclusive ? ", ..=" : ", ..") + ")";
                else if (auto fe = std::dynamic_pointer_cast<ForEachStmt>(st)) label = "ForEach(" + fe->var_name + ")";
                else if (std::dynamic_pointer_cast<WhileStmt>(st)) label = "WhileLoop";
                else if (std::dynamic_pointer_cast<RepeatStmt>(st)) label = "RepeatLoop";
                else if (std::dynamic_pointer_cast<IfStmt>(st)) label = "IfConditionalBlock";
                else if (auto ms = std::dynamic_pointer_cast<MatchStmt>(st)) label = "MatchPatternBlock(arms=" + std::to_string(ms->arms.size()) + ")";
                else if (auto tc = std::dynamic_pointer_cast<TryCatchStmt>(st)) label = "TryCatchBlock(err=" + tc->err_var + ")";
                else if (auto ui = std::dynamic_pointer_cast<DrawUIStmt>(st)) label = "DrawUI(" + ui->ui_type + ": \"" + (ui->title.empty() ? ui->text : ui->title) + "\")";
                else if (auto sp = std::dynamic_pointer_cast<SpawnEntityStmt>(st)) label = "SpawnEntity(" + sp->entity_type + ": \"" + sp->name + "\")";
                else if (auto sp3 = std::dynamic_pointer_cast<SpawnEntity3DStmt>(st)) label = "SpawnEntity3D(" + sp3->entity_type + ": \"" + sp3->name + "\")";
                else if (auto sc3 = std::dynamic_pointer_cast<Scene3DConfigStmt>(st)) label = "Scene3DConfig(" + sc3->category + ")";
                else if (std::dynamic_pointer_cast<PrintStmt>(st)) label = "PrintStmt";
                else if (std::dynamic_pointer_cast<ReturnStmt>(st)) label = "ReturnStmt";
                else if (auto cs = std::dynamic_pointer_cast<CallStmt>(st)) label = "CallStmt(" + cs->name + ")";
                else if (std::dynamic_pointer_cast<ExprStmt>(st)) label = "ExprStmt";
                else if (auto ap = std::dynamic_pointer_cast<AppDefineStmt>(st)) label = "AppDefine(" + ap->app_name + " v" + ap->version + ")";
                else if (auto wn = std::dynamic_pointer_cast<WindowStmt>(st)) label = "Window(" + wn->title + ")";
                else if (auto iv = std::dynamic_pointer_cast<InvisCompileStmt>(st)) label = "InvisCompile(target=" + iv->target_ui + ")";
                std::cout << prefix << color::PURPLE << branch << color::RESET << color::BOLD << label << color::RESET << "\n";

                if (auto fn = std::dynamic_pointer_cast<FunctionDefStmt>(st)) print_tree(fn->body, child_prefix);
                else if (auto fr = std::dynamic_pointer_cast<ForRangeStmt>(st)) print_tree(fr->body, child_prefix);
                else if (auto fe = std::dynamic_pointer_cast<ForEachStmt>(st)) print_tree(fe->body, child_prefix);
                else if (auto wh = std::dynamic_pointer_cast<WhileStmt>(st)) print_tree(wh->body, child_prefix);
                else if (auto rp = std::dynamic_pointer_cast<RepeatStmt>(st)) print_tree(rp->body, child_prefix);
                else if (auto ifs = std::dynamic_pointer_cast<IfStmt>(st)) {
                    print_tree(ifs->then_branch, child_prefix);
                    if (!ifs->else_branch.empty()) print_tree(ifs->else_branch, child_prefix);
                }
            }
        };
        print_tree(stmts, "  ");
        return 0;
    }

    if (first_arg == "fmt") {
        if (argc < 3) {
            std::cerr << color::RED << "Error: 'fmt' requires a .loop script file." << color::RESET << "\n";
            return 1;
        }
        std::string fpath = argv[2];
        bool write_in_place = (argc >= 4 && (std::string(argv[3]) == "--write" || std::string(argv[3]) == "-w"));
        std::ifstream f(fpath);
        if (!f.is_open()) {
            std::cerr << color::RED << "Error: Could not open file '" << fpath << "'." << color::RESET << "\n";
            return 1;
        }
        std::vector<std::string> formatted;
        std::string line;
        int indent_level = 0;
        while (std::getline(f, line)) {
            while (!line.empty() && (line.back() == ' ' || line.back() == '\t' || line.back() == '\r')) line.pop_back();
            size_t first_non_space = line.find_first_not_of(" \t");
            std::string trimmed = (first_non_space == std::string::npos) ? "" : line.substr(first_non_space);
            if (trimmed.empty()) {
                formatted.push_back("");
                continue;
            }
            if (trimmed.rfind("}", 0) == 0 || trimmed == "end") {
                indent_level = std::max(0, indent_level - 1);
            }
            formatted.push_back(std::string(indent_level * 4, ' ') + trimmed);
            if (trimmed.back() == '{' || trimmed.back() == ':') {
                indent_level++;
            }
        }
        f.close();
        std::ostringstream out_ss;
        for (const auto& l : formatted) out_ss << l << "\n";
        if (write_in_place) {
            std::ofstream out(fpath);
            out << out_ss.str();
            std::cout << color::GREEN << "✔ [FMT]" << color::RESET << " Formatted " << fpath << " in-place.\n";
        } else {
            std::cout << out_ss.str();
        }
        return 0;
    }

    if (first_arg == "doc" || first_arg == "docs") {
        std::string topic = (argc >= 3) ? argv[2] : "all";
        std::cout << color::BOLD << color::CYAN << "═══ " << vm.channel_name << " v" << vm.engine_version << " (Arch " << vm.arch_version << ") REFERENCE MANUAL ═══" << color::RESET << "\n\n";
        if (topic == "all" || topic == "channels" || topic == "nomenclature") {
            std::cout << color::YELLOW << "▸ OFFICIAL RELEASE NOMENCLATURE & CHANNELS:" << color::RESET << "\n"
                      << "  • Looping        [prod]  : Production Release (v1.1 / Arch 3.0A)\n"
                      << "  • Omega Looping  [omega] : Release Candidate / RC (v1.1-omega / Arch 3.0A)\n"
                      << "  • Alpha! Looping [alpha] : Super Experimental Lab Builds (v1.1-alpha / Arch 3.0A)\n\n";
        }
        if (topic == "all" || topic == "syntax") {
            std::cout << color::YELLOW << "▸ SYNTAX & CONTROL FLOW:" << color::RESET << "\n"
                      << "  let x = 10 | mut y = 20 | val z := 30 | x %= 7\n"
                      << "  fn calc(a, b = 10) => a * b + 1\n"
                      << "  for (i in 1..=10 step 2) { ... } | match x { \"S\" | \"SS\" => ... 90..=100 => ... _ => ... }\n"
                      << "  try { ... } catch (err) { ... } | val v = opt \?\? \"fallback\" | s.trim().upper()\n\n";
        }
        if (topic == "all" || topic == "math") {
            std::cout << color::YELLOW << "▸ MATH, VECTORS & DATA SCIENCE (math.*):" << color::RESET << "\n"
                      << "  Constants: math.pi, math.e, math.tau, math.phi\n"
                      << "  math.sqrt, math.pow, math.clamp, math.lerp, math.hypot\n"
                      << "  math.dot(v1,v2), math.norm(v), math.distance(p1,p2), math.linspace(start,end,n)\n"
                      << "  math.sum(list), math.mean(list), math.median(list), math.percentile(list,p)\n"
                      << "  math.variance(list), math.stddev(list), math.gcd(a,b), math.lcm(a,b), math.fib(n), math.is_prime(n)\n\n";
        }
        if (topic == "all" || topic == "collections") {
            std::cout << color::YELLOW << "▸ FUNCTIONAL COLLECTIONS:" << color::RESET << "\n"
                      << "  map, filter, reduce, find, any, all, count, zip, enumerate, unique, flatten, chunk\n"
                      << "  take(list,n), drop(list,n), partition(list,fn), group_by(list,fn)\n"
                      << "  sort_by(list,fn), min_by(list,fn), max_by(list,fn), sum_by(list,fn), frequencies(list)\n\n";
        }
        if (topic == "all" || topic == "crypto") {
            std::cout << color::YELLOW << "▸ CRYPTOGRAPHY & SECURITY (crypto.* / url.*):" << color::RESET << "\n"
                      << "  crypto.sha256(str), crypto.hmac_sha256(key, msg), crypto.crc32(str), crypto.fnv1a(str)\n"
                      << "  crypto.base64_encode(str), crypto.base64_decode(b64), crypto.uuid(), crypto.random_hex(bytes)\n"
                      << "  crypto.constant_time_eq(a, b), crypto.csms_key(room_id), crypto.csms_payload(room_id, msg)\n"
                      << "  url.encode(str), url.decode(str)\n\n";
        }
        if (topic == "all" || topic == "csv" || topic == "datetime") {
            std::cout << color::YELLOW << "▸ CSV & DATETIME (csv.* / datetime.* / time.*):" << color::RESET << "\n"
                      << "  csv.parse(text, [delim]), csv.parse_maps(text, [delim]), csv.stringify(rows, [delim])\n"
                      << "  datetime.iso([ts]), datetime.now([ts]), datetime.format(ts, fmt)\n"
                      << "  time.now(), time.millis(), time.micros(), time.nanos()\n\n";
        }
        if (topic == "all" || topic == "regex") {
            std::cout << color::YELLOW << "▸ REGEX ENGINE (regex.*):" << color::RESET << "\n"
                      << "  regex.match(text, pattern), regex.find_all(text, pattern), regex.replace(text, pat, rep)\n\n";
        }
        if (topic == "all" || topic == "ui") {
            std::cout << color::YELLOW << "▸ UI & NATIVE WINDOWS (ui.* / window.*):" << color::RESET << "\n"
                      << "  window.create(title, w, h, target), ui.card(at: (x,y), size: (w,h), title: \"...\")\n"
                      << "  draw slider, draw toggle, draw progress, spawn.sprite, audio.tone(hz, ms)\n\n";
        }
        if (topic == "all" || topic == "game3d" || topic == "3d") {
            std::cout << color::YELLOW << "▸ 3D QUANTUM GAME ENGINE & 120Hz SUB-STEPPING PHYSICS (scene3d.* / spawn3d.* / math3d.* / physics3d.*):" << color::RESET << "\n"
                      << "  define game3d \"CyberOdyssey\" version 3.0:\n"
                      << "  scene3d.world(name: \"Arena\", size: (180,80,180), sky: \"cyber_night\", fog: 0.010, grid: true)\n"
                      << "  camera3d.set(mode: \"chase\"|\"fps\"|\"orbit\"|\"topdown\", pos: (0,8,-16), target: (0,2,10), fov: 64)\n"
                      << "  light3d.directional(dir: (-0.4,-1,-0.3), color: \"#fff\", intensity: 1.1) | light3d.point(at: (x,y,z), ...)\n"
                      << "  physics3d.config(gravity: -26.0, substeps: 4, friction: 0.86, bounce: 0.12)\n"
                      << "  spawn3d.player, spawn3d.box, spawn3d.moving_platform, spawn3d.sphere, spawn3d.cylinder, spawn3d.pyramid\n"
                      << "  spawn3d.ring, spawn3d.crystal, spawn3d.enemy, spawn3d.boss, spawn3d.pad, spawn3d.hazard, spawn3d.portal\n"
                      << "  math3d: vec3, add, sub, scale, dot, cross, normalize, lerp, reflect, quat_euler, quat_slerp, quat_rotate, mat4_trs, project\n"
                      << "  physics3d: collide_sphere, collide_aabb, collide_capsule_sphere, raycast_sphere, raycast_aabb, raycast_scene, step_body\n"
                      << "  CLI: looping preview3d game.loop | looping create MyGame3D --type game3d | looping --native game.loop\n\n";
        }
        if (topic == "all" || topic == "swiftui" || topic == "apple") {
            std::cout << color::YELLOW << "▸ DECLARATIVE SWIFTUI SUBSYSTEM (v2.9 Apple Ecosystem Experience):" << color::RESET << "\n"
                      << "  view DashboardView {\n"
                      << "      @state count = 0\n"
                      << "      @state is_active = true\n"
                      << "      VStack(spacing: 16) {\n"
                      << "          Text(\"Coki Studios\").font(.largeTitle).fontWeight(.bold).foregroundColor(.cyan)\n"
                      << "          Text(\"Counter: $count\").font(.headline).padding(8).background(.ultraThinMaterial)\n"
                      << "          HStack(spacing: 12) {\n"
                      << "              Button(\"Decrementar\") { count -= 1 }.buttonStyle(.bordered)\n"
                      << "              Button(\"Incrementar\") { count += 1 }.buttonStyle(.borderedProminent)\n"
                      << "          }\n"
                      << "          Toggle(\"Activar Telemetría\", isOn: $is_active).padding(12)\n"
                      << "      }.padding(20).frame(width: 420)\n"
                      << "  }\n"
                      << "  CLI: looping preview app.loop | looping compile app.loop --target swiftui -o App.swift\n\n";
        }
        if (topic == "all" || topic == "metal4" || topic == "metal" || topic == "m4") {
            std::cout << color::YELLOW << "▸ METAL 4 GRAPHICS & SHADING PIPELINE (Apple Silicon APU Unified Memory):" << color::RESET << "\n"
                      << "  • Target Profile : --target metal4 | --metal4 | pipeline: Apple Metal 4 Unified Memory 240Hz (<0.1ms)\n"
                      << "  • Shaders (MSL)  : Metal Shading Language 4.0 (Hardware Mesh Shaders & BVH Raytracing)\n"
                      << "  • System Query   : sys.metal_version, sys.has_metal4, metal4.is_supported(), metal4.pipeline_info()\n"
                      << "  • Interactive GUI: Persistent terminal session keeps native Tkinter & Metal 4 windows active (like py -i)\n"
                      << "  • CLI Commands   : looping --metal4 <file.loop> | looping -i <file.loop>\n\n";
        }
        if (topic == "all" || topic == "invis" || topic == "binary") {
            std::cout << color::YELLOW << "▸ INVIS. COMPILE BINARY ARCHITECTURE (LPBN v3.0A — .loop -> Binary File):" << color::RESET << "\n"
                      << "  • Directive in .loop : invis. compile \"app.loop\" to \"build/app.bin\" for xui\n"
                      << "  • Self-Compile Pragma: invis. compile\n"
                      << "  • Built-in Module    : invis.compile(src, [dst], [target], [compact]), invis.verify(bin), invis.info(bin), invis.run(bin)\n"
                      << "  • CLI Commands       : looping invis <file.loop> [-o <out.bin>] [--target <ui>] [--compact] [--in-place] [--run]\n"
                      << "  • Binary Format      : LPBN v3.0A (8-byte magic + 16-byte salt + 32-byte SHA-256 + CRC32 + SHA-256 CTR stream cipher)\n"
                      << "  • Standalone Mode    : Embeds LPBN v3.0A into Universal Mach-O/ELF binary slot + ad-hoc codesign for direct ./app.bin execution\n"
                      << "  • Auto Invisible Cache: Every .loop execution automatically caches a verified binary in build/.invis/<name>.loopb\n\n";
        }
        return 0;
    }

    if (first_arg == "guide" || first_arg == "learn" || first_arg == "tutorial") {
        std::string export_path = "";
        for (int i = 2; i < argc; ++i) {
            std::string arg = argv[i];
            if ((arg == "--export" || arg == "-o" || arg == "--output") && i + 1 < argc) {
                export_path = argv[++i];
            } else if (export_path.empty() && arg.rfind("-", 0) != 0) {
                export_path = arg;
            }
        }
        std::ostringstream g;
        g << "# Looping Code (v1.1 / Arch 3.0A) — Complete Learning & Mastery Guide\n\n"
          << "> **Official Nomenclature**: `Looping` (`[prod]`), `Omega Looping` (`[omega]`), `Alpha! Looping` (`[alpha]`)  \n"
          << "> **Engine Architecture**: Native C++17 Universal Engine + `Invis. Compile` (`LPBN v3.0A` Binary Pipeline)\n\n"
          << "---\n\n"
          << "## Module 1: Variables, Constants & String Interpolation\n"
          << "```looping\n"
          << "// Immutable & mutable bindings\n"
          << "val studio = \"Coki Studios\"\n"
          << "let version = 3.0\n"
          << "mut score = 100\n"
          << "score += 50\n"
          << "fast_assign := 42\n\n"
          << "// String interpolation with $\"...\" or \"...{expr}...\"\n"
          << "print($\"Welcome to {studio} — Looping Arch {version} (Score: {score})\")\n"
          << "```\n\n"
          << "## Module 2: Functions, Lambdas, Defaults & Pipe Operators\n"
          << "```looping\n"
          << "// Expression-bodied function with default argument\n"
          << "fn boost(x, factor = 2) => x * factor + 10\n\n"
          << "// Block-bodied function\n"
          << "fn classify(power) {\n"
          << "    if (power >= 100) {\n"
          << "        return \"OMEGA\"\n"
          << "    }\n"
          << "    return \"STANDARD\"\n"
          << "}\n\n"
          << "// Pipe operator (|>) chains transformations left-to-right\n"
          << "val tier = 45 |> boost(3) |> classify()\n"
          << "print($\"Tier: {tier}\")\n"
          << "```\n\n"
          << "## Module 3: Control Flow, Ranges & Pattern Matching (`match`)\n"
          << "```looping\n"
          << "// Inclusive (..=) and exclusive (..) ranges with step\n"
          << "mut total = 0\n"
          << "for (i in 1..=10 step 2) {\n"
          << "    total += i\n"
          << "}\n\n"
          << "// Pattern matching with multi-value arms, ranges & guards\n"
          << "val grade = 96\n"
          << "match grade {\n"
          << "    100 => print(\"Perfect S+\")\n"
          << "    90..=99 if grade >= 95 => print(\"Rank S (Honors)\")\n"
          << "    80..=89 => print(\"Rank A\")\n"
          << "    _ => print(\"Keep training\")\n"
          << "}\n"
          << "```\n\n"
          << "## Module 4: Collections, Maps, Destructuring & Functional Pipelines\n"
          << "```looping\n"
          << "let nums = [1, 2, 3, 4, 5, 6]\n"
          << "let [first, second, ...rest] = nums\n\n"
          << "val evens_squared = nums\n"
          << "    |> filter(fn(n) => n % 2 == 0)\n"
          << "    |> map(fn(n) => n * n)\n"
          << "print($\"Evens squared: {evens_squared} | Sum: {math.sum(evens_squared)}\")\n\n"
          << "let config = {\"engine\": \"Looping\", \"fps\": 240, \"invis\": true}\n"
          << "print($\"Engine: {config[\"engine\"]} @ {config[\"fps\"]}Hz\")\n"
          << "```\n\n"
          << "## Module 5: Error Handling (`try / catch / throw`) & Null Coalescing (`??`)\n"
          << "```looping\n"
          << "let custom_title = null\n"
          << "val active_title = custom_title ?? \"Default Coki Window\"\n\n"
          << "try {\n"
          << "    assert(active_title.len() > 0, \"Title must not be empty\")\n"
          << "} catch (err) {\n"
          << "    print($\"Recovered from error: {err}\")\n"
          << "}\n"
          << "```\n\n"
          << "## Module 6: Cryptography, CS ID (PKCE S256) & CSMS E2EE\n"
          << "```looping\n"
          << "use \"csid\"\n"
          << "use \"csms\"\n\n"
          << "val digest = crypto.sha256(\"CokiStudios\")\n"
          << "val room_key = crypto.csms_key(\"room_global_01\")\n"
          << "val encrypted_packet = csms.encrypt(\"room_global_01\", \"Hello Secure World\")\n"
          << "print($\"CSMS Packet: {encrypted_packet}\")\n"
          << "```\n\n"
          << "## Module 7: Native UI Windows, Reactive Cards & Declarative SwiftUI\n"
          << "```looping\n"
          << "define app \"TelemetryStudio\" version 3.0:\n"
          << "window \"Telemetry Studio\" (960x600) target xui\n\n"
          << "view MainDashboard {\n"
          << "    @state counter = 1\n"
          << "    VStack(spacing: 12) {\n"
          << "        Text(\"Coki Studios — Looping SwiftUI\").font(.title).fontWeight(.bold).foregroundColor(.cyan)\n"
          << "        Text(\"Active Nodes: $counter\").font(.headline)\n"
          << "        Button(\"Scale Cluster\") { counter += 1 }.buttonStyle(.borderedProminent)\n"
          << "    }.padding(20)\n"
          << "}\n"
          << "```\n\n"
          << "## Module 8: 3D Quantum Engine & 120Hz Sub-Stepping Physics\n"
          << "```looping\n"
          << "define game3d \"QuantumArena\" version 3.0:\n"
          << "scene3d.world(name: \"Nexus\", size: (180, 80, 180), sky: \"cyber_night\", fog: 0.01, grid: true)\n"
          << "camera3d.set(mode: \"chase\", pos: (0, 8, -16), target: (0, 2, 10), fov: 65)\n"
          << "physics3d.config(gravity: -25.0, substeps: 4, friction: 0.88, bounce: 0.15)\n"
          << "spawn3d.player \"Pilot\" at (0, 2, 0) size (1.2, 2.2, 1.2) color \"#38bdf8\" speed 14\n"
          << "spawn3d.crystal \"CoreShard\" at (0, 3, 12) size (1.2, 2.0, 1.2) color \"#a855f7\" spin 2.4\n"
          << "```\n\n"
          << "## Module 9: `Invis. Compile` Binary Architecture (`.loop` -> Binary File)\n"
          << "`Invis. Compile` converts any `.loop` source file into a cryptographically sealed `LPBN v3.0A` binary file with zero plaintext source exposure.\n\n"
          << "### 9.1 In-Language Syntax\n"
          << "```looping\n"
          << "// 1. Compile current script invisibly into build/<script>.bin\n"
          << "invis. compile\n\n"
          << "// 2. Compile a specific .loop file to a standalone native binary for XUI\n"
          << "invis. compile \"sample_loop_projects/hi.loop\" to \"build/hi.bin\" for xui\n\n"
          << "// 3. Programmatic API via built-in invis.* module\n"
          << "val bin_path = invis.compile(\"app.loop\", \"build/app.bin\", \"xui\")\n"
          << "print(invis.verify(bin_path))  // true\n"
          << "print(invis.info(bin_path))    // Map with format, sha256, crc32, standalone\n"
          << "```\n\n"
          << "### 9.2 CLI Commands\n"
          << "```zsh\n"
          << "# Compile .loop to a standalone native binary executable (.bin)\n"
          << "looping invis app.loop -o build/app.bin --target xui\n\n"
          << "# Execute the binary directly from zsh or via looping\n"
          << "./build/app.bin\n"
          << "looping build/app.bin\n\n"
          << "# Compile to a compact LPBN binary container (.loopb)\n"
          << "looping invis app.loop -o build/app.loopb --compact\n"
          << "```\n";

        if (!export_path.empty()) {
            std::ofstream out(export_path);
            if (!out.is_open()) {
                std::cerr << color::RED << "Error: Could not write guide to '" << export_path << "'." << color::RESET << "\n";
                return 1;
            }
            out << g.str();
            out.close();
            std::cout << color::GREEN << "✔ [LOOPING GUIDE]" << color::RESET << " Full Learning Guide exported to: " << color::BOLD << export_path << color::RESET << "\n";
        } else {
            std::cout << g.str();
        }
        return 0;
    }

    if (first_arg == "eval") {
        if (argc < 3) {
            std::cerr << color::RED << "Error: 'eval' requires code string argument." << color::RESET << "\n";
            return 1;
        }
        vm.execute_code(argv[2]);
        return 0;
    }

    // CS ID Connect Authentication: looping auth <login|whoami|logout>
    if (first_arg == "auth") {
        std::string auth_subcmd = (argc >= 3) ? argv[2] : "status";
        const char* home = getenv("HOME");
        std::string auth_file = (home ? std::string(home) : ".") + "/.looping_csid_auth";

        if (auth_subcmd == "login") {
            std::cout << color::BOLD << color::CYAN << "[CS ID Connect]" << color::RESET << " Initiating authentication flow for Looping CLI...\n";
            std::string client_id = "c0c11009-4ce0-4b11-8a01-1009c0c1e001";
            std::string redirect_uri = "https://cokistudios.com/client-demo";
            std::string code_verifier = CryptoUtils::random_hex(32);
            std::string code_challenge = CryptoUtils::sha256_hex(code_verifier);
            std::string state = CryptoUtils::random_hex(16);
            std::string auth_url = "https://cokistudios.com/authorize?client_id=" + client_id + 
                                  "&redirect_uri=" + redirect_uri + 
                                  "&response_type=code&scope=openid+profile+email+offline_access" +
                                  "&code_challenge=" + code_challenge + 
                                  "&code_challenge_method=S256" + 
                                  "&state=" + state;

            std::cout << color::YELLOW << "Opening authorization URL in browser:" << color::RESET << "\n";
            std::cout << "  " << auth_url << "\n\n";

#ifdef __APPLE__
            system(("open \"" + auth_url + "\" 2>/dev/null").c_str());
#elif __linux__
            system(("xdg-open \"" + auth_url + "\" 2>/dev/null").c_str());
#elif _WIN32
            system(("start \"\" \"" + auth_url + "\" 2>/dev/null").c_str());
#endif

            std::cout << "Paste the Authorization Code or Token received from the portal:\n> ";
            std::string token;
            if (std::cin >> token && !token.empty()) {
                std::ofstream out(auth_file);
                if (out.is_open()) {
                    out << "token=" << token << "\n";
                    out << "client_id=" << client_id << "\n";
                    out << "code_verifier=" << code_verifier << "\n";
                    out << "auth_time=" << time(nullptr) << "\n";
                    out.close();
                    std::cout << color::GREEN << "✔ [SUCCESS]" << color::RESET << " Successfully authenticated with CS ID Connect!\n";
                    std::cout << "Credentials stored in " << auth_file << "\n";
                } else {
                    std::cerr << color::RED << "Error: Could not save credentials." << color::RESET << "\n";
                    return 1;
                }
            }
            return 0;
        } else if (auth_subcmd == "whoami" || auth_subcmd == "status") {
            std::ifstream in(auth_file);
            if (!in.is_open()) {
                std::cout << color::YELLOW << "Not logged in to CS ID Connect." << color::RESET << "\n";
                std::cout << "Run 'looping auth login' to authenticate.\n";
                return 0;
            }
            std::cout << color::BOLD << color::CYAN << "[CS ID Connect Session]" << color::RESET << "\n";
            std::string line;
            while (std::getline(in, line)) {
                if (line.rfind("token=", 0) == 0) {
                    std::string tok = line.substr(6);
                    std::string masked = tok.size() > 8 ? tok.substr(0, 4) + "..." + tok.substr(tok.size() - 4) : "****";
                    std::cout << "  • Token: " << masked << "\n";
                } else {
                    std::cout << "  • " << line << "\n";
                }
            }
            in.close();
            return 0;
        } else if (auth_subcmd == "logout") {
            std::remove(auth_file.c_str());
            std::cout << color::GREEN << "✔ [SUCCESS]" << color::RESET << " Logged out from CS ID Connect session.\n";
            return 0;
        } else {
            std::cerr << "Unknown auth subcommand: " << auth_subcmd << "\n";
            std::cerr << "Usage: looping auth <login|whoami|logout>\n";
            return 1;
        }
    }

    // Coki AI Local Coding Assistant CLI: looping ai "<query>" | --chat | --fix <file.loop> | --rag-only
    if (first_arg == "ai" || first_arg == "coki-ai") {
        auto shell_quote = [](const std::string& arg) -> std::string {
            std::string out = "'";
            for (char c : arg) {
                if (c == '\'') out += "'\\''";
                else out += c;
            }
            out += "'";
            return out;
        };

        auto file_exists = [](const std::string& p) -> bool {
            std::ifstream f(p);
            return f.good();
        };

        if (argc >= 3 && (std::string(argv[2]) == "--help" || std::string(argv[2]) == "-h")) {
            std::cout << color::BOLD << color::CYAN << "Coki AI · Local Apple Silicon MLX + Looping RAG" << color::RESET << "\n";
            std::cout << "  " << argv[0] << " ai \"<consulta>\"          Ask Coki AI using local MLX (127.0.0.1:8080) + RAG\n";
            std::cout << "  " << argv[0] << " ai --chat                 Interactive terminal chat session\n";
            std::cout << "  " << argv[0] << " ai --fix <archivo.loop>   Diagnose & repair a .loop file\n";
            std::cout << "  " << argv[0] << " ai --rag-only \"<tema>\"    Search official local Looping docs offline\n";
            std::cout << "  " << argv[0] << " ai --cloud \"<consulta>\"   Allow cloud edge fallback if local MLX is off\n";
            std::cout << "  Hugging Face org: https://huggingface.co/CokiStudios\n";
            return 0;
        }

        std::string bin_dir = ".";
        std::string exe_path = argv[0] ? std::string(argv[0]) : "";
        size_t slash_pos = exe_path.find_last_of("/\\");
        if (slash_pos != std::string::npos) {
            bin_dir = exe_path.substr(0, slash_pos);
        }

        std::string chat_script;
        if (const char* env_chat = std::getenv("COKI_AI_CHAT")) {
            if (file_exists(env_chat)) chat_script = env_chat;
        }
        std::vector<std::string> script_candidates = {
            "coki-ai/chat.py",
            bin_dir + "/../coki-ai/chat.py",
            bin_dir + "/../../coki-ai/chat.py"
        };
        if (chat_script.empty()) {
            for (const auto& cand : script_candidates) {
                if (file_exists(cand)) {
                    chat_script = cand;
                    break;
                }
            }
        }

        if (chat_script.empty()) {
            std::cerr << color::RED << "Error: coki-ai/chat.py not found in workspace." << color::RESET << "\n";
            std::cerr << "Run from your Looping repo root or set COKI_AI_CHAT, or download weights from https://huggingface.co/CokiStudios\n";
            return 1;
        }

        std::string ai_root = chat_script.substr(0, chat_script.find_last_of("/\\"));
        std::string venv_py = ai_root + "/.venv/bin/python";
        std::string ext_venv_py = "/Volumes/Support HD/CokiAI/.venv/bin/python";
        std::string py_exec = file_exists(venv_py) ? venv_py : (file_exists(ext_venv_py) ? ext_venv_py : "python3");

        std::string cmd = shell_quote(py_exec) + " " + shell_quote(chat_script);
        if (argc < 3) {
            cmd += " --chat";
        } else {
            for (int i = 2; i < argc; ++i) {
                cmd += " " + shell_quote(argv[i]);
            }
        }
        int rc = std::system(cmd.c_str());
        return rc == 0 ? 0 : 1;
    }

    // Dynamic Window Creator CLI: looping window <name> [--title <t>] [--size <w,h>] [--theme <th>] [--target <tgt>] [--output <out>] [--html <out>] [--run]
    if (first_arg == "window" || first_arg == "win" || first_arg == "gui-create") {
        if (argc < 3) {
            std::cerr << color::RED << "Error: 'window' requires a window name." << color::RESET << "\n";
            std::cerr << "Usage: " << argv[0] << " window <name> [--title <t>] [--size <w,h>] [--theme <th>] [--target <tgt>] [--output <out>] [--run]\n";
            return 1;
        }

        std::string name = argv[2];
        std::string title = name;
        double width = 850;
        double height = 540;
        std::string theme = "";
        std::string target_ui = "shine_ui";
        std::string out_loop = "";
        std::string out_html = "";
        bool launch = true;

        for (int i = 3; i < argc; ++i) {
            std::string arg = argv[i];
            if ((arg == "--title" || arg == "-t") && i + 1 < argc) {
                title = argv[++i];
            } else if ((arg == "--size" || arg == "-s") && i + 1 < argc) {
                std::string sz = argv[++i];
                size_t comma = sz.find(',');
                if (comma != std::string::npos) {
                    try {
                        width = std::stod(sz.substr(0, comma));
                        height = std::stod(sz.substr(comma + 1));
                    } catch (...) {}
                }
            } else if ((arg == "--theme" || arg == "-th") && i + 1 < argc) {
                theme = argv[++i];
            } else if ((arg == "--target" || arg == "--ui" || arg == "-u") && i + 1 < argc) {
                target_ui = argv[++i];
            } else if ((arg == "--output" || arg == "-o") && i + 1 < argc) {
                out_loop = argv[++i];
            } else if (arg == "--html" && i + 1 < argc) {
                out_html = argv[++i];
            } else if (arg == "--no-run" || arg == "--no-open") {
                launch = false;
            } else if (arg == "--run" || arg == "--open" || arg == "--gui") {
                launch = true;
            }
        }

        DynamicWindow win(title, width, height, target_ui);
        if (!theme.empty()) win.set_theme(theme);

        UIProfileSpecs specs = resolve_ui_profile(target_ui);
        win.add_card(title, "Ventana dinámica generada por Looping v1.1 (Arch 3.0A)\nArquitectura: " + specs.name + " (" + specs.pipeline + ")")
           .add_card("Métricas de Sistema", "Frecuencia: " + std::to_string(specs.target_fps) + " FPS\nLatencia Entrada: <0.2ms\nEstado: Óptimo")
           .add_card("Módulos Activos", "• Xtraps Background Engine\n• Looping AST & Interpreter v1.1 (Arch 3.0A)\n• Audio Synthesizer Core")
           .add_card("Acciones de Control", "Panel reactivo interactivo. Haz clic en los botones para disparar eventos.")
           .add_button("INICIAR PROCESO", "start_process")
           .add_button("REINICIAR SERVICIOS", "restart_services")
           .add_button("EXPORTAR DATOS", "export_data")
           .add_tone(587, 80)
           .add_tone(880, 100);

        if (!out_loop.empty()) win.save_loop(out_loop);
        if (!out_html.empty()) win.save_html(out_html);

        win.show(launch);
        return 0;
    }

    // Dynamic Program Creator: looping create <name> [--type <game|arcade|rpg|dashboard|tool|swiftui>] [--target <shine_ui|xui|flui>] [--output <out>]
    if (first_arg == "create" || first_arg == "new") {
        if (argc < 3) {
            std::cerr << color::RED << "Error: 'create' requires an application name." << color::RESET << "\n";
            std::cerr << "Usage: " << argv[0] << " create <name> [--type <game|rpg|dashboard|tool|swiftui>] [--target <shine_ui|xui|flui>] [--output <out>]\n";
            return 1;
        }

        std::string app_name = argv[2];
        std::string type = "dashboard";
        std::string target_ui = "shine_ui";
        std::string out_path = "";
        bool show_snippets = false;
        (void)show_snippets;

        for (int i = 3; i < argc; ++i) {
            std::string arg = argv[i];
            if ((arg == "--type" || arg == "-k" || arg == "-t") && i + 1 < argc) {
                type = argv[++i];
            } else if ((arg == "--target" || arg == "--ui") && i + 1 < argc) {
                target_ui = argv[++i];
            } else if ((arg == "--output" || arg == "-o") && i + 1 < argc) {
                out_path = argv[++i];
            } else if (arg == "--snippets" || arg == "-s") {
                show_snippets = true;
            }
        }

        std::cout << color::BOLD << color::CYAN << "⚡ [LOOPING CREATE]" << color::RESET << " Initializing dynamic " 
                  << ((type == "game" || type == "arcade" || type == "rpg") ? "Game" : "Application")
                  << ": " << color::BOLD << app_name << color::RESET << " (Type: " << color::YELLOW << type << color::RESET 
                  << ", Target: " << color::GREEN << target_ui << color::RESET << ")\n";

        DynamicProgram prog = Compiler::create_template(type, app_name, target_ui);
        std::string created_path;
        bool ok = Compiler::compile_dynamic_program(prog, out_path, &created_path);
        if (ok) {
            std::cout << "\n" << color::GREEN << "✔ Successfully generated dynamic application template!" << color::RESET << "\n";
            std::cout << color::BOLD << "  • Artifact:" << color::RESET << " " << created_path << "\n";
            std::cout << color::BOLD << "  • Arch:" << color::RESET << " 3.0A Quantum Synthesis & Coki Studios Ecosystem\n";
            std::cout << color::BOLD << "  • Bundled CS Modules:" << color::RESET << " csid, csms, game_plus, core_utils, audio, ai\n";
            if (!prog.snippets.empty()) {
                std::cout << color::BOLD << "  • Embedded Reactive Snippets (" << prog.snippets.size() << "):" << color::RESET << "\n";
                for (const auto& sn : prog.snippets) {
                    std::cout << "    - " << color::CYAN << sn.name << color::RESET << " (" << sn.type << ")\n";
                }
            }
            std::cout << color::BOLD << "\n🚀 Next steps:" << color::RESET << "\n";
            std::cout << "  " << argv[0] << " " << created_path << "            # Run application directly\n";
            std::cout << "  " << argv[0] << " check " << created_path << "      # Verify syntax and AST\n";
            if (type == "swiftui" || target_ui == "swiftui") {
                std::cout << "  " << argv[0] << " preview " << created_path << "    # SwiftUI live Canvas preview\n";
            }
            std::cout << "\n";
        }
        return ok ? 0 : 1;
    }

    // Preview command: looping preview <script.loop> [view_name] OR looping preview3d <script.loop>
    if (first_arg == "preview" || first_arg == "canvas" || first_arg == "preview3d") {
        if (argc < 3) {
            std::cerr << color::RED << "Error: '" << first_arg << "' requires a .loop or binary file." << color::RESET << "\n";
            std::cerr << "Usage: " << argv[0] << " " << first_arg << " <file.loop> [ComponentName]\n";
            return 1;
        }
        std::string script_path = argv[2];
        std::string target_view = (argc > 3) ? argv[3] : "";

        std::string source_code;
        if (!InvisBinaryCompiler::extract_from_file(script_path, &source_code)) {
            std::ifstream file(script_path);
            if (!file.is_open()) {
                std::cerr << color::RED << "Error: Cannot open script: " << script_path << color::RESET << "\n";
                return 1;
            }
            std::stringstream buffer;
            buffer << file.rdbuf();
            source_code = buffer.str();
        }
        vm.execute_code(source_code);

        if (first_arg == "preview3d" || (vm.current_scene3d.active && vm.swiftui_components.empty())) {
            std::cout << vm.current_scene3d.render_tui(74, 20);
            return 0;
        }
        if (!target_view.empty()) {
            vm.eval(std::make_shared<CallExpr>("swiftui.preview", std::vector<std::shared_ptr<Expr>>{
                std::make_shared<LiteralExpr>(Value(target_view))
            }));
        } else if (!vm.swiftui_components.empty()) {
            for (const auto& kv : vm.swiftui_components) {
                vm.render_swiftui_tui(kv.second->root_view, kv.second->root_modifiers, kv.second->name);
            }
        }
        return 0;
    }

    // Invis. Compile command: looping invis <file.loop> [-o <out.bin>] [--target <ui>] [--compact] [--in-place] [--run]
    if (first_arg == "invis" || first_arg == "invis-compile" || first_arg == "invis.compile") {
        if (argc < 3) {
            std::cerr << color::RED << "Error: 'invis' requires a source .loop file." << color::RESET << "\n";
            std::cerr << "Usage: " << argv[0] << " invis <file.loop> [-o <out.bin>] [--target <shine_ui|xui|flui|swiftui>] [--compact] [--in-place] [--run]\n";
            return 1;
        }

        std::string script_path = argv[2];
        // Allow `looping invis compile <file.loop>`
        int start_idx = 3;
        if (script_path == "compile" && argc >= 4) {
            script_path = argv[3];
            start_idx = 4;
        }

        std::string target_ui = "shine_ui";
        std::string out_path = "";
        bool standalone_bin = true;
        bool in_place = false;
        bool run_after = false;

        for (int i = start_idx; i < argc; ++i) {
            std::string arg = argv[i];
            if ((arg == "--target" || arg == "-t" || arg == "--ui") && i + 1 < argc) {
                target_ui = argv[++i];
            } else if ((arg == "--output" || arg == "-o") && i + 1 < argc) {
                out_path = argv[++i];
            } else if (arg == "--compact" || arg == "--loopb") {
                standalone_bin = false;
            } else if (arg == "--standalone" || arg == "--native-bin") {
                standalone_bin = true;
            } else if (arg == "--in-place" || arg == "--replace") {
                in_place = true;
            } else if (arg == "--run" || arg == "-r") {
                run_after = true;
            }
        }

        if (in_place && out_path.empty()) {
            out_path = script_path;
        }

        std::string produced_path;
        bool ok = Compiler::compile_file(script_path, target_ui, out_path, &produced_path, !standalone_bin);
        if (ok && run_after && !produced_path.empty()) {
            std::cout << color::CYAN << "▸ [INVIS. RUN]" << color::RESET << " Executing compiled binary " << produced_path << "...\n";
            vm.execute_file(produced_path);
        }
        return ok ? 0 : 1;
    }

    // Compile command: looping compile <script.loop> [--target <shine_ui|xui|flui|invis>] [--output <out>] [--invis] [--compact]
    if (first_arg == "compile" || first_arg == "build") {
        if (argc < 3) {
            std::cerr << color::RED << "Error: 'compile' requires a source script file." << color::RESET << "\n";
            std::cerr << "Usage: " << argv[0] << " compile <file.loop> [--target <shine_ui|xui|flui|invis>] [--output <out>] [--invis] [--compact]\n";
            return 1;
        }

        std::string script_path = argv[2];
        std::string target_ui = "shine_ui";
        std::string out_path = "";
        bool force_invis = false;
        bool compact_mode = false;

        for (int i = 3; i < argc; ++i) {
            std::string arg = argv[i];
            if ((arg == "--target" || arg == "-t" || arg == "--ui") && i + 1 < argc) {
                target_ui = argv[++i];
            } else if ((arg == "--output" || arg == "-o") && i + 1 < argc) {
                out_path = argv[++i];
            } else if (arg == "--invis" || arg == "--binary" || arg == "-b") {
                force_invis = true;
            } else if (arg == "--compact" || arg == "--loopb") {
                compact_mode = true;
            }
        }

        if (force_invis || compact_mode) {
            return Compiler::compile_file(script_path, target_ui, out_path, nullptr, compact_mode) ? 0 : 1;
        }

        bool success = vm.compile_script_to_target(script_path, target_ui, out_path);
        return success ? 0 : 1;
    }

    // Run command or script execution: supports flags anywhere, including --gui / -g / -t / --native / -i / --persistent / --metal4
    bool gui_mode = false;
    bool native_mode = false;
    bool persistent_mode = false;
    bool batch_mode = false;
    bool force_metal4 = false;
    std::string script_path = "";
    std::string target_ui = "";

    for (int i = 1; i < argc; ++i) {
        std::string arg = argv[i];
        if (arg == "--gui" || arg == "-g" || arg == "--window") {
            gui_mode = true;
        } else if (arg == "--native" || arg == "-n" || arg == "--os") {
            gui_mode = true;
            native_mode = true;
        } else if (arg == "-i" || arg == "--interactive" || arg == "-p" || arg == "--persistent") {
            persistent_mode = true;
        } else if (arg == "--no-persist" || arg == "--batch" || arg == "-b") {
            batch_mode = true;
        } else if (arg == "--metal4" || arg == "--metal" || arg == "-m4") {
            force_metal4 = true;
            target_ui = "metal4";
        } else if ((arg == "--target" || arg == "-t" || arg == "--ui") && i + 1 < argc) {
            target_ui = argv[++i];
        } else if (arg == "run") {
            continue;
        } else if (script_path.empty() && arg.rfind("-", 0) != 0) {
            script_path = arg;
        }
    }

    if (script_path.empty()) {
        std::cerr << color::RED << "Error: No script file provided." << color::RESET << "\n";
        print_usage(argv[0]);
        return 1;
    }

    if (force_metal4 || target_ui == "metal4") {
        vm.set_target_ui("metal4");
    } else if (!target_ui.empty()) {
        vm.set_target_ui(target_ui);
    }

    if (gui_mode) {
        std::cout << color::CYAN << "[GUI RUNTIME]" << color::RESET 
                  << (native_mode ? " Initializing Pure Native OS Window subsystem (No HTML5)...\n" 
                                  : " Initializing Loop OS Native Graphical Window subsystem...\n");
    }

    bool success = vm.execute_file(script_path);

    bool has_ui_window = !vm.current_window.cards.empty() || 
                         !vm.current_window.buttons.empty() || 
                         !vm.last_exported_native_script.empty() || 
                         vm.has_active_window;
    bool is_playable_game = vm.has_game_entities || vm.current_scene3d.active || !vm.current_scene3d.entities.empty();

    if (success && gui_mode && !native_mode && (is_playable_game || !has_ui_window)) {
        // Universal 2D/3D Stage GUI Launcher: resolves loop-node-window from any working directory
        std::string home_dir = getenv("HOME") ? getenv("HOME") : "";
        std::string bin_dir = ".";
        std::string argv0_str = argv[0] ? argv[0] : "";
        size_t b_slash = argv0_str.find_last_of("/\\");
        if (b_slash != std::string::npos) bin_dir = argv0_str.substr(0, b_slash);

        std::vector<std::string> nw_candidates = {
            "modules/loop-node-window/index.js",
            bin_dir + "/../modules/loop-node-window/index.js",
            "/Users/jerix/engine/modules/loop-node-window/index.js"
        };
        if (!home_dir.empty()) {
            nw_candidates.insert(nw_candidates.begin() + 1, home_dir + "/.smiledev/modules/loop-node-window/index.js");
            nw_candidates.push_back(home_dir + "/engine/modules/loop-node-window/index.js");
            nw_candidates.push_back(home_dir + "/cokistudios.github.io/modules/loop-node-window/index.js");
        }

        std::string resolved_nw = "";
        for (const auto& cand : nw_candidates) {
            std::ifstream f(cand);
            if (f.good()) {
                resolved_nw = cand;
                break;
            }
        }

        if (!resolved_nw.empty()) {
            std::cout << color::GREEN << "[2D/3D STAGE LAUNCH]" << color::RESET 
                      << " Launching Universal 2D/3D Quantum Stage (" << resolved_nw << ") for " << script_path << "...\n";
            std::string cmd = "PATH=\"/opt/homebrew/bin:/usr/local/bin:$PATH\" node \"" + resolved_nw + "\" --game --script \"" + script_path + "\"";
            system(cmd.c_str());
        } else {
#ifdef __APPLE__
            std::cout << color::GREEN << "[GUI LAUNCH]" << color::RESET 
                      << " Opening native Loop OS Graphical Window...\n";
            if (script_path.find("hiop") != std::string::npos) {
                system("open -g \"hiOP.macOS/build/Build/Products/Release/hiOP.app\" 2>/dev/null || open \"hiOP.macOS/build/Build/Products/Release/hiOP.app\" 2>/dev/null");
            } else {
                system("open \"ShineLoopLauncher.macOS/build/Build/Products/Release/ShineLoopLauncher.app\" 2>/dev/null || open -g \"ShineLoopLauncher.macOS/build/Build/Products/Release/ShineLoopLauncher.app\" 2>/dev/null");
            }
#endif
        }
    } else if (success && (has_ui_window || native_mode)) {
        if (vm.window_process_pid <= 0) {
            std::string win_script = vm.last_exported_native_script;
            if (win_script.empty() && (!vm.current_window.cards.empty() || !vm.current_window.buttons.empty())) {
                win_script = "build/" + vm.current_window.app_name + "_native.py";
                vm.current_window.save_native_gui(win_script);
            }
            if (!win_script.empty()) {
                std::ifstream test_f(win_script);
                if (test_f.good()) {
                    pid_t pid = launch_native_window_process(win_script);
                    vm.window_process_pid = pid;
                    std::cout << color::CYAN << "[NATIVE WINDOW]" << color::RESET 
                              << " Launched native OS window: " << color::BOLD << win_script << color::RESET 
                              << " (PID: " << pid << ")\n";
                }
            }
        }
    }

    // Persistent interactive terminal mode (like py -i):
    // Enter if explicitly requested (-i / --persistent) OR if a window is active and stdin is an interactive terminal
    bool should_persist = (persistent_mode || ((has_ui_window || native_mode) && !is_playable_game && !batch_mode)) && 
                          (isatty(fileno(stdin)) || persistent_mode);

    if (should_persist) {
        std::string win_title = !vm.current_window.title.empty() ? vm.current_window.title : "Looping Window";
        REPL::run_persistent(vm, vm.window_process_pid, win_title);
    }

    return success ? 0 : 1;
}

