#include "LoopingInterpreter.hpp"
#include "LoopingREPL.hpp"
#include <iostream>
#include <string>
#include <vector>

using namespace looping;

void print_usage(const char* prog_name) {
    std::cout << color::BOLD << "Usage:" << color::RESET << "\n";
    std::cout << "  " << prog_name << " <script.loop>            Execute Looping script\n";
    std::cout << "  " << prog_name << " run <script.loop>        Execute Looping script\n";
    std::cout << "  " << prog_name << " create <name> [--type]   Create and synthesize new dynamic program\n";
    std::cout << "  " << prog_name << " compile <file.loop>      Compile script for target UI profile\n";
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

    // Dynamic Program Creator: looping create <name> [--type <arcade|dashboard|tool>] [--target <shine_ui|xui|flui>] [--output <out>]
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

    // Run command: looping run <script.loop> [flags] OR looping <script.loop> [flags]
    std::string script_path = first_arg;
    int arg_start = 2;
    if (first_arg == "run" && argc >= 3) {
        script_path = argv[2];
        arg_start = 3;
    }

    for (int i = arg_start; i < argc; ++i) {
        std::string arg = argv[i];
        if ((arg == "--target" || arg == "-t" || arg == "--ui") && i + 1 < argc) {
            vm.set_target_ui(argv[++i]);
        }
    }

    bool success = vm.execute_file(script_path);
    return success ? 0 : 1;
}

