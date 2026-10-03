#include "LoopingInterpreter.hpp"
#include "LoopingREPL.hpp"
#include <iostream>
#include <string>
#include <vector>

using namespace looping;

void print_usage(const char* prog_name) {
    std::cout << color::BOLD << "Usage:" << color::RESET << "\n";
    std::cout << "  " << prog_name << " <script.loop>            Execute Looping script\n";
    std::cout << "  " << prog_name << " repl                     Launch interactive REPL shell\n";
    std::cout << "  " << prog_name << " eval \"<code>\"            Evaluate inline code string\n";
    std::cout << "  " << prog_name << " test                     Run built-in engine test suite\n";
    std::cout << "  " << prog_name << " --version, -v            Display engine version\n";
    std::cout << "  " << prog_name << " --help, -h               Show this help message\n\n";
}

int run_tests() {
    std::cout << color::BOLD << color::CYAN << "[TEST SUITE]" << color::RESET << " Running Looping C++ verification suite...\n\n";
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

    // Test 1: Variable assignments & Math
    vm.execute_code("set a to 15\nset b = 25\nset c = a + b");
    assert_test("Variable Assignment & Addition", vm.variables["c"].as_int() == 40);

    // Test 2: Arithmetic shorthand
    vm.execute_code("set score = 100\nscore += 50\nscore *= 2");
    assert_test("Shorthand Operators (+=, *=)", vm.variables["score"].as_int() == 300);

    // Test 3: Math functions
    vm.execute_code("set sq = math.sqrt(144)\nset pw = math.pow(2, 8)");
    assert_test("Math Builtins (sqrt, pow)", vm.variables["sq"].as_int() == 12 && vm.variables["pw"].as_int() == 256);

    // Test 4: String Interpolation
    vm.execute_code("set user to 'Angel'\nset greeting to 'Hello {user}!'");
    assert_test("String Interpolation", vm.variables["greeting"].as_string() == "Hello Angel!");

    // Test 5: Repeat loop
    vm.execute_code("set total = 0\nrepeat 5 times {\n total += 10\n}");
    assert_test("Repeat Loop", vm.variables["total"].as_int() == 50);

    // Test 6: Conditionals
    vm.execute_code("set flag = false\nif total == 50 do set flag to true");
    assert_test("Inline Conditionals", vm.variables["flag"].is_truthy());

    // Test 7: Python Bridge if available
    if (vm.python_bridge.is_available) {
        vm.execute_code("set py_val to py: math.sqrt(64)");
        assert_test("Python Bridge Inline Eval", vm.variables["py_val"].as_int() == 8);
    } else {
        std::cout << "  " << color::YELLOW << "⚠ [SKIP]" << color::RESET << " Python Bridge (No python executable in PATH)\n";
    }

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

    if (first_arg == "eval") {
        if (argc < 3) {
            std::cerr << color::RED << "Error: 'eval' requires code argument.\n" << color::RESET;
            return 1;
        }
        std::string code = argv[2];
        vm.execute_code(code);
        return 0;
    }

    if (first_arg == "test") {
        return run_tests();
    }

    // Default: run script file
    bool success = vm.execute_file(first_arg);
    return success ? 0 : 1;
}
