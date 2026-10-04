#pragma once

#include "LoopingValue.hpp"
#include <string>
#include <vector>
#include <memory>

namespace looping {

// Base Expression
class Expr {
public:
    virtual ~Expr() = default;
};

// Literal (number, string, bool, nil)
class LiteralExpr : public Expr {
public:
    Value val;
    LiteralExpr(Value v) : val(v) {}
};

// Variable reference
class VariableExpr : public Expr {
public:
    std::string name;
    VariableExpr(const std::string& n) : name(n) {}
};

// Tuple (x, y)
class TupleExpr : public Expr {
public:
    std::shared_ptr<Expr> x;
    std::shared_ptr<Expr> y;
    TupleExpr(std::shared_ptr<Expr> _x, std::shared_ptr<Expr> _y) : x(_x), y(_y) {}
};

// Binary Expression
class BinaryExpr : public Expr {
public:
    std::shared_ptr<Expr> left;
    std::string op;
    std::shared_ptr<Expr> right;
    BinaryExpr(std::shared_ptr<Expr> l, const std::string& o, std::shared_ptr<Expr> r)
        : left(l), op(o), right(r) {}
};

// Unary Expression
class UnaryExpr : public Expr {
public:
    std::string op;
    std::shared_ptr<Expr> operand;
    UnaryExpr(const std::string& o, std::shared_ptr<Expr> opnd) : op(o), operand(opnd) {}
};

// Function Call Expression: func(a, b, c)
class CallExpr : public Expr {
public:
    std::string callee;
    std::vector<std::shared_ptr<Expr>> args;
    CallExpr(const std::string& c, const std::vector<std::shared_ptr<Expr>>& a)
        : callee(c), args(a) {}
};

// Python Inline Expression: py: math.sqrt(16) * 1.5
class PyInlineExpr : public Expr {
public:
    std::string py_code;
    PyInlineExpr(const std::string& c) : py_code(c) {}
};

// Interpolated String: "Hello {name}, level: {lvl}"
class InterpolatedStringExpr : public Expr {
public:
    std::string raw_template;
    InterpolatedStringExpr(const std::string& t) : raw_template(t) {}
};

// Base Statement
class Stmt {
public:
    virtual ~Stmt() = default;
};

// Print / Echo
class PrintStmt : public Stmt {
public:
    std::vector<std::shared_ptr<Expr>> expressions;
    PrintStmt(const std::vector<std::shared_ptr<Expr>>& exprs) : expressions(exprs) {}
};

// Assignment: set x to 10, set x = 10, x += 5
class SetStmt : public Stmt {
public:
    std::string var_name;
    std::string op; // "=", "+=", "-=", "*=", "/="
    std::shared_ptr<Expr> value_expr;
    SetStmt(const std::string& name, const std::string& o, std::shared_ptr<Expr> val)
        : var_name(name), op(o), value_expr(val) {}
};

// Conditional: if cond do stmt OR if cond { ... } else { ... }
class IfStmt : public Stmt {
public:
    std::shared_ptr<Expr> condition;
    std::vector<std::shared_ptr<Stmt>> then_branch;
    std::vector<std::shared_ptr<Stmt>> else_branch;
    IfStmt(std::shared_ptr<Expr> cond, const std::vector<std::shared_ptr<Stmt>>& then_b, const std::vector<std::shared_ptr<Stmt>>& else_b = {})
        : condition(cond), then_branch(then_b), else_branch(else_b) {}
};

// Repeat Loop: repeat N times { ... }
class RepeatStmt : public Stmt {
public:
    std::shared_ptr<Expr> count_expr;
    std::vector<std::shared_ptr<Stmt>> body;
    RepeatStmt(std::shared_ptr<Expr> c, const std::vector<std::shared_ptr<Stmt>>& b)
        : count_expr(c), body(b) {}
};

// While Loop: while cond { ... }
class WhileStmt : public Stmt {
public:
    std::shared_ptr<Expr> condition;
    std::vector<std::shared_ptr<Stmt>> body;
    WhileStmt(std::shared_ptr<Expr> cond, const std::vector<std::shared_ptr<Stmt>>& b)
        : condition(cond), body(b) {}
};

// For Range Loop: for i in start..end { ... }
class ForRangeStmt : public Stmt {
public:
    std::string var_name;
    std::shared_ptr<Expr> start_expr;
    std::shared_ptr<Expr> end_expr;
    std::vector<std::shared_ptr<Stmt>> body;
    ForRangeStmt(const std::string& var, std::shared_ptr<Expr> s, std::shared_ptr<Expr> e, const std::vector<std::shared_ptr<Stmt>>& b)
        : var_name(var), start_expr(s), end_expr(e), body(b) {}
};

// Return Statement: return <expr>
class ReturnStmt : public Stmt {
public:
    std::shared_ptr<Expr> value_expr;
    ReturnStmt(std::shared_ptr<Expr> val = nullptr) : value_expr(val) {}
};

// Break Statement: break
class BreakStmt : public Stmt {
public:
    BreakStmt() = default;
};

// Expression Statement: expr (e.g. pipelines, function calls)
class ExprStmt : public Stmt {
public:
    std::shared_ptr<Expr> expr;
    ExprStmt(std::shared_ptr<Expr> e) : expr(e) {}
};

// Function Definition: function name(p1, p2) { ... }
class FunctionDefStmt : public Stmt {
public:
    std::string name;
    std::vector<std::string> params;
    std::vector<std::shared_ptr<Stmt>> body;
    FunctionDefStmt(const std::string& n, const std::vector<std::string>& p, const std::vector<std::shared_ptr<Stmt>>& b)
        : name(n), params(p), body(b) {}
};

// Function Call Statement: call name(args)
class CallStmt : public Stmt {
public:
    std::string name;
    std::vector<std::shared_ptr<Expr>> args;
    CallStmt(const std::string& n, const std::vector<std::shared_ptr<Expr>>& a = {})
        : name(n), args(a) {}
};

// Python Multi-line Block: python { ... }
class PythonBlockStmt : public Stmt {
public:
    std::string py_code;
    PythonBlockStmt(const std::string& code) : py_code(code) {}
};

// Python Snippet Definition: insert pysnippet as <name>: ...
class PySnippetDefStmt : public Stmt {
public:
    std::string snippet_name;
    std::string py_code;
    PySnippetDefStmt(const std::string& name, const std::string& code)
        : snippet_name(name), py_code(code) {}
};

// Import: import loop.ui as ui / use python "math" / from pyloop import snippets runpy
class ImportStmt : public Stmt {
public:
    std::string module_name;
    std::string alias;
    bool is_python;
    std::vector<std::string> symbols;
    ImportStmt(const std::string& mod, const std::string& al = "", bool py = false, const std::vector<std::string>& syms = {})
        : module_name(mod), alias(al), is_python(py), symbols(syms) {}
};

// App Definition: define app "Name" version 1.0
class AppDefineStmt : public Stmt {
public:
    std::string app_name;
    std::string version;
    AppDefineStmt(const std::string& name, const std::string& ver) : app_name(name), version(ver) {}
};

// Window: create window with title "..." and size (w, h)
class WindowStmt : public Stmt {
public:
    std::string title;
    double width;
    double height;
    WindowStmt(const std::string& t, double w, double h) : title(t), width(w), height(h) {}
};

// Theme / UI Profile: set theme to "..." / set ui_profile to "..."
class ConfigStmt : public Stmt {
public:
    std::string key;
    std::string value;
    ConfigStmt(const std::string& k, const std::string& v) : key(k), value(v) {}
};

// Draw UI: draw card / button / input
class DrawUIStmt : public Stmt {
public:
    std::string ui_type; // "card", "button", "input", "label"
    double x = 0, y = 0, w = 0, h = 0;
    std::string title;
    std::string text;
    std::string action;
    std::string placeholder;
    std::string var_name;
    std::string color;
};

// Spawn Entity: spawn sprite / platform / coin / bubbly_dot
class SpawnEntityStmt : public Stmt {
public:
    std::string entity_type; // "sprite", "platform", "coin", "bubbly_dot"
    std::string name;
    double x = 0, y = 0, w = 0, h = 0;
    std::string color;
    double points = 0;
    std::string text;
    std::string state;
};

// Emit Particles
class EmitParticlesStmt : public Stmt {
public:
    double x = 0, y = 0;
    std::string color;
    EmitParticlesStmt(double _x, double _y, const std::string& col) : x(_x), y(_y), color(col) {}
};

// Audio: play tone at 587 Hz for 100 ms
class PlayToneStmt : public Stmt {
public:
    double freq_hz;
    double duration_ms;
    PlayToneStmt(double f, double d) : freq_hz(f), duration_ms(d) {}
};

// Kernel Syscall & Process
class SyscallStmt : public Stmt {
public:
    std::string call_name;
    std::string args;
    SyscallStmt(const std::string& n, const std::string& a = "") : call_name(n), args(a) {}
};

class SpawnProcessStmt : public Stmt {
public:
    std::string process_name;
    int priority = 10;
    SpawnProcessStmt(const std::string& n, int p = 10) : process_name(n), priority(p) {}
};

} // namespace looping
