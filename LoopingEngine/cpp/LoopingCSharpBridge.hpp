#pragma once

#include "LoopingValue.hpp"
#include "Looping3D.hpp"
#include <string>
#include <vector>
#include <unordered_map>
#include <sstream>
#include <fstream>
#include <iostream>
#include <algorithm>
#include <cctype>
#include <cmath>
#include <cstdlib>

namespace looping {

// ═══════════════════════════════════════════════════════════════════════
//  LOOPING C# GAME BRIDGE & ZERO-DEPENDENCY C# SUBSET RUNTIME
//  Supports `use csharp`, `cs! { ... }`, `cs!(...)`, `cssnippet`,
//  MonoBehaviour classes (Start / Update), Vector3, Mathf, Scene3D,
//  bidirectional LoopingBridge.Get/Set, .cs/.csproj export, and
//  automatic external dotnet/mcs execution when installed.
// ═══════════════════════════════════════════════════════════════════════

struct CSharpClassDef {
    std::string name;
    std::string base_class = "MonoBehaviour";
    std::unordered_map<std::string, Value> default_fields;
    std::unordered_map<std::string, std::string> methods;      // methodName -> body
    std::unordered_map<std::string, std::vector<std::string>> method_params;
};

struct CSharpInstance {
    std::string instance_id;
    std::string class_name;
    std::string bound_entity;
    std::unordered_map<std::string, Value> fields;
    bool started = false;
};

class CSharpBridge {
public:
    bool detected = false;
    bool available = false; // external dotnet/csc/mcs toolchain available
    std::string toolchain_name = "builtin-cs-vm";
    bool prefer_external = false;
    std::vector<std::string> logs;

    std::unordered_map<std::string, CSharpClassDef> classes;
    std::unordered_map<std::string, CSharpInstance> instances;

    bool detect(std::string* out_tool = nullptr) {
        if (detected) {
            if (out_tool) *out_tool = toolchain_name;
            return available;
        }
        detected = true;
#ifndef _WIN32
        if (system("command -v dotnet >/dev/null 2>&1") == 0) {
            available = true;
            toolchain_name = "dotnet";
        } else if (system("command -v mcs >/dev/null 2>&1") == 0 && system("command -v mono >/dev/null 2>&1") == 0) {
            available = true;
            toolchain_name = "mcs+mono";
        } else {
            available = false;
            toolchain_name = "builtin-cs-vm";
        }
#else
        available = false;
        toolchain_name = "builtin-cs-vm";
#endif
        if (out_tool) *out_tool = toolchain_name;
        return available;
    }

    static std::string trim(const std::string& s) {
        size_t a = 0;
        while (a < s.size() && std::isspace(static_cast<unsigned char>(s[a]))) a++;
        size_t b = s.size();
        while (b > a && std::isspace(static_cast<unsigned char>(s[b - 1]))) b--;
        return s.substr(a, b - a);
    }

    static std::string strip_comments(const std::string& code) {
        std::string out;
        out.reserve(code.size());
        bool in_str = false;
        char q = 0;
        for (size_t i = 0; i < code.size(); ++i) {
            char c = code[i];
            if (in_str) {
                out.push_back(c);
                if (c == '\\' && i + 1 < code.size()) {
                    out.push_back(code[++i]);
                } else if (c == q) {
                    in_str = false;
                }
                continue;
            }
            if (c == '"' || c == '\'') {
                in_str = true;
                q = c;
                out.push_back(c);
                continue;
            }
            if (c == '/' && i + 1 < code.size() && code[i + 1] == '/') {
                while (i < code.size() && code[i] != '\n') i++;
                out.push_back('\n');
                continue;
            }
            if (c == '/' && i + 1 < code.size() && code[i + 1] == '*') {
                i += 2;
                while (i + 1 < code.size() && !(code[i] == '*' && code[i + 1] == '/')) i++;
                i++;
                continue;
            }
            out.push_back(c);
        }
        return out;
    }

    static size_t find_matching_brace(const std::string& s, size_t open_pos) {
        int depth = 0;
        bool in_str = false;
        char q = 0;
        for (size_t i = open_pos; i < s.size(); ++i) {
            char c = s[i];
            if (in_str) {
                if (c == '\\' && i + 1 < s.size()) { i++; continue; }
                if (c == q) in_str = false;
                continue;
            }
            if (c == '"' || c == '\'') { in_str = true; q = c; continue; }
            if (c == '{') depth++;
            else if (c == '}') {
                depth--;
                if (depth == 0) return i;
            }
        }
        return std::string::npos;
    }

    static size_t find_matching_paren(const std::string& s, size_t open_pos) {
        int depth = 0;
        bool in_str = false;
        char q = 0;
        for (size_t i = open_pos; i < s.size(); ++i) {
            char c = s[i];
            if (in_str) {
                if (c == '\\' && i + 1 < s.size()) { i++; continue; }
                if (c == q) in_str = false;
                continue;
            }
            if (c == '"' || c == '\'') { in_str = true; q = c; continue; }
            if (c == '(') depth++;
            else if (c == ')') {
                depth--;
                if (depth == 0) return i;
            }
        }
        return std::string::npos;
    }

    static std::vector<std::string> split_args(const std::string& args_str) {
        std::vector<std::string> res;
        std::string cur;
        int pd = 0, bd = 0, cd = 0;
        bool in_str = false;
        char q = 0;
        for (size_t i = 0; i < args_str.size(); ++i) {
            char c = args_str[i];
            if (in_str) {
                cur.push_back(c);
                if (c == '\\' && i + 1 < args_str.size()) cur.push_back(args_str[++i]);
                else if (c == q) in_str = false;
                continue;
            }
            if (c == '"' || c == '\'') { in_str = true; q = c; cur.push_back(c); continue; }
            if (c == '(') pd++; else if (c == ')') pd--;
            else if (c == '[') bd++; else if (c == ']') bd--;
            else if (c == '{') cd++; else if (c == '}') cd--;
            if (c == ',' && pd == 0 && bd == 0 && cd == 0) {
                std::string t = trim(cur);
                if (!t.empty()) res.push_back(t);
                cur.clear();
            } else {
                cur.push_back(c);
            }
        }
        std::string t = trim(cur);
        if (!t.empty()) res.push_back(t);
        return res;
    }

    static Value vec3_map(const loop_math::Vec3& v) {
        std::unordered_map<std::string, Value> m;
        m["x"] = Value(v.x);
        m["y"] = Value(v.y);
        m["z"] = Value(v.z);
        return Value(m);
    }

    static loop_math::Vec3 val_to_vec3(const Value& v) {
        if (v.type == ValueType::Map && v.map_val) {
            double x = v.map_val->count("x") ? v.map_val->at("x").as_number() : 0.0;
            double y = v.map_val->count("y") ? v.map_val->at("y").as_number() : 0.0;
            double z = v.map_val->count("z") ? v.map_val->at("z").as_number() : 0.0;
            return {x, y, z};
        }
        if (v.type == ValueType::List && v.list_val) {
            const auto& l = *v.list_val;
            return {
                l.size() > 0 ? l[0].as_number() : 0.0,
                l.size() > 1 ? l[1].as_number() : 0.0,
                l.size() > 2 ? l[2].as_number() : 0.0
            };
        }
        return {0, 0, 0};
    }

    // Parse & register C# classes inside `code`, returning remaining top-level statements
    std::string parse_and_register_classes(const std::string& raw_code,
                                           std::unordered_map<std::string, Value>& bridge_vars,
                                           loop_math::Scene3D* scene3d) {
        std::string clean = strip_comments(raw_code);
        std::ostringstream leftover;
        size_t pos = 0;

        while (pos < clean.size()) {
            while (pos < clean.size() && std::isspace(static_cast<unsigned char>(clean[pos]))) pos++;
            if (pos >= clean.size()) break;

            // Skip `using ...;`
            if (clean.compare(pos, 5, "using") == 0 && (pos + 5 < clean.size()) && std::isspace(static_cast<unsigned char>(clean[pos + 5]))) {
                size_t semi = clean.find(';', pos);
                if (semi == std::string::npos) break;
                pos = semi + 1;
                continue;
            }
            // Unwrap `namespace Foo { ... }`
            if (clean.compare(pos, 9, "namespace") == 0 && (pos + 9 < clean.size()) && std::isspace(static_cast<unsigned char>(clean[pos + 9]))) {
                size_t ob = clean.find('{', pos);
                if (ob != std::string::npos) {
                    size_t cb = find_matching_brace(clean, ob);
                    if (cb != std::string::npos) {
                        leftover << parse_and_register_classes(clean.substr(ob + 1, cb - ob - 1), bridge_vars, scene3d) << "\n";
                        pos = cb + 1;
                        continue;
                    }
                }
            }

            // Detect `[public|private|internal|sealed|static] class <Name> [: <Base>] { ... }`
            size_t line_end = clean.find_first_of("{;\n", pos);
            std::string header = clean.substr(pos, (line_end == std::string::npos ? clean.size() : line_end) - pos);
            size_t class_kw = std::string::npos;
            for (size_t k = pos; k < pos + header.size(); ++k) {
                if (clean.compare(k, 5, "class") == 0 &&
                    (k == pos || std::isspace(static_cast<unsigned char>(clean[k - 1]))) &&
                    (k + 5 < clean.size() && std::isspace(static_cast<unsigned char>(clean[k + 5])))) {
                    class_kw = k;
                    break;
                }
            }

            if (class_kw != std::string::npos) {
                size_t ob = clean.find('{', class_kw);
                if (ob != std::string::npos) {
                    size_t cb = find_matching_brace(clean, ob);
                    if (cb != std::string::npos) {
                        std::string cls_hdr = trim(clean.substr(class_kw + 5, ob - (class_kw + 5)));
                        std::string cls_name = cls_hdr;
                        std::string base_name = "MonoBehaviour";
                        size_t colon = cls_hdr.find(':');
                        if (colon != std::string::npos) {
                            cls_name = trim(cls_hdr.substr(0, colon));
                            base_name = trim(cls_hdr.substr(colon + 1));
                        }
                        // strip generic / extra tokens
                        size_t sp = cls_name.find_first_of(" \t<");
                        if (sp != std::string::npos) cls_name = cls_name.substr(0, sp);

                        CSharpClassDef def;
                        def.name = cls_name;
                        def.base_class = base_name;
                        parse_class_body(clean.substr(ob + 1, cb - ob - 1), def, bridge_vars, scene3d);
                        classes[cls_name] = def;
                        pos = cb + 1;
                        continue;
                    }
                }
            }

            // Copy non-class top-level statement up to next `;` or block
            size_t next_ob = clean.find('{', pos);
            size_t next_sc = clean.find(';', pos);
            if (next_ob != std::string::npos && (next_sc == std::string::npos || next_ob < next_sc)) {
                size_t next_cb = find_matching_brace(clean, next_ob);
                if (next_cb != std::string::npos) {
                    leftover << clean.substr(pos, next_cb - pos + 1) << "\n";
                    pos = next_cb + 1;
                    continue;
                }
            }
            if (next_sc != std::string::npos) {
                leftover << clean.substr(pos, next_sc - pos + 1) << "\n";
                pos = next_sc + 1;
            } else {
                leftover << clean.substr(pos) << "\n";
                break;
            }
        }
        return leftover.str();
    }

    void parse_class_body(const std::string& body, CSharpClassDef& def,
                          std::unordered_map<std::string, Value>& bridge_vars,
                          loop_math::Scene3D* scene3d) {
        size_t pos = 0;
        while (pos < body.size()) {
            while (pos < body.size() && std::isspace(static_cast<unsigned char>(body[pos]))) pos++;
            if (pos >= body.size()) break;

            size_t ob = body.find('{', pos);
            size_t sc = body.find(';', pos);

            if (ob != std::string::npos && (sc == std::string::npos || ob < sc)) {
                size_t cb = find_matching_brace(body, ob);
                if (cb == std::string::npos) break;
                std::string sig = trim(body.substr(pos, ob - pos));
                size_t lp = sig.find('(');
                size_t rp = (lp != std::string::npos) ? sig.rfind(')') : std::string::npos;
                if (lp != std::string::npos && rp != std::string::npos && rp > lp) {
                    std::string pre = trim(sig.substr(0, lp));
                    size_t last_sp = pre.find_last_of(" \t\r\n");
                    std::string mname = (last_sp == std::string::npos) ? pre : pre.substr(last_sp + 1);
                    std::string pstr = trim(sig.substr(lp + 1, rp - lp - 1));
                    std::vector<std::string> pnames;
                    for (const auto& p : split_args(pstr)) {
                        std::string pt = trim(p);
                        size_t psp = pt.find_last_of(" \t");
                        pnames.push_back(psp == std::string::npos ? pt : trim(pt.substr(psp + 1)));
                    }
                    def.methods[mname] = body.substr(ob + 1, cb - ob - 1);
                    def.method_params[mname] = pnames;
                }
                pos = cb + 1;
            } else if (sc != std::string::npos) {
                std::string stmt = trim(body.substr(pos, sc - pos));
                std::unordered_map<std::string, Value> empty_locals;
                std::string fname;
                Value fval = Value();
                if (try_parse_var_decl(stmt, fname, fval, def.default_fields, bridge_vars, scene3d)) {
                    def.default_fields[fname] = fval;
                }
                pos = sc + 1;
            } else {
                break;
            }
        }
    }

    Value instantiate(const std::string& class_name, const std::string& inst_id,
                      const std::string& entity_name,
                      std::unordered_map<std::string, Value>& bridge_vars,
                      loop_math::Scene3D* scene3d) {
        auto it = classes.find(class_name);
        if (it == classes.end()) return Value();
        CSharpInstance inst;
        inst.instance_id = inst_id.empty() ? (class_name + "_" + std::to_string(instances.size() + 1)) : inst_id;
        inst.class_name = class_name;
        inst.bound_entity = entity_name;
        inst.fields = it->second.default_fields;
        if (!entity_name.empty()) {
            inst.fields["gameObject"] = Value(entity_name);
        }
        instances[inst.instance_id] = inst;
        if (it->second.methods.count("Start")) {
            call_method(inst.instance_id, "Start", {}, bridge_vars, scene3d);
            instances[inst.instance_id].started = true;
        }
        return Value(inst.instance_id);
    }

    Value call_method(const std::string& inst_id, const std::string& method_name,
                      const std::vector<Value>& args,
                      std::unordered_map<std::string, Value>& bridge_vars,
                      loop_math::Scene3D* scene3d) {
        auto iit = instances.find(inst_id);
        if (iit == instances.end()) return Value();
        auto cit = classes.find(iit->second.class_name);
        if (cit == classes.end()) return Value();
        auto mit = cit->second.methods.find(method_name);
        if (mit == cit->second.methods.end()) return Value();

        std::unordered_map<std::string, Value> method_locals = iit->second.fields;
        const auto& pnames = cit->second.method_params[method_name];
        for (size_t i = 0; i < pnames.size(); ++i) {
            method_locals[pnames[i]] = (i < args.size()) ? args[i] : Value();
        }
        Value ret = Value();
        bool returned = false;
        exec_block(mit->second, method_locals, bridge_vars, scene3d, ret, returned);

        // Persist mutated instance fields back
        for (auto& kv : iit->second.fields) {
            if (method_locals.count(kv.first)) kv.second = method_locals[kv.first];
        }
        for (const auto& kv : cit->second.default_fields) {
            if (method_locals.count(kv.first)) iit->second.fields[kv.first] = method_locals[kv.first];
        }
        return ret;
    }

    int step_all(double dt, std::unordered_map<std::string, Value>& bridge_vars, loop_math::Scene3D* scene3d) {
        int count = 0;
        std::vector<std::string> ids;
        ids.reserve(instances.size());
        for (const auto& kv : instances) ids.push_back(kv.first);
        for (const auto& id : ids) {
            auto& inst = instances[id];
            auto cit = classes.find(inst.class_name);
            if (cit == classes.end()) continue;
            if (!inst.started && cit->second.methods.count("Start")) {
                call_method(id, "Start", {}, bridge_vars, scene3d);
                instances[id].started = true;
            }
            if (cit->second.methods.count("Update")) {
                call_method(id, "Update", {Value(dt)}, bridge_vars, scene3d);
                count++;
            }
        }
        return count;
    }

    Value eval_expr(const std::string& raw,
                    std::unordered_map<std::string, Value>& locals,
                    std::unordered_map<std::string, Value>& bridge_vars,
                    loop_math::Scene3D* scene3d) {
        std::string s = trim(raw);
        if (s.empty()) return Value();

        // Remove surrounding parens
        if (s.front() == '(' && find_matching_paren(s, 0) == s.size() - 1) {
            return eval_expr(s.substr(1, s.size() - 2), locals, bridge_vars, scene3d);
        }

        // Interpolated C# string $"..."
        if (s.size() >= 3 && s[0] == '$' && s[1] == '"' && s.back() == '"') {
            std::string body = s.substr(2, s.size() - 3);
            std::string res;
            for (size_t i = 0; i < body.size(); ++i) {
                if (body[i] == '{') {
                    size_t end = body.find('}', i + 1);
                    if (end != std::string::npos) {
                        res += eval_expr(body.substr(i + 1, end - i - 1), locals, bridge_vars, scene3d).as_string();
                        i = end;
                        continue;
                    }
                }
                res.push_back(body[i]);
            }
            return Value(res);
        }

        // String literal
        if (s.size() >= 2 && s.front() == '"' && s.back() == '"') {
            bool single_str = true;
            bool in_q = true;
            for (size_t i = 1; i + 1 < s.size(); ++i) {
                if (s[i] == '\\') { i++; continue; }
                if (s[i] == '"') { single_str = false; break; }
            }
            if (single_str && in_q) return Value(s.substr(1, s.size() - 2));
        }

        if (s == "true") return Value(true);
        if (s == "false") return Value(false);
        if (s == "null") return Value();
        if (s == "Vector3.zero") return vec3_map({0, 0, 0});
        if (s == "Vector3.one") return vec3_map({1, 1, 1});
        if (s == "Vector3.up") return vec3_map({0, 1, 0});
        if (s == "Vector3.forward") return vec3_map({0, 0, 1});
        if (s == "Mathf.PI" || s == "Math.PI") return Value(3.14159265358979323846);
        if (s == "Time.deltaTime") return Value(1.0 / 60.0);

        // `new Vector3(x, y, z)` or `new ClassName(...)`
        if (s.compare(0, 4, "new ") == 0) {
            std::string rest = trim(s.substr(4));
            size_t lp = rest.find('(');
            if (lp != std::string::npos && rest.back() == ')') {
                std::string tname = trim(rest.substr(0, lp));
                auto args = split_args(rest.substr(lp + 1, rest.size() - lp - 2));
                std::vector<Value> ev_args;
                for (const auto& a : args) ev_args.push_back(eval_expr(a, locals, bridge_vars, scene3d));
                if (tname == "Vector3") {
                    double x = ev_args.size() > 0 ? ev_args[0].as_number() : 0.0;
                    double y = ev_args.size() > 1 ? ev_args[1].as_number() : 0.0;
                    double z = ev_args.size() > 2 ? ev_args[2].as_number() : 0.0;
                    return vec3_map({x, y, z});
                }
                if (classes.count(tname)) {
                    return instantiate(tname, "", "", bridge_vars, scene3d);
                }
            }
        }

        // Binary operators (lowest to highest precedence) at depth 0
        auto find_op = [&](const std::vector<std::string>& ops, bool rtl = false) -> std::pair<size_t, std::string> {
            int pd = 0, bd = 0;
            bool in_str = false;
            char q = 0;
            size_t best_pos = std::string::npos;
            std::string best_op;
            for (size_t i = 0; i < s.size(); ++i) {
                char c = s[i];
                if (in_str) {
                    if (c == '\\' && i + 1 < s.size()) { i++; continue; }
                    if (c == q) in_str = false;
                    continue;
                }
                if (c == '"' || c == '\'') { in_str = true; q = c; continue; }
                if (c == '(') { pd++; continue; }
                if (c == ')') { pd--; continue; }
                if (c == '[') { bd++; continue; }
                if (c == ']') { bd--; continue; }
                if (pd != 0 || bd != 0) continue;

                for (const auto& op : ops) {
                    if (i + op.size() <= s.size() && s.compare(i, op.size(), op) == 0) {
                        // Avoid splitting scientific notation / unary +/- at start
                        if ((op == "+" || op == "-") && i == 0) continue;
                        if ((op == "<" || op == ">") && (i + 1 < s.size() && s[i + 1] == '=')) continue;
                        if (op == "=" && (i + 1 < s.size() && s[i + 1] == '=')) continue;
                        if (op == "+" && (i + 1 < s.size() && s[i + 1] == '+')) continue;
                        if (op == "-" && (i + 1 < s.size() && s[i + 1] == '-')) continue;
                        if (i > 0 && (op == "+" || op == "-")) {
                            char prev = s[i - 1];
                            if (prev == '+' || prev == '-' || prev == '*' || prev == '/' || prev == '(' || prev == ',' || prev == '=' || prev == '<' || prev == '>') continue;
                        }
                        if (!rtl) { best_pos = i; best_op = op; }
                        else if (best_pos == std::string::npos) { best_pos = i; best_op = op; }
                    }
                }
            }
            return {best_pos, best_op};
        };

        auto logical = find_op({"||", "&&"});
        if (logical.first != std::string::npos) {
            Value L = eval_expr(s.substr(0, logical.first), locals, bridge_vars, scene3d);
            Value R = eval_expr(s.substr(logical.first + logical.second.size()), locals, bridge_vars, scene3d);
            return Value(logical.second == "&&" ? (L.is_truthy() && R.is_truthy()) : (L.is_truthy() || R.is_truthy()));
        }

        auto cmp = find_op({"==", "!=", "<=", ">=", "<", ">"});
        if (cmp.first != std::string::npos) {
            Value L = eval_expr(s.substr(0, cmp.first), locals, bridge_vars, scene3d);
            Value R = eval_expr(s.substr(cmp.first + cmp.second.size()), locals, bridge_vars, scene3d);
            if (cmp.second == "==") return Value((L == R));
            if (cmp.second == "!=") return Value(!(L == R));
            if (cmp.second == "<")  return Value(L.as_number() < R.as_number());
            if (cmp.second == ">")  return Value(L.as_number() > R.as_number());
            if (cmp.second == "<=") return Value(L.as_number() <= R.as_number());
            if (cmp.second == ">=") return Value(L.as_number() >= R.as_number());
        }

        auto add = find_op({"+", "-"});
        if (add.first != std::string::npos) {
            Value L = eval_expr(s.substr(0, add.first), locals, bridge_vars, scene3d);
            Value R = eval_expr(s.substr(add.first + 1), locals, bridge_vars, scene3d);
            if (add.second == "+") {
                if (L.type == ValueType::String || R.type == ValueType::String) {
                    return Value(L.as_string() + R.as_string());
                }
                if (L.type == ValueType::Map && R.type == ValueType::Map) {
                    return vec3_map(val_to_vec3(L) + val_to_vec3(R));
                }
                return Value(L.as_number() + R.as_number());
            } else {
                if (L.type == ValueType::Map && R.type == ValueType::Map) {
                    return vec3_map(val_to_vec3(L) - val_to_vec3(R));
                }
                return Value(L.as_number() - R.as_number());
            }
        }

        auto mul = find_op({"*", "/", "%"});
        if (mul.first != std::string::npos) {
            Value L = eval_expr(s.substr(0, mul.first), locals, bridge_vars, scene3d);
            Value R = eval_expr(s.substr(mul.first + 1), locals, bridge_vars, scene3d);
            if (mul.second == "*") {
                if (L.type == ValueType::Map) return vec3_map(val_to_vec3(L) * R.as_number());
                return Value(L.as_number() * R.as_number());
            }
            if (mul.second == "/") {
                double d = R.as_number();
                return Value(std::abs(d) > 1e-12 ? L.as_number() / d : 0.0);
            }
            int64_t r_int = static_cast<int64_t>(R.as_number());
            return Value(r_int != 0 ? static_cast<double>(static_cast<int64_t>(L.as_number()) % r_int) : 0.0);
        }

        // Unary ! / -
        if (s[0] == '!') return Value(!eval_expr(s.substr(1), locals, bridge_vars, scene3d).is_truthy());
        if (s[0] == '-') return Value(-eval_expr(s.substr(1), locals, bridge_vars, scene3d).as_number());

        // Function / Method call: `Target.Method(args)`
        size_t lp = s.find('(');
        if (lp != std::string::npos && find_matching_paren(s, lp) == s.size() - 1) {
            std::string fn = trim(s.substr(0, lp));
            auto raw_args = split_args(s.substr(lp + 1, s.size() - lp - 2));
            std::vector<Value> args;
            for (const auto& ra : raw_args) args.push_back(eval_expr(ra, locals, bridge_vars, scene3d));

            if (fn == "Console.WriteLine" || fn == "Debug.Log" || fn == "Debug.LogWarning") {
                std::ostringstream os;
                for (size_t i = 0; i < args.size(); ++i) {
                    if (i > 0) os << " ";
                    os << args[i].as_string();
                }
                std::string msg = os.str();
                logs.push_back(msg);
                std::cout << "\033[35m[C#]\033[0m " << msg << "\n";
                return Value(msg);
            }
            if (fn == "LoopingBridge.Get" && !args.empty()) {
                std::string k = args[0].as_string();
                if (bridge_vars.count(k)) return bridge_vars[k];
                return Value();
            }
            if (fn == "LoopingBridge.Set" && args.size() >= 2) {
                std::string k = args[0].as_string();
                bridge_vars[k] = args[1];
                return args[1];
            }
            if (fn == "Mathf.Clamp" || fn == "Math.Clamp") {
                double v = args.size() > 0 ? args[0].as_number() : 0.0;
                double lo = args.size() > 1 ? args[1].as_number() : 0.0;
                double hi = args.size() > 2 ? args[2].as_number() : 1.0;
                return Value(std::clamp(v, std::min(lo, hi), std::max(lo, hi)));
            }
            if (fn == "Mathf.Lerp" && args.size() >= 3) {
                return Value(args[0].as_number() + (args[1].as_number() - args[0].as_number()) * args[2].as_number());
            }
            if (fn == "Mathf.Sin" || fn == "Math.Sin") return Value(std::sin(args.empty() ? 0.0 : args[0].as_number()));
            if (fn == "Mathf.Cos" || fn == "Math.Cos") return Value(std::cos(args.empty() ? 0.0 : args[0].as_number()));
            if (fn == "Mathf.Abs" || fn == "Math.Abs") return Value(std::abs(args.empty() ? 0.0 : args[0].as_number()));
            if (fn == "Mathf.Sqrt" || fn == "Math.Sqrt") return Value(std::sqrt(std::max(0.0, args.empty() ? 0.0 : args[0].as_number())));
            if (fn == "Mathf.Min" || fn == "Math.Min") return Value(std::min(args.size() > 0 ? args[0].as_number() : 0.0, args.size() > 1 ? args[1].as_number() : 0.0));
            if (fn == "Mathf.Max" || fn == "Math.Max") return Value(std::max(args.size() > 0 ? args[0].as_number() : 0.0, args.size() > 1 ? args[1].as_number() : 0.0));
            if (fn == "Vector3.Distance" && args.size() >= 2) {
                return Value((val_to_vec3(args[0]) - val_to_vec3(args[1])).length());
            }
            if (fn == "Vector3.Lerp" && args.size() >= 3) {
                return vec3_map(loop_math::lerp(val_to_vec3(args[0]), val_to_vec3(args[1]), args[2].as_number()));
            }
            if (fn == "Vector3.Dot" && args.size() >= 2) {
                return Value(loop_math::dot(val_to_vec3(args[0]), val_to_vec3(args[1])));
            }
            if (fn == "Vector3.Cross" && args.size() >= 2) {
                return vec3_map(loop_math::cross(val_to_vec3(args[0]), val_to_vec3(args[1])));
            }
            if (fn == "Scene3D.Move" || fn == "Scene3D.Translate") {
                if (scene3d && args.size() >= 2) {
                    std::string target = args[0].as_string();
                    loop_math::Vec3 d = (args.size() >= 4)
                        ? loop_math::Vec3{args[1].as_number(), args[2].as_number(), args[3].as_number()}
                        : val_to_vec3(args[1]);
                    for (auto& e : scene3d->entities) {
                        if (e.name == target) {
                            e.pos = e.pos + d;
                            return vec3_map(e.pos);
                        }
                    }
                }
                return Value();
            }
            if (fn == "Scene3D.SetPosition" && scene3d && args.size() >= 2) {
                std::string target = args[0].as_string();
                loop_math::Vec3 p = (args.size() >= 4)
                    ? loop_math::Vec3{args[1].as_number(), args[2].as_number(), args[3].as_number()}
                    : val_to_vec3(args[1]);
                for (auto& e : scene3d->entities) {
                    if (e.name == target) { e.pos = p; return vec3_map(e.pos); }
                }
                return Value();
            }
            if (fn == "Scene3D.Rotate" && scene3d && args.size() >= 2) {
                std::string target = args[0].as_string();
                loop_math::Vec3 dr = (args.size() >= 4)
                    ? loop_math::Vec3{args[1].as_number(), args[2].as_number(), args[3].as_number()}
                    : val_to_vec3(args[1]);
                for (auto& e : scene3d->entities) {
                    if (e.name == target) {
                        e.rot_deg = e.rot_deg + dr;
                        return vec3_map(e.rot_deg);
                    }
                }
                return Value();
            }
            if (fn == "Scene3D.SetRotation" && scene3d && args.size() >= 2) {
                std::string target = args[0].as_string();
                loop_math::Vec3 r = (args.size() >= 4)
                    ? loop_math::Vec3{args[1].as_number(), args[2].as_number(), args[3].as_number()}
                    : val_to_vec3(args[1]);
                for (auto& e : scene3d->entities) {
                    if (e.name == target) { e.rot_deg = r; return vec3_map(e.rot_deg); }
                }
                return Value();
            }
            if (fn == "Scene3D.Scale" && scene3d && args.size() >= 2) {
                std::string target = args[0].as_string();
                loop_math::Vec3 sc = (args.size() >= 4)
                    ? loop_math::Vec3{args[1].as_number(), args[2].as_number(), args[3].as_number()}
                    : val_to_vec3(args[1]);
                for (auto& e : scene3d->entities) {
                    if (e.name == target) { e.scale = sc; return vec3_map(e.scale); }
                }
                return Value();
            }
            if ((fn == "Scene3D.GetPos" || fn == "Scene3D.GetPosition") && scene3d && !args.empty()) {
                std::string target = args[0].as_string();
                for (const auto& e : scene3d->entities) {
                    if (e.name == target) return vec3_map(e.pos);
                }
                return vec3_map({0, 0, 0});
            }
            if (fn == "Scene3D.GetRotation" && scene3d && !args.empty()) {
                std::string target = args[0].as_string();
                for (const auto& e : scene3d->entities) {
                    if (e.name == target) return vec3_map(e.rot_deg);
                }
                return vec3_map({0, 0, 0});
            }
            if (fn == "Scene3D.Damage" && scene3d && args.size() >= 2) {
                std::string target = args[0].as_string();
                for (auto& e : scene3d->entities) {
                    if (e.name == target) {
                        e.health = std::max(0.0, e.health - args[1].as_number());
                        return Value(e.health);
                    }
                }
                return Value(0.0);
            }
            return Value();
        }

        // Property access e.g. `pos.x`
        size_t dot_pos = s.rfind('.');
        if (dot_pos != std::string::npos && !(std::isdigit(static_cast<unsigned char>(s[0])) || s[0] == '-')) {
            std::string lhs = trim(s.substr(0, dot_pos));
            std::string prop = trim(s.substr(dot_pos + 1));
            Value base = eval_expr(lhs, locals, bridge_vars, scene3d);
            if (base.type == ValueType::Map && base.map_val && base.map_val->count(prop)) {
                return base.map_val->at(prop);
            }
            if (base.type == ValueType::Map && base.map_val && prop == "magnitude") {
                return Value(val_to_vec3(base).length());
            }
        }

        // Number literal (handles C# suffixes like 25.0f, 100d, 10L)
        std::string num_s = s;
        if (num_s.size() >= 2 && (num_s.back() == 'f' || num_s.back() == 'F' || num_s.back() == 'd' || num_s.back() == 'D' || num_s.back() == 'm' || num_s.back() == 'L')) {
            if (std::isdigit(static_cast<unsigned char>(num_s[num_s.size() - 2]))) {
                num_s.pop_back();
            }
        }
        try {
            size_t idx = 0;
            double v = std::stod(num_s, &idx);
            if (idx == num_s.size()) return Value(v);
        } catch (...) {}

        if (locals.count(s)) return locals[s];
        if (bridge_vars.count(s)) return bridge_vars[s];
        return Value();
    }

    bool try_parse_var_decl(const std::string& stmt, std::string& out_name, Value& out_val,
                            std::unordered_map<std::string, Value>& locals,
                            std::unordered_map<std::string, Value>& bridge_vars,
                            loop_math::Scene3D* scene3d) {
        std::string s = trim(stmt);
        static const std::vector<std::string> modifiers = {"public", "private", "protected", "internal", "static", "readonly", "const"};
        bool stripped = true;
        while (stripped) {
            stripped = false;
            for (const auto& m : modifiers) {
                if (s.compare(0, m.size(), m) == 0 && s.size() > m.size() && std::isspace(static_cast<unsigned char>(s[m.size()]))) {
                    s = trim(s.substr(m.size()));
                    stripped = true;
                    break;
                }
            }
        }
        static const std::vector<std::string> types = {"int", "float", "double", "bool", "string", "var", "Vector3", "Quaternion"};
        for (const auto& tp : types) {
            if (s.compare(0, tp.size(), tp) == 0 && s.size() > tp.size() && std::isspace(static_cast<unsigned char>(s[tp.size()]))) {
                std::string rest = trim(s.substr(tp.size()));
                size_t eq = rest.find('=');
                if (eq != std::string::npos) {
                    out_name = trim(rest.substr(0, eq));
                    out_val = eval_expr(rest.substr(eq + 1), locals, bridge_vars, scene3d);
                } else {
                    out_name = rest;
                    out_val = (tp == "string") ? Value("") : (tp == "bool" ? Value(false) : (tp == "Vector3" ? vec3_map({0, 0, 0}) : Value(0.0)));
                }
                return !out_name.empty();
            }
        }
        return false;
    }

    void exec_single_stmt(const std::string& raw,
                          std::unordered_map<std::string, Value>& locals,
                          std::unordered_map<std::string, Value>& bridge_vars,
                          loop_math::Scene3D* scene3d,
                          Value& out_ret, bool& returned) {
        std::string s = trim(raw);
        if (s.empty() || returned) return;

        if (s.compare(0, 6, "return") == 0 && (s.size() == 6 || std::isspace(static_cast<unsigned char>(s[6])))) {
            std::string expr = trim(s.substr(6));
            out_ret = expr.empty() ? Value() : eval_expr(expr, locals, bridge_vars, scene3d);
            returned = true;
            return;
        }

        // var / typed declaration
        std::string vname;
        Value vval = Value();
        if (try_parse_var_decl(s, vname, vval, locals, bridge_vars, scene3d)) {
            locals[vname] = vval;
            out_ret = vval;
            return;
        }

        // x++ / x--
        if (s.size() > 2 && s.substr(s.size() - 2) == "++") {
            std::string target = trim(s.substr(0, s.size() - 2));
            Value cur = eval_expr(target, locals, bridge_vars, scene3d);
            Value next(cur.as_number() + 1.0);
            if (locals.count(target) || !bridge_vars.count(target)) locals[target] = next;
            else bridge_vars[target] = next;
            out_ret = next;
            return;
        }
        if (s.size() > 2 && s.substr(s.size() - 2) == "--") {
            std::string target = trim(s.substr(0, s.size() - 2));
            Value cur = eval_expr(target, locals, bridge_vars, scene3d);
            Value next(cur.as_number() - 1.0);
            if (locals.count(target) || !bridge_vars.count(target)) locals[target] = next;
            else bridge_vars[target] = next;
            out_ret = next;
            return;
        }

        // Assignment (`=`, `+=`, `-=`, `*=`, `/=`)
        size_t eq = std::string::npos;
        bool in_str = false;
        int pd = 0;
        for (size_t i = 0; i < s.size(); ++i) {
            char c = s[i];
            if (c == '"' && (i == 0 || s[i - 1] != '\\')) in_str = !in_str;
            if (in_str) continue;
            if (c == '(') pd++; else if (c == ')') pd--;
            if (pd != 0) continue;
            if (c == '=' && !(i > 0 && (s[i - 1] == '!' || s[i - 1] == '<' || s[i - 1] == '>' || s[i - 1] == '=')) &&
                !(i + 1 < s.size() && s[i + 1] == '=')) {
                eq = i;
                break;
            }
        }
        if (eq != std::string::npos) {
            std::string op = "=";
            size_t lhs_end = eq;
            if (eq > 0 && (s[eq - 1] == '+' || s[eq - 1] == '-' || s[eq - 1] == '*' || s[eq - 1] == '/')) {
                op = std::string(1, s[eq - 1]) + "=";
                lhs_end = eq - 1;
            }
            std::string lhs = trim(s.substr(0, lhs_end));
            Value rhs = eval_expr(s.substr(eq + 1), locals, bridge_vars, scene3d);
            Value cur = eval_expr(lhs, locals, bridge_vars, scene3d);
            Value res = rhs;
            if (op == "+=") {
                if (cur.type == ValueType::String || rhs.type == ValueType::String) res = Value(cur.as_string() + rhs.as_string());
                else if (cur.type == ValueType::Map && rhs.type == ValueType::Map) res = vec3_map(val_to_vec3(cur) + val_to_vec3(rhs));
                else res = Value(cur.as_number() + rhs.as_number());
            } else if (op == "-=") res = Value(cur.as_number() - rhs.as_number());
            else if (op == "*=") res = Value(cur.as_number() * rhs.as_number());
            else if (op == "/=") res = Value(std::abs(rhs.as_number()) > 1e-12 ? cur.as_number() / rhs.as_number() : 0.0);

            if (locals.count(lhs) || !bridge_vars.count(lhs)) locals[lhs] = res;
            else bridge_vars[lhs] = res;
            out_ret = res;
            return;
        }

        out_ret = eval_expr(s, locals, bridge_vars, scene3d);
    }

    Value exec_block(const std::string& code,
                     std::unordered_map<std::string, Value>& locals,
                     std::unordered_map<std::string, Value>& bridge_vars,
                     loop_math::Scene3D* scene3d,
                     Value& out_ret, bool& returned) {
        size_t pos = 0;
        while (pos < code.size() && !returned) {
            while (pos < code.size() && (std::isspace(static_cast<unsigned char>(code[pos])) || code[pos] == ';')) pos++;
            if (pos >= code.size()) break;

            // if (...) { ... } [else { ... }]
            if (code.compare(pos, 2, "if") == 0 && (pos + 2 < code.size() && (code[pos + 2] == '(' || std::isspace(static_cast<unsigned char>(code[pos + 2]))))) {
                size_t lp = code.find('(', pos);
                size_t rp = (lp != std::string::npos) ? find_matching_paren(code, lp) : std::string::npos;
                size_t ob = (rp != std::string::npos) ? code.find('{', rp) : std::string::npos;
                if (ob != std::string::npos) {
                    size_t cb = find_matching_brace(code, ob);
                    if (cb != std::string::npos) {
                        bool cond = eval_expr(code.substr(lp + 1, rp - lp - 1), locals, bridge_vars, scene3d).is_truthy();
                        std::string then_b = code.substr(ob + 1, cb - ob - 1);
                        std::string else_b;
                        pos = cb + 1;
                        while (pos < code.size() && std::isspace(static_cast<unsigned char>(code[pos]))) pos++;
                        if (code.compare(pos, 4, "else") == 0 && (pos + 4 >= code.size() || !std::isalnum(static_cast<unsigned char>(code[pos + 4])))) {
                            size_t eob = code.find('{', pos + 4);
                            if (eob != std::string::npos) {
                                size_t ecb = find_matching_brace(code, eob);
                                if (ecb != std::string::npos) {
                                    else_b = code.substr(eob + 1, ecb - eob - 1);
                                    pos = ecb + 1;
                                }
                            }
                        }
                        if (cond) exec_block(then_b, locals, bridge_vars, scene3d, out_ret, returned);
                        else if (!else_b.empty()) exec_block(else_b, locals, bridge_vars, scene3d, out_ret, returned);
                        continue;
                    }
                }
            }

            // for (init; cond; step) { ... }
            if (code.compare(pos, 3, "for") == 0 && (pos + 3 < code.size() && (code[pos + 3] == '(' || std::isspace(static_cast<unsigned char>(code[pos + 3]))))) {
                size_t lp = code.find('(', pos);
                size_t rp = (lp != std::string::npos) ? find_matching_paren(code, lp) : std::string::npos;
                size_t ob = (rp != std::string::npos) ? code.find('{', rp) : std::string::npos;
                if (ob != std::string::npos) {
                    size_t cb = find_matching_brace(code, ob);
                    if (cb != std::string::npos) {
                        std::string header = code.substr(lp + 1, rp - lp - 1);
                        size_t s1 = header.find(';');
                        size_t s2 = (s1 != std::string::npos) ? header.find(';', s1 + 1) : std::string::npos;
                        if (s1 != std::string::npos && s2 != std::string::npos) {
                            exec_single_stmt(header.substr(0, s1), locals, bridge_vars, scene3d, out_ret, returned);
                            std::string cond_s = trim(header.substr(s1 + 1, s2 - s1 - 1));
                            std::string step_s = trim(header.substr(s2 + 1));
                            std::string body = code.substr(ob + 1, cb - ob - 1);
                            int guard = 0;
                            while (!returned && guard++ < 10000) {
                                if (!cond_s.empty() && !eval_expr(cond_s, locals, bridge_vars, scene3d).is_truthy()) break;
                                exec_block(body, locals, bridge_vars, scene3d, out_ret, returned);
                                if (!step_s.empty() && !returned) exec_single_stmt(step_s, locals, bridge_vars, scene3d, out_ret, returned);
                            }
                        }
                        pos = cb + 1;
                        continue;
                    }
                }
            }

            // while (cond) { ... }
            if (code.compare(pos, 5, "while") == 0 && (pos + 5 < code.size() && (code[pos + 5] == '(' || std::isspace(static_cast<unsigned char>(code[pos + 5]))))) {
                size_t lp = code.find('(', pos);
                size_t rp = (lp != std::string::npos) ? find_matching_paren(code, lp) : std::string::npos;
                size_t ob = (rp != std::string::npos) ? code.find('{', rp) : std::string::npos;
                if (ob != std::string::npos) {
                    size_t cb = find_matching_brace(code, ob);
                    if (cb != std::string::npos) {
                        std::string cond_s = code.substr(lp + 1, rp - lp - 1);
                        std::string body = code.substr(ob + 1, cb - ob - 1);
                        int guard = 0;
                        while (!returned && guard++ < 10000 && eval_expr(cond_s, locals, bridge_vars, scene3d).is_truthy()) {
                            exec_block(body, locals, bridge_vars, scene3d, out_ret, returned);
                        }
                        pos = cb + 1;
                        continue;
                    }
                }
            }

            // Normal statement terminated by `;` or newline/end when parens balanced
            size_t sc = std::string::npos;
            bool in_str = false;
            int pd = 0;
            for (size_t i = pos; i < code.size(); ++i) {
                char c = code[i];
                if (c == '"' && (i == 0 || code[i - 1] != '\\')) in_str = !in_str;
                if (in_str) continue;
                if (c == '(') pd++; else if (c == ')') pd--;
                if ((c == ';' || c == '\n') && pd <= 0) { sc = i; break; }
            }
            std::string stmt = (sc == std::string::npos) ? code.substr(pos) : code.substr(pos, sc - pos);
            exec_single_stmt(stmt, locals, bridge_vars, scene3d, out_ret, returned);
            pos = (sc == std::string::npos) ? code.size() : (sc + 1);
        }
        return out_ret;
    }

    Value execute_block(const std::string& raw_code,
                        std::unordered_map<std::string, Value>& bridge_vars,
                        loop_math::Scene3D* scene3d = nullptr) {
        detect();
        std::string leftover = parse_and_register_classes(raw_code, bridge_vars, scene3d);
        std::unordered_map<std::string, Value> locals;
        Value ret = Value();
        bool returned = false;
        exec_block(leftover, locals, bridge_vars, scene3d, ret, returned);
        // Propagate top-level newly defined variables back to bridge_vars if scalar/map
        for (const auto& kv : locals) {
            bridge_vars[kv.first] = kv.second;
        }
        return ret;
    }

    Value evaluate_inline(const std::string& expr,
                          std::unordered_map<std::string, Value>& bridge_vars,
                          loop_math::Scene3D* scene3d = nullptr) {
        std::unordered_map<std::string, Value> empty_locals;
        return eval_expr(expr, empty_locals, bridge_vars, scene3d);
    }

    static std::string export_scene_csharp(const loop_math::Scene3D& scene, const std::string& class_name = "LoopizeGeneratedGame") {
        std::ostringstream cs;
        cs << "// Generated by Looping Engine v1.1 (Arch 3.0A) + loopize++ C# Bridge\n";
        cs << "using System;\n";
        cs << "using System.Collections.Generic;\n\n";
        cs << "namespace CokiStudios.Loopize {\n";
        cs << "    public struct Vec3 {\n";
        cs << "        public float X, Y, Z;\n";
        cs << "        public Vec3(float x, float y, float z) { X = x; Y = y; Z = z; }\n";
        cs << "    }\n\n";
        cs << "    public class EntitySpec {\n";
        cs << "        public string Type, Name, ObjFile, CsClass, Color;\n";
        cs << "        public Vec3 Position, Scale;\n";
        cs << "    }\n\n";
        cs << "    public class " << class_name << " {\n";
        cs << "        public string WorldName = \"" << scene.world_name << "\";\n";
        cs << "        public float Gravity = " << scene.gravity << "f;\n";
        cs << "        public int PhysicsSubsteps = " << scene.substeps << ";\n";
        cs << "        public List<EntitySpec> Entities = new List<EntitySpec> {\n";
        for (const auto& e : scene.entities) {
            cs << "            new EntitySpec { Type = \"" << e.type << "\", Name = \"" << e.name
               << "\", ObjFile = \"" << e.obj_file << "\", CsClass = \"" << e.cs_class
               << "\", Color = \"" << e.color << "\", Position = new Vec3("
               << e.pos.x << "f, " << e.pos.y << "f, " << e.pos.z << "f), Scale = new Vec3("
               << e.scale.x << "f, " << e.scale.y << "f, " << e.scale.z << "f) },\n";
        }
        cs << "        };\n\n";
        cs << "        public void RunSimulationStep(float dt = 0.016f) {\n";
        cs << "            Console.WriteLine($\"[Loopize C#] {WorldName} | {Entities.Count} 3D entities @ {PhysicsSubsteps * 60}Hz\");\n";
        cs << "        }\n";
        cs << "    }\n";
        cs << "}\n";
        return cs.str();
    }
};

} // namespace looping
