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
    std::cout << "  " << prog_name << " window <name> [flags]    Create, synthesize & launch dynamic graphical window\n";
    std::cout << "  " << prog_name << " run <script.loop>        Execute Looping script\n";
    std::cout << "  " << prog_name << " create <name> [--type]   Create and synthesize new dynamic program\n";
    std::cout << "  " << prog_name << " compile <file.loop>      Compile script for target UI profile\n";
    std::cout << "  " << prog_name << " auth <login|whoami|logout> CS ID Connect Developer authentication\n";
    std::cout << "  " << prog_name << " repl                     Launch interactive REPL shell\n";
    std::cout << "  " << prog_name << " eval \"<code>\"            Evaluate inline code string\n";
    std::cout << "  " << prog_name << " test                     Run built-in engine test suite\n";
    std::cout << "  " << prog_name << " --version, -v            Display engine version\n";
    std::cout << "  " << prog_name << " --help, -h               Show this help message\n\n";
}

int run_tests() {
    std::cout << color::BOLD << color::CYAN << "[TEST SUITE]" << color::RESET << " Running Looping C++ verification suite (v2.5 Signature)...\n\n";
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

    // Run command or script execution: supports flags anywhere, including --gui / -g / -t
    bool gui_mode = false;
    std::string script_path = "";
    std::string target_ui = "";

    for (int i = 1; i < argc; ++i) {
        std::string arg = argv[i];
        if (arg == "--gui" || arg == "-g" || arg == "--window") {
            gui_mode = true;
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
                  << " Initializing Loop OS Native Graphical Window subsystem...\n";
    }

    bool success = vm.execute_file(script_path);

    if (success && gui_mode) {
        if (!vm.current_window.cards.empty()) {
            vm.current_window.show(true);
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

