#pragma once

#include "LoopingValue.hpp"
#include <string>
#include <vector>
#include <memory>
#include <map>

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

// List Literal: [1, 2, 3]
class ListExpr : public Expr {
public:
    std::vector<std::shared_ptr<Expr>> elements;
    ListExpr(const std::vector<std::shared_ptr<Expr>>& elems) : elements(elems) {}
};

// Map Literal: {"key": val, "k2": v2}
class MapExpr : public Expr {
public:
    std::vector<std::pair<std::string, std::shared_ptr<Expr>>> entries;
    MapExpr(const std::vector<std::pair<std::string, std::shared_ptr<Expr>>>& ents) : entries(ents) {}
};

// Index Expression: target[index]
class IndexExpr : public Expr {
public:
    std::shared_ptr<Expr> target;
    std::shared_ptr<Expr> index;
    IndexExpr(std::shared_ptr<Expr> tgt, std::shared_ptr<Expr> idx)
        : target(tgt), index(idx) {}
};

// Ternary Conditional Expression: cond ? then_expr : else_expr
class TernaryExpr : public Expr {
public:
    std::shared_ptr<Expr> condition;
    std::shared_ptr<Expr> then_expr;
    std::shared_ptr<Expr> else_expr;
    TernaryExpr(std::shared_ptr<Expr> c, std::shared_ptr<Expr> t, std::shared_ptr<Expr> e)
        : condition(c), then_expr(t), else_expr(e) {}
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

// For Range Loop: for i in start..end { ... } / start..=end / step S
class ForRangeStmt : public Stmt {
public:
    std::string var_name;
    std::shared_ptr<Expr> start_expr;
    std::shared_ptr<Expr> end_expr;
    std::vector<std::shared_ptr<Stmt>> body;
    bool inclusive = false;
    std::shared_ptr<Expr> step_expr = nullptr;
    ForRangeStmt(const std::string& var, std::shared_ptr<Expr> s, std::shared_ptr<Expr> e,
                 const std::vector<std::shared_ptr<Stmt>>& b, bool inc = false, std::shared_ptr<Expr> st = nullptr)
        : var_name(var), start_expr(s), end_expr(e), body(b), inclusive(inc), step_expr(st) {}
};

// For-Each Loop: for (item in list_expr) { ... }
class ForEachStmt : public Stmt {
public:
    std::string var_name;
    std::shared_ptr<Expr> collection_expr;
    std::vector<std::shared_ptr<Stmt>> body;
    ForEachStmt(const std::string& var, std::shared_ptr<Expr> coll, const std::vector<std::shared_ptr<Stmt>>& b)
        : var_name(var), collection_expr(coll), body(b) {}
};

// Index Assignment Statement: arr[0] = 10, map["key"] = "val"
class SetIndexStmt : public Stmt {
public:
    std::string var_name;
    std::shared_ptr<Expr> index_expr;
    std::string op;
    std::shared_ptr<Expr> value_expr;
    SetIndexStmt(const std::string& name, std::shared_ptr<Expr> idx, const std::string& o, std::shared_ptr<Expr> val)
        : var_name(name), index_expr(idx), op(o), value_expr(val) {}
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

// Continue Statement: continue
class ContinueStmt : public Stmt {
public:
    ContinueStmt() = default;
};

// Pattern Match Statement: match <expr> { pattern => stmt ... }
struct MatchArm {
    std::shared_ptr<Expr> pattern; // nullptr for wildcard _ / default
    std::vector<std::shared_ptr<Expr>> patterns; // multi-pattern: "S" | "SS" => ...
    bool is_range = false;
    bool range_inclusive = false;
    std::shared_ptr<Expr> range_start;
    std::shared_ptr<Expr> range_end;
    std::vector<std::shared_ptr<Stmt>> body;
};

class MatchStmt : public Stmt {
public:
    std::shared_ptr<Expr> target;
    std::vector<MatchArm> arms;
    MatchStmt(std::shared_ptr<Expr> tgt, const std::vector<MatchArm>& a)
        : target(tgt), arms(a) {}
};

// Destructuring Declaration: let [a, b] = expr OR let (x, y) = expr
class DestructureStmt : public Stmt {
public:
    std::vector<std::string> var_names;
    std::shared_ptr<Expr> value_expr;
    DestructureStmt(const std::vector<std::string>& names, std::shared_ptr<Expr> val)
        : var_names(names), value_expr(val) {}
};

// Try / Catch Block: try { ... } catch (err) { ... }
class TryCatchStmt : public Stmt {
public:
    std::vector<std::shared_ptr<Stmt>> try_body;
    std::string err_var;
    std::vector<std::shared_ptr<Stmt>> catch_body;
    TryCatchStmt(const std::vector<std::shared_ptr<Stmt>>& tb, const std::string& ev, const std::vector<std::shared_ptr<Stmt>>& cb)
        : try_body(tb), err_var(ev), catch_body(cb) {}
};

// Throw Statement: throw <expr>
class ThrowStmt : public Stmt {
public:
    std::shared_ptr<Expr> error_expr;
    ThrowStmt(std::shared_ptr<Expr> e) : error_expr(e) {}
};

// Assert Statement: assert(cond, msg) / assert cond
class AssertStmt : public Stmt {
public:
    std::shared_ptr<Expr> condition;
    std::shared_ptr<Expr> message;
    AssertStmt(std::shared_ptr<Expr> c, std::shared_ptr<Expr> m = nullptr)
        : condition(c), message(m) {}
};

// Expression Statement: expr (e.g. pipelines, function calls)
class ExprStmt : public Stmt {
public:
    std::shared_ptr<Expr> expr;
    ExprStmt(std::shared_ptr<Expr> e) : expr(e) {}
};

// Function Definition: function name(p1, p2 = default) { ... }
class FunctionDefStmt : public Stmt {
public:
    std::string name;
    std::vector<std::string> params;
    std::vector<std::shared_ptr<Expr>> default_values;
    std::vector<std::shared_ptr<Stmt>> body;
    FunctionDefStmt(const std::string& n, const std::vector<std::string>& p, const std::vector<std::shared_ptr<Stmt>>& b,
                    const std::vector<std::shared_ptr<Expr>>& defs = {})
        : name(n), params(p), default_values(defs), body(b) {}
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

// Module Definition: define module "Name" version 1.0
class ModuleDefineStmt : public Stmt {
public:
    std::string module_name;
    std::string version;
    ModuleDefineStmt(const std::string& name, const std::string& ver = "1.0")
        : module_name(name), version(ver) {}
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

// Target UI Compilation: compile target "shine_ui" / target("xui") / @target("flui")
class TargetCompileStmt : public Stmt {
public:
    std::string target_ui; // "shine_ui", "xui", "flui"
    TargetCompileStmt(const std::string& t) : target_ui(t) {}
};

// Draw UI: draw card / button / input / slider / toggle / progress
class DrawUIStmt : public Stmt {
public:
    std::string ui_type; // "card", "button", "input", "label", "slider", "toggle", "progress"
    double x = -1, y = -1, w = 0, h = 0;
    std::string title;
    std::string text;
    std::string action;
    std::string placeholder;
    std::string var_name;
    std::string color;
    std::string snippet;
    double min_val = 0, max_val = 100, current_val = 0;
    bool is_checked = false;
    std::string position = "top";
    std::string visible_when;
    std::vector<std::string> actions_list;
};

// Spawn Entity: spawn sprite / platform / coin / bubbly_dot / spike / jump_pad / orb / moving_platform / enemy / boss / heart / portal / checkpoint / gravity_zone / teleporter / breakable / laser_hazard
class SpawnEntityStmt : public Stmt {
public:
    std::string entity_type; // "sprite", "platform", "coin", "bubbly_dot", "spike", "jump_pad", "orb", "moving_platform", "enemy", "boss", "heart", "portal", "checkpoint", "gravity_zone", "teleporter", "breakable", "laser_hazard"
    std::string name;
    double x = 0, y = 0, w = 0, h = 0;
    std::string color;
    double points = 0;
    std::string text;
    std::string state;
    // Enhanced 2D game capabilities
    std::string axis = "x";
    double min_pos = 0, max_pos = 0;
    double speed = 80;
    double power = 650;
    double health = 100;
    double damage = 25;
    double to_x = 0, to_y = 0;
    double scale = 0.35;
    double wind_x = 0, wind_y = 0;
    double fire_rate = 1.8;
    double interval = 2.0;
    std::string dest = "";
};

// Game World & Physics Directives: game.gravity(...) / game.world(...) / game.camera(...) / game.lives(...) / game.scenario(...) / game.physics(...) / game.time_scale(...)
class GameConfigStmt : public Stmt {
public:
    std::string config_key; // "gravity", "world", "camera", "lives", "friction", "scenario", "physics", "time_scale"
    double val1 = 0, val2 = 0, val3 = 0;
    std::string str_val = "";
    std::string str_val2 = "";
    std::string str_val3 = "";
    GameConfigStmt(const std::string& key, double v1 = 0, double v2 = 0, const std::string& sv = "",
                   const std::string& sv2 = "", const std::string& sv3 = "", double v3 = 0)
        : config_key(key), val1(v1), val2(v2), val3(v3), str_val(sv), str_val2(sv2), str_val3(sv3) {}
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

// Dynamic Program Compilation: compile program "Name" [target "flui"] [to "path"] [and run]: ...
class DynamicProgramCompileStmt : public Stmt {
public:
    std::string program_name;
    std::string target_ui = "shine_ui";
    std::string output_path = "";
    std::string version = "1.0";
    std::string title = "";
    double width = 800;
    double height = 520;
    std::string theme = "";
    bool and_run = false;
    std::vector<std::string> raw_lines;
    std::vector<std::shared_ptr<Stmt>> inner_statements;

    DynamicProgramCompileStmt(const std::string& name, const std::string& target = "shine_ui", const std::string& out = "", const std::string& ver = "1.0")
        : program_name(name), target_ui(target), output_path(out), version(ver) {}
};

// ── SwiftUI View Hierarchy Declarative Nodes (v2.9 Experience) ──

enum class SwiftUIViewType {
    VStack,
    HStack,
    ZStack,
    List,
    ScrollView,
    Section,
    Group,
    ForEach,
    Text,
    Button,
    Image,
    TextField,
    Toggle,
    Slider,
    ProgressView,
    Spacer,
    Divider,
    Badge,
    Circle,
    Rectangle,
    RoundedRectangle,
    Color,
    Custom
};

inline std::string swiftui_view_type_name(SwiftUIViewType t) {
    switch (t) {
        case SwiftUIViewType::VStack: return "VStack";
        case SwiftUIViewType::HStack: return "HStack";
        case SwiftUIViewType::ZStack: return "ZStack";
        case SwiftUIViewType::List: return "List";
        case SwiftUIViewType::ScrollView: return "ScrollView";
        case SwiftUIViewType::Section: return "Section";
        case SwiftUIViewType::Group: return "Group";
        case SwiftUIViewType::ForEach: return "ForEach";
        case SwiftUIViewType::Text: return "Text";
        case SwiftUIViewType::Button: return "Button";
        case SwiftUIViewType::Image: return "Image";
        case SwiftUIViewType::TextField: return "TextField";
        case SwiftUIViewType::Toggle: return "Toggle";
        case SwiftUIViewType::Slider: return "Slider";
        case SwiftUIViewType::ProgressView: return "ProgressView";
        case SwiftUIViewType::Spacer: return "Spacer";
        case SwiftUIViewType::Divider: return "Divider";
        case SwiftUIViewType::Badge: return "Badge";
        case SwiftUIViewType::Circle: return "Circle";
        case SwiftUIViewType::Rectangle: return "Rectangle";
        case SwiftUIViewType::RoundedRectangle: return "RoundedRectangle";
        case SwiftUIViewType::Color: return "Color";
        case SwiftUIViewType::Custom: return "CustomView";
    }
    return "UnknownView";
}

struct SwiftUIModifier {
    std::string name; // "padding", "background", "foregroundColor", "foregroundStyle", "tint", "cornerRadius", "frame", "font", "fontWeight", "shadow", "opacity", "border", "buttonStyle", "onTapGesture"
    std::vector<std::string> args;
    std::map<std::string, std::string> named_args;
};

class SwiftUIViewNode {
public:
    SwiftUIViewType type = SwiftUIViewType::VStack;
    std::string custom_name = "";
    std::string primary_arg = ""; // Text label, Button title, Image name
    std::map<std::string, std::string> attributes; // spacing, alignment, role, etc.
    std::vector<SwiftUIModifier> modifiers;
    std::vector<std::shared_ptr<SwiftUIViewNode>> children;
    std::string action_code = ""; // Button action code or trailing closure
    std::string binding_var = ""; // For $state binding in TextField, Toggle, Slider
    std::string foreach_collection = ""; // Collection for ForEach
    std::string foreach_item_var = "";   // Iteration item variable name

    SwiftUIViewNode(SwiftUIViewType t = SwiftUIViewType::VStack) : type(t) {}
};

class SwiftUIStateDecl {
public:
    std::string name;
    std::string type_hint; // "Int", "String", "Double", "Bool", "Any"
    std::string initial_expr_str;
    std::shared_ptr<Expr> initial_expr = nullptr;
};

class SwiftUIComponentDeclStmt : public Stmt {
public:
    std::string name; // "DashboardView"
    std::vector<std::string> params;
    std::vector<SwiftUIStateDecl> states; // @state variables
    std::shared_ptr<SwiftUIViewNode> root_view;
    std::vector<SwiftUIModifier> root_modifiers;

    SwiftUIComponentDeclStmt(const std::string& n) : name(n) {}
};

class SwiftUIViewRenderStmt : public Stmt {
public:
    std::shared_ptr<SwiftUIViewNode> root_view;
    std::vector<SwiftUIModifier> root_modifiers;
    SwiftUIViewRenderStmt(std::shared_ptr<SwiftUIViewNode> r) : root_view(r) {}
};

} // namespace looping

