#pragma once

#include <iostream>
#include <string>
#include <vector>
#include <unordered_map>
#include <memory>
#include <sstream>
#include <cmath>
#include <iomanip>

namespace looping {

enum class ValueType {
    Nil,
    Bool,
    Int,
    Float,
    String,
    Tuple,   // 2D coordinate / size (x, y)
    List,    // Vector of Values
    Map      // Key-Value Dictionary
};

class Value {
public:
    ValueType type;
    bool bool_val = false;
    int64_t int_val = 0;
    double float_val = 0.0;
    std::string str_val;
    std::pair<double, double> tuple_val = {0.0, 0.0};
    std::shared_ptr<std::vector<Value>> list_val;
    std::shared_ptr<std::unordered_map<std::string, Value>> map_val;

    // Constructors
    Value() : type(ValueType::Nil) {}
    Value(bool b) : type(ValueType::Bool), bool_val(b) {}
    Value(int i) : type(ValueType::Int), int_val(i), float_val(static_cast<double>(i)) {}
    Value(int64_t i) : type(ValueType::Int), int_val(i), float_val(static_cast<double>(i)) {}
    Value(double d) : type(ValueType::Float), int_val(static_cast<int64_t>(d)), float_val(d) {}
    Value(const char* s) : type(ValueType::String), str_val(s ? s : "") {}
    Value(const std::string& s) : type(ValueType::String), str_val(s) {}
    Value(double x, double y) : type(ValueType::Tuple), tuple_val({x, y}) {}
    Value(const std::vector<Value>& l) : type(ValueType::List), list_val(std::make_shared<std::vector<Value>>(l)) {}
    Value(const std::unordered_map<std::string, Value>& m) : type(ValueType::Map), map_val(std::make_shared<std::unordered_map<std::string, Value>>(m)) {}

    // Truthiness
    bool is_truthy() const {
        switch (type) {
            case ValueType::Nil: return false;
            case ValueType::Bool: return bool_val;
            case ValueType::Int: return int_val != 0;
            case ValueType::Float: return float_val != 0.0 && !std::isnan(float_val);
            case ValueType::String: return !str_val.empty();
            case ValueType::Tuple: return tuple_val.first != 0.0 || tuple_val.second != 0.0;
            case ValueType::List: return list_val && !list_val->empty();
            case ValueType::Map: return map_val && !map_val->empty();
        }
        return false;
    }

    bool is_number() const {
        return type == ValueType::Int || type == ValueType::Float;
    }

    double as_number() const {
        if (type == ValueType::Int) return static_cast<double>(int_val);
        if (type == ValueType::Float) return float_val;
        if (type == ValueType::Bool) return bool_val ? 1.0 : 0.0;
        if (type == ValueType::String) {
            try { return std::stod(str_val); } catch (...) { return 0.0; }
        }
        return 0.0;
    }

    int64_t as_int() const {
        if (type == ValueType::Int) return int_val;
        if (type == ValueType::Float) return static_cast<int64_t>(float_val);
        if (type == ValueType::Bool) return bool_val ? 1 : 0;
        if (type == ValueType::String) {
            try { return std::stoll(str_val); } catch (...) { return 0; }
        }
        return 0;
    }

    std::string as_string() const {
        switch (type) {
            case ValueType::Nil: return "nil";
            case ValueType::Bool: return bool_val ? "true" : "false";
            case ValueType::Int: return std::to_string(int_val);
            case ValueType::Float: {
                if (std::isnan(float_val)) return "nan";
                if (std::isinf(float_val)) return float_val > 0 ? "inf" : "-inf";
                // Print clean representation (avoid trailing zeros if integer)
                if (float_val == std::floor(float_val) && std::abs(float_val) < 1e14) {
                    return std::to_string(static_cast<int64_t>(float_val));
                }
                std::ostringstream ss;
                ss << std::setprecision(10) << float_val;
                return ss.str();
            }
            case ValueType::String: return str_val;
            case ValueType::Tuple: {
                std::ostringstream ss;
                ss << "(" << tuple_val.first << ", " << tuple_val.second << ")";
                return ss.str();
            }
            case ValueType::List: {
                std::ostringstream ss;
                ss << "[";
                if (list_val) {
                    for (size_t i = 0; i < list_val->size(); ++i) {
                        if (i > 0) ss << ", ";
                        ss << (*list_val)[i].to_repr();
                    }
                }
                ss << "]";
                return ss.str();
            }
            case ValueType::Map: {
                std::ostringstream ss;
                ss << "{";
                if (map_val) {
                    bool first = true;
                    for (const auto& [k, v] : *map_val) {
                        if (!first) ss << ", ";
                        first = false;
                        ss << "\"" << k << "\": " << v.to_repr();
                    }
                }
                ss << "}";
                return ss.str();
            }
        }
        return "";
    }

    std::string to_repr() const {
        if (type == ValueType::String) {
            std::string esc = "\"";
            for (char c : str_val) {
                if (c == '"') esc += "\\\"";
                else if (c == '\\') esc += "\\\\";
                else if (c == '\n') esc += "\\n";
                else if (c == '\t') esc += "\\t";
                else esc += c;
            }
            esc += "\"";
            return esc;
        }
        return as_string();
    }

    // JSON export representation for Python bridge
    std::string to_json() const {
        switch (type) {
            case ValueType::Nil: return "null";
            case ValueType::Bool: return bool_val ? "true" : "false";
            case ValueType::Int: return std::to_string(int_val);
            case ValueType::Float: {
                if (std::isnan(float_val) || std::isinf(float_val)) return "0";
                std::ostringstream ss;
                ss << float_val;
                return ss.str();
            }
            case ValueType::String: return to_repr();
            case ValueType::Tuple: {
                std::ostringstream ss;
                ss << "[" << tuple_val.first << ", " << tuple_val.second << "]";
                return ss.str();
            }
            case ValueType::List: {
                std::ostringstream ss;
                ss << "[";
                if (list_val) {
                    for (size_t i = 0; i < list_val->size(); ++i) {
                        if (i > 0) ss << ", ";
                        ss << (*list_val)[i].to_json();
                    }
                }
                ss << "]";
                return ss.str();
            }
            case ValueType::Map: {
                std::ostringstream ss;
                ss << "{";
                if (map_val) {
                    bool first = true;
                    for (const auto& [k, v] : *map_val) {
                        if (!first) ss << ", ";
                        first = false;
                        ss << "\"" << k << "\": " << v.to_json();
                    }
                }
                ss << "}";
                return ss.str();
            }
        }
        return "null";
    }

    // Operator overloads
    Value operator+(const Value& other) const {
        // String concatenation
        if (type == ValueType::String || other.type == ValueType::String) {
            return Value(as_string() + other.as_string());
        }
        // Integer arithmetic
        if (type == ValueType::Int && other.type == ValueType::Int) {
            return Value(int_val + other.int_val);
        }
        // Float arithmetic
        return Value(as_number() + other.as_number());
    }

    Value operator-(const Value& other) const {
        if (type == ValueType::Int && other.type == ValueType::Int) {
            return Value(int_val - other.int_val);
        }
        return Value(as_number() - other.as_number());
    }

    Value operator*(const Value& other) const {
        // String repetition: "abc" * 3
        if (type == ValueType::String && other.type == ValueType::Int) {
            std::string res;
            int64_t times = other.int_val;
            if (times > 0 && times < 100000) {
                res.reserve(str_val.size() * times);
                for (int64_t i = 0; i < times; ++i) res += str_val;
            }
            return Value(res);
        }
        if (type == ValueType::Int && other.type == ValueType::Int) {
            return Value(int_val * other.int_val);
        }
        return Value(as_number() * other.as_number());
    }

    Value operator/(const Value& other) const {
        double divisor = other.as_number();
        if (divisor == 0.0) return Value(0.0);
        if (type == ValueType::Int && other.type == ValueType::Int && other.int_val != 0 && (int_val % other.int_val == 0)) {
            return Value(int_val / other.int_val);
        }
        return Value(as_number() / divisor);
    }

    Value operator%(const Value& other) const {
        int64_t d = other.as_int();
        if (d == 0) return Value(0);
        return Value(as_int() % d);
    }

    Value power(const Value& other) const {
        return Value(std::pow(as_number(), other.as_number()));
    }

    bool operator==(const Value& other) const {
        if (type != other.type) {
            if (is_number() && other.is_number()) {
                return as_number() == other.as_number();
            }
            return as_string() == other.as_string();
        }
        switch (type) {
            case ValueType::Nil: return true;
            case ValueType::Bool: return bool_val == other.bool_val;
            case ValueType::Int: return int_val == other.int_val;
            case ValueType::Float: return float_val == other.float_val;
            case ValueType::String: return str_val == other.str_val;
            case ValueType::Tuple: return tuple_val == other.tuple_val;
            default: return as_string() == other.as_string();
        }
    }

    bool operator!=(const Value& other) const {
        return !(*this == other);
    }

    bool operator<(const Value& other) const {
        if (is_number() && other.is_number()) return as_number() < other.as_number();
        return as_string() < other.as_string();
    }

    bool operator<=(const Value& other) const {
        if (is_number() && other.is_number()) return as_number() <= other.as_number();
        return as_string() <= other.as_string();
    }

    bool operator>(const Value& other) const {
        if (is_number() && other.is_number()) return as_number() > other.as_number();
        return as_string() > other.as_string();
    }

    bool operator>=(const Value& other) const {
        if (is_number() && other.is_number()) return as_number() >= other.as_number();
        return as_string() >= other.as_string();
    }
};

} // namespace looping
