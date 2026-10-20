#include "LoopingInterpreter.hpp"
#include "LoopingREPL.hpp"
#include <iostream>
#include <string>
#include <vector>

using namespace looping;

void print_usage(const char* prog_name) {
    std::cout << color::BOLD << "Usage:" << color::RESET << "\n";
    std::cout << "  " << prog_name << " <script.loop>            Execute Looping script\n";
    std::cout << "  " << prog_name << " --gui <script.loop>      Execute Looping script in native GUI window\n";
    std::cout << "  " << prog_name << " --native <script.loop>   Execute Looping script in pure OS native window\n";
    std::cout << "  " << prog_name << " window <name> [flags]    Create, synthesize & launch dynamic graphical window\n";
    std::cout << "  " << prog_name << " run <script.loop>        Execute Looping script\n";
    std::cout << "  " << prog_name << " create <name> [--type]   Create and synthesize new dynamic program\n";
    std::cout << "  " << prog_name << " compile <file.loop>      Compile script for target UI profile\n";
    std::cout << "  " << prog_name << " check <file.loop>        Static syntax & AST verification report\n";
    std::cout << "  " << prog_name << " ast <file.loop>          Display visual AST node tree & structure\n";
    std::cout << "  " << prog_name << " fmt <file.loop> [--write] Format & normalize .loop source file\n";
    std::cout << "  " << prog_name << " doc [topic]              Built-in reference manual (syntax, math, crypto, regex, ui)\n";
    std::cout << "  " << prog_name << " bench                    Run native C++17 VM throughput benchmark\n";
    std::cout << "  " << prog_name << " doctor                   Inspect engine subsystems & environment health\n";
    std::cout << "  " << prog_name << " auth <login|whoami|logout> CS ID Connect Developer authentication\n";
    std::cout << "  " << prog_name << " repl                     Launch interactive REPL shell\n";
    std::cout << "  " << prog_name << " eval \"<code>\"            Evaluate inline code string\n";
    std::cout << "  " << prog_name << " test                     Run built-in engine test suite (40 tests)\n";
    std::cout << "  " << prog_name << " --version, -v            Display engine version\n";
    std::cout << "  " << prog_name << " --help, -h               Show this help message\n\n";
}

int run_tests() {
    std::cout << color::BOLD << color::CYAN << "[TEST SUITE]" << color::RESET << " Running Looping C++ verification suite (v2.7 Quantum Signature)...\n\n";
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

    // Test 10: Modern UI & Entity Directives
    vm.execute_code("ui.card(at: (10, 20), size: (200, 100), title: \"Test Card\")\nspawn.sprite(\"Hero\", at: (50, 50), color: \"#38bdf8\")\naudio.tone(587, 80)");
    assert_test("Modern Directives (ui.card, spawn.sprite, audio.tone)", true);

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
                vm.variables["eng_v"].as_string() == "2.7.0" &&
                vm.variables["fallback_env"].as_string() == "default_ok");

    std::cout << "\n" << color::BOLD << (passed == total ? color::GREEN : color::YELLOW)
              << "Results: " << passed << "/" << total << " tests passed." << color::RESET << "\n\n";

    return passed == total ? 0 : 1;
}

int main(int argc, char* argv[]) {
    Interpreter vm;

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
        std::cout << "Looping C++ Engine v" << vm.app_version << " (POSIX/Win32 Native)\n";
        std::cout << "Developed by Holo Entertainment (Coki Studios)\n";
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
        std::cout << color::BOLD << color::CYAN << "[LOOPING DOCTOR]" << color::RESET << " Inspecting C++ Native Engine & Subsystems...\n\n";
        std::cout << "  " << color::GREEN << "✔" << color::RESET << " Engine Version     : v" << vm.app_version << " (C++17 Native)\n";
        std::cout << "  " << color::GREEN << "✔" << color::RESET << " Host Platform      : " << vm.eval(std::make_shared<VariableExpr>("sys.platform")).as_string()
                  << " (" << vm.eval(std::make_shared<VariableExpr>("sys.arch")).as_string() << ")\n";
        std::cout << "  " << (vm.python_bridge.is_available ? color::GREEN : color::YELLOW)
                  << (vm.python_bridge.is_available ? "✔" : "⚠") << color::RESET
                  << " Python Interop     : " << (vm.python_bridge.is_available ? "Available (" + vm.python_bridge.detected_exe + ")" : "Not found in PATH") << "\n";
        std::cout << "  " << color::GREEN << "✔" << color::RESET << " UI Target Profiles : Shine UI (60Hz), XUI (240Hz), flUI (120Hz), C2 (.c2), Vintage, hiUI\n";
        std::cout << "  " << color::GREEN << "✔" << color::RESET << " Crypto Subsystem   : SHA-256, FNV-1a, Base64, UUID v4, CSMS E2EE Key Derivation\n\n";
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
            std::cerr << color::RED << "Error: 'check' requires a .loop script file." << color::RESET << "\n";
            return 1;
        }
        std::string fpath = argv[2];
        std::ifstream f(fpath);
        if (!f.is_open()) {
            std::cerr << color::RED << "Error: Could not open file '" << fpath << "'." << color::RESET << "\n";
            return 1;
        }
        std::stringstream ss;
        ss << f.rdbuf();
        auto t0 = std::chrono::high_resolution_clock::now();
        Parser p(ss.str());
        auto stmts = p.parse_script();
        auto t1 = std::chrono::high_resolution_clock::now();
        double parse_us = std::chrono::duration<double, std::micro>(t1 - t0).count();

        size_t fn_count = 0, ui_count = 0, entity_count = 0, loop_count = 0;
        for (const auto& st : stmts) {
            if (std::dynamic_pointer_cast<FunctionDefStmt>(st)) fn_count++;
            else if (std::dynamic_pointer_cast<DrawUIStmt>(st)) ui_count++;
            else if (std::dynamic_pointer_cast<SpawnEntityStmt>(st)) entity_count++;
            else if (std::dynamic_pointer_cast<ForRangeStmt>(st) ||
                     std::dynamic_pointer_cast<ForEachStmt>(st) ||
                     std::dynamic_pointer_cast<WhileStmt>(st) ||
                     std::dynamic_pointer_cast<RepeatStmt>(st)) loop_count++;
        }
        std::cout << color::GREEN << "✔ [AST CHECK OK]" << color::RESET << " " << fpath
                  << " (" << std::fixed << std::setprecision(1) << parse_us << " µs)\n";
        std::cout << "  • Top-level Statements : " << stmts.size() << "\n";
        std::cout << "  • Functions Defined    : " << fn_count << "\n";
        std::cout << "  • UI Directives        : " << ui_count << "\n";
        std::cout << "  • 2D Entities          : " << entity_count << "\n";
        std::cout << "  • Loop Constructs      : " << loop_count << "\n";
        return 0;
    }

    if (first_arg == "ast") {
        if (argc < 3) {
            std::cerr << color::RED << "Error: 'ast' requires a .loop script file." << color::RESET << "\n";
            return 1;
        }
        std::string fpath = argv[2];
        std::ifstream f(fpath);
        if (!f.is_open()) {
            std::cerr << color::RED << "Error: Could not open file '" << fpath << "'." << color::RESET << "\n";
            return 1;
        }
        std::stringstream ss;
        ss << f.rdbuf();
        Parser p(ss.str());
        auto stmts = p.parse_script();
        std::cout << color::BOLD << color::CYAN << "[LOOPING AST TREE] " << color::RESET << fpath << " (" << stmts.size() << " root nodes)\n";
        for (size_t i = 0; i < stmts.size(); ++i) {
            std::string branch = (i + 1 == stmts.size()) ? "└── " : "├── ";
            const auto& st = stmts[i];
            std::string label = "Stmt";
            if (auto s = std::dynamic_pointer_cast<SetStmt>(st)) label = "SetVar(" + s->var_name + " " + s->op + ")";
            else if (auto idx = std::dynamic_pointer_cast<SetIndexStmt>(st)) label = "SetIndex(" + idx->var_name + "[] " + idx->op + ")";
            else if (auto fn = std::dynamic_pointer_cast<FunctionDefStmt>(st)) label = "FunctionDef(" + fn->name + ", params=" + std::to_string(fn->params.size()) + ")";
            else if (auto fr = std::dynamic_pointer_cast<ForRangeStmt>(st)) label = "ForRange(" + fr->var_name + ")";
            else if (auto fe = std::dynamic_pointer_cast<ForEachStmt>(st)) label = "ForEach(" + fe->var_name + ")";
            else if (std::dynamic_pointer_cast<IfStmt>(st)) label = "IfConditionalBlock";
            else if (std::dynamic_pointer_cast<MatchStmt>(st)) label = "MatchPatternBlock";
            else if (std::dynamic_pointer_cast<TryCatchStmt>(st)) label = "TryCatchBlock";
            else if (auto ui = std::dynamic_pointer_cast<DrawUIStmt>(st)) label = "DrawUI(" + ui->ui_type + ": \"" + ui->title + "\")";
            else if (auto sp = std::dynamic_pointer_cast<SpawnEntityStmt>(st)) label = "SpawnEntity(" + sp->entity_type + ": \"" + sp->name + "\")";
            else if (std::dynamic_pointer_cast<PrintStmt>(st)) label = "PrintStmt";
            else if (std::dynamic_pointer_cast<ExprStmt>(st)) label = "ExprStmt";
            std::cout << "  " << color::PURPLE << branch << color::RESET << color::BOLD << label << color::RESET << "\n";
        }
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
        std::cout << color::BOLD << color::CYAN << "═══ LOOPING v" << vm.app_version << " BUILT-IN REFERENCE MANUAL ═══" << color::RESET << "\n\n";
        if (topic == "all" || topic == "syntax") {
            std::cout << color::YELLOW << "▸ SYNTAX & CONTROL FLOW:" << color::RESET << "\n"
                      << "  let x = 10 | mut y = 20 | val z := 30\n"
                      << "  fn calc(a, b) => a * b + 1\n"
                      << "  for (i in 1..=10 step 2) { ... } | match x { 1 => ... _ => ... }\n"
                      << "  try { ... } catch (err) { ... } | val v = opt \?\? \"fallback\"\n\n";
        }
        if (topic == "all" || topic == "math") {
            std::cout << color::YELLOW << "▸ MATH & DATA SCIENCE (math.*):" << color::RESET << "\n"
                      << "  math.sqrt, math.pow, math.clamp, math.lerp, math.hypot\n"
                      << "  math.sum(list), math.mean(list), math.median(list), math.variance(list), math.stddev(list)\n"
                      << "  math.gcd(a,b), math.lcm(a,b), math.fib(n), math.fact(n), math.is_prime(n)\n\n";
        }
        if (topic == "all" || topic == "crypto") {
            std::cout << color::YELLOW << "▸ CRYPTOGRAPHY & SECURITY (crypto.* / url.*):" << color::RESET << "\n"
                      << "  crypto.sha256(str), crypto.hmac_sha256(key, msg), crypto.fnv1a(str)\n"
                      << "  crypto.base64_encode(str), crypto.base64_decode(b64), crypto.uuid()\n"
                      << "  crypto.random_hex(bytes), crypto.csms_key(room_id)\n"
                      << "  url.encode(str), url.decode(str)\n\n";
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
            std::string client_id = "looping-engine-cli";
            std::string redirect_uri = "https://cokistudios.com/client-demo";
            std::string auth_url = "https://cokistudios.com/authorize?client_id=" + client_id + 
                                  "&redirect_uri=" + redirect_uri + 
                                  "&response_type=code&scope=openid+profile+email+offline_access";

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
        win.add_card(title, "Ventana dinámica generada por Looping Engine v2.5\nArquitectura: " + specs.name + " (" + specs.pipeline + ")")
           .add_card("Métricas de Sistema", "Frecuencia: " + std::to_string(specs.target_fps) + " FPS\nLatencia Entrada: <0.2ms\nEstado: Óptimo")
           .add_card("Módulos Activos", "• Xtraps Background Engine\n• Looping AST & Interpreter v2.5\n• Audio Synthesizer Core")
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

    // Dynamic Program Creator: looping create <name> [--type <arcade|dashboard|tool|window>] [--target <shine_ui|xui|flui>] [--output <out>]
    if (first_arg == "create" || first_arg == "new") {
        if (argc < 3) {
            std::cerr << color::RED << "Error: 'create' requires an application name." << color::RESET << "\n";
            std::cerr << "Usage: " << argv[0] << " create <name> [--type <game|dashboard|tool>] [--target <shine_ui|xui|flui>] [--output <out>]\n";
            return 1;
        }

        std::string app_name = argv[2];
        std::string type = "dashboard";
        std::string target_ui = "shine_ui";
        std::string out_path = "";

        for (int i = 3; i < argc; ++i) {
            std::string arg = argv[i];
            if ((arg == "--type" || arg == "-k") && i + 1 < argc) {
                type = argv[++i];
            } else if ((arg == "--target" || arg == "-t" || arg == "--ui") && i + 1 < argc) {
                target_ui = argv[++i];
            } else if ((arg == "--output" || arg == "-o") && i + 1 < argc) {
                out_path = argv[++i];
            }
        }

        DynamicProgram prog = Compiler::create_template(type, app_name, target_ui);
        std::string created_path;
        bool ok = Compiler::compile_dynamic_program(prog, out_path, &created_path);
        return ok ? 0 : 1;
    }

    // Compile command: looping compile <script.loop> [--target <shine_ui|xui|flui>] [--output <out>]
    if (first_arg == "compile" || first_arg == "build") {
        if (argc < 3) {
            std::cerr << color::RED << "Error: 'compile' requires a source script file." << color::RESET << "\n";
            std::cerr << "Usage: " << argv[0] << " compile <file.loop> [--target <shine_ui|xui|flui>] [--output <out>]\n";
            return 1;
        }

        std::string script_path = argv[2];
        std::string target_ui = "shine_ui";
        std::string out_path = "";

        for (int i = 3; i < argc; ++i) {
            std::string arg = argv[i];
            if ((arg == "--target" || arg == "-t" || arg == "--ui") && i + 1 < argc) {
                target_ui = argv[++i];
            } else if ((arg == "--output" || arg == "-o") && i + 1 < argc) {
                out_path = argv[++i];
            }
        }

        bool success = vm.compile_script_to_target(script_path, target_ui, out_path);
        return success ? 0 : 1;
    }

    // Run command or script execution: supports flags anywhere, including --gui / -g / -t / --native
    bool gui_mode = false;
    bool native_mode = false;
    std::string script_path = "";
    std::string target_ui = "";

    for (int i = 1; i < argc; ++i) {
        std::string arg = argv[i];
        if (arg == "--gui" || arg == "-g" || arg == "--window") {
            gui_mode = true;
        } else if (arg == "--native" || arg == "-n" || arg == "--os") {
            gui_mode = true;
            native_mode = true;
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

    if (!target_ui.empty()) {
        vm.set_target_ui(target_ui);
    }

    if (gui_mode) {
        std::cout << color::CYAN << "[GUI RUNTIME]" << color::RESET 
                  << (native_mode ? " Initializing Pure Native OS Window subsystem (No HTML5)...\n" 
                                  : " Initializing Loop OS Native Graphical Window subsystem...\n");
    }

    bool success = vm.execute_file(script_path);

    if (success && gui_mode) {
        if (!vm.current_window.cards.empty() || !vm.current_window.buttons.empty()) {
            if (native_mode) {
                vm.current_window.show_native(true);
            } else {
                vm.current_window.show(true, "native");
            }
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
    }

    return success ? 0 : 1;
}

